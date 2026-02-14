import re, os

src_dir = 'weather/Sources'
swift_files = []
for root, dirs, files in os.walk(src_dir):
    for f in files:
        if f.endswith('.swift'):
            swift_files.append(os.path.join(root, f))

for filepath in sorted(swift_files):
    with open(filepath) as fh:
        content = fh.read()
    lines = content.split('\n')
    
    brace_depth = 0
    issues = []
    in_multiline_comment = False
    
    for i, line in enumerate(lines, 1):
        stripped = line.strip()
        
        if '/*' in stripped and not in_multiline_comment:
            in_multiline_comment = True
        if '*/' in stripped:
            in_multiline_comment = False
            continue
        if in_multiline_comment:
            continue
        if stripped.startswith('//'):
            continue
        if not stripped:
            continue
        
        code_line = re.sub(r'"[^"]*"', '""', stripped)
        opens = code_line.count('{')
        closes = code_line.count('}')
        
        if brace_depth == 0:
            exec_patterns = [
                r'^print\s*\(',
                r'^debugPrint\s*\(',
                r'^Task\s*\{',
                r'^Task\.\w',
                r'^if\s',
                r'^guard\s',
                r'^switch\s',
                r'^for\s',
                r'^while\s',
                r'^repeat\s',
                r'^do\s*\{',
                r'^return\s',
                r'^try\s',
                r'^await\s',
                r'^fatalError\s*\(',
                r'^precondition\s*\(',
                r'^assert\s*\(',
            ]
            
            is_exec = any(re.match(p, stripped) for p in exec_patterns)
            
            if is_exec:
                issues.append((i, stripped[:120]))
        
        brace_depth += opens - closes
    
    if issues:
        print(f'*** ISSUES IN: {filepath} ***')
        for line_no, text in issues:
            print(f'  Line {line_no}: {text}')

print('\n--- Script complete ---')
