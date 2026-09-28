import sys, re, json, os, collections
root, bj, exef = sys.argv[1], sys.argv[2], sys.argv[3]
B=json.load(open(bj)); blz=set(B['globals']); ns={k:set(v) for k,v in B['ns'].items()}
exe=set(l.strip() for l in open(exef,encoding='utf-8',errors='ignore'))
lua_builtin=set('assert collectgarbage date error getmetatable ipairs load loadstring next pairs pcall print rawequal rawget rawset select setmetatable tonumber tostring type unpack xpcall require setfenv getfenv math string table coroutine bit os debug strsplit strjoin strtrim strlower strupper strfind strsub strlen strrep strbyte strchar format gsub tinsert tremove wipe sort floor ceil abs max min random mod time difftime hooksecurefunc issecurevariable securecall geterrorhandler seterrorhandler debugstack'.split())
files=[]
for d,_,fs in os.walk(root):
    for f in fs:
        if f.endswith('.lua'): files.append(os.path.join(d,f))
src={f:open(f,encoding='utf-8',errors='ignore').read() for f in files}
defined=set()
for s in src.values():
    s2=re.sub(r'--\[(=*)\[.*?\]\1\]','',s,flags=re.S)
    defined.update(re.findall(r'function\s+([A-Za-z_]\w*)\s*\(',s2))
    defined.update(re.findall(r'local\s+function\s+([A-Za-z_]\w*)',s2))
    for m in re.findall(r'local\s+([\w\s,]+?)\s*=',s2):
        defined.update(x.strip() for x in m.split(','))
    defined.update(re.findall(r'^\s*([A-Za-z_]\w*)\s*=',s2,re.M))
    defined.update(re.findall(r'_G\[?\.?["\']?([A-Za-z_]\w*)["\']?\]?\s*=',s2))
    for m in re.findall(r'function\s*\(([^)]*)\)',s2):
        defined.update(x.strip() for x in m.split(','))
    for m in re.findall(r'for\s+([\w\s,]+?)\s+in',s2):
        defined.update(x.strip() for x in m.split(','))
miss=collections.defaultdict(list); missns=collections.defaultdict(list)
for f,s in src.items():
    for i,line in enumerate(s.split('\n'),1):
        code=line.split('--')[0]
        for m in re.finditer(r'(?<![\w.:])([A-Z][A-Za-z0-9_]+)\s*\(',code):
            n=m.group(1)
            if n in defined or n in blz or n in exe or n in lua_builtin: continue
            miss[n].append(f"{os.path.relpath(f,root)}:{i}")
        for m in re.finditer(r'(?<![\w.:])(C_\w+)\.(\w+)',code):
            a,b=m.groups()
            if (a in ns and b in ns[a]) or b in exe: continue
            missns[f"{a}.{b}"].append(f"{os.path.relpath(f,root)}:{i}")
for k,v in sorted(miss.items(),key=lambda x:-len(x[1])): print(f"{k} x{len(v)}  {v[0]}")
print('--- namespaced')
for k,v in sorted(missns.items(),key=lambda x:-len(x[1])): print(f"{k} x{len(v)}  {v[0]}")
