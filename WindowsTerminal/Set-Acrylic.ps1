[CmdletBinding()]
param(
    [string]$SettingsPath
)

$ErrorActionPreference = 'Stop'

if (-not $SettingsPath) {
    $settingsPath = @(
        (Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'),
        (Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json')
    ) | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
}

if (-not $SettingsPath -or -not (Test-Path -LiteralPath $SettingsPath)) {
    Write-Warning 'Windows Terminal settings were not found. Open Windows Terminal once, then rerun install.ps1.'
    return
}

$documentOptions = [System.Text.Json.JsonDocumentOptions]::new()
$documentOptions.CommentHandling = [System.Text.Json.JsonCommentHandling]::Skip
$documentOptions.AllowTrailingCommas = $true
$settings = [System.Text.Json.Nodes.JsonNode]::Parse((Get-Content -Raw -LiteralPath $SettingsPath), $null, $documentOptions)
if ($settings -isnot [System.Text.Json.Nodes.JsonObject]) {
    throw "Windows Terminal settings are not a JSON object: $SettingsPath"
}

$profiles = $settings['profiles']
if ($profiles -isnot [System.Text.Json.Nodes.JsonObject]) {
    $profiles = [System.Text.Json.Nodes.JsonObject]::new()
    $settings['profiles'] = $profiles
}

$defaults = $profiles['defaults']
if ($defaults -isnot [System.Text.Json.Nodes.JsonObject]) {
    $defaults = [System.Text.Json.Nodes.JsonObject]::new()
    $profiles['defaults'] = $defaults
}

$isConfigured = $defaults['opacity'] -and $defaults['opacity'].ToJsonString() -eq '85' -and
    $defaults['useAcrylic'] -and $defaults['useAcrylic'].ToJsonString() -eq 'true'
if ($isConfigured) {
    Write-Host "Windows Terminal acrylic already configured: $SettingsPath"
    return
}

$backup = "$SettingsPath.bak.$(Get-Date -Format 'yyyyMMddHHmmss')"
Copy-Item -LiteralPath $SettingsPath -Destination $backup
$defaults['opacity'] = 85
$defaults['useAcrylic'] = $true

$serializerOptions = [System.Text.Json.JsonSerializerOptions]::new()
$serializerOptions.WriteIndented = $true
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
[System.IO.File]::WriteAllText($SettingsPath, $settings.ToJsonString($serializerOptions) + [Environment]::NewLine, $utf8NoBom)
Write-Host "Enabled Windows Terminal acrylic: $SettingsPath"
