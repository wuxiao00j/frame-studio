import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

Color designColor(String value) {
  final s=value.replaceAll('#', '');
  final n=int.tryParse(s,radix:16) ?? 0;
  return Color(s.length==8 ? ((n & 255)<<24) | (n>>8) : 0xFF000000 | n);
}
Gradient? designGradient(Map<String,dynamic> spec,Size size) {
 final raw=spec['gradient'];if(raw is! Map)return null;
 final g=Map<String,dynamic>.from(raw);final entries=(g['stops'] as List).map((e)=>Map<String,dynamic>.from(e as Map)).toList();
 final colors=entries.map((e)=>designColor(e['color'] as String)).toList();
 final stops=entries.map((e)=>(e['location'] as num).toDouble()).toList();
 final start=Alignment(numProp(g,'startX')*2-1,numProp(g,'startY')*2-1);
 if(g['kind']=='radial') {final radius=numProp(g,'endRadius',200),inner=numProp(g,'startRadius')/radius;return RadialGradient(colors:colors,stops:stops.map((v)=>inner+(1-inner)*v).toList(),center:start,radius:radius/math.max(1,math.min(size.width,size.height)));}
 return LinearGradient(colors:colors,stops:stops,begin:start,end:Alignment(numProp(g,'endX',1)*2-1,numProp(g,'endY',1)*2-1));
}
IconData designIcon(String key) => switch(key) {
 'menu'=>Icons.menu,'home'=>Icons.home_outlined,'star'=>Icons.auto_awesome,'favorite'=>Icons.favorite,
 'person'=>Icons.account_circle_outlined,'chat'=>Icons.chat_bubble_outline,'grid'=>Icons.grid_view,
 'image'=>Icons.image_outlined,'settings'=>Icons.settings_outlined,'edit'=>Icons.edit_outlined,
 'add'=>Icons.add,'close'=>Icons.close,'search'=>Icons.search,'bookmark'=>Icons.bookmark_outline,
 'notifications'=>Icons.notifications_none,'qr'=>Icons.qr_code,'chevronRight'=>Icons.chevron_right,
 'back'=>Icons.arrow_back,'forward'=>Icons.arrow_forward,'check'=>Icons.check_circle_outline,
 'more'=>Icons.more_horiz,'send'=>Icons.send_outlined,'mail'=>Icons.mail_outline,'phone'=>Icons.phone_outlined,
 'calendar'=>Icons.calendar_today,'clock'=>Icons.schedule,'location'=>Icons.location_on_outlined,
 'play'=>Icons.play_circle_outline,'folder'=>Icons.folder_outlined,'file'=>Icons.description_outlined,
 'camera'=>Icons.camera_alt_outlined,'mic'=>Icons.mic_none,'lock'=>Icons.lock_outline,'eye'=>Icons.visibility_outlined,
 'cart'=>Icons.shopping_cart_outlined,'payment'=>Icons.credit_card,'moon'=>Icons.dark_mode_outlined,
 'sun'=>Icons.light_mode_outlined,'globe'=>Icons.public,'link'=>Icons.link,'up'=>Icons.arrow_upward,'down'=>Icons.arrow_downward,
 'music'=>Icons.music_note,'wifi'=>Icons.wifi,'video'=>Icons.videocam_outlined,'like'=>Icons.thumb_up_outlined,
 'palette'=>Icons.palette_outlined,'tune'=>Icons.tune,'layers'=>Icons.layers_outlined,'code'=>Icons.code,_=>Icons.info_outline,
};
double numProp(Map<String,dynamic> spec,String key,[double fallback=0]) => (spec[key] as num?)?.toDouble() ?? fallback;
String strProp(Map<String,dynamic> spec,String key) => spec[key] as String? ?? '';
class DesignCanvas extends StatelessWidget {
 final String pageID;
 final int variant;
 final Color background;
 final List<Map<String,dynamic>> specs;
 final ValueChanged<String> navigate;
 final VoidCallback openSidebar;
 final Map<String,WidgetBuilder> customBuilders;
 final bool scrollable;final List<double> heights;
 const DesignCanvas({super.key,required this.pageID,required this.variant,required this.background,required this.specs,required this.navigate,required this.openSidebar,this.customBuilders=const {},this.scrollable=true,this.heights=const []});
 @override Widget build(BuildContext context) => LayoutBuilder(builder:(context,bounds) {
  final height=scrollable ? math.max(bounds.maxHeight,heights.isEmpty ? bounds.maxHeight:heights[variant]):bounds.maxHeight;
  final content=SizedBox(width:bounds.maxWidth,height:height,child:Stack(clipBehavior:Clip.hardEdge,children:[for(final spec in specs.where((s)=>s['visibleVariants']==null || (s['visibleVariants'] as List).contains(variant))) if(spec['fixed']!=true) _place(spec,Size(bounds.maxWidth,height))]));
  return Stack(clipBehavior:Clip.hardEdge,children:[
   Positioned.fill(child:ColoredBox(color:background)),
   for(final spec in specs.where((s)=>s['visibleVariants']==null || (s['visibleVariants'] as List).contains(variant))) if(spec['fixed']==true && spec['backgroundLayer']==true) _place(spec,bounds.biggest),
   Positioned.fill(child:scrollable ? SingleChildScrollView(key:PageStorageKey('$pageID:$variant'),child:content):content),
   for(final spec in specs.where((s)=>s['visibleVariants']==null || (s['visibleVariants'] as List).contains(variant))) if(spec['fixed']==true && spec['backgroundLayer']!=true) _place(spec,bounds.biggest),
  ]);
 });
 Widget _place(Map<String,dynamic> spec,Size size) {
  final f=Map<String,dynamic>.from((spec['layouts'] as List)[variant] as Map);
  final dx=size.width-numProp(f,'refWidth'),dy=size.height-numProp(f,'refHeight');
  final anchor=strProp(spec,'anchor');
  final w=math.max(1.0,numProp(f,'width')+(anchor=='stretch' ? dx:0));
  final x=numProp(f,'x')+(['topRight','bottomRight'].contains(anchor) ? dx:anchor=='center' ? dx/2:0);
  final y=numProp(f,'y')+(['bottomLeft','bottomRight'].contains(anchor) ? dy:anchor=='center' ? dy/2:0);
  return Positioned(left:x,top:y,width:w,height:numProp(f,'height'),child:DesignElement(key:ValueKey('$pageID:${spec['id']}'),spec:{...spec,"_corners":f,"_masks":(spec["clipMasks"] as List? ?? const [[],[],[],[],[],[]])[variant]},activePage:pageID,navigate:navigate,openSidebar:openSidebar,customBuilder:customBuilders[spec['id']]));
 }
}
class DesignElement extends StatefulWidget {
 final Map<String,dynamic> spec; final String activePage; final ValueChanged<String> navigate;final VoidCallback openSidebar;final WidgetBuilder? customBuilder;
 const DesignElement({super.key,required this.spec,required this.activePage,required this.navigate,required this.openSidebar,this.customBuilder});
 @override State<DesignElement> createState()=>_DesignElementState();
}
class _DesignElementState extends State<DesignElement> {
 Map<String,dynamic> get n=>widget.spec;
 String s(String key)=>strProp(n,key); double d(String key,[double fallback=0])=>numProp(n,key,fallback);
 Color get accent=>designColor(s('accent')); Color get foreground=>designColor(s('foreground'));
 bool on=false;double value=0;double number=1;int selected=0;DateTime date=DateTime(2026);
 List<Map<String,dynamic>> get items=>(n['items'] as List? ?? []).map((e)=>Map<String,dynamic>.from(e as Map)).toList();
 @override void initState(){super.initState();on=n['isOn']==true;selected=d('selectedIndex').toInt().clamp(0,math.max(0,items.length-1));value=d('value');number=d('numberValue',1);date=DateTime.tryParse(s('dateValue'))??DateTime(2026);}
 TextAlign get align=>s('textAlignment')=='center' ? TextAlign.center:s('textAlignment')=='trailing' ? TextAlign.right:TextAlign.left;
 Widget text(String content,{double? size,Color? color,FontWeight? weight,int? maxLines})=>Text(content,textAlign:align,maxLines:maxLines,overflow:maxLines==null ? null:TextOverflow.ellipsis,style:TextStyle(fontSize:size??d('fontSize',16),color:color??foreground,fontWeight:weight??switch(s('fontWeight')){'bold'=>FontWeight.bold,'semibold'=>FontWeight.w600,'medium'=>FontWeight.w500,_=>FontWeight.normal}));
 Widget icon({double? size,Color? color,String? key,String? asset}) {
  final path=asset??s('iconAsset'),pixels=size??d('iconSize',22);
  return path.isNotEmpty ? SizedBox(width:pixels,height:pixels,child:Image.asset(path,fit:BoxFit.contain,errorBuilder:(context,error,stack)=>Icon(Icons.broken_image_outlined,size:pixels,color:color??accent))) : Icon(designIcon(key??s('symbol')),size:pixels,color:color??accent);
 }

