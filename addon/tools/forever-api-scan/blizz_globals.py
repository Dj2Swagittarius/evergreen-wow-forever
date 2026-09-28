import sys, re, json
sys.path.insert(0,'casc')
from forever_casc import Reader
r=Reader()
names=set(); ns_funcs={}; n_ok=n_bad=0
rx_fn=re.compile(r'^\s*function\s+([A-Za-z_][\w]*)\s*\(', re.M)
rx_ns=re.compile(r'^\s*function\s+([A-Za-z_]\w*)[.:]([A-Za-z_]\w*)\s*\(', re.M)
rx_as=re.compile(r'^([A-Za-z_][\w]*)\s*=', re.M)
# API docs: namespaced + global C functions
rx_docns=re.compile(r'Namespace = "([\w]+)"')
for line in open('MultiConverter-bin/listfile.csv',encoding='utf-8',errors='ignore'):
    fid,_,path=line.strip().partition(';')
    p=path.lower()
    if not p.startswith('interface/addons/') or not p.endswith('.lua'): continue
    try: d=r.read(int(fid)).decode('utf-8','ignore'); n_ok+=1
    except Exception: n_bad+=1; continue
    if 'apidocumentation' in p:
        m=rx_docns.search(d); nsn=m.group(1) if m else None
        for block in re.finditer(r'Name = "(\w+)",\s*Type = "Function"', d):
            if nsn: ns_funcs.setdefault(nsn,set()).add(block.group(1))
            else: names.add(block.group(1))
        continue
    names.update(rx_fn.findall(d)); names.update(rx_as.findall(d))
    for a,b in rx_ns.findall(d): pass
json.dump({'globals':sorted(names),'ns':{k:sorted(v) for k,v in ns_funcs.items()}},open(sys.argv[1],'w'))
print('files',n_ok,'unreadable',n_bad,'globals',len(names),'namespaces',len(ns_funcs))
