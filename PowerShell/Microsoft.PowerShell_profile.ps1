# PowerShell setup.
$configRoot = Join-Path $HOME ".config"
$themePath = Join-Path $configRoot "oh-my-posh\star.omp.json"
if ((Get-Command oh-my-posh -ErrorAction SilentlyContinue) -and (Test-Path $themePath)) {
    oh-my-posh init pwsh --config $themePath | Invoke-Expression
}

try {
    [Console]::InputEncoding = [System.Text.Encoding]::UTF8
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.UTF8Encoding]::new($false)
    chcp 65001 > $null
}
catch {}

# Tell Windows Terminal the current directory so duplicated panes inherit it.
if ($env:WT_SESSION -and (Test-Path Function:\prompt)) {
    $global:__OriginalPrompt = $function:prompt
    function global:prompt {
        $location = $executionContext.SessionState.Path.CurrentLocation
        [Console]::Write("`e]9;9;$location`e\\")
        & $global:__OriginalPrompt
    }
}

if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { zoxide init powershell | Out-String })
}

# Prefer the newest Python installed by uv when one is available.
$uvPythonRoot = Join-Path $env:APPDATA "uv\python"
if (Test-Path $uvPythonRoot) {
    $latestPython = Get-ChildItem $uvPythonRoot -Directory |
        Where-Object { $_.Name -match 'cpython-(\d+\.\d+\.\d+)' } |
        Sort-Object { [version]($_.Name -replace '^cpython-(\d+\.\d+\.\d+).*', '$1') } -Descending |
        Select-Object -First 1
    if ($latestPython) {
        $env:PATH = "$($latestPython.FullName);$($latestPython.FullName)\Scripts;$env:PATH"
    }
}

if (Get-Command python -ErrorAction SilentlyContinue) {
    Set-Alias py python
}

if ($env:WT_SESSION) {
    Clear-Host
}
if (Get-Command fastfetch -ErrorAction SilentlyContinue) {
    fastfetch --config (Join-Path $configRoot "fastfetch\config.jsonc")
}

function venv {
    & "$PWD\.venv\Scripts\Activate.ps1"
}

$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path $ChocolateyProfile) {
    Import-Module $ChocolateyProfile
}

if (Get-Command uv -ErrorAction SilentlyContinue) {
    uv generate-shell-completion powershell | Out-String | Invoke-Expression
}
if (Get-Command uvx -ErrorAction SilentlyContinue) {
    uvx --generate-shell-completion powershell | Out-String | Invoke-Expression
}
