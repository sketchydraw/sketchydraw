//
//  ASDialKnobCell.m
//
//  Created by 佐藤昭 on Fri 1-Oct-1999.
//  Copyright (c) 2006 SatoAkira. All rights reserved.
//

#import "ASDialKnobCell.h"
#import "ASDialKnob.h"

#ifndef M_PI
#define M_PI        3.14159265358979323846264338327950288   /* pi */
#define M_1_PI      0.318309886183790671537767526745028724  /* 1/pi */
#define M_2_PI      0.636619772367581343075535053490057448  /* 2/pi */
#endif

#ifndef __APPLE__
void dialKnobDefaultImage(CGFloat lradius,CGFloat sradius,CGFloat rotate,BOOL isFlipped);
void dialKnobtickMarks(CGFloat radius,CGFloat llength,CGFloat slength);
#endif

#ifdef WIN32
#define MAXFLOAT 3.4028234663852886e38
#endif

@implementation ASDialKnobCell

NSString *ASDialKnobBackgroundColorKey = @"backgroundColor";
NSString *ASDialKnobImageRepKey = @"imageRep";
NSString *ASDialKnobSelfFrameKey = @"selfFrame";
NSString *ASDialKnobViewRadiusKey = @"viewRadius";
NSString *ASDialKnobTickColorKey = @"tickColorKey";
NSString *ASDialKnobTickBackgroundColorKey = @"tickBackgroundColor";
NSString *ASDialKnobTickWidthKey = @"tickWidth";
NSString *ASDialKnobStartAngleKey = @"startAngle";
NSString *ASDialKnobBaseAngleKey = @"baseAngle";
NSString *ASDialKnobPrintButtonRectKey = @"printButtonRect";
NSString *ASDialKnobCopyButtonRectKey = @"copyButtonRect";
NSString *ASDialKnobClockwiseKey = @"clockwise";
NSString *ASDialKnobIsFlippedKey = @"isFlipped";

#ifdef __APPLE__
void drawCopyButton(NSRect copyButtonRect,BOOL flippedFlag)
{
	/* NSDrawButton(copyButtonRect, copyButtonRect); */ // colorが無くなるので要注意 //
	NSBezierPath *path = [NSBezierPath bezierPath];
	NSPoint center = NSMakePoint(NSMidX(copyButtonRect), NSMidY(copyButtonRect));
	CGFloat radius = 0.5 * copyButtonRect.size.width;
	CGFloat sAngle = (YES == flippedFlag) ? 0.75 * M_PI : 0.25 * M_PI;
	CGFloat eAngle = (YES == flippedFlag) ? 1.75 * M_PI : 1.25 * M_PI;
	CGFloat lineWidth = 0.2 * radius;

	[path appendBezierPathWithArcWithCenter:center radius:radius startAngle:0.0 endAngle:360.0];
	[[NSColor colorWithDeviceHue:0.133333333 saturation:0.7 brightness:1.0 alpha:1.0] set];
	[path fill];
	path = [NSBezierPath bezierPath];
	[path appendBezierPathWithArcWithCenter:center radius:radius - 0.5 * lineWidth startAngle:180.0 * M_1_PI * sAngle endAngle:180.0 * M_1_PI * eAngle clockwise:NO];
	[[NSColor colorWithDeviceHue:0.133333333 saturation:0.4 brightness:1.0 alpha:1.0] set];
	[path setLineWidth:lineWidth];
	[path stroke];
	path = [NSBezierPath bezierPath];
	[path appendBezierPathWithArcWithCenter:center radius:radius - 0.5 * lineWidth startAngle:180.0 * M_1_PI * sAngle endAngle:180.0 * M_1_PI * eAngle clockwise:YES];
	[[NSColor colorWithDeviceHue:0.133333333 saturation:0.7 brightness:0.7 alpha:1.0] set];
	[path setLineWidth:lineWidth];
	[path stroke];
}

