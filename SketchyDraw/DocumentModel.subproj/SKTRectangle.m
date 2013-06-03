/*
     File: SKTRectangle.m
 Abstract: A graphic object to represent a rectangle.
  Version: 1.8
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2012 Apple Inc. All Rights Reserved.
 
 */

#import "SKTRectangle.h"
#import "SKTFoundationExtras.h" // SatoAkira add. for svg...() //
#define cornerMakePoint(x,y,l,b,r) NSMakePoint((x) + (l) * cos((b) + (r)),(y) + (l) * sin((b) + (r)))  // SatoAkira add. //
NSString *SKTRectangleRadiusXKey = @"rx"; // SatoAkira add. //
NSString *SKTRectangleRadiusYKey = @"ry"; // SatoAkira add. //
static NSString *SKTRectangleRadiusXSKTDKey = @"SKTRectangleRadiusX"; // SatoAkira add.sktd互換 //
static NSString *SKTRectangleRadiusYSKTDKey = @"SKTRectangleRadiusY"; // SatoAkira add.sktd互換 //


@implementation SKTRectangle

- (id)init
// SatoAkira add. //
{
    self = [super init];
	_rx = _ry = 0.0;
    return self;
}

/* - (NSBezierPath *)bezierPathForDrawing {

    // Simple.
    NSBezierPath *path = [NSBezierPath bezierPathWithRect:[self bounds]];
    [path setLineWidth:[self strokeWidth]];
    return path;

} */ // SatoAkira delete. //
- (NSBezierPath *)bezierPathForDrawing
// SatoAkira add. //
{
	NSRect bounds = [self bounds];

	if ((0.0 < NSWidth(bounds)) || (0.0 < NSHeight(bounds))) {
		NSRect rectangleRect = NSMakeRect(-0.5 * NSWidth(bounds),-0.5 * NSHeight(bounds),NSWidth(bounds),NSHeight(bounds));
		NSAffineTransform *transform = [NSAffineTransform transform];
		/* NSGraphicsContext *currentContext = [NSGraphicsContext currentContext]; */

		[transform translateXBy:NSMidX(bounds) yBy:NSMidY(bounds)];
		[transform rotateByRadians:[self rotateAngle]];
		[transform concat];
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5
		return [NSBezierPath bezierPathWithRoundedRect:rectangleRect xRadius:_rx yRadius:_ry];
#else
		NSBezierPath *path = [NSBezierPath bezierPath];
		if (((1e-7 < _rx) && (1e-7 < _ry)) && (NSWidth(rectangleRect) > 2.0 * _rx) && (NSHeight(rectangleRect) > 2.0 * _ry)) {
			// ASSVGImageRepのSVGPolygon.mと同じアルゴリズム //
			NSPoint *points = NSZoneMalloc([self zone],sizeof(NSPoint) * 4);
			double rotate = 0.0;
			CGFloat radiusX = _rx;
			CGFloat radiusY = _ry;
			CGFloat dx = 0.0;
			CGFloat dy = radiusY;

			points->x = NSMinX(rectangleRect);
			points->y = NSMinY(rectangleRect);
			(points + 1)->x = NSMinX(rectangleRect) + NSWidth(rectangleRect);
			(points + 1)->y = NSMinY(rectangleRect);
			(points + 2)->x = NSMinX(rectangleRect) + NSWidth(rectangleRect);
			(points + 2)->y = NSMinY(rectangleRect) + NSHeight(rectangleRect);
			(points + 3)->x = NSMinX(rectangleRect);
			(points + 3)->y = NSMinY(rectangleRect) + NSHeight(rectangleRect);
			[path moveToPoint:cornerMakePoint(points->x,points->y,radiusX,0.0,rotate)];
			[path lineToPoint:cornerMakePoint((points + 1)->x,(points + 1)->y,radiusX,M_PI,rotate)];
			[path curveToPoint:cornerMakePoint((points + 1)->x,(points + 1)->y,radiusY,M_PI_2,rotate) controlPoint1:cornerMakePoint((points + 1)->x,(points + 1)->y,dx,M_PI,rotate) controlPoint2:cornerMakePoint((points + 1)->x,(points + 1)->y,dy,M_PI_2,rotate)];
			[path lineToPoint:cornerMakePoint((points + 2)->x,(points + 2)->y,radiusY,M_PI + M_PI_2,rotate)];
			[path curveToPoint:cornerMakePoint((points + 2)->x,(points + 2)->y,radiusX,M_PI,rotate) controlPoint1:cornerMakePoint((points + 2)->x,(points + 2)->y,dy,M_PI + M_PI_2,rotate) controlPoint2:cornerMakePoint((points + 2)->x,(points + 2)->y,dx,M_PI,rotate)];
			[path lineToPoint:cornerMakePoint((points + 3)->x,(points + 3)->y,radiusX,0.0,rotate)];
			[path curveToPoint:cornerMakePoint((points + 3)->x,(points + 3)->y,radiusY,M_PI + M_PI_2,rotate) controlPoint1:cornerMakePoint((points + 3)->x,(points + 3)->y,dx,0.0,rotate) controlPoint2:cornerMakePoint((points + 3)->x,(points + 3)->y,dy,M_PI + M_PI_2,rotate)];
			[path lineToPoint:cornerMakePoint(points->x,points->y,radiusY,M_PI_2,rotate)];
			[path curveToPoint:cornerMakePoint(points->x,points->y,radiusX,0.0,rotate) controlPoint1:cornerMakePoint(points->x,points->y,dy,M_PI_2,rotate) controlPoint2:cornerMakePoint(points->x,points->y,dx,0.0,rotate)];
			[path closePath];
			NSZoneFree([self zone], points);
		}
		else
			[path appendBezierPathWithRect:rectangleRect];
		return path;
#endif
	}
	else
		return nil;
}
// ↓SatoAkira add. //
- (BOOL)canDrawArrow {
	return NO;
}
- (BOOL)canDrawCorner {
	return YES;
}
- (void)setRx:(CGFloat)aValue {
	_rx = aValue;
}
- (void)setRy:(CGFloat)aValue {
	_ry = aValue;
}
- (CGFloat)rx {
	return _rx;
}
- (CGFloat)ry {
	return _ry;
}
- (BOOL)isCreating {
	return _isCreating;
}
- (BOOL)createWithEvent:(NSEvent *)theEvent inView:(SKTGraphicView *)view withGrid:(SKTGrid *)grid {
 	BOOL alternateFlag = ([theEvent modifierFlags] & NSAlternateKeyMask) ? YES : NO;
	if (YES == alternateFlag) {
		_isSquareBounds = _isCreating = YES;
	}
	else
		_isSquareBounds = _isCreating = NO; // _isCreatingの使い途が無いのでNOとする。 //
	return NO;
}
- (NSView *)newEditingViewWithSuperviewBounds:(NSRect)superviewBounds view:(NSView *)graphicView
// doubleClicked->startEditingGraphic:-> から呼ばれる。またはcreateGraphicOfClass:withEvent:->から呼ばれる。nilを返すと、finalizeEditingView が呼ばれなくなる。何らかのビューを返すとfinalizeEditingViewが呼ばれる。 //
{
	if (YES == _isCreating)
		_isCreating = NO;
	return nil;
}
/* + (void)initialize // override のやり方が判らない。不要かもしれない。 // */
- (id)copyWithZone:(NSZone *)zone
{
	SKTRectangle *copy = [super copyWithZone:zone];
	copy->_rx = _rx;
	copy->_ry = _ry;
	return copy;
}
- (id)initWithProperties:(NSDictionary *)properties
{
	if (nil != (self = [super initWithProperties:properties])) {
		NSNumber *obj;
		if ((nil != (obj = [properties objectForKey:SKTRectangleRadiusXKey])) || (nil != (obj = [properties objectForKey:SKTRectangleRadiusXSKTDKey])))
			_rx = [obj floatValue];
		else
			_rx = 0.0;
		if ((nil != (obj = [properties objectForKey:SKTRectangleRadiusYKey])) || (nil != (obj = [properties objectForKey:SKTRectangleRadiusYSKTDKey])))
			_ry = [obj floatValue];
		else
			_ry = 0.0;
	}
	return self;
}
- (NSMutableDictionary *)properties
{
	NSMutableDictionary *properties = [super properties];
	[properties setObject:[NSNumber numberWithFloat:_rx] forKey:SKTRectangleRadiusXKey];
	[properties setObject:[NSNumber numberWithFloat:_ry] forKey:SKTRectangleRadiusYKey];
    return properties;

}
+ (NSSet *)keyPathsForValuesAffectingDrawingContents {
    NSMutableSet *keys = [[super keyPathsForValuesAffectingDrawingContents] mutableCopy];
    [keys addObject:SKTRectangleRadiusXKey];
    [keys addObject:SKTRectangleRadiusYKey];
    return [keys autorelease];
}
- (NSSet *)keysForValuesToObserveForUndo
{
	NSMutableSet *keys = [[super keysForValuesToObserveForUndo] mutableCopy];
	[keys addObject:SKTRectangleRadiusXKey];
	[keys addObject:SKTRectangleRadiusYKey];
    return [keys autorelease];
}
+ (NSString *)presentablePropertyNameForKey:(NSString *)key
{
	static NSDictionary *presentablePropertyNamesByKey = nil;
	if (nil == presentablePropertyNamesByKey)
		presentablePropertyNamesByKey = [[NSMutableDictionary alloc] initWithObjectsAndKeys:NSLocalizedStringFromTable(SKTRectangleRadiusXKey, @"UndoStrings", @"Action name part for SKTRectangleRadiusXKey."), SKTRectangleRadiusXKey,NSLocalizedStringFromTable(SKTRectangleRadiusYKey, @"UndoStrings",@"Action name part for SKTRectangleRadiusYKey."), SKTRectangleRadiusYKey,nil];
	NSString *presentablePropertyName = [presentablePropertyNamesByKey objectForKey:key];
	if (nil == presentablePropertyName)
		presentablePropertyName = [super presentablePropertyNameForKey:key];
    return presentablePropertyName;
}
- (NSArray *)svgXMLElements:(NSRect)aRect name:(NSString *)unique_ID
{
	NSRect bounds = [self bounds];
	NSMutableArray *elements = [NSMutableArray arrayWithObject:[NSXMLNode commentWithStringValue:NSStringFromClass([self class])]];

	if ((0.0 < NSWidth(bounds)) || (0.0 < NSHeight(bounds))) {
		BOOL shadowFlag = (0.1 > [self shadowBlurRadiusValue]) ? NO : YES;
		NSArray *defsAndRect = [self svgDefsAndRect:unique_ID allGraphics:NSZeroRect bounds:bounds transform:nil];
		if (0 < [defsAndRect count])
			[elements addObjectsFromArray:defsAndRect];
		CGFloat translateX = NSMidX(bounds) - NSMinX(aRect);
		CGFloat translateY = NSMidY(bounds) - NSMinY(aRect);
		NSXMLElement *element = [NSXMLElement elementWithName:@"rect"];
		NSMutableArray *attributes = [NSMutableArray arrayWithObjects:svgTransformNode(translateX,translateY,[self rotateAngle],1.0,1.0),[NSXMLNode attributeWithName:@"x" stringValue:[NSString stringWithFormat:@"%g%@",-0.5 * NSWidth(bounds),svgUnit]],[NSXMLNode attributeWithName:@"y" stringValue:[NSString stringWithFormat:@"%g%@",-0.5 * NSHeight(bounds),svgUnit]],[NSXMLNode attributeWithName:@"width" stringValue:[NSString stringWithFormat:@"%g%@",NSWidth(bounds),svgUnit]],[NSXMLNode attributeWithName:@"height" stringValue:[NSString stringWithFormat:@"%g%@",NSHeight(bounds),svgUnit]],nil];
		NSArray *fillAndStrokeAttributes = [self svgFillAndStrokeAttributes:unique_ID];

		[attributes addObjectsFromArray:fillAndStrokeAttributes];
		if (YES == [self isDrawingStroke]) {
			[attributes addObject:svgStrokeWidthNode([self strokeWidth])];
			[attributes addObject:svgLineJoinNode([self lineJoin])];
			[attributes addObject:svgLineCapNode([self lineCap])];
			[attributes addObjectsFromArray:(0 < [[self lineDashPattern] count]) ? svgDashArrayNodes([self lineDashPattern],[self lineDashPhase]) : svgDashArrayNodes(nil,0.0)];
		}
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5
		if ((1e-7 < _rx) && (1e-7 < _ry)) {
#else
		if (((1e-7 < _rx) && (1e-7 < _ry)) && (NSWidth(bounds) > 2.0 * _rx) && (NSHeight(bounds) > 2.0 * _ry)) {
#endif
			[attributes addObject:[NSXMLNode attributeWithName:@"rx" stringValue:[NSString stringWithFormat:@"%g%@",_rx,svgUnit]]];
			[attributes addObject:[NSXMLNode attributeWithName:@"ry" stringValue:[NSString stringWithFormat:@"%g%@",_ry,svgUnit]]];
		}
		if (YES == shadowFlag)
			[attributes addObject:[NSXMLNode attributeWithName:@"filter" stringValue:[NSString stringWithFormat:@"url(#shadow_%@)",unique_ID]]];
		[element setAttributes:attributes];
		[elements addObject:element];
		return elements;
	}
	else
		return nil;
}
// ↑SatoAkira add. //

@end


/*
IMPORTANT:  This Apple software is supplied to you by Apple Computer, Inc. ("Apple") in
consideration of your agreement to the following terms, and your use, installation,
modification or redistribution of this Apple software constitutes acceptance of these
terms.  If you do not agree with these terms, please do not use, install, modify or
redistribute this Apple software.

In consideration of your agreement to abide by the following terms, and subject to these
terms, Apple grants you a personal, non-exclusive license, under Apple's copyrights in
this original Apple software (the "Apple Software"), to use, reproduce, modify and
redistribute the Apple Software, with or without modifications, in source and/or binary
forms; provided that if you redistribute the Apple Software in its entirety and without
modifications, you must retain this notice and the following text and disclaimers in all
such redistributions of the Apple Software.  Neither the name, trademarks, service marks
or logos of Apple Computer, Inc. may be used to endorse or promote products derived from
the Apple Software without specific prior written permission from Apple. Except as expressly
stated in this notice, no other rights or licenses, express or implied, are granted by Apple
herein, including but not limited to any patent rights that may be infringed by your
derivative works or by other works in which the Apple Software may be incorporated.

The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO WARRANTIES,
EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT,
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS
USE AND OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.

IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE,
REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND
WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR
OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
