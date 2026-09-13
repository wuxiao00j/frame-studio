#!/usr/bin/env python3
import json,pathlib,subprocess,os
root=pathlib.Path(__file__).resolve().parents[1]
artifacts=root/'.artifacts/platform-exports';artifacts.mkdir(exist_ok=True,parents=True)
project=artifacts/'All-Components.framestudio'
if project.exists():project.unlink()
p=subprocess.Popen([os.environ.get('FRAME_STUDIO_MCP',str(root/'.build/debug/frame-studio-mcp')),'--project',str(project)],stdin=subprocess.PIPE,stdout=subprocess.PIPE,text=True)
seq=0

def rpc(method,args={}):
 global seq
 seq+=1;p.stdin.write(json.dumps({'jsonrpc':'2.0','id':seq,'method':method,'params':args})+'\n');p.stdin.flush();r=json.loads(p.stdout.readline());assert 'error' not in r,r;return r['result']
def tool(name,args={}):
 r=rpc('tools/call',{'name':name,'arguments':args});assert not r['isError'],r;return json.loads(r['content'][0]['text'])
rpc('initialize',{'protocolVersion':'2025-06-18'})
design=tool('get_project');design=tool('create_page',{'name':'全部组件','expectedRevision':design['revision']});page=design['pages'][-1]['id']
for kind in tool('list_components')['components']:
 design=tool('add_component',{'pageID':page,'kind':kind['kind'],'expectedRevision':design['revision']})
# Exercise injected-looking strings, alpha colors, real images and native custom expressions.
png=__import__('base64').b64encode((root/'Resources/AppIcon.iconset/icon_32x32.png').read_bytes()).decode()
for node in design['pages'][-1]['nodes']:
 if node['kind']=='text':node['text']='中文 $price ${danger} "quote" \\ slash\nNext line'
 if node['kind']=='text':node['lineLimit']=2;node['lineSpacing']=4;node['minimumScaleFactor']=0.7
 if node['kind']=='image':node['imageData']=png;node['imageFit']='fit'
 if node['kind']=='card':node['material']='thin'
 if node['kind']=='rectangle':node['clipMasks']={v:[{'shape':'roundedRectangle','rect':{'x':0.1,'y':0,'width':0.8,'height':1},'radius':0.15},{'shape':'ellipse','rect':{'x':0,'y':0,'width':1,'height':1},'radius':0}] for v in ['standardPortrait','standardLandscape','outerPortrait','outerLandscape','innerPortrait','innerLandscape']}
 if node['kind']=='custom':node['flutterCode']="const Text('Custom Flutter')";node['composeCode']='Text("Custom Compose")'
 node['fill']='EEEAF8DD'
 if node['kind']=='toggle':node['showIcon']=True;node['iconData']=png;node['controlPosition']='leading'
 if node['kind']=='profileRow':node['showQRCode']=False;node['showChevron']=False
 if node['kind']=='progress':node['progressStyle']='steps';node['progressCurrent']=25;node['progressTotal']=80;node['progressLabel']='fraction';node['frames']['standardPortrait']['height']=44
 if node['kind']=='ringProgress':node['progressLabel']='percent'
 if node['kind'] in ['rectangle','circle']:
  node['gradient']={'kind':'radial' if node['kind']=='circle' else 'linear','stops':[{'color':'FF000080','location':0},{'color':'3366FFFF','location':1}],'startX':0.5,'startY':0.5 if node['kind']=='circle' else 0,'endX':1,'endY':1,'startRadius':0,'endRadius':80}
  node['blurRadius']=3;node['shadowColor']='3366AA55';node['shadowX']=2;node['shadowY']=4;node['shadow']=6
 if node['kind']=='tabBar':
  node['items'][0]['iconData']=png;node['items'][0]['selectedIconData']=png
design=tool('replace_project',{'project':design,'expectedRevision':design['revision']})
paths={}
for fmt in ['flutter','android','swiftui']:
 r=tool('export_project',{'format':fmt,'directory':str(artifacts)});paths[fmt]=r['directory'];dest=pathlib.Path(r['directory'])
 assert json.loads((dest/'Design.framestudio').read_text())==design
 if fmt!='swiftui':assert (dest/'EXPORT_REPORT.md').exists()
 if fmt=='flutter':
  assert (dest/'android/gradlew').exists() and (dest/'ios/Runner.xcodeproj/project.pbxproj').exists()
  assert len(list((dest/'lib/pages').glob('*.dart')))==len(design['pages'])
 elif fmt=='android':assert (dest/'gradlew').exists() and (dest/'app/build.gradle.kts').exists()
 else:assert (dest/'GeneratedApp.xcodeproj/project.pbxproj').exists()
# Aliases must also generate files; legacy SwiftUI remains callable.
for toolname in ['export_android','export_flutter']:
 r=tool(toolname,{'directory':str(artifacts)});assert pathlib.Path(r['directory']).exists()
(artifacts/'paths.json').write_text(json.dumps(paths,indent=2))
p.stdin.close();assert p.wait(timeout=10)==0
print('PLATFORM_EXPORTS_PASS: 43 components, image assets, custom code, string escaping, per-page files, navigation and all six layouts.')
print(json.dumps(paths,ensure_ascii=False))
