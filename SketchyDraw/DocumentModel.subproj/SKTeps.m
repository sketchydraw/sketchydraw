//
//  SKTeps.m
//  Sketch
//
//  Created by 佐藤 昭 on Tue Dec 02 2003.
//  Copyright (c) 2003 SatoAkira. All rights reserved.
//

#import "SKTeps.h"
#import "SKTGraphicView.h" // for ISFLIPPED //
#import "SKTFoundationExtras.h" // SatoAkira add.for svg...() //


@implementation SKTeps

- (void)dealloc {
	[_EPSImageReps release];
	[super dealloc];
}

- (NSSize)setImageRepresentation:(NSData *)aData type:(NSString *)aString
{
	NSArray *tempImageReps;
	if (YES == [aString isEqualToString:@"com.adobe.postscript"]) {
		NSPasteboardItem *pasteboardItem = [[NSPasteboardItem alloc] init];
		if (YES == [pasteboardItem setData:aData forType:@"com.adobe.postscript"]) {
			NSPasteboard *pboard = [NSPasteboard generalPasteboard];
			[pboard clearContents];
			[pboard writeObjects:[NSArray arrayWithObject:pasteboardItem]];
			tempImageReps = [NSImageRep imageRepsWithPasteboard:pboard];
			NSLog(@"count=%lu",[tempImageReps count]);
		}
		else
			tempImageReps = nil;
		[pasteboardItem release];
	}
	else
		tempImageReps = (nil != aData) ? [NSArray arrayWithObject:[NSEPSImageRep imageRepWithData:aData]] : nil;
	if ((nil != aData) && (nil != tempImageReps)) {
		[_EPSImageReps release];
		[_imageType release];
		[_imageRepresentation release];
		_EPSImageReps = [[NSArray allocWithZone:[self zone]] initWithArray:tempImageReps];
		_currentPage = 1;
		_EPSImageRep = [_EPSImageReps objectAtIndex:_currentPage - 1];
		_imageRepresentation = [[NSData allocWithZone:[self zone]] initWithData:aData];
		_imageType = [[NSString allocWithZone:[self zone]] initWithString:aString];
		originalSize = [_EPSImageRep boundingBox].size;
		return originalSize;
	}
	else {
		NSString *message = [NSString stringWithFormat:NSLocalizedString(@"'%@' image is not created. Please try again.",@""),aString];

		originalSize = NSZeroSize;
		_currentPage = 1;
		[_imageType release];
		[_imageRepresentation release];
		[_EPSImageReps release];
		_imageRepresentation = nil;
		_imageType = [[NSString alloc] initWithString:aString];
		_EPSImageReps = [[NSArray allocWithZone:[self zone]] initWithArray:[NSArray array]];
		_EPSImageRep = nil;
		NSBeginAlertSheet(NSStringFromClass([self class]),nil,nil,nil,nil,self,NULL,NULL,NULL,message,nil); // windowを指定できないのでnil //
		return NSZeroSize;
	}
}

- (void)drawContentsInView:(NSView *)view isBeingCreateOrEdited:(BOOL)isBeingCreatedOrEditing
// ここのdrawContentsInView:の中で_imageRepをいじることはできない。 //
{
	if (nil != _EPSImageRep) {
		NSRect bounds = [self bounds];
		double rotateAngle = [self rotateAngle];
		NSRect fillRect = NSMakeRect(-0.5 * NSWidth(bounds),-0.5 * NSHeight(bounds),NSWidth(bounds),NSHeight(bounds));
		NSAffineTransform *transform = [NSAffineTransform transform];
		NSGraphicsContext *currentContext = [NSGraphicsContext currentContext];
		CGFloat scaleX = (YES == _isFlippedHorizontally) ? -1.0: 1.0;
#ifdef ISFLIPPED
		CGFloat scaleY = (YES == _isFlippedVertically) ? 1.0 : -1.0;
#else
		CGFloat scaleY = (YES == [self flippedVertically]) ? -1.0 : 1.0;
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
				[fillTransform scaleXBy:1.0 yBy:-1.0];
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
		if ((nil != view) && (YES == [currentContext isDrawingToScreen])) { // addRepresentationがまともに動作しているので[currentContext imageInterpolation]によって判断しなくても良い。 //
			if (nil == _cachedImage) {
				if (nil != (_cachedImage = [[NSImage allocWithZone:[self zone]] initWithSize:fillRect.size])) {
					[_cachedImage addRepresentation:_EPSImageRep];
					[_cachedImage setScalesWhenResized:YES];
				}
			}
			if (nil != _cachedImage)
				[_cachedImage drawAtPoint:fillRect.origin fromRect:NSMakeRect(0.0,0.0,NSWidth(fillRect),NSHeight(fillRect)) operation:NSCompositeSourceOver fraction:1.0];
		}
		else {
			if (NO == [_EPSImageRep drawInRect:fillRect fromRect:NSMakeRect(0.0,0.0,originalSize.width,originalSize.height) operation:NSCompositeSourceOver fraction:1.0 respectFlipped:NO hints:[NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:NSImageInterpolationHigh] forKey:NSImageHintInterpolation]])
				NSLog(@"SKTeps: draw fail.");
		}
		if (YES == shadowFlag)
			[currentContext restoreGraphicsState];
	}
}

