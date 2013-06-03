//
//  ASPointControlCell.m
//  ASPointControlPlugin
//
//  Created by 佐藤 昭 on 11/02/05.
//  Copyright 2011 SatoAkira. All rights reserved.
//

#import "ASPointControlCell.h"
#import "ASPointControl.h"


@implementation ASPointControlCell

@synthesize horizontalFlipped;
@synthesize verticalFlipped;
@synthesize drawsTickMark;
@synthesize square;
@synthesize minPoint;
@synthesize maxPoint;

+ (void)initialize {
	// Sets our class version for archiving purposes. //
    if (self == [ASPointControlCell class]) {
		[self setVersion:1];
    }
}
/* - (NSArray *)exposedBindings
 {
 NSMutableArray *tempArray = [NSMutableArray arrayWithArray:[super exposedBindings]];
 [tempArray addObject:@"mousePoint"];
 return tempArray;
 } */
+ (BOOL)prefersTrackingUntilMouseUp {
	return NO;	// trackMouse: inRect: ofView: untilMouseUp: で無限大の領域に設定していないのでNOを返す。 //
}
- (NSView *)controlView { // 頻繁に呼ばれる。 //
	return [super controlView];
}
- (id)initImageCell:(NSImage *)anImage
{
	if (nil != (self = [super initImageCell:anImage])) {
		minPoint = NSMakePoint(-1.0,-1.0);
		maxPoint = NSMakePoint(1.0,1.0);
		horizontalFlipped = verticalFlipped = NO;
		drawsTickMark = NO;
		square = NO;
	}
	return self;
}
- (void)dealloc {
	[super dealloc];
}
- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	NSRect bounds = [controlView bounds];
	NSBezierPath *path = [NSBezierPath bezierPath];
	[path moveToPoint:NSMakePoint(NSMaxX(bounds),NSMinY(bounds))];
	[path relativeLineToPoint:NSMakePoint(-1.0 * THICKNESS,THICKNESS)];
	[path relativeLineToPoint:NSMakePoint(0.0,NSHeight(bounds) - THICKNESS)];
	[path relativeLineToPoint:NSMakePoint(THICKNESS,-1.0 * THICKNESS)];
	[path closePath];
	[[NSColor grayColor] setFill];
	[path fill];
	path = [NSBezierPath bezierPath];
	[path moveToPoint:NSMakePoint(NSMaxX(bounds),NSMinY(bounds))];
	[path relativeLineToPoint:NSMakePoint(THICKNESS - NSWidth(bounds),0.0)];
	[path relativeLineToPoint:NSMakePoint(-1.0 * THICKNESS,THICKNESS)];
	[path relativeLineToPoint:NSMakePoint(NSWidth(bounds) - THICKNESS,0.0)];
	[path closePath];
	[[NSColor grayColor] setFill];
	[path fill];
	if (nil == [self image]) {
		NSColor *darkColor = [NSColor colorWithCalibratedHue:0.417 saturation:0.34 brightness:0.70 alpha:1.0];
		NSColor *brightColor = [NSColor colorWithCalibratedHue:0.417 saturation:0.34 brightness:1.00 alpha:1.0];
		NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:darkColor endingColor:brightColor];

		path = [NSBezierPath bezierPathWithRect:NSMakeRect(NSMinX(bounds), NSMinY(bounds) + THICKNESS, 0.5 * (NSWidth(bounds) - THICKNESS), 0.5 * (NSHeight(bounds) - THICKNESS))];
		[gradient drawInBezierPath:path angle:225.0];
		path = [NSBezierPath bezierPathWithRect:NSMakeRect(NSMidX(bounds) - 0.5 * THICKNESS, NSMidY(bounds) + 0.5 * THICKNESS, 0.5 * (NSWidth(bounds) - THICKNESS), 0.5 * (NSHeight(bounds) - THICKNESS))];
		[gradient drawInBezierPath:path angle:45.0];
		[gradient release];
		darkColor = [NSColor colorWithCalibratedHue:0.417 saturation:0.34 brightness:0.55 alpha:1.0];
		gradient = [[NSGradient alloc] initWithStartingColor:darkColor endingColor:brightColor];
		path = [NSBezierPath bezierPathWithRect:NSMakeRect(NSMinX(bounds), NSMidY(bounds) + 0.5 * THICKNESS, 0.5 * (NSWidth(bounds) - THICKNESS), 0.5 * (NSHeight(bounds) - THICKNESS))];
		[gradient drawInBezierPath:path angle:135.0];
		path = [NSBezierPath bezierPathWithRect:NSMakeRect(NSMidX(bounds) - 0.5 * THICKNESS, NSMinY(bounds) + THICKNESS, 0.5 * (NSWidth(bounds) - THICKNESS), 0.5 * (NSHeight(bounds) - THICKNESS))];
		[gradient drawInBezierPath:path angle:315.0];
		[gradient release];
	}
	else
		[[self image] drawInRect:NSMakeRect(NSMinX(cellFrame),NSMinY(cellFrame) + THICKNESS,NSWidth(cellFrame) - THICKNESS,NSHeight(cellFrame) - THICKNESS) fromRect:NSMakeRect(0.0,0.0,[[self image] size].width,[[self image] size].height) operation:NSCompositeSourceOver fraction:(YES == [self isEnabled]) ? 1.0 : 0.5];
}
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	NSRect bounds = [controlView bounds];
	CGFloat lineWidth = 1.0;
	[[NSGraphicsContext currentContext] saveGraphicsState];
	[self drawInteriorWithFrame:cellFrame inView:controlView];
	if (YES == drawsTickMark) {
		NSBezierPath *tickPath = [NSBezierPath bezierPath];
		[tickPath moveToPoint:NSMakePoint(NSMidX(bounds) - THICKNESS,NSMinY(bounds) + THICKNESS)];
		[tickPath relativeLineToPoint:NSMakePoint(0.0,NSHeight(bounds) - THICKNESS)];
		[tickPath moveToPoint:NSMakePoint(NSMinX(bounds),NSMidY(bounds) + THICKNESS)];
		[tickPath relativeLineToPoint:NSMakePoint(NSWidth(bounds) - THICKNESS,0.0)];
		[[NSColor redColor] setStroke];
		[tickPath setLineWidth:0.5];
		[tickPath stroke];
	}
	if (YES == [self isBordered]) {
		NSBezierPath *rectPath = [NSBezierPath bezierPathWithRect:NSMakeRect(0.5 * lineWidth + NSMinX(bounds),0.5 * lineWidth + NSMinY(bounds) + THICKNESS,NSWidth(bounds) - THICKNESS - lineWidth,NSHeight(bounds) - THICKNESS - lineWidth)];
		if (YES == [self isEnabled])
			[[NSColor colorWithCalibratedRed:0.184 green:0.310 blue:0.310 alpha:1.000] setStroke]; // darkslateGray //
		else
			[[NSColor grayColor] setStroke];
		[rectPath setLineWidth:lineWidth];
		[rectPath stroke];
	}
	NSPoint mousePoint = [(ASPointControl *)controlView mousePoint];
	if (YES == square) {
		double signeX = (0.0 > mousePoint.x) ? -1.0 : 1.0;
		double signeY = (0.0 > mousePoint.y) ? -1.0 : 1.0;
		mousePoint.x = sqrt(signeX * mousePoint.x);
		mousePoint.y = sqrt(signeY * mousePoint.y);
		mousePoint.x *= signeX;
		mousePoint.y *= signeY;
	}
	CGFloat x = (mousePoint.x - minPoint.x) * (NSWidth(bounds) - THICKNESS) / (maxPoint.x - minPoint.x);
	CGFloat y = (mousePoint.y - minPoint.y) * (NSHeight(bounds) - THICKNESS) / (maxPoint.y - minPoint.y) + THICKNESS;
	CGFloat dia = (NSWidth(bounds) > NSHeight(bounds)) ? 0.07 * NSHeight(bounds) : 0.07 * NSWidth(bounds);
	if (1.0 > dia) dia = 1.0;
	if (YES == horizontalFlipped) x = NSMaxX(bounds) - x - THICKNESS;
	else x += NSMinX(bounds);
	if (YES == verticalFlipped) y = NSMaxY(bounds) - y + THICKNESS;
	else y += NSMinY(bounds);
	NSBezierPath *circlePath = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(x - 0.5 * dia,y - 0.5 * dia,dia,dia)];
	if (YES == [self isEnabled])
		[[NSColor blackColor] setFill];
	else
		[[NSColor grayColor] setFill];
	[[NSColor whiteColor] setStroke];
	[circlePath setLineWidth:1.0];
	[circlePath fill];
	[circlePath stroke];
	[[NSGraphicsContext currentContext] restoreGraphicsState];
}
// Archiving methods //

