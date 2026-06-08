# Build city-places.json from compact data
$OUT = "C:\Users\DIEGO\Desktop\moweb\cartagena-local-automation\scripts\city-places.json"

function New-Place($n,$b,$c,$t,$r,$h,$p,$d,$tl,$ig,$mn,$co,$o) {
    $tags = $t -split ','
    $menu = $mn -split ','
    $coords = $co -split ',' | % { [double]$_ }
    @{name=$n; barrio=$b; cat=$c; tags=$tags; rating=$r; horario=$h; precio=$p; desc=$d; telefono=$tl; instagram=$ig; menu=$menu; coords=@($coords[0],$coords[1]); orden=999; bg="pt1"}
}

function New-Event($d,$ed,$c,$ic,$n,$pl,$pr,$s) {
    @{date=$d; endDate=$ed; cat=$c; icon=$ic; name=$n; place=$pl; price=$pr; short=$s}
}

$data = @{}

# === BOGOTA ===
$data.bogota = @{
    places = 1..35 | % { $_ }
    events = @()
}
# Too complex with inline data. Generate JSON directly using Write-Host/Out-File

# Instead, let me write CSV-like data files and convert them
Write-Host "This approach is too complex for inline data. Use direct JSON file instead." -ForegroundColor Red
