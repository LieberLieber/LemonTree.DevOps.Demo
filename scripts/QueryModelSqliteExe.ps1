<#
.SYNOPSIS
    Runs a SQL query against a SQLite database (.qeax file) using sqlite3.exe.

.PARAMETER Model
    Path to the SQLite database file (.qeax).

.PARAMETER Query
    The SQL query to execute.

.EXAMPLE
    .\QueryModelSqliteExe.ps1 -Query "SELECT name FROM sqlite_master;"
#>

param(
    [string]$Model = "C:\PCS\LemonTree.Devops.Demo\LemonTree.DevOps.Demo.qeax",
    [string]$Query = "SELECT name FROM sqlite_master;"
)

# Ensure sqlite3.exe is available
$sqliteExe = "sqlite3.exe"
$wingetId = "SQLite.sqlite"

function Install-SqliteExe {
    if (-not (Get-Command $sqliteExe -ErrorAction SilentlyContinue)) {
        Write-Host "[INFO] Installing sqlite3 using winget..." -ForegroundColor Yellow
        winget install -e --id SQLite.SQLite
        if (-not (Get-Command $sqliteExe -ErrorAction SilentlyContinue)) {
            Write-Host "[ERROR] sqlite3.exe not found after install. Please install manually." -ForegroundColor Red
            exit 1
        }
        Write-Host "[INFO] sqlite3.exe installed." -ForegroundColor Green
    } else {
        Write-Host "[INFO] sqlite3.exe found." -ForegroundColor Green
    }
}

Install-SqliteExe

# Run the query
Write-Host "[INFO] Running query against $Model..." -ForegroundColor Cyan
Write-Host "[INFO] Executing: sqlite3.exe `"$Model`" `"$Query`"" -ForegroundColor Gray

try {
    $output = & $sqliteExe "$Model" "$Query"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] sqlite3.exe returned exit code $LASTEXITCODE" -ForegroundColor Red
        exit $LASTEXITCODE
    }
    Write-Host "[RESULT]" -ForegroundColor Green
    Write-Output $output
} catch {
    Write-Host "[ERROR] Exception running sqlite3.exe: $_" -ForegroundColor Red
    exit 1
}
