# =============================================================================
# setup-claude-plugins.ps1
#
# Cowork プラグインを Windows 環境用に設定する PowerShell スクリプト
#
# 使い方（PowerShell から）:
#   powershell -ExecutionPolicy Bypass -File "C:\Users\tomoh\Dropbox\Cursor\cowork\cowork_plugin\setup-claude-plugins.ps1"
#
# または PowerShell を管理者で開いて:
#   Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
#   & "C:\Users\...\setup-claude-plugins.ps1"
#
# 何をするか:
#   - Dropbox の cowork_plugin を installPath として
#     %USERPROFILE%\.claude\plugins\installed_plugins.json を生成する
# =============================================================================

$ErrorActionPreference = "Stop"

# UTF-8 output (fixes garbled Japanese on some terminals)
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding           = [System.Text.Encoding]::UTF8

# ─────────────────────────────────────────────────────────────────────────────
# Path config
# ─────────────────────────────────────────────────────────────────────────────
$ScriptDir    = Split-Path -Parent $MyInvocation.MyCommand.Path  # = cowork_plugin dir
$PluginsDir   = $ScriptDir
$ClaudeDir    = "$env:USERPROFILE\.claude"
$OutputPath   = "$ClaudeDir\plugins\installed_plugins.json"
$Now          = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss.000Z")

Write-Host "[ENV]     Windows (PowerShell)" -ForegroundColor Cyan
Write-Host "[PLUGINS] $PluginsDir"
Write-Host "[CLAUDE]  $ClaudeDir"
Write-Host ""

# ─────────────────────────────────────────────────────────────────────────────
# プラグインディレクトリの確認
# ─────────────────────────────────────────────────────────────────────────────
if (-not (Test-Path $PluginsDir)) {
    Write-Host "[ERROR] Plugin directory not found: $PluginsDir" -ForegroundColor Red
    exit 1
}

# ─────────────────────────────────────────────────────────────────────────────
# Generate installed_plugins.json
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "--- Generating installed_plugins.json ---"

$plugins = @{}

# cowork_plugin/ 配下のサブディレクトリをスキャン
Get-ChildItem -Path $PluginsDir -Directory | Sort-Object Name | ForEach-Object {
    $name      = $_.Name
    $pluginDir = $_.FullName
    $metaPath  = Join-Path $pluginDir ".claude-plugin\plugin.json"

    if (-not (Test-Path $metaPath)) { return }

    $metaContent = [System.IO.File]::ReadAllText($metaPath, [System.Text.Encoding]::UTF8)
    $meta    = $metaContent | ConvertFrom-Json
    $version = if ($meta.version) { $meta.version } else { "1.0.0" }
    $key     = "${name}@cowork-plugins-marketplace"

    $plugins[$key] = @(
        [ordered]@{
            scope       = "user"
            installPath = $pluginDir
            version     = $version
            installedAt = $Now
            lastUpdated = $Now
        }
    )

    Write-Host "  [OK] $name (v$version)"
    Write-Host "       -> $pluginDir"
}

$result = [ordered]@{
    version = 2
    plugins = $plugins
}

# 出力ディレクトリを作成
$outDir = Split-Path -Parent $OutputPath
if (-not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

# JSON として書き出し (UTF8 BOM なし)
$json = $result | ConvertTo-Json -Depth 10
[System.IO.File]::WriteAllText($OutputPath, $json, [System.Text.Encoding]::UTF8)

Write-Host ""
Write-Host "[DONE] Saved: $OutputPath"
Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "Setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Restart Claude Code"
Write-Host "  2. Verify skills: /list-plugins"
Write-Host ""
Write-Host "Re-run after adding/updating plugins:"
Write-Host "  powershell -ExecutionPolicy Bypass -File `"$ScriptDir\setup-claude-plugins.ps1`""
Write-Host "==========================================" -ForegroundColor Green
