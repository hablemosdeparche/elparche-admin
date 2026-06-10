// Cloudflare Worker — Recibe webhooks de Mercado Pago y gatilla workflows de GitHub
// Deploy: wrangler deploy _webhook-worker.js
// Configurar en MP: https://www.mercadopago.com.ar/developers/panel/webhooks

const GITHUB_TOKEN = 'ghp_tu_token_aqui'; // Reemplazar con fine-grained PAT con actions:write
const GITHUB_OWNER = 'hablemosdeparche';
const GITHUB_REPO = 'elparche-admin';
const WORKFLOW_FILE = 'process-payment.yml';

async function handleRequest(request) {
  if (request.method !== 'POST') return new Response('OK', { status: 200 });

  try {
    const data = await request.json();
    const tipo = data.type || data.action || '';

    // MP webhook: subscription_authorized_payment
    if (tipo === 'subscription_authorized_payment' || tipo === 'authorized_payment') {
      const subId = data.data?.id || data.id;
      const externalRef = data.data?.external_reference || data.external_reference;

      // Extraer issue_number del external_reference (formato: elparche-123)
      let issueNumber = '';
      if (externalRef && externalRef.startsWith('elparche-')) {
        issueNumber = externalRef.replace('elparche-', '');
      }

      if (issueNumber) {
        await dispatchWorkflow(issueNumber);
        return new Response(JSON.stringify({ triggered: true, issue: issueNumber }), {
          headers: { 'Content-Type': 'application/json' }
        });
      }
    }

    return new Response('OK', { status: 200 });
  } catch (e) {
    return new Response('Error: ' + e.message, { status: 500 });
  }
}

async function dispatchWorkflow(issueNumber) {
  const resp = await fetch(
    `https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/actions/workflows/${WORKFLOW_FILE}/dispatches`,
    {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${GITHUB_TOKEN}`,
        'Content-Type': 'application/json',
        'Accept': 'application/vnd.github+json'
      },
      body: JSON.stringify({
        ref: 'main',
        inputs: { issue_number: issueNumber }
      })
    }
  );

  if (!resp.ok) {
    const text = await resp.text();
    throw new Error(`GitHub API error: ${resp.status} - ${text}`);
  }
}

addEventListener('fetch', event => {
  event.respondWith(handleRequest(event.request));
});
