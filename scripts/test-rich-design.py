#!/usr/bin/env python3
import pathlib,json,subprocess,os
root=pathlib.Path(__file__).resolve().parents[1];folder=root/'.artifacts/rich-design';folder.mkdir(parents=True,exist_ok=True)
project=folder/'Rich.framestudio'
if project.exists():project.unlink()
p=subprocess.Popen([os.environ.get('FRAME_STUDIO_MCP',str(root/'.build/debug/frame-studio-mcp')),'--project',str(project)],stdin=subprocess.PIPE,stdout=subprocess.PIPE,text=True)
i=0
def rpc(method,params={}):
 global i
 i+=1;p.stdin.write(json.dumps({'jsonrpc':'2.0','id':i,'method':method,'params':params})+'\n');p.stdin.flush();return json.loads(p.stdout.readline())['result']
def tool(name,args={}):
 result=rpc('tools/call',{'name':name,'arguments':args});assert not result['isError'],result;return json.loads(result['content'][0]['text'])
rpc('initialize',{'protocolVersion':'2025-06-18'})
design=tool('get_project');design=tool('create_page',{'name':'长页面验收','expectedRevision':design['revision']});page=design['pages'][-1]['id']
def add(kind,props={}):
 global design
 design=tool('add_component',{'pageID':page,'kind':kind,'properties':props,'expectedRevision':design['revision']});return design['pages'][-1]['nodes'][-1]['id']
rows=[add('listRow') for _ in range(3)]
rs=design['pages'][-1]['nodes'];assert rs[1]['frames']['standardPortrait']['y']==rs[0]['frames']['standardPortrait']['y']+rs[0]['frames']['standardPortrait']['height']
assert len({n['rowGroupID'] for n in rs})==1
design=tool('update_page',{'pageID':page,'scrollEnabled':True,'contentHeights':{'standardPortrait':2000},'expectedRevision':design['revision']})
toggle=add('toggle',{'controlPosition':'leading','showIcon':True,'frames':{'standardPortrait':{'x':24,'y':450,'width':345,'height':52}}})
icon=str(root/'Resources/AppIcon.iconset/icon_32x32.png')
design=tool('import_icon',{'nodeID':toggle,'path':icon,'expectedRevision':design['revision']})
assert design['pages'][-1]['nodes'][-1]['iconData']
progress=add('progress',{'progressStyle':'circular','progressLabel':'fraction','progressCurrent':25,'progressTotal':80,'frames':{'standardPortrait':{'x':24,'y':550,'width':100,'height':100}}})
tab=add('tabBar')
design=tool('update_component',{'nodeID':tab,'expectedRevision':design['revision'],'properties':{'items':[{'id':'home-item','title':'首页','symbol':'house','selectedSymbol':'house.fill','pageID':design['pages'][0]['id']}]}})
design=tool('import_icon',{'nodeID':tab,'itemID':'home-item','path':icon,'selected':True,'expectedRevision':design['revision']})
assert design['pages'][-1]['nodes'][-1]['items'][0]['selectedIconData']
design=tool('create_component_template',{'pageID':page,'nodeIDs':[rows[0],toggle],'name':'通知组合','expectedRevision':design['revision']})
template=design['templates'][-1];assert template['name']=='通知组合'
design=tool('insert_component_template',{'pageID':page,'templateID':template['id'],'x':36,'y':1100,'variant':'standardPortrait','expectedRevision':design['revision']})
assert min(n['frames']['standardPortrait']['y'] for n in design['pages'][-1]['nodes'][-2:])==1100
profile=add('profileRow',{'showQRCode':False,'showChevron':False,'frames':{'standardPortrait':{'x':24,'y':1650,'width':345,'height':100}}})
before=len(design['pages'][-1]['nodes']);design=tool('decompose_component',{'nodeID':profile,'expectedRevision':design['revision']})
assert len(design['pages'][-1]['nodes'])>before
assert all(not n['groupID'] for n in design['pages'][-1]['nodes'][before-1:])
assert not any(n['id']==profile for n in design['pages'][-1]['nodes'])
source=folder/'Legacy.dart';source.write_text("import 'package:flutter/material.dart'; Widget build() => Column(children: [SwitchListTile(title: Text('通知'), value:true, onChanged:(_){}), CircularProgressIndicator(value:0.6), AwesomeNebulaPanel()]);")
report=tool('inspect_ui_project',{'path':str(source)})
assert any(c['componentKind']=='toggle' for c in report['classifications'])
assert any(c['typeName']=='AwesomeNebulaPanel' for c in report['unmatched'])
text_node=add('text')
rendering={'lineLimit':2,'lineSpacing':5,'minimumScaleFactor':0.7,'imageFit':'fit','material':'thin','clipMasks':{'standardPortrait':[{'shape':'ellipse','rect':{'x':0,'y':0,'width':1,'height':1},'radius':0}]}}
design=tool('update_component',{'nodeID':text_node,'properties':rendering,'expectedRevision':design['revision']})
actual=design['pages'][-1]['nodes'][-1]
assert all(actual[k]==v for k,v in rendering.items())
before=project.read_bytes()
invalid=rpc('tools/call',{'name':'update_component','arguments':{'nodeID':text_node,'properties':{'minimumScaleFactor':0},'expectedRevision':design['revision']}})
assert invalid['isError'] and project.read_bytes()==before
design=tool('update_component',{'nodeID':text_node,'properties':{k:None for k in rendering},'expectedRevision':design['revision']})
assert all(k not in design['pages'][-1]['nodes'][-1] for k in rendering)
paths={}
for fmt in ['swiftui','flutter','android']:
 paths[fmt]=tool('export_project',{'format':fmt,'directory':str(folder)})['directory']
(folder/'paths.json').write_text(json.dumps(paths,indent=2))
p.stdin.close();assert p.wait(timeout=10)==0
print('RICH_DESIGN_PASS: joined rows, long-page settings, icon uploads, selected Tab icons, reusable composite, decomposition and import classification.')
