/*
     File: SKTCircle.m
 Abstract: A graphic object to represent a circle.
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

#import "SKTCircle.h"
#import "SKTFoundationExtras.h" // SatoAkira add. for svg...() //

@implementation SKTCircle


/* - (NSBezierPath *)bezierPathForDrawing {
    
    // Simple.
    NSBezierPath *path = [NSBezierPath bezierPathWithOvalInRect:[self bounds]];
    [path setLineWidth:[self strokeWidth]];
    return path;
    
} */ // SatoAkira delete. //
- (NSBezierPath *)bezierPathForDrawing
// SatoAkira add. //
{
	NSRect bounds = [self bounds];
	if ((0.0 < NSWidth(bounds)) || (0.0 < NSHeight(bounds))) {
		NSRect circleRect = NSMakeRect(-0.5 * NSWidth(bounds),-0.5 * NSHeight(bounds),NSWidth(bounds),NSHeight(bounds));
		NSAffineTransform *transform = [NSAffineTransform transform];
		NSBezierPath *path = [NSBezierPath bezierPath];

		[transform translateXBy:NSMidX(bounds) yBy:NSMidY(bounds)];
		[transform rotateByRadians:[self rotateAngle]];
		[transform concat];
		[path appendBezierPathWithOvalInRect:circleRect]; // If the aRect parameter specifies a square, the inscribed path is a circle. The path is constructed by starting in the lower-right quadrant of the rectangle and adding arc segments counterclockwise to complete the oval. appendBezierPathWithArcWithCenter:radius:startAngle:endAngle:もcounter clockwise。 //
		[_cachedBezierPath release];
		_cachedBezierPath = [path copyWithZone:[self zone]];
		return path;
	}
	else
		return nil;
}

/* - (BOOL)isContentsUnderPoint:(NSPoint)point {
    
    // Just check to see if the point is in the path.
    return [[self bezierPathForDrawing] containsPoint:point];

} */ // SatoAkira delete. //
- (BOOL)isContentsUnderPoint:(NSPoint)point
// SatoAkira add. //
{
	if (NO == [self locked]) {
		NSRect bounds = [self bounds];
		double rotateAngle = [self rotateAngle];
		NSPoint center = NSMakePoint(NSMidX(bounds),NSMidY(bounds));
		CGFloat x = (point.x - center.x) * cos(rotateAngle) + (point.y - center.y) * sin(rotateAngle);
		CGFloat y = -1.0 * (point.x - center.x) * sin(rotateAngle) + (point.y - center.y) * cos(rotateAngle);

#ifdef ISFLIPPED
			return (nil != _cachedBezierPath) ? [_cachedBezierPath containsPoint:NSMakePoint(x,y)] : NSPointInRect(NSMakePoint(x,y),NSMakeRect(-0.5 * NSWidth(bounds),-0.5 * NSHeight(bounds),NSWidth(bounds),NSHeight(bounds))); // は矩形領域の場合 //
#else
			return (nil != _cachedBezierPath) ? [_cachedBezierPath containsPoint:NSMakePoint(x,y)] : NSMouseInRect(NSMakePoint(x,y),NSMakeRect(-0.5 * NSWidth(bounds),-0.5 * NSHeight(bounds),NSWidth(bounds),NSHeight(bounds)),NO);
#endif
	}
	else
		return NO;
}
- (BOOL)canDrawArrow { // SatoAkira add. //
	return NO;
}
- (BOOL)isCreating { // SatoAkira add. //
	return _isCreating;
}
- (BOOL)createWithEvent:(NSEvent *)theEvent inView:(SKTGraphicView *)view withGrid:(SKTGrid *)grid { // SatoAkira add. //
 	BOOL alternateFlag = ([theEvent modifierFlags] & NSAlternateKeyMask) ? YES : NO;
	if (YES == alternateFlag) {
		_isSquareBounds = _isCreating = YES;
	}
	else
		_isSquareBounds = _isCreating = NO; // _isCreatingの使い途が無いのでNOとする。 //
	return NO;
}
- (NSView *)newEditingViewWithSuperviewBounds:(NSRect)superviewBounds view:(NSView *)graphicView
// SatoAkira add. doubleClicked->startEditingGraphic:-> から呼ばれる。またはcreateGraphicOfClass:withEvent:->から呼ばれる。nilを返すと、finalizeEditingView が呼ばれなくなる。何らかのビューを返すとfinalizeEditingViewが呼ばれる。 //
{
	if (YES == _isCreating)
		_isCreating = NO;
	return nil;
}
- (void)dealloc { // SatoAkira add. //
	[_cachedBezierPath release];
	[super dealloc];
}

