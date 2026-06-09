# El Parche - Progreso del Proyecto

## Estado General
Web de guía turística con **suscripciones automáticas** via Mercado Pago para locales.

## Arquitectura Actual

### Sitio Web
- `hablemosdeparche.github.io` — sitio público (GitHub Pages)
- `hablemosdeparche/elparche-admin` — repo admin con billing-db y HTML de ciudades
- El HTML de cada ciudad se despliega al repo Pages y se actualiza solo

### Sistema de Suscripciones (Mercado Pago)
- **Reemplazó a Bold** como pasarela de pago
- **Suscripciones con cobro automático mensual** — el cliente paga una vez con tarjeta y MP cobra cada mes automáticamente
- **Primer mes gratis** configurado via `free_trial` de MP
- **Cancelación** desde el panel admin o contactando por WhatsApp
- Si fallan 3 pagos seguidos, MP cancela la suscripción automáticamente

### Componentes Modificados/Creados

#### 1. GitHub Actions — `mp-monitor.yml`
- Corre **cada 30 minutos** en los servidores de GitHub (no depende del PC local)
- **Job 1 (monitor):** Procesa Issues nuevos y actualiza `billing-db.json` en el repo central
- **Job 2 (hide-venues):** Matrix de 18 ciudades. Por cada ciudad afectada, checkout del repo de esa ciudad (`hablemosdeparche/{ciudad}`), oculta venues expirados con `orden: 99999`, pushea al repo de la ciudad
- Si MP dice `authorized` → activa el local y dispara `process-payment.yml`
- **No necesita que el PC esté encendido**
- **Nota:** Las ciudades que no tengan `{ciudad}_PAT` configurado en GitHub Secrets no podrán ocultar venues automáticamente (fallará el checkout)

#### 2. GitHub Actions — `process-submission.yml`
- Se activa cuando se crea un Issue con `mp-status:pending`
- Crea una suscripción en MP con `free_trial: 1 mes`
- Actualiza el Issue con `mp-init-point` (link de pago MP)
- El frontend redirige al usuario a MP para que ingrese su tarjeta

#### 3. GitHub Actions — `process-payment.yml`
- Se activa cuando `mp-monitor` detecta una suscripción `authorized`
- Agrega el venue al HTML de la ciudad
- Actualiza `venues.json` y `billing-db.json`
- Commit + push

#### 4. GitHub Actions — `deploy.yml`
- Reemplaza placeholders (`{{GITHUB_PAT}}`, `{{GITHUB_OWNER}}`, `{{GITHUB_REPO}}`)
- Ya no necesita `{{BOLD_API_KEY}}`

#### 5. Frontend — `admintaller/index.html`
- Diseño "chilo" original **se mantiene intacto**
- Formulario ahora pide **email** (requerido por MP para suscripciones)
- Flujo de pago:
  1. Usuario llena formulario → se crea Issue en GitHub
  2. Frontend espera a que GHA cree la suscripción MP
  3. Cuando recibe el `init_point`, muestra botón "Ir a Mercado Pago"
  4. Usuario ingresa tarjeta en MP → suscripción activa
- Nueva sección: **"Cancelar suscripción"** al final del panel
- Ya no llama a Bold directamente (todo va por GitHub Issues + GHA)

#### 6. Frontend — `admintaller/mp-success.html`
- Página a la que MP redirige después del checkout
- Muestra mensaje de confirmación

#### 7. Script Local — `elparche-agent/elparche-core.ps1`
- Ahora también verifica `mp_status` de `billing-db.json`
- Si MP dice `cancelled`/`past_due`, oculta el local (además de la verificación por fecha)
- Backup local del sistema (GitHub Actions hace el trabajo pesado en la nube)

#### 8. Base de Datos — `billing-db.json`
- Nuevos campos por venue:
  - `mp_subscription_id` — ID de la suscripción en MP
  - `mp_status` — Estado actual (authorized, cancelled, past_due, pending)
  - `mp_payer_email` — Email del suscriptor
  - `mp_next_payment` — Próxima fecha de cobro
  - `mp_trial_ends` — Fin del período gratis

