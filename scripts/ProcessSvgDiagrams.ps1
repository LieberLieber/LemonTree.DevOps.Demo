# Copyright (c) LieberLieber Software GmbH
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

param(
    [string]$DiffReportFilename,
    [string]$GitUserName,
    [string]$GitUserEmail,
    [string]$OriginalBranch = "",
    [string]$PullRequestNumber = "",
    [string]$RepositoryName = ""
)

# Read the DiffReport.xml to extract diagram information
$xmlFilePath = $DiffReportFilename
[xml]$xmlContent = Get-Content -Path $xmlFilePath

# Define the XML namespaces
$ns = New-Object Xml.XmlNamespaceManager $xmlContent.NameTable
$ns.AddNamespace("ns", "http://www.lieberlieber.com")

# Select all diagramPicture elements using the defined namespace
$diagramPictures = $xmlContent.SelectNodes('//ns:diagramPictures/ns:diagramPicture', $ns)

Write-Host "Found $($diagramPictures.Count) Diagrams."
Write-Output "Processing $($diagramPictures.Count) diagrams for SVG export"

function Invoke-SvgGit {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)
    $result = & git @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "git $($Arguments -join ' ') failed with exit code $LASTEXITCODE"
    }
    $result
}

$ErrorActionPreference = 'Stop'
$originalCommit = Invoke-SvgGit rev-parse HEAD
$restoreBranch = Invoke-SvgGit branch --show-current
if (![string]::IsNullOrEmpty($OriginalBranch)) {
    Invoke-SvgGit rev-parse --verify "$OriginalBranch^{commit}" | Out-Null
    $restoreBranch = $OriginalBranch
}
Write-Output "Original checkout: $restoreBranch ($originalCommit)"

$svgFiles = @()
$svgInfo = @()
$svgLinksMarkdown = ""

foreach ($diagramPicture in $diagramPictures) {
    $diagramGuid = $diagramPicture.guid
    if($diagramGuid){
        $cdata_b = $diagramPicture.diagramPictureB.InnerText
        if (![string]::IsNullOrEmpty($cdata_b)) {
            $qualifiedName = $diagramPicture.diagramPictureB.qualifiedName
            Write-Output "Processing diagram: $qualifiedName"
            $fileGuid = $diagramGuid.Replace('{','').Replace('}','')
            $filename = "$fileGuid.svg"
            Write-Output "$qualifiedName ==> $filename"
            $svgFiles += $filename
            $svgInfo += @{ Name = $qualifiedName; File = $filename; Content = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($cdata_b)) }
        }
    }
}

if ($svgFiles.Count -gt 0) {
    $publishError = $null
    try {
        Invoke-SvgGit config user.name $GitUserName | Out-Host
        Invoke-SvgGit config user.email $GitUserEmail | Out-Host
        Invoke-SvgGit fetch origin | Out-Host
        $localSvg = Invoke-SvgGit branch --list svg
        $remoteSvg = Invoke-SvgGit branch --remotes --list origin/svg
        if ($localSvg) {
            Invoke-SvgGit checkout svg | Out-Host
        } elseif ($remoteSvg) {
            Invoke-SvgGit checkout --track -b svg origin/svg | Out-Host
        } else {
            Invoke-SvgGit checkout --orphan svg | Out-Host
            Invoke-SvgGit rm -rf . | Out-Host
        }
        if ($remoteSvg) {
            Invoke-SvgGit pull --ff-only origin svg | Out-Host
        }

        foreach ($svg in $svgInfo) {
            Set-Content -Encoding UTF8 -LiteralPath $svg.File -Value $svg.Content
        }
        Invoke-SvgGit add -- @svgFiles | Out-Host
        & git diff --cached --quiet
        $diffExitCode = $LASTEXITCODE
        if ($diffExitCode -eq 1) {
            $commitMsg = "Add SVG files for diagrams"
            if (![string]::IsNullOrEmpty($PullRequestNumber)) {
                $commitMsg += " - PR #$PullRequestNumber"
            }
            Invoke-SvgGit commit -m $commitMsg | Out-Host
        } elseif ($diffExitCode -ne 0) {
            throw "git diff failed with exit code $diffExitCode"
        }
        $svgCommitId = Invoke-SvgGit rev-parse HEAD
        Invoke-SvgGit push origin svg | Out-Host
        Write-Output "Pushed $($svgFiles.Count) SVG files to svg branch (commit: $svgCommitId)"
    } catch {
        $publishError = $_
        throw
    } finally {
        try {
            if (![string]::IsNullOrEmpty($restoreBranch)) {
                Invoke-SvgGit checkout $restoreBranch | Out-Host
            } else {
                Invoke-SvgGit checkout --detach $originalCommit | Out-Host
            }
        } catch {
            if ($publishError) {
                throw "SVG publishing failed: $publishError; checkout restoration also failed: $_"
            }
            throw
        }
    }

    # Build GitHub raw links for all SVGs using the same commit id
    foreach ($svg in $svgInfo) {
        if (![string]::IsNullOrEmpty($RepositoryName)) {
            $svgUrl = "https://github.com/$RepositoryName/blob/$svgCommitId/$($svg.File)?raw=true"
        } else {
            $svgUrl = "https://github.com/blob/$svgCommitId/$($svg.File)?raw=true"
        }
        $safeName = $svg.Name -replace '[^\w\s\-\.]', '_'
        $svgLinksMarkdown += "\n\n$safeName\n\n [![SVG]($svgUrl)]($svgUrl)"
    }
} else {
    Write-Output "No SVG files to process"
}

# Set outputs
$svgLinksEscaped = $svgLinksMarkdown -replace "`n", "%0A" -replace "`r", "%0D"
Write-Output "svgLinksMarkdown=$svgLinksEscaped" >> $env:GITHUB_OUTPUT
Write-Output "svgCount=$($svgFiles.Count)" >> $env:GITHUB_OUTPUT
