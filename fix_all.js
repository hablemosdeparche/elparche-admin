const fs = require('fs');
const path = require('path');
const base = 'C:\\Users\\DIEGO\\Desktop\\moweb';

const svgNoise = [
  'body::before {',
  "  content: '';",
  '  position: fixed;',
  '  inset: 0;',
  '  background-image: url("data:image/svg+xml,%3Csvg viewBox=\'0 0 256 256\' xmlns=\'http://www.w3.org/2000/svg\'%3E%3Cfilter id=\'n\'%3E%3CfeTurbulence type=\'fractalNoise\' baseFrequency=\'0.9\' numOctaves=\'4\' stitchTiles=\'stitch\'/%3E%3C/filter%3E%3Crect width=\'100%25\' height=\'100%25\' filter=\'url(%23n)\' opacity=\'0.04\'/%3E%3C/svg%3E");',
  '  pointer-events: none;',
  '  z-index: 0;',
  '  opacity: 0.5;',
  '}',
].join('\n');

const pexelsByCategory = {
  bares: ['images.pexels.com/photos/2741312/pexels-photo-2741312.jpeg?w=1920','images.pexels.com/photos/260922/pexels-photo-260922.jpeg?w=1920','images.pexels.com/photos/7573895/pexels-photo-7573895.jpeg?w=1920','images.pexels.com/photos/2741312/pexels-photo-2741312.jpeg?w=1920','images.pexels.com/photos/260922/pexels-photo-260922.jpeg?w=1920','images.pexels.com/photos/7573895/pexels-photo-7573895.jpeg?w=1920'],
  cafe: ['images.pexels.com/photos/312418/pexels-photo-312418.jpeg?w=1920','images.pexels.com/photos/302902/pexels-photo-302902.jpeg?w=1920','images.pexels.com/photos/1695052/pexels-photo-1695052.jpeg?w=1920','images.pexels.com/photos/312418/pexels-photo-312418.jpeg?w=1920','images.pexels.com/photos/302902/pexels-photo-302902.jpeg?w=1920'],
  comida: ['images.pexels.com/photos/262978/pexels-photo-262978.jpeg?w=1920','images.pexels.com/photos/375889/pexels-photo-375889.jpeg?w=1920','images.pexels.com/photos/2295285/pexels-photo-2295285.jpeg?w=1920','images.pexels.com/photos/262978/pexels-photo-262978.jpeg?w=1920','images.pexels.com/photos/375889/pexels-photo-375889.jpeg?w=1920','images.pexels.com/photos/2295285/pexels-photo-2295285.jpeg?w=1920','images.pexels.com/photos/262978/pexels-photo-262978.jpeg?w=1920','images.pexels.com/photos/375889/pexels-photo-375889.jpeg?w=1920'],
  arte: ['images.pexels.com/photos/236698/pexels-photo-236698.jpeg?w=1920','images.pexels.com/photos/1194420/pexels-photo-1194420.jpeg?w=1920','images.pexels.com/photos/5962234/pexels-photo-5962234.jpeg?w=1920','images.pexels.com/photos/236698/pexels-photo-236698.jpeg?w=1920'],
  plan: ['images.pexels.com/photos/3214958/pexels-photo-3214958.jpeg?w=1920','images.pexels.com/photos/1761279/pexels-photo-1761279.jpeg?w=1920','images.pexels.com/photos/206660/pexels-photo-206660.jpeg?w=1920','images.pexels.com/photos/3214958/pexels-photo-3214958.jpeg?w=1920','images.pexels.com/photos/1761279/pexels-photo-1761279.jpeg?w=1920','images.pexels.com/photos/206660/pexels-photo-206660.jpeg?w=1920'],
  noche: ['images.pexels.com/photos/1285647/pexels-photo-1285647.jpeg?w=1920','images.pexels.com/photos/696407/pexels-photo-696407.jpeg?w=1920','images.pexels.com/photos/167092/pexels-photo-167092.jpeg?w=1920','images.pexels.com/photos/1285647/pexels-photo-1285647.jpeg?w=1920','images.pexels.com/photos/696407/pexels-photo-696407.jpeg?w=1920','images.pexels.com/photos/167092/pexels-photo-167092.jpeg?w=1920'],
};

const cities = [
  'medellin','bogota','barranquilla','cali','bucaramanga','eje-cafetero','guatape',
  'leticia','mompox','nuqui','popayan','providencia','san-agustin','san-andres',
  'san-gil','santa-marta','villa-de-leyva'
];

for (const city of cities) {
  const fp = path.join(base, city, 'index.html');
  if (!fs.existsSync(fp)) { console.log(city + ': NOT FOUND'); continue; }
  
  let content = fs.readFileSync(fp, 'utf8');
  const changes = [];
  
  // 1. Fix body::before
  if (content.indexOf('body::before { display: none; }') !== -1) {
    content = content.replace('body::before { display: none; }', svgNoise);
    changes.push('body::before SVG');
  }
  
  // 2. Add images
  const cats = [];
  const catRe = /cat:'(\w+)'/g;
  let m;
  while ((m = catRe.exec(content)) !== null) cats.push(m[1]);
  
  const counters = {};
  let imgCount = 0;
  content = content.replace(/img:''/g, function() {
    const cat = cats[imgCount] || 'plan';
    if (!counters[cat]) counters[cat] = 0;
    const list = pexelsByCategory[cat] || pexelsByCategory.plan;
    const url = 'https://' + list[counters[cat] % list.length];
    counters[cat]++;
    imgCount++;
    return "img:'" + url + "'";
  });
  if (imgCount > 0) changes.push(imgCount + ' images');
  
  // 3. Fix URL
  content = content.replace(/https:\/\/cartagenalocal\.github\.io\/elparche-admin\/admintaller\//g, 'https://hablemosdeparche.github.io/elparche-admin/admintaller/');
  if (content.indexOf('cartagenalocal.github.io') === -1) changes.push('URL updated');
  
  // 4. Fix "Cartagena" in eventos text
  content = content.replace('Pr\u00f3ximos eventos en Cartagena', 'Pr\u00f3ximos eventos en ' + cityNames(city));
  
  // 5. Fix "Cartagena" in sharePlace
  content = content.replace(/Mira este parche en Cartagena Local/g, 'Mira este parche en ' + cityNames(city) + ' Local');
  
  // 6. Fix "Hero compacto con imagen de Cartagena" CSS comment
  content = content.replace(/Hero compacto con imagen de Cartagena/g, 'Hero compacto con imagen de ' + cityNames(city));
  
  
  // Check remaining Cartagena refs
  const ctgCount = (content.match(/Cartagena/g) || []).length;
  if (ctgCount > 0) changes.push(ctgCount + 'x Cartagena remaining');
  else changes.push('text OK');
  
  fs.writeFileSync(fp, content, 'utf8');
  console.log(city + ': ' + changes.join(', '));
}

function cityNames(city) {
  const map = {
    medellin: 'Medellin', bogota: 'Bogota', barranquilla: 'Barranquilla',
    cali: 'Cali', bucaramanga: 'Bucaramanga', 'eje-cafetero': 'Eje Cafetero',
    guatape: 'Guatape', leticia: 'Leticia', mompox: 'Mompox', nuqui: 'Nuqui',
    popayan: 'Popayan', providencia: 'Providencia', 'san-agustin': 'San Agustin',
    'san-andres': 'San Andres', 'san-gil': 'San Gil', 'santa-marta': 'Santa Marta',
    'villa-de-leyva': 'Villa de Leyva'
  };
  return map[city] || city;
}
