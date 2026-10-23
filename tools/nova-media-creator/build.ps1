$ErrorActionPreference = 'Stop'
$project = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$compiler = 'C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe'
$source = Join-Path $PSScriptRoot 'App.cs'
$manifest = Join-Path $PSScriptRoot 'app.manifest'
$previewManifest = Join-Path $PSScriptRoot 'preview.manifest'
$vendor = Join-Path $project 'tools\media\FedoraMediaWriter-win64-portable-5.3.2.zip'
$iso = Join-Path $project 'artifacts\NOVA-OS-0.3-Preview-x86_64.iso'
$output = Join-Path $project 'NOVA Media Creation Tool.exe'
$preview = Join-Path $project 'NOVA Media Creation Tool Preview QA.exe'
$releaseManifest = Join-Path $project 'NOVA Media Creation Tool.release.json'
if (!(Test-Path -LiteralPath $compiler)) { throw 'The .NET Framework compiler was not found.' }
if (!(Test-Path -LiteralPath $vendor)) { throw 'The pinned Fedora Media Writer package is missing.' }
$vendorHash = (Get-FileHash -LiteralPath $vendor -Algorithm SHA256).Hash.ToLowerInvariant()
if ($vendorHash -ne '1043a01b5bfc4b0a79b4f431696eeaeb18c605f38579009877aada3a836904da') { throw 'Fedora Media Writer archive hash mismatch.' }
if (!(Test-Path -LiteralPath $iso)) { throw 'The pinned NOVA Preview ISO is missing.' }
$isoFile = Get-Item -LiteralPath $iso
$isoHash = (Get-FileHash -LiteralPath $iso -Algorithm SHA256).Hash.ToLowerInvariant()
if ($isoFile.Length -ne 4950038528 -or $isoHash -ne '9119ccb6e21780f0310c59a4a68c82a97c9373da74361aff9bd67c9afdd23240') { throw 'NOVA ISO hash or size mismatch.' }
$references = @('/reference:System.dll','/reference:System.Core.dll','/reference:System.Drawing.dll','/reference:System.Windows.Forms.dll','/reference:System.Management.dll','/reference:System.Security.dll','/reference:System.IO.Compression.dll','/reference:System.IO.Compression.FileSystem.dll')
$common = @('/nologo','/target:winexe','/optimize+','/codepage:65001') + $references + @('/resource:' + $vendor + ',NOVA.Media.VendorZip')
& $compiler @common ('/out:' + $output) ('/win32manifest:' + $manifest) $source
if ($LASTEXITCODE -ne 0) { throw 'NOVA Media Creation Tool compile failed.' }
& $compiler @common ('/out:' + $preview) '/define:PREVIEW' ('/win32manifest:' + $previewManifest) $source
if ($LASTEXITCODE -ne 0) { throw 'NOVA Media Creation Tool Preview compile failed.' }
$selfTest = Start-Process -FilePath $preview -ArgumentList '/self-test' -Wait -PassThru -WindowStyle Hidden
if ($selfTest.ExitCode -ne 0) { throw ('NOVA Media Creation Tool self-test failed: ' + $selfTest.ExitCode) }
Write-Host ('Built ' + $output)
Write-Host ('Built safe UI preview ' + $preview)
$release = [ordered]@{
    name = 'NOVA Media Creation Tool'
    version = '0.3 Preview'
    builtAtUtc = [DateTime]::UtcNow.ToString('o')
    compiler = (Get-Item -LiteralPath $compiler).VersionInfo.FileVersion
    sourceSha256 = [ordered]@{
        'App.cs' = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToLowerInvariant()
        'build.ps1' = (Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash.ToLowerInvariant()
        'app.manifest' = (Get-FileHash -LiteralPath $manifest -Algorithm SHA256).Hash.ToLowerInvariant()
    }
    signed = $false
    executable = [ordered]@{ file = [IO.Path]::GetFileName($output); bytes = (Get-Item -LiteralPath $output).Length; sha256 = (Get-FileHash -LiteralPath $output -Algorithm SHA256).Hash.ToLowerInvariant() }
    safePreview = [ordered]@{ file = [IO.Path]::GetFileName($preview); bytes = (Get-Item -LiteralPath $preview).Length; sha256 = (Get-FileHash -LiteralPath $preview -Algorithm SHA256).Hash.ToLowerInvariant(); writesEnabled = $false }
    selfTest = [ordered]@{ passed = $true; exitCode = $selfTest.ExitCode; usbDisksEnumerated = $false; usbWritten = $false }
    iso = [ordered]@{ file = [IO.Path]::GetFileName($iso); bytes = $isoFile.Length; sha256 = $isoHash }
    usbWriter = [ordered]@{ name = 'Fedora Media Writer'; version = '5.3.2'; archiveSha256 = $vendorHash; helperSha256 = 'bcb7c9f9d57ad58bbc8433e475af8fec13e47c5b236dc4bab1c61ceeb7cf6303'; source = 'https://github.com/FedoraQt/MediaWriter/tree/5.3.2'; license = 'GPL-2.0-or-later; Qt component notices retained' }
}
$json = $release | ConvertTo-Json -Depth 5
[IO.File]::WriteAllText($releaseManifest, $json + [Environment]::NewLine, [Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllText($output + '.sha256', $release.executable.sha256 + '  ' + [IO.Path]::GetFileName($output) + [Environment]::NewLine, [Text.Encoding]::ASCII)
[IO.File]::WriteAllText($preview + '.sha256', $release.safePreview.sha256 + '  ' + [IO.Path]::GetFileName($preview) + [Environment]::NewLine, [Text.Encoding]::ASCII)
Write-Host ('Release manifest: ' + $releaseManifest)
