# ═══════════════════════════════════════
# HTML MANAGER - Cartagena Local
# ═══════════════════════════════════════
# Modifica el array places[] en el HTML

if (!$CONFIG) { . "$PSScriptRoot\..\config.ps1" }

function Read-HtmlContent {
    if (!(Test-Path $CONFIG.HTML_PATH)) {
        Write-Error "HTML no encontrado: $($CONFIG.HTML_PATH)"
        return $null
    }
    return Get-Content $CONFIG.HTML_PATH -Raw
}

function Backup-Html {
    $backupDir = $CONFIG.BACKUP_DIR
    if (!(Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir -Force | Out-Null }
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupFile = Join-Path $backupDir "cartagena-local_backup_${timestamp}.html"
    Copy-Item $CONFIG.HTML_PATH $backupFile
    Write-Output "Backup creado: $backupFile"
    return $backupFile
}

function Get-PlacesFromHtml {
    $content = Read-HtmlContent
    if (!$content) { return @() }

    # Extraer el array places entre "const places = [" y "];"
    $match = [regex]::Match($content, 'const places\s*=\s*\[([\s\S]*?)\];')
    if (!$match.Success) {
        Write-Error "No se pudo encontrar el array places en el HTML"
        return @()
    }

    $placesRaw = $match.Groups[1].Value
    $places = @()

    # Parsear cada objeto
    $objRegex = [regex]'\{([^}]+)\}'
    $objMatches = $objRegex.Matches($placesRaw)

    foreach ($m in $objMatches) {
        $objStr = $m.Groups[0].Value
        $place = @{}

        # id
        $idMatch = [regex]::Match($objStr, "id\s*:\s*(\d+)")
        if ($idMatch.Success) { $place.id = [int]$idMatch.Groups[1].Value }

        # orden
        $ordMatch = [regex]::Match($objStr, "orden\s*:\s*(\d+)")
        if ($ordMatch.Success) { $place.orden = [int]$ordMatch.Groups[1].Value } else { $place.orden = 999 }

        # bg
        $bgMatch = [regex]::Match($objStr, "bg\s*:\s*'([^']*)'")
        if ($bgMatch.Success) { $place.bg = $bgMatch.Groups[1].Value }

        # cat
        $catMatch = [regex]::Match($objStr, "cat\s*:\s*'([^']*)'")
        if ($catMatch.Success) { $place.cat = $catMatch.Groups[1].Value }

        # name
        $nameMatch = [regex]::Match($objStr, "name\s*:\s*'([^']*)'")
        if ($nameMatch.Success) { $place.name = $nameMatch.Groups[1].Value }

        # nit
        $nitMatch = [regex]::Match($objStr, "nit\s*:\s*'([^']*)'")
        if ($nitMatch.Success) { $place.nit = $nitMatch.Groups[1].Value } else { $place.nit = "" }

        # barrio
        $barMatch = [regex]::Match($objStr, "barrio\s*:\s*'([^']*)'")
        if ($barMatch.Success) { $place.barrio = $barMatch.Groups[1].Value }

        # tags
        $tagsMatch = [regex]::Match($objStr, "tags\s*:\s*\[([^\]]*)\]")
        if ($tagsMatch.Success) {
            $tagStr = $tagsMatch.Groups[1].Value
            $tags = [regex]::Matches($tagStr, "'([^']*)'") | ForEach-Object { $_.Groups[1].Value }
            $place.tags = $tags
        }

        # rating
        $ratMatch = [regex]::Match($objStr, "rating\s*:\s*([\d.]+)")
        if ($ratMatch.Success) { $place.rating = [double]$ratMatch.Groups[1].Value }

        # horario
        $horMatch = [regex]::Match($objStr, "horario\s*:\s*'([^']*)'")
        if ($horMatch.Success) { $place.horario = $horMatch.Groups[1].Value }

        # precio
        $precMatch = [regex]::Match($objStr, "precio\s*:\s*'([^']*)'")
        if ($precMatch.Success) { $place.precio = $precMatch.Groups[1].Value }

        # desc
        $descMatch = [regex]::Match($objStr, "desc\s*:\s*'([^']*)'")
        if ($descMatch.Success) { $place.desc = $descMatch.Groups[1].Value }

        # img
        $imgMatch = [regex]::Match($objStr, "img\s*:\s*'([^']*)'")
        if ($imgMatch.Success) { $place.img = $imgMatch.Groups[1].Value }

        # telefono
        $telMatch = [regex]::Match($objStr, "telefono\s*:\s*'([^']*)'")
        if ($telMatch.Success) { $place.telefono = $telMatch.Groups[1].Value }

        # instagram
        $igMatch = [regex]::Match($objStr, "instagram\s*:\s*'([^']*)'")
        if ($igMatch.Success) { $place.instagram = $igMatch.Groups[1].Value }

        # menu
        $menuMatch = [regex]::Match($objStr, "menu\s*:\s*\[([^\]]*)\]")
        if ($menuMatch.Success) {
            $menuStr = $menuMatch.Groups[1].Value
            $menu = [regex]::Matches($menuStr, "'([^']*)'") | ForEach-Object { $_.Groups[1].Value }
            $place.menu = $menu
        }

        # coords
        $coordMatch = [regex]::Match($objStr, "coords\s*:\s*\[([^\]]*)\]")
        if ($coordMatch.Success) {
            $coordStr = $coordMatch.Groups[1].Value
            $coords = $coordStr -split ',' | ForEach-Object { [double]$_.Trim() }
            $place.coords = $coords
        }

        $places += $place
    }

    return $places
}

function Get-NextPlaceId {
    $places = Get-PlacesFromHtml
    if ($places.Count -eq 0) { return 1 }
    $maxId = ($places | ForEach-Object { $_.id }) | Measure-Object -Maximum
    return $maxId.Maximum + 1
}

function Get-PrecioForPlan($plan) {
    $map = @{
        "Presencia Basica" = "`$ Económico"
        "Presencia Básica" = "`$ Económico"
        "Verificado"       = "`$$ Promedio"
        "Destacado"        = "`$$$ Exclusivo"
        "Completo"         = "`$$$ Exclusivo"
    }
    if ($map.ContainsKey($plan)) { return $map[$plan] }
    return "`$$ Promedio"
}

function Get-OrdenForPlan($plan) {
    # Destacado y Completo aparecen primero
    $map = @{
        "Presencia Basica" = 999
        "Presencia Básica" = 999
        "Verificado"       = 999
        "Destacado"        = 50
        "Completo"         = 10
    }
    if ($map.ContainsKey($plan)) { return $map[$plan] }
    return 999
}

function Get-BgClass($cat, $usedBgs) {
    $pool = @("pt1","pt2","pt3","pt4","pt5","pt6","pt7","pt8")
    $available = $pool | Where-Object { $_ -notin $usedBgs }
    if ($available.Count -eq 0) { $available = $pool }
    return $available[0]
}

function Escape-JsString($s) {
    return $s -replace "'", "\'" -replace '"', '\"'
}

function Place-ToJsString($p) {
    $tagsStr = ($p.tags | ForEach-Object { "'$($_)'" }) -join ","
    $menuStr = ($p.menu | ForEach-Object { "'$($_)'" }) -join ","
    $coordStr = "$($p.coords[0]),$($p.coords[1])"
    $nameEsc = Escape-JsString $p.name
    $descEsc = Escape-JsString $p.desc
    $barrioEsc = Escape-JsString $p.barrio
    $horarioEsc = Escape-JsString $p.horario
    $precioEsc = Escape-JsString $p.precio
    $nitEsc = if ($p.nit) { Escape-JsString $p.nit } else { "" }

    return "{ id:$($p.id), orden:$($p.orden), bg:'$($p.bg)', cat:'$($p.cat)', name:'$nameEsc', nit:'$nitEsc', barrio:'$barrioEsc', tags:[$tagsStr], rating:$($p.rating), horario:'$horarioEsc', precio:'$precioEsc', desc:'$descEsc', img:'$($p.img)', telefono:'$($p.telefono)', instagram:'$($p.instagram)', menu:[$menuStr], coords:[$coordStr] }"
}

function Add-PlaceToHtml {
    param($place)  # Hashtable con los mismos campos que el array places[]

    $content = Read-HtmlContent
    if (!$content) { return }

    # Encontrar donde insertar (antes del cierre del array)
    $closeMatch = [regex]::Match($content, '(\s*)\];\s*\n\s*// ═══ EVENTOS')
    if (!$closeMatch.Success) {
        Write-Error "No se pudo encontrar el cierre del array places"
        return
    }

    $indent = $closeMatch.Groups[1].Value
    $newPlaceStr = Place-ToJsString $place

    # Buscar la categoría para insertar en el grupo correcto
    $catComment = "// ═══ $($place.cat.ToUpper()) ═══"
    $catCheck = $content.IndexOf($catComment)

    if ($catCheck -ge 0) {
        # Insertar después del último elemento de esa categoría
        $afterCat = $content.IndexOf("`n", $catCheck)
        $searchFrom = $afterCat
        # Buscar la siguiente línea que tenga "// ═══" o el cierre del array
        $nextSection = [regex]::Match($content, '(// ═══\s*\w+\s*═══|\]\s*;\s*\n)', $searchFrom)
        if ($nextSection.Success) {
            $insertPos = $nextSection.Index
            # Encontrar el inicio de la línea
            $lineStart = $content.LastIndexOf("`n", $insertPos - 1) + 1
            $newContent = $content.Substring(0, $lineStart) + "  $newPlaceStr,`n" + $content.Substring($lineStart)
            [System.IO.File]::WriteAllText($CONFIG.HTML_PATH, $newContent, [System.Text.Encoding]::UTF8)
            Write-Output "Place '$($place.name)' agregado en categoria $($place.cat)"
        }
    } else {
        # Insertar al final del array
        $insertPos = $closeMatch.Index
        $newContent = $content.Substring(0, $insertPos) + "  $newPlaceStr," + $content.Substring($insertPos)
        [System.IO.File]::WriteAllText($CONFIG.HTML_PATH, $newContent, [System.Text.Encoding]::UTF8)
        Write-Output "Place '$($place.name)' agregado al final"
    }
}

function Update-PlaceInHtml {
    param($nombre, $newData)  # nombre a buscar, newData = hashtable con campos a actualizar

    $content = Read-HtmlContent
    if (!$content) { return $false }

    # Buscar el place por nombre
    $pattern = [regex]::Escape($nombre)
    $placeMatch = [regex]::Match($content, "\{[^}]*name\s*:\s*'$pattern'[^}]*\}")
    if (!$placeMatch.Success) {
        Write-Error "Place '$nombre' no encontrado en el HTML"
        return $false
    }

    $oldStr = $placeMatch.Value
    $place = Get-PlacesFromHtml | Where-Object { $_.name -eq $nombre } | Select-Object -First 1
    if (!$place) { return $false }

    # Aplicar cambios
    foreach ($key in $newData.Keys) {
        $place[$key] = $newData[$key]
    }

    $newStr = Place-ToJsString $place
    $newContent = $content.Replace($oldStr, $newStr)
    [System.IO.File]::WriteAllText($CONFIG.HTML_PATH, $newContent, [System.Text.Encoding]::UTF8)
    Write-Output "Place '$nombre' actualizado"
    return $true
}

function Remove-PlaceFromHtml {
    param($nombre)

    $content = Read-HtmlContent
    if (!$content) { return $false }

    $pattern = [regex]::Escape($nombre)
    $placeMatch = [regex]::Match($content, "\{[^}]*name\s*:\s*'$pattern'[^}]*\},\s*`n")
    if (!$placeMatch.Success) {
        $placeMatch = [regex]::Match($content, "\{[^}]*name\s*:\s*'$pattern'[^}]*\}")
    }
    if (!$placeMatch.Success) {
        Write-Error "Place '$nombre' no encontrado"
        return $false
    }

    $newContent = $content.Remove($placeMatch.Index, $placeMatch.Length)
    [System.IO.File]::WriteAllText($CONFIG.HTML_PATH, $newContent, [System.Text.Encoding]::UTF8)
    Write-Output "Place '$nombre' eliminado del HTML"
    return $true
}

function Get-PlanDataForPlace($plan) {
    # Determina verified y orden según el plan
    $verified = $false
    $orden = 999

    switch -Regex ($plan.ToLower()) {
        "verificado" { $verified = $true; $orden = 999 }
        "destacado"  { $verified = $true; $orden = 50 }
        "completo"   { $verified = $true; $orden = 10 }
        "basica"     { $verified = $false; $orden = 999 }
        default      { $verified = $false; $orden = 999 }
    }

    return @{ verified = $verified; orden = $orden }
}

function Sync-PlacesToHtml {
    # Sincroniza el Excel -> HTML: actualiza verified/orden según plan
    $locales = Get-AllLocalesFromExcel
    $places = Get-PlacesFromHtml

    foreach ($local in $locales) {
        $place = $places | Where-Object { $_.name.ToLower() -eq $local.Nombre.ToLower() } | Select-Object -First 1
        if ($place) {
            $planData = Get-PlanDataForPlace $local.Plan
            $changed = $false
            if ($planData.verified -and $place.orden -ne $planData.orden) {
                $place.orden = $planData.orden
                $changed = $true
            }
            if ($changed) {
                Update-PlaceInHtml -nombre $local.Nombre -newData @{ orden = $place.orden }
            }
        }
    }
    Write-Output "Sincronización Excel -> HTML completada"
}
