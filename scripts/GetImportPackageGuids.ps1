# Copyright (c) LieberLieber Software GmbH
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

<#
.SYNOPSIS
    Retrieves all import package GUIDs from a LemonTree model file.

.DESCRIPTION
    Queries the SQLite database embedded in a LemonTree model (.qeax) file
    and returns all GUIDs of packages configured for import to EA.

.PARAMETER Model
    The path to the LemonTree model file (.qeax).

.EXAMPLE
    .\GetImportPackageGuids.ps1 -Model "LemonTree.DevOps.Demo.qeax"
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$Model
)

# Validate that the model file exists
if (-not (Test-Path $Model)) {
    Write-Error "Model file not found: $Model"
    exit 1
}

# SQL query to get all package GUIDs with direction set to "ToEa"
$query = @"
select ea_guid as importPackageGuids from t_object
where object_id in (select object_id from t_objectproperties where property = 'direction' and [value] = 'ToEa')
"@

try {
    # Execute the query using the QueryModelSqliteExe wrapper
    $result = & .\scripts\QueryModelSqliteExe.ps1 -Model $Model -Query $query
    
    # Parse and output the results
    $guids = @()
    foreach ($line in $result) {
        if (-not [string]::IsNullOrWhiteSpace($line)) {
            $guids += $line.Trim()
        }
    }
    
    if ($guids.Count -eq 0) {
        Write-Output "No import package GUIDs found."
    } else {
        Write-Output "Found $($guids.Count) import package GUID(s):"
        $guids | ForEach-Object { Write-Output $_ }
    }
    
    # Also return the array for programmatic use
    return $guids
}
catch {
    Write-Error "Error querying model: $_"
    exit 1
}
