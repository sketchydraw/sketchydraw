//
//  SKTCurve.m
//  Sketch
//
//  Created by me on Sat Apr 28 2001.
//  Copyright (c) 2001 SatoAkira. All rights reserved.
//

#import "SKTCurve.h"
#import "SKTGraphicView.h" // SatoAkira add. for ISFLIPPED //
#import "SKTFoundationExtras.h" // SatoAkira add. for svg...() //

@implementation SKTCurve

- (id)init {
	self = [super init];
	move = to = control1 = control2 = NSZeroPoint;
	/* [self setRotateAngle:[NSNumber numberWithDouble:0.25 * M_PI_2]]; */ // Debug!!!!!!!!!!!!!!! //
	return self;
}

- (void)makeNaturalSize {
    NSRect bounds = [self bounds];
    if (NSWidth(bounds) < NSHeight(bounds)) {
        bounds.size.height = NSWidth(bounds);
        [self setBounds:bounds];
    } else if (NSWidth(bounds) > NSHeight(bounds)) {
        bounds.size.width = NSHeight(bounds);
        [self setBounds:bounds];
    }
}

- (void)curvePoints:(NSRect)bounds
{
	NSPoint beginPoint = [self beginPoint];
	NSPoint endPoint = [self endPoint];
	NSPoint midPoint = NSMakePoint(0.5 * (beginPoint.x + endPoint.x), 0.5 * (beginPoint.y + endPoint.y));
	move = NSMakePoint(beginPoint.x - midPoint.x, beginPoint.y - midPoint.y);
	to = NSMakePoint(endPoint.x - midPoint.x, endPoint.y - midPoint.y);
	control1 = control2 = NSMakePoint(endPoint.x - midPoint.x, beginPoint.y - midPoint.y);
}
- (NSBezierPath *)bezierPathForDrawing {
    NSBezierPath *path = [NSBezierPath bezierPath];
	NSPoint beginPoint = [self beginPoint];
	NSPoint endPoint = [self endPoint];
    NSRect bounds = [self bounds];

	if ((0.0 < NSWidth(bounds)) || (0.0 < NSHeight(bounds))) {
		NSAffineTransform *transform = [NSAffineTransform transform];

		[transform translateXBy:0.5 * (beginPoint.x + endPoint.x) yBy:0.5 * (beginPoint.y + endPoint.y)];
		[transform rotateByRadians:[self rotateAngle]];
		[transform concat];
		[self curvePoints:bounds];
		[path moveToPoint:move];
		[path curveToPoint:to controlPoint1:control1 controlPoint2:control2];
		/* if (YES == [self isDrawingStroke]) {
			// 選択されていないときにも表示されてしまうので良くない。selectedか否かはSKTGraphicViewに問い合わせないと分からない。 //
			if (YES == [NSGraphicsContext currentContextDrawingToScreen]) {
				NSBezierPath *controlPath = [NSBezierPath bezierPath];

				if ([self selected])
				[[NSColor selectedKnobColor] set];
				[controlPath setLineWidth:1.0];
				[controlPath appendBezierPathWithRect:NSMakeRect(control1.x - 2,control1.y - 2,4,4)];
				[controlPath stroke];
			}
		} */
	}
	return path;
}
- (double)arrowRadianAtBeginPoint:(int)corner
{
	double radian;

	switch (corner) {
	case SKTGraphicLowerLeftHandle:
		radian = M_PI;
		break;
	case SKTGraphicUpperLeftHandle:
		radian = M_PI;
		break;
	case SKTGraphicLowerRightHandle:
		radian = 0.0;
		break;
	default: // SKTGraphicUpperRightHandle //
		radian = 0.0;
		break;
	}
#ifdef ISFLIPPED
	radian *= -1.0;
#endif
    return radian;	
}
- (double)arrowRadianAtEndPoint:(int)corner
{
	double radian;

	switch (corner) {
	case SKTGraphicLowerLeftHandle:
		radian = 1.5 * M_PI;
		break;
	case SKTGraphicUpperLeftHandle:
		radian = 0.5 * M_PI;
		break;
	case SKTGraphicLowerRightHandle:
		radian = 1.5 * M_PI;
		break;
	default: // SKTGraphicUpperRightHandle //
		radian = 0.5 * M_PI;
		break;
	}
#ifdef ISFLIPPED
	radian *= -1.0;
#endif
    return radian;	
}
- (NSBezierPath *)arrowBezierPath:(BOOL)isAtStart
// SatoAkira add. //
{
    NSBezierPath *path = [NSBezierPath bezierPath];
    NSRect bounds = [self bounds];
    
	if (((0.0 < NSWidth(bounds)) || (0.0 < NSHeight(bounds))) && (SKTArrowNone != [self arrowState])) {
		NSInteger corner;
		NSPoint beginPoint = [self beginPoint];
		NSPoint endPoint = [self endPoint];
		NSPoint midPoint = NSMakePoint(0.5 * (beginPoint.x + endPoint.x),0.5 * (beginPoint.y + endPoint.y));
		/* BOOL shadowFlag = ((NO == NSEqualSizes([self shadowOffset],NSZeroSize)) && (NO == [self isDrawingFill])) ? YES : NO;

		if (YES == shadowFlag)
			[self shadowSet]; */
		[self strokeColorSet];
		[[self convertColorSpace:[self strokeColor]] setFill];
		[path setLineWidth:1.0];
		[path setLineJoinStyle:NSMiterLineJoinStyle];
		[path setLineDash:(CGFloat *)NULL count:0 phase:0.0];
		if (YES == isAtStart) {
			if ((YES == _pointsRight) && (YES == _pointsDown))
				corner = SKTGraphicUpperLeftHandle;
			else {
				if ((YES == _pointsRight) && (NO == _pointsDown))
					corner = SKTGraphicLowerLeftHandle;
				else {
					if ((NO == _pointsRight) && (YES == _pointsDown))
						corner = SKTGraphicUpperRightHandle;
					else
						corner = SKTGraphicLowerRightHandle;
				}
			}
			pdfArrow(nil,beginPoint.x - midPoint.x, beginPoint.y - midPoint.y,[self arrowRadianAtBeginPoint:corner],[self strokeWidth],[self lineCap]);
		}
		else {
			if ((YES == _pointsRight) && (YES == _pointsDown))
				corner = SKTGraphicLowerRightHandle;
			else {
				if ((YES == _pointsRight) && (NO == _pointsDown))
					corner = SKTGraphicUpperRightHandle;
				else {
					if ((NO == _pointsRight) && (YES == _pointsDown))
						corner = SKTGraphicLowerLeftHandle;
					else
						corner = SKTGraphicUpperLeftHandle;
				}
			}
			pdfArrow(nil,endPoint.x - midPoint.x, endPoint.y - midPoint.y,[self arrowRadianAtEndPoint:corner],[self strokeWidth],[self lineCap]);
		}
	}
	return path;
}

