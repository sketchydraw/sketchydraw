//
//  ASImageViewCell.m
//  ASImageView
//
//  Created by 佐藤 昭 on 平成 21/02/11.
//  Copyright 2009 SatoAkira. All rights reserved.
//

#import "ASImageViewCell.h"
#import <PDFKit/PDFDocument.h>

@implementation ASImageViewCell

NSString *ASImageViewImageRepsKey = @"imageReps";
NSString *ASImageViewCurrentPageKey = @"currentPage";
CGFloat ASImageViewDefaultFraction = 1.0;
NSString *ASImageViewFractionKey = @"delta";
NSString *ASImageViewCanUseFractionKey = @"canUseFraction";
NSString *ASImageViewCompositingOperationKey = @"compositingOperation";
NSCompositingOperation ASImageViewDefaultCompositeOperation = NSCompositeSourceOver;
NSString *ASImageViewImageScalingKey = @"imageScaling";
NSString *ASImageViewImageFrameStyleKey = @"imageFrameStyle";
NSString *ASImageViewImageAlignmentKey = @"imageAlignment";
NSString *ASImageViewBackgroundColorKey = @"backgroundColor";
NSString *ASImageViewUseBackgroundColorKey = @"useBackgroundColor";

+ (void)initialize
// Sets our class version for archiving purposes. //
{
    if (self == [ASImageViewCell class]) {
		[self setVersion:1];
    }
}
- (NSView *)controlView { // 頻繁に呼ばれる。 //
	return [super controlView];
}
- (BOOL)isFlipped {
	return isFlipped;
}
- (id)initImageCell:(NSImage *)anImage
{
	if (nil != (self = [super initImageCell:anImage])) {
		imageScaling = NSImageScaleProportionallyUpOrDown;
		imageFrameStyle = NSImageFrameNone;
		imageAlignment = NSImageAlignCenter;
		backgroundColor = [[NSColor whiteColor] retain];
		useBackgroundColor = NO;
		compositingOperation = ASImageViewDefaultCompositeOperation;
		delta = ASImageViewDefaultFraction;
		bottomLeft = NSZeroSize;
		topRight = NSZeroSize;
		frameName = nil;
		[self setImage:anImage]; // 大体のものはここで初期化される。 //
	}
	return self;
}
- (void)dealloc
{
	[_imageReps release];
	[backgroundColor release];
	[frameName release];
	[super dealloc];
}