NSBezierPath *dialKnobDefaultImage(CGFloat lradius,CGFloat sradius,CGFloat rotate,BOOL clockwiseFlag)
{
	CGFloat sAngle,eAngle,lAngle,f,radius,lineWidth;
	NSBezierPath *path;
	CGFloat lRotate = (YES == clockwiseFlag) ? -1.0 * rotate : rotate;

	lineWidth = lradius - sradius;
	radius = lradius - 0.5 * lineWidth;
	lAngle = 0.75 * M_PI;
	for (sAngle = 0.25 * M_PI,eAngle = 1.25 * M_PI,f = 1.0; sAngle < lAngle; sAngle += 0.1, eAngle -= 0.1, f -= 0.0625) {
		path = [NSBezierPath bezierPath];
		[path moveToPoint:NSMakePoint(radius * cos(sAngle),radius * sin(sAngle))];
		[path appendBezierPathWithArcWithCenter:NSZeroPoint radius:radius startAngle:180.0 * M_1_PI * sAngle endAngle:180.0 * M_1_PI * eAngle clockwise:NO];
		[[NSColor colorWithDeviceHue:0.133333333 saturation:f brightness:1.0 alpha:1.0] set];
		[path setLineWidth:lineWidth];
		[path stroke];
	}
	lAngle = 1.75 * M_PI;
	for (sAngle = 0.25 * M_PI,eAngle = 1.25 * M_PI,f = 1.0; eAngle < lAngle; sAngle -= 0.1, eAngle += 0.1, f -= 0.0625) {
		path = [NSBezierPath bezierPath];
		[path moveToPoint:NSMakePoint(radius * cos(sAngle),radius * sin(sAngle))];
		[path appendBezierPathWithArcWithCenter:NSZeroPoint radius:radius startAngle:180.0 * M_1_PI * sAngle endAngle:180.0 * M_1_PI * eAngle clockwise:YES];
		[[NSColor colorWithDeviceHue:0.133333333 saturation:1.0 brightness:f alpha:1.0] setStroke];
		[path setLineWidth:lineWidth];
		[path stroke];
	}
	radius = lradius - lineWidth;
	path = [NSBezierPath bezierPath];
	[path appendBezierPathWithArcWithCenter:NSZeroPoint radius:radius startAngle:0.0 endAngle:360.0];
	[[NSColor colorWithDeviceHue:0.133333333 saturation:1.0 brightness:1.0 alpha:1.0] set];
	[path fill];
	lAngle = 0.875 * M_PI;
	for (sAngle = 0.75 * M_PI,eAngle = 1.75 * M_PI,f = 0.0; sAngle < lAngle; sAngle += 0.01, eAngle += 0.01,f += 0.025) {
		path = [NSBezierPath bezierPath];
		[path moveToPoint:NSMakePoint(radius * cos(sAngle),radius * sin(sAngle))];
		[path lineToPoint:NSMakePoint(radius * cos(eAngle),radius * sin(eAngle))];
		[[NSColor colorWithDeviceHue:0.133333333 saturation:f brightness:1.0 alpha:1.0] setStroke];
		[path setLineWidth:0.5];
		[path stroke];
	}
	lAngle = 0.625 * M_PI;
	for (sAngle = 0.75 * M_PI,eAngle = 1.75 * M_PI,f = 0.3; sAngle > lAngle; sAngle -= 0.01, eAngle -= 0.01,f += 0.025) {
		path = [NSBezierPath bezierPath];
		[path moveToPoint:NSMakePoint(radius * cos(sAngle),radius * sin(sAngle))];
		[path lineToPoint:NSMakePoint(radius * cos(eAngle),radius * sin(eAngle))];
		[[NSColor colorWithDeviceHue:0.133333333 saturation:f brightness:1.0 alpha:1.0] setStroke];
		[path setLineWidth:0.5];
		[path stroke];
	}
	path = [NSBezierPath bezierPath];
	[path moveToPoint:NSMakePoint(radius * cos(lRotate),radius * sin(lRotate))];
	[path lineToPoint:NSMakePoint(2.0 * cos(lRotate),2.0 * sin(lRotate))];
	[[NSColor blackColor] setStroke];
	[path setLineWidth:2.0];
	[path stroke];
	return path;
}

void dialKnobtickMarks(CGFloat radius,CGFloat llength,CGFloat slength)
{
	CGFloat angle;
	NSGraphicsContext *currentContext = [NSGraphicsContext currentContext];
	NSBezierPath *path = [NSBezierPath bezierPath];
	NSAffineTransform *transform = [NSAffineTransform transform];

	[currentContext saveGraphicsState];
	[path setLineWidth:1.0];
	[transform rotateByDegrees:0.0];
	for (angle = 0.0; 360.0 > angle; angle += 30.0) {
		[path transformUsingAffineTransform:transform]; // newpathに相当する //
		[path moveToPoint:NSMakePoint(radius,0.0)];
		[path relativeLineToPoint:NSMakePoint(slength,0.0)];
		[path stroke];
		[transform rotateByDegrees:30.0]; // rotateに相当する //
	}
	for (angle = 0.0; 360.0 > angle; angle += 90.0) {
		[path transformUsingAffineTransform:transform];
		[path moveToPoint:NSMakePoint(radius,0.0)];
		[path relativeLineToPoint:NSMakePoint(llength,0.0)];
		[path stroke];
		[transform rotateByDegrees:90.0];
	}
	[currentContext restoreGraphicsState];
}
NSBezierPath *dialKnobDisabledSymbol(CGFloat radius)
{
	NSBezierPath *path = [NSBezierPath bezierPath];

	[[NSColor colorWithDeviceRed:1.0 green:0.5 blue:0.5 alpha:0.75] setStroke];
	[path setLineWidth:8.0];
	[path moveToPoint:NSMakePoint(cos(0.875 * 2.0 * M_PI) * (radius - 4.0),sin(0.875 * 2.0 * M_PI) * (radius - 4.0))];
	[path appendBezierPathWithArcWithCenter:NSMakePoint(0.0,0.0) radius:radius - 4.0 startAngle:135.0 endAngle:495.0];
	[path stroke];
	return path;
}
#endif

+ (void)initialize
/*"
   Sets our class version for archiving purposes.
"*/
{
    if (self == [ASDialKnobCell class]) {
		[self setVersion:1];
    }
}

+ (BOOL)prefersTrackingUntilMouseUp {
	return YES;	// trackMouse: inRect: ofView: untilMouseUp: で無限大の領域に設定しているのでYESを返す。 //
}

