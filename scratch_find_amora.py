import os
import re

def find_amora(directory):
    pattern = re.compile(r'Amora(?!a)[^a-zA-Z]', re.IGNORECASE)
    results = []
    
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith('.dart'):
                filepath = os.path.join(root, file)
                with open(filepath, 'r', encoding='utf-8') as f:
                    try:
                        lines = f.readlines()
                        for i, line in enumerate(lines):
                            if pattern.search(line):
                                # Check if it's inside a string. Simplified check:
                                if "'" in line or '"' in line:
                                    results.append(f"{filepath}:{i+1}: {line.strip()}")
                    except:
                        pass
    return results

if __name__ == '__main__':
    res = find_amora('c:/Users/praja.HERRY/AMORA-AI/lib')
    for r in res:
        print(r)
