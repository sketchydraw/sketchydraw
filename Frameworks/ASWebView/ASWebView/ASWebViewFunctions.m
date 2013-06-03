//
//  ASWebViewFunctions.m
//  ASWebView
//
//  Created by 佐藤 昭 on 10/12/02.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ASWebViewFunctions.h"


NSString *guessEncoding(NSData *data, NSStringEncoding *enc)
// http://blogs.dion.ne.jp/fujidana/の藤棚さんのFJDDetectEncodingによる。 //
{
	// 2. Search for ESC (0x1b). Is ESC is found, its string encoding will be ISO-2022-JP.
	if (nil != data) {
		NSString *string;
		NSStringEncoding encoding;
		
		if (memchr([data bytes], 0x1b, [data length]) != NULL) {
			NSLog(@"J2022P");
			
			string = [[NSString alloc] initWithData:data encoding:NSISO2022JPStringEncoding];
			if (nil != string) {
				/* NSLog(@"ESC character is found and initWithData:encoding: with %@ succeeded", [NSString localizedNameOfStringEncoding:NSISO2022JPStringEncoding]); */
				*enc = NSISO2022JPStringEncoding;
				return [string autorelease];
			}
		}
		// 3. Try each encodings listed in encodings[]. You can reorder this list if need be.
		
		NSStringEncoding encodings[] = {
			NSUTF8StringEncoding,
			NSNonLossyASCIIStringEncoding,
			NSShiftJISStringEncoding, 
			NSJapaneseEUCStringEncoding, 
			NSUnicodeStringEncoding, 
			0};
		
		NSInteger i = 0;
		while ((encoding = encodings[i]) != 0) {
			i++;
			string = [[NSString alloc] initWithData:data encoding:encoding];
			if (string != nil) {
#ifdef DEBUG
				NSLog(@"initWithContentsOfURL:encoding:error: with %@ succeeded", [NSString localizedNameOfStringEncoding:encoding]);
#endif
				*enc = encoding;
				return [string autorelease];
			}
		}
#ifdef DEBUG
		NSLog(@"failed");
#endif
		return nil;
	}
	else
		return nil;
}
NSDictionary *characterSets(void)
{
	return [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInteger:NSASCIIStringEncoding],@"iso-8859-6",[NSNumber numberWithUnsignedInteger:NSNEXTSTEPStringEncoding],@"next",[NSNumber numberWithUnsignedInteger:NSJapaneseEUCStringEncoding],@"euc-jp",[NSNumber numberWithUnsignedInteger:NSUTF8StringEncoding],@"utf-8",[NSNumber numberWithUnsignedInteger:NSISOLatin1StringEncoding],@"iso-8859-1",[NSNumber numberWithUnsignedInteger:NSSymbolStringEncoding],@"cshppsmath",[NSNumber numberWithUnsignedInteger:NSSymbolStringEncoding],@"adobe-symbol-encoding",[NSNumber numberWithUnsignedInteger:NSNonLossyASCIIStringEncoding],@"us-ascii",[NSNumber numberWithUnsignedInteger:NSShiftJISStringEncoding],@"shift_jis",[NSNumber numberWithUnsignedInteger:NSISOLatin2StringEncoding],@"iso-8859-2",[NSNumber numberWithUnsignedInteger:NSUnicodeStringEncoding],@"utf-16",[NSNumber numberWithUnsignedInteger:NSWindowsCP1251StringEncoding],@"windows-1251",[NSNumber numberWithUnsignedInteger:NSWindowsCP1252StringEncoding],@"windows-1252",[NSNumber numberWithUnsignedInteger:NSWindowsCP1253StringEncoding],@"windows-1253",[NSNumber numberWithUnsignedInteger:NSWindowsCP1254StringEncoding],@"windows-1254",[NSNumber numberWithUnsignedInteger:NSWindowsCP1250StringEncoding],@"windows-1250",[NSNumber numberWithUnsignedInteger:NSISO2022JPStringEncoding],@"iso-2022-jp",[NSNumber numberWithUnsignedInteger:NSMacOSRomanStringEncoding],@"macos-roman",nil];
}
double unitToPix(NSString *aString,NSFont *font,CGFloat baseValue)
// 1pxは1インチ/90=0.2822222222mmとする。Inkscapeでは単位無しを1/90インチとして扱っている。 //
{
	double f;
	double value;
	NSUInteger index;
    double r = 96.0; // WebKitやFirefoxでは96.0を使っている。Incscapeでは仕様書通りの90.0を使っている。 //
    double px = 72.0;
	NSArray *units = [NSArray arrayWithObjects:@"px",@"pt",@"pc",@"mm",@"cm",@"in",@"em",@"ex",@"\%",nil];
	
	f = [aString doubleValue];
	for (index = 0; index < [units count]; index++) {
		if (0 < [aString rangeOfString:[units objectAtIndex:index]].length)
			break;
	}
	switch (index) {
		case 0:
			value = f; // 単位無しと同じなのでそのまま。font-sizeが単位無しの場合とも同じ。 //
			break;
		case 1:
			value = r / px * f; // 90.0/72.0px なので 1.25 * f のはずだけれども、WebKitやFirefoxでは96.0/72.0=1.33...として動作している。Inkscapeでは1.25を使っている。WebKitの描画に合わせなければならないので1.33...とする。 //
			break;
		case 2:
			value = 12.0 * r / px * f; // 12pt*90.0/72.0px=15.0, 12pt*96.0/72.0px=16.0 //
			break;
		case 3:
			value = r / 25.4 * f; // 90.0/25.4mm=3.543307087 のはずだけれども、WebKitやFirefoxでは96.0/25.4mm=3.779527559として動作している。 //
			break;
		case 4:
			value = r / 2.54 * f; // 90.0/2.54cm=35.43307087, 96.0/2.54=37.79527559 //
			break;
		case 5:
			value = r * f; // 90.0/1.0インチ, 96.0/1.0インチ //
			break;
		case 6: // em //
			value = [font pointSize] * f;
			break;
		case 7: // ex //
			value = [font xHeight] * f;
			break;
		case 8: // % //
			value = 0.01 * f * baseValue;
			break;
		default:
			value = f;
			break;
	}
	return value;
}
NSArray *values() {
	return [NSArray arrayWithObjects:@"none",@"xMinYMin",@"xMinYMid",@"xMinYMax",@"xMidYMin",@"xMidYMid",@"xMidYMax",@"xMaxYMin",@"xMaxYMid",@"xMaxYMax",@"meet",@"slice",nil];
}
NSDictionary *getSVGRect(NSXMLDocument *xmlDoc)
// x （最も外側の 'svg' 要素に対してはどんな意味も効果も生じない。） 埋め込まれた 'svg' 要素が配置される領域矩形の第一頂点のＸ座標。 この属性が指定されていない場合、値 "0" が指定されたものと見なされる。(Has no meaning or effect on outermost 'svg' elements.) The x-axis coordinate of one corner of the rectangular region into which an embedded 'svg' element is placed.If the attribute is not specified, the effect is as if a value of "0" were specified. //
// y （最も外側の 'svg' 要素に対してはどんな意味も効果も生じない。） 埋め込まれた 'svg' 要素が配置される領域矩形の第一頂点のＹ座標。 この属性が指定されていない場合、値 "0" が指定されたものと見なされる。(Has no meaning or effect on outermost 'svg' elements.) The x-axis coordinate of one corner of the rectangular region into which an embedded 'svg' element is placed.If the attribute is not specified, the effect is as if a value of "0" were specified. //
// width。最も外側の 'svg' 要素に対してはSVG文書片の本来の横幅を意味する。埋め込まれた 'svg' 要素に対しては配置されるときの矩形の横幅を意味する。 負値はエラー（ エラー処理 を見よ）。値を０にすると要素は描画されなくなる。 この属性が指定されていない場合、値 "100%" が指定されたものと見なされる。 //
// height。最も外側の 'svg' 要素に対してはSVG文書片の本来の高さを意味する。埋め込まれた 'svg' 要素に対しては配置されるときの矩形の横幅を意味する。 負値はエラー（ エラー処理 を見よ）。値を０にすると要素は描画されなくなる。 この属性が指定されていない場合、値 "100%" が指定されたものと見なされる。 //
// viewBox。与えられたグラフィックたちを特定のコンテナ要素にぴったり収まるように伸縮させることが望ましいときがある。 viewBox 属性はそのような機能を提供する。新しいビューポートを確立する要素の全て（ ビューポートを確立する要素 を見よ）、加えて 'marker', 'pattern', 'view' 要素は viewBox 属性を持つ。 viewBox 属性の値は空白又はコンマで区切られた４個の数値のリスト <min-x>, <min-y>, <width>, <height> で記述される。これらの数値は要素によって確立されたビューポートの境界に写像されるべきユーザー空間における矩形を preserveAspectRatio 属性を考慮に入れて決定する。もし viewBox 属性が要素に指定された場合、要素の全ての子孫にも適用される。transform 属性と異なり（ 隣接属性に対する transform 属性の効果 を見よ）、要素の viewBox 属性によってもたらされる自動的変換はその要素の x, y, width, height 属性（ 'marker' 要素の場合は markerWidth, markerHeight 属性）に影響しない。したがって、上の例に示された属性 width, height 及び viewBox を持つ 'svg' 要素では、 width と height 属性は viewBox による変換が適用される前の座標系における値を表す。その一方で transform 属性と同様に新しい座標系は確立され、他のすべての属性と子孫要素には適用される //
// 仕様書7.8によると「属性viewBoxが指定されなければpreserveAspectRatioは無視される」。固定比率の拡大縮小を強制しない。 //
{
	double vx,vy,vw,vh,gRatioX,gRatioY,gRatio,ox,oy;
	NSXMLElement *rootElement = [xmlDoc rootElement];
	NSString *widthStr = [[rootElement attributeForName:@"width"] stringValue];
	NSString *heightStr = [[rootElement attributeForName:@"height"] stringValue];
	BOOL isViewBox = NO;
	NSScanner *viewboxScanner = (nil != [rootElement attributeForName:@"viewBox"]) ? [NSScanner scannerWithString:[[rootElement attributeForName:@"viewBox"] stringValue]] : nil; // scannerWithString:nil はnilを返さない。 //
	NSScanner *preserveAspectRatioScanner = (nil != [rootElement attributeForName:@"preserveAspectRatio"]) ? [NSScanner scannerWithString:[[rootElement attributeForName:@"preserveAspectRatio"] stringValue]] : nil; // scannerWithString:nil はnilを返さない。 //
	NSFont *font = [NSFont userFontOfSize:13.0];
	double w = ((nil != widthStr) && (NO == [widthStr isEqualToString:@""])) ? unitToPix(widthStr,font,640.0) : 640.0;
	double h = ((nil != heightStr) && (NO == [heightStr isEqualToString:@""])) ? unitToPix(heightStr,font,480.0) : 480.0;
	// NSString *xStr = [[rootElement attributeForName:@"x"] stringValue]; //
	// NSString *yStr = [[rootElement attributeForName:@"y"] stringValue]; //
	double x = 0.0; // 最も外側の 'svg' 要素に対してはどんな意味も効果も生じない。((nil != xStr) && (NO == [xStr isEqualToString:@""])) ? unitToPix(xStr,font,w) : 0.0; //
	double y = 0.0; // 最も外側の 'svg' 要素に対してはどんな意味も効果も生じない。((nil != yStr) && (NO == [yStr isEqualToString:@""])) ? unitToPix(yStr,font,h) : 0.0; //
	BOOL fixedRatioX = ((nil != widthStr) && (NO == [widthStr isEqualToString:@""]) && (0 == [widthStr rangeOfString:@"%"].length)) ? YES : NO; // 省略されたどうかと、%が指定されたかどうかの判断 //
	BOOL fixedRatioY = ((nil != heightStr) && (NO == [heightStr isEqualToString:@""]) && (0 == [heightStr rangeOfString:@"%"].length)) ? YES : NO; // 省略されたどうかと、%が指定されたかの判断 //
	NSString *align = [values() objectAtIndex:5]; // 継承はしない。仕様書のとおりxMidYMid:固定比率の拡大縮小を強制する。viewBoxが指定されたときに備えてデフォルト値を設定する。以前は xMinYMinにしてあった。 //
	NSString *meetOrSlice = [values() objectAtIndex:10]; // 仕様書のとおりmeet。viewBoxが指定されたときに備えてデフォルト値を設定する。以前は sliceにしてあった。 //
	
	if (nil != viewboxScanner) {
		double tempf;
		NSCharacterSet *numericSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789-+."]; // カンマや単位文字を読み飛ばして，数値の最初の文字位置を得るときに使用する。 //
		if (YES == [viewboxScanner scanDouble:&tempf]) {
			[viewboxScanner scanUpToCharactersFromSet:numericSet intoString:NULL];
			vx = vy = vw = vh = tempf;
			isViewBox = YES;
			if (YES == [viewboxScanner scanDouble:&tempf]) {
				[viewboxScanner scanUpToCharactersFromSet:numericSet intoString:NULL];
				vy = vw = vh = tempf;
				if (YES == [viewboxScanner scanDouble:&tempf]) {
					[viewboxScanner scanUpToCharactersFromSet:numericSet intoString:NULL];
					vw = vh = tempf;
					if (YES == [viewboxScanner scanDouble:&tempf]) {
						[viewboxScanner scanUpToCharactersFromSet:numericSet intoString:NULL];
						vh = tempf;
					}
				}
			}
		}
	}
	if (nil != preserveAspectRatioScanner) {
		NSString *tempString;
		if (YES == [preserveAspectRatioScanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:&tempString]) {
			align = [NSString stringWithString:tempString];
			[preserveAspectRatioScanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:NULL];
			if (YES == [preserveAspectRatioScanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:&tempString])
				meetOrSlice = [NSString stringWithString:tempString];
		}
	}
	if (NO == isViewBox) { // サイズ不定のイメージを許さないので、ここで規定する。 //
		vx = vy = 0.0;
		vw = w;
		vh = h;
	}
	if (YES == isViewBox) {
		gRatioX = w / vw;
		gRatioY = h / vh;
	}
	else {
		align = [values() objectAtIndex:0]; // 仕様書7.8によると「属性viewBoxが指定されなければpreserveAspectRatioは無視される」。固定比率の拡大縮小を強制しない。 //
		gRatioX = gRatioY = 1.0;
	}
	// ox,oy,gRatioX,gRatioYはsvg全体の"translate(%g %g) scale(%g %g)",ox,oy,gRatioX,gRatioY に使われる。 //
	if (0 != [values() indexOfObject:align]) { // 固定比率の拡大縮小を強制する。 //
		if (11 == [values() indexOfObject:meetOrSlice]) { // slice:preserveAspectRatioがなかったときのデフォルト //
			if (gRatioX < gRatioY)
				gRatio = gRatioY;
			else
				gRatio = gRatioX;
		}
		else { // 10 meet:preserveAspectRatioがあったときのデフォルト //
			if (gRatioX > gRatioY)
				gRatio = gRatioY;
			else
				gRatio = gRatioX;
		}
		switch ([values() indexOfObject:align]) {
			case 1: // xMinYMin //
				ox = x - gRatio * vx;
				oy = y - gRatio * vy;
				break;
			case 2: // xMinYMid //
				ox = x - gRatio * vx;
				oy = y + 0.5 * h - gRatio * (vy + 0.5 * vh);
				break;
			case 3: // xMinYMax //
				ox = x - gRatio * vx;
				oy = y + h - gRatio * (vy + vh);
				break;
			case 4: // xMidYMin //
				ox = x + 0.5 * w - gRatio * (vx + 0.5 * vw);
				oy = y - gRatio * vy;
				break;
			case 6: // xMidYMax //
				ox = x + 0.5 * w - gRatio * (vx + 0.5 * vw);
				oy = y + h - gRatio * (vy + vh);
				break;
			case 7: // xMaxYMin //
				ox = x + w - gRatio * (vx + vw);
				oy = y - gRatio * vy;
				break;
			case 8: // xMaxYMid //
				ox = x + w - gRatio * (vx + vw);
				oy = y + 0.5 * h - gRatio * (vy + 0.5 * vh);
				break;
			case 9: // xMaxYMax //
				ox = x + w - gRatio * (vx + vw);
				oy = y + h - gRatio * (vy + vh);
				break;
			default: // case 5: xMidYMid //
				ox = x + 0.5 * w - gRatio * (vx + 0.5 * vw);
				oy = y + 0.5 * h - gRatio * (vy + 0.5 * vh);
				// NSLog(@"xMidYMid ox=%f oy=%f",ox,oy); //
				break;
		}
		gRatioX = gRatioY = gRatio;
	}
	else { // 0:noneならば<meetOrSlice>の値を無視する。固定比率の拡大縮小を強制しない。 //
		if (YES == isViewBox) {
			ox = x - gRatioX * vx;
			oy = y - gRatioY * vy;
		}
		else {
			ox = x;
			oy = y;
		}
		if (11 == [values() indexOfObject:meetOrSlice]) { // slice:preserveAspectRatioがなかったときのデフォルト //
			if (gRatioX < gRatioY)
				gRatio = gRatioY;
			else
				gRatio = gRatioX;
		}
		else { // 10 meet:preserveAspectRatioがあったときのデフォルト //
			if (gRatioX > gRatioY)
				gRatio = gRatioY;
			else
				gRatio = gRatioX;
		}
	}
	
	// NSMakeRect(vx,vy,vw,vh); がViewBox //
	NSXMLElement *element;
	NSString *desc = [NSString string];
	NSString *title = [NSString string];
	NSEnumerator *childrenEnumerator = [[rootElement children] objectEnumerator];
	while (nil != (element = [childrenEnumerator nextObject])) {
		if (YES == [[element name] isEqualToString:@"desc"])
			desc = [element objectValue];
		if (YES == [[element name] isEqualToString:@"title"])
			title = [element objectValue];
	}
	return [NSDictionary dictionaryWithObjectsAndKeys:[NSValue valueWithRect:NSMakeRect(x,y,w,h)],@"Bounds",[NSValue valueWithRect:NSMakeRect(vx,vy,vw,vh)],@"ViewBox",desc,@"desc",title,@"title",[NSNumber numberWithBool:fixedRatioX],@"FixedRatioX",[NSNumber numberWithBool:fixedRatioY],@"FixedRatioY",[NSNumber numberWithDouble:ox],@"Ox",[NSNumber numberWithDouble:oy],@"Oy",[NSNumber numberWithDouble:gRatioX],@"GRatioX",[NSNumber numberWithDouble:gRatioY],@"GRatioY",[NSNumber numberWithDouble:gRatio],@"GRatio",align,@"Align",meetOrSlice,@"MeetOrSlice",nil];
}