- (void)setCurrentPage:(NSNumber *)pageNumber
// 1-based. //
{
	NSInteger page;
	if ((0 < [pageNumber integerValue]) && ((NSInteger)[_EPSImageReps count] >= [pageNumber integerValue]))
		page = [pageNumber integerValue];
	else
		page = (0 >= [pageNumber integerValue]) ? 1 : [_EPSImageReps count];
	if (_currentPage != page) {
		_currentPage = page;
		_EPSImageRep = [_EPSImageReps objectAtIndex:_currentPage - 1];
		[_cachedImage release];
		_cachedImage = nil;
	}
}
- (NSUInteger)pageCount {
	return [_EPSImageReps count];
}

- (NSArray *)svgXMLElements:(NSRect)aRect name:(NSString *)unique_ID
// EPSを解析してSVGのelementにするのが正当であるが、現在のところ不可能なので、5.0 * 72.0 = 360.0dpi でラスター化する。 //
{
	NSRect bounds = [self bounds];

	if ((0.0 < NSWidth(bounds)) || (0.0 < NSHeight(bounds))) {
		NSMutableArray *elements = [NSMutableArray arrayWithObject:[NSXMLNode commentWithStringValue:NSStringFromClass([self class])]];
		BOOL shadowFlag = (0.1 > [self shadowBlurRadiusValue]) ? NO : YES;
		NSArray *defsAndRect = [self svgDefsAndRect:unique_ID allGraphics:aRect bounds:bounds transform:nil];
		if (0 < [defsAndRect count])
			[elements addObjectsFromArray:defsAndRect];
		CGFloat translateX = NSMidX(bounds) - NSMinX(aRect);
		CGFloat translateY = NSMidY(bounds) - NSMinY(aRect);
		NSImage *anImage = [[NSImage allocWithZone:[self zone]] initWithSize:NSMakeSize(NSWidth(bounds) * 5.0, NSHeight(bounds) * 5.0)];
	
		[anImage setScalesWhenResized:YES];
		[anImage addRepresentation:_EPSImageRep];
		NSBitmapImageRep *anImageImageRep = [NSBitmapImageRep imageRepWithData:[anImage TIFFRepresentation]];
		[anImageImageRep setSize:bounds.size];
		NSString *base64Str = (nil != anImageImageRep) ? imageRepToBase64(anImageImageRep) : nil;
	
		[anImage release];
		if (nil != base64Str) {
			NSXMLElement *element = [NSXMLElement elementWithName:@"image"];
			NSMutableArray *attributes = [NSMutableArray arrayWithObjects:svgTransformNode(translateX,translateY,[self rotateAngle],1.0,1.0),[NSXMLNode attributeWithName:@"x" stringValue:[NSString stringWithFormat:@"%g%@",-0.5 * NSWidth(bounds),svgUnit]],[NSXMLNode attributeWithName:@"y" stringValue:[NSString stringWithFormat:@"%g%@",-0.5 * NSHeight(bounds),svgUnit]],[NSXMLNode attributeWithName:@"width" stringValue:[NSString stringWithFormat:@"%g%@",NSWidth(bounds),svgUnit]],[NSXMLNode attributeWithName:@"height" stringValue:[NSString stringWithFormat:@"%g%@",NSHeight(bounds),svgUnit]],[NSXMLNode attributeWithName:@"preserveAspectRatio" stringValue:@"none"],[NSXMLNode attributeWithName:@"xlink:href" stringValue:[NSString stringWithFormat:@"data:%@",base64Str]],nil]; // WebKit,OPera,BatikなどではpreserveAspectRatio="none"がデフォルトでない。 //

			if ((YES == shadowFlag) && (NO == [self isDrawingFill]))
				[attributes addObject:[NSXMLNode attributeWithName:@"filter" stringValue:[NSString stringWithFormat:@"url(#shadow_%@)",unique_ID]]];
			[element setAttributes:attributes];
			[elements addObject:element];
			return elements;
		}
		else
			return nil;
	}
	else
		return nil;
}

@end
