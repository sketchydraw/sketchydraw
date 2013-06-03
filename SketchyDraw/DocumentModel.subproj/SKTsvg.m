//
//  SKTsvg.m
//  Sketch
//
//  Created by me on Sat Aug 04 2001.
//  Copyright (c) 2001 SatoAkira. All rights reserved.
//

#import "SKTsvg.h"
#import "SKTFoundationExtras.h"
#import "SKTGraphicView.h" // for ISFLIPPED //

@implementation SKTsvg

- (void)dealloc {
	[_SVGImageRep release];
	[frameName release];
	[super dealloc];
}

- (void)pdfImageRepDidLoad:(NSNotification *)aNotification
{
	NSDictionary *infoDic = [aNotification userInfo];
	BOOL result = [[infoDic objectForKey:PDFImageRepDidLoadResultKey] boolValue];
	NSError *err = [infoDic objectForKey:PDFImageRepDidLoadErrorKey];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:PDFImageRepDidLoadNotification object:nil];
	[frameName release];
	frameName = nil; // ASWebImageRepで使われたWebViewも消え去っているのでframeNameもnilにしてしまう。 //
	[NSImageRep unregisterImageRepClass:[ASWebImageRep class]];
	if (YES == result) {
		NSData *svgData = [_SVGImageRep SVGRepresentation];
		
		[_imageRepresentation release];
		_imageRepresentation = (nil != svgData) ? [[NSData allocWithZone:[self zone]] initWithData:svgData] : nil;
	}
	else {
		[_imageRepresentation release];
		_imageRepresentation = nil;
	}
	if (nil == _imageRepresentation) {
		// もともとURLを与えていないので、[infoDic objectForKey:ASWebViewFileURLKey]は常にnil //
		NSString *title = (nil != [err localizedDescription]) ? [err localizedDescription] : NSStringFromClass([[aNotification object] class]);
		NSString *msg = (nil != [err localizedRecoverySuggestion]) ? [err localizedRecoverySuggestion] : (nil != [infoDic objectForKey:ASWebViewFileURLKey]) ? [[(NSURL *)[infoDic objectForKey:ASWebViewFileURLKey] absoluteString] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] : @"";
		NSBeginAlertSheet(title,nil,nil,nil,nil,self,NULL,NULL,NULL,msg,nil);
		[_SVGImageRep release];
		_SVGImageRep = nil;
		[_imageType release];
		_imageType = nil;
		originalSize = NSZeroSize;
		[self setBounds:NSZeroRect];
	}
	else
		[self setBounds:[self bounds]]; // 何かのイベントを与えないと表示されない。 //
}

- (NSSize)setImageRepresentation:(NSData *)aData type:(NSString *)aString
{
	if (nil != aData) {
		[_imageType release];
		[_SVGImageRep release];
		[frameName release];
		frameName = [[NSProcessInfo processInfo] globallyUniqueString];
		_SVGImageRep = [[ASWebImageRep allocWithZone:[self zone]] initWithData:aData URL:nil ofType:ASSVGDocumentTypeName frameName:frameName groupName:NSStringFromClass([self class])]; // ファイル位置に依存するようなSVGには対応しても無意味なので対応しない。従ってURL:の引数はnil。 // マルチスレッド関係でエラーになるのでこの段階でASWebImageRepにWebKitを起動させることはできない。従ってどこかのタイミングで[_SVGImageRep setupWebView]としてWebKitを起動させなければならない。 //
		if (YES == [NSThread isMainThread]) {
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pdfImageRepDidLoad:) name:PDFImageRepDidLoadNotification object:_SVGImageRep];
			[frameName release];
			frameName = nil;
		}
		hasColorSyncProfileData = NO;
		_imageType = [[NSString allocWithZone:[self zone]] initWithString:aString];
		originalSize = [_SVGImageRep bounds].size;
		return originalSize;
	}
	else {
		NSString *message = [NSString stringWithFormat:NSLocalizedString(@"'%@' image is not created. Please try again.",@""),aString];

		NSBeginAlertSheet(NSStringFromClass([self class]),nil,nil,nil,nil,self,NULL,NULL,NULL,message,nil); // windowを指定できないのでnil //
		[NSImageRep unregisterImageRepClass:[ASWebImageRep class]];
		return NSZeroSize;
	}
}