- (NSView *)controlView { // 頻繁に呼ばれる。 //
	return [super controlView];
}
- (void)setSelfFrame:(NSRect)aRect
// これは重要。イニシャライズの後必ず呼び出すこと。 //
{
	selfFrame = aRect;
	viewRadius = (selfFrame.size.width < selfFrame.size.height) ? 0.5 * selfFrame.size.width : 0.5 * selfFrame.size.height;
}
- (id)initImageCell:(NSImage *)anImage
{
	if (nil != (self = [super initImageCell:anImage])) {
		clockwise = NO;
		isFlipped = NO;
		backgroundColor = nil;
		self.rotateAngle = 0.0; // ここでsetRotateAngle:を呼び出す。 //
		tickColor = nil;
		tickBackgroundColor = nil;
		tickWidth = 0;
		copyFlag = printFlag = NO;
		imageRep = nil;
		if (nil != [self controlView]) {
			// 必ずnilになるのでこれが実行されることはない。 //
			selfFrame = [[self controlView] frame];
			viewRadius = (selfFrame.size.width < selfFrame.size.height) ? 0.5 * selfFrame.size.width : 0.5 * selfFrame.size.height;
		}
		if (nil != anImage)
			/* [self setBitmapImage:[anImage TIFFRepresentation]]; */
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6
			[self setImageRep:[anImage bestRepresentationForRect:selfFrame context:[NSGraphicsContext currentContext] hints:nil]];
#else
		[self setImageRep:[anImage bestRepresentationForDevice:nil]];
#endif
	}
	return self;
}

- (void)dealloc {
	[imageRep release];
	[backgroundColor release];
	[tickColor release];
	[tickBackgroundColor release];
	[frameName release];
	[super dealloc];
}

