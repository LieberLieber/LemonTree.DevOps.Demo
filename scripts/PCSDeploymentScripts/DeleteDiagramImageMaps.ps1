# Copyright (c) LieberLieber Software GmbH
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

# Deletes Diagram Images from the model database

$scriptPath = Join-Path $PSScriptRoot 'QueryModelSqliteExe.ps1'
$defaultModel = "C:\PCS\LemonTree.Devops.Demo\LemonTree.DevOps.Demo.qeax"
$deleteQuery = "DELETE from t_document where t_document.DocName = 'DIAGRAMIMAGEMAP';"

& $scriptPath -Model $defaultModel -Query $deleteQuery
