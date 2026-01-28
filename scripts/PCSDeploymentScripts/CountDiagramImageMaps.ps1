# Copyright (c) LieberLieber Software GmbH
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

# Calls QueryModel.ps1 with the provided SELECT statement

$scriptPath = Join-Path $PSScriptRoot 'QueryModelSqliteExe.ps1'
$defaultModel = "C:\PCS\LemonTree.Devops.Demo\LemonTree.DevOps.Demo.qeax"
$selectQuery = "Select Count(*) as NumberOfDiagrams from t_document where t_document.DocName = 'DIAGRAMIMAGEMAP';"

& $scriptPath -Model $defaultModel -Query $selectQuery
