const fs = require('fs');
const fixes = {
  'eje-cafetero': ['Eje cafetero', 'Eje Cafetero'],
  'san-agustin': ['San agustin', 'San Agustin'],
  'san-andres': ['San andres', 'San Andres'],
  'san-gil': ['San gil', 'San Gil'],
  'santa-marta': ['Santa marta', 'Santa Marta'],
  'villa-de-leyva': ['Villa de leyva', 'Villa de Leyva']
};
for (const city in fixes) {
  const fp = 'C:\\Users\\DIEGO\\Desktop\\moweb\\' + city + '\\index.html';
  let content = fs.readFileSync(fp, 'utf8');
  const [before, after] = fixes[city];
  if (content.indexOf(before) !== -1) {
    content = content.replace(before, after);
    fs.writeFileSync(fp, content, 'utf8');
    console.log(city + ': fixed "' + before + '" -> "' + after + '"');
  } else {
    console.log(city + ': "' + before + '" not found');
  }
}
