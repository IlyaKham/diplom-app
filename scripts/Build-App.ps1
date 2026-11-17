[CmdletBinding()]
param(
    [string]$Image = 'diplom-app:0.1.0',
    [ValidatePattern('^[a-zA-Z0-9][a-zA-Z0-9._+-]*$')]
    [string]$Version = '0.1.0',
    [ValidatePattern('^[a-zA-Z0-9][a-zA-Z0-9._-]*$')]
    [string]$Revision = 'local'
)

$ErrorActionPreference = 'Stop'
$appRoot = Split-Path -Parent $PSScriptRoot
$buildDate = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ')

& docker build --pull --platform linux/amd64 --tag $Image `
    --build-arg "APP_VERSION=$Version" --build-arg "VCS_REF=$Revision" `
    --build-arg "BUILD_DATE=$buildDate" $appRoot
if ($LASTEXITCODE -ne 0) { throw 'Docker build failed.' }
Write-Host "Built $Image"
