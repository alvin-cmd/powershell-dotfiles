[CmdletBinding()]
param(
    [switch]$Force,
    [switch]$Larp
)

$ErrorActionPreference = 'Stop'
$repoRoot = $PSScriptRoot
$fastfetchConfig = if ($Larp) { 'larp.jsonc' } else { 'config.jsonc' }
$links = @{
    (Join-Path $repoRoot 'PowerShell\Microsoft.PowerShell_profile.ps1') = $PROFILE.CurrentUserCurrentHost
    (Join-Path $repoRoot ".config\fastfetch\$fastfetchConfig") = (Join-Path $HOME '.config\fastfetch\config.jsonc')
    (Join-Path $repoRoot '.config\fastfetch\earth.txt') = (Join-Path $HOME '.config\fastfetch\earth.txt')
    (Join-Path $repoRoot '.config\oh-my-posh\star.omp.json') = (Join-Path $HOME '.config\oh-my-posh\star.omp.json')
}

foreach ($source in $links.Keys) {
    $destination = $links[$source]
    $destinationDirectory = Split-Path -Parent $destination
    New-Item -ItemType Directory -Force -Path $destinationDirectory | Out-Null

    if (Test-Path -LiteralPath $destination) {
        $item = Get-Item -LiteralPath $destination -Force
        if ($item.LinkType -and $item.Target -eq $source) {
            Write-Host "Linked: $destination"
            continue
        }
        if (-not $Force) {
            Write-Warning "Skipped existing file: $destination (run with -Force to replace it)"
            continue
        }
        $backup = "$destination.bak.$(Get-Date -Format 'yyyyMMddHHmmss')"
        Move-Item -LiteralPath $destination -Destination $backup
        Write-Host "Backed up: $backup"
    }

    New-Item -ItemType HardLink -Path $destination -Target $source | Out-Null
    Write-Host "Linked: $destination"
}
