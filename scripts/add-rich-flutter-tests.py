#!/usr/bin/env python3
import json,pathlib,sys
base=pathlib.Path(__file__).resolve().parents[1]/'.artifacts/platform-exports'
root=pathlib.Path(json.loads((base/'paths.json').read_text())['flutter'])
design=json.loads((root/'Design.framestudio').read_text());last=design['pages'][-1]
name='Page_'+last['id'].encode().hex().upper();source=(root/'lib/pages'/(name.lower()+'.dart')).read_text()
start=source.index('specs: ')+len('specs: ')
specs=json.JSONDecoder().raw_decode(source[start:].replace('\\$','$'))[0]
def literal(value):return json.dumps(value,ensure_ascii=False).replace('$','\\$')
by_kind={n['kind']:n for n in specs}
base_spec=by_kind['text'].copy();base_spec.update(id='bottom-marker',text='页面最底部',fontSize=16,opacity=1,fill='FFFFFF',foreground='000000',fixed=False)
layout={'x':24,'y':1800,'width':300,'height':40,'refWidth':393,'refHeight':2000,'tl':0,'tr':0,'bl':0,'br':0};base_spec['layouts']=[layout]*6
tab=by_kind['tabBar'].copy();tab.update(id='fixed-tab',fixed=True);tab['layouts']=[{'x':12,'y':764,'width':369,'height':64,'refWidth':393,'refHeight':852,'tl':14,'tr':14,'bl':14,'br':14}]*6
toggle=by_kind['toggle'];profile=by_kind['profileRow'];progress=by_kind['progress'].copy();progress.update(progressStyle='circular',fraction=0.3125,progressText='25/80')
test=f"""import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:designed_app/design_runtime.dart';
Widget host(Widget child,double w,double h)=>MaterialApp(home:Scaffold(body:Align(alignment:Alignment.topLeft,child:SizedBox(width:w,height:h,child:child))));
Widget element(Map<String,dynamic> spec,{{String page=''}})=>DesignElement(spec:spec,activePage:page,navigate:(_){{}},openSidebar:(){{}});
void main(){{
 testWidgets('long page scrolls while Tab stays fixed',(tester)async{{
  tester.view.physicalSize=const Size(393,852);tester.view.devicePixelRatio=1;
  addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(host(DesignCanvas(pageID:'scroll',variant:0,background:Colors.white,specs:[{literal(base_spec)},{literal(tab)}],navigate:(_){{}},openSidebar:(){{}},heights:const[2000,2000,2000,2000,2000,2000]),393,852));
  final before=tester.getTopLeft(find.byKey(const ValueKey('scroll:fixed-tab')));
  expect(find.text('页面最底部').hitTestable(),findsNothing);
  await tester.drag(find.byType(SingleChildScrollView).first,const Offset(0,-1700));await tester.pump(const Duration(milliseconds:400));
  expect(find.text('页面最底部').hitTestable(),findsOneWidget);
  expect(tester.getTopLeft(find.byKey(const ValueKey('scroll:fixed-tab'))),before);
  expect(tester.takeException(),isNull);
 }});
 testWidgets('switch can dock left or right with uploaded icon',(tester)async{{
  final spec=<String,dynamic>{literal(toggle)};
  await tester.pumpWidget(host(element(spec),345,52));await tester.pump();
  final left=tester.getTopLeft(find.byType(Switch)).dx;
  expect(tester.getSize(find.byType(Image).first),const Size(22,22));
  await tester.pumpWidget(host(element({{...spec,'controlPosition':'trailing'}}),345,52));await tester.pump();
  expect(tester.getTopLeft(find.byType(Switch)).dx,greaterThan(left+180));expect(tester.takeException(),isNull);
 }});
 testWidgets('profile QR and chevron can be hidden',(tester)async{{
  final spec=<String,dynamic>{literal(profile)};
  await tester.pumpWidget(host(element({{...spec,'showQRCode':false,'showChevron':false}}),345,100));await tester.pump();
  expect(find.byIcon(Icons.qr_code),findsNothing);expect(find.byIcon(Icons.chevron_right),findsNothing);
  await tester.pumpWidget(host(element({{...spec,'showQRCode':true,'showChevron':true}}),345,100));await tester.pump();
  expect(find.byIcon(Icons.qr_code),findsOneWidget);expect(find.byIcon(Icons.chevron_right),findsOneWidget);
 }});
 testWidgets('circular progress displays current and total',(tester)async{{
  await tester.pumpWidget(host(element({literal(progress)}),100,100));await tester.pump();
  expect(find.text('25/80'),findsOneWidget);expect(tester.widget<CircularProgressIndicator>(find.byType(CircularProgressIndicator)).value,0.3125);
 }});
 testWidgets('Tab selected and default uploaded icons are independent',(tester)async{{
  final spec=<String,dynamic>{literal(tab)};
  final first=Map<String,dynamic>.from((spec['items'] as List).first);first['pageID']='selected';
  spec['items']=[first];
  await tester.pumpWidget(host(element(spec,page:'selected'),369,64));await tester.pump();
  expect((tester.widget<Image>(find.byType(Image)).image as AssetImage).assetName,first['selectedAsset']);
  await tester.pumpWidget(host(element(spec,page:'elsewhere'),369,64));await tester.pump();
  expect((tester.widget<Image>(find.byType(Image)).image as AssetImage).assetName,first['iconAsset']);
 }});
}}
"""
(root/'test/rich_features_test.dart').write_text(test)
print('Prepared 5 additional widget tests for scrolling, icon states, switches, profile and progress.')