- (void)drawContentsInView:(NSView *)view isBeingCreateOrEdited:(BOOL)isBeingCreatedOrEditing
// ここのdrawContentsInView:の中で_SVGImageRepをいじることはできない。 //
{
	if ((nil != _SVGImageRep) && (nil == frameName)) {
		NSRect bounds = [self bounds];
		double rotateAngle = [self rotateAngle];
		NSRect fillRect = NSMakeRect(-0.5 * bounds.size.width,-0.5 * bounds.size.height,bounds.size.width, bounds.size.height);
		NSAffineTransform *transform = [NSAffineTransform transform];
		NSGraphicsContext *currentContext = [NSGraphicsContext currentContext];
		CGFloat scaleX = (YES == _isFlippedHorizontally) ? -1.0: 1.0;
#ifdef ISFLIPPED
		CGFloat scaleY = (YES == _isFlippedVertically) ? 1.0 : -1.0; // ASWebImageRepが代替pdfImageRepを使わなければ反対方向にしなければならない。 //
#else
		CGFloat scaleY = (YES == _isFlippedVertically) ? -1.0 : 1.0;
#endif
		BOOL shadowFlag = (0.1 > [self shadowBlurRadiusValue]) ? NO : YES; // shadowSetすると中身の描画総てに影響するのでfillのみに影響するようにする。 //
		
		[transform translateXBy:NSMidX(bounds) yBy:NSMidY(bounds)];
		if (0.0 != rotateAngle)
			[transform rotateByRadians:rotateAngle];
		[transform scaleXBy:scaleX yBy:scaleY];
		[transform concat];
		if (YES == [self isDrawingFill]) {
			NSBezierPath *fillPath = [NSBezierPath bezierPathWithRect:fillRect]; // NSRectFill(fillRect)を使うと暗くなってしまう。 //
			
			if ((YES == [self shading]) || (YES == [[[self fillColor] colorSpaceName] isEqualToString:NSPatternColorSpace])) {
				NSAffineTransform *fillTransform = [NSAffineTransform
													transform];
				[fillTransform scaleXBy:1.0 yBy:-1.0]; // pdfが代替に使われてしまうので反対回り。 //
				if (YES == shadowFlag) {
					[currentContext saveGraphicsState];
					[self shadowSet];
					[[NSColor whiteColor] setFill];
					[fillPath fill];
					[currentContext restoreGraphicsState];
					shadowFlag = NO;
				}
				if (YES == [self shading])
					[self drawShading:[NSBezierPath bezierPathWithRect:fillRect] transform:fillTransform];
				else {
					ASPatternModel *pModel = [self patternModel];
					[pModel setBounds:bounds clip:[NSBezierPath bezierPathWithRect:fillRect] transform:fillTransform colorSpace:[self colorSpace] winding:[self windingRule]];
					[pModel fill];
				}
			}
			else {
				if (YES == shadowFlag) {
					[currentContext saveGraphicsState]; // この方法でないと影が暗くなってしまう。 //
					[self shadowSet];
					[self fillColorSet];
					[fillPath fill];
					[currentContext restoreGraphicsState];
					shadowFlag = NO;
				}
				else {
					[self fillColorSet];
					[fillPath fill]; // [path closePath]されていなくても正しくfillされる。 //
				}
			}
		}		
		if (YES == shadowFlag) {
			[currentContext saveGraphicsState];
			[self shadowSet];
		}
		if ((nil != view) && (YES == [currentContext isDrawingToScreen])) {
			if (nil == _cachedImage) {
				if (nil != (_cachedImage = [[NSImage allocWithZone:[self zone]] initWithSize:fillRect.size])) {
					[_cachedImage addRepresentation:[_SVGImageRep bestRepresantion]];
					[_cachedImage setScalesWhenResized:YES];
				}
			}
			if (nil != _cachedImage)
				[_cachedImage drawAtPoint:fillRect.origin fromRect:NSMakeRect(0.0,0.0,NSWidth(fillRect),NSHeight(fillRect)) operation:NSCompositeSourceOver fraction:1.0];
		}
		else {
			if (NO == [_SVGImageRep drawInRect:fillRect fromRect:NSMakeRect(0.0,0.0,originalSize.width,originalSize.height) operation:NSCompositeSourceOver fraction:1.0 respectFlipped:NO hints:[NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:NSImageInterpolationHigh] forKey:NSImageHintInterpolation]])
				NSLog(@"SKTsvg: draw fail.");
		}
		if (YES == shadowFlag)
			[currentContext restoreGraphicsState];
	}
	else {
		if ((nil != _SVGImageRep) && (YES == [NSThread isMainThread])) {
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pdfImageRepDidLoad:) name:PDFImageRepDidLoadNotification object:_SVGImageRep]; // _SVGImageRepをinitしたときにMainThreadでなかった場合、WebViewが起動されないためPDFImageRepができない。ここでnotification待ちにしてPDFImageRepが出来上がるのを待たなければならない。 //
			[_SVGImageRep setupWebView];
		}
	}
}
- (NSUInteger)pageCount {
	return 1;
}

