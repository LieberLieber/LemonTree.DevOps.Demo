# Deletes Diagram Images from the model database

$scriptPath = Join-Path $PSScriptRoot 'QueryModelSqliteExe.ps1'
$defaultModel = "C:\PCS\LemonTree.Devops.Demo\LemonTree.DevOps.Demo.qeax"
$deleteQuery = "DELETE from t_document where t_document.DocName = 'DIAGRAMIMAGEMAP';"

& $scriptPath -Model $defaultModel -Query $deleteQuery
