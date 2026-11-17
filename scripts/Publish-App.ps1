[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[a-z0-9]{20}$')]
    [string]$RegistryId,
    [ValidatePattern('^[a-zA-Z0-9][a-zA-Z0-9._-]{0,127}$')]
    [string]$Version = '0.1.0',
    [string]$LocalImage = 'diplom-app:0.1.0',
    [string]$YcPath = 'yc',
    [string]$YcConfig
)

$ErrorActionPreference = 'Stop'
$appRoot = Split-Path -Parent $PSScriptRoot
$authDirectory = Join-Path $appRoot ('.tools/docker-auth-' + [Guid]::NewGuid().ToString('N'))
$remoteImage = "cr.yandex/${RegistryId}/diplom-app:${Version}"
$ycArguments = @()
if ($YcConfig) { $ycArguments += @('--config', $YcConfig) }
$ycArguments += @('--no-browser', 'iam', 'create-token')

try {
    $token = & $YcPath @ycArguments
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($token)) {
        throw 'Could not obtain an IAM token. Check the yc service account profile.'
    }

    # Keep the existing Docker configuration and registry logins unchanged.
    $dockerEndpoint = & docker context inspect --format '{{.Endpoints.docker.Host}}'
    if ($LASTEXITCODE -ne 0) { throw 'Could not determine the Docker endpoint.' }
    New-Item -ItemType Directory -Path $authDirectory -Force | Out-Null
    [IO.File]::WriteAllText((Join-Path $authDirectory 'config.json'), '{}')
    $dockerArguments = @('--config', $authDirectory, '--host', $dockerEndpoint.Trim())

    $token.Trim() | & docker @dockerArguments login --username iam --password-stdin cr.yandex
    if ($LASTEXITCODE -ne 0) { throw 'Container Registry login failed.' }
    & docker @dockerArguments image tag $LocalImage $remoteImage
    if ($LASTEXITCODE -ne 0) { throw 'Could not tag the application image.' }
    & docker @dockerArguments image push $remoteImage
    if ($LASTEXITCODE -ne 0) { throw 'Image push failed.' }

    # Pull again to check registry access and record the immutable image reference.
    & docker @dockerArguments image pull --platform linux/amd64 $remoteImage
    if ($LASTEXITCODE -ne 0) { throw 'Registry pull verification failed.' }
    $digestJson = & docker @dockerArguments image inspect --format '{{json .RepoDigests}}' $remoteImage
    if ($LASTEXITCODE -ne 0) { throw 'Could not read the published image digest.' }
    $digests = @($digestJson | ConvertFrom-Json)
    $publishedDigest = @($digests | Where-Object { $_ -like "cr.yandex/${RegistryId}/diplom-app@sha256:*" })
    if ($publishedDigest.Count -ne 1) { throw 'Expected one published application digest.' }
    Write-Host "Published and pulled: $remoteImage"
    Write-Host "Immutable reference: $($publishedDigest[0])"
} finally {
    Remove-Variable token -ErrorAction SilentlyContinue
    $authFile = Join-Path $authDirectory 'config.json'
    if (Test-Path -LiteralPath $authFile) { Remove-Item -LiteralPath $authFile -Force }
    if (Test-Path -LiteralPath $authDirectory) { Remove-Item -LiteralPath $authDirectory -Force }
}
