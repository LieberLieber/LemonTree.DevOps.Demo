# Calls QueryModel.ps1 with the provided SELECT statement

$scriptPath = Join-Path $PSScriptRoot 'QueryModelSqliteExe.ps1'
$defaultModel = "C:\PCS\LemonTree.Devops.Demo\LemonTree.DevOps.Demo.qeax"
$selectQuery = "Select Count(*) as NumberOfDiagrams from t_document where t_document.DocName = 'DIAGRAMIMAGEMAP';"

& $scriptPath -Model $defaultModel -Query $selectQuery
