[CmdletBinding()]
param(
    [string]$Image = 'diplom-app:0.1.0',
    [int]$Port = 18080,
    [string]$ExpectedVersion = '0.1.0'
)

$ErrorActionPreference = 'Stop'
$containerName = 'diplom-app-test-' + [Guid]::NewGuid().ToString('N').Substring(0, 10)
$started = $false

try {
    $runOutput = & docker run --detach --name $containerName `
        --read-only --tmpfs /tmp:rw,noexec,nosuid,size=16m `
        --cap-drop ALL --security-opt no-new-privileges:true `
        --publish "127.0.0.1:${Port}:8080" $Image
    if ($LASTEXITCODE -ne 0) { throw 'Could not start the test container.' }
    $started = $true

    $baseUrl = "http://127.0.0.1:$Port"
    $ready = $false
    for ($attempt = 0; $attempt -lt 20; $attempt++) {
        try {
            $health = Invoke-WebRequest "$baseUrl/healthz" -UseBasicParsing -TimeoutSec 2
            if ($health.StatusCode -eq 200 -and $health.Content.Trim() -eq 'ok') {
                $ready = $true
                break
            }
        } catch { Start-Sleep -Milliseconds 500 }
    }
    if (-not $ready) { throw 'The health endpoint did not become ready.' }
    Write-Host 'PASS /healthz: HTTP 200, ok'

    $page = Invoke-WebRequest $baseUrl -UseBasicParsing -TimeoutSec 5
    if ($page.StatusCode -ne 200 -or $page.Content -notmatch '<title>Diplom') {
        throw 'The application page was not served.'
    }
    Write-Host 'PASS /: application HTML served'

    foreach ($asset in @('style.css', 'app.js')) {
        $response = Invoke-WebRequest "$baseUrl/$asset" -UseBasicParsing -TimeoutSec 5
        if ($response.StatusCode -ne 200) { throw "Asset failed: $asset" }
    }
    Write-Host 'PASS static CSS and JavaScript'

    $metadata = Invoke-RestMethod "$baseUrl/version.json" -TimeoutSec 5
    if ($metadata.version -ne $ExpectedVersion -or -not $metadata.revision -or -not $metadata.built_at) {
        throw 'Build metadata does not match the expected version.'
    }
    Write-Host "PASS /version.json: $($metadata.version), revision $($metadata.revision)"

    $missingStatus = & curl.exe --silent --output NUL --write-out '%{http_code}' "$baseUrl/missing-page"
    if ($LASTEXITCODE -ne 0 -or $missingStatus -ne '404') { throw 'Expected HTTP 404 for a missing page.' }
    Write-Host 'PASS missing page: HTTP 404'

    & docker exec $containerName nginx -t
    if ($LASTEXITCODE -ne 0) { throw 'nginx configuration check failed.' }
    $userId = & docker exec $containerName id -u
    if ($LASTEXITCODE -ne 0 -or $userId -eq '0') { throw 'The container must run without root.' }
    Write-Host "PASS nginx configuration; user UID=$userId; read-only filesystem"
    Write-Host 'All smoke checks passed.'
} catch {
    if ($started) { & docker logs $containerName }
    throw
} finally {
    if ($started) {
        & docker rm --force $containerName | Out-Null
    }
}
