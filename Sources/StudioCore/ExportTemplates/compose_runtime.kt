package dev.framestudio.generated

import android.graphics.BitmapFactory
import android.app.DatePickerDialog
import java.util.Calendar
import java.text.SimpleDateFormat
import java.util.Locale
import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.*
import androidx.compose.ui.graphics.*
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.*
import org.json.JSONArray
import org.json.JSONObject
import kotlin.math.max
import kotlin.math.roundToInt

class DesignSpec(val data: JSONObject) {
    fun s(key: String) = data.optString(key, "")
    fun n(key: String, default: Double = 0.0) = data.optDouble(key, default).toFloat()
    fun b(key: String) = data.optBoolean(key)
    val items: List<DesignSpec> get() = data.optJSONArray("items")?.let { a -> (0 until a.length()).map { DesignSpec(a.getJSONObject(it)) } } ?: emptyList()
    fun layout(variant: Int) = DesignSpec(data.getJSONArray("layouts").getJSONObject(variant))
}
fun parseDesignNodes(json: String): List<DesignSpec> = JSONArray(json).let { a -> (0 until a.length()).map { DesignSpec(a.getJSONObject(it)) } }
fun designColor(raw: String): Color {
    val s = raw.removePrefix("#")
    val n = s.toLongOrNull(16) ?: 0L
    val argb = if (s.length == 8) ((n and 255L) shl 24) or (n shr 8) else 0xFF000000L or n
    return Color(argb)
}
fun designIcon(key: String): ImageVector = when(key) {
    "menu" -> Icons.Default.Menu; "home" -> Icons.Default.Home; "star" -> Icons.Default.AutoAwesome
    "favorite" -> Icons.Default.Favorite; "person" -> Icons.Default.AccountCircle; "chat" -> Icons.Default.ChatBubbleOutline
    "grid" -> Icons.Default.GridView; "image" -> Icons.Default.Image; "settings" -> Icons.Default.Settings
    "edit" -> Icons.Default.Edit; "add" -> Icons.Default.Add; "close" -> Icons.Default.Close; "search" -> Icons.Default.Search
    "bookmark" -> Icons.Default.BookmarkBorder; "notifications" -> Icons.Default.NotificationsNone; "qr" -> Icons.Default.QrCode
    "chevronRight" -> Icons.Default.ChevronRight; "back" -> Icons.Default.ArrowBack; "forward" -> Icons.Default.ArrowForward
    "check" -> Icons.Default.CheckCircle; "more" -> Icons.Default.MoreHoriz; "send" -> Icons.Default.Send
    "mail" -> Icons.Default.Email; "phone" -> Icons.Default.Phone; "calendar" -> Icons.Default.DateRange
    "clock" -> Icons.Default.Schedule; "location" -> Icons.Default.LocationOn; "play" -> Icons.Default.PlayCircleOutline
    "folder" -> Icons.Default.Folder; "file" -> Icons.Default.Description; "camera" -> Icons.Default.CameraAlt
    "mic" -> Icons.Default.Mic; "lock" -> Icons.Default.Lock; "eye" -> Icons.Default.Visibility
    "cart" -> Icons.Default.ShoppingCart; "payment" -> Icons.Default.CreditCard; "moon" -> Icons.Default.DarkMode
    "sun" -> Icons.Default.LightMode; "globe" -> Icons.Default.Public; "link" -> Icons.Default.Link
    "up" -> Icons.Default.ArrowUpward; "down" -> Icons.Default.ArrowDownward; "music" -> Icons.Default.MusicNote
    "wifi" -> Icons.Default.Wifi; "video" -> Icons.Default.Videocam; "like" -> Icons.Default.ThumbUp
    "palette" -> Icons.Default.Palette; "tune" -> Icons.Default.Tune; "layers" -> Icons.Default.Layers
    "code" -> Icons.Default.Code; else -> Icons.Default.Info
}
@Composable fun DesignCanvas(pageID: String, background: Color, nodes: List<DesignSpec>, variant: Int, navigate: (String) -> Unit, openSidebar: () -> Unit, scrollable: Boolean, heights: List<Float>, custom: @Composable (String) -> Unit) {
    BoxWithConstraints(Modifier.fillMaxSize().background(background).clipToBounds()) {
        val width=maxWidth.value;val viewportHeight=maxHeight.value
        val contentHeight=if(scrollable) max(viewportHeight,heights[variant]) else viewportHeight
        key(pageID,variant) {
            if(scrollable) {
                Box(Modifier.fillMaxSize().verticalScroll(rememberScrollState())) {
                    Box(Modifier.fillMaxWidth().height(contentHeight.dp)) {DesignLayer(pageID,nodes.filter{!it.b("fixed")},variant,width,contentHeight,navigate,openSidebar,custom)}
                }
            }else {DesignLayer(pageID,nodes.filter{!it.b("fixed")},variant,width,contentHeight,navigate,openSidebar,custom)}
        }
        DesignLayer(pageID,nodes.filter{it.b("fixed")},variant,width,viewportHeight,navigate,openSidebar,custom)
    }
}
@Composable private fun DesignLayer(pageID:String,nodes:List<DesignSpec>,variant:Int,width:Float,height:Float,navigate:(String)->Unit,openSidebar:()->Unit,custom: @Composable (String) -> Unit) {
    val density=LocalDensity.current.density
    nodes.forEach { n -> key(n.s("id")) {
        val f=n.layout(variant);val dx=width-f.n("refWidth");val dy=height-f.n("refHeight");val anchor=n.s("anchor")
        val w=max(1f,f.n("width")+if(anchor=="stretch") dx else 0f)
        val x=f.n("x")+when(anchor){"topRight","bottomRight"->dx;"center"->dx/2;else->0f}
        val y=f.n("y")+when(anchor){"bottomLeft","bottomRight"->dy;"center"->dy/2;else->0f}
        val shape=RoundedCornerShape(topStart=f.n("tl").dp,topEnd=f.n("tr").dp,bottomStart=f.n("bl").dp,bottomEnd=f.n("br").dp)
        Box(Modifier.offset { IntOffset((x*density).roundToInt(),(y*density).roundToInt()) }.requiredSize(w.dp,f.n("height").dp)
            .graphicsLayer { alpha=n.n("opacity",1.0); rotationZ=n.n("rotation") }
            .shadow(n.n("shadow").dp,shape).clip(shape).background(designColor(n.s("fill")))
            .then(if(n.n("borderWidth")>0) Modifier.border(n.n("borderWidth").dp,designColor(n.s("borderColor")),shape) else Modifier)) {
            CompositionLocalProvider(LocalContentColor provides designColor(n.s("foreground"))) {
                ProvideTextStyle(TextStyle(fontSize=n.n("fontSize",16.0).sp,fontWeight=when(n.s("fontWeight")){"bold"->FontWeight.Bold;"semibold"->FontWeight.SemiBold;"medium"->FontWeight.Medium;else->FontWeight.Normal},textAlign=when(n.s("textAlignment")){"center"->TextAlign.Center;"trailing"->TextAlign.End;else->TextAlign.Start})) {DesignContent(n,pageID,navigate,openSidebar,custom)}
            }
        }
    } }
}
@Composable private fun Glyph(n: DesignSpec, size: Float=n.n("iconSize",22.0), color: Color=designColor(n.s("accent")), key: String=n.s("symbol"), asset:String=n.s("iconAsset")) {
    if(asset.isNotEmpty()) {
        val context=LocalContext.current
        val image=remember(asset){context.assets.open(asset.removePrefix("assets/")).use{BitmapFactory.decodeStream(it)?.asImageBitmap()}}
        if(image!=null) Image(image,null,Modifier.size(size.dp),contentScale=ContentScale.Fit)
    }else Icon(designIcon(key), contentDescription=null, modifier=Modifier.size(size.dp),tint=color)
}
@Composable private fun Media(n: DesignSpec, modifier: Modifier=Modifier, fit: ContentScale=ContentScale.Crop) {
    val asset=n.s("asset").removePrefix("assets/"); val context=LocalContext.current
    val bitmap=remember(asset) { if(asset.isEmpty()) null else context.assets.open(asset).use { BitmapFactory.decodeStream(it)?.asImageBitmap() } }
    if(bitmap!=null) Image(bitmap,contentDescription=n.s("text"),modifier=modifier.fillMaxSize(),contentScale=fit)
    else Box(modifier.fillMaxSize(),contentAlignment=Alignment.Center) { Glyph(n,n.n("iconSize")+12) }
}
@Composable private fun Avatar(n: DesignSpec) {
    Box(Modifier.size(n.n("avatarSize",58.0).dp).clip(RoundedCornerShape((n.n("avatarSize")/3).dp)).background(designColor(n.s("accent")).copy(alpha=0.12f))) { Media(n) }
}
@Composable private fun DesignContent(n: DesignSpec, pageID: String, navigate: (String) -> Unit, openSidebar: () -> Unit, custom: @Composable (String) -> Unit) {
    val accent=designColor(n.s("accent"));val foreground=designColor(n.s("foreground"));val pad=n.n("padding").dp;val gap=n.n("spacing").dp
    var enabled by remember { mutableStateOf(n.b("isOn")) };var value by remember { mutableFloatStateOf(n.n("value")) };var text by remember { mutableStateOf("") };var selected by remember { mutableIntStateOf(0) };var number by remember {mutableFloatStateOf(n.n("numberValue",1.0))};var date by remember {mutableStateOf(n.s("dateValue"))};val context=LocalContext.current
    val go = { navigate(n.s("targetPageID")) }
    when(n.s("kind")) {
        "text" -> Box(Modifier.fillMaxSize(),contentAlignment=when(n.s("textAlignment")){"center"->Alignment.Center;"trailing"->Alignment.CenterEnd;else->Alignment.CenterStart}) { Text(n.s("text")) }
        "icon","iconButton" -> Box(Modifier.fillMaxSize().then(if(n.s("kind")=="iconButton") Modifier.clickable(onClick=openSidebar) else Modifier),contentAlignment=Alignment.Center) { if(n.s("iconAsset").isNotEmpty() || n.s("asset").isEmpty()) Glyph(n,color=foreground) else Box(Modifier.size(n.n("iconSize").dp)) { Media(n,fit=ContentScale.Fit) } }
        "button" -> Row(Modifier.fillMaxSize().clickable(onClick=go),horizontalArrangement=Arrangement.Center,verticalAlignment=Alignment.CenterVertically) { if(n.b("showIcon")){Glyph(n,color=foreground);Spacer(Modifier.width(gap))};if(n.b("showLabel"))Text(n.s("text")) }
        "image","avatar" -> Media(n)
        "profileRow" -> Row(Modifier.fillMaxSize().padding(pad),verticalAlignment=Alignment.CenterVertically) { Avatar(n);Spacer(Modifier.width(gap));Column(Modifier.weight(1f),verticalArrangement=Arrangement.spacedBy(8.dp)) { Text(n.s("text"),fontWeight=FontWeight.SemiBold,maxLines=1,overflow=TextOverflow.Ellipsis);Text(n.s("subtitle"),fontSize=max(10f,n.n("fontSize")-3).sp,color=foreground.copy(alpha=0.55f),maxLines=1,overflow=TextOverflow.Ellipsis) };if(n.b("showQRCode"))Glyph(n,18f,foreground.copy(alpha=0.4f),"qr",n.s("qrAsset"));if(n.b("showChevron"))Glyph(n,16f,foreground.copy(alpha=0.3f),"chevronRight",n.s("chevronAsset")) }
        "navigationBar" -> Row(Modifier.fillMaxSize().padding(horizontal=pad),verticalAlignment=Alignment.CenterVertically) { Box(Modifier.size(32.dp,44.dp).clickable {if(n.s("navigationAction")=="back") navigate("__back") else openSidebar()},contentAlignment=Alignment.Center){Glyph(n,color=foreground)};Text(n.s("text"),Modifier.weight(1f),textAlign=TextAlign.Center,fontWeight=FontWeight.SemiBold);Box(Modifier.size(32.dp,44.dp).clickable(onClick=go),contentAlignment=Alignment.Center){Glyph(n,color=foreground,key=n.s("trailingSymbol"),asset=n.s("trailingAsset"))} }
        "tabBar" -> Row(Modifier.fillMaxSize()) { n.items.forEach { item -> val color=if(item.s("pageID")==pageID) accent else foreground.copy(alpha=0.5f);Column(Modifier.weight(1f).fillMaxHeight().clickable { navigate(item.s("pageID")) },horizontalAlignment=Alignment.CenterHorizontally,verticalArrangement=Arrangement.Center) { Glyph(n,color=color,key=if(item.s("pageID")==pageID) item.s("selectedSymbol") else item.s("symbol"),asset=if(item.s("pageID")==pageID) item.s("selectedAsset") else item.s("iconAsset"));Spacer(Modifier.height(6.dp));Text(item.s("title"),color=color) } } }
        "sidebar" -> Column(Modifier.fillMaxSize().padding(pad).verticalScroll(rememberScrollState()),verticalArrangement=Arrangement.spacedBy(gap)) {Text(n.s("text"),fontWeight=FontWeight.SemiBold);n.items.forEach { item -> Row(Modifier.fillMaxWidth().clickable {navigate(item.s("pageID"))}.padding(vertical=12.dp),verticalAlignment=Alignment.CenterVertically) {Glyph(n,key=item.s("symbol"),asset=item.s("iconAsset"));Spacer(Modifier.width(gap));Text(item.s("title"))} } }
        "listRow" -> Row(Modifier.fillMaxSize().clickable(onClick=go).padding(horizontal=pad),verticalAlignment=Alignment.CenterVertically) {if(n.b("showIcon")){Glyph(n);Spacer(Modifier.width(gap))};Column(Modifier.weight(1f),verticalArrangement=Arrangement.spacedBy(5.dp)) {Text(n.s("text"));if(n.s("subtitle").isNotEmpty()) Text(n.s("subtitle"),fontSize=max(10f,n.n("fontSize")-4).sp,color=foreground.copy(alpha=0.45f))};if(n.b("showChevron"))Glyph(n,16f,foreground.copy(alpha=0.3f),"chevronRight",n.s("chevronAsset"))}
        "card" -> Column(Modifier.fillMaxSize().padding(pad+4.dp),verticalArrangement=Arrangement.spacedBy(gap)) {if(n.b("showIcon"))Glyph(n,n.n("iconSize")+6);Spacer(Modifier.weight(1f));Text(n.s("text"),fontWeight=FontWeight.SemiBold);Text(n.s("subtitle"),fontSize=max(11f,n.n("fontSize")-5).sp,color=foreground.copy(alpha=0.5f))}
        "divider" -> Box(Modifier.fillMaxSize().background(designColor(n.s("fill"))))
        "toggle","checkbox","radio","switchControl" -> Row(Modifier.fillMaxSize().padding(horizontal=pad),verticalAlignment=Alignment.CenterVertically) {
            val choice: @Composable () -> Unit={when(n.s("kind")){"checkbox"->Checkbox(enabled,{enabled=it},colors=CheckboxDefaults.colors(checkedColor=accent));"radio"->RadioButton(enabled,{enabled=!enabled},colors=RadioButtonDefaults.colors(selectedColor=accent));else->Switch(enabled,{enabled=it},colors=SwitchDefaults.colors(checkedTrackColor=accent))}}
            if(n.s("controlPosition")=="leading"){choice();Spacer(Modifier.width(gap))}
            if(n.b("showIcon")){Glyph(n);Spacer(Modifier.width(gap))}
            Box(Modifier.weight(1f)){if(n.b("showLabel"))Text(n.s("text"))}
            if(n.s("controlPosition")!="leading")choice()
        }
        "textField","searchField" -> Row(Modifier.fillMaxSize().padding(horizontal=pad),verticalAlignment=Alignment.CenterVertically) {if(n.s("kind")=="searchField"){Glyph(n);Spacer(Modifier.width(10.dp))};BasicTextField(value=text,onValueChange={text=it},modifier=Modifier.weight(1f),textStyle=LocalTextStyle.current.copy(color=foreground),decorationBox={inner->Box {if(text.isEmpty()) Text(n.s("text"),color=foreground.copy(alpha=0.45f));inner()}})}
        "badge" -> Box(Modifier.fillMaxSize(),contentAlignment=Alignment.Center) {Text(n.s("text"))}
        "progress","ringProgress" -> DetailedProgress(n)
        "slider" -> Slider(value=value,onValueChange={value=it},modifier=Modifier.fillMaxSize(),colors=SliderDefaults.colors(thumbColor=accent,activeTrackColor=accent))
        "segmented" -> Row(Modifier.fillMaxSize()) {n.items.forEachIndexed { index,item -> Box(Modifier.weight(1f).fillMaxHeight().clip(RoundedCornerShape(6.dp)).background(if(selected==index) accent.copy(alpha=0.12f) else Color.Transparent).clickable{selected=index},contentAlignment=Alignment.Center) {Text(item.s("title"))}}}
        "backButton" -> Row(Modifier.fillMaxSize().clickable{navigate("__back")},horizontalArrangement=Arrangement.Center,verticalAlignment=Alignment.CenterVertically){Glyph(n,color=foreground);Spacer(Modifier.width(gap));if(n.b("showLabel"))Text(n.s("text"))}
        "iconLabel","textButton","outlinedButton" -> Row(Modifier.fillMaxSize().clickable(onClick=go),horizontalArrangement=Arrangement.Center,verticalAlignment=Alignment.CenterVertically){if(n.b("showIcon")){Glyph(n,color=foreground);Spacer(Modifier.width(gap))};if(n.b("showLabel"))Text(n.s("text"))}
        "stepper" -> Row(Modifier.fillMaxSize().padding(horizontal=pad),verticalAlignment=Alignment.CenterVertically){Text("${n.s("text")}  ${if(number%1f==0f) number.toInt().toString() else number.toString()}",Modifier.weight(1f));IconButton(onClick={number=(number-n.n("stepValue",1.0)).coerceIn(n.n("minimumValue"),n.n("maximumValue",99.0))}){Icon(Icons.Default.Remove,null)};IconButton(onClick={number=(number+n.n("stepValue",1.0)).coerceIn(n.n("minimumValue"),n.n("maximumValue",99.0))}){Icon(Icons.Default.Add,null)}}
        "secureField","textArea" -> Row(Modifier.fillMaxSize().padding(pad),verticalAlignment=Alignment.CenterVertically){if(n.b("showIcon") && n.s("kind")=="secureField"){Glyph(n);Spacer(Modifier.width(gap))};BasicTextField(text,{text=it},modifier=Modifier.weight(1f),textStyle=LocalTextStyle.current.copy(color=foreground),singleLine=n.s("kind")=="secureField",visualTransformation=if(n.s("kind")=="secureField") PasswordVisualTransformation() else VisualTransformation.None,decorationBox={inner->Box{if(text.isEmpty())Text(n.s("text"),color=foreground.copy(alpha=0.45f));inner()}})}
        "selectField" -> {var expanded by remember{mutableStateOf(false)};Box(Modifier.fillMaxSize().padding(horizontal=pad),contentAlignment=Alignment.CenterStart){TextButton(onClick={expanded=true}){Text(n.items.getOrNull(selected)?.s("title") ?: n.s("text"));Icon(Icons.Default.ArrowDropDown,null)};DropdownMenu(expanded,{expanded=false}){n.items.forEachIndexed{i,item->DropdownMenuItem(text={Text(item.s("title"))},onClick={selected=i;expanded=false})}}}}
        "dateField" -> Row(Modifier.fillMaxSize().clickable{val parser=SimpleDateFormat("yyyy-MM-dd",Locale.US);val calendar=Calendar.getInstance();calendar.time=parser.parse(date)?:calendar.time;DatePickerDialog(context,{_,year,month,day->date=String.format(Locale.US,"%04d-%02d-%02d",year,month+1,day)},calendar.get(Calendar.YEAR),calendar.get(Calendar.MONTH),calendar.get(Calendar.DAY_OF_MONTH)).show()}.padding(horizontal=pad),verticalAlignment=Alignment.CenterVertically){Text("${n.s("text")}  $date",Modifier.weight(1f));Icon(Icons.Default.CalendarToday,null,Modifier.size(20.dp))}
        "rating" -> Row(Modifier.fillMaxSize(),horizontalArrangement=Arrangement.spacedBy(gap,Alignment.CenterHorizontally),verticalAlignment=Alignment.CenterVertically){for(i in 1..n.n("maximumValue",5.0).toInt()){Icon(if(i<=number) Icons.Default.Star else Icons.Default.StarBorder,null,Modifier.size(n.n("iconSize").dp).clickable{number=i.toFloat()},tint=accent)}}
        "loading" -> Box(Modifier.fillMaxSize(),contentAlignment=Alignment.Center){CircularProgressIndicator(Modifier.size(24.dp),color=accent,strokeWidth=3.dp)}
        "rectangle" -> Box(Modifier.fillMaxSize().background(designColor(n.s("fill"))))
        "circle" -> Box(Modifier.fillMaxSize().clip(androidx.compose.foundation.shape.CircleShape).background(designColor(n.s("fill"))))
        "spacer" -> Spacer(Modifier.fillMaxSize())
        "qrCode","chevron" -> Box(Modifier.fillMaxSize().clickable(onClick=go),contentAlignment=Alignment.Center){Glyph(n,color=foreground)}
        "statistic" -> Column(Modifier.fillMaxSize().padding(pad),verticalArrangement=Arrangement.Center){Row(verticalAlignment=Alignment.CenterVertically){if(n.b("showIcon")){Glyph(n);Spacer(Modifier.width(8.dp))};Text(n.s("text"),fontSize=13.sp)};Spacer(Modifier.height(8.dp));Text(n.s("subtitle"),fontSize=n.n("fontSize").sp,fontWeight=FontWeight.SemiBold)}
        "alertBanner" -> Row(Modifier.fillMaxSize().padding(horizontal=pad),verticalAlignment=Alignment.CenterVertically){if(n.b("showIcon")){Glyph(n);Spacer(Modifier.width(gap))};Column(Modifier.weight(1f)){Text(n.s("text"));Text(n.s("subtitle"),fontSize=max(10f,n.n("fontSize")-3).sp,color=foreground.copy(alpha=0.6f))}}
        "custom" -> Box(Modifier.fillMaxSize(),contentAlignment=Alignment.Center) {custom(n.s("id"))}
    }
}

