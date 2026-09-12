#!/usr/bin/env python3
"""Audit only curated source files or explicitly selected release archives."""
import argparse,pathlib,re,subprocess,zipfile
p=argparse.ArgumentParser();p.add_argument('--tracked',action='store_true');p.add_argument('--archive',action='append',default=[]);a=p.parse_args()
root=pathlib.Path(__file__).resolve().parents[1]
forbidden={'.apk','.aab','.ipa','.dmg','.keystore','.jks','.p12','.mobileprovision'}
problems=[]
if a.tracked:
 files=subprocess.check_output(['git','ls-files','-z'],cwd=root).decode().split('\0')
 for raw in filter(None,files):
  file=root/raw;path=pathlib.PurePosixPath(raw)
  if path.parts[0] in ['.artifacts','.build','dist'] or file.suffix.lower() in forbidden or '.app' in ''.join(path.suffixes):problems.append('disallowed source path: '+raw)
  if file.name in ['local.properties','.env','.DS_Store'] or file.name.startswith('.env.'):problems.append('local configuration: '+raw)
  if file.is_symlink():problems.append('symlink requires review: '+raw);continue
  data=file.read_bytes()
  if b'\0' in data:continue
  text=data.decode('utf-8',errors='replace')
  if raw!='scripts/audit-release.py' and re.search(r'/Users/[^/\s\"\']+/|/Volumes/[^/\s\"\']+/',text):problems.append('personal machine path: '+raw)
  if re.search(r'gh[pousr]_[A-Za-z0-9]{24,}|github_pat_[A-Za-z0-9_]{30,}|-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----',text):problems.append('credential-like content: '+raw)
for archive in a.archive:
 with zipfile.ZipFile(archive) as z:
  for info in z.infolist():
   path=pathlib.PurePosixPath(info.filename)
   if pathlib.Path(info.filename).suffix.lower() in forbidden:problems.append('mobile package/signing file in archive: '+info.filename)
   if any(part in ['.artifacts','.git','.build','local.properties'] for part in path.parts):problems.append('private/build path in archive: '+info.filename)
   if path.name.endswith('.framestudio') and 'Demo.framestudio' not in path.name:problems.append('unexpected design document in archive: '+info.filename)
if problems:raise SystemExit('\n'.join(problems))
print('RELEASE_AUDIT_PASS')
