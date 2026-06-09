# Setup del Sistema Automatizado — El Parche

---

## Estructura final del proyecto

```
moweb/
├── admintaller/          ← Web independiente para todas las ciudades (GitHub Pages)
│   └── index.html         ← Formulario + pagos Bold
├── cartagena/             ← Guía de Cartagena
├── bogota/                ← Guía de Bogotá
├── medellin/              ← Guía de Medellín
├── ... (50+ ciudades)
├── .github/workflows/
│   ├── process-submission.yml   ← Crea checkout Bold + espera pago
│   └── process-payment.yml      ← Cuando paga: actualiza HTML de la ciudad
│   └── monthly-billing.yml      ← Cada mes: oculta vencidos
└── cartagena-local-automation/  ← Scripts locales
    ├── ejecutar.bat
    ├── config.ps1
    └── scripts/
        ├── web-processor.ps1
        ├── billing-manager.ps1
        ├── html-manager.ps1
        ├── github-manager.ps1
        └── ...
```

---

## 1. Crear repositorio central en GitHub

1. Andá a https://github.com/new
2. Nombre del repo: **elparche-admin** (o el que quieras)
3. **Privado** o **Público** (si es público, el token en JS es visible)
4. Subí toda la carpeta `moweb/` a este repo

## 2. Configurar GitHub Pages

```
Settings > Pages > Source: Deploy from branch > main / (root) > Save
```

Tu admin panel va a estar en: `https://TUUSUARIO.github.io/elparche-admin/admintaller/`

## 3. Conseguir API Key de Bold

Bold es el procesador de pagos colombiano. Acá te explico cómo obtener tu API key:

1. Ingresá a https://bold.co y creá tu cuenta (ya dijiste que tenés una)
2. Andá a **Configuración > Desarrollo > API Keys**
3. Copiá tu **Llave de identidad** (Identity API Key)
4. Guardala, la vas a necesitar

## 4. Configurar GitHub Secrets

En tu repo central: **Settings > Secrets and variables > Actions**

### Agregá estos secrets:

| Secret | Valor |
|--------|-------|
| `BOLD_API_KEY` | Tu llave de identidad de Bold |
| `CARTAGENA_PAT` | Token de GitHub para hablemosdeparche/cartagena-local |
| `BOGOTA_PAT` | Token para bogotalocal/bogota |
| `MEDELLIN_PAT` | Token para medellinlocal/medellin |
| ... | (por cada ciudad que tengas) |

### OPCIÓN: Un solo token para todo

Si querés usar un solo token que tenga acceso a TODOS los repos de ciudades,
creá un token con scope `repo` y guardalo como:

| Secret | Valor |
|--------|-------|
| `GLOBAL_PAT` | Token con acceso a todos los repos |

---

## 5. Qué hacer con las ciudades que NO tienen repo

De las 50+ ciudades en `config.ps1`, solo algunas tienen repos creados
(cartagena, bogota, medellin, cali, santa-marta, etc.).

Las ciudades sin repo funcionan igual: el formulario las lista,
y cuando alguien paga, el workflow intenta pushear al repo.
Si el repo no existe, falla y el issue queda como recordatorio.

**Recomendación**: creá repos solo para las ciudades que tienen
35+ venues activos. Las demás se habilitan cuando alcancen ese mínimo.

---

## 6. Editar el HTML del admin panel

En `admintaller/index.html`, buscá estas líneas (alrededor de la línea 450):

```javascript
const CONFIG = {
  githubToken: '{{GITHUB_PAT}}',      // Tu token personal de GitHub
  githubOwner: '{{GITHUB_OWNER}}',    // Tu usuario de GitHub
  githubRepo: '{{GITHUB_REPO}}',      // Nombre del repo central (ej: elparche-admin)
  boldApiKey: '{{BOLD_API_KEY}}',     // Tu llave de Bold
};
```

Reemplazá los `{{...}}` con tus valores reales.

---

## 7. Cómo fluye el pago con Bold

```
1. Cliente llena formulario en admintaller/index.html
2. JavaScript crea checkout en Bold via API
3. Muestra link de pago al cliente
4. Crea un GitHub Issue con los datos + referencia Bold
5. Cliente paga (Nequi, PSE, tarjeta, etc.)
6. GitHub Actions (process-submission.yml) detecta nuevo issue
7. Workflow crea checkout en Bold (si no existe) y espera el pago
8. Workflow consulta Bold cada 30 segundos
9. Cuando Bold confirma: workflow process-payment.yml se activa
10. Clona el repo de la ciudad, edita index.html, pushea
11. Cierra el issue con mensaje de éxito
```

**Tiempo total**: el pago se confirma en segundos (Nequi/PSE) o minutos (tarjeta).
La ficha se activa automaticamente.

---

## 8. Si el pago NO se completa

- El issue queda abierto con estado `bold-status:pending`
- Después de 30 minutos, el workflow deja de esperar
- El cliente puede volver a generar un link de pago desde el formulario
- O pagar manualmente y enviar comprobante por WhatsApp

---

## 9. Costos (todo GRATIS)

| Servicio | Costo | Límite |
|----------|-------|--------|
| GitHub Actions | **$0** | 2000 min/mes (~600 procesamientos) |
| GitHub Pages | **$0** | Ilimitado |
| Bold | **$0** | Sin costo fijo (comisión por transacción) |
| ImgBB | **$0** | 10k visitas/día |

**Total: $0 de costo fijo.** Solo pagás la comisión de Bold por cada pago recibido.

---

## 10. Resumen: checklist de setup

- [ ] Crear repo central en GitHub
- [ ] Subir carpeta moweb/
- [ ] Activar GitHub Pages
- [ ] Obtener API key de Bold
- [ ] Crear PAT de GitHub
- [ ] Guardar secrets en GitHub
- [ ] Editar admintaller/index.html con tokens
- [ ] Crear repos para las ciudades existentes
- [ ] Probar con un pago de $1.000 desde el formulario