### Flujo Completo (usuario nuevo)
```
1. Usuario llena formulario en admintaller/index.html
2. Se crea Issue en GitHub con mp-status:pending
3. GHA mp-monitor.yml detecta el Issue (o process-submission.yml)
4. GHA llama a MP API → crea suscripción con 1 mes gratis
5. Issue se actualiza con mp-init-point (URL de checkout MP)
6. Frontend (polling) detecta el init_point → muestra botón
7. Usuario hace clic → va a MP → ingresa tarjeta → autoriza
8. Estado de suscripción en MP cambia a "authorized"
9. GHA mp-monitor.yml detecta el cambio
10. GHA actualiza Issue a mp-status:authorized
11. GHA dispara process-payment.yml
12. process-payment.yml agrega venue al HTML y billing-db.json
13. Usuario ve su local en la guía. Sin hacer nada más.
14. A los 30 días, MP cobra la tarjeta automáticamente.
```

### Flujo de Cancelación
```
1. Usuario completa formulario de cancelación en admintaller
2. Se crea Issue con etiqueta "cancel"
3. Admin recibe notificación y cancela en MP manualmente
   O automáticamente via mp-monitor.yml si se implementa
4. GHA mp-monitor.yml detecta mp_status: "cancelled"
5. Oculta el local en el HTML
6. MP deja de cobrar
```

### Diferencia con Bold (anterior)
| Aspecto | Bold (anterior) | Mercado Pago (nuevo) |
|---------|----------------|---------------------|
| Tipo de pago | Pago único | Suscripción recurrente |
| Cobro automático | No | Sí (MP cobra cada mes) |
| Primer mes gratis | Manual | Automático (free_trial nativo) |
| Reintentos | No | 3 intentos automáticos |
| Cancelación | No aplica | Sí, desde panel o MP |
| Dependencia PC | Sí (agente local) | No (GitHub Actions cloud) |
| Token API | {{BOLD_API_KEY}} | MP_ACCESS_TOKEN (GitHub Secret) |
| HTML ciudades | En repo central (copias locales) | En repos separados por ciudad (cartagenalocal/{slug}) |

### Arquitectura de Repos
- **Repo central:** `hablemosdeparche/elparche-admin` — billing-db.json, venues.json, panel admin, workflows GHA
- **Repos por ciudad:** `hablemosdeparche/{slug}` — index.html de cada guía (serve via GitHub Pages)
- **Conexión:** `mp-monitor.yml` job2 usa per-city PATs (`{slug}_PAT`) para pushear cambios a city repos
- **Local:** Las carpetas de ciudades en el repo central son solo copias de desarrollo

## Pendientes

### Crítico (antes de pushear)
1. **Access Token de Mercado Pago** — se necesita para activar el sistema
   - Crear cuenta vendedor en mercadopago.com.co
   - Ir a Credenciales → copiar Access Token (APP_USR-...)
   - Agregar como `MP_ACCESS_TOKEN` en GitHub Secrets del repo

2. **Rotar el GitHub Token expuesto** — el que está en ELPARCHE_PROGRESS.md línea 74 está público
   - Crear nuevo token en GitHub Settings → Developer settings → Personal access tokens
   - Actualizar el secreto `GH_PAT` en GitHub Secrets

3. **Verificar per-city PATs** — `mp-monitor.yml` job2 usa `{slug}_PAT` por cada ciudad. Solo funcionará para las ciudades que ya tengan ese secreto configurado. Si falta alguna, toca agregarla.

### Opcional
- Verificar que mp-monitor.yml funcione correctamente los primeros días
- Probar cancelación de suscripción desde el panel
- Cancelar cuenta de Bold (después de verificar que MP funciona)

## Cuentas Git
- Remoto: `hablemosdeparche/elparche-admin`
- Token: `[REVOCADO - estaba expuesto]`- Email: `bot@elparche.co`
- Las cuentas `medellinlocal`, `bogotalocal`, `guia-calilocal` tienen email sin verificar (rate limit 60/hr)

## Archivos Relevantes
- `C:\Users\DIEGO\Desktop\moweb\billing-db.json` — base de datos de pagos
- `C:\Users\DIEGO\Desktop\moweb\elparche-agent\` — agente, scripts, EXEs
- `C:\Users\DIEGO\Desktop\moweb\admintaller\index.html` — panel admin
- `C:\Users\DIEGO\Desktop\moweb\admintaller\mp-success.html` — post-checkout MP
- `C:\Users\DIEGO\Desktop\moweb\.github\workflows\mp-monitor.yml` — monitor cada 30 min
- `C:\Users\DIEGO\Desktop\moweb\.github\workflows\process-submission.yml` — crea suscripciones
- `C:\Users\DIEGO\Desktop\moweb\.github\workflows\process-payment.yml` — activa venues
- `C:\Users\DIEGO\Desktop\moweb\.github\workflows\deploy.yml` — despliegue Pages
- `C:\Users\DIEGO\Desktop\moweb\reportes\` — CSVs generados por ExportData
