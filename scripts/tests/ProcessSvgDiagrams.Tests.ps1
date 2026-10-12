param()

$ErrorActionPreference = 'Stop'
$scriptPath = Join-Path $PSScriptRoot '../ProcessSvgDiagrams.ps1'
$testRoot = Join-Path ([IO.Path]::GetTempPath()) "svg-tests-$([guid]::NewGuid())"
$previousOutput = $env:GITHUB_OUTPUT
$previousLocation = Get-Location

function Invoke-TestGit {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)
    $result = & git @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Test setup/check failed: git $($Arguments -join ' ')"
    }
    $result
}

function Assert-Equal {
    param($Actual, $Expected, [string]$Message)
    if ($Actual -ne $Expected) {
        throw "$Message - expected '$Expected', got '$Actual'"
    }
}

$cases = @(
    @{ Name = 'Detached, fresh SVG branch'; Detached = $true },
    @{ Name = 'Named branch, fresh SVG branch' },
    @{ Name = 'Detached, existing remote SVG branch'; Detached = $true; Existing = $true },
    @{ Name = 'Named branch, existing local SVG branch'; Existing = $true; Local = $true },
    @{ Name = 'Unchanged export'; Detached = $true; Existing = $true; Unchanged = $true },
    @{ Name = 'No diagrams'; Detached = $true; Empty = $true },
    @{ Name = 'No exportable diagrams'; Detached = $true; NoContent = $true },
    @{ Name = 'Explicit OriginalBranch'; Detached = $true; Override = 'main' },
    @{ Name = 'Invalid OriginalBranch'; Detached = $true; Override = 'missing'; Fails = $true },
    @{ Name = 'Malformed SVG'; Detached = $true; Malformed = $true; Fails = $true },
    @{ Name = 'Rejected push, detached HEAD'; Detached = $true; Reject = $true; Fails = $true },
    @{ Name = 'Rejected push, named branch'; Reject = $true; Fails = $true }
)