- (BOOL)isContentsUnderPoint:(NSPoint)point
// isFlipped 以前は- (BOOL)hitTest:(NSPoint)point isSelected:(BOOL)isSelected //
// とりあえず良い方法が見つからないのでSKTLineのisContentsUnderPointよりは良い物にする。三角形の範囲に絞る。bezierPathForDrawingでは対応できない。 //
{
	NSRect bounds = [self bounds];

	if ((NO == [self locked]) && (YES == NSPointInRect(point, bounds))) {
		double rotateAngle = [self rotateAngle];
		NSPoint beginPoint = [self beginPoint];
		NSPoint endPoint = [self endPoint];
		NSPoint controlPoint = NSMakePoint(endPoint.x, beginPoint.y);
		NSPoint cross = crosspoint(beginPoint, endPoint, controlPoint, point);
		NSPoint center = NSMakePoint(0.5 * (beginPoint.x + endPoint.x),0.5 * (beginPoint.y + endPoint.y));
		NSPoint pCross = NSMakePoint((cross.x - center.x) * cos(rotateAngle) + (cross.y - center.y) * sin(rotateAngle), -1.0 * (cross.x - center.x) * sin(rotateAngle) + (cross.y - center.y) * cos(rotateAngle));
		NSPoint pPoint = NSMakePoint((point.x - center.x) * cos(rotateAngle) + (point.y - center.y) * sin(rotateAngle),-1.0 * (point.x - center.x) * sin(rotateAngle) + (point.y - center.y) * cos(rotateAngle));
		NSPoint pControl = NSMakePoint((controlPoint.x - center.x) * cos(rotateAngle) + (controlPoint.y - center.y) * sin(rotateAngle),-1.0 * (controlPoint.x - center.x) * sin(rotateAngle) + (controlPoint.y - center.y) * cos(rotateAngle));
		return hypot(pCross.x - pControl.x, pCross.y - pControl.y) >= hypot(pPoint.x - pControl.x, pPoint.y - pControl.y);
		// 以下は10.4のときのアルゴリズム //
		/* NSPoint center = NSMakePoint(NSMidX(bounds),NSMidY(bounds));
		NSPoint pPoint = NSMakePoint((point.x - center.x) * cos(rotateAngle) + (point.y - center.y) * sin(rotateAngle),-1.0 * (point.x - center.x) * sin(rotateAngle) + (point.y - center.y) * cos(rotateAngle));
		NSPoint lowerLeft = NSMakePoint(-0.5 * NSWidth(bounds),0.5 * NSHeight(bounds));
		NSPoint upperLeft = NSMakePoint(-0.5 * NSWidth(bounds),-0.5 * NSHeight(bounds));
		NSPoint upperRight = NSMakePoint(0.5 * NSWidth(bounds),-0.5 * NSHeight(bounds));
		NSPoint lowerRight = NSMakePoint(0.5 * NSWidth(bounds),0.5 * NSHeight(bounds));
		NSPoint cross = (_pointsRight != _pointsDown) ? crosspoint(upperLeft,lowerRight,upperRight,pPoint) : crosspoint(lowerLeft, upperRight, upperLeft,pPoint);

		return (_pointsRight != _pointsDown) ? (hypot(cross.x - upperRight.x,cross.y - upperRight.y) >= hypot(pPoint.x - upperRight.x,pPoint.y - upperRight.y)) ? YES : NO : (hypot(cross.x - upperLeft.x,cross.y - upperLeft.y) >= hypot(pPoint.x - upperLeft.x,pPoint.y - upperLeft.y)) ? YES : NO; */
	}
	else
		return NO;
}