 Widget media({BoxFit? fit})=>s('asset').isNotEmpty ? Image.asset(s('asset'),fit:fit ?? (s('imageFit')=='fit' ? BoxFit.contain:s('imageFit')=='stretch' ? BoxFit.fill:BoxFit.cover),width:double.infinity,height:double.infinity):Center(child:icon(size:d('iconSize')+12));
 Widget glyph()=>s('iconAsset').isNotEmpty ? icon(color:foreground):s('asset').isEmpty ? icon(color:foreground):SizedBox(width:d('iconSize'),height:d('iconSize'),child:media(fit:BoxFit.contain));
 Widget avatar()=>ClipRRect(borderRadius:BorderRadius.circular(d('avatarSize')/3),child:SizedBox(width:d('avatarSize'),height:d('avatarSize'),child:ColoredBox(color:accent.withValues(alpha:0.12),child:media())));
 Widget hit(Widget child,VoidCallback action)=>GestureDetector(behavior:HitTestBehavior.opaque,onTap:action,child:child);
 void go()=>widget.navigate(s('navigationAction')=='back' ? '__back':s('targetPageID'));
 @override Widget build(BuildContext context) {
  final f=Map<String,dynamic>.from(n['_corners'] as Map? ?? {});final radius=BorderRadius.only(topLeft:Radius.circular(numProp(f,'tl',d('cornerRadius'))),topRight:Radius.circular(numProp(f,'tr',d('cornerRadius'))),bottomLeft:Radius.circular(numProp(f,'bl',d('cornerRadius'))),bottomRight:Radius.circular(numProp(f,'br',d('cornerRadius'))));
  return LayoutBuilder(builder:(context,bounds) {
   Widget result=DecoratedBox(decoration:BoxDecoration(color:s('kind')=='circle' ? Colors.transparent:(s('material').isEmpty ? designColor(s('fill')):designMaterialTint(s('material'))),gradient:s('kind')=='circle' || s('material').isNotEmpty ? null:designGradient(n,bounds.biggest),borderRadius:radius,boxShadow:d('shadow')>0 ? [BoxShadow(color:s('shadowColor').isEmpty ? Colors.black.withValues(alpha:0.09):designColor(s('shadowColor')),blurRadius:d('shadow'),offset:Offset(d('shadowX'),d('shadowY',d('shadow')/3)))]:null),child:ClipRRect(borderRadius:radius,child:DecoratedBox(position:DecorationPosition.foreground,decoration:BoxDecoration(borderRadius:radius,border:d('borderWidth')>0 ? Border.all(color:designColor(s('borderColor')),width:d('borderWidth')):null),child:s('material').isEmpty ? content(context):BackdropFilter(filter:ui.ImageFilter.blur(sigmaX:20,sigmaY:20),child:content(context)))));
   if(d('blurRadius')>0)result=ImageFiltered(imageFilter:ui.ImageFilter.blur(sigmaX:d('blurRadius'),sigmaY:d('blurRadius')),child:result);
   final masks=n['_masks'] as List? ?? const [];
   if(masks.isNotEmpty)result=ClipPath(clipper:DesignImportedClipper(masks),child:result);
   return Transform.rotate(angle:d('rotation')*math.pi/180,child:Opacity(opacity:d('opacity',1)*(n['isEnabled']==false ? 0.45:1),child:ExcludeFocus(excluding:n['isEnabled']==false,child:AbsorbPointer(absorbing:n['isEnabled']==false,child:result))));
  });
 }
 Widget formControl(BuildContext context) {
  if(s('kind')=='selectField')return Row(children:[text(s('text')),const Spacer(),PopupMenuButton<int>(enabled:n['isEnabled']!=false,initialValue:selected,onSelected:(v)=>setState(()=>selected=v),itemBuilder:(_)=>[for(var i=0;i<items.length;i++) PopupMenuItem(value:i,child:Text(items[i]['title']))],child:Row(mainAxisSize:MainAxisSize.min,children:[text(items.isEmpty ? '' : items[selected.clamp(0,items.length-1)]['title'],color:foreground.withValues(alpha:0.55)),const Icon(Icons.unfold_more,size:14)]))]);
  if(s('kind')=='dateField')return Row(children:[text(s('text')),const Spacer(),hit(Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:5),decoration:BoxDecoration(color:Colors.black.withValues(alpha:0.05),borderRadius:BorderRadius.circular(24)),child:text('${date.year}年${date.month}月${date.day}日')),()async{final value=await showDatePicker(context:context,initialDate:date,firstDate:DateTime(1900),lastDate:DateTime(2200));if(value!=null && mounted)setState(()=>date=value);})]);
  return Align(alignment:s('kind')=='textArea' ? Alignment.topLeft:Alignment.centerLeft,child:TextField(enabled:n['isEnabled']!=false,minLines:s('kind')=='textArea' ? 2:1,maxLines:s('kind')=='textArea' ? 4:1,style:TextStyle(fontSize:d('fontSize',16),color:foreground),decoration:InputDecoration(hintText:s('text'),border:InputBorder.none,isDense:true,contentPadding:EdgeInsets.zero)));
 }
 Widget content(BuildContext context) {
  final pad=d('padding',16),gap=d('spacing',12);
  if(s('controlStyle')=='formRow' && ['textField','textArea','selectField','dateField'].contains(s('kind')))return formControl(context);
  switch(s('kind')) {
   case 'text':return Align(alignment:align==TextAlign.center ? Alignment.center:align==TextAlign.right ? Alignment.centerRight:Alignment.centerLeft,child:DesignImportedText(value:s('text'),align:align,style:TextStyle(fontSize:d('fontSize',16),color:foreground,fontWeight:s('fontWeight')=='bold' ? FontWeight.bold:s('fontWeight')=='semibold' ? FontWeight.w600:s('fontWeight')=='medium' ? FontWeight.w500:FontWeight.normal),limit:n['lineLimit'] as int?,spacing:d('lineSpacing'),minimumScale:d('minimumScaleFactor',1)));
   case 'icon':return Center(child:glyph());
   case 'iconButton':return hit(Center(child:glyph()),widget.openSidebar);
   case 'button':return hit(Center(child:Row(mainAxisSize:MainAxisSize.min,children:[if(n['showIcon']==true) ...[icon(color:foreground),SizedBox(width:gap)],if(n['showLabel']!=false) Flexible(child:text(s('text')))])),go);
   case 'image':return media();
   case 'avatar':return media(fit:BoxFit.cover);
   case 'profileRow':return Padding(padding:EdgeInsets.all(pad),child:Row(children:[avatar(),SizedBox(width:gap),Expanded(child:Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.start,children:[text(s('text'),weight:FontWeight.w600,maxLines:1),const SizedBox(height:8),text(s('subtitle'),size:math.max(10,d('fontSize')-3),color:foreground.withValues(alpha:0.55),maxLines:1)])),if(n['showQRCode']!=false) ...[icon(key:'qr',asset:s('qrAsset'),size:18,color:foreground.withValues(alpha:0.4)),const SizedBox(width:8)],if(n['showChevron']!=false) icon(key:'chevronRight',asset:s('chevronAsset'),size:14,color:foreground.withValues(alpha:0.3))]));
   case 'navigationBar':return Padding(padding:EdgeInsets.symmetric(horizontal:pad),child:Row(children:[hit(SizedBox(width:32,height:44,child:icon(color:foreground)),(){if(s("navigationAction")=="back"){widget.navigate("__back");}else{widget.openSidebar();}}),Expanded(child:Center(child:text(s('text'),weight:FontWeight.w600))),hit(SizedBox(width:32,height:44,child:icon(key:s("trailingSymbol"),asset:s("trailingAsset"),color:foreground)),go)]));
   case 'tabBar':return Row(children:[for(final item in items) Expanded(child:hit(Column(mainAxisAlignment:MainAxisAlignment.center,children:[icon(key:item['pageID']==widget.activePage ? item['selectedSymbol']:item['symbol'],asset:item['pageID']==widget.activePage ? item['selectedAsset']:item['iconAsset'],color:item['pageID']==widget.activePage ? accent:foreground.withValues(alpha:0.5)),const SizedBox(height:6),text(item['title'],color:item['pageID']==widget.activePage ? accent:foreground.withValues(alpha:0.5))]),()=>widget.navigate(item['pageID'])))]);
   case 'sidebar':return Padding(padding:EdgeInsets.all(pad),child:ListView(padding:EdgeInsets.zero,children:[text(s('text'),weight:FontWeight.w600),SizedBox(height:gap),for(final item in items) ListTile(contentPadding:EdgeInsets.zero,leading:icon(key:item['symbol'],asset:item['iconAsset']),title:text(item['title']),selected:item['pageID']==widget.activePage,onTap:()=>widget.navigate(item['pageID']))]));
   case 'listRow':return hit(Padding(padding:EdgeInsets.symmetric(horizontal:pad),child:Row(children:[if(n['showIcon']==true) ...[icon(),SizedBox(width:gap)],Expanded(child:Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.start,children:[text(s('text')),if(s('subtitle').isNotEmpty) ...[const SizedBox(height:5),text(s('subtitle'),size:math.max(10,d('fontSize')-4),color:foreground.withValues(alpha:0.45))]])),if(n['showChevron']!=false) icon(key:'chevronRight',asset:s('chevronAsset'),size:16,color:foreground.withValues(alpha:0.3))])),go);
   case 'card':return Padding(padding:EdgeInsets.all(pad+4),child:LayoutBuilder(builder:(context,bounds)=>FittedBox(fit:BoxFit.scaleDown,alignment:Alignment.topLeft,child:SizedBox(width:math.max(1,bounds.maxWidth),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[if(n['showIcon']==true) ...[icon(size:d('iconSize')+6),SizedBox(height:gap)],text(s('text'),weight:FontWeight.w600),SizedBox(height:gap),text(s('subtitle'),size:math.max(11,d('fontSize')-5),color:foreground.withValues(alpha:0.5))])))));
   case 'divider':return const SizedBox.expand();
   case 'toggle':case 'checkbox':case 'radio':case 'switchControl':return Padding(padding:EdgeInsets.symmetric(horizontal:pad),child:Row(children:[
    if(s('controlPosition')=='leading') ...[choice(),SizedBox(width:gap)],
    if(n['showIcon']==true) ...[icon(),SizedBox(width:gap)],
    Expanded(child:n['showLabel']==false ? const SizedBox.shrink():text(s('text'))),
    if(s('controlPosition')!='leading') choice(),
   ]));
   case 'textField':case 'searchField':return Padding(padding:EdgeInsets.symmetric(horizontal:pad),child:Row(children:[if(s('kind')=='searchField') ...[icon(),const SizedBox(width:10)],Expanded(child:TextField(style:TextStyle(color:foreground,fontSize:d('fontSize')),decoration:InputDecoration(hintText:s('text'),border:InputBorder.none,isDense:true,contentPadding:EdgeInsets.zero)))]));
   case 'badge':return Center(child:text(s('text')));
   case 'progress':case 'ringProgress':return progress();
   case 'slider':return Slider(value:value,activeColor:accent,onChanged:(v)=>setState(()=>value=v));
   case 'segmented':return Row(children:[for(var i=0;i<items.length;i++) Expanded(child:hit(Container(alignment:Alignment.center,decoration:BoxDecoration(color:selected==i ? accent.withValues(alpha:0.12):Colors.transparent,borderRadius:BorderRadius.circular(6)),child:text(items[i]['title'])),()=>setState(()=>selected=i)))]);
   case 'backButton':return hit(Center(child:Row(mainAxisSize:MainAxisSize.min,children:[icon(color:foreground),SizedBox(width:gap),if(n['showLabel']!=false) text(s('text'))])),()=>widget.navigate('__back'));
   case 'iconLabel':case 'textButton':case 'outlinedButton':return hit(Center(child:Row(mainAxisSize:MainAxisSize.min,children:[if(n['showIcon']==true) ...[icon(color:foreground),SizedBox(width:gap)],if(n['showLabel']!=false) Flexible(child:text(s('text')))])),go);
   case 'stepper':return Padding(padding:EdgeInsets.symmetric(horizontal:pad),child:Row(children:[Expanded(child:text('${s('text')}  ${number.toStringAsFixed(number.roundToDouble()==number ? 0:2)}')),IconButton(onPressed:()=>setState(()=>number=(number-d('stepValue',1)).clamp(d('minimumValue'),d('maximumValue',99))),icon:const Icon(Icons.remove)),IconButton(onPressed:()=>setState(()=>number=(number+d('stepValue',1)).clamp(d('minimumValue'),d('maximumValue',99))),icon:const Icon(Icons.add))]));
   case 'secureField':case 'textArea':return Padding(padding:EdgeInsets.all(pad),child:Row(children:[if(n['showIcon']==true && s('kind')=='secureField') ...[icon(),SizedBox(width:gap)],Expanded(child:TextField(obscureText:s('kind')=='secureField',maxLines:s('kind')=='textArea' ? null:1,style:TextStyle(color:foreground,fontSize:d('fontSize')),decoration:InputDecoration(hintText:s('text'),border:InputBorder.none,isDense:true,contentPadding:EdgeInsets.zero)))]));
   case 'selectField':return Padding(padding:EdgeInsets.symmetric(horizontal:pad),child:DropdownButton<int>(isExpanded:true,value:items.isEmpty ? null:math.min(selected,items.length-1),hint:text(s('text')),underline:const SizedBox.shrink(),items:[for(var i=0;i<items.length;i++) DropdownMenuItem(value:i,child:text(items[i]['title']))],onChanged:(v){if(v!=null)setState(()=>selected=v);}));
   case 'dateField':return hit(Padding(padding:EdgeInsets.symmetric(horizontal:pad),child:Row(children:[Expanded(child:text('${s('text')}  ${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}')),const Icon(Icons.calendar_today,size:20)])),()async{final picked=await showDatePicker(context:context,initialDate:date,firstDate:DateTime(1900),lastDate:DateTime(2200));if(picked!=null&&mounted)setState(()=>date=picked);});
   case 'rating':return Center(child:FittedBox(fit:BoxFit.scaleDown,child:Row(mainAxisSize:MainAxisSize.min,children:[for(var i=1;i<=d('maximumValue',5).toInt();i++) Padding(padding:EdgeInsets.only(right:i==d('maximumValue',5).toInt()?0:gap),child:hit(Icon(i<=number?Icons.star:Icons.star_border,color:accent,size:d('iconSize')),()=>setState(()=>number=i.toDouble())))])));
   case 'loading':return Center(child:SizedBox(width:24,height:24,child:CircularProgressIndicator(color:accent,strokeWidth:3)));
   case 'rectangle':return const SizedBox.expand();
   case 'circle':return LayoutBuilder(builder:(context,bounds)=>DecoratedBox(decoration:BoxDecoration(color:s('material').isEmpty ? designColor(s('fill')):designMaterialTint(s('material')),gradient:s('material').isEmpty ? designGradient(n,bounds.biggest):null,shape:BoxShape.circle)));
   case 'spacer':return const SizedBox.expand();
   case 'qrCode':case 'chevron':return hit(Center(child:icon(color:foreground)),go);
   case 'statistic':return Padding(padding:EdgeInsets.all(pad),child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.center,children:[Row(children:[if(n['showIcon']==true) ...[icon(),const SizedBox(width:8)],Expanded(child:text(s('text'),size:13))]),const SizedBox(height:8),text(s('subtitle'),size:d('fontSize'),weight:FontWeight.w600)]));
   case 'alertBanner':return Padding(padding:EdgeInsets.symmetric(horizontal:pad),child:Row(children:[if(n['showIcon']==true) ...[icon(),SizedBox(width:gap)],Expanded(child:Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.start,children:[text(s('text')),text(s('subtitle'),size:math.max(10,d('fontSize')-3),color:foreground.withValues(alpha:0.6))]))]));
   case 'custom':return widget.customBuilder?.call(context) ?? Center(child:Column(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.code),text(s('text'),size:12),const Text('TODO: Flutter Widget',style:TextStyle(fontSize:10))]));
   default:return const SizedBox.shrink();
  }
 }
 Widget choice() {
  if(s('kind')=='checkbox')return Checkbox(value:on,activeColor:accent,onChanged:(v)=>setState(()=>on=v??false));
  if(s('kind')=='radio')return RadioGroup<int>(groupValue:on?1:0,onChanged:(v)=>setState(()=>on=v==1),child:Radio<int>(value:1,toggleable:true,activeColor:accent));
  return Switch(value:on,activeThumbColor:accent,onChanged:(v)=>setState(()=>on=v));
 }
 Widget progress() {
  final amount=d('fraction'),label=s('progressText'),thickness=d('progressThickness',6),track=designColor(s('trackColor'));
  if(s('progressStyle')=='circular')return LayoutBuilder(builder:(context,bounds){final diameter=math.min(bounds.maxWidth,bounds.maxHeight);return Center(child:SizedBox(width:diameter,height:diameter,child:Stack(alignment:Alignment.center,children:[Positioned.fill(child:Padding(padding:EdgeInsets.all(thickness/2+2),child:CircularProgressIndicator(value:amount,color:accent,backgroundColor:track,strokeWidth:thickness))),if(label.isNotEmpty) Padding(padding:EdgeInsets.all(thickness+2),child:FittedBox(fit:BoxFit.scaleDown,child:text(label)))])));});
  final steps=d('progressSteps',5).toInt();
  return Padding(padding:const EdgeInsets.symmetric(horizontal:2),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[if(label.isNotEmpty) ...[Align(alignment:Alignment.centerRight,child:text(label,size:math.min(14,d('fontSize')))),const SizedBox(height:4)],SizedBox(height:thickness,child:s('progressStyle')=='steps' ? Row(children:[for(var i=0;i<steps;i++) Expanded(child:Padding(padding:EdgeInsets.only(right:i==steps-1 ? 0:4),child:DecoratedBox(decoration:BoxDecoration(color:i<amount*steps ? accent:track,borderRadius:BorderRadius.circular(thickness/2)))))]) : ClipRRect(borderRadius:BorderRadius.circular(thickness/2),child:LinearProgressIndicator(value:amount,color:accent,backgroundColor:track)))]));
 }

}