- (NSImage *)image // NSCellのoverwride //
{
	NSImage *anImage;

	if (YES == [imageRep isKindOfClass:[NSBitmapImageRep class]])
		anImage = [[NSImage allocWithZone:[self zone]] initWithData:[(NSBitmapImageRep *)imageRep TIFFRepresentation]];
	else {
		if (YES == [imageRep isKindOfClass:[NSEPSImageRep class]])
			anImage = [[NSImage allocWithZone:[self zone]] initWithData:[(NSEPSImageRep *)imageRep EPSRepresentation]];
		else {
			if (YES == [imageRep isKindOfClass:[NSPDFImageRep class]])
				anImage = [[NSImage allocWithZone:[self zone]] initWithData:[(NSPDFImageRep *)imageRep PDFRepresentation]];
			else {
				if (YES == [imageRep isKindOfClass:[NSPICTImageRep class]])
					anImage = [[NSImage allocWithZone:[self zone]] initWithData:[(NSPICTImageRep *)imageRep PICTRepresentation]];
				else {
#ifdef USESVG
					if (YES == [imageRep isKindOfClass:[ASWebImageRep class]])
						anImage = [[NSImage allocWithZone:[self zone]] initWithData:[(ASWebImageRep *)imageRep EPSRepresentation]];
					else
#endif
						anImage = nil;
				}
			}
		}
	}
	if (nil != anImage)
		[anImage setScalesWhenResized:YES];
	return [anImage autorelease];
}
- (void)setImage:(NSImage *)image // NSCellのoverwride //
{
	if (nil != image) {
		NSData *tiffData = [image TIFFRepresentation]; // bestRepresentationForDevice:ではNSCachedImageRepが返ってくる。NSCompositeSourceOverなどのとき見えなくなるのでTIFF表現からNSBitmapImageRepを得る。 //
		NSArray *tempReps = (nil != tiffData) ? [NSBitmapImageRep imageRepsWithData:tiffData] : nil;

		if ((nil != tempReps) && (0 < [tempReps count]))
			[self setImageRep:[tempReps objectAtIndex:0]];
		// エラーが起きたら何もしない。 //
	}
	else
		[self setImageRep:nil];
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	if (nil != controlView) { // 自身の属するWindowがisVisibleでないときに描画するとDPS Error が発生することもあるので要注意。compositeでDPS Errorになるので、setEPSImageをWindowが表示されてからセットすることで解消できる。Windowがクローズされた後にOrderFrontされると[[controlView window] isVisible]がNOになってしまうのでこの判断で決めることができない。 //
	// 上のエラーは- (NSView *)controlViewを実装していなかったためと思われる。 //
		NSGraphicsContext *currentContext = [NSGraphicsContext currentContext];

		if (YES == [currentContext isDrawingToScreen]) {
			NSBezierPath *path = [NSBezierPath bezierPath];

			if (nil != backgroundColor) {
				[backgroundColor set];
				[path appendBezierPathWithArcWithCenter:NSMakePoint(0.0,0.0) radius:viewRadius - 1.0 startAngle:0.0 endAngle:360.0];
				[path fill];
			}
			if (nil != tickBackgroundColor) {
				[tickBackgroundColor set];
				[path setLineWidth:(CGFloat)tickWidth];
				[path appendBezierPathWithArcWithCenter:NSMakePoint(0.0,0.0) radius:viewRadius - 0.5 * (CGFloat)tickWidth startAngle:0.0 endAngle:360.0];
				[path stroke];
			}
			if (nil != tickColor) {
				[tickColor set];
				dialKnobtickMarks(viewRadius - (CGFloat)tickWidth,(CGFloat)tickWidth,0.5 * (CGFloat)tickWidth);
			}
		}
		if ((YES == [currentContext isDrawingToScreen]) && (NO == [self isEnabled]))
			dialKnobDisabledSymbol(viewRadius);
		if (nil != imageRep) {
#ifdef USESVG
			if ((nil != frameName) && (YES == [NSThread isMainThread])) {
				[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pdfImageRepDidLoad:) name:PDFImageRepDidLoadNotification object:imageRep]; // imageRepをinitしたときにMainThreadでなかった場合、WebViewが起動されないためPDFImageRepができない。ここでnotification待ちにしてPDFImageRepが出来上がるのを待たなければならない。 //
				[(ASWebImageRep *)imageRep setupWebView];
				return;
			}
#endif
			NSAffineTransform *transform = [NSAffineTransform transform];
			NSRect viewRect = NSMakeRect(-1.0 * (viewRadius - (CGFloat)tickWidth),-1.0 * (viewRadius - (CGFloat)tickWidth),2.0 * (viewRadius - (CGFloat)tickWidth),2.0 * (viewRadius - (CGFloat)tickWidth));

			[currentContext saveGraphicsState];
			[transform rotateByRadians:(isFlipped != clockwise) ? -1.0 * rotateAngle : rotateAngle];
			[transform concat];
			if (NO == [imageRep drawInRect:viewRect fromRect:NSMakeRect(0.0,0.0,[imageRep size].width,[imageRep size].height) operation:NSCompositeSourceOver fraction:1.0 respectFlipped:NO hints:[NSDictionary dictionary]]) {
				if (NO == [imageRep isKindOfClass:[ASWebImageRep class]]) // 必ず最初は失敗するのでログを吐かないようにする。 //
					NSLog(@"ASDialKnob: drawInRect failed.viewRect=%@",NSStringFromRect(viewRect));
			}
			/* if (NO == [imageRep isKindOfClass:[NSBitmapImageRep class]])
				[imageRep drawInRect:viewRect];
			else {
				NSImage *anImage = [self image];
				
				if (nil != anImage) {
					NSSize imageSize = [anImage size];

					[anImage drawInRect:viewRect fromRect:NSMakeRect(0.0,0.0,imageSize.width,imageSize.height) operation:NSCompositeSourceOver fraction:1.0];
				}
			} */
			[currentContext restoreGraphicsState];
		}
		else {
			CGFloat r = viewRadius - 4.0 - (CGFloat)tickWidth;

			dialKnobDefaultImage(r,0.85 * r,rotateAngle,clockwise);
		}
	}
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	NSBezierPath *path = [NSBezierPath bezierPath];
	CGFloat halfCellWidth = 0.5 * NSWidth(cellFrame);
	CGFloat halfCellHeight = 0.5 * NSHeight(cellFrame);

	if (nil != controlView) { // 自身の属するWindowがisVisibleでないときに描画するとDPS Error が発生することもあるので要注意。compositeでDPS Errorになるので、setEPSImageをWindowが表示されてからセットすることで解消できる。Windowがクローズされた後にOrderFrontされると[[controlView window] isVisible]がNOになってしまうのでこの判断で決めることができない。 //

		if (YES == [NSGraphicsContext currentContextDrawingToScreen]) {
			
			NSRect remainRect;
			CGFloat offset,borderWidth;
			CGFloat inRectSize = (CGFloat)viewRadius * 0.2929;
			NSRect inRect = (isFlipped != clockwise) ? NSMakeRect(-1.0 * halfCellWidth,halfCellHeight - inRectSize,NSWidth(cellFrame), inRectSize) : NSMakeRect(-1.0 * halfCellWidth,-1.0 * halfCellHeight,NSWidth(cellFrame), inRectSize);

			if (YES == [self showsFirstResponder]) {
				NSUInteger i;
				CGFloat offset;
				NSColor *fColor;
				NSRect borderRect;
				NSBezierPath *fPath;
				NSColor *foColor = [self highlightColorWithFrame:cellFrame inView:controlView];
				CGFloat lineWidth = 1.0;
				NSRect savedFrame = [controlView frame];
		
				[controlView setFrame:NSInsetRect(savedFrame,-4.0,-4.0)];
				for (i = 0; i < 3; i++) { // 何故かわからないけれど3ポイントを超えると消え残ってしまう。3ポイントの中に1.0ポイントの線を引くということは3本に決まってしまう。controlViewの広げる分も大きめに取らないと不安定になる。 //
					offset = 0.5 + (CGFloat)i * lineWidth;
					borderRect = NSInsetRect(cellFrame, -1.0 * offset, -1.0 * offset);
					fPath = [NSBezierPath bezierPathWithRoundedRect:borderRect xRadius:6.0 yRadius:6.0];
					fColor = [foColor colorWithAlphaComponent:0.333333 * (CGFloat)(3 - i)];
					[fColor setStroke];
					[fPath setLineWidth:lineWidth];
					[fPath stroke];
				}
				[controlView setFrame:savedFrame];
			}
			if (YES == [self isBordered]) {
				borderWidth = 0.5;
				offset = 0.5 * borderWidth;
				[[NSColor blackColor] setStroke];
				[path appendBezierPathWithRect:NSMakeRect(offset - halfCellWidth,offset - halfCellHeight,2.0 * (halfCellWidth - offset),2.0 * (halfCellHeight - offset))];
				[path setLineWidth:borderWidth];
				[path setLineDash:(CGFloat *)NULL count:0 phase:0.0];
				[path stroke];
			}
			// else 何もしない。 //
			NSDivideRect(inRect,&printButtonRect,&remainRect, inRectSize,NSMinXEdge);
			drawCopyButton(printButtonRect,isFlipped);
			if (YES == printFlag)
				NSHighlightRect(printButtonRect);
			NSDivideRect(inRect,&copyButtonRect,&remainRect, inRectSize,NSMaxXEdge);
			drawCopyButton(copyButtonRect,isFlipped);
			if (YES == copyFlag)
				NSHighlightRect(copyButtonRect);
			offset = inRectSize * 0.25; // offset = inRectSize * 0.2; //
			[@"C" drawAtPoint:NSMakePoint(offset - halfCellWidth,NSMinY(inRect)) withAttributes:[NSDictionary dictionaryWithObject:[NSFont systemFontOfSize:0.8 * inRectSize] forKey:NSFontAttributeName]];
			[@"C" drawAtPoint:NSMakePoint(halfCellWidth - inRectSize + offset,NSMinY(inRect)) withAttributes:[NSDictionary dictionaryWithObject:[NSFont systemFontOfSize:0.8 * inRectSize] forKey:NSFontAttributeName]];
		}
		[self drawInteriorWithFrame:cellFrame inView:controlView];
		if ((YES == [NSGraphicsContext currentContextDrawingToScreen]) && (NO == [self showsFirstResponder])) {
			[[NSColor colorWithCalibratedWhite:0.0 alpha:0.2] set];
			[path appendBezierPathWithRect:NSMakeRect(-1.0 * halfCellWidth,-1.0 * halfCellHeight,2.0 * halfCellWidth,2.0 * halfCellHeight)];
			[path fill];
		}
	}
}

