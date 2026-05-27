param(
    [string]$PubspecPath = "app/pubspec.yaml",
    [string]$AppSettingsPath = "src/Conscia.Api/appsettings.json",
    [string]$DevelopmentAppSettingsPath = "src/Conscia.Api/appsettings.Development.json",
    [string]$AppCompatibilityOptionsPath = "src/Conscia.Api/Versioning/AppCompatibilityOptions.cs",
    [string]$ReleaseMatrixPath = "release-matrix.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-AppBuildVersion {
    param([string]$Path)

    $match = Select-String -Path $Path -Pattern '^version:\s*(?<version>\S+)\s*$' | Select-Object -First 1
    if ($null -eq $match) {
        throw "Could not find an app version in '$Path'."
    }

    return $match.Matches[0].Groups['version'].Value
}

function Update-AppCompatibilityFile {
    param(
        [string]$Path,
        [string]$CurrentAppVersion
    )

    $json = Get-Content $Path -Raw | ConvertFrom-Json
    $existingCurrent = [string]$json.AppCompatibility.CurrentSupportedAppVersion
    $existingPrevious = [string]$json.AppCompatibility.PreviousSupportedAppVersion

    if ($existingCurrent -ne $CurrentAppVersion) {
        $json.AppCompatibility.PreviousSupportedAppVersion = $existingCurrent
        $json.AppCompatibility.CurrentSupportedAppVersion = $CurrentAppVersion
    } elseif ([string]::IsNullOrWhiteSpace($existingPrevious)) {
        $json.AppCompatibility.PreviousSupportedAppVersion = $existingCurrent
    }

    $json | ConvertTo-Json -Depth 32 | Set-Content $Path

    return @{
        Current = [string]$json.AppCompatibility.CurrentSupportedAppVersion
        Previous = [string]$json.AppCompatibility.PreviousSupportedAppVersion
    }
}

function Update-ReleaseMatrix {
    param(
        [string]$Path,
        [string]$CurrentAppVersion,
        [string]$PreviousAppVersion
    )

    $content = Get-Content $Path -Raw

    $compatibilityPattern = '\| `v=1` \| `[^`]+` \| `[^`]+` \|'
    $compatibilityReplacement = "| ``v=1`` | ``$CurrentAppVersion`` | ``$PreviousAppVersion`` |"
    $updated = [regex]::Replace($content, $compatibilityPattern, $compatibilityReplacement, 1)

    $versionHistoryPattern = '\| \d{4}-\d{2}-\d{2} \| [^|]+ \| [^|]+ \| [^|]+ \| [^|]+ \|'
    $versionHistoryReplacement = "| $(Get-Date -Format 'yyyy-MM-dd') | 1.0.0 | $CurrentAppVersion | 1.0.0 | 1.0.0 |"
    $updated = [regex]::Replace($updated, $versionHistoryPattern, $versionHistoryReplacement, 1)

    Set-Content $Path $updated
}

function Update-AppCompatibilityOptionsSource {
    param(
        [string]$Path,
        [string]$CurrentAppVersion,
        [string]$PreviousAppVersion
    )

    $content = Get-Content $Path -Raw
    $content = [regex]::Replace(
        $content,
        'CurrentSupportedAppVersion \{ get; set; \} = "[^"]+";',
        "CurrentSupportedAppVersion { get; set; } = `"$CurrentAppVersion`";",
        1
    )
    $content = [regex]::Replace(
        $content,
        'PreviousSupportedAppVersion \{ get; set; \} = "[^"]+";',
        "PreviousSupportedAppVersion { get; set; } = `"$PreviousAppVersion`";",
        1
    )

    Set-Content $Path $content
}

$appBuildVersion = Get-AppBuildVersion -Path $PubspecPath
$appSettings = Update-AppCompatibilityFile -Path $AppSettingsPath -CurrentAppVersion $appBuildVersion
Update-AppCompatibilityFile -Path $DevelopmentAppSettingsPath -CurrentAppVersion $appBuildVersion | Out-Null
if (Test-Path $ReleaseMatrixPath) {
    Update-ReleaseMatrix -Path $ReleaseMatrixPath -CurrentAppVersion $appSettings.Current -PreviousAppVersion $appSettings.Previous
}
Update-AppCompatibilityOptionsSource -Path $AppCompatibilityOptionsPath -CurrentAppVersion $appSettings.Current -PreviousAppVersion $appSettings.Previous

Write-Host "Updated app compatibility metadata to current=$($appSettings.Current) previous=$($appSettings.Previous)"