- (NSArray *)svgXMLElements:(NSRect)aRect name:(NSString *)unique_ID
// SatoAkira add. //
{
	NSRect bounds = [self bounds];
	NSMutableArray *elements = [NSMutableArray arrayWithObject:[NSXMLNode commentWithStringValue:NSStringFromClass([self class])]];

	if ((0.0 < NSWidth(bounds)) || (0.0 < NSHeight(bounds))) {
		NSXMLElement *element;
		NSMutableArray *attributes;
		BOOL combine = YES;
		BOOL shadowFlag = (0.1 > [self shadowBlurRadiusValue]) ? NO : YES;
		NSArray *defsAndRect = [self svgDefsAndRect:unique_ID allGraphics:NSZeroRect bounds:bounds transform:nil];
		if (0 < [defsAndRect count])
			[elements addObjectsFromArray:defsAndRect];
		CGFloat translateX = NSMidX(bounds) - NSMinX(aRect);
		CGFloat translateY = NSMidY(bounds) - NSMinY(aRect);
		CGFloat rx = 0.5 * NSWidth(bounds);
		CGFloat ry = 0.5 * NSHeight(bounds);
		NSArray *fillAndStrokeAttributes = [self svgFillAndStrokeAttributes:unique_ID];
		
		if (YES == combine) {
			// combineをサポートしたときには、ellipseは使えなくなる。中心(x,y),x方向の半径rx,y方向の半径ryの楕円を三次ベジェ曲線Cで近似する方法。d="M x+rx y C x+rx y+a*ry x+a*rx y+ry x y+ry C x-a*rx y+ry x-rx y+a*ry x-rx y C x-rx y-a*ry x-a*rx y-ry x y-ry C x+a*rx y-ry x+rx y-a*ry x+rx y Z" ただしa=4 * (sqrt(2) - 1) / 3 である。4つのアンカーポイントは(x+rx,y)(x,y+ry)(x-rx,y)(x,y-ry)とし、この順番で描かせている。 //
			CGFloat a = 4.0 * (sqrt(2.0) - 1.0) / 3.0;
			NSMutableString *coordStr = [NSMutableString stringWithFormat:@"M %0.3f,%0.3f",rx,0.0];
			element = [NSXMLElement elementWithName:@"path"];
			attributes = [NSMutableArray arrayWithObjects:svgTransformNode(translateX,translateY,[self rotateAngle],1.0,1.0), nil];
			[coordStr appendFormat:@" C %0.3f %0.3f %0.3f %0.3f %0.3f %0.3f",rx,a * ry,a*rx,ry,0.0,ry]; // 中心点は(0,0)なので0.0を省略してある。 //
			[coordStr appendFormat:@" C %0.3f %0.3f %0.3f %0.3f %0.3f %0.3f",-1.0 * a * rx,ry,-1.0 * rx,a * ry,-1.0 * rx,0.0];
			[coordStr appendFormat:@" C %0.3f %0.3f %0.3f %0.3f %0.3f %0.3f",-1.0 * rx,-1.0 * a * ry,-1.0 * a * rx,-1.0 * ry,0.0,-1.0 * ry];
			[coordStr appendFormat:@" C %0.3f %0.3f %0.3f %0.3f %0.3f %0.3f",a * rx,-1.0 * ry,rx,-1.0 * a * ry,rx,0.0];
			[attributes addObject:[NSXMLNode attributeWithName:@"d" stringValue:coordStr]];
		}
		else {
			element = [NSXMLElement elementWithName:@"ellipse"];
			attributes = [NSMutableArray arrayWithObjects:svgTransformNode(translateX,translateY,[self rotateAngle],1.0,1.0),[NSXMLNode attributeWithName:@"cx" stringValue:[NSString stringWithFormat:@"%g%@",0.0,svgUnit]],[NSXMLNode attributeWithName:@"cy" stringValue:[NSString stringWithFormat:@"%g%@",0.0,svgUnit]],[NSXMLNode attributeWithName:@"rx" stringValue:[NSString stringWithFormat:@"%g%@",rx,svgUnit]],[NSXMLNode attributeWithName:@"ry" stringValue:[NSString stringWithFormat:@"%g%@",ry,svgUnit]],nil];
		}
		[attributes addObjectsFromArray:fillAndStrokeAttributes];
		if (YES == [self isDrawingStroke]) {
			[attributes addObject:svgStrokeWidthNode([self strokeWidth])];
			[attributes addObject:svgLineJoinNode([self lineJoin])];
			[attributes addObject:svgLineCapNode([self lineCap])];
			[attributes addObjectsFromArray:(0 < [[self lineDashPattern] count]) ? svgDashArrayNodes([self lineDashPattern],[self lineDashPhase]) : svgDashArrayNodes(nil,0.0)];
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

@end