- (BOOL)trackMouse:(NSEvent *)theEvent inRect:(NSRect)cellFrame ofView:(NSView *)controlView untilMouseUp:(BOOL)flag {
	return [super trackMouse:theEvent inRect:NSMakeRect(-0.5 * MAXFLOAT,-0.5 * MAXFLOAT,MAXFLOAT,MAXFLOAT) ofView:controlView untilMouseUp:flag]; // NSMakeRect(-0.5 * MAXFLOAT,-0.5 * MAXFLOAT,MAXFLOAT,MAXFLOAT)によって領域がほぼ無限大に広がっているものとしてしまう。 //
}
- (BOOL)startTrackingAt:(NSPoint)startPoint inView:(NSView *)controlView
{
	if (YES == NSMouseInRect(startPoint,printButtonRect,[controlView isFlipped])) {
		printFlag = YES;
		return YES;	// ここでNOを返すと、動作が不安定になる。 //
	}
	else {
		if (YES == NSMouseInRect(startPoint,copyButtonRect,[controlView isFlipped])) {
			copyFlag = YES;
			return YES;
		}
		else {
			if (YES == [self isEnabled]) {
				startAngle = atan2(startPoint.y,startPoint.x);
				if (isFlipped != clockwise)
					startAngle *= -1.0;
				baseAngle = rotateAngle;
			}
			return [self isEnabled];
		}
	}
}
- (BOOL)continueTracking:(NSPoint)lastPoint at:(NSPoint)currentPoint inView:(NSView *)controlView
{
	if ((NO == printFlag) && (NO == copyFlag)) {
		double pAngle = atan2(currentPoint.y,currentPoint.x);

		if (isFlipped != clockwise)
			pAngle *= -1.0;
		rotateAngle = baseAngle + pAngle - startAngle;
		while (0.0 > rotateAngle)
			rotateAngle += 2.0 * M_PI;
		while (2.0 * M_PI < rotateAngle)
			rotateAngle -= 2.0 * M_PI;
		if (nil == backgroundColor)
			[controlView setNeedsDisplay:YES]; // drawInteriorWithFrame:では、軌跡が描かれてしまう。但しスピードが少し落ちる。 //
		else
			[self drawInteriorWithFrame:selfFrame inView:controlView];
		[(ASDialKnob *)controlView writeToOutlet];
	}
	return YES;
}
- (void)stopTracking:(NSPoint)lastPoint at:(NSPoint)stopPoint inView:(NSView *)controlView mouseIsUp:(BOOL)flag
{
	if ((YES == flag) && (YES == copyFlag)) {
		[NSEvent stopPeriodicEvents];	// これをやらないと、NSPeriodicタイプのイベントエラーが発生してしまう //
		[self copy:self];
		copyFlag = NO;
	}
	else {
		if ((YES == flag) && (YES == printFlag)) {
			[NSEvent stopPeriodicEvents];
			[self copy:self];
			printFlag = NO;
		}
	}
}