- (NSImage *)image
// 元のサイズのNSImageを返す。 //
{
	NSImageRep *imageRep = [self imageRep];
	if (nil != imageRep) {
		NSImage *originalImage;

#ifdef USESVG
		if (YES == [imageRep isKindOfClass:[ASWebImageRep class]]) {
			originalImage = [[NSImage allocWithZone:[self zone]] initWithData:[(ASWebImageRep *)imageRep PDFRepresentation]]; // not flipped. //
		}
		else {
#endif
		if (YES == [imageRep isKindOfClass:[NSPDFImageRep class]]) {
			/* if (1 < [(NSPDFImageRep *)_imageRep pageCount])
				originalImage = [[NSImage allocWithZone:[self zone]] initWithData:[self dataWithPDFInsideRect:[self bounds]]];
			else */
				originalImage = [[NSImage allocWithZone:[self zone]] initWithData:[(NSPDFImageRep *)imageRep PDFRepresentation]];
				/* NSLog(@"count=%u",[[NSBitmapImageRep imageRepsWithData:[originalImage TIFFRepresentation]] count]); */
		}
		else {
			if (YES == [imageRep isKindOfClass:[NSBitmapImageRep class]])
				originalImage = [[NSImage allocWithZone:[self zone]] initWithData:[(NSBitmapImageRep *)imageRep TIFFRepresentation]];
			else {
				if (YES == [imageRep isKindOfClass:[NSPICTImageRep class]])
					originalImage = [[NSImage allocWithZone:[self zone]] initWithData:[(NSPICTImageRep *)imageRep PICTRepresentation]];
				else {
					if (YES == [imageRep isKindOfClass:[NSEPSImageRep class]])
						originalImage = [[NSImage allocWithZone:[self zone]] initWithData:[(NSEPSImageRep *)imageRep EPSRepresentation]];
					else
						originalImage = nil;
				}
			}
		}
#ifdef USESVG
		}
#endif
		if (nil != originalImage) {
			[originalImage setSize:originalSize];
			return [originalImage autorelease];
		}
		else
			return nil;
	}
	else
		return nil;
}
- (NSImageRep *)imageRep
{
	NSImageRep *imageRep = (nil != _imageReps) ? [_imageReps objectAtIndex:0] : nil;
	if (nil != imageRep) {
		if  (YES == [imageRep isKindOfClass:[NSPDFImageRep class]]) {
			[(NSPDFImageRep *)imageRep setCurrentPage:currentPage];
			return imageRep;
		}
		else
			return [_imageReps objectAtIndex:(NSUInteger)currentPage];
	}
	else
		return nil;
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
- (void)setImageWithArray:(NSArray *)anArray
{
	[_imageReps release];
	if ((nil != anArray) && (0 < [anArray count])) {
		NSImageRep *imageRep;
		_imageReps = [[NSArray allocWithZone:[self zone]] initWithArray:anArray];
		currentPage = 0;
		imageRep = [_imageReps objectAtIndex:0];
		originalSize = [imageRep size];
#ifdef USESVG
		if ((YES == [imageRep isKindOfClass:[NSPDFImageRep class]]) || (YES == [imageRep isKindOfClass:[ASWebImageRep class]])) {
			isFlipped = NO;
			canUseFraction = YES; // SVGの場合、マルチページに未対応なのと、NSImageからのprint:でハングアップする(NSImageを取得するときにprintOperationを使うため)のでNOとする。PDFの場合、1ページ目以降のNSImageを取得できない。従って[NSImage drawAtPoint: は不可能である。 //
			if (YES == [imageRep isKindOfClass:[ASWebImageRep class]]) {
				if (YES == [NSThread isMainThread]) {
					[[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(pdfImageRepDidLoad:) name:PDFImageRepDidLoadNotification object:imageRep];
					[frameName release];
					frameName = nil;
				}
				else {
					[frameName release];
					frameName = [[NSString alloc] initWithString:NSStringFromClass([self class])]; // ASWebImageRepにframeNameをセットするタイミングが無いので、ここでセットする。 //
				}

			}
		}
		else {
			isFlipped = NO;
			canUseFraction = YES;
		}
#else
		if (YES == [imageRep isKindOfClass:[NSPDFImageRep class]]) {
			isFlipped = NO;
			canUseFraction = NO;
		}
		else {
			isFlipped = NO;
			canUseFraction = YES;
		}
#endif
	}
	else {
		_imageReps = nil;
		currentPage = 0;
		originalSize = NSZeroSize;
		canUseFraction = YES; // default //
	}
}
- (void)setImageRep:(NSImageRep *)imageRep
{
	[_imageReps release];
	if (nil != imageRep) {
		_imageReps = [[NSArray allocWithZone:[self zone]] initWithArray:[NSArray arrayWithObject:imageRep]];
		currentPage = 0;
		originalSize = [imageRep size];
#ifdef USESVG
		if ((YES == [imageRep isKindOfClass:[NSPDFImageRep class]]) || (YES == [imageRep isKindOfClass:[ASWebImageRep class]])) {
			isFlipped = NO;
			canUseFraction = NO; // SVGの場合、マルチページに未対応なのと、NSImageからのprint:でハングアップするのでNOとする。PDFの場合、1ページ目以降のNSImageを取得できない。従って[NSImage drawAtPoint: は不可能である。 //
			if (YES == [imageRep isKindOfClass:[ASWebImageRep class]]) {
				if (YES == [NSThread isMainThread]) {
					[[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(pdfImageRepDidLoad:) name:PDFImageRepDidLoadNotification object:imageRep];
					[frameName release];
					frameName = nil;
				}
				else {
					[frameName release];
					frameName = [[NSString alloc] initWithString:NSStringFromClass([self class])]; // ASWebImageRepにframeNameをセットするタイミングが無いので、ここでセットする。 //
				}
			}
		}
		else {
			isFlipped = NO;
			canUseFraction = YES;
		}
#else
		if (YES == [imageRep isKindOfClass:[NSPDFImageRep class]]) {
			isFlipped = NO;
			canUseFraction = NO;
		}
		else {
			isFlipped = NO;
			canUseFraction = YES;
		}
#endif
	}
	else {
		_imageReps = nil;
		currentPage = 0;
		originalSize = NSZeroSize;
		canUseFraction = YES; // default //
	}
}

- (void)setImage:(NSImage *)image
// override.imageがnilのときはイメージが消去される。 //
{
	if (nil != image) {
		NSData *tiffData = [image TIFFRepresentation]; // bestRepresentationForDevice:ではNSCachedImageRepが返ってくる。NSCompositeSourceOverなどのとき見えなくなるのでTIFF表現からNSBitmapImageRepを得る。 //
		NSArray *tempReps = (nil != tiffData) ? [NSBitmapImageRep imageRepsWithData:tiffData] : nil;

		if ((nil != tempReps) && (0 < [tempReps count]))
			[self setImageWithArray:tempReps];
		else
			[self setImageWithArray:nil];
	}
	else
		[self setImageWithArray:nil];
}
- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
// ASImageViewをWebViewのサブクラスにすると、これが呼ばれなくなる。従って何も表示されない。黒くなる。 //
{
	CGFloat ratio;
	NSRect clipRect;
	NSSize imageSize;
	CGFloat wSize = NSWidth(cellFrame) - bottomLeft.width - topRight.width;
	CGFloat hSize = NSHeight(cellFrame) - bottomLeft.height - topRight.height;
	NSPoint oPoint = NSMakePoint(NSMinX(cellFrame) + bottomLeft.width,NSMinY(cellFrame) + bottomLeft.height);
	NSGraphicsContext *currentContext = [NSGraphicsContext currentContext];
	BOOL setClip = NO;
	NSImageScaling tempImageScaling = imageScaling;

	if (NSImageScaleProportionallyDown == imageScaling) { // NSImageViewとの互換性をとる。 //
		imageSize = NSMakeSize(originalSize.width - bottomLeft.width - topRight.width,originalSize.height - bottomLeft.height - topRight.height);
		if (wSize / imageSize.width < hSize / imageSize.height) {
			if (1.0 < (ratio = wSize / imageSize.width))
				tempImageScaling = NSImageScaleNone;
		}
		else {
			if (1.0 < (ratio = hSize / imageSize.height))
				tempImageScaling = NSImageScaleNone;
		}
	}
	switch (tempImageScaling) {
	case NSImageScaleProportionallyDown: case NSImageScaleProportionallyUpOrDown: // イメージの上端又は右端に白い線が表示されることがあるが直し方が分からない。標準のNSImageViewでも同じ症状が出る。 //
		imageSize = NSMakeSize(originalSize.width - bottomLeft.width - topRight.width,originalSize.height - bottomLeft.height - topRight.height);
		if (wSize / imageSize.width < hSize / imageSize.height) {
			ratio = wSize / imageSize.width;
			imageSize.width *= ratio;
			imageSize.height *= ratio;
			switch (imageAlignment) {
			case NSImageAlignCenter: case NSImageAlignLeft: case NSImageAlignRight:
				oPoint.y += 0.5 * (hSize - imageSize.height);
				break;
			case NSImageAlignTop: case NSImageAlignTopLeft: case NSImageAlignTopRight:
				oPoint.y += hSize - imageSize.height;
				break;
			default:
				break;
			}
		}
		else {
			ratio = hSize / imageSize.height;
			imageSize.width *= ratio;
			imageSize.height *= ratio;
			switch (imageAlignment) {
			case NSImageAlignCenter: case NSImageAlignTop: case NSImageAlignBottom:
				oPoint.x += 0.5 * (wSize - imageSize.width);
				break;
			case NSImageAlignRight: case NSImageAlignTopRight: case NSImageAlignBottomRight:
				oPoint.x += wSize - imageSize.width;
				break;
			default:
				break;
			}
		}
		clipRect = NSMakeRect(0.0,0.0,imageSize.width,imageSize.height);
		break;
	case NSImageScaleAxesIndependently:
		imageSize = NSMakeSize(wSize,hSize);
		clipRect = NSMakeRect(0.0,0.0,imageSize.width,imageSize.height);
		break;
		
	default:	// case NSImageScaleNone: //
		imageSize = originalSize;
#ifdef __APPLE__
		clipRect.size = originalSize;
#else
		clipRect.size.width = (imageSize.width < wSize) ? imageSize.width : wSize;
		clipRect.size.height = (imageSize.height < hSize) ? imageSize.height : hSize; // [imageObj compositeToPoint: fromRect: operation:]を使うときはこれでsizeを決める。 //
#endif
		clipRect.origin = NSZeroPoint;
		switch (imageAlignment) {
		case NSImageAlignCenter:
			if (imageSize.width < wSize)
				oPoint.x += 0.5 * (wSize - imageSize.width);
			else
				clipRect.origin.x += 0.5 * (imageSize.width - wSize);
			if (imageSize.height < hSize)
				oPoint.y += 0.5 * (hSize - imageSize.height);
			else
				clipRect.origin.y += 0.5 * (imageSize.height - hSize);
			break;
		case NSImageAlignTop:
			if (imageSize.width < wSize)
				oPoint.x += 0.5 * (wSize - imageSize.width);
			else
				clipRect.origin.x += 0.5 * (imageSize.width - wSize);
			if (NO == isFlipped) {
				if (imageSize.height < hSize)
					oPoint.y += hSize - imageSize.height;
				else
					clipRect.origin.y += imageSize.height - hSize;
			}
			break;
		case NSImageAlignTopLeft:
			if (NO == isFlipped) {
				if (imageSize.height < hSize)
					oPoint.y += hSize - imageSize.height;
				else
					clipRect.origin.y += imageSize.height - hSize;
			}
			break;
		case NSImageAlignTopRight:
			if (imageSize.width < wSize)
				oPoint.x += wSize - imageSize.width;
			else
				clipRect.origin.x += imageSize.width - wSize;
			if (NO == isFlipped) {
				if (imageSize.height < hSize)
					oPoint.y += hSize - imageSize.height;
				else
					clipRect.origin.y += imageSize.height - hSize;
			}
			break;
		case NSImageAlignLeft:
			if (imageSize.height < hSize)
				oPoint.y += 0.5 * (hSize - imageSize.height);
			else
				clipRect.origin.y += 0.5 * (imageSize.height - hSize);
			break;
		case NSImageAlignBottom:
			if (imageSize.width < wSize)
				oPoint.x += 0.5 * (wSize - imageSize.width);
			else
				clipRect.origin.x += 0.5 * (imageSize.width - wSize);
			if (YES == isFlipped) {
				if (imageSize.height < hSize)
					oPoint.y += hSize - imageSize.height;
				else
					clipRect.origin.y += imageSize.height - hSize;
			}
			break;
		case NSImageAlignBottomRight:
			if (imageSize.width < wSize)
				oPoint.x += wSize - imageSize.width;
			else
				clipRect.origin.x += imageSize.width - wSize;
			if (YES == isFlipped) {
				if (imageSize.height < hSize)
					oPoint.y += hSize - imageSize.height;
				else
					clipRect.origin.y += imageSize.height - hSize;
			}
			break;
		case NSImageAlignRight:
			if (imageSize.width < wSize)
				oPoint.x += wSize - imageSize.width;
			else
				clipRect.origin.x += imageSize.width - wSize;
			if (imageSize.height < hSize)
				oPoint.y += 0.5 * (hSize - imageSize.height);
			else
				clipRect.origin.y += 0.5 * (imageSize.height - hSize);
			break;
		default:	// case NSImageAlignBottomLeft: //
			if (YES == isFlipped) {
				if (imageSize.height < hSize)
					oPoint.y += hSize - imageSize.height;
				else
					clipRect.origin.y += imageSize.height - hSize;
			}
			break;
		}
		break;
	}
	if ((oPoint.x + imageSize.width > NSMinX(cellFrame) + bottomLeft.width + wSize) || (oPoint.y + imageSize.height > NSMinY(cellFrame) + bottomLeft.height + hSize)) {
		NSSize renderingSize;
		NSBezierPath *path = [NSBezierPath bezierPath];

		renderingSize.width = (oPoint.x + imageSize.width > NSMinX(cellFrame) + bottomLeft.width + wSize) ? NSMinX(cellFrame) + NSWidth(cellFrame) - oPoint.x - topRight.width : imageSize.width;
		renderingSize.height = (oPoint.y + imageSize.height > NSMinY(cellFrame) + bottomLeft.height + hSize) ? NSMinY(cellFrame) + NSHeight(cellFrame) - oPoint.y - topRight.height : imageSize.height;
		[currentContext saveGraphicsState];
		[path appendBezierPathWithRect:NSMakeRect(oPoint.x,oPoint.y,renderingSize.width,renderingSize.height)];
		[path addClip];
		setClip = YES;
	}
	NSImageRep *imageRep = [self imageRep];
	if (nil != imageRep) {
#ifdef USESVG
		if ((nil != frameName) && (YES == [NSThread isMainThread])) {
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pdfImageRepDidLoad:) name:PDFImageRepDidLoadNotification object:imageRep]; // imageRepをinitしたときにMainThreadでなかった場合、WebViewが起動されないためPDFImageRepができない。ここでnotification待ちにしてPDFImageRepが出来上がるのを待たなければならない。 //
			[(ASWebImageRep *)imageRep setupWebView];
			if (YES == setClip)
				[currentContext restoreGraphicsState];
			return;
		}
#endif		
		if (NO == [imageRep drawInRect:NSMakeRect(oPoint.x - NSMinX(clipRect),oPoint.y - NSMinY(clipRect),imageSize.width,imageSize.height) fromRect:NSMakeRect(0.0,0.0,originalSize.width,originalSize.height) operation:compositingOperation fraction:delta respectFlipped:NO hints:[NSDictionary dictionary]]) { // respectFlippedはYESでもNOでも結果は同じ。YES if the flipped context of the receiver should be respected, otherwise NO.An optional dictionary of hints that provide more context for selecting or generating the image. See Image_Hint_Dictionary_Keys for a summary of the possible key-value pairs.キーはNSImageHintCTMとNSImageHintInterpolationの2つ。 //
			if (NO == [imageRep isKindOfClass:[ASWebImageRep class]]) // 必ず最初は失敗するのでログを吐かないようにする。 //
				NSLog(@"ASImageView:%@ that is subclass of NSImageRep can't drawInRect:%@. fraction=%f",NSStringFromClass([imageRep class]),NSStringFromRect(NSMakeRect(oPoint.x - NSMinX(clipRect),oPoint.y - NSMinY(clipRect),imageSize.width,imageSize.height)),delta);
		}
		/* else {
			NSImage *anImage = [self image]; // NSImageを保持しておいてリサイズすると画像の質が劣化するのでその都度作る。かなりスピードが落ちるがこのままにする。 //

			if (nil != anImage) {
				if (NO == NSEqualSizes(originalSize,imageSize))
					[anImage setSize:imageSize];
				[anImage setFlipped:isFlipped];
#ifdef __APPLE__
				[anImage drawAtPoint:oPoint fromRect:clipRect operation:compositingOperation fraction:delta];
#else
				[anImage compositeToPoint:oPoint fromRect:clipRect operation:compositingOperation];
#endif
			}
		} */
	}
	if (YES == setClip)
		[currentContext restoreGraphicsState];
}

- (void)drawFrame:(NSRect)aRect
{
	CGFloat lineW;
#ifdef __APPLE__
	NSUInteger i,j;
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5
	CGFloat hue,saturation,bright,alpha;
	CGFloat r,grayScale0,grayScale1,grayScale2,lineW2;
#else
	float r,grayScale0,grayScale1,grayScale2,lineW2,bright,hue,saturation,alpha;
#endif
	NSPoint *points;
	NSColor *thisBackgroundColor;
	NSBezierPath *bPath = [NSBezierPath bezierPath];
#endif

	switch (imageFrameStyle) {
	case NSImageFramePhoto:
		lineW = bottomLeft.width;
#ifdef __APPLE__
		points = (NSPoint *)malloc(3 * sizeof(NSPoint));
		if (NO == isFlipped) {
			*points = NSMakePoint(NSMinX(aRect) + lineW, NSMinY(aRect) + 0.5 * (bottomLeft.height - lineW));
			*(points + 1) = NSMakePoint(NSMaxX(aRect) - 0.5 * (topRight.width - lineW), NSMinY(aRect) + 0.5 * (bottomLeft.height - lineW));
			*(points + 2) = NSMakePoint(NSMaxX(aRect) - 0.5 * (topRight.width - lineW), NSMaxY(aRect) - lineW);
		}
		else {
			*points = NSMakePoint(NSMinX(aRect) + lineW, NSMaxY(aRect) - 0.5 * (bottomLeft.height - lineW));
			*(points + 1) = NSMakePoint(NSMaxX(aRect) - 0.5 * (topRight.width - lineW), NSMaxY(aRect) - 0.5 * (bottomLeft.height - lineW));
			*(points + 2) = NSMakePoint(NSMaxX(aRect) - 0.5 * (topRight.width - lineW), NSMinY(aRect) + lineW);
		}
		[bPath appendBezierPathWithPoints:points count:3];
		[[NSColor colorWithDeviceWhite:0.167 alpha:1.0] setStroke];
		[bPath setLineJoinStyle:NSMiterLineJoinStyle];
		[bPath setLineCapStyle:NSButtLineCapStyle];
		[bPath setLineWidth:bottomLeft.height - lineW];
		[bPath stroke];
		bPath = [NSBezierPath bezierPath];
		if (NO == isFlipped)
			[bPath appendBezierPathWithRect:NSMakeRect(NSMinX(aRect) + 0.5 * lineW, NSMinY(aRect) + bottomLeft.height - 0.5 * lineW, NSWidth(aRect) - topRight.width, NSHeight(aRect) - bottomLeft.height)];
		else
			[bPath appendBezierPathWithRect:NSMakeRect(NSMinX(aRect) + 0.5 * lineW, NSMinY(aRect) + 0.5 * lineW, NSWidth(aRect) - topRight.width, NSHeight(aRect) - bottomLeft.height)];
		[[NSColor colorWithDeviceWhite:0.333 alpha:1.0] setStroke];
		[bPath setLineWidth:lineW];
		[bPath stroke];
		free(points);
#else
		PSsetlinejoin(0);
		PSsetlinewidth(2.0);
		PSsetgray(0.167);
		PSmoveto(aRect.origin.x + bottomLeft.width,aRect.origin.y + 1.0);
		PSrlineto(aRect.size.width - 2.0,0.0);
		PSrlineto(0.0,aRect.size.height - 2.0);
		PSstroke();
		PSsetlinewidth(1.0);
		PSsetgray(0.333);
		PSrectstroke(aRect.origin.x + 0.5,aRect.origin.y + 1.5,aRect.size.width - 2.0,aRect.size.height - 2.0);
#endif
		break;
	case NSImageFrameGroove:
		lineW = bottomLeft.width;
#ifdef __APPLE__
		[bPath appendBezierPathWithRect:NSMakeRect(NSMinX(aRect) + 0.5 * lineW, NSMinY(aRect) + 0.5 * lineW, NSWidth(aRect) - lineW, NSHeight(aRect) - lineW)];
		[bPath setLineJoinStyle:NSMiterLineJoinStyle];
		[bPath setLineWidth:lineW];
		[[NSColor colorWithDeviceWhite:0.333 alpha:1.0] setStroke];
		[bPath stroke];
		lineW = 0.667 * bottomLeft.width;
		if (NO == isFlipped)
			[bPath appendBezierPathWithRect:NSMakeRect(NSMinX(aRect) + bottomLeft.width - 0.5 * lineW, NSMinY(aRect) + 0.5 * lineW, NSWidth(aRect) - bottomLeft.width, NSHeight(aRect) - bottomLeft.height)];
		else
			[bPath appendBezierPathWithRect:NSMakeRect(NSMinX(aRect) + bottomLeft.width - 0.5 * lineW, NSMinY(aRect) + topRight.height - 0.5 * lineW, NSWidth(aRect) - bottomLeft.width, NSHeight(aRect) - topRight.height)];
		[bPath setLineWidth:lineW];
		[[NSColor colorWithDeviceWhite:0.835 alpha:1.0] setStroke];
		[bPath stroke];
#else
		PSsetlinejoin(0);
		PSsetgray(0.333);	// 0.42 //
		PSsetlinewidth(bottomLeft.width);
		PSrectstroke(aRect.origin.x + 0.5 * bottomLeft.width,aRect.origin.y + 0.5 * bottomLeft.height,aRect.size.width - bottomLeft.width,aRect.size.height - bottomLeft.height);
		PSsetgray(0.835);	// 0.916 //
		PSsetlinewidth(2.0);
		PSrectstroke (aRect.origin.x + 2.0,aRect.origin.y + 1.0,aRect.size.width - 3.0,aRect.size.height - 3.0);
#endif
		break;
#ifdef __APPLE__
	case NEXTSTEPImageFrameGrayBezel:	case NSImageFrameButton: // gray0.667を基準 //
		points = (NSPoint *)malloc(4 * sizeof(NSPoint));
		if (NO == isFlipped) {
			*points = NSMakePoint(NSMinX(aRect),NSMinY(aRect));
			*(points + 1) = NSMakePoint(NSMinX(aRect),NSMaxY(aRect));
			*(points + 2) = NSMakePoint(NSMinX(aRect) + bottomLeft.width,NSMaxY(aRect) - topRight.height);
			*(points + 3) = NSMakePoint(NSMinX(aRect) + bottomLeft.width,NSMinY(aRect) + bottomLeft.height);
		}
		else {
			*points = NSMakePoint(NSMinX(aRect),NSHeight(aRect) - NSMinY(aRect));
			*(points + 1) = NSMakePoint(NSMinX(aRect),NSMinY(aRect));
			*(points + 2) = NSMakePoint(NSMinX(aRect) + bottomLeft.width,NSMinY(aRect) + topRight.height);
			*(points + 3) = NSMakePoint(NSMinX(aRect) + bottomLeft.width,NSMaxY(aRect) - bottomLeft.height);
		}
		[bPath appendBezierPathWithPoints:points count:4];
		if (NSImageFrameButton == imageFrameStyle)
			[[NSColor colorWithDeviceWhite:0.835 alpha:1.0] setFill];
		else
			[[NSColor colorWithDeviceWhite:0.333 alpha:1.0] setFill];
		[bPath closePath];
		[bPath fill];
		if (NO == isFlipped) {
			*points = NSMakePoint(NSMinX(aRect),NSMaxY(aRect));
			*(points + 1) = NSMakePoint(NSMaxX(aRect),NSMaxY(aRect));
			*(points + 2) = NSMakePoint(NSMaxX(aRect) - topRight.width,NSMaxY(aRect) - topRight.height);
			*(points + 3) = NSMakePoint(NSMinX(aRect) + bottomLeft.width,NSMaxY(aRect) - topRight.height);
		}
		else {
			*points = NSMakePoint(aRect.origin.x,aRect.origin.y);
			*(points + 1) = NSMakePoint(NSMaxX(aRect),NSMinY(aRect));
			*(points + 2) = NSMakePoint(NSMaxX(aRect) - topRight.width,NSMinY(aRect) + topRight.height);
			*(points + 3) = NSMakePoint(NSMinX(aRect) + bottomLeft.width,NSMinY(aRect) + topRight.height);
		}
		bPath = [NSBezierPath bezierPath];
		[bPath appendBezierPathWithPoints:points count:4];
		if (NSImageFrameButton == imageFrameStyle)
			[[NSColor colorWithDeviceWhite:0.916 alpha:1.0] setFill];
		else
			[[NSColor colorWithDeviceWhite:0.167 alpha:1.0] setFill];
		[bPath closePath];
		[bPath fill];
		if (NO == isFlipped) {
			*points = NSMakePoint(aRect.origin.x + aRect.size.width,aRect.origin.y + aRect.size.height);
			*(points + 1) = NSMakePoint(NSMaxX(aRect),NSMinY(aRect));
			*(points + 2) = NSMakePoint(NSMaxX(aRect) - topRight.width, NSMinY(aRect) + bottomLeft.height);
			*(points + 3) = NSMakePoint(NSMaxX(aRect) - topRight.width, NSMaxY(aRect) - topRight.height);
		}
		else {
			*points = NSMakePoint(aRect.origin.x + aRect.size.width,aRect.origin.y);
			*(points + 1) = NSMakePoint(NSMaxX(aRect),NSMaxY(aRect));
			*(points + 2) = NSMakePoint(NSMaxX(aRect) - topRight.width,NSMaxY(aRect) - bottomLeft.height);
			*(points + 3) = NSMakePoint(NSMaxX(aRect) - topRight.width,NSMinY(aRect) + topRight.height);
		}
		bPath = [NSBezierPath bezierPath];
		[bPath appendBezierPathWithPoints:points count:4];
		if (NSImageFrameButton == imageFrameStyle)
			[[NSColor colorWithDeviceWhite:0.333 alpha:1.0] setFill];
		else
			[[NSColor colorWithDeviceWhite:0.835 alpha:1.0] setFill];
		[bPath closePath];
		[bPath fill];
		if (NO == isFlipped) {
			*points = NSMakePoint(aRect.origin.x + aRect.size.width,aRect.origin.y);
			*(points + 1) = NSMakePoint(NSMinX(aRect),NSMinY(aRect));
			*(points + 2) = NSMakePoint(NSMinX(aRect) + bottomLeft.width, NSMinY(aRect) + bottomLeft.height);
			*(points + 3) = NSMakePoint(NSMaxX(aRect) - topRight.width, NSMinY(aRect) + bottomLeft.height);
		}
		else {
			*points = NSMakePoint(NSMaxX(aRect),NSMaxY(aRect));
			*(points + 1) = NSMakePoint(NSMinX(aRect),NSMaxY(aRect));
			*(points + 2) = NSMakePoint(NSMinX(aRect) + bottomLeft.width, NSMaxY(aRect) - bottomLeft.height);
			*(points + 3) = NSMakePoint(NSMaxX(aRect) - topRight.width, NSMaxY(aRect) - bottomLeft.height);
		}
		bPath = [NSBezierPath bezierPath];
		[bPath appendBezierPathWithPoints:points count:4];
		if (NSImageFrameButton == imageFrameStyle)
			[[NSColor colorWithDeviceWhite:0.167 alpha:1.0] setFill];
		else
			[[NSColor colorWithDeviceWhite:0.916 alpha:1.0] setFill];
		[bPath closePath];
		[bPath fill];
		free(points);
		break;
	case NSImageFrameGrayBezel:
		if (NO == useBackgroundColor)
			thisBackgroundColor = [NSColor colorWithCalibratedHue:0.0 saturation:0.0 brightness:0.955 alpha:1.0];
		else {
			if ((YES == [[backgroundColor colorSpaceName] isEqualToString:NSDeviceRGBColorSpace]) || (YES == [[backgroundColor colorSpaceName] isEqualToString:NSCalibratedRGBColorSpace]))
				thisBackgroundColor = backgroundColor;
			else
				thisBackgroundColor = [NSColor colorWithCalibratedHue:0.0 saturation:0.0 brightness:0.955 alpha:1.0];
		}
		[thisBackgroundColor getHue:&hue saturation:&saturation brightness:&bright alpha:&alpha];
		if (YES == useBackgroundColor) {
			[thisBackgroundColor set];
			NSRectFill(NSMakeRect(NSMinX(aRect) + bottomLeft.width,NSMinY(aRect) + bottomLeft.height,NSWidth(aRect) - bottomLeft.width - topRight.width,NSHeight(aRect) - bottomLeft.height - topRight.height));
		}

		points = (NSPoint *)malloc(2 * sizeof(NSPoint));
		lineW = 0.4 * bottomLeft.width;
		r = 0.5 * lineW + 3.0; // 3.0くらいのoffsetがないと内側が直角になってしまう。 //
		for (i = 0; i < 2; i++) {
			if (0 == i)
				lineW = 0.4 * bottomLeft.width;
			else
				lineW = 0.01;
			*points = NSMakePoint(NSMinX(aRect) + 0.5 * lineW,NSMinY(aRect) + 0.5 * lineW + r);
			bPath = [NSBezierPath bezierPath];
			[bPath moveToPoint:*points];
			*points = NSMakePoint(NSMinX(aRect) + 0.5 * lineW,NSMaxY(aRect) - 0.5 * lineW);
			*(points + 1) = NSMakePoint(NSMaxX(aRect) - 0.5 * lineW,NSMaxY(aRect) - 0.5 * lineW);
			[bPath appendBezierPathWithArcFromPoint:*points toPoint:*(points  + 1) radius:r];
			*points = *(points + 1);
			*(points + 1) = NSMakePoint(NSMaxX(aRect) - 0.5 * lineW,NSMinY(aRect) + 0.5 * lineW);
			[bPath appendBezierPathWithArcFromPoint:*points toPoint:*(points + 1) radius:r];
			*points = *(points + 1);
			*(points + 1) = NSMakePoint(NSMinX(aRect) + 0.5 * lineW,NSMinY(aRect) + 0.5 * lineW);
			[bPath appendBezierPathWithArcFromPoint:*points toPoint:*(points  + 1) radius:r];
			*points = *(points + 1);
			*(points + 1) = NSMakePoint(NSMinX(aRect) + 0.5 * lineW,NSMaxY(aRect) - 0.5 * lineW);
			[bPath appendBezierPathWithArcFromPoint:*points toPoint:*(points + 1) radius:r];
			if (0 == i)
				[[NSColor whiteColor] setStroke];
			else
				[[NSColor colorWithCalibratedWhite:0.0 alpha:1.0] setStroke];
			[bPath setLineWidth:lineW];
			[bPath stroke];
		}
		lineW = 0.4 * bottomLeft.width;

		bPath = [NSBezierPath bezierPath];
		lineW2 = 0.5;
		j = (NSUInteger)((bottomLeft.width - lineW) / lineW2);
		lineW2 = 0.5 * 0.5 * (CGFloat)j; // 0.5の太さがj個分の半分の太さ。四隅の空白を埋めるため。 //
		[bPath appendBezierPathWithRect:NSMakeRect(NSMinX(aRect) + lineW + 0.5 * lineW2,NSMinY(aRect) + lineW + 0.5 * lineW2,NSWidth(aRect) - 2.0 * (lineW + 0.5 * lineW2),NSHeight(aRect) - 2.0 * (lineW + 0.5 * lineW2))];
		[[NSColor whiteColor] setStroke];
		[bPath setLineWidth:lineW2];
		[bPath stroke];

		lineW2 = 0.5;
		for (i = 0; i < j; i++) {
			grayScale0 = bright * (0.576 + 0.424 * (CGFloat)i / (CGFloat)j);
			grayScale1 = bright * (0.314 + 0.686 * (CGFloat)i / (CGFloat)j);
			grayScale2 = bright * (0.838 + 0.162 * (CGFloat)i / (CGFloat)j);
			bPath = [NSBezierPath bezierPath];
			*points = NSMakePoint(NSMinX(aRect) + lineW + lineW2 * ((CGFloat)i + 0.5),NSMinY(aRect) + lineW + lineW2 * ((float)i + 0.5));
			points->y += r;
			[bPath moveToPoint:*points];
			*points = NSMakePoint(points->x,NSMaxY(aRect) - lineW - lineW2 * ((CGFloat)i + 0.5));
			*(points + 1) = NSMakePoint(NSMaxX(aRect) - lineW - lineW2 * ((CGFloat)i + 0.5),points->y);
			[bPath appendBezierPathWithArcFromPoint:*points toPoint:*(points + 1) radius:r];
			[[NSColor colorWithDeviceHue:hue saturation:saturation brightness:grayScale0 alpha:alpha] set];
			[bPath setLineWidth:lineW2];
			[bPath stroke];
			bPath = [NSBezierPath bezierPath];
			points->x += r;
			[bPath moveToPoint:*points];
			*points = *(points + 1);
			*(points + 1) = NSMakePoint(points->x,NSMinY(aRect) + lineW + lineW2 * ((float)i + 0.5));
			[bPath appendBezierPathWithArcFromPoint:*points toPoint:*(points + 1) radius:r];
			if (YES == isFlipped)
				[[NSColor colorWithDeviceHue:hue saturation:saturation brightness:grayScale2 alpha:alpha] setStroke];
			else
				[[NSColor colorWithDeviceHue:hue saturation:saturation brightness:grayScale1 alpha:alpha] setStroke];
			[bPath setLineWidth:lineW2];
			[bPath stroke];
			bPath = [NSBezierPath bezierPath];
			points->y -= r;
			[bPath moveToPoint:*points];
			*points = *(points + 1);
			*(points + 1) = NSMakePoint(NSMinX(aRect) + lineW + lineW2 * ((float)i + 0.5),points->y);
			[bPath appendBezierPathWithArcFromPoint:*points toPoint:*(points + 1) radius:r];
			[[NSColor colorWithDeviceHue:hue saturation:saturation brightness:grayScale0 alpha:alpha] setStroke];
			[bPath setLineWidth:lineW2];
			[bPath stroke];
			bPath = [NSBezierPath bezierPath];
			points->x -= r;
			[bPath moveToPoint:*points];
			*points = *(points + 1);
			*(points + 1) = NSMakePoint(points->x,NSMaxY(aRect) - lineW - lineW2 * ((CGFloat)i + 0.5));
			[bPath appendBezierPathWithArcFromPoint:*points toPoint:*(points + 1) radius:r];
			if (YES == isFlipped)
				[[NSColor colorWithDeviceHue:hue saturation:saturation brightness:grayScale1 alpha:alpha] setStroke];
			else
				[[NSColor colorWithDeviceHue:hue saturation:saturation brightness:grayScale2 alpha:alpha] setStroke];
			[bPath setLineWidth:lineW2];
			[bPath stroke];
		}
		free(points);
		break;
#else
	case NSImageFrameButton:  case NSImageFrameGrayBezel: // gray0.667を基準 //
		PSsetlinejoin(0);
		PSsetlinewidth(0.0);
		if (NSImageFrameButton == imageFrameStyle)
			PSsetgray(0.835);
		else
			PSsetgray(0.333);
		PSmoveto(aRect.origin.x,aRect.origin.y);
		PSrlineto(0.0,aRect.size.height);
		PSrlineto(bottomLeft.width,-1.0 * topRight.height);
		PSrlineto(0.0,-1.0 * hInside);
		PSclosepath();
		PSfill();
		if (NSImageFrameButton == imageFrameStyle)
			PSsetgray(0.916);
		else
			PSsetgray(0.167);
		PSmoveto(aRect.origin.x,aRect.origin.y + aRect.size.height);
		PSrlineto(aRect.size.width,0.0);
		PSrlineto(-1.0 * topRight.width,-1.0 * topRight.height);
		PSrlineto(-1.0 * wInside,0.0);
		PSclosepath();
		PSfill();
		if (NSImageFrameButton == imageFrameStyle)
			PSsetgray(0.333);
		else
			PSsetgray(0.835);
		PSmoveto(aRect.origin.x + aRect.size.width,aRect.origin.y + aRect.size.height);
		PSrlineto(0.0,-1.0 * aRect.size.height);
		PSrlineto(-1.0 * topRight.width,bottomLeft.height);
		PSrlineto(0.0,hInside);
		PSclosepath();
		PSfill();
		if (NSImageFrameButton == imageFrameStyle)
			PSsetgray(0.167);
		else
			PSsetgray(0.916);
		PSmoveto(aRect.origin.x + aRect.size.width,aRect.origin.y);
		PSrlineto(-1.0 * aRect.size.width,0.0);
		PSrlineto(bottomLeft.width,bottomLeft.height);
		PSrlineto(wInside,0.0);
		PSclosepath();
		PSfill();
		break;
#endif
	default:	// case NSImageFrameNone: //
		break;
	}
}
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView // override //
{
	// (YES == [self isHighlighted])となるのはマウスクリックされた瞬間だけ。highlightColorWithFrame::は常にnilでない [NSBezierPath bezierPathWithRoundedRect:rectangleRect xRadius:_rx yRadius:_ry]  //
	if ((YES == [self isEditable]) && (YES == [[controlView valueForKey:@"allowsCutCopyPaste"] boolValue]) && (YES == [NSGraphicsContext currentContextDrawingToScreen]) && (YES == [self showsFirstResponder])) {
		NSRect borderRect;
		NSBezierPath *fPath;
		NSUInteger i;
		CGFloat offset;
		NSColor *fColor;
		NSColor *foColor = [self highlightColorWithFrame:cellFrame inView:controlView];
		NSRect savedFrame = [controlView frame];
		CGFloat lineWidth = 1.0;

		[controlView setFrame:NSInsetRect(savedFrame,-4.0,-4.0)];
		for (i = 0; i < 3; i++) { // 何故かわからないけれど3ポイントを超えると消え残ってしまう。3ポイントの中に1.0ポイントの線を引くということは3本に決まってしまう。controlViewの広げる分も大きめに取らないと不安定になる。 //
			offset = 0.5 + (CGFloat)i * lineWidth;
			borderRect = NSInsetRect(cellFrame, -1.0 * offset, -1.0 * offset);
			fPath = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(NSMinX(borderRect) + 4.0,NSMinY(borderRect) + 4.0, NSWidth(borderRect),NSHeight(borderRect)) xRadius:6.0 yRadius:6.0];
			fColor = [foColor colorWithAlphaComponent:0.33333 * (CGFloat)(3 - i)];
			[fColor setStroke];
			[fPath setLineWidth:lineWidth];
			[fPath setLineCapStyle:NSButtLineCapStyle];
			[fPath setLineJoinStyle:NSBevelLineJoinStyle];
			[fPath stroke];
		}
		[controlView setFrame:savedFrame];
	}
	switch (imageFrameStyle) {
	case NSImageFramePhoto:
		bottomLeft = NSMakeSize(1.0,2.0); // 線の太さ,線の太さ+影の太さ //
		topRight = NSMakeSize(2.0,1.0); // 線の太さ+影の太さ,線の太さ //
		break;
	case NSImageFrameGroove:
		bottomLeft = NSMakeSize(3.0,3.0);
		topRight = NSMakeSize(3.0,3.0);
		break;
#ifdef __APPLE__
	case NEXTSTEPImageFrameGrayBezel: case NSImageFrameButton:
		bottomLeft = NSMakeSize(2.0,2.0);
		topRight = NSMakeSize(2.0,2.0);
		break;
	case NSImageFrameGrayBezel:
		bottomLeft = NSMakeSize(6.0,6.0);
		topRight = NSMakeSize(6.0,6.0);
		break;
#else
	case NSImageFrameGrayBezel: case NSImageFrameButton:
		bottomLeft = NSMakeSize(2.0,2.0);
		topRight = NSMakeSize(2.0,2.0);
		break;
#endif
	default:	// case NSImageFrameNone: //
		bottomLeft = NSZeroSize;
		topRight = NSZeroSize;
		break;
	}
	[self drawFrame:cellFrame];
#ifdef __APPLE__
	if ((YES == useBackgroundColor) && (NSImageFrameGrayBezel != imageFrameStyle)) {
		[backgroundColor setFill];
		NSRectFill(NSMakeRect(NSMinX(cellFrame) + bottomLeft.width,NSMinY(cellFrame) + bottomLeft.height,NSWidth(cellFrame) - bottomLeft.width - topRight.width,NSHeight(cellFrame) - bottomLeft.height - topRight.height));
#else
	if (YES == useBackgroundColor) {
		[backgroundColor set];
		NSRectFill(NSMakeRect(aRect.origin.x + bottomLeft.width,aRect.origin.y + bottomLeft.height,aRect.size.width - bottomLeft.width - topRight.width,aRect.size.height - bottomLeft.height - topRight.height));
		PSsetalpha(1.0);
#endif
	}
	[self drawInteriorWithFrame:cellFrame inView:controlView];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	[super initWithCoder:aDecoder];
	_imageReps = [[aDecoder decodeObjectForKey:ASImageViewImageRepsKey] retain];
	currentPage = [aDecoder decodeIntegerForKey:ASImageViewCurrentPageKey];
	imageScaling = [aDecoder decodeIntegerForKey:ASImageViewImageScalingKey];
	imageFrameStyle = [aDecoder decodeIntegerForKey:ASImageViewImageFrameStyleKey];
	imageAlignment = [aDecoder decodeIntegerForKey:ASImageViewImageAlignmentKey];
	originalSize = [aDecoder decodeSizeForKey:@"originalSize"];
	backgroundColor = [[aDecoder decodeObjectForKey:ASImageViewBackgroundColorKey] retain];
	useBackgroundColor = [aDecoder decodeBoolForKey:ASImageViewUseBackgroundColorKey];
	compositingOperation = [aDecoder decodeIntegerForKey:ASImageViewCompositingOperationKey];
	isFlipped = [aDecoder decodeBoolForKey:@"isFlipped"];
	delta = [aDecoder decodeDoubleForKey:ASImageViewFractionKey];
	canUseFraction = [aDecoder decodeBoolForKey:ASImageViewCanUseFractionKey];
	bottomLeft = [aDecoder decodeSizeForKey:@"bottomLeft"];
	topRight = [aDecoder decodeSizeForKey:@"topRight"];
	if ((nil != _imageReps) && (YES == [[_imageReps objectAtIndex:0] isKindOfClass:[NSPDFImageRep class]]))
		[(NSPDFImageRep *)[_imageReps objectAtIndex:0] setCurrentPage:currentPage]; // やらなくても良いが念のためフェッチしておく。 //
	return self;
}
- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[super encodeWithCoder:aCoder];
	[aCoder encodeObject:_imageReps forKey:ASImageViewImageRepsKey];
	[aCoder encodeInteger:currentPage forKey:ASImageViewCurrentPageKey];
	[aCoder encodeInteger:imageScaling forKey:ASImageViewImageScalingKey];
	[aCoder encodeInteger:imageFrameStyle forKey:ASImageViewImageFrameStyleKey];
	[aCoder encodeInteger:imageAlignment forKey:ASImageViewImageAlignmentKey];
	[aCoder encodeSize:originalSize forKey:@"originalSize"];
	[aCoder encodeObject:backgroundColor forKey:ASImageViewBackgroundColorKey]; 
	[aCoder encodeBool:useBackgroundColor forKey:ASImageViewUseBackgroundColorKey];
	[aCoder encodeInteger:compositingOperation forKey:ASImageViewCompositingOperationKey];
	[aCoder encodeBool:isFlipped forKey:@"isFlipped"];
	[aCoder encodeDouble:delta forKey:ASImageViewFractionKey];
	[aCoder encodeBool:canUseFraction forKey:ASImageViewCanUseFractionKey];
	[aCoder encodeSize:bottomLeft forKey:@"bottomLeft"];
	[aCoder encodeSize:topRight forKey:@"topRight"];
}

- (NSDictionary *)generalProperties
{
	NSImageRep *imageRep;
	if (nil != (imageRep = [self imageRep])) {
		if (YES == [imageRep isKindOfClass:[NSBitmapImageRep class]]) {
			// NSImageCompressionMethod:NSNumber(CGFloat),NSImageCompressionFactor:NSNumber(CGFloat),NSImageDitherTransparency:NSNumber(bool),NSImageRGBColorTable:NSData,NSImageInterlaced:NSNumber(bool),NSImageColorSyncProfileData:NSData,NSImageFrameCount:NSNumber(),NSImageCurrentFrame:NSNumber(0 base),NSImageCurrentFrameDuration:NSNumber(CGFloat),NSImageLoopCount:NSNumber(integer),NSImageGamma:NSNumber(CGFloat),NSImageProgressive:NSNumber(bool),NSImageEXIFData:NSDictionary,NSImageFallbackBackgroundColor:NSColor //
			NSMutableDictionary *bitmapDic = [NSMutableDictionary dictionary];
			NSBitmapFormat bitmapFormat = [(NSBitmapImageRep *)imageRep bitmapFormat];
			NSSize bSize = [imageRep size];
			NSInteger pixelsWide = [imageRep pixelsWide];
			NSInteger pixelsHigh = [imageRep pixelsHigh];
			NSColorSpace *colorSpace = [(NSBitmapImageRep *)imageRep colorSpace];

			[bitmapDic setObject:[imageRep colorSpaceName] forKey:@"ColorSpaceName"];
			[bitmapDic setObject:[NSNumber numberWithInteger:[imageRep bitsPerSample]] forKey:@"BitsPerSample"];
			[bitmapDic setObject:NSStringFromSize(bSize) forKey:@"Size"];
			if (0.0 != bSize.width)
				[bitmapDic setObject:[NSString stringWithFormat:@"%0.0fdpi at %0.2finch",72.0 * (CGFloat)pixelsWide / bSize.width,bSize.width / 72.0] forKey:@"DPIWide"];
			if (0.0 != bSize.height)
				[bitmapDic setObject:[NSString stringWithFormat:@"%0.0fdpi at %0.2finch",72.0 * (CGFloat)pixelsHigh / bSize.height,bSize.height / 72.0] forKey:@"DPIHigh"];
			[bitmapDic setObject:[NSNumber numberWithInteger:pixelsWide] forKey:@"PixelsWide"];
			[bitmapDic setObject:[NSNumber numberWithInteger:pixelsHigh] forKey:@"PixelsHigh"];
			[bitmapDic setObject:(YES == [imageRep hasAlpha]) ? @"YES" : @"NO" forKey:@"HasAlpha"];
			[bitmapDic setObject:(YES == [imageRep isOpaque]) ? @"YES" : @"NO" forKey:@"IsOpaque"];
			[bitmapDic setObject:[NSNumber numberWithInteger:[(NSBitmapImageRep *)imageRep bitsPerPixel]] forKey:@"BitsPerPixel"];
			[bitmapDic setObject:[NSNumber numberWithInteger:[(NSBitmapImageRep *)imageRep bytesPerPlane]] forKey:@"BytesPerPlane"];
			[bitmapDic setObject:[NSNumber numberWithInteger:[(NSBitmapImageRep *)imageRep bytesPerRow]] forKey:@"BytesPerRow"];
			[bitmapDic setObject:(YES == [(NSBitmapImageRep *)imageRep isPlanar]) ? @"YES" : @"NO" forKey:@"IsPlanar"];
			if (YES == [(NSBitmapImageRep *)imageRep isPlanar])
				[bitmapDic setObject:[NSNumber numberWithInteger:[(NSBitmapImageRep *)imageRep numberOfPlanes]] forKey:@"NumberOfPlanes"];
			[bitmapDic setObject:[NSNumber numberWithInteger:[(NSBitmapImageRep *)imageRep samplesPerPixel]] forKey:@"SamplesPerPixel"];
			[bitmapDic setObject:(bitmapFormat & NSAlphaFirstBitmapFormat) ? @"Alpha first" : @"Alpha last" forKey:@"Format0"];
			[bitmapDic setObject:(bitmapFormat & NSAlphaNonpremultipliedBitmapFormat) ? @"Alpha nonpremultiplied" : @"Alpha premultiplied" forKey:@"Format1"];
			[bitmapDic setObject:(bitmapFormat & NSFloatingPointSamplesBitmapFormat) ? @"Floating point samples" : @"Integer samples" forKey:@"Format2"];
			[bitmapDic setObject:[colorSpace localizedName] forKey:@"ProfileName"];
			return bitmapDic;
		}
		else {
			if (YES == [imageRep isKindOfClass:[NSPDFImageRep class]]) {
				PDFDocument *pdfDoc = [[PDFDocument alloc] initWithData:[(NSPDFImageRep *)imageRep PDFRepresentation]];
				NSDictionary *attributes = (nil != pdfDoc) ? [pdfDoc documentAttributes] : nil;
				[pdfDoc release];
				return attributes; // NSDateも含まれる。 //
			}
			else {
				if (YES == [imageRep isKindOfClass:[ASWebImageRep class]]) {
					id obj;
					NSMutableDictionary *svgDic = [NSMutableDictionary dictionary];
					if (nil != (obj = [imageRep valueForKey:ASWebViewDescKey]))
						[svgDic setObject:obj forKey:@"Description"];
					if (nil != (obj = [imageRep valueForKey:ASWebViewEncodingKey]))
						[svgDic setObject:obj forKey:@"Encoding"];
					if (nil != (obj = [imageRep valueForKey:ASWebViewTitleKey]))
						[svgDic setObject:obj forKey:@"Title"];
					return svgDic;
				}
				else
					return nil;
			}
		}
	}
	else
		return nil;
}
- (NSDictionary *)metadataFromSource:(id)source
{
	if ((nil != source) && (nil != [self imageRep]) && (YES == [[self imageRep] isKindOfClass:[NSBitmapImageRep class]])) {
		CGImageSourceRef cgImage = NULL;
		if (YES == [source isKindOfClass:[NSData class]])
			cgImage = CGImageSourceCreateWithData((CFDataRef)source, NULL);
		else {
			if (YES == [source isKindOfClass:[NSURL class]])
				cgImage = CGImageSourceCreateWithURL((CFURLRef)source, NULL);
		}
		if (cgImage) {
			NSDictionary *metadata = (NSDictionary *)CGImageSourceCopyPropertiesAtIndex(cgImage, 0, nil);
			CFRelease(cgImage);
			return [metadata autorelease];
		}
		else
			return nil;
	}
	else
		return nil;
}
- (NSDictionary *)CGImagePropertyInMetadata:(NSDictionary *)metadata key:(NSString *)property {
		return ((nil != metadata) && (nil != property)) ? [NSDictionary dictionaryWithDictionary:[metadata objectForKey:property]] : nil;
}
	
@end