try {
    New-Item -ItemType Directory -Path $testRoot | Out-Null
    foreach ($case in $cases) {
        $caseRoot = Join-Path $testRoot ([guid]::NewGuid().ToString())
        $remote = Join-Path $caseRoot 'origin.git'
        $repo = Join-Path $caseRoot 'repo'
        New-Item -ItemType Directory -Path $caseRoot | Out-Null
        Invoke-TestGit init --bare $remote | Out-Null
        Invoke-TestGit init -b main $repo | Out-Null
        Set-Location $repo
        Invoke-TestGit config user.name 'SVG Tests' | Out-Null
        Invoke-TestGit config user.email 'svg-tests@example.invalid' | Out-Null
        Invoke-TestGit config core.autocrlf false | Out-Null
        Invoke-TestGit remote add origin $remote | Out-Null
        $manifest = Join-Path $repo '.github/actions/setup-lta/action.yml'
        New-Item -ItemType Directory -Path (Split-Path $manifest) -Force | Out-Null
        [IO.File]::WriteAllText($manifest, 'name: test manifest')
        [IO.File]::WriteAllText((Join-Path $repo 'original.svg'), '<svg>original</svg>')
        Invoke-TestGit add . | Out-Null
        Invoke-TestGit commit -m 'Original checkout' | Out-Null
        Invoke-TestGit push origin main | Out-Null
        $originalCommit = Invoke-TestGit rev-parse HEAD
        $svgContent = '<svg xmlns="http://www.w3.org/2000/svg"><text>diagram</text></svg>'
        $previousSvgCommit = $null

        if ($case.Existing) {
            Invoke-TestGit checkout --orphan svg | Out-Null
            Invoke-TestGit rm -rf . | Out-Null
            [IO.File]::WriteAllText((Join-Path $repo 'seed.svg'), '<svg>seed</svg>')
            if ($case.Unchanged) {
                Set-Content -LiteralPath 'diagram.svg' -Encoding UTF8 -Value $svgContent
            }
            Invoke-TestGit add . | Out-Null
            Invoke-TestGit commit -m 'Existing SVG history' | Out-Null
            Invoke-TestGit push origin svg | Out-Null
            $previousSvgCommit = Invoke-TestGit rev-parse HEAD
            Invoke-TestGit checkout main | Out-Null
            if (!$case.Local) {
                Invoke-TestGit branch -D svg | Out-Null
            }
        }
        if ($case.Detached) {
            Invoke-TestGit checkout --detach $originalCommit | Out-Null
        }
        if ($case.Reject) {
            [IO.File]::WriteAllText((Join-Path $remote 'hooks/pre-receive'), "#!/bin/sh`nexit 1`n")
        }

        $report = Join-Path $caseRoot 'DiffReport.xml'
        $document = [xml]'<report xmlns="http://www.lieberlieber.com"><diagramPictures /></report>'
        if (!$case.Empty) {
            $picture = $document.CreateElement('diagramPicture', $document.DocumentElement.NamespaceURI)
            $picture.SetAttribute('guid', '{diagram}')
            $image = $document.CreateElement('diagramPictureB', $document.DocumentElement.NamespaceURI)
            $image.SetAttribute('qualifiedName', 'Test diagram')
            if ($case.Malformed) {
                $image.InnerText = 'invalid base64!'
            } elseif (!$case.NoContent) {
                $image.InnerText = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($svgContent))
            }
            $picture.AppendChild($image) | Out-Null
            $document.DocumentElement.FirstChild.AppendChild($picture) | Out-Null
        }
        $document.Save($report)
        $env:GITHUB_OUTPUT = Join-Path $caseRoot 'outputs.txt'
        $arguments = @{
            DiffReportFilename = $report
            GitUserName = 'SVG Tests'
            GitUserEmail = 'svg-tests@example.invalid'
            PullRequestNumber = '145'
            RepositoryName = 'test/repo'
        }
        if ($case.Override) {
            $arguments.OriginalBranch = $case.Override
        }
        $failure = $null
        try {
            & $scriptPath @arguments | Out-Null
        } catch {
            $failure = $_
        }
        Assert-Equal ([bool]$failure) ([bool]$case.Fails) "$($case.Name): failure status ($failure)"
        Assert-Equal (Invoke-TestGit rev-parse HEAD) $originalCommit "$($case.Name): original commit"
        $expectedBranch = if ($case.Detached) { '' } else { 'main' }
        if ($case.Override -eq 'main') {
            $expectedBranch = 'main'
        }
        Assert-Equal ([string](Invoke-TestGit branch --show-current)) $expectedBranch "$($case.Name): checkout mode"
        Assert-Equal (Test-Path $manifest) $true "$($case.Name): local action manifest"
        Assert-Equal ([IO.File]::ReadAllText((Join-Path $repo 'original.svg'))) '<svg>original</svg>' "$($case.Name): original SVG"
        Assert-Equal ([string](Invoke-TestGit status --porcelain)) '' "$($case.Name): clean checkout"

        if ($case.Fails) {
            Assert-Equal (Test-Path $env:GITHUB_OUTPUT) $false "$($case.Name): no success outputs"
            if ($case.Reject -and $failure.ToString() -notmatch 'git push origin svg failed') {
                throw "Expected push failure, got: $failure"
            }
        } else {
            $outputs = Get-Content $env:GITHUB_OUTPUT -Raw
            $expectedCount = if ($case.Empty -or $case.NoContent) { 0 } else { 1 }
            if ($outputs -notmatch "svgCount=$expectedCount") {
                throw "$($case.Name): incorrect diagram count"
            }
            if ($expectedCount -gt 0) {
                $publishedCommit = Invoke-TestGit --git-dir=$remote rev-parse refs/heads/svg
                if ($outputs -notmatch [regex]::Escape("blob/$publishedCommit/diagram.svg?raw=true")) {
                    throw "$($case.Name): incorrect published SVG link"
                }
                Assert-Equal ([string](Invoke-TestGit --git-dir=$remote show "${publishedCommit}:diagram.svg")) $svgContent "$($case.Name): published SVG"
                if ($case.Existing) {
                    Invoke-TestGit --git-dir=$remote merge-base --is-ancestor $previousSvgCommit $publishedCommit
                    Assert-Equal ([string](Invoke-TestGit --git-dir=$remote show "${publishedCommit}:seed.svg")) '<svg>seed</svg>' "$($case.Name): existing SVG"
                }
                if ($case.Unchanged) {
                    Assert-Equal $publishedCommit $previousSvgCommit "$($case.Name): no unnecessary commit"
                }
            } else {
                Assert-Equal ([string](Invoke-TestGit branch --list svg)) '' "$($case.Name): no branch mutation"
            }
        }
        Write-Output "PASS: $($case.Name)"
    }
    Write-Output "PASS: All $($cases.Count) SVG publishing regression cases"
} finally {
    Set-Location $previousLocation
    $env:GITHUB_OUTPUT = $previousOutput
    Remove-Item -LiteralPath $testRoot -Recurse -Force -ErrorAction SilentlyContinue
}