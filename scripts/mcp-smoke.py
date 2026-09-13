#!/usr/bin/env python3
"""Read-only MCP handshake check; uses a temporary project unless --project is given."""
import argparse,json,pathlib,subprocess,tempfile
p=argparse.ArgumentParser();p.add_argument('binary');p.add_argument('--project');a=p.parse_args()
with tempfile.TemporaryDirectory(prefix='frame-studio-mcp-') as temp:
    path=a.project or str(pathlib.Path(temp)/'Smoke.framestudio')
    requests=[{'jsonrpc':'2.0','id':1,'method':'initialize','params':{'protocolVersion':'2025-06-18','capabilities':{},'clientInfo':{'name':'frame-studio-smoke','version':'1'}}},{'jsonrpc':'2.0','method':'notifications/initialized'},{'jsonrpc':'2.0','id':2,'method':'tools/list'},{'jsonrpc':'2.0','id':3,'method':'tools/call','params':{'name':'get_project','arguments':{}}}]
    result=subprocess.run([str(pathlib.Path(a.binary).expanduser().resolve()),'--project',path],input='\n'.join(json.dumps(x) for x in requests)+'\n',text=True,capture_output=True,timeout=20,check=True)
    messages={m['id']:m for m in map(json.loads,result.stdout.splitlines())}
    assert messages[1]['result']['serverInfo']['name']=='frame-studio'
    assert len(messages[2]['result']['tools'])==28
    assert not messages[3]['result']['isError']
    print('MCP_SMOKE_PASS: '+messages[1]['result']['serverInfo']['version']+' · 28 tools · get_project OK')
