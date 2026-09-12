#!/usr/bin/env python3
"""Source-only verification: analysis, widget tests and Kotlin compilation. Never packages mobile apps."""
import json, pathlib, subprocess, os
base=pathlib.Path(__file__).resolve().parents[1]/'.artifacts/platform-exports'
paths=json.loads((base/'paths.json').read_text());flutter=pathlib.Path(paths['flutter'])
design=json.loads((flutter/'Design.framestudio').read_text())
text="import 'package:flutter/material.dart';\nimport 'package:flutter_test/flutter_test.dart';\nimport 'package:designed_app/main.dart';\nimport 'package:designed_app/design_runtime.dart';\n"
names=['Page_'+page['id'].encode().hex().upper() for page in design['pages']]
for i,name in enumerate(names):text+=f"import 'package:designed_app/pages/{name.lower()}.dart' as p{i};\n"
text+='void main() {\n'
dims=[(393,852),(852,393),(400,560),(560,400),(570,798),(798,570)]
for i,name in enumerate(names):
 for variant,(w,h) in enumerate(dims):
  text+=f"""testWidgets('page {i} variant {variant}',(tester) async {{
   tester.view.physicalSize=const Size(1200,1200);tester.view.devicePixelRatio=1;
   addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
   await tester.pumpWidget(MaterialApp(home:Scaffold(body:Align(alignment:Alignment.topLeft,child:SizedBox(width:{w},height:{h},child:p{i}.{name}(variant:{variant},navigate:(_){{}},openSidebar:(){{}}))))));
   await tester.pump();expect(tester.takeException(),isNull);
  }});\n"""
text+="""testWidgets('Tab and switch',(tester) async {
 tester.view.physicalSize=const Size(393,852);tester.view.devicePixelRatio=1;
 addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
 await tester.pumpWidget(const DesignedApp());await tester.pump();
 await tester.tap(find.text('我的'));await tester.pump();expect(find.text('设计师'),findsOneWidget);
 final before=tester.widget<Switch>(find.byType(Switch)).value;
 await tester.tap(find.byType(Switch));await tester.pump();expect(tester.widget<Switch>(find.byType(Switch)).value,!before);
});
test('RGBA',(){expect(designColor('FF000080').toARGB32(),0x80FF0000);});
}
"""
(flutter/'test').mkdir(exist_ok=True);(flutter/'test/exported_ui_test.dart').write_text(text)
subprocess.run(["python3",str(pathlib.Path(__file__).with_name("add-rich-flutter-tests.py"))],check=True)
commands=[('flutter',['flutter','pub','get'],'flutter-pub.log'),('flutter',['flutter','analyze'],'flutter-analyze.log'),('flutter',['flutter','test','--reporter','expanded'],'flutter-widget-tests.log'),('android',['./gradlew','--console=plain',':app:compileDebugKotlin'],'android-compile.log')]
for fmt,command,logname in commands:
 with (base/logname).open('w') as log:result=subprocess.run(command,cwd=paths[fmt],stdout=log,stderr=subprocess.STDOUT,env=os.environ)
 print(fmt,command,'exit:',result.returncode,flush=True)
 if result.returncode:
  print((base/logname).read_text()[-8000:]);raise SystemExit(result.returncode)
subprocess.run(['python3',str(pathlib.Path(__file__).with_name('typecheck-swiftui.py'))],check=True)
for directory in paths.values():
 for file in pathlib.Path(directory).rglob('*'):
  if file.suffix.lower() in ['.apk','.aab','.ipa','.app']:raise SystemExit('Unexpected mobile artifact: '+str(file))
print('GENERATED_SOURCE_VERIFICATION_PASS · no mobile packages',flush=True)