@Composable private fun DetailedProgress(n:DesignSpec) {
    val accent=designColor(n.s("accent"));val track=designColor(n.s("trackColor"));val thickness=n.n("progressThickness",6.0);val amount=n.n("fraction");val label=n.s("progressText")
    if(n.s("progressStyle")=="circular") {
        BoxWithConstraints(Modifier.fillMaxSize(),contentAlignment=Alignment.Center) {
            val diameter=minOf(maxWidth,maxHeight)
            Box(Modifier.size(diameter),contentAlignment=Alignment.Center) {
                CircularProgressIndicator(progress={amount},modifier=Modifier.fillMaxSize().padding((thickness/2+2).dp),color=accent,trackColor=track,strokeWidth=thickness.dp)
                if(label.isNotEmpty())Text(label,Modifier.padding((thickness+2).dp),maxLines=1,fontSize=n.n("fontSize").sp)
            }
        }
    }else {
        Column(Modifier.fillMaxSize().padding(horizontal=2.dp),verticalArrangement=Arrangement.Center) {
            if(label.isNotEmpty()){Text(label,Modifier.fillMaxWidth(),textAlign=TextAlign.End,fontSize=minOf(14f,n.n("fontSize")).sp);Spacer(Modifier.height(4.dp))}
            if(n.s("progressStyle")=="steps") {val count=n.n("progressSteps",5.0).toInt();Row(Modifier.fillMaxWidth().height(thickness.dp),horizontalArrangement=Arrangement.spacedBy(4.dp)){repeat(count){index->Box(Modifier.weight(1f).fillMaxHeight().clip(RoundedCornerShape((thickness/2).dp)).background(if(index<amount*count)accent else track))}}}
            else LinearProgressIndicator(progress={amount},modifier=Modifier.fillMaxWidth().height(thickness.dp),color=accent,trackColor=track)
        }
    }
}
