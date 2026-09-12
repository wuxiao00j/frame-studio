#!/usr/bin/env python3
"""Exercise shared Tab mutations and composite editing over the real MCP transport."""
import copy, json, os, pathlib, subprocess, tempfile

root = pathlib.Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix='frame-studio-shared-tabs-') as temporary:
    folder = pathlib.Path(temporary)
    process = subprocess.Popen(
        [os.environ.get('FRAME_STUDIO_MCP', str(root / '.build/debug/frame-studio-mcp')),
         '--project', str(folder / 'Design.framestudio')],
        stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True)
    sequence = 0

    def rpc(method, params):
        global sequence
        sequence += 1
        process.stdin.write(json.dumps({'jsonrpc': '2.0', 'id': sequence, 'method': method, 'params': params}) + '\n')
        process.stdin.flush()
        return json.loads(process.stdout.readline())['result']

    def tool(name, arguments=None, error=False):
        result = rpc('tools/call', {'name': name, 'arguments': arguments or {}})
        assert result['isError'] == error, result
        return result if error else json.loads(result['content'][0]['text'])

    def tabs(project):
        return [node for page in project['pages'] for node in page['nodes'] if node['kind'] == 'tabBar']

    def shared(project):
        configs = [{key: value for key, value in node.items()
                    if key not in {'id', 'groupID', 'rowGroupID', 'sourceReference'}} for node in tabs(project)]
        assert configs and all(config == configs[0] for config in configs)

    try:
        rpc('initialize', {'protocolVersion': '2025-06-18'})
        project = tool('get_project')
        initial_ids = [n['id'] for n in tabs(project)]
        last = tabs(project)[-1]['id']
        items = list(reversed(tabs(project)[-1]['items']))
        items[0]['title'] = 'Profile updated'
        items[0]['selectedSymbol'] = 'person.fill'
        items.append({'id': 'extra-tab-item', 'title': 'Extra', 'symbol': 'star', 'pageID': project['pages'][0]['id']})
        properties = {'items': items, 'fill': '123456', 'foreground': 'FFFFFF', 'cornerRadius': 28,
                      'fontSize': 14, 'iconSize': 24, 'spacing': 5, 'syncTabIcons': False,
                      'frames': {'innerLandscape': {'x': 30, 'y': 400, 'width': 680, 'height': 72}}}
        original_frames = copy.deepcopy(tabs(project)[0]['frames'])
        project = tool('update_component', {'nodeID': last, 'properties': properties, 'expectedRevision': project['revision']})
        shared(project)
        assert [n['id'] for n in tabs(project)] == initial_ids
        assert tabs(project)[0]['items'] == items
        assert tabs(project)[0]['cornerRadius'] == 28
        for variant, frame in original_frames.items():
            if variant != 'innerLandscape':
                assert tabs(project)[0]['frames'][variant] == frame

        stale = project['revision']
        project = tool('import_icon', {'nodeID': last, 'itemID': items[0]['id'], 'selected': True,
                                      'path': str(root / 'Resources/AppIcon.iconset/icon_32x32.png'),
                                      'expectedRevision': stale})
        shared(project)
        assert tabs(project)[0]['items'][0]['selectedIconData']
        tool('update_component', {'nodeID': last, 'properties': {'cornerRadius': 99}, 'expectedRevision': stale}, error=True)
        assert tool('get_project') == project
        project = tool('align_components', {'pageID': project['pages'][-1]['id'], 'nodeIDs': [last],
                                           'variant': 'innerLandscape', 'alignment': 'centerX',
                                           'expectedRevision': project['revision']})
        shared(project)
        assert tabs(project)[0]['frames']['innerLandscape']['x'] == 59

        project = tool('create_page', {'name': 'No Tab', 'expectedRevision': project['revision']})
        empty_page = project['pages'][-1]['id']
        assert not project['pages'][-1]['nodes']
        project = tool('add_component', {'pageID': empty_page, 'kind': 'tabBar', 'properties': {'fill': 'FF0000'},
                                        'expectedRevision': project['revision']})
        shared(project)
        assert tabs(project)[-1]['fill'] == '123456'
        project = tool('delete_components', {'nodeIDs': [tabs(project)[-1]['id']], 'expectedRevision': project['revision']})
        assert not project['pages'][-1]['nodes']
        # A raw bulk edit to the last existing Tab must remain authoritative.
        tabs(project)[-1]['items'].pop(0)
        project = tool('replace_project', {'project': project, 'expectedRevision': project['revision']})
        shared(project)
        assert len(tabs(project)[0]['items']) == 3
        assert not project['pages'][-1]['nodes']

        project = tool('add_component', {'pageID': empty_page, 'kind': 'backButton', 'expectedRevision': project['revision']})
        back = project['pages'][-1]['nodes'][-1]
        assert back['frames']['standardPortrait'] == {'x': 16, 'y': 52, 'width': 80, 'height': 44}
        assert back['fixedToViewport'] and back['anchor'] == 'topLeft'
        project = tool('add_component', {'pageID': empty_page, 'kind': 'profileRow', 'expectedRevision': project['revision']})
        profile = project['pages'][-1]['nodes'][-1]
        project = tool('decompose_component', {'nodeID': profile['id'], 'expectedRevision': project['revision']})
        parts = project['pages'][-1]['nodes'][1:]
        assert len(parts) > 1 and all(not n['groupID'] for n in parts)
        geometry = {n['id']: copy.deepcopy(n['frames']) for n in parts}
        for node in parts:
            node['groupID'] = 'recombined-layers'
        project = tool('replace_project', {'project': project, 'expectedRevision': project['revision']})
        assert all(n['groupID'] == 'recombined-layers' for n in project['pages'][-1]['nodes'][1:])
        for node in project['pages'][-1]['nodes'][1:]:
            node['groupID'] = ''
        project = tool('replace_project', {'project': project, 'expectedRevision': project['revision']})
        assert all(not n['groupID'] and n['frames'] == geometry[n['id']] for n in project['pages'][-1]['nodes'][1:])
        for format_name in ['swiftui', 'android', 'flutter']:
            directory = pathlib.Path(tool('export_project', {'format': format_name, 'directory': str(folder)})['directory'])
            exported = json.loads((directory / 'Design.framestudio').read_text())
            shared(exported)
            assert exported == project
            assert json.loads((directory / 'export-manifest.json').read_text())['includesMobileBinary'] is False
    finally:
        process.stdin.close()
        assert process.wait(timeout=10) == 0

print('SHARED_TABS_PASS: full configuration, ordering, assets, variants, inheritance, deletion, revisions, back button, ungroup/regroup and three source exports.')