// Platform material approximation; does not emulate system Liquid Glass.
Color designMaterialTint(String material)=>Colors.white.withValues(alpha:switch(material){'ultraThin'=>0.30,'thin'=>0.45,'thick'=>0.80,'ultraThick'=>0.92,_=>0.65});
class DesignImportedClipper extends CustomClipper<Path> {
 final List masks;
 const DesignImportedClipper(this.masks);
 @override Path getClip(Size size) {
  Path? result;
  for(final raw in masks) {
   final m=Map<String,dynamic>.from(raw as Map),r=Map<String,dynamic>.from(m['rect'] as Map);
   final bounds=Rect.fromLTWH(numProp(r,'x')*size.width,numProp(r,'y')*size.height,numProp(r,'width')*size.width,numProp(r,'height')*size.height);
   final radius=numProp(m,'radius')*math.min(size.width,size.height);
   final path=Path();
   if(m['shape']=='ellipse'){path.addOval(bounds);}else{path.addRRect(RRect.fromRectAndRadius(bounds,Radius.circular(m['shape']=='rectangle' ? 0:radius)));}
   result=result==null ? path:Path.combine(PathOperation.intersect,result,path);
  }
  return result ?? (Path()..addRect(Offset.zero & size));
 }
 @override bool shouldReclip(DesignImportedClipper oldClipper)=>oldClipper.masks!=masks;
}
class DesignImportedText extends StatelessWidget {
 final String value;final TextAlign align;final TextStyle style;final int? limit;final double spacing,minimumScale;
 const DesignImportedText({super.key,required this.value,required this.align,required this.style,this.limit,this.spacing=0,this.minimumScale=1});
 @override Widget build(BuildContext context)=>LayoutBuilder(builder:(context,bounds) {
  final original=style.fontSize ?? 16;
  TextStyle sized(double size)=>style.copyWith(fontSize:size,height:spacing>0 ? 1.25+spacing/size:null);
  var size=original;
  if(minimumScale<1) {
   bool fits(double font) {
    final painter=TextPainter(text:TextSpan(text:value,style:sized(font)),textDirection:Directionality.of(context),textAlign:align,maxLines:limit,textScaler:MediaQuery.textScalerOf(context))..layout(maxWidth:bounds.maxWidth);
    final ok=!painter.didExceedMaxLines && painter.height<=bounds.maxHeight && painter.width<=bounds.maxWidth;painter.dispose();return ok;
   }
   if(!fits(original)){var low=original*minimumScale,high=original;for(var i=0;i<10;i++){final mid=(low+high)/2;if(fits(mid)){low=mid;}else{high=mid;}}size=low;}
  }
  return Text(value,textAlign:align,maxLines:limit,overflow:limit==null ? null:TextOverflow.ellipsis,style:sized(size));
 });
}