- (id)initWithCoder:(NSCoder *)aDecoder
{
	[super initWithCoder:aDecoder];
	minPoint = [aDecoder decodePointForKey:@"minPointKey"];
	maxPoint = [aDecoder decodePointForKey:@"maxPointKey"];
	horizontalFlipped = [aDecoder decodeBoolForKey:@"horizontalFlippedKey"];
	verticalFlipped = [aDecoder decodeBoolForKey:@"verticalFlippedKey"];
	drawsTickMark = [aDecoder decodeBoolForKey:@"drawsTickMarkKey"];
	square = [aDecoder decodeBoolForKey:@"squareKey"];
	return self;
}
- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[super encodeWithCoder:aCoder];
	[aCoder encodePoint:minPoint forKey:@"minPointKey"];
	[aCoder encodePoint:maxPoint forKey:@"maxPointKey"];
	[aCoder encodeBool:horizontalFlipped forKey:@"horizontalFlippedKey"];
	[aCoder encodeBool:verticalFlipped forKey:@"verticalFlippedKey"];
	[aCoder encodeBool:drawsTickMark forKey:@"drawsTickMarkKey"];
	[aCoder encodeBool:square forKey:@"squareKey"];
}
- (BOOL)trackMouse:(NSEvent *)theEvent inRect:(NSRect)cellFrame ofView:(NSView *)controlView untilMouseUp:(BOOL)flag {
	return [super trackMouse:theEvent inRect:cellFrame ofView:controlView untilMouseUp:flag];
}
- (BOOL)startTrackingAt:(NSPoint)startPoint inView:(NSView *)controlView
{
	if ((YES == [self isEnabled]) && (YES == [self isEditable]) && (YES == [self isContinuous])) {
		NSRect bounds = [controlView bounds];
		double w = (YES == horizontalFlipped) ? NSMaxX(bounds) - startPoint.x - THICKNESS : startPoint.x - NSMinX(bounds);
		double h = (YES == verticalFlipped) ? NSMaxY(bounds) - startPoint.y - THICKNESS : startPoint.y - NSMinY(bounds);
		double x = w * (maxPoint.x - minPoint.x) / (NSWidth(bounds) - THICKNESS) + minPoint.x;
		double y = h * (maxPoint.y - minPoint.y) / (NSHeight(bounds) - THICKNESS) + minPoint.y;
		if (YES == square) {
			double signeX = (0.0 > x) ? -1.0 : 1.0;
			double signeY = (0.0 > y) ? -1.0 : 1.0;
			x *= x;
			y *= y;
			x *= signeX;
			y *= signeY;
		}
		if (minPoint.x > x) x = minPoint.x;
		if (maxPoint.x < x) x = maxPoint.x;
		if (minPoint.y > y) y = minPoint.y;
		if (maxPoint.y < y) y = maxPoint.y;
		[(ASPointControl *)controlView setMousePoint:NSMakePoint(x,y)];
		[(ASPointControl *)controlView writeToOutlet];
		// [self drawWithFrame:[controlView frame] inView:controlView]; は効果無し //
	}
	return ((YES == [self isEnabled]) && (YES == [self isEditable]));
}
- (BOOL)continueTracking:(NSPoint)lastPoint at:(NSPoint)currentPoint inView:(NSView *)controlView
{
	if ((YES == [self isEnabled]) && (YES == [self isEditable]) && (YES == [self isContinuous])) {
		NSRect bounds = [controlView bounds];
		double w = (YES == horizontalFlipped) ? NSMaxX(bounds) - currentPoint.x - THICKNESS : currentPoint.x - NSMinX(bounds);
		double h = (YES == verticalFlipped) ? NSMaxY(bounds) - currentPoint.y - THICKNESS : currentPoint.y - NSMinY(bounds);
		double x = w * (maxPoint.x - minPoint.x) / (NSWidth(bounds) - THICKNESS) + minPoint.x;
		double y = h * (maxPoint.y - minPoint.y) / (NSHeight(bounds) - THICKNESS) + minPoint.y;
		if (YES == square) {
			double signeX = (0.0 > x) ? -1.0 : 1.0;
			double signeY = (0.0 > y) ? -1.0 : 1.0;
			x *= x;
			y *= y;
			x *= signeX;
			y *= signeY;
		}
		if (minPoint.x > x) x = minPoint.x;
		if (maxPoint.x < x) x = maxPoint.x;
		if (minPoint.y > y) y = minPoint.y;
		if (maxPoint.y < y) y = maxPoint.y;
		[(ASPointControl *)controlView setMousePoint:NSMakePoint(x,y)];
		[(ASPointControl *)controlView writeToOutlet];
		// [self drawWithFrame:[controlView frame] inView:controlView]; は効果無し //
	}
	return ((YES == [self isEnabled]) && (YES == [self isEditable]));
}
- (void)stopTracking:(NSPoint)lastPoint at:(NSPoint)stopPoint inView:(NSView *)controlView mouseIsUp:(BOOL)flag
{
	if ((YES == [self isEnabled]) && (YES == [self isEditable])) {
		NSRect bounds = [controlView bounds];
		double w = (YES == horizontalFlipped) ? NSMaxX(bounds) - stopPoint.x - THICKNESS : stopPoint.x - NSMinX(bounds);
		double h = (YES == verticalFlipped) ? NSMaxY(bounds) - stopPoint.y - THICKNESS : stopPoint.y - NSMinY(bounds);
		double x = w * (maxPoint.x - minPoint.x) / (NSWidth(bounds) - THICKNESS) + minPoint.x;
		double y = h * (maxPoint.y - minPoint.y) / (NSHeight(bounds) - THICKNESS) + minPoint.y;
		if (YES == square) {
			double signeX = (0.0 > x) ? -1.0 : 1.0;
			double signeY = (0.0 > y) ? -1.0 : 1.0;
			x *= x;
			y *= y;
			x *= signeX;
			y *= signeY;
		}
		if (minPoint.x > x) x = minPoint.x;
		if (maxPoint.x < x) x = maxPoint.x;
		if (minPoint.y > y) y = minPoint.y;
		if (maxPoint.y < y) y = maxPoint.y;
		[(ASPointControl *)controlView setMousePoint:NSMakePoint(x,y)];
		[(ASPointControl *)controlView writeToOutlet];
	}
}

@end