- (void)pdfImageRepDidLoad:(NSNotification *)aNotification
// localizedRecoverySuggestion,localizedFailureReason,localizedRecoveryOptionsはnil。 //
{
	NSDictionary *infoDic = [aNotification userInfo];
	BOOL result = [[infoDic objectForKey:PDFImageRepDidLoadResultKey] boolValue];
	NSError *err = [infoDic objectForKey:PDFImageRepDidLoadErrorKey];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:PDFImageRepDidLoadNotification object:nil];
	if (nil != frameName) {
		[frameName release];
		frameName = nil;
	}
	if (YES == result)
		[(NSControl *)[self controlView] updateCellInside:self];
	else {
		NSString *title = (nil != [err localizedDescription]) ? [err localizedDescription] : NSStringFromClass([[aNotification object] class]);
		NSString *msg = (nil != [err localizedRecoverySuggestion]) ? [err localizedRecoverySuggestion] : (nil != [infoDic objectForKey:ASWebViewFileURLKey]) ? [[(NSURL *)[infoDic objectForKey:ASWebViewFileURLKey] absoluteString] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] : @"";
		NSBeginAlertSheet(title,nil,nil,nil,nil,self,NULL,NULL,NULL,msg,nil);
	}
}
- (void)setImageRep:(NSImageRep *)newImageRep
{
	[imageRep release];
	imageRep = (nil != newImageRep) ? [newImageRep retain] : nil; // copyすることはできても、ASWebImageRepの場合には別オブジェクトにnotification待ちにしてしまうので待ちにならなくなる。 //
	if (nil != imageRep) {
		isFlipped = NO;
#ifdef USESVG
		if (YES == [imageRep isKindOfClass:[ASWebImageRep class]]) { // 通常のNSImageRepはisFlippedメソッドを持たない。 //
			isFlipped = [(ASWebImageRep *)imageRep isFlipped];
			isFlipped = NO; // 画像 //
			if (YES == [NSThread isMainThread]) {
				[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pdfImageRepDidLoad:) name:PDFImageRepDidLoadNotification object:imageRep];
				[frameName release];
				frameName = nil;
			}
			else {
				[frameName release];
				frameName = [[NSString alloc] initWithString:NSStringFromClass([self class])];
			}
		}
#endif
	}
	else
		isFlipped = NO;
}
- (NSImageRep *)imageRep {
	return imageRep;
}

- (void)setBackgroundColor:(NSColor *)newColor {
	[backgroundColor release];
	backgroundColor = (nil != newColor) ? [[newColor copy] retain] : nil;
}
- (NSColor *)backgroundColor {
	return backgroundColor;
}

- (void)setTickMarks:(NSColor *)aColor background:(NSColor *)bColor width:(NSInteger)wValue
{
	tickWidth = ((nil == aColor) && (nil == bColor)) ? 0 : labs(wValue);
	[tickColor release];
	tickColor = ((0 < tickWidth) && (nil != aColor)) ? [[aColor copy] retain] : nil;
	[tickBackgroundColor release];
	tickBackgroundColor = ((0 < tickWidth) && (nil != bColor)) ? [[bColor copy] retain] : nil;
}

- (void)setRadianValue:(double)aRadian
{
	rotateAngle = aRadian;
	while (0.0 > rotateAngle)
		rotateAngle += 2.0 * M_PI;
	while (2.0 * M_PI < rotateAngle)
		rotateAngle -= 2.0 * M_PI;
}
- (void)setDMSValue:(double)aDouble
{
	double a,b,c;
	double error = 1.0e-11; // modf()が1.0を返してしまうことを防ぐ為の数値 //
	NSInteger sgn = (aDouble < 0.0) ? -1 : 1;
	double x = (aDouble < 0.0) ? fabs(aDouble) : aDouble;
	
	/* x = modf(modf(modf(x,&a) * 100.0 + error, &b) * 100.0 + error, &c) * 2.777777777777777777e-4;
	x += c * 2.777777777777777777e-4;
	x += a + b * 1.666666666666666666e-2;
	x *= 1.7453292519943296e-2; */
	x = modf(modf(modf(x,&a) * 100.0 + error, &b) * 100.0 + error, &c) * M_PI / 648000.0 - 4.896618179206312657133e-15;
	x += (a + b / 60.0 + c / 3600.0) * M_PI / 180.0;
	rotateAngle = (sgn == -1) ? -x : x;
	while (0.0 > rotateAngle)
		rotateAngle += 2.0 * M_PI;
	while (2.0 * M_PI < rotateAngle)
		rotateAngle -= 2.0 * M_PI;
}
- (void)setDEGValue:(double)aDouble
{
	rotateAngle = aDouble * M_PI / 180.0;
	while (0.0 > rotateAngle)
		rotateAngle += 2.0 * M_PI;
	while (2.0 * M_PI < rotateAngle)
		rotateAngle -= 2.0 * M_PI;
}
- (void)setDoubleValue:(double)aDouble {
	[self setDEGValue:aDouble];
}

- (double)radianValue {
	return rotateAngle;
}
- (double)dmsValue
{
	double a,b;
	NSInteger sgn = (rotateAngle < 0.0) ? -1 : 1;
	double x = (rotateAngle < 0.0) ? fabs(rotateAngle) : rotateAngle;

	x = modf( modf(x * 180.0 * M_1_PI, &a) * 60.0, &b ) * 0.006;
	x += a + b * 0.01;
	return (sgn == -1) ? -x : x;
}
- (double)degValue {
	return rotateAngle * 180.0 * M_1_PI;
}
- (double)doubleValue {
	return [self degValue];
}
- (void)setClockwise:(BOOL)flag {
	clockwise = flag;
}
- (BOOL)clockwise {
	return clockwise;
}

- (BOOL)isFlipped {
	return isFlipped;
}

#ifdef USESVG
- (void)pdfImageRepDidLoad_copy:(NSNotification *)aNotification
// localizedRecoverySuggestion,localizedFailureReason,localizedRecoveryOptionsはnil。 //
{
	NSDictionary *infoDic = [aNotification userInfo];
	ASWebImageRep *copiedRep = [aNotification object];
	BOOL result = [[infoDic objectForKey:PDFImageRepDidLoadResultKey] boolValue];
	NSError *err = [infoDic objectForKey:PDFImageRepDidLoadErrorKey];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:PDFImageRepDidLoadNotification object:nil];
	if (nil != frameName) {
		[frameName release];
		frameName = nil;
	}
	if (YES == result) {
		NSPasteboardItem *pasteboardItem = [[NSPasteboardItem alloc] init];
		if (nil != [copiedRep SVGRepresentation])
			[pasteboardItem setData:[copiedRep SVGRepresentation] forType:ASSVGDocumentTypeName];
		if (nil != [copiedRep EPSRepresentation])
			[pasteboardItem setData:[copiedRep EPSRepresentation] forType:@"com.adobe.encapsulated-postscript"];
		if (nil != [copiedRep PDFRepresentation])
			[pasteboardItem setData:[copiedRep PDFRepresentation] forType:(NSString *)kUTTypePDF];
		if (0 < [[pasteboardItem types] count]) {
			NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
			[pasteboard clearContents];
			if (NO == [pasteboard writeObjects:[NSArray arrayWithObject:pasteboardItem]])
				NSLog(@"ASDialKnob:pasteboard error.");
		}
		[pasteboardItem release];
	}
	else {
		NSString *title = (nil != [err localizedDescription]) ? [err localizedDescription] : NSStringFromClass([[aNotification object] class]);
		NSString *msg = (nil != [err localizedRecoverySuggestion]) ? [err localizedRecoverySuggestion] : (nil != [infoDic objectForKey:ASWebViewFileURLKey]) ? [[(NSURL *)[infoDic objectForKey:ASWebViewFileURLKey] absoluteString] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] : @"";
		NSBeginAlertSheet(title,nil,nil,nil,nil,self,NULL,NULL,NULL,msg,nil);
	}
	// [copiedRep release]; //
}
#endif

- (void)copy:(id)sender
{
	NSPasteboardItem *pasteboardItem;
	NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
	NSRect insideRect = NSMakeRect(-1.0 * viewRadius,-1.0 * viewRadius,2.0 * viewRadius,2.0 * viewRadius);

	copyFlag = printFlag = YES;
	if (nil != imageRep) {
		Class imageRepClass = [imageRep class];
#ifdef USESVG
		if ([ASWebImageRep class] == imageRepClass) {
			double scaleX = 2.0 * (viewRadius - (CGFloat)tickWidth) / NSWidth([(ASWebImageRep *)imageRep bounds]);
			double scaleY = 2.0 * (viewRadius - (CGFloat)tickWidth) / NSHeight([(ASWebImageRep *)imageRep bounds]);
			NSXMLDocument *tempDoc = [(ASWebImageRep *)imageRep transformedDocument:([(ASWebImageRep *)imageRep isFlipped] == clockwise) ? rotateAngle : 2.0 * M_PI - rotateAngle scaleXBy:scaleX yBy:scaleY]; // グローバル変数isFlippedでは判断できないので[ isFlipped]を呼び出して判断する。 //
			ASWebImageRep *copiedRep = [[ASWebImageRep allocWithZone:[self zone]] initWithXMLDocument:tempDoc];
			if (YES == [NSThread isMainThread]) {
				[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pdfImageRepDidLoad_copy:) name:PDFImageRepDidLoadNotification object:copiedRep];
				[frameName release];
				frameName = nil;
			}
			else {
				[frameName release];
				frameName = nil; // どうしようもないのでcopy不可能。SVGRepresentationのみ取得する方法もあるが面倒くさいのでやめる。 //
			}
			[copiedRep release];
		}
		else {
#endif
			if ([NSPDFImageRep class] == imageRepClass) {
				pasteboardItem = [[NSPasteboardItem alloc] init];
				[pasteboardItem setData:[[self controlView] dataWithPDFInsideRect:insideRect] forType:(NSString *)kUTTypePDF];
				[pasteboardItem setData:[[self controlView] dataWithEPSInsideRect:insideRect] forType:@"com.adobe.encapsulated-postscript"];
				if (0 < [[pasteboardItem types] count]) {
					[pasteboard clearContents];
					if (NO == [pasteboard writeObjects:[NSArray arrayWithObject:pasteboardItem]])
						NSLog(@"ASWebImageView:pasteboard error.");
				}
				[pasteboardItem release];
			}
			else {
				pasteboardItem = [[NSPasteboardItem alloc] init];
				[pasteboardItem setData:[[self controlView] dataWithEPSInsideRect:insideRect] forType:@"com.adobe.encapsulated-postscript"];
				[pasteboardItem setData:[[self controlView] dataWithPDFInsideRect:insideRect] forType:(NSString *)kUTTypePDF];
				if (0 < [[pasteboardItem types] count]) {
					[pasteboard clearContents];
					if (NO == [pasteboard writeObjects:[NSArray arrayWithObject:pasteboardItem]])
						NSLog(@"ASWebImageView:pasteboard error.");
				}
				[pasteboardItem release];
			}
#ifdef USESVG
		}
#endif
	}
	else {
		pasteboardItem = [[NSPasteboardItem alloc] init];
		[pasteboardItem setData:[[self controlView] dataWithEPSInsideRect:insideRect] forType:@"com.adobe.encapsulated-postscript"];
		[pasteboardItem setData:[[self controlView] dataWithPDFInsideRect:insideRect] forType:(NSString *)kUTTypePDF];
		if (0 < [[pasteboardItem types] count]) {
			[pasteboard clearContents];
			if (NO == [pasteboard writeObjects:[NSArray arrayWithObject:pasteboardItem]])
				NSLog(@"ASWebImageView:pasteboard error.");
		}
		[pasteboardItem release];
	}
	copyFlag = printFlag = NO;
}

