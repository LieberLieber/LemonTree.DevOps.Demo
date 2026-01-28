#rough script for testing - no checks no nothing
if (-not (Test-Path .\LemonTree.Pipeline.Tools.ModelCheck.exe)) {
    Invoke-WebRequest -URI "https://nexus.lieberlieber.com/repository/lemontree-pipeline-tools/LemonTree.Pipeline.Tools.ModelCheck.exe" -OutFile ./LemonTree.Pipeline.Tools.ModelCheck.exe
}
& .\LemonTree.Pipeline.Tools.ModelCheck.exe --model "./LemonTree.DevOps.Demo.qeax" --out ".\output.md" --ChecksConfig ".\checks-config.json" --NoCompact