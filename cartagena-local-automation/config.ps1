# ═══════════════════════════════════════
# CONFIGURACIÓN GENERAL - Cartagena Local
# ═══════════════════════════════════════

$CONFIG = @{

    # ─── RUTAS ───
    BASE_DIR       = "C:\Users\DIEGO\Desktop\moweb"
    AUTOMATION_DIR = "C:\Users\DIEGO\Desktop\moweb\cartagena-local-automation"
    ACCOUNTS_JSON  = "C:\Users\DIEGO\Desktop\moweb\github-accounts.json"
    PLANES_DIR     = "C:\Users\DIEGO\Desktop\moweb\planes"
    SUBMISSIONS_DIR = "C:\Users\DIEGO\Desktop\moweb\submissions"
    BILLING_DB     = "C:\Users\DIEGO\Desktop\moweb\billing-db.json"

    # ─── EXCEL CENTRAL DE GESTIÓN (se sobreescribe por ciudad) ───
    EXCEL_PATH     = "C:\Users\DIEGO\Desktop\moweb\cartagena\CartagenaLocal_Gestion.xlsx"

    # ─── CIUDADES DISPONIBLES ───
    CIUDADES = @{
        "cartagena"      = @{ nombre = "Cartagena"; slug = "cartagena" }
        "medellin"       = @{ nombre = "Medellin"; slug = "medellin" }
        "bogota"         = @{ nombre = "Bogota"; slug = "bogota" }
        "cali"           = @{ nombre = "Cali"; slug = "cali" }
        "barranquilla"   = @{ nombre = "Barranquilla"; slug = "barranquilla" }
        "santa-marta"    = @{ nombre = "Santa Marta"; slug = "santa-marta" }
        "bucaramanga"    = @{ nombre = "Bucaramanga"; slug = "bucaramanga" }
        "pereira"        = @{ nombre = "Pereira"; slug = "pereira" }
        "manizales"      = @{ nombre = "Manizales"; slug = "manizales" }
        "cucuta"         = @{ nombre = "Cucuta"; slug = "cucuta" }
        "ibague"         = @{ nombre = "Ibague"; slug = "ibague" }
        "villavicencio"  = @{ nombre = "Villavicencio"; slug = "villavicencio" }
        "armenia"        = @{ nombre = "Armenia"; slug = "armenia" }
        "neiva"          = @{ nombre = "Neiva"; slug = "neiva" }
        "sincelejo"      = @{ nombre = "Sincelejo"; slug = "sincelejo" }
        "pasto"          = @{ nombre = "Pasto"; slug = "pasto" }
        "monteria"       = @{ nombre = "Monteria"; slug = "monteria" }
        "valledupar"     = @{ nombre = "Valledupar"; slug = "valledupar" }
        "san-andres"     = @{ nombre = "San Andres"; slug = "san-andres" }
        "eje-cafetero"   = @{ nombre = "Eje Cafetero"; slug = "eje-cafetero" }
        "villa-de-leyva" = @{ nombre = "Villa de Leyva"; slug = "villa-de-leyva" }
        "san-gil"        = @{ nombre = "San Gil"; slug = "san-gil" }
        "leticia"        = @{ nombre = "Leticia"; slug = "leticia" }
        "mompox"         = @{ nombre = "Mompox"; slug = "mompox" }
        "popayan"        = @{ nombre = "Popayan"; slug = "popayan" }
        "guatape"        = @{ nombre = "Guatape"; slug = "guatape" }
        "providencia"    = @{ nombre = "Providencia"; slug = "providencia" }
        "nuqui"          = @{ nombre = "Nuqui"; slug = "nuqui" }
        "san-agustin"    = @{ nombre = "San Agustin"; slug = "san-agustin" }
        "tunja"          = @{ nombre = "Tunja"; slug = "tunja" }
        "riohacha"       = @{ nombre = "Riohacha"; slug = "riohacha" }
        "quibdo"         = @{ nombre = "Quibdo"; slug = "quibdo" }
        "mitu"           = @{ nombre = "Mitu"; slug = "mitu" }
        "puerto-carreno" = @{ nombre = "Puerto Carreño"; slug = "puerto-carreno" }
        "yopal"          = @{ nombre = "Yopal"; slug = "yopal" }
        "arauca"         = @{ nombre = "Arauca"; slug = "arauca" }
        "casanare"       = @{ nombre = "Casanare"; slug = "casanare" }
        "putumayo"       = @{ nombre = "Putumayo"; slug = "putumayo" }
        "choco"          = @{ nombre = "Choco"; slug = "choco" }
        "guajira"        = @{ nombre = "La Guajira"; slug = "guajira" }
        "magdalena"      = @{ nombre = "Magdalena"; slug = "magdalena" }
        "cauca"          = @{ nombre = "Cauca"; slug = "cauca" }
        "narino"         = @{ nombre = "Nariño"; slug = "narino" }
        "huila"          = @{ nombre = "Huila"; slug = "huila" }
        "tolima"         = @{ nombre = "Tolima"; slug = "tolima" }
        "meta"           = @{ nombre = "Meta"; slug = "meta" }
        "bolivar"        = @{ nombre = "Bolivar"; slug = "bolivar" }
        "atlantico"      = @{ nombre = "Atlantico"; slug = "atlantico" }
        "cordoba"        = @{ nombre = "Cordoba"; slug = "cordoba" }
        "sucre"          = @{ nombre = "Sucre"; slug = "sucre" }
    }

    # ─── PLANES Y PRECIOS ───
    PLANES = @{
        "Presencia Basica" = 30000
        "Verificado"       = 60000
        "Destacado"        = 80000
        "Completo"         = 100000
    }

    PLAN_ORDEN = @{
        "Presencia Basica" = 999
        "Verificado"       = 60
        "Destacado"        = 30
        "Completo"         = 10
    }

    PLAN_PRECIO_TAG = @{
        "Presencia Basica" = "$ Economico"
        "Verificado"       = "$$ Promedio"
        "Destacado"        = "$$$ Exclusivo"
        "Completo"         = "$$$ Exclusivo"
    }

    # ─── CATEGORIAS ───
    CATEGORIAS = @("bares", "cafe", "comida", "arte", "plan", "noche")
    CAT_EMOJIS = @{
        "bares"  = "🍺"
        "cafe"   = "☕"
        "comida" = "🍽️"
        "arte"   = "🎨"
        "plan"   = "🌅"
        "noche"  = "🌙"
    }
    BG_CLASSES = @{
        "bares"  = "pt1"
        "cafe"   = "pt2"
        "comida" = "pt3"
        "arte"   = "pt4"
        "plan"   = "pt5"
        "noche"  = "pt6"
    }

    WHATSAPP_NUMBER = "573218879876"

    # ─── APIs ───
    IMGBB_API_KEY    = "2bf08b9ce1d13ca9ddf785696f0ab9c9"
    GEMINI_API_KEY   = "{{GEMINI_API_KEY}}"  # Reemplazar con API key de Gemini
    BOLD_API_KEY     = "{{BOLD_API_KEY}}"  # Reemplazar con la API key de Bold
    BOLD_BASE_URL    = "https://integrations.api.bold.co"

    # ─── GITHUB CENTRAL ───
    CENTRAL_OWNER    = "hablemosdeparche"      # Tu usuario de GitHub
    CENTRAL_REPO     = "elparche-admin"     # Nombre del repo central
    CENTRAL_PAT      = "{{GITHUB_PAT}}"     # Token con permisos de issues y actions

    # ─── POLLINATIONS.AI ───
    POLLINATIONS_URL   = "https://image.pollinations.ai/prompt"
    POLLINATIONS_MODEL = "flux"
    POLLINATIONS_WIDTH = 1024
    POLLINATIONS_HEIGHT = 1024

    # ─── BILLING ───
    FREE_TRIAL_MONTHS  = 1
    GRACE_PERIOD_DAYS  = 7
    MIN_VENUES_PER_CITY = 35
    EDIT_PRICE         = 10000
}

