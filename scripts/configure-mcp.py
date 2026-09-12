#!/usr/bin/env python3
"""Print portable MCP setup. Only --install-codex modifies client configuration."""
import argparse,json,pathlib,shlex,shutil,subprocess
p=argparse.ArgumentParser(description='Frame Studio MCP configuration / MCP 配置生成器')
p.add_argument('--app',default='/Applications/原境 Frame Studio.app',help='Installed macOS application bundle')
p.add_argument('--binary',help='Use a source-built MCP executable instead of an application bundle')
p.add_argument('--project',help='Absolute design document path; omit for the default workspace')
p.add_argument('--format',choices=['json','toml','command'],default='json')
p.add_argument('--install-codex',action='store_true',help='Explicitly register with Codex using its CLI')
p.add_argument('--codex',default='codex',help='Codex CLI executable')
a=p.parse_args()
command=pathlib.Path(a.binary).expanduser().resolve() if a.binary else pathlib.Path(a.app).expanduser().resolve()/'Contents/MacOS/frame-studio-mcp'
if not command.is_file():p.error(f'MCP executable not found / 未找到 MCP 程序: {command}')
args=['--project',str(pathlib.Path(a.project).expanduser().resolve())] if a.project else []
invocation=[a.codex,'mcp','add','frame_studio','--',str(command),*args]
if a.install_codex:
    if not shutil.which(a.codex):p.error('Codex CLI not found. Use --format toml and merge the configuration manually.')
    subprocess.run(invocation,check=True)
elif a.format=='command':print(shlex.join(invocation))
elif a.format=='toml':print('[mcp_servers.frame_studio]\ncommand = '+json.dumps(str(command),ensure_ascii=False)+'\nargs = '+json.dumps(args,ensure_ascii=False))
else:print(json.dumps({'mcpServers':{'frame_studio':{'command':str(command),'args':args}}},ensure_ascii=False,indent=2))
