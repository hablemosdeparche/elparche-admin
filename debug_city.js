const fs = require('fs');
const content = fs.readFileSync('C:\\Users\\DIEGO\\Desktop\\moweb\\medellin\\index.html', 'utf8');

console.log('=== CARTAGENA REFERENCES ===');
let idx = content.indexOf('Cartagena');
while (idx !== -1) {
  const start = Math.max(0, idx - 30);
  const end = Math.min(content.length, idx + 30);
  console.log('pos ' + idx + ': ' + JSON.stringify(content.substring(start, end)));
  idx = content.indexOf('Cartagena', idx + 1);
}

console.log('\n=== IMG FORMAT ===');
const imgMatch = content.match(/img:''/);
const imgMatch2 = content.match(/img: '/);
const imgMatch3 = content.match(/img:'/);
console.log('img:"" (no space): ' + (imgMatch ? imgMatch.index : 'NOT FOUND'));
console.log('img: " (space): ' + (imgMatch2 ? imgMatch2.index : 'NOT FOUND'));
console.log('img:\' (no space): ' + (imgMatch3 ? content.substring(imgMatch3.index, imgMatch3.index + 15) : 'NOT FOUND'));

// Test the first image entry
const placesStart = content.indexOf('const places = [');
if (placesStart !== -1) {
  const placesEnd = content.indexOf('];', placesStart);
  const placesStr = content.substring(placesStart, placesEnd + 2);
  const firstFew = placesStr.substring(0, 300);
  console.log('\n=== FIRST PLACES ===');
  console.log(firstFew);
}

console.log('\n=== EVENTOS TEXT ===');
const evIdx = content.indexOf('Pr');
if (evIdx !== -1) {
  console.log('Pr at ' + evIdx + ': ' + JSON.stringify(content.substring(evIdx, evIdx + 40)));
}
const evIdx2 = content.indexOf('eventos en');
if (evIdx2 !== -1) {
  console.log('"eventos en" at ' + evIdx2 + ': ' + JSON.stringify(content.substring(evIdx2, evIdx2 + 40)));
}
