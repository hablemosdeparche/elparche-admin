# GENERADOR MASIVO DE WEBS PARA TODAS LAS CIUDADES
$BASE = "C:\Users\DIEGO\Desktop\moweb"
$TEMPLATE = Join-Path $BASE "cartagena\index.html"
$TEMPLATE_HTML = Get-Content $TEMPLATE -Raw

$CITIES = @()

# ===== BOGOTA - Dark / Rojo =====
$CITIES += @{
    slug = "bogota"
    title = "Bogota Local - El Parche"
    logo = "Bogota Local"
    subtitle = "La capital es un parche"
    theme = "dark"
    gold = "#C0392B"; goldLight = "#E74C3C"; coral = "#E76F51"
    dark = "#0F0C08"; dark2 = "#181309"; cardBg = "#1C1508"
    cardBorder = "#2E2010"; text = "#F0E8D8"; muted = "#7A6A4A"
    muted2 = "#9A8A6A"; tagBg = "#241A08"; navBg = "#0F0C08"
    waNumber = "573218879876"
    storageKey = "bog_saved"
    mapCenter = "4.6097,-74.0817"
    mapZoom = 12
    eventsText = "Proximos eventos en Bogota"
}

Write-Host "Script cargado correctamente"
Write-Host "Ciudades definidas: $($CITIES.Count)"
