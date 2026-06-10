const fs = require('fs');
const base = 'C:\\Users\\DIEGO\\Desktop\\moweb';
const cities = ['medellin','bogota','barranquilla','cali','bucaramanga','eje-cafetero','guatape','leticia','mompox','nuqui','popayan','providencia','san-agustin','san-andres','san-gil','santa-marta','villa-de-leyva'];

for (const c of cities) {
  const fp = base + '\\' + c + '\\index.html';
  if (!fs.existsSync(fp)) { console.log(c + ': NOT FOUND'); continue; }
  const content = fs.readFileSync(fp, 'utf8');
  const m1 = content.match(/<title>(.*?)<\/title>/);
  const m2 = content.match(/<h1>(.*?)<\/h1>/);
  const m3 = content.match(/eventos en (.*?)</);
  const m4 = content.match(/en Cartagena Local/);
  const m5 = content.match(/href="https:\/\/(.*?)\/elparche-admin/);
  console.log(c + ': title=' + (m1 ? m1[1] : '?') + ' | h1=' + (m2 ? m2[1] : '?') + ' | eventos=' + (m3 ? m3[1] : '?') + ' | CartagenaRef=' + (m4 ? 'YES' : 'NO') + ' | URL=' + (m5 ? m5[1] : '?'));
}