/* - (NSInteger)resizeByMovingHandle:(NSInteger)handle toPoint:(NSPoint)point
{
	NSLog(@"SKTCurve:resizeByMovingHandle");
	if (handle==SKTLineBeginHandle) {
		[self setBeginPoint:point];
	} else if (handle==SKTLineEndHandle) {
		[self setEndPoint:point];
    } // else a cataclysm occurred.
	return handle;
} */

- (id)copyWithZone:(NSZone *)zone
// 各カーブ要素は現在のところboundsからその都度計算されるので無意味である。従ってsuperのをそのまま継承する。 //
{
	SKTCurve *copy = [super copyWithZone:zone];
	copy->move = move;
	copy->control1 = control1;
	copy->control2 = control2;
    return copy;
}

- (NSArray *)svgXMLElements:(NSRect)aRect name:(NSString *)unique_ID
{
	NSRect bounds = [self bounds];
	NSMutableArray *elements = [NSMutableArray arrayWithObject:[NSXMLNode commentWithStringValue:NSStringFromClass([self class])]];

	if ((0.0 < NSWidth(bounds)) || (0.0 < NSHeight(bounds))) {
		BOOL shadowFlag = (0.1 > [self shadowBlurRadiusValue]) ? NO : YES;
		// dx,dyの符号は逆でなければならないが、SKTGraphic.mのsvgDefsAndRect::の中で符号を反転する。 //
		NSArray *defsAndRect = [self svgDefsAndRect:unique_ID allGraphics:NSZeroRect bounds:bounds transform:nil];
		if (0 < [defsAndRect count])
			[elements addObjectsFromArray:defsAndRect];
		CGFloat translateX = NSMidX(bounds) - NSMinX(aRect);
		CGFloat translateY = NSMidY(bounds) - NSMinY(aRect);
		NSXMLElement *element = [[NSXMLElement allocWithZone:[self zone]] initWithName:@"path"];
		NSMutableArray *attributes = [NSMutableArray arrayWithObjects:svgTransformNode(translateX,translateY,[self rotateAngle],1.0,1.0),nil];
		NSArray *fillAndStrokeAttributes = [self svgFillAndStrokeAttributes:unique_ID];
		
		[self curvePoints:bounds];
		[attributes addObjectsFromArray:fillAndStrokeAttributes];
		[attributes addObject:[NSXMLNode attributeWithName:@"d" stringValue:[NSString stringWithFormat:@"M%g,%g C%g,%g %g,%g %g,%g",move.x,move.y,control1.x,control1.y,control2.x,control2.y,to.x,to.y]]];
		if (YES == [self isDrawingStroke]) {
			[attributes addObject:svgStrokeWidthNode([self strokeWidth])];
			[attributes addObject:svgLineCapNode([self lineCap])];
			[attributes addObjectsFromArray:(0 < [[self lineDashPattern] count]) ? svgDashArrayNodes([self lineDashPattern],[self lineDashPhase]) : svgDashArrayNodes(nil,0.0)];
		}
		if (YES == shadowFlag)
			[attributes addObject:[NSXMLNode attributeWithName:@"filter" stringValue:[NSString stringWithFormat:@"url(#shadow_%@)",unique_ID]]];
		[element setAttributes:attributes];
		[elements addObject:element];
		[element release];
		if (SKTArrowNone != [self arrowState]) {
			element = [[NSXMLElement allocWithZone:[self zone]] initWithName:@"g"];
			attributes = [NSMutableArray arrayWithObjects:svgTransformNode(translateX,translateY,[self rotateAngle],1.0,1.0),nil];
			[attributes addObjectsFromArray:svgColorNodes(unique_ID,@"fill",@"stroke",[self strokeColor])];
			[attributes addObject:svgFillRuleNode(NSNonZeroWindingRule)];
			[attributes addObjectsFromArray:svgColorNodes(unique_ID,@"stroke",@"stroke",nil)];
			if (YES == [[[self strokeColor] colorSpaceName] isEqualToString:NSPatternColorSpace])
				[attributes addObject:[NSXMLNode attributeWithName:@"stroke" stringValue:[NSString stringWithFormat:@"url(#stroke_%@)",unique_ID]]];
			if (YES == shadowFlag)
				[attributes addObject:[NSXMLNode attributeWithName:@"filter" stringValue:[NSString stringWithFormat:@"url(#shadow_%@)",unique_ID]]];
			[element setAttributes:attributes];
			[element addChild:[NSXMLNode commentWithStringValue:[NSString stringWithFormat:@"%@/arrow",NSStringFromClass([self class])]]];
			if ([self arrowState] & SKTArrowOnStart) {
				if ((YES == _pointsRight) && (YES == _pointsDown))
					[element addChild:svgArrowElement([self strokeColor],-0.5 * NSWidth(bounds),-0.5 * NSHeight(bounds),[self arrowRadianAtBeginPoint:SKTGraphicUpperLeftHandle],[self strokeWidth],[self lineCap])];
				else {
					if ((YES == _pointsRight) && (NO == _pointsDown))
						[element addChild:svgArrowElement([self strokeColor],-0.5 * NSWidth(bounds),0.5 * NSHeight(bounds),[self arrowRadianAtBeginPoint:SKTGraphicLowerLeftHandle],[self strokeWidth],[self lineCap])];
					else {
						if ((NO == _pointsRight) && (YES == _pointsDown))
							[element addChild:svgArrowElement([self strokeColor],0.5 * NSWidth(bounds),-0.5 * NSHeight(bounds),[self arrowRadianAtBeginPoint:SKTGraphicUpperRightHandle],[self strokeWidth],[self lineCap])];
						else
							[element addChild:svgArrowElement([self strokeColor],0.5 * NSWidth(bounds),0.5 * NSHeight(bounds),[self arrowRadianAtBeginPoint:SKTGraphicLowerRightHandle],[self strokeWidth],[self lineCap])];
					}
				}
			}
			if ([self arrowState] & SKTArrowOnEnd) {
				if ((YES == _pointsRight) && (YES == _pointsDown))
					[element addChild:svgArrowElement([self strokeColor],0.5 * NSWidth(bounds),0.5 * NSHeight(bounds),[self arrowRadianAtEndPoint:SKTGraphicLowerRightHandle],[self strokeWidth],[self lineCap])];
				else {
					if ((YES == _pointsRight) && (NO == _pointsDown))
						[element addChild:svgArrowElement([self strokeColor],0.5 * NSWidth(bounds),-0.5 * NSHeight(bounds),[self arrowRadianAtEndPoint:SKTGraphicUpperRightHandle],[self strokeWidth],[self lineCap])];
					else {
						if ((NO == _pointsRight) && (YES == _pointsDown))
							[element addChild:svgArrowElement([self strokeColor],-0.5 * NSWidth(bounds),0.5 * NSHeight(bounds),[self arrowRadianAtEndPoint:SKTGraphicLowerLeftHandle],[self strokeWidth],[self lineCap])];
						else
							[element addChild:svgArrowElement([self strokeColor],-0.5 * NSWidth(bounds),-0.5 * NSHeight(bounds),[self arrowRadianAtEndPoint:SKTGraphicUpperLeftHandle],[self strokeWidth],[self lineCap])];
					}
				}
			}
			[elements addObject:element];
			[element release];
		}
		return elements;
	}
	else
		return nil;
}

@end
