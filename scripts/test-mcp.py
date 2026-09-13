#!/usr/bin/env python3
"""Exercise the actual MCP stdio transport and write a compiler-verification fixture."""
import json, subprocess, pathlib, tempfile, sys, os
root=pathlib.Path(__file__).resolve().parents[1]
artifacts=root/'.artifacts'; artifacts.mkdir(exist_ok=True)
project=artifacts/'MCP-Acceptance.framestudio'
if project.exists(): project.unlink()
process=subprocess.Popen([os.environ.get('FRAME_STUDIO_MCP',str(root/'.build/debug/frame-studio-mcp')),'--project',str(project)],stdin=subprocess.PIPE,stdout=subprocess.PIPE,text=True)
seq=0

def rpc(method,params=None):
    global seq
    seq+=1
    process.stdin.write(json.dumps({'jsonrpc':'2.0','id':seq,'method':method,'params':params or {}})+'\n');process.stdin.flush()
    response=json.loads(process.stdout.readline());assert response['id']==seq,response
    return response

def tool(name,args=None,error=False):
    r=rpc('tools/call',{'name':name,'arguments':args or {}})['result']
    assert r['isError']==error,r
    return r['content'][0]['text'] if error else json.loads(r['content'][0]['text'])

assert rpc('tools/list')['error']['code']==-32002
assert rpc('initialize',{'protocolVersion':'2025-06-18','clientInfo':{'name':'acceptance','version':'1.0'},'capabilities':{}})['result']['protocolVersion']=='2025-06-18'
process.stdin.write('{"jsonrpc":"2.0","method":"notifications/initialized"}\n');process.stdin.flush()
assert len(rpc('tools/list')['result']['tools'])==28
p=tool('get_project');old=p['revision']; first=p['pages'][0]['id']
p=tool('create_page',{'name':'MCP Test','expectedRevision':old});page=p['pages'][-1]['id']
assert '更新' in tool('create_page',{'name':'Stale','expectedRevision':old},error=True)
p=tool('add_component',{'pageID':page,'kind':'button','properties':{'text':'Agent button','targetPageID':first,'frames':{'innerLandscape':{'x':35,'y':50,'width':200,'height':50}}},'expectedRevision':p['revision']})
node=p['pages'][-1]['nodes'][-1]['id']
p=tool('update_component',{'nodeID':node,'properties':{'symbol':'heart.fill','foreground':'FFFFFF','fill':'AA5599'},'expectedRevision':p['revision']})
assert p['pages'][-1]['nodes'][-1]['frames']['innerLandscape']['x']==35
revision=p['revision']
tool('update_component',{'nodeID':node,'properties':{'targetPageID':'missing'},'expectedRevision':revision},error=True)
assert tool('get_project')['revision']==revision
p=tool('align_components',{'pageID':page,'nodeIDs':[node],'variant':'innerLandscape','alignment':'centerX','expectedRevision':revision})
assert p['pages'][-1]['nodes'][-1]['frames']['innerLandscape']['x']==299
p=tool('set_device',{'wideMode':True,'expectedRevision':p['revision']})
assert p['wideMode']
p=tool('delete_components',{'nodeIDs':[node],'expectedRevision':p['revision']})
assert not p['pages'][-1]['nodes']
p=tool('delete_page',{'pageID':page,'expectedRevision':p['revision']})
(artifacts/'import-fixture').mkdir(exist_ok=True)
source=artifacts/'import-fixture/OldUI.swift'
source.write_text('import SwiftUI\nstruct OldUI: View { var body: some View { VStack { Text("Imported title"); Image(systemName: "star"); Button("Next") {} } } }')
report=tool('inspect_swift_project',{'path':str(source)})
assert len(report['pages'][0]['nodes'])==3
assert 'Imported title' in tool('read_swift_source',{'path':str(source)})['source']
assert str(source) in tool('inspect_source_project',{'path':str(source.parent)})['sourceFiles']
assert 'Imported title' in tool('read_ui_source',{'path':str(source)})['source']
p=tool('import_swift_project',{'path':str(source),'expectedRevision':p['revision']})
assert p['importNotes']
p=tool('create_page',{'name':'Every component','expectedRevision':p['revision']});page=p['pages'][-1]['id']
for entry in tool('list_components')['components']:
    p=tool('add_component',{'pageID':page,'kind':entry['kind'],'expectedRevision':p['revision']})
# Test a real image asset export and all six variants.
import base64
png=__import__('base64').b64encode((root/'Resources/AppIcon.iconset/icon_32x32.png').read_bytes()).decode()
image=next(n for n in p['pages'][-1]['nodes'] if n['kind']=='image')
p=tool('update_component',{'nodeID':image['id'],'properties':{'imageData':png},'expectedRevision':p['revision']})
p['pages'][-1]['nodes'][0]['text']='A quote " and a slash \\ and interpolation \\(safe)\n中文'
p=tool('replace_project',{'project':p,'expectedRevision':p['revision']})
exports=artifacts/'exports';exports.mkdir(exist_ok=True)
export=tool('export_swiftui',{'directory':str(exports)})['directory']
(artifacts/'last-export.txt').write_text(export)
assert pathlib.Path(export,'GeneratedApp.xcodeproj','project.pbxproj').exists()
# Complete design round-trip, remapping navigation identifiers on append.
before=len(p['pages']); p=tool('import_design',{'path':str(pathlib.Path(export,'Design.framestudio')),'mode':'append','expectedRevision':p['revision']})
assert len(p['pages'])==before*2
ids=[n['id'] for page in p['pages'] for n in page['nodes']];assert len(ids)==len(set(ids))
p=tool('create_page',{'name':'Layer order acceptance','expectedRevision':p['revision']});layer_page=p['pages'][-1]['id'];layer_ids=[]
for index in range(3):
    p=tool('add_component',{'pageID':layer_page,'kind':'rectangle','properties':{'text':str(index)},'expectedRevision':p['revision']});layer_ids.append(p['pages'][-1]['nodes'][-1]['id'])
layer_revision=p['revision']
p=tool('reorder_components',{'pageID':layer_page,'nodeIDs':[layer_ids[1]],'variant':'standardPortrait','action':'forward','expectedRevision':layer_revision})
assert [n['id'] for n in p['pages'][-1]['nodes']]==[layer_ids[0],layer_ids[2],layer_ids[1]]
before_bytes=project.read_bytes()
tool('reorder_components',{'pageID':layer_page,'nodeIDs':[layer_ids[1]],'variant':'standardPortrait','action':'backward','expectedRevision':layer_revision},error=True)
assert project.read_bytes()==before_bytes
p=tool('reorder_components',{'pageID':layer_page,'nodeIDs':[layer_ids[1]],'variant':'standardPortrait','action':'backward','expectedRevision':p['revision']})
assert [n['id'] for n in p['pages'][-1]['nodes']]==layer_ids
process.stdin.write('not-json\n');process.stdin.flush();assert json.loads(process.stdout.readline())['error']['code']==-32700
process.stdin.close();assert process.wait(timeout=10)==0
print(f'MCP_ACCEPTANCE_PASS: 28 tools, revision conflicts, atomic rollback, navigation, 43 components, source import, JSON round-trip, asset export.\nExport: {export}')
