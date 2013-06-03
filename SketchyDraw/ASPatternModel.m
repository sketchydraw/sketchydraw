//
//  ASPatternModel.m
//  SketchyDraw
//
//  Created by 佐藤 昭 on  平成19/10/20.
//  Copyright 2007 SatoAkira. All rights reserved.
//

#import "ASPatternModel.h"


@implementation ASPatternModel

- (id)init
{
	self = [super init];
	transform = nil;
	clipPath = nil;
	patternImageRep = nil;
	colorSpace = [[NSColorSpace genericRGBColorSpace] retain];
	return self;
}
- (void)dealloc
{
	[transform release];
	[clipPath release];
	[patternImageRep release];
	[cachedImage release];
	[colorSpace release];
	[super dealloc];
}
- (void)setPatternImageRep:(NSImageRep *)imageRep
{
	[patternImageRep release];
	patternImageRep = [imageRep copyWithZone:[self zone]];
	if (YES == [imageRep isKindOfClass:[NSBitmapImageRep class]]) {
		[(NSBitmapImageRep *)patternImageRep setProperty:NSImageColorSyncProfileData withValue:[colorSpace ICCProfileData]];
	}
	[cachedImage release];
	cachedImage = [[NSImage allocWithZone:[self zone]] initWithSize:[patternImageRep size]];
	[cachedImage addRepresentation:patternImageRep];
}
- (void)setBounds:(NSRect)aRect clip:(NSBezierPath *)aPath transform:(NSAffineTransform *)aTrans colorSpace:(NSColorSpace *)aSpace winding:(NSWindingRule)aRule
{
	bounds = aRect;
	windingRule = aRule;
	if ((nil != aSpace) && (NO == [[aSpace localizedName] isEqualToString:[colorSpace localizedName]])) {
		NSData *profileData = [aSpace ICCProfileData];
		[colorSpace release];
		colorSpace = [[NSColorSpace allocWithZone:[self zone]] initWithICCProfileData:profileData];
		if ((nil != patternImageRep) && (YES == [patternImageRep isKindOfClass:[NSBitmapImageRep class]])) {
			[(NSBitmapImageRep *)patternImageRep setProperty:NSImageColorSyncProfileData withValue:[colorSpace ICCProfileData]];
			[cachedImage release];
			cachedImage = [[NSImage allocWithZone:[self zone]] initWithSize:[patternImageRep size]];
			[cachedImage addRepresentation:patternImageRep];
		}
	}
	if ((nil != transform) || (nil != aTrans)) {
		if (nil != aTrans) {
			[transform release];
			transform = [aTrans copyWithZone:[self zone]];
		}
		else {
			[transform release];
			transform = nil;
		}
	}
	if (nil != aPath) {
		[clipPath release];
		clipPath = [aPath copyWithZone:[self zone]];
	}
}
- (void)fill
{
	if (nil != patternImageRep) {
		double x,y;
		NSUInteger i,j;
		NSGraphicsContext *cC = [NSGraphicsContext currentContext];
		NSSize imageSize = [patternImageRep size];
		NSUInteger hCount = (NSUInteger)(NSWidth(bounds) / imageSize.width) + 1;
		NSUInteger vCount = (NSUInteger)(NSHeight(bounds) / imageSize.height) + 1;
		double dx = imageSize.width;
		double dy = imageSize.height;
		NSAffineTransform *localTransform = [NSAffineTransform transform];

		[cC saveGraphicsState];
		if (nil != transform)
			[transform concat];
		if (nil != clipPath) {
			/* NSBezierPath *path = [NSBezierPath bezierPath];
			[path appendBezierPath:clipPath];
			[path appendBezierPathWithOvalInRect:NSMakeRect(-0.5 * NSWidth(bounds) + 10.0,-0.5 * NSHeight(bounds) + 10.0,NSWidth(bounds) - 20.0,NSHeight(bounds) - 20.0)];
			[path setWindingRule:NSEvenOddWindingRule];
			[path addClip]; // この方法でstrokeの方もできる。 // */
			[clipPath setWindingRule:windingRule];
			[clipPath addClip];
		}
		[localTransform scaleXBy:1.0 yBy:-1.0]; // flipped //
		[localTransform concat];
		if ((nil != cachedImage) && (YES == [cC isDrawingToScreen]) && (NSImageInterpolationHigh != [cC imageInterpolation])) {
			NSRect fR = NSMakeRect(0.0,0.0,imageSize.width,imageSize.height);
			
			for (y = 0.5 * NSHeight(bounds) - imageSize.height,i = 0; i < vCount; i++, y-= dy) { // flipped //
				for (x = -0.5 * NSWidth(bounds),j = 0; j < hCount; j++, x+= dx)
					[cachedImage drawAtPoint:NSMakePoint(x,y) fromRect:fR operation:NSCompositeSourceOver fraction:1.0];
			}
		}
		else {
			for (y = 0.5 * NSHeight(bounds) - imageSize.height,i = 0; i < vCount; i++, y-= dy) { // flipped //
				for (x = -0.5 * NSWidth(bounds),j = 0; j < hCount; j++, x+= dx)
					[patternImageRep drawAtPoint:NSMakePoint(x,y)];
			}
		}
		[cC restoreGraphicsState];
	}
}

@end