function Get-CiudadConfig($ciudadSlug) {
    if (!$CONFIG.CIUDADES.ContainsKey($ciudadSlug)) {
        Write-Error "Ciudad '$ciudadSlug' no encontrada"
        return $null
    }
    $info = $CONFIG.CIUDADES[$ciudadSlug]
    $carpeta = Join-Path $CONFIG.BASE_DIR $ciudadSlug
    return @{
        slug      = $ciudadSlug
        nombre    = $info.nombre
        htmlPath  = Join-Path $carpeta "index.html"
        backupDir = Join-Path $carpeta "backup"
        excelPath = Join-Path $carpeta "CartagenaLocal_Gestion.xlsx"
        gitDir    = $carpeta
    }
}

function Get-AllCities {
    return $CONFIG.CIUDADES.Keys | Sort-Object
}

function Get-PlanLabel($plan) {
    if ($CONFIG.PLANES.ContainsKey($plan)) { return $plan }
    return "Presencia Basica"
}

function Get-PlanPrice($plan) {
    if ($CONFIG.PLANES.ContainsKey($plan)) { return $CONFIG.PLANES[$plan] }
    return 30000
}

function Get-PlanOrden($plan) {
    if ($CONFIG.PLAN_ORDEN.ContainsKey($plan)) { return $CONFIG.PLAN_ORDEN[$plan] }
    return 999
}

function Get-CitySlug($nombreCiudad) {
    foreach ($kv in $CONFIG.CIUDADES.GetEnumerator()) {
        if ($kv.Value.nombre -eq $nombreCiudad -or $kv.Key -eq $nombreCiudad) {
            return $kv.Key
        }
    }
    return $null
}

function Get-CiudadConfig($ciudadSlug) {
    if (!$CONFIG.CIUDADES.ContainsKey($ciudadSlug)) {
        Write-Error "Ciudad '$ciudadSlug' no encontrada"
        return $null
    }
    $info = $CONFIG.CIUDADES[$ciudadSlug]
    $carpeta = Join-Path $CONFIG.BASE_DIR $ciudadSlug
    return @{
        slug      = $ciudadSlug
        nombre    = $info.nombre
        htmlPath  = Join-Path $carpeta "index.html"
        backupDir = Join-Path $carpeta "backup"
        excelPath = Join-Path $carpeta "CartagenaLocal_Gestion.xlsx"
        gitDir    = $carpeta
    }
}
