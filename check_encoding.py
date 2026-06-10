import os, glob

base = r'C:\Users\DIEGO\Desktop\moweb'
cities = ['cartagena','medellin','bogota','barranquilla','cali']

for city in cities:
    path = os.path.join(base, city, 'index.html')
    if not os.path.exists(path):
        continue
    with open(path, 'rb') as f:
        raw = f.read()
    content = raw.decode('utf-8')
    
    issues = []
    
    # Check for ?? corruption
    qq_count = content.count('??')
    if qq_count > 0:
        issues.append(f'{qq_count} x ??')
    
    # Check body::before
    if 'body::before { display: none; }' in content:
        issues.append('body::before DISABLED')
    elif 'fractalNoise' in content:
        issues.append('body::before SVG OK')
    else:
        issues.append('body::before UNKNOWN')
    
    # Check images
    img_count = content.count("img: ''")
    pexels_count = content.count('pexels.com')
    issues.append(f'img empty: {img_count}, pexels: {pexels_count}')
    
    # Check for encoding issues (replacement character)
    repl_char = '\ufffd'
    repl_count = content.count(repl_char)
    if repl_count > 0:
        issues.append(f'{repl_count} x replacement chars')
    
    # Check for corrupted Spanish chars
    for bad, good in [('aqu\ufffd', 'aquí'), ('a\ufffdo', 'año'), ('pr\ufffdximos', 'próximos')]:
        if bad in content:
            issues.append(f'has: {repr(bad)}')
    
    # Check emojis - search-box
    if '🔍' in content:
        issues.append('search emoji OK')
    else:
        issues.append('search emoji MISSING')
    
    print(f'{city}: {", ".join(issues)}')
