# Copyright (c) LieberLieber Software GmbH
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

<#
.SYNOPSIS
    Copies Enterprise Architect model to PCS with connection management

.DESCRIPTION
    This script disables the PCS connection, copies the model file to the PCS directory,
    and then re-enables the PCS connection.

.PARAMETER SourceModel
    Path to the source .qeax model file

.PARAMETER DestinationPath
    Path to the destination PCS directory

.PARAMETER PCSUri
    URI of the PCS server (default: http://localhost:1804/)

.PARAMETER DatabaseManager
    Database Manager connection string (e.g., ssdb:anonymous@c:\pcs\models\lemontree.devops.demo\lemontree.devops.demo.qeax)

.PARAMETER PCSPassword
    Password for PCS authentication

.PARAMETER ToolPCStoggle
    Path to the PCS Toggle tool executable
#>

param(
    [string]$SourceModel = "LemonTree.DevOps.Demo.qeax",
    [string]$DestinationPath = "C:\PCS\LemonTree.Devops.Demo\LemonTree.DevOps.Demo.qeax",
    [string]$PCSUri = "http://localhost:1804/",
    [string]$DatabaseManager = "ssdb:anonymous@c:\pcs\lemontree.devops.demo\lemontree.devops.demo.qeax",
    [string]$PCSPassword,
    [string]$ToolPCStoggle = ".\LieberLieber.Pipeline.Tools.PCS.Toggle.exe"
)

# Function to download PCS Toggle tool if not present
function Get-PCSToggleTool {
    param([string]$ToolPath)
    
    if (-not (Test-Path $ToolPath)) {
        Write-Host "Downloading PCS Toggle Tool..." -ForegroundColor Cyan
        while (Test-Path Alias:curl) { Remove-Item Alias:curl } # Remove the alias binding from curl to Invoke-WebRequest
        curl "https://nexus.lieberlieber.com/repository/lemontree-pipeline-tools/LieberLieber.Pipeline.Tools.PCS.Toggle.exe" --output "$ToolPath" -k
        Write-Host "Download complete." -ForegroundColor Green
    }
}

# Function to check PCS status
function Get-PCSStatus {
    param(
        [string]$Tool,
        [string]$Uri,
        # Not using SecureString here for simplicity; in production, consider using SecureString
        [String]$Password,
        [string]$DbManager
    )
    
    Write-Host "Checking PCS status for: $DbManager" -ForegroundColor Cyan
    & $Tool Status --uri $Uri --Password $Password --DatabaseManager $DbManager | Out-Null
    
    switch ($LASTEXITCODE) {
        1 {
            Write-Host "DatabaseManager exists and is offline." -ForegroundColor Yellow
            return "offline"
        }
        0 {
            Write-Host "DatabaseManager exists and is online." -ForegroundColor Green
            return "online"
        }
        -3 {
            Write-Host "DatabaseManager doesn't exist!" -ForegroundColor Red
            return "not-exists"
        }
        -2 {
            Write-Host "Authentication failed! Invalid password." -ForegroundColor Red
            return "auth-failed"
        }
        default {
            Write-Host "Unknown exit code: $LASTEXITCODE" -ForegroundColor Red
            return "unknown"
        }
    }
}

# Main script execution
try {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "LemonTree Model Copy to PCS" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    # Validate source file exists
    if (-not (Test-Path $SourceModel)) {
        throw "Source model file not found: $SourceModel"
    }

    # Download PCS Toggle tool if needed
    Get-PCSToggleTool -ToolPath $ToolPCStoggle

    # Prompt for password if not provided
    if ([string]::IsNullOrEmpty($PCSPassword)) {
        Write-Host "PCS password is required." -ForegroundColor Yellow
        $securePassword = Read-Host "Please enter PCS password" -AsSecureString
        $PCSPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
        )
    }

    # Step 1: Validate authentication with PCS
    Write-Host "`nStep 1: Validating PCS authentication..." -ForegroundColor Cyan
    $status = Get-PCSStatus -Tool $ToolPCStoggle -Uri $PCSUri -Password $PCSPassword -DbManager $DatabaseManager
    
    if ($status -eq "auth-failed") {
        throw "Authentication failed! Invalid PCS password. Cannot proceed."
    }
    
    if ($status -eq "not-exists") {
        throw "PCS DatabaseManager doesn't exist. Cannot proceed."
    }
    
    if ($status -eq "unknown") {
        throw "Failed to validate PCS connection. Cannot proceed."
    }
    
    Write-Host "Authentication successful!" -ForegroundColor Green

    # Step 2: Disable PCS DatabaseManager
    Write-Host "`nStep 2: Disabling PCS DatabaseManager..." -ForegroundColor Cyan
    & $ToolPCStoggle Disable --uri $PCSUri --Password $PCSPassword --DatabaseManager $DatabaseManager | Out-Null
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Warning: Disable command returned exit code $LASTEXITCODE" -ForegroundColor Yellow
    } else {
        Write-Host "PCS DatabaseManager disabled successfully." -ForegroundColor Green
    }

    # Step 3: Copy model to PCS
    Write-Host "`nStep 3: Copying model to PCS directory..." -ForegroundColor Cyan
    
    # Create directory structure if it doesn't exist
    $destinationDir = Split-Path -Parent $DestinationPath
    if (-not (Test-Path $destinationDir)) {
        Write-Host "Creating directory: $destinationDir" -ForegroundColor Yellow
        New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
    }
    
    # Copy the file
    Copy-Item $SourceModel -Destination $DestinationPath -Force
    Write-Host "Model copied successfully to: $DestinationPath" -ForegroundColor Green

    # Step 4: Enable PCS DatabaseManager
    Write-Host "`nStep 4: Enabling PCS DatabaseManager..." -ForegroundColor Cyan
    & $ToolPCStoggle Enable --uri $PCSUri --Password $PCSPassword --DatabaseManager $DatabaseManager | Out-Null
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Warning: Enable command returned exit code $LASTEXITCODE" -ForegroundColor Yellow
    } else {
        Write-Host "PCS DatabaseManager enabled successfully." -ForegroundColor Green
    }

    Write-Host "`n========================================" -ForegroundColor Green
    Write-Host "Operation completed successfully!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
}
catch {
    Write-Host "`n========================================" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    
    # Attempt to re-enable PCS connection if it was disabled
    Write-Host "`nAttempting to re-enable PCS DatabaseManager..." -ForegroundColor Yellow
    & $ToolPCStoggle Enable --uri $PCSUri --Password $PCSPassword --DatabaseManager $DatabaseManager | Out-Null
    
    exit 1
}
