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

# Store current branch name before switching to svg branch
if ([string]::IsNullOrEmpty($OriginalBranch)) {
    $originalBranch = git branch --show-current
} else {
    $originalBranch = $OriginalBranch
}
Write-Output "Current branch: $originalBranch"

# Configure git user for commits
git config user.name $GitUserName
git config user.email $GitUserEmail

# Checkout svg branch before writing SVG files
git fetch origin
if (-not (git branch --list svg)) {
    git checkout --orphan svg
    git rm -rf .
} else {
    git checkout svg
}
git pull origin svg || Write-Host "svg branch does not exist remotely yet."

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
            $cdata_b | %{[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($_))}|Set-Content -Encoding UTF8 -Path $filename
            $svgFiles += $filename
            $svgInfo += @{ Name = $qualifiedName; File = $filename }
        }
    }
}

# Commit all SVGs together to orphan branch 'svg'
if ($svgFiles.Count -gt 0) {
    git add *.svg
    $commitMsg = "Add SVG files for diagrams"
    if (![string]::IsNullOrEmpty($PullRequestNumber)) {
        $commitMsg += " - PR #$PullRequestNumber"
    }
    git commit -m $commitMsg
    $svgCommitId = git rev-parse HEAD
    git push origin svg

    Write-Output "Pushed $($svgFiles.Count) SVG files to svg branch (commit: $svgCommitId)"

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

# Return to the original branch
if (![string]::IsNullOrEmpty($originalBranch)) {
    Write-Output "Returning to original branch: $originalBranch"
    git checkout $originalBranch
    
    if (Test-Path "*.svg") {
        Remove-Item "*.svg" -Force
        Write-Output "Cleaned up SVG files from main branch"
    }
}

# Set outputs
$svgLinksEscaped = $svgLinksMarkdown -replace "`n", "%0A" -replace "`r", "%0D"
Write-Output "svgLinksMarkdown=$svgLinksEscaped" >> $env:GITHUB_OUTPUT
Write-Output "svgCount=$($svgFiles.Count)" >> $env:GITHUB_OUTPUT
