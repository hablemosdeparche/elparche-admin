$csc = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
$src = Join-Path $PSScriptRoot "export-data.cs"
$out = Join-Path $PSScriptRoot "ExportData.exe"
& $csc -reference:System.Web.Extensions.dll -out:$out $src 2>&1
Write-Output "ExportData.exe compilado!"