- (IBAction)print:(id)sender
{
	copyFlag = printFlag = YES;
	[[NSPrintOperation printOperationWithView:[self controlView] printInfo:[NSPrintInfo sharedPrintInfo]] runOperation];
	copyFlag = printFlag = NO;
}

- (void)sizeToFit
{
	if (NO == NSEqualRects([[self controlView] frame],selfFrame)) {
		NSView *cView = [self controlView];
		NSSize frameSize = [cView frame].size;

		selfFrame = [cView frame];
		viewRadius = (frameSize.width < frameSize.height) ? 0.5 * frameSize.width : 0.5 * frameSize.height;
		[cView setBoundsOrigin:NSMakePoint(-0.5 * frameSize.width,-0.5 * frameSize.height)];
		[cView setNeedsDisplay:YES]; // drawWithFrame:は駄目 //
	}
}

// Archiving methods //

- (id)initWithCoder:(NSCoder *)aDecoder
{
	[super initWithCoder:aDecoder];
	backgroundColor = [[aDecoder decodeObjectForKey:ASDialKnobBackgroundColorKey] copy];
	rotateAngle = [aDecoder decodeDoubleForKey:ASDialKnobRotateAngleKey];
	imageRep = [[aDecoder decodeObjectForKey:ASDialKnobImageRepKey] copy];
	selfFrame = [aDecoder decodeRectForKey:ASDialKnobSelfFrameKey];
	viewRadius = [aDecoder decodeDoubleForKey:ASDialKnobViewRadiusKey];
	tickColor = [[aDecoder decodeObjectForKey:ASDialKnobTickColorKey] copy];
	tickBackgroundColor = [[aDecoder decodeObjectForKey:ASDialKnobTickBackgroundColorKey] copy];
	tickWidth = [aDecoder decodeIntegerForKey:ASDialKnobTickWidthKey];
	startAngle = [aDecoder decodeDoubleForKey:ASDialKnobStartAngleKey];
	baseAngle = [aDecoder decodeDoubleForKey:ASDialKnobBaseAngleKey];
	printButtonRect = [aDecoder decodeRectForKey:ASDialKnobPrintButtonRectKey];
	copyButtonRect = [aDecoder decodeRectForKey:ASDialKnobCopyButtonRectKey];
	clockwise = [aDecoder decodeBoolForKey:ASDialKnobClockwiseKey];
	isFlipped = [aDecoder decodeBoolForKey:ASDialKnobIsFlippedKey];
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[super encodeWithCoder:aCoder];
	[aCoder encodeObject:backgroundColor forKey:ASDialKnobBackgroundColorKey];
	[aCoder encodeDouble:rotateAngle forKey:ASDialKnobRotateAngleKey];
	[aCoder encodeObject:imageRep forKey:ASDialKnobImageRepKey];
	[aCoder encodeRect:selfFrame forKey:ASDialKnobSelfFrameKey];
	[aCoder encodeDouble:viewRadius forKey:ASDialKnobViewRadiusKey];
	[aCoder encodeObject:tickColor forKey:ASDialKnobTickColorKey];
	[aCoder encodeObject:tickBackgroundColor forKey:ASDialKnobTickBackgroundColorKey];
	[aCoder encodeInteger:tickWidth forKey:ASDialKnobTickWidthKey];
	[aCoder encodeDouble:startAngle forKey:ASDialKnobStartAngleKey];
	[aCoder encodeDouble:baseAngle forKey:ASDialKnobBaseAngleKey];
	[aCoder encodeRect:printButtonRect forKey:ASDialKnobPrintButtonRectKey];
	[aCoder encodeRect:copyButtonRect forKey:ASDialKnobCopyButtonRectKey];
	[aCoder encodeBool:clockwise forKey:ASDialKnobClockwiseKey];
	[aCoder encodeBool:isFlipped forKey:ASDialKnobIsFlippedKey];
}

#pragma mark Property

- (double)rotateAngle {
	return rotateAngle;
}
- (void)setRotateAngle:(double)aValue {
	rotateAngle = aValue;
	[self setObjectValue:[NSNumber numberWithDouble:aValue]];
}

@end