- (NSArray *)svgXMLElements:(NSRect)aRect name:(NSString *)unique_ID
// x,yすなわち左上の座標値と，width,heightとを新たなsvgとして指定すれば良い。viewBox,preserveAspectRatioはいじる必要が無い。 //
{
	NSRect bounds = [self bounds];
	
	if ((0.0 < NSWidth(bounds)) || (0.0 < NSHeight(bounds))) {
		BOOL shadowFlag = (0.1 > [self shadowBlurRadiusValue]) ? NO : YES;
		NSMutableArray *elements = [NSMutableArray arrayWithObject:[NSXMLNode commentWithStringValue:NSStringFromClass([self class])]];
		NSArray *defsAndRect = [self svgDefsAndRect:unique_ID allGraphics:aRect bounds:bounds transform:nil];
		if (0 < [defsAndRect count])
			[elements addObjectsFromArray:defsAndRect];
		/* CGFloat translateX = NSMidX(bounds) - NSMinX(aRect);
		CGFloat translateY = NSMidY(bounds) - NSMinY(aRect);
		if (YES == [self isDrawingFill]) {
			NSXMLElement *rectElement = [NSXMLElement elementWithName:@"rect"];
			NSMutableArray *attributes = [NSMutableArray arrayWithObjects:svgTransformNode(translateX,translateY,[self rotateAngle],1.0,1.0),[NSXMLNode attributeWithName:@"x" stringValue:[NSString stringWithFormat:@"%g%@",-0.5 * NSWidth(bounds),svgUnit]],[NSXMLNode attributeWithName:@"y" stringValue:[NSString stringWithFormat:@"%g%@",-0.5 * NSHeight(bounds),svgUnit]],[NSXMLNode attributeWithName:@"width" stringValue:[NSString stringWithFormat:@"%g%@",NSWidth(bounds),svgUnit]],[NSXMLNode attributeWithName:@"height" stringValue:[NSString stringWithFormat:@"%g%@",NSHeight(bounds),svgUnit]],nil];
			NSArray *fillAndStrokeAttributes = [self svgFillAndStrokeAttributes:unique_ID];
			[attributes addObjectsFromArray:fillAndStrokeAttributes];
			if (YES == [self isDrawingStroke]) {
				[attributes addObject:svgStrokeWidthNode([self strokeWidth])];
				[attributes addObject:svgLineJoinNode([self lineJoin])];
				[attributes addObject:svgLineCapNode([self lineCap])];
				[attributes addObjectsFromArray:(0 < [[self lineDashPattern] count]) ? svgDashArrayNodes([self lineDashPattern],[self lineDashPhase]) : svgDashArrayNodes(nil,0.0)];
			}
			if ((1e-7 < _rx) && (1e-7 < _ry)) {
			 [attributes addObject:[NSXMLNode attributeWithName:@"rx" stringValue:[NSString stringWithFormat:@"%g%@",0,svgUnit]]];
			 [attributes addObject:[NSXMLNode attributeWithName:@"ry" stringValue:[NSString stringWithFormat:@"%g%@",0,svgUnit]]];
			 }
			[rectElement setAttributes:attributes];
			[elements addObject:rectElement];
			
		} // if (YES == [self isDrawingFill]) // */
		double originX = NSMinX(bounds) - NSMinX(aRect);
		double originY = NSMinY(bounds) - NSMinY(aRect);
		NSError *err = nil;
		NSXMLDocument *xmlDoc = [[NSXMLDocument allocWithZone:[self zone]] initWithData:[_SVGImageRep SVGRepresentation] options:NSXMLNodeOptionsNone error:&err];
		NSXMLElement *rootElement;
		NSArray *rootEAttributes;
		NSArray *attributeSet = [NSArray arrayWithObjects:@"x",@"y",@"width",@"height",@"viewBox",@"preserveAspectRatio",@"id",nil];
		NSXMLNode *viewBoxNode = nil;
		NSXMLNode *preserveNode = nil;
		NSMutableArray *otherNodes = [NSMutableArray array];
		double rotate = [self rotateAngle];
		NSXMLElement *gElement = nil;
		NSMutableArray *attributes;

		if (nil == xmlDoc) {
			NSLog(@"error=%@",[err localizedDescription]);
			err = nil;
			if (nil == (xmlDoc = [[NSXMLDocument allocWithZone:[self zone]] initWithData:[_SVGImageRep SVGRepresentation] options:NSXMLDocumentValidate error:&err])) {
				NSLog(@"error=%@",[err localizedDescription]);
				err = nil;			
			}
		}
		if (nil == xmlDoc)
			return nil;
		else {
			rootElement = [xmlDoc rootElement];
			rootEAttributes = [rootElement attributes];
		}
		if (nil != rootEAttributes) {
			NSUInteger i;
			NSXMLNode *aNode;
			NSString *attr,*value;

			for (i = 0; i < [rootEAttributes count]; i++) {
				aNode = [rootEAttributes objectAtIndex:i];
				attr = [aNode name];
				value = [aNode stringValue];
				switch ([attributeSet indexOfObject:attr]) {
				case 0: // x //
					break;
				case 1: // y //
					break;
				case 2: // width //
					break;
				case 3: // height //
					break;
				case 4: // viewBox //
					viewBoxNode = [NSXMLNode attributeWithName:attr stringValue:value];
					break;
				case 5: // preserveAspectRatio //
					preserveNode = [NSXMLNode attributeWithName:attr stringValue:value];
					break;
				case 6: // id. "svg-root"であることが多いので削除する。 //
					break;
				default:
					if (nil != value)
						[otherNodes addObject:[NSXMLNode attributeWithName:attr stringValue:value]];
					break;
				}
			}
		}
		if ((-1e-13 > rotate) || (1e-13 < rotate)) {
			double svgTranslateX = originX + 0.5 * NSWidth(bounds);
			double svgTranslateY = originY + 0.5 * NSHeight(bounds);

			gElement = [[NSXMLElement allocWithZone:[self zone]] initWithName:@"g"];
			attributes = [NSMutableArray arrayWithObjects:svgTransformNode(svgTranslateX,svgTranslateY,[self rotateAngle],1.0,1.0),nil];
			[gElement setAttributes:attributes]; // shadowも付けない。できるだけ本体をいじりたくないので、shadowはどんな場合でも付け加えない。 //
			originX = -0.5 * NSWidth(bounds);
			originY = -0.5 * NSHeight(bounds);
		}
		else // SVG本体には何も変更を加えない。 //
			gElement = nil;
		if (nil == viewBoxNode)
			viewBoxNode = [NSXMLNode attributeWithName:[attributeSet objectAtIndex:4] stringValue:[NSString stringWithFormat:@"%lf %lf %lf %lf",0.0,0.0,originalSize.width,originalSize.height]];
		if (originalSize.width / originalSize.height != NSWidth(bounds) / NSHeight(bounds))
			preserveNode = [NSXMLNode attributeWithName:[attributeSet objectAtIndex:5] stringValue:@"none"];
		attributes = [NSMutableArray arrayWithObjects:[NSXMLNode attributeWithName:[attributeSet objectAtIndex:0] stringValue:[NSString stringWithFormat:@"%lf%@",originX,svgUnit]],[NSXMLNode attributeWithName:[attributeSet objectAtIndex:1] stringValue:[NSString stringWithFormat:@"%lf%@",originY,svgUnit]],[NSXMLNode attributeWithName:[attributeSet objectAtIndex:2] stringValue:[NSString stringWithFormat:@"%lf%@",NSWidth(bounds),svgUnit]],[NSXMLNode attributeWithName:[attributeSet objectAtIndex:3] stringValue:[NSString stringWithFormat:@"%lf%@",NSHeight(bounds),svgUnit]],viewBoxNode,nil];
		if (nil != preserveNode)
			[attributes addObject:preserveNode];
		if (0 < [otherNodes count])
			[attributes addObjectsFromArray:otherNodes];
		if (YES == shadowFlag)
			[attributes addObject:[NSXMLNode attributeWithName:@"filter" stringValue:[NSString stringWithFormat:@"url(#shadow_%@)",unique_ID]]];
		[rootElement setAttributes:attributes];
		if (nil != gElement) {
			[rootElement detach]; // Cannot add a child that has a parent; detach or copy first //
			[gElement addChild:rootElement];
			[elements addObject:gElement];
			[gElement release];
		}
		else {
			[rootElement detach];
			[elements addObject:rootElement];
		}
		[xmlDoc release];
		return elements;
	}
	else
		return nil;
}

@end
