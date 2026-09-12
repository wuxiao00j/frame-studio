import AppKit
let root=URL(fileURLWithPath:CommandLine.arguments[1])
let set=root.appendingPathComponent("AppIcon.iconset")
try FileManager.default.createDirectory(at:set,withIntermediateDirectories:true)
for size in [16,32,64,128,256,512,1024] {
    let image=NSImage(size:NSSize(width:size,height:size));image.lockFocus()
    let scale=Double(size)/1024
    let ctx=NSGraphicsContext.current!.cgContext;ctx.scaleBy(x:scale,y:scale)
    let background=NSBezierPath(roundedRect:NSRect(x:36,y:36,width:952,height:952),xRadius:216,yRadius:216)
    NSGradient(starting:NSColor(red:0.61,green:0.48,blue:0.91,alpha:1),ending:NSColor(red:0.34,green:0.23,blue:0.66,alpha:1))!.draw(in:background,angle:-60)
    NSColor.white.withAlphaComponent(0.18).setFill();NSBezierPath(roundedRect:NSRect(x:220,y:206,width:420,height:580),xRadius:65,yRadius:65).fill()
    NSColor.white.setFill();NSBezierPath(roundedRect:NSRect(x:370,y:256,width:410,height:540),xRadius:60,yRadius:60).fill()
    NSColor(red:0.53,green:0.4,blue:0.81,alpha:1).setFill()
    NSBezierPath(roundedRect:NSRect(x:424,y:650,width:290,height:72),xRadius:18,yRadius:18).fill()
    NSBezierPath(roundedRect:NSRect(x:424,y:455,width:128,height:158),xRadius:18,yRadius:18).fill()
    NSColor(red:0.79,green:0.72,blue:0.93,alpha:1).setFill()
    NSBezierPath(roundedRect:NSRect(x:579,y:455,width:135,height:158),xRadius:18,yRadius:18).fill()
    NSBezierPath(roundedRect:NSRect(x:424,y:348,width:290,height:68),xRadius:18,yRadius:18).fill()
    image.unlockFocus()
    let data=NSBitmapImageRep(data:image.tiffRepresentation!)!.representation(using:.png,properties:[:])!
    let names:[String]
    switch size {case 16:names=["icon_16x16.png"];case 32:names=["icon_16x16@2x.png","icon_32x32.png"];case 64:names=["icon_32x32@2x.png"];case 128:names=["icon_128x128.png"];case 256:names=["icon_128x128@2x.png","icon_256x256.png"];case 512:names=["icon_256x256@2x.png","icon_512x512.png"];default:names=["icon_512x512@2x.png"]}
    for name in names {try data.write(to:set.appendingPathComponent(name))}
}
