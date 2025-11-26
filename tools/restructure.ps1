param(
    [string]$Root = (Resolve-Path "$PSScriptRoot\.."),
    [switch]$ExecuteRemoval
)

$src = Join-Path $Root 'src'
$cleanSrc = Join-Path $Root 'clean-src'

Write-Host "Source root:" $src
Write-Host "Clean tree:" $cleanSrc

# Define which folders feed each modern target
$map = @{
    Core   = @('ProxyDll', '_Shared')
    UI     = @('ClickerDll')
    Loader = @('LordOfMU', 'InjectorTest')
}

# Recreate clean layout
Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $cleanSrc
foreach ($bucket in $map.Keys) {
    New-Item -ItemType Directory -Force -Path (Join-Path $cleanSrc $bucket) | Out-Null
}

# Copy sources into the new layout
foreach ($bucket in $map.GetEnumerator()) {
    foreach ($folder in $bucket.Value) {
        $sourcePath = Join-Path $src $folder
        if (Test-Path $sourcePath) {
            Copy-Item -Path (Join-Path $sourcePath '*') -Destination (Join-Path $cleanSrc $bucket.Key) -Recurse -Force
        }
    }
}

# Optional: purge legacy VS2008 artifacts only when explicitly requested
if ($ExecuteRemoval) {
    $legacyPatterns = @('*.vcproj', '*.sln', '*.vdproj', 'packer.exe', '*.bat', 'Setup.build', '*.dia')
    foreach ($pattern in $legacyPatterns) {
        Get-ChildItem -Path $Root -Recurse -Filter $pattern -ErrorAction SilentlyContinue | ForEach-Object {
            Write-Host "Removing" $_.FullName
            Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
        }
    }
}

Write-Host "Clean layout prepared. Update project references to point at" $cleanSrc
