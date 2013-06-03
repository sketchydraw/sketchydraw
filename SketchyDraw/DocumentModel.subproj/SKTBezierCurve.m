//
//  SKTBezierCurve.m
//  Sketch
//
//  Created by SatoAkira on Sun Oct 06 2002.
//  Copyright (c) 2002 SatoAkira. All rights reserved.
//
// - (NSView *)newEditingViewWithSuperviewBounds:(NSRect)superviewBounds がnilを返さないことが他のものと大きく異なる。新規作成は- (BOOL)createWithEvent:(NSEvent *)theEvent inView:(SKTGraphicView *)view withGrid:(SKTGrid *)grid で、編集は- (BOOL)editWithEvent:(NSEvent*)theEvent inView:(SKTGraphicView *)view withGrid:(SKTGrid *)grid。 //
// 拡大・縮小・フリップはSKTGraphic.mのresizeByMovingHandle:で行われる。ここで座標値変更をすることはできない。サイズが極端に小さくなったときに座標値がすべて同じになってしまうからである。setBounds:をオーバーライドして対応する。縦横移動もsetBounds:をオーバーライドして対応する。 //

#import "SKTBezierCurve.h"
#import "SKTGraphicView.h"
#import "SKTFoundationExtras.h" // for rotateRect(),svg...() //
#import "SKTGrid.h"
NSString *SKTBezierCurvePointsKey = @"createdPoints";
NSString *SKTBezierCurveIsFlippedHorizontallyKey = @"flippedHorizontally";
NSString *SKTBezierCurveIsFlippedVerticallyKey = @"flippedVertically";

static CGFloat	SKTBezierPathHandleWidthHalf = 2.0;
static NSPoint	SktInvalidPoint = { -9999.0f, -9999.0f };

@implementation SKTBezierCurve

#define BEZIERCURVE_MASK (NSLeftMouseDraggedMask | NSLeftMouseUpMask)
#define END_BEZIERCURVE_MASK (NSAppKitDefinedMask | NSLeftMouseDownMask | NSApplicationDefinedMask)

- (BOOL)isEditing {
	return _isEditing;
}
- (BOOL)isCreating {
    return _isCreating;
}

- (void)setFlippedHorizontally:(BOOL)isFlippedHorizontally {
	_isFlippedHorizontally = isFlippedHorizontally;
}

- (void)setFlippedVertically:(BOOL)isFlippedVertically {
	_isFlippedVertically = isFlippedVertically;
}

- (void)flipHorizontally {
    [self setFlippedHorizontally:(_isFlippedHorizontally ? NO : YES)];
}

- (void)flipVertically {
    [self setFlippedVertically:(_isFlippedVertically ? NO : YES)];
}

- (void)calcNewPoints:(NSRect)oldBounds
// oldBoundsの値は計算に使わない。変化したかどうかを見るだけ。NSZeroRectとすれば_pointsの初期化に使える。 //
{
	NSRect newBounds = [self bounds];
	
	if ((NO == NSEqualRects(oldBounds,newBounds)) && (nil != _createdPoints) && (0 < [_createdPoints count])) {
		NSPoint createdPoint,point;
		CGFloat scaleX = (0.0 != NSWidth(_createdBounds)) ? NSWidth(newBounds) / NSWidth(_createdBounds) : 1.0;
		CGFloat scaleY = (0.0 != NSHeight(_createdBounds)) ? NSHeight(newBounds) / NSHeight(_createdBounds) : 1.0;
		NSPoint oldMidPoint = NSMakePoint(NSMidX(_createdBounds), NSMidY(_createdBounds));
		NSPoint newMidPoint = NSMakePoint(NSMidX(newBounds), NSMidY(newBounds));

		[_points release];
		_points = [[NSMutableArray allocWithZone:[self zone]] initWithCapacity:10];
		for (NSValue *pValue in _createdPoints) {
			createdPoint = [pValue pointValue];
			point.x = scaleX * (createdPoint.x - oldMidPoint.x) + newMidPoint.x;
			point.y = scaleY * (createdPoint.y - oldMidPoint.y) + newMidPoint.y;
			[_points addObject:[NSValue valueWithPoint:point]];
		}
	}
}
- (void)setBounds:(NSRect)bounds
// not simple.ここで_pointsを計算し直す。 //
{
	if ((NO == _isCreating) && (NO == _isEditing)) {
		NSRect oldBounds = [self bounds];
		[super setBounds:bounds];
		[self calcNewPoints:oldBounds];
	}
	else
		[super setBounds:bounds];
}

- (void)makeNaturalSize {
    NSRect oldBounds = [self bounds];
	NSRect newBounds = oldBounds;
	BOOL boundsChanged = NO;

    if (NSWidth(oldBounds) < NSHeight(oldBounds)) {
        newBounds.size.height = NSWidth(oldBounds);
        [self setBounds:newBounds];
		boundsChanged = YES;
    } else if (NSWidth(oldBounds) > NSHeight(oldBounds)) {
        newBounds.size.width = NSHeight(oldBounds);
        [self setBounds:newBounds];
		boundsChanged = YES;
    }
	if (YES == boundsChanged)
		[self calcNewPoints:oldBounds];
}

- (void)dealloc {
    [_points release];
    [_createdPoints release];
	[super dealloc];
}

//
// Anchor points and control points management
//

- (NSUInteger)numberOfAnchorPoint {
	return (0 == [_createdPoints count]) ? 0 : (YES == _isPathClosed) ? [_createdPoints count] / 3 : ([_createdPoints count] - 1) / 3 + 1;
}

- (BOOL)isAnchorPoint:(NSUInteger)index {
    return (YES == _isPathClosed) ? (1 == index % 3) : (0 == index % 3);
}

- (NSUInteger)indexOfLastAnchorPoint {
	if (YES == _isPathClosed)
		return (1 < [_createdPoints count]) ? [_createdPoints count] - 2 : NSNotFound;
	else
		return (0 < [_createdPoints count]) ? [_createdPoints count] - 1 : NSNotFound;
}

- (NSPoint)pointAtIndex:(NSUInteger)index {
    return [[_points objectAtIndex:index] pointValue];
}
- (NSPoint)createdPointAtIndex:(NSUInteger)index {
    return [[_createdPoints objectAtIndex:index] pointValue];
}

//
// Drawing
//

- (void)drawAnchorHandles
{
     
	if ((YES == [self isCreating]) || (YES == [self isEditing])) {
		NSUInteger i;
		NSPoint point;
		NSRect bounds = [self bounds];
		NSPoint center = NSMakePoint(NSMidX(bounds), NSMidY(bounds));
		NSRect rect = NSMakeRect(0.0,0.0,SKTBezierPathHandleWidthHalf * 2 + 1.0,SKTBezierPathHandleWidthHalf * 2 + 1.0);
		if (YES == [self isCreating]) { // controlポイントが調整される前なので_isPathClosedの影響を受けない。 //
			for (i = 0; i < [_points count]; i++) {
				if ((0 != i) && (0 != i % 3))
					continue;
				else {
					point = [self pointAtIndex:i];
					rect.origin = NSMakePoint(point.x - SKTBezierPathHandleWidthHalf - center.x, point.y - SKTBezierPathHandleWidthHalf - center.y);
					[[NSColor blackColor] set];
					NSRectFill(rect);
				}
			}
		}
		else { // YES == [self isEditing] //
			for (i = 0; i < [_points count]; i++) {
				if (((YES == _isPathClosed) && (1 != i % 3)) || ((NO == _isPathClosed) && (0 != i) && (0 != i % 3)))
					continue;
				else {
					point = [self pointAtIndex:i];
					rect.origin = NSMakePoint(point.x - SKTBezierPathHandleWidthHalf - center.x, point.y - SKTBezierPathHandleWidthHalf - center.y);
					[[NSColor whiteColor] set];
					NSRectFill(rect);
					[[NSColor blackColor] set];
					NSFrameRect(rect);
					if ((i == _selectedPointIndex) && (NSNotFound != _selectedPointIndex)) {
						if (YES == _isPathClosed)
							[[NSColor orangeColor] set];
						else
							[[NSColor magentaColor] set];
						NSRectFill(NSInsetRect(rect, 1.0, 1.0));
					}
				}
			}
		}
	}
}

- (void)drawControlHandlesFromAnchorPoint:(NSPoint)anchorPoint toControlPoint:(NSPoint)controlPoint
{
	NSRect bounds = [self bounds];
	NSPoint center = NSMakePoint(NSMidX(bounds), NSMidY(bounds));
	NSRect rect = NSMakeRect(controlPoint.x - SKTBezierPathHandleWidthHalf - center.x, controlPoint.y - SKTBezierPathHandleWidthHalf - center.y, SKTBezierPathHandleWidthHalf * 2 + 1.0, SKTBezierPathHandleWidthHalf * 2 + 1.0);
    
	[[NSColor blueColor] set];
	[NSBezierPath strokeLineFromPoint:NSMakePoint(anchorPoint.x - center.x, anchorPoint.y - center.y) toPoint:NSMakePoint(controlPoint.x - center.x, controlPoint.y - center.y)];
	[[NSBezierPath bezierPathWithOvalInRect:rect] fill];
}

- (void)drawControlHandles
{
    if ((YES == _isCreating) || (YES == _isEditing)) {
		NSPoint	anchorPoint,ctrlPoint;
		NSUInteger lastAnchorIndex = (YES == _isCreating) ? [_points count] - 1 : [self indexOfLastAnchorPoint]; // isCreatingのときは最初の点と最終の点が調整される前なのでindexOfLastAnchorPointは使えない。 //
		
		if (YES == _isCreating) {
			anchorPoint = [self pointAtIndex:lastAnchorIndex]; // _points //
			[self drawControlHandlesFromAnchorPoint:anchorPoint toControlPoint:_lastControlPoint];
			if (0 < lastAnchorIndex) {
				ctrlPoint = [self pointAtIndex:lastAnchorIndex - 1];
				[self drawControlHandlesFromAnchorPoint:anchorPoint toControlPoint:ctrlPoint];
			}
		}
		else { // YES == _isEditing //
			NSPoint	ctrlPoint1;
			if ((NSNotFound != _selectedPointIndex) && (1 < [_points count])) {
				if (YES == _isPathClosed) {
					if (0 == _selectedPointIndex)
						return; // editの最初のタイミングで0となっている。 //
					else {
						anchorPoint	= [self pointAtIndex:_selectedPointIndex];
						ctrlPoint = [self pointAtIndex:_selectedPointIndex  - 1];
						ctrlPoint1 = [self pointAtIndex:_selectedPointIndex + 1];
					}
				}
				else {
					anchorPoint = [self pointAtIndex:_selectedPointIndex];
					ctrlPoint = (0 == _selectedPointIndex) ? SktInvalidPoint : [self pointAtIndex:_selectedPointIndex - 1];
					ctrlPoint1 = (_selectedPointIndex == lastAnchorIndex) ? SktInvalidPoint : [self pointAtIndex:_selectedPointIndex  + 1];
				}
				if (NO == NSEqualPoints(ctrlPoint, SktInvalidPoint))
					[self drawControlHandlesFromAnchorPoint:anchorPoint toControlPoint:ctrlPoint];
				if (NO == NSEqualPoints(ctrlPoint1, SktInvalidPoint))
					[self drawControlHandlesFromAnchorPoint:anchorPoint toControlPoint:ctrlPoint1];
			}
		}
	}
}

- (NSRect)bezierCurveBounds
// _isCreatingまたは_isEditingの場合のみdrawingBoundsから使われるだけ。controlポイントの中に曲線も入っているはずだという前提。これが崩れる場合があると作り直さなければならない。 //
{
	NSPoint point;
	NSPoint orig = NSMakePoint(MAXFLOAT,MAXFLOAT);
	NSPoint max = NSMakePoint(-1.0 * MAXFLOAT,-1.0 * MAXFLOAT);

	for (NSValue *pValue in _points) {
		point = [pValue pointValue];
		orig.x = MIN(orig.x,point.x);
		orig.y = MIN(orig.y,point.y);
		max.x = MAX(max.x,point.x);
		max.y = MAX(max.y,point.y);
	}
	return NSMakeRect(orig.x,orig.y,fabs(max.x - orig.x),fabs(max.y - orig.y));
}

- (NSBezierPath *)bezierCurvePath:(NSPoint)center
{
	NSUInteger numberOfAnchorPoint = [self numberOfAnchorPoint];
	if (0 < numberOfAnchorPoint) {
		NSBezierPath *path = [NSBezierPath bezierPath];
		NSUInteger index;
		if (1 < numberOfAnchorPoint) {
			if (YES == _isPathClosed) {
				NSUInteger i;
				NSPoint control1, control2, anchor2;
				NSPoint anchor1 = [self pointAtIndex:1];
				[path moveToPoint:NSMakePoint(anchor1.x - center.x, anchor1.y - center.y)];
				for (index = 2, i = 1; i < numberOfAnchorPoint; i++) {
					control1 = [self pointAtIndex:index++];
					control2 = [self pointAtIndex:index++];
					anchor2 = [self pointAtIndex:index++];
					[path curveToPoint:NSMakePoint(anchor2.x - center.x, anchor2.y - center.y) controlPoint1:NSMakePoint(control1.x - center.x, control1.y - center.y) controlPoint2:NSMakePoint(control2.x - center.x, control2.y - center.y)];
				}
				control1 = [self pointAtIndex:index];
				control2 = [self pointAtIndex:0];
				anchor2 = [self pointAtIndex:1];
				[path curveToPoint:NSMakePoint(anchor2.x - center.x, anchor2.y - center.y) controlPoint1:NSMakePoint(control1.x - center.x, control1.y - center.y) controlPoint2:NSMakePoint(control2.x - center.x, control2.y - center.y)];
				[path closePath];
			}
			else {
				NSUInteger i;
				NSPoint control1, control2, anchor2;
				NSPoint anchor1 = [self pointAtIndex:0];
				[path moveToPoint:NSMakePoint(anchor1.x - center.x, anchor1.y - center.y)];
				for (index = 1, i = 1; i < numberOfAnchorPoint; i++) {
					control1 = [self pointAtIndex:index++];
					control2 = [self pointAtIndex:index++];
					anchor2 = [self pointAtIndex:index++];
					if (YES == NSEqualPoints(control1, SktInvalidPoint))
						control1 = anchor1;
					if (YES == NSEqualPoints(control2, SktInvalidPoint))
						control2 = anchor2;
					[path curveToPoint:NSMakePoint(anchor2.x - center.x, anchor2.y - center.y) controlPoint1:NSMakePoint(control1.x - center.x, control1.y - center.y) controlPoint2:NSMakePoint(control2.x - center.x, control2.y - center.y)];
					anchor1 = anchor2;
				}
			}
		}
		return path;
	}
	else
		return nil;
}
- (NSBezierPath *)bezierPathForDrawing
{
	NSUInteger numberOfAnchorPoint = [self numberOfAnchorPoint];
	NSRect bounds = [self bounds];

	if ((0 < numberOfAnchorPoint) && ((0.0 < NSWidth(bounds)) || (0.0 < NSHeight(bounds)))) {
		NSAffineTransform *transform = [NSAffineTransform transform];
		NSPoint center = NSMakePoint(NSMidX(bounds),NSMidY(bounds));
		NSBezierPath *path = [self bezierCurvePath:center];

		[transform translateXBy:center.x yBy:center.y];
		[transform rotateByRadians:[self rotateAngle]];
		[transform scaleXBy:(YES == _isFlippedHorizontally) ? -1.0 : 1.0 yBy:(YES == _isFlippedVertically) ? -1.0 : 1.0]; // ここは必須のようだ //
		[transform concat];
		return path;
	}
	else
		return nil;
}

- (NSRect)drawingBounds
// overwrite SKTGraphic.m. controlポイント関連以外はSKTGraphic.mと同じ。 //
{
	CGFloat inset = 0.0;

	if (YES == [self isDrawingStroke]) {
		CGFloat halfLineWidth = 0.5 * [self strokeWidth] + 1.0;

		inset = (-1.0 * halfLineWidth < -1.0 * SKTBezierPathHandleWidthHalf) ? -1.0 * halfLineWidth : -1.0 * SKTBezierPathHandleWidthHalf - 1.0;
	}
	else
		inset = -1.0 * SKTBezierPathHandleWidthHalf - 1.0;
	if (SKTArrowNone != [self arrowState]) {
		inset = (0.0 != [self strokeWidth]) ? -1.0 * [self strokeWidth] * 2.5 : -13.0;
	}
	inset += -1.0;
	if ((NO == _isCreating) && (NO == _isEditing)) {
		if (0.1 > [self shadowBlurRadiusValue])
			return rotateRect(NSInsetRect([self bounds],inset, inset),[self rotateAngle]);
		else {
			double offsetX = [self shadowOffsetPoint].x * NSWidth([self bounds]);
			double offsetY = [self shadowOffsetPoint].y * NSHeight([self bounds]);
			double l = hypot(offsetY,offsetX);
			double angle = atan3(offsetY,offsetX);
			double x = l * cos(angle - [self rotateAngle]);
			double y = l * sin(angle - [self rotateAngle]);
			double blurOffset = [self shadowBlurRadiusValue]; // 3.5は根拠が無い。blurが100.0までならば大体これでいける。 //
			NSRect shadowBounds = NSInsetRect([self bounds], -1.0 * blurOffset, -1.0 * blurOffset);

			if (0.0 < x) shadowBounds.size.width += x;
			else if (0.0 > x)  { shadowBounds.origin.x += x; shadowBounds.size.width -= x; }
// ISFLIPPED 1 のとき //
			if (0.0 > y) shadowBounds.size.height -= y;
			else if (0.0 < y)  { shadowBounds.origin.y -= y; shadowBounds.size.height += y; }
			// ISFLIPPED でないときは上のwidth方向と同じアルゴリズムになる。 //
			return rotateRect(NSInsetRect(shadowBounds,inset, inset),[self rotateAngle]);
		}
	}
	else {
		NSRect rect;
		NSRect controlBounds = [self bezierCurveBounds];

		if (1.0 > NSWidth(controlBounds))
			controlBounds.size.width = 1;
		if (1.0 > NSHeight(controlBounds))
			controlBounds.size.height = 1;
		rect.origin.x = _lastControlPoint.x - SKTBezierPathHandleWidthHalf;
		rect.origin.y = _lastControlPoint.y - SKTBezierPathHandleWidthHalf;
		rect.size.width = SKTBezierPathHandleWidthHalf * 2 + 1.0;
		rect.size.height = SKTBezierPathHandleWidthHalf * 2 + 1.0;
		return rotateRect(NSInsetRect(NSUnionRect(controlBounds, rect), inset, inset), [self rotateAngle]);
	}
}

- (NSBezierPath *)arrowBezierPath:(BOOL)isAtStart
{
    NSBezierPath *path = [NSBezierPath bezierPath];
    NSRect bounds = [self bounds];
    
	if (((nil != _points) && (1 < [self numberOfAnchorPoint])) && ((0.0 < NSWidth(bounds)) || (0.0 < NSHeight(bounds)))) {
		NSPoint center = NSMakePoint(NSMidX(bounds),NSMidY(bounds));
		[self strokeColorSet];
		[[self convertColorSpace:[self strokeColor]] setFill];
		[path setLineWidth:1.0];
		[path setLineJoinStyle:NSMiterLineJoinStyle];
		[path setLineDash:(CGFloat *)NULL count:0 phase:0.0];
		if (SKTArrowNone != [self arrowState]) {
			NSUInteger i;
			double angle;
			NSPoint p1,p2;

			if (YES == isAtStart) {
				i = (YES == _isPathClosed) ? 1 : 0;
				p1 = [self pointAtIndex:i];
				p1 = NSMakePoint(p1.x - center.x,p1.y - center.y);
				p2 = [self pointAtIndex:i + 1];
				p2 = NSMakePoint(p2.x - center.x,p2.y - center.y);
				angle = atan2(p1.y - p2.y,p1.x - p2.x);
#ifdef ISFLIPPED
				pdfArrow(nil,p1.x,p1.y,angle,[self strokeWidth],[self lineCap]);
#else
				pdfArrow(nil,*points - center.x,*(points + 1) - center.y,180.0 * angle * M_1_PI,[self strokeWidth],[self lineCap]);
#endif
			}
			else {
				if ((NSNotFound != (i = [self indexOfLastAnchorPoint])) && (0 < i)) {
					p1 = [self pointAtIndex:i];
					p1 = NSMakePoint(p1.x - center.x,p1.y - center.y);
					p2 = [self pointAtIndex:i - 1];
					p2 = NSMakePoint(p2.x - center.x,p2.y - center.y);
					angle = atan2(p1.y - p2.y,p1.x - p2.x);
#ifdef ISFLIPPED
					pdfArrow(nil,p1.x,p1.y, angle,[self strokeWidth],[self lineCap]);
#else
					pdfArrow(nil,*(points + 2 * length) - cente.x,*(points + 2 * length + 1), 180.0 * angle * M_1_PI,[self strokeWidth],[self lineCap]);
#endif
				}
			}
		}
	}
	return path;
}

//
// Event handling
//

- (BOOL)pointInRect:(NSPoint)point atIndex:(NSUInteger)index
{
	NSRect	rect;
	NSPoint	pt = [self pointAtIndex:index];
	rect.origin.x = pt.x - (SKTBezierPathHandleWidthHalf + 1);
	rect.origin.y = pt.y - (SKTBezierPathHandleWidthHalf + 1);
	rect.size.width = (SKTBezierPathHandleWidthHalf + 1) * 2 + 1.0;
	rect.size.height = (SKTBezierPathHandleWidthHalf + 1) * 2 + 1.0;
	return NSPointInRect(point, rect);
}
- (NSUInteger)pointUnderPoint:(NSPoint)point control:(BOOL)flag
{
	NSUInteger i;
	NSUInteger returnValue = NSNotFound;

	if (YES == _isPathClosed) {
		if (YES == flag) {
			for (i = 0; i < [_points count]; i++) { // ControlPointを先に探す。 //
				if (YES == [self pointInRect:point atIndex:i]) {
					returnValue = i;
					break;
				}
				i += 2;
				if (YES == [self pointInRect:point atIndex:i]) {
					returnValue = i;
					break;
				}
			}
		}
		else {
			for (i = 1; i < [_points count]; i += 3) { // AnchorPointを先に探す。 //
				if (YES == [self pointInRect:point atIndex:i]) {
					returnValue = i;
					break;
				}
			}
		}
	}
	else {
		if (YES == flag) {
			for (i = 1; i < [_points count] - 1; i += 2) { // ControlPointを先に探す。 //
				if (YES == [self pointInRect:point atIndex:i]) {
					returnValue = i;
					break;
				}
				i++;
				if (YES == [self pointInRect:point atIndex:i]) {
					returnValue = i;
					break;
				}
			}
		}
		else {
			for (i = 0; i < [_points count]; i += 3) { // AnchorPointを先に探す。 //
				if (YES == [self pointInRect:point atIndex:i]) {
					returnValue = i;
					break;
				}
			}
		}
	}
	if (NSNotFound == returnValue) {
		for (i = 0; i < [_points count]; i++) { // AnchorPoint以外も総て探す。 //
			if (YES == [self pointInRect:point atIndex:i]) {
				returnValue = i;
				break;
			}
		}
	}
	return returnValue;
}

- (void)movePointAtIndex:(NSUInteger)index toPoint:(NSPoint)point
// create,edit専用。resizeやmoveでは使われない。 //
{
    [_createdPoints replaceObjectAtIndex:index withObject:[NSValue valueWithPoint:point]];
    [_points replaceObjectAtIndex:index withObject:[NSValue valueWithPoint:point]];
}
- (void)movePointAtIndex:(NSUInteger)index bySize:(NSSize)size
// create,edit専用。resizeやmoveでは使われない。 //
{
    NSPoint	point = [self pointAtIndex:index];

    point.x += size.width;
    point.y += size.height;
    [self movePointAtIndex:index toPoint:point];
}

- (BOOL)createWithEvent:(NSEvent *)theEvent inView:(SKTGraphicView *)view withGrid:(SKTGrid *)grid
// マウスドラッグから開始し、3点目以後はマウスクリックでも良い。 //
{
	CGFloat ox,oy,bx,by;
	NSEventType type;
	NSUInteger index;
	NSPoint	flippedCtrlPt;
	NSPoint	convertPoint = [view convertPoint:[theEvent locationInWindow] fromView:nil];
	BOOL snapsToGrid = (nil != grid) ? [grid isConstraining] : NO;;
	BOOL echoToRulers = [[view enclosingScrollView] rulersVisible];
	NSPoint point = (YES == snapsToGrid) ? [grid constrainedPoint:convertPoint] : convertPoint;
	NSPoint lastAnchorPt = point;
	BOOL done = NO;
	NSInteger windowNumber = [theEvent windowNumber];
	NSRect viewBounds = [view visibleRect];
 	BOOL alternateFlag = ([theEvent modifierFlags] & NSAlternateKeyMask) ? YES : NO;
   
	_isCreating = YES;
	_isPathClosed = NO;
	/* [self setRotateAngle:[NSNumber numberWithDouble:0.0]]; */
	[self setValue:[NSNumber numberWithDouble:0.0] forKey:SKTRotateAngleKey]; // 回転角は0.0として座標値を計算する。 //
	_createdBounds = NSMakeRect(point.x, point.y, 0.0, 0.0);
	[self setBounds:NSMakeRect(point.x, point.y, 0.0, 0.0)];
	ox = bx = point.x;
	oy = by = point.y;
	if (echoToRulers)
        [view beginEchoingMoveToRulers:[self bounds]];
	[_createdPoints release];
	_createdPoints = [[NSMutableArray allocWithZone:[self zone]] initWithCapacity:10];
	[_points release];
	_points = [[NSMutableArray allocWithZone:[self zone]] initWithCapacity:10];
	[_createdPoints addObject:[NSValue valueWithPoint:point]];
	[_points addObject:[NSValue valueWithPoint:point]];
	theEvent = [[view window] nextEventMatchingMask:BEZIERCURVE_MASK];
	type = [theEvent type];
	while (NO == done) {
		if (NSLeftMouseDown == type) {
			if (1 < [theEvent clickCount]) {
				done = YES;
				if ((YES == alternateFlag) && (NO == _isPathClosed))
					_isPathClosed = YES;
				[[view window] nextEventMatchingMask:NSLeftMouseUpMask];
			}
			else {
				if (windowNumber != [theEvent windowNumber])
					done = YES;
				else {
					point = [view convertPoint:[theEvent locationInWindow] fromView:nil];
					if (snapsToGrid)
						point = [grid constrainedPoint:point];
					if (NO == NSPointInRect(point,viewBounds)) // viewの範囲外でクリックされた //
						done = YES;
					else {
						[_createdPoints addObject:[NSValue valueWithPoint:_lastControlPoint]];
						[_points addObject:[NSValue valueWithPoint:_lastControlPoint]];
						[_createdPoints addObject:[NSValue valueWithPoint:point]];
						[_points addObject:[NSValue valueWithPoint:point]];
						[_createdPoints addObject:[NSValue valueWithPoint:point]];
						[_points addObject:[NSValue valueWithPoint:point]];
						lastAnchorPt = point;
						_lastControlPoint = point;
						ox = MIN(ox,point.x);
						bx = MAX(bx,point.x);
						oy = MIN(oy,point.y);
						by = MAX(by,point.y);
					}
				}
			}
		} // if (NSLeftMouseDown == type) //
		else {
			if ((NSAppKitDefined == type) || (NSSystemDefined == type))
				done = YES;
		}
		if (NO == done) {
			while (NSLeftMouseUp != type) { // すなわちドラッグ中 //
				point = [view convertPoint:[theEvent locationInWindow] fromView:nil];
				if (YES == snapsToGrid)
					point = [grid constrainedPoint:point];
				index = (0 < [_createdPoints count]) ? [_createdPoints count] - 1 : NSNotFound; // indexOfLastAnchorPointは呼べない。 //
				flippedCtrlPt = NSMakePoint(2 * lastAnchorPt.x - point.x,2 * lastAnchorPt.y - point.y);
				if ((0 != index) && (NSNotFound != index)) // Move the last control point //
					[self movePointAtIndex:index - 1 toPoint:flippedCtrlPt];
				_lastControlPoint = point;
				ox = MIN(ox,point.x);
				bx = MAX(bx,point.x);
				oy = MIN(oy,point.y);
				by = MAX(by,point.y);
				[self setBounds:NSMakeRect(ox,oy,fabs(bx - ox),fabs(by - oy))];
				_createdBounds = NSMakeRect(ox,oy,fabs(bx - ox),fabs(by - oy)); // [view setNeedsDisplayInrect:]はOS10.5から自動的に呼ばれるので不要になった。 //
				if (echoToRulers)
					[view continueEchoingMoveToRulers:[self bounds]];
				theEvent = [[view window] nextEventMatchingMask:BEZIERCURVE_MASK];
				type = [theEvent type];
			} // while (NSLeftMouseUp != type) //
			// 下の判断を入れると、最初がマウスドラッグでない場合に、このメソッドの最終のreturnへ飛ぶようになる。 //
			if (0 == [self pointUnderPoint:point control:NO]) {
				index = (0 < [_createdPoints count]) ? [_createdPoints count] - 1 : NSNotFound; // indexOfLastAnchorPointは呼べない。 //
				[self movePointAtIndex:index toPoint:[self createdPointAtIndex:0]]; // 最初の点の前にコントロールポイントが挿入される前なので0インデックス //
				done = YES;
				_isPathClosed = YES;
				// NSLog(@"0start equal last."); //
			}
		} // if (NO == done) //
		if (NO == done) { // マウスアップで確定 //
			if (1 < [_createdPoints count]) {
				if (0 == [self pointUnderPoint:lastAnchorPt control:NO]) {
					index = (0 < [_createdPoints count]) ? [_createdPoints count] - 1 : NSNotFound; // indexOfLastAnchorPointは呼べない。 //
					[self movePointAtIndex:index toPoint:[self createdPointAtIndex:0]];
					_isPathClosed = YES;
					done = YES;
					// NSLog(@"1start equal last."); //
				}
			}
			if (NO == done) {
				theEvent = [[view window] nextEventMatchingMask:END_BEZIERCURVE_MASK];
				type = [theEvent type];
			}
		}
	} // while (NO == done) //
	if (echoToRulers)
		[view stopEchoingMoveToRulers];    
    if ((0.0 < NSWidth(_createdBounds)) || (0.0 < NSHeight(_createdBounds))) {
		if (YES == _isPathClosed) { // 最初の点にコントロールポイントを追加する。ダブルクリックされた点を削除する。 //
			NSPoint firstAnchorPoint = [self pointAtIndex:0];
			point = [self pointAtIndex:1];
			flippedCtrlPt = NSMakePoint(2 * firstAnchorPoint.x - point.x,2 * firstAnchorPoint.y - point.y);
			[_createdPoints insertObject:[NSValue valueWithPoint:flippedCtrlPt] atIndex:0];
			[_points insertObject:[NSValue valueWithPoint:flippedCtrlPt] atIndex:0];
			[_createdPoints removeLastObject];
			[_points removeLastObject];
			[_createdPoints removeLastObject];
			[_points removeLastObject];
		}
		else { // ダブルクリックされた点を削除する。 //
			[_createdPoints removeLastObject];
			[_points removeLastObject];
			[_createdPoints removeLastObject];
			[_points removeLastObject];
			[_createdPoints removeLastObject];
			[_points removeLastObject];
		}
		_createdBounds = [[self bezierCurvePath:NSZeroPoint] bounds]; // アンカーポイントのみではboundsを決定できないので曲線を含めたboundsを得る。 //
		[self setBounds:_createdBounds]; // controlポイントを除いた範囲。 //
        return YES;
	}
    else
        return YES; // NOをかえすとおかしくなる。 //
}

- (NSView *)newEditingViewWithSuperviewBounds:(NSRect)superviewBounds view:(NSView *)graphicView
// doubleClicked->startEditingGraphic:-> から呼ばれる。またはcreateGraphicOfClass:withEvent:->から呼ばれる。nilを返すと、finalizeEditingView が呼ばれなくなる。何らかのビューを返すとfinalizeEditingViewが呼ばれる。 //
{
	if (YES == _isCreating) {
		_isCreating = NO;
		return nil;
	}
	else {
		double r = [self rotateAngle];
		[_editingView release];
		_editingView = [[NSView alloc] initWithFrame:[self drawingBounds]];
		if ((nil != _points) && (0.0 != r)) { // 回転角を0.0にして編集状態にする。回転角を0.0にしないとマウスドラッグにより編集開始したときboundsの中心がずれていくので全体も移動してしまう。 //
			NSUInteger i;
			NSPoint oldPoint,newPoint;
			NSRect newBounds, bounds = [self bounds];
			NSPoint center = NSMakePoint(NSMidX(bounds),NSMidY(bounds));
			CGFloat maxX = -1.0 * MAXFLOAT;
			CGFloat maxY = -1.0 * MAXFLOAT;
			CGFloat minX = MAXFLOAT;
			CGFloat minY = MAXFLOAT;
			NSMutableArray *newCreatedArray;
			NSMutableArray *newPointsArray = [NSMutableArray arrayWithArray:_points]; // undoに対応する為には、単に_createdBoundsを変えただけでは駄目。 //

			for (i = 0; i < [newPointsArray count]; i++) {
				oldPoint = [[newPointsArray objectAtIndex:i] pointValue];
				newPoint.x = (oldPoint.x - center.x) * cos(r) - (oldPoint.y - center.y) * sin(r) + center.x;
				newPoint.y = (oldPoint.x - center.x) * sin(r) + (oldPoint.y - center.y) * cos(r) + center.y;
				[newPointsArray replaceObjectAtIndex:i withObject:[NSValue valueWithPoint:newPoint]];
				maxX = MAX(maxX,newPoint.x);
				maxY = MAX(maxY,newPoint.y);
				minX = MIN(minX,newPoint.x);
				minY = MIN(minY,newPoint.y);
			}
			newCreatedArray = [NSMutableArray arrayWithArray:newPointsArray];
			newBounds = NSMakeRect(minX,minY,maxX - minX,maxY - minY);
			_isEditing = YES;
			[self setValue:[NSValue valueWithRect:newBounds] forKey:SKTCreatedBoundsKey];
			[self setValue:[NSNumber numberWithDouble:0.0] forKey:SKTRotateAngleKey];
			[self setValue:newCreatedArray forKey:SKTCreatedPointsKey];
			[self setValue:newPointsArray forKey:SKTPointsKey];
			[self setBounds:newBounds];
		}
		else {
			if (nil != _points) {
				[_createdPoints release];
				_createdPoints = [[NSMutableArray allocWithZone:[self zone]] initWithArray:_points];
			}
			_isEditing = YES;
		}
		return _editingView;
	}
}
- (void)finalizeEditingView:(NSView *)editingView view:(NSView *)graphicView {
	_isEditing = NO;
	_selectedPointIndex = NSNotFound;
	[_editingView release];
	_editingView = nil;
}

- (NSRect)movePoints:(NSMutableArray *)points created:(NSMutableArray *)createdPoints atIndex:(NSUInteger)index to:(NSArray *)new
// editWithEvent::から呼ばれる。 //
{
	if (YES == [self isAnchorPoint:index]) {
		if (YES == _isPathClosed) {
			[points replaceObjectAtIndex:index - 1 withObject:[new objectAtIndex:0]]; // control1 //
			[points replaceObjectAtIndex:index withObject:[new objectAtIndex:1]]; // anchor //
			[points replaceObjectAtIndex:index + 1 withObject:[new objectAtIndex:2]]; // control2 //
			[createdPoints replaceObjectAtIndex:index - 1 withObject:[new objectAtIndex:0]]; // control1 //
			[createdPoints replaceObjectAtIndex:index withObject:[new objectAtIndex:1]]; // anchor //
			[createdPoints replaceObjectAtIndex:index + 1 withObject:[new objectAtIndex:2]]; // control2 //	
		}
		else {
			if ((0 < index / 3) && ([self indexOfLastAnchorPoint] > index)) {
				[points replaceObjectAtIndex:index - 1 withObject:[new objectAtIndex:0]]; // control1 //
				[points replaceObjectAtIndex:index withObject:[new objectAtIndex:1]]; // anchor //
				[points replaceObjectAtIndex:index + 1 withObject:[new objectAtIndex:2]]; // control2 //
				[createdPoints replaceObjectAtIndex:index - 1 withObject:[new objectAtIndex:0]]; // control1 //
				[createdPoints replaceObjectAtIndex:index withObject:[new objectAtIndex:1]]; // anchor //
				[createdPoints replaceObjectAtIndex:index + 1 withObject:[new objectAtIndex:2]]; // control2 //				
			}
			else {
				if (0 == index) { // 最初のanchor //
					[points replaceObjectAtIndex:index withObject:[new objectAtIndex:0]]; // anchor //
					[points replaceObjectAtIndex:index + 1 withObject:[new objectAtIndex:1]];
					[createdPoints replaceObjectAtIndex:index withObject:[new objectAtIndex:0]]; // anchor //
					[createdPoints replaceObjectAtIndex:index + 1 withObject:[new objectAtIndex:1]];
				}
				else { // 最終のanchor //
					[points replaceObjectAtIndex:index - 1 withObject:[new objectAtIndex:0]];
					[points replaceObjectAtIndex:index withObject:[new objectAtIndex:1]]; // anchor //
					[createdPoints replaceObjectAtIndex:index - 1 withObject:[new objectAtIndex:0]];
					[createdPoints replaceObjectAtIndex:index withObject:[new objectAtIndex:1]]; // anchor //
				}				
			}
		}
	}
	else {
		[points replaceObjectAtIndex:index withObject:[new objectAtIndex:0]];
		[createdPoints replaceObjectAtIndex:index withObject:[new objectAtIndex:0]];
	}
	return [[self bezierCurvePath:NSZeroPoint] bounds];
}
- (BOOL)editWithEvent:(NSEvent*)theEvent inView:(SKTGraphicView *)view withGrid:(SKTGrid *)grid
{
	NSRect bounds = [self bounds];
	NSPoint center = NSMakePoint(NSMidX(bounds), NSMidY(bounds));
	double r = [self rotateAngle];
	NSPoint mousePoint = [view convertPoint:[theEvent locationInWindow] fromView:nil];
	NSPoint convertedPoint = NSMakePoint((mousePoint.x - center.x) * cos(r) + (mousePoint.y - center.y) * sin(r) + center.x, (mousePoint.y - center.y) * cos(r) - (mousePoint.x - center.x) * sin(r) + center.y); // 回転移動 //
	NSUInteger pointIndex = [self pointUnderPoint:convertedPoint control:([theEvent modifierFlags] & NSControlKeyMask) ? YES : NO];
    
	if (NSNotFound == pointIndex)
		return NO;
	else {
		if (YES == [self isAnchorPoint:pointIndex])
			_selectedPointIndex = pointIndex; // _selectedPointIndexはアンカーポイント //
		if (NSNotFound == _selectedPointIndex)
			return NO;
		else {
			NSSize diffSize;
			NSUInteger index;
			NSPoint point;
			NSRect drawingBounds;
			BOOL snapsToGrid = [grid isConstraining];
			BOOL echoToRulers = [[view enclosingScrollView] rulersVisible];
			NSPoint tempPoint = convertedPoint;
			NSMutableArray *oldPoints = [NSMutableArray array];
			NSMutableArray *newPoints = [NSMutableArray array];
			NSUInteger lastAnchor = [self indexOfLastAnchorPoint];
			BOOL hasDragged = NO; // undo機能を避けるため。 //
			NSRect lastDrawingBounds = [self drawingBounds];
			NSMutableArray *tempCreatedArray = [NSMutableArray arrayWithArray:_createdPoints]; // undo対応用 //
			NSMutableArray *tempPointsArray = [NSMutableArray arrayWithArray:_points]; // undo対応用 //
    
			if (YES == [self isAnchorPoint:pointIndex]) {
				if (YES == _isPathClosed) {
					[oldPoints addObject:[_points objectAtIndex:pointIndex - 1]];
					[oldPoints addObject:[_points objectAtIndex:pointIndex]];
					[oldPoints addObject:[_points objectAtIndex:pointIndex + 1]];
				}
				else {
					if ((0 < pointIndex / 3) && ([self indexOfLastAnchorPoint] > pointIndex)) {
						[oldPoints addObject:[_points objectAtIndex:pointIndex - 1]];
						[oldPoints addObject:[_points objectAtIndex:pointIndex]];
						[oldPoints addObject:[_points objectAtIndex:pointIndex + 1]];
					}
					else {
						if (0 == pointIndex) { // 最初のanchor //
							[oldPoints addObject:[_points objectAtIndex:0]];
							[oldPoints addObject:[_points objectAtIndex:1]];
						}
						else { // 最後のanchor //
							[oldPoints addObject:[_points objectAtIndex:lastAnchor - 1]];
							[oldPoints addObject:[_points objectAtIndex:lastAnchor]];
						}
					}
				}
			}
			else
				[oldPoints addObject:[_points objectAtIndex:pointIndex]];
			while (1) {
				theEvent = [[view window] nextEventMatchingMask:BEZIERCURVE_MASK];
				if (NSLeftMouseDragged == [theEvent type]) {
					point = [view convertPoint:[theEvent locationInWindow] fromView:nil];
					if (YES == snapsToGrid)
						point = [grid constrainedPoint:point];
					convertedPoint.x = (point.x - center.x) * cos(r) + (point.y - center.y) * sin(r) + center.x;
					convertedPoint.y = (point.y - center.y) * cos(r) - (point.x - center.x) * sin(r) + center.y;
					[self movePointAtIndex:pointIndex toPoint:convertedPoint];
					if (YES == [self isAnchorPoint:pointIndex]) {
						index = [self indexOfLastAnchorPoint];
						diffSize.width = convertedPoint.x - tempPoint.x;
						diffSize.height = convertedPoint.y - tempPoint.y;
						if (YES == _isPathClosed) {
							[self movePointAtIndex:pointIndex + 1 bySize:diffSize];
							[self movePointAtIndex:pointIndex - 1 bySize:diffSize];
						}
						else {
							if (0 < pointIndex)
								[self movePointAtIndex:pointIndex - 1 bySize:diffSize];
							if (index > pointIndex)
								[self movePointAtIndex:pointIndex + 1 bySize:diffSize];		
						}
					}
					drawingBounds = [self drawingBounds];
					[view setNeedsDisplayInRect:NSUnionRect(drawingBounds, lastDrawingBounds)]; // anchorとcontrolポイントを表示する為。 //
					lastDrawingBounds = drawingBounds;
					if (YES == echoToRulers)
						[view continueEchoingMoveToRulers:[self bounds]];
				} // if (NSLeftMouseDragged == [event type]) //
				tempPoint = convertedPoint;
				if (YES == [self isAnchorPoint:pointIndex]) {
					if (YES == _isPathClosed) {
						newPoints = [NSMutableArray array];
						[newPoints addObject:[NSValue valueWithPoint:[self pointAtIndex:pointIndex - 1]]];
						[newPoints addObject:[NSValue valueWithPoint:[self pointAtIndex:pointIndex]]];
						[newPoints addObject:[NSValue valueWithPoint:[self pointAtIndex:pointIndex + 1]]];
						hasDragged = YES;
					}
					else {
						if ((0 < pointIndex / 3) && (lastAnchor > pointIndex)) {
							if (NO == NSEqualPoints([[oldPoints objectAtIndex:1] pointValue],[[_points objectAtIndex:pointIndex] pointValue])) {
								newPoints = [NSMutableArray array];
								[newPoints addObject:[_points objectAtIndex:pointIndex - 1]];
								[newPoints addObject:[_points objectAtIndex:pointIndex]];
								[newPoints addObject:[_points objectAtIndex:pointIndex + 1]];
								hasDragged = YES;
							}							
						}
						else {
							if (0 == pointIndex) {
								if (NO == NSEqualPoints([[oldPoints objectAtIndex:0] pointValue],[[_points objectAtIndex:0] pointValue])) {
									newPoints = [NSMutableArray array];
									[newPoints addObject:[_points objectAtIndex:0]];
									[newPoints addObject:[_points objectAtIndex:1]];
									hasDragged = YES;
								}
							}
							else {
								if (NO == NSEqualPoints([[oldPoints objectAtIndex:1] pointValue],[[_points objectAtIndex:lastAnchor] pointValue])) {
									newPoints = [NSMutableArray array];
									[newPoints addObject:[_points objectAtIndex:lastAnchor - 1]];
									[newPoints addObject:[_points objectAtIndex:lastAnchor]];
									hasDragged = YES;
								}
							}							
						}
					}
				} // if (YES == [self isAnchorPoint:pointIndex]) //
				else {
					if (NO == NSEqualPoints([[oldPoints objectAtIndex:0] pointValue],[[_points objectAtIndex:pointIndex] pointValue])) {
						newPoints = [NSMutableArray array];
						[newPoints addObject:[_points objectAtIndex:pointIndex]];
						hasDragged = YES;
					}
				}
				if (YES == hasDragged) {
					_createdBounds = [self movePoints:_points created:_createdPoints atIndex:pointIndex to:newPoints];
					if (NO == NSEqualRects([self bounds], _createdBounds))
						[self setBounds:_createdBounds];
				}
				// else  ポイントを選択しただけのとき、何もしない。 //
				if (NSLeftMouseUp == [theEvent type])
					break;
			} //  while(1) //
			if (YES == hasDragged) {
				// 以下はundoの為だけの処理。undoの必要がなければ総て削除しても良い。削除してもmovePointInview:の中でsetBounds:しているので一応はundoできるが、見た目に戸惑うようになる。 //
				NSRect newBounds = _createdBounds; // newPointsによる新しいbounds //

				_createdBounds = bounds; // 元に戻す。 //
				[_points release];
				_points = [[NSMutableArray allocWithZone:[self zone]] initWithArray:tempPointsArray]; // 元に戻す。 //
				[_createdPoints release];
				_createdPoints = [[NSMutableArray allocWithZone:[self zone]] initWithArray:tempCreatedArray]; // 元に戻す。 //
				[self movePoints:tempPointsArray created:tempCreatedArray atIndex:pointIndex to:newPoints]; // newPointsに置き換える。 //
				if (NO == NSEqualRects(newBounds, bounds))
					[self setValue:[NSValue valueWithRect:newBounds] forKey:SKTCreatedBoundsKey]; // newPointsに置き換えた物をsetValueしてundoに対応させる。 //
				[self setValue:tempCreatedArray forKey:SKTCreatedPointsKey]; // newPointsに置き換えた物をsetValueしてundoに対応させる。 //
				[self setValue:tempPointsArray forKey:SKTPointsKey]; // newPointsに置き換えた物をsetValueしてundoに対応させる。 //
				// undoの為の処理終了 //
			}
			else {
				[view setNeedsDisplayInRect:[self drawingBounds]]; // anchorとcontrolポイントを表示する為。 //
				if (YES == echoToRulers)
					[view continueEchoingMoveToRulers:[self bounds]];
			}
			return YES;
		}
	}
}

- (void)insertForEditingInView:(SKTGraphicView *)view
{
	if ((NSNotFound != _selectedPointIndex) && (0 < [_createdPoints count]) && ([_createdPoints count] > _selectedPointIndex)) {
		NSPoint control1, control2;
		NSUInteger lastIndex = [self indexOfLastAnchorPoint];
		NSMutableArray *tempCreatedArray = [NSMutableArray arrayWithArray:_createdPoints];
		NSMutableArray *tempPointsArray = [NSMutableArray arrayWithArray:_points];
		NSPoint point = [[tempPointsArray objectAtIndex:_selectedPointIndex] pointValue];

		if (YES == _isPathClosed) {
			control1 = [[_createdPoints objectAtIndex:_selectedPointIndex - 1] pointValue];
			control2 = [[_createdPoints objectAtIndex:_selectedPointIndex + 1] pointValue];
			[tempPointsArray insertObject:[NSValue valueWithPoint:control2] atIndex:_selectedPointIndex - 1];
			[tempPointsArray insertObject:[NSValue valueWithPoint:point] atIndex:_selectedPointIndex - 1];
			[tempPointsArray insertObject:[NSValue valueWithPoint:control1] atIndex:_selectedPointIndex - 1];
			[tempCreatedArray insertObject:[NSValue valueWithPoint:control2] atIndex:_selectedPointIndex - 1];
			[tempCreatedArray insertObject:[NSValue valueWithPoint:point] atIndex:_selectedPointIndex - 1];
			[tempCreatedArray insertObject:[NSValue valueWithPoint:control1] atIndex:_selectedPointIndex - 1];
		}
		else {
			if ((0 < _selectedPointIndex / 3) && (lastIndex > _selectedPointIndex)) {
				control1 = [self createdPointAtIndex:_selectedPointIndex - 1];
				control2 = [self createdPointAtIndex:_selectedPointIndex + 1];
				[tempPointsArray insertObject:[NSValue valueWithPoint:control2] atIndex:_selectedPointIndex - 1];
				[tempPointsArray insertObject:[NSValue valueWithPoint:point] atIndex:_selectedPointIndex - 1];
				[tempPointsArray insertObject:[NSValue valueWithPoint:control1] atIndex:_selectedPointIndex - 1];
				[tempCreatedArray insertObject:[NSValue valueWithPoint:control2] atIndex:_selectedPointIndex - 1];
				[tempCreatedArray insertObject:[NSValue valueWithPoint:point] atIndex:_selectedPointIndex - 1];
				[tempCreatedArray insertObject:[NSValue valueWithPoint:control1] atIndex:_selectedPointIndex - 1];
			}
			else {
				if (0 == _selectedPointIndex) {
					control2 = [self createdPointAtIndex:1];
					control1 = [self createdPointAtIndex:1];
					[tempCreatedArray insertObject:[NSValue valueWithPoint:control2] atIndex:0];
					[tempCreatedArray insertObject:[NSValue valueWithPoint:control1] atIndex:0];
					[tempCreatedArray insertObject:[NSValue valueWithPoint:point] atIndex:0];
					[tempPointsArray insertObject:[NSValue valueWithPoint:control2] atIndex:0];
					[tempPointsArray insertObject:[NSValue valueWithPoint:control1] atIndex:0];
					[tempPointsArray insertObject:[NSValue valueWithPoint:point] atIndex:0];
				}
				else {
					if (lastIndex < _selectedPointIndex) { // この場合は無い。 //
						control2 = point;
						control1 = point;
							[tempCreatedArray addObject:[NSValue valueWithPoint:control1]];
							[tempCreatedArray addObject:[NSValue valueWithPoint:control2]];
							[tempCreatedArray insertObject:[NSValue valueWithPoint:control1] atIndex:lastIndex - 1];
							[tempPointsArray addObject:[NSValue valueWithPoint:control1]];
							[tempPointsArray addObject:[NSValue valueWithPoint:control2]];
							[tempPointsArray insertObject:[NSValue valueWithPoint:control1] atIndex:lastIndex - 1];
					}
					else {
						control1 = [self createdPointAtIndex:_selectedPointIndex - 1];
						[tempCreatedArray insertObject:[NSValue valueWithPoint:control1] atIndex:lastIndex - 1]; // ここが一つ前のアンカーの後ろ向きのコントロール //
						[tempCreatedArray insertObject:[NSValue valueWithPoint:point] atIndex:lastIndex - 1]; // ここが最終アンカーの一つ前のアンカー //
						[tempCreatedArray insertObject:[NSValue valueWithPoint:control1] atIndex:lastIndex - 1]; // ここが一つ前のアンカーの前向きのコントロール。最終アンカーの後ろ向きコントロールはそのまま。最終アンカーはそのまま。 //
						[tempPointsArray insertObject:[NSValue valueWithPoint:control1] atIndex:lastIndex - 1];
						[tempPointsArray insertObject:[NSValue valueWithPoint:point] atIndex:lastIndex - 1];
						[tempPointsArray insertObject:[NSValue valueWithPoint:control1] atIndex:lastIndex - 1];
					}
				}
			}
		}
		[self setValue:tempCreatedArray forKey:SKTCreatedPointsKey];
		[self setValue:tempPointsArray forKey:SKTPointsKey];
	}
}

- (NSRect)rectForRemoved:(NSMutableArray *)points created:(NSMutableArray *)createdPoints atIndex:(NSUInteger)index
{
	NSUInteger lastIndex = [self indexOfLastAnchorPoint];

	if (YES == _isPathClosed) {
		[points removeObjectsInRange:NSMakeRange(index - 1, 3)];
		[createdPoints removeObjectsInRange:NSMakeRange(index - 1, 3)];
		
	}
	else {
		if (0 == index || lastIndex == index) {
			if (0 == index) {
				[points removeObjectsInRange:NSMakeRange(0, 3)];
				[createdPoints removeObjectsInRange:NSMakeRange(0, 3)];
			}
			else {
				[points removeObjectsInRange:NSMakeRange(lastIndex - 2, 3)];
				[createdPoints removeObjectsInRange:NSMakeRange(lastIndex - 2, 3)];
			}
		}
		else {
			[points removeObjectsInRange:NSMakeRange(index - 1, 3)];
			[createdPoints removeObjectsInRange:NSMakeRange(index - 1, 3)];
		}
	}
	return [[self bezierCurvePath:NSZeroPoint] bounds]; // points,createdPointsに関係なく_points,_createdPointsで描かれる。 //
}
- (void)deleteForEditingInView:(SKTGraphicView *)view
{
	if ((NSNotFound != _selectedPointIndex) && (1 != [_points count]) && (YES == [self isAnchorPoint:_selectedPointIndex])) {
		NSRect newBounds;
		NSRect bounds = [self bounds];
		NSRect drawingBounds = [self drawingBounds];
		NSMutableArray *newCreatedArray = [NSMutableArray arrayWithArray:_createdPoints]; // deleteする前の物だがあとでdeleteさせる。 //
		NSMutableArray *newPointsArray = [NSMutableArray arrayWithArray:_points]; // deleteする前の物だがあとでdeleteさせる。 //

		_createdBounds = bounds; // 元の値にしておく //
		newBounds = [self rectForRemoved:_points created:_createdPoints atIndex:_selectedPointIndex]; // deleteされたときのbounds //
		[_points release];
		_points = [[NSMutableArray allocWithZone:[self zone]] initWithArray:newPointsArray]; // deleteする前の状態に戻す。 //
		[_createdPoints release];
		_createdPoints = [[NSMutableArray allocWithZone:[self zone]] initWithArray:newCreatedArray]; // deleteする前の状態に戻す。 //
		[self rectForRemoved:newPointsArray created:newCreatedArray atIndex:_selectedPointIndex]; // deleteさせる。 //
		if (NO == NSEqualRects(newBounds, bounds)) {
			[self setBounds:newBounds];
			[self setValue:[NSValue valueWithRect:newBounds] forKey:SKTCreatedBoundsKey]; // deleteされた物をsetValueしてundoに対応させる。 //
		}
		[self setValue:newCreatedArray forKey:SKTCreatedPointsKey]; // deleteされた物をsetValueしてundoに対応させる。 //
		[self setValue:newPointsArray forKey:SKTPointsKey]; // deleteされた物をsetValueしてundoに対応させる。 //
		_selectedPointIndex = NSNotFound;
		drawingBounds = NSUnionRect(drawingBounds, [self drawingBounds]);
		[view setNeedsDisplayInRect:drawingBounds];
	}
}

- (BOOL)isContentsUnderPoint:(NSPoint)point
{
   if (NO == [self locked]) {
		NSRect bounds = [self bounds];
		double rotateAngle = [self rotateAngle];
		NSPoint center = NSMakePoint(NSMidX(bounds),NSMidY(bounds));
		CGFloat scaleX = (YES == _isFlippedHorizontally) ? -1.0 : 1.0;
		CGFloat scaleY = (YES == _isFlippedVertically) ? -1.0 : 1.0;
		CGFloat x = ((point.x - center.x) * cos(rotateAngle) + (point.y - center.y) * sin(rotateAngle)) / scaleX;
		CGFloat y = (-1.0 * (point.x - center.x) * sin(rotateAngle) + (point.y - center.y) * cos(rotateAngle)) / scaleY;
		NSBezierPath *path = [self bezierCurvePath:center];

		return (nil != path) ? [path containsPoint:NSMakePoint(x,y)] : NSPointInRect(NSMakePoint(x,y), [self bounds]);
    }
	else
		return NO;
}

- (id)copyWithZone:(NSZone*)zone
{
	SKTBezierCurve *copy = [super copyWithZone:zone];

	copy->_createdPoints = [_createdPoints copy];
	copy->_isPathClosed = _isPathClosed;
	copy->_isFlippedHorizontally = _isFlippedHorizontally;
	copy->_isFlippedVertically = _isFlippedVertically;
	return copy;
}
+ (NSSet *)keyPathsForValuesAffectingDrawingContents
{
	NSMutableSet *keys = [NSMutableSet setWithSet:[super keyPathsForValuesAffectingDrawingContents]];
	[keys addObject:SKTCreatedPointsKey];
	[keys addObject:SKTPointsKey];
	[keys addObject:SKTCreatedBoundsKey];
	return keys;
}

- (NSSet *)keysForValuesToObserveForUndo {
	NSMutableSet *keys = [[super keysForValuesToObserveForUndo] mutableCopy];
	[keys addObject:SKTCreatedPointsKey];
	[keys addObject:SKTPointsKey];
	[keys addObject:SKTCreatedBoundsKey];
	[keys addObject:SKTBezierCurveIsFlippedHorizontallyKey];
	[keys addObject:SKTBezierCurveIsFlippedVerticallyKey];
	return [keys autorelease];
}

+ (NSString *)presentablePropertyNameForKey:(NSString *)key
{
	static NSDictionary *presentablePropertyNamesByKey = nil;
	
	if (nil == presentablePropertyNamesByKey)
		presentablePropertyNamesByKey = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
			NSLocalizedStringFromTable(SKTCreatedPointsKey, @"UndoStrings", @""), SKTCreatedPointsKey,
			NSLocalizedStringFromTable(SKTPointsKey,@"UndoStrings",@""),SKTPointsKey,
			NSLocalizedStringFromTable(SKTCreatedBoundsKey,@"UndoStrings",@""),SKTCreatedBoundsKey,
			NSLocalizedStringFromTable(@"Horizontal Flipping", @"UndoStrings", @""), SKTBezierCurveIsFlippedHorizontallyKey,
			NSLocalizedStringFromTable(@"Vertical Flipping", @"UndoStrings",@""), SKTBezierCurveIsFlippedVerticallyKey,
			nil];
	NSString *presentablePropertyName = [presentablePropertyNamesByKey objectForKey:key];
	if (nil == presentablePropertyName)
		presentablePropertyName = [super presentablePropertyNameForKey:key];
	return presentablePropertyName;
}

static NSString *SKTCreatedBoundsSKTDKey = @"CreatedBounds"; // for sktd //
static NSString *SKTBezierPathPointsKey = @"BezierPoints"; // for sktd //
static NSString *SKTBezierPathIsPathClosedKey = @"BezierIsPathClosed"; // sktd 互換 //
static NSString *SKTBezierFlippedHorizontallyKey = @"BezierFlippedHorizontally"; // for sktd //
static NSString *SKTBezierFlippedVerticallyKey = @"BezierFlippedVertically"; // for sktd //

- (NSMutableDictionary *)properties
{
	NSMutableDictionary *properties = [super properties];
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:[_createdPoints count]];
    
	for (NSValue *pointObj in _createdPoints)
		[array addObject:NSStringFromPoint([pointObj pointValue])];
	[properties setObject:array forKey:SKTCreatedPointsKey];
	[properties setObject:[NSNumber numberWithBool:_isPathClosed] forKey:SKTBezierPathIsPathClosedKey];
	[properties setObject:[NSNumber numberWithBool:_isFlippedHorizontally] forKey:SKTBezierCurveIsFlippedHorizontallyKey];
	[properties setObject:[NSNumber numberWithBool:_isFlippedVertically] forKey:SKTBezierCurveIsFlippedVerticallyKey];
	[properties setObject:NSStringFromRect(_createdBounds) forKey:SKTCreatedBoundsKey];
	return properties;
}

- (id)initWithProperties:(NSDictionary *)properties
{
    if (nil != (self = [super initWithProperties:properties])) {
		id obj;

		if (nil != (obj = [properties objectForKey:SKTBezierPathIsPathClosedKey])) // 古いものとの互換性をとる為に最初に取得する必要がある。 //
			_isPathClosed = [obj boolValue];
		else
			_isPathClosed = NO;
		if (nil == (obj = [properties objectForKey:SKTCreatedPointsKey]))
			obj = [properties objectForKey:SKTBezierPathPointsKey];
		if (nil != obj) {
			NSMutableArray *array = [NSMutableArray arrayWithCapacity:[(NSArray *)obj count]];
			BOOL oldBezierCurvePoints = ((YES == _isPathClosed) && (0 != [(NSArray *)obj count] % 3)) ? YES : NO; // 旧バージョンかどうか調べる。 //

			if (YES == oldBezierCurvePoints) {
				NSLog(@"BezierCurve is old format.");
				[array addObject:[NSValue valueWithPoint:NSPointFromString([(NSArray *)obj objectAtIndex:0])]];
			}
			for (NSString *pStr in (NSArray *)obj)
				[array addObject:[NSValue valueWithPoint:NSPointFromString(pStr)]];
			if (YES == oldBezierCurvePoints)
				[array addObject:[NSValue valueWithPoint:NSPointFromString([(NSArray *)obj lastObject])]];
			[_createdPoints release];
			_createdPoints = [[NSMutableArray allocWithZone:[self zone]] initWithArray:array];
		}
		if (nil != (obj = [properties objectForKey:SKTBezierCurveIsFlippedHorizontallyKey]))
			_isFlippedHorizontally = [obj boolValue];
		else {
			if (nil != (obj = [properties objectForKey:SKTBezierFlippedHorizontallyKey]))
				_isFlippedHorizontally = [obj isEqualToString:@"YES"];
			else
				_isFlippedHorizontally = NO;
		}
		if (nil != (obj = [properties objectForKey:SKTBezierCurveIsFlippedVerticallyKey]))
			_isFlippedVertically = [obj boolValue];
		else {
			if (nil != (obj = [properties objectForKey:SKTBezierFlippedVerticallyKey]))
				_isFlippedVertically = [obj isEqualToString:@"YES"];
			else
				_isFlippedVertically = NO;
		}
		if (nil == (obj = [properties objectForKey:SKTCreatedBoundsKey]))
			obj = [properties objectForKey:SKTCreatedBoundsSKTDKey];
		if (nil != obj) {
			_createdBounds = NSRectFromString(obj);
			[self calcNewPoints:NSZeroRect];
		}
	}
	return self;
}

- (NSArray *)svgXMLElements:(NSRect)aRect name:(NSString *)unique_ID
{
	NSRect bounds = [self bounds];
	NSMutableArray *elements = [NSMutableArray arrayWithObject:[NSXMLNode commentWithStringValue:NSStringFromClass([self class])]];
	NSUInteger numberOfAnchorPoint = [self numberOfAnchorPoint];

	if (((0.0 < NSWidth(bounds)) || (0.0 < NSHeight(bounds))) && (0 < numberOfAnchorPoint)) {
		NSXMLElement *element; 
		NSMutableArray *attributes;
		NSUInteger index = (YES == _isPathClosed) ? 1 : 0;
		NSPoint anchor1 = [self pointAtIndex:index++];
		NSMutableString *coordStr = [NSMutableString stringWithFormat:@"M%g,%g",anchor1.x,anchor1.y];
		CGFloat translateX = NSMidX(bounds) - NSMinX(aRect);
		CGFloat translateY = NSMidY(bounds) - NSMinY(aRect);
		CGFloat scaleX = (YES == _isFlippedHorizontally) ? -1.0 : 1.0;
		CGFloat scaleY = (YES == _isFlippedVertically) ? -1.0 : 1.0;
		NSMutableString *transformStr = [NSMutableString stringWithFormat:@"translate(%g %g) rotate(%g)",translateX,translateY,180.0 * [self rotateAngle] * M_1_PI];
		CGFloat tX = -1.0 * NSMidX(bounds);
		CGFloat tY = -1.0 * NSMidY(bounds);
		NSArray *fillAndStrokeAttributes = [self svgFillAndStrokeAttributes:unique_ID];
		BOOL shadowFlag = (0.1 > [self shadowBlurRadiusValue]) ? NO : YES;
		NSAffineTransform *trans = [NSAffineTransform transform];
		[trans translateXBy:NSMidX(bounds) yBy:NSMidY(bounds)];
		NSArray *defsAndRect = [self svgDefsAndRect:unique_ID allGraphics:NSZeroRect bounds:bounds transform:trans];
		if (0 < [defsAndRect count])
			[elements addObjectsFromArray:defsAndRect];
		
		[transformStr appendFormat:@" scale(%g %g) translate(%g %g)",scaleX,scaleY,tX,tY];
		element = [NSXMLElement elementWithName:@"path"];
		attributes = [NSMutableArray arrayWithObjects:[NSXMLNode attributeWithName:@"transform" stringValue:transformStr],nil];
		if (1 < numberOfAnchorPoint) {
			if (YES == _isPathClosed) {
				NSUInteger i;
				NSPoint control1,control2,anchor2;
				for (index = 2, i = 1; i < numberOfAnchorPoint; i++) {
					control1 = [self pointAtIndex:index++];
					control2 = [self pointAtIndex:index++];
					anchor2 = [self pointAtIndex:index++];
					[coordStr appendFormat:@" C%0.3f,%0.3f %0.3f,%0.3f %0.3f,%0.3f",control1.x,control1.y,control2.x,control2.y,anchor2.x,anchor2.y];
				}
				control1 = [self pointAtIndex:index];
				control2 = [self pointAtIndex:0];
				anchor2 = [self pointAtIndex:1];
				[coordStr appendFormat:@" C%0.3f,%0.3f %0.3f,%0.3f %0.3f,%0.3f Z",control1.x,control1.y,control2.x,control2.y,anchor2.x,anchor2.y];
			}
			else {
				NSUInteger i;
				NSPoint control1, control2, anchor2;
				for (index = 1, i = 1; i < numberOfAnchorPoint; i++) {
					control1 = [self pointAtIndex:index++];
					control2 = [self pointAtIndex:index++];
					anchor2 = [self pointAtIndex:index++];
					if (YES == NSEqualPoints(control1, SktInvalidPoint))
						control1 = anchor1;
					if (YES == NSEqualPoints(control2, SktInvalidPoint))
						control2 = anchor2;
					[coordStr appendFormat:@" C%g,%g %g,%g %g,%g",control1.x,control1.y,control2.x,control2.y,anchor2.x,anchor2.y];
					anchor1 = anchor2;
				}
			}
		}
		/* if (nil != fillDefs)
			[elements addObject:fillDefs];
		if (nil != strokeDefs)
			[elements addObject:strokeDefs]; */
		[attributes addObjectsFromArray:fillAndStrokeAttributes];
		[attributes addObject:[NSXMLNode attributeWithName:@"d" stringValue:coordStr]];
		if (YES == [self isDrawingStroke]) {
			[attributes addObject:svgStrokeWidthNode([self strokeWidth])];
			[attributes addObject:svgLineCapNode([self lineCap])];
			[attributes addObjectsFromArray:(0 < [[self lineDashPattern] count]) ? svgDashArrayNodes([self lineDashPattern],[self lineDashPhase]) : svgDashArrayNodes(nil,0.0)];
		}
		if (YES == shadowFlag)
			[attributes addObject:[NSXMLNode attributeWithName:@"filter" stringValue:[NSString stringWithFormat:@"url(#shadow_%@)",unique_ID]]];
		[element setAttributes:attributes];
		[elements addObject:element];
		if (SKTArrowNone != [self arrowState]) {
			NSUInteger i;
			double angle;
			NSPoint p1,p2;
			NSPoint center = NSMakePoint(NSMidX(bounds),NSMidY(bounds));

			element = [NSXMLElement elementWithName:@"g"];
			attributes = [NSMutableArray arrayWithObjects:[NSXMLNode attributeWithName:@"transform" stringValue:[NSString stringWithFormat:@"translate(%g %g) rotate(%g) scale(%g %g)",translateX,translateY,180.0 * [self rotateAngle] * M_1_PI,scaleX,scaleY]],nil];
			[attributes addObjectsFromArray:svgColorNodes(unique_ID,@"fill",@"stroke",[self strokeColor])];
			[attributes addObject:svgFillRuleNode(NSNonZeroWindingRule)];
			[attributes addObjectsFromArray:svgColorNodes(unique_ID,@"stroke",@"stroke",nil)];
			if (YES == shadowFlag)
				[attributes addObject:[NSXMLNode attributeWithName:@"filter" stringValue:[NSString stringWithFormat:@"url(#shadow_%@)",unique_ID]]];
			[element setAttributes:attributes];
			[element addChild:[NSXMLNode commentWithStringValue:[NSString stringWithFormat:@"%@/arrow",NSStringFromClass([self class])]]];
			if ([self arrowState] & SKTArrowOnStart) {
				i = (YES == _isPathClosed) ? 1 : 0;
				p1 = [self pointAtIndex:i];
				p1 = NSMakePoint(p1.x - center.x,p1.y - center.y);
				p2 = [self pointAtIndex:i + 1];
				p2 = NSMakePoint(p2.x - center.x,p2.y - center.y);
				angle = atan2(p1.y - p2.y,p1.x - p2.x);
#ifdef ISFLIPPED
				[element addChild:svgArrowElement([self strokeColor],p1.x,p1.y,angle,[self strokeWidth],[self lineCap])];
#else
				[element addChild:svgArrowElement([self strokeColor],*points - center.x,*(points + 1) - center.y,180.0 * angle * M_1_PI,[self strokeWidth],[self lineCap])];
#endif
			}
			if ([self arrowState] & SKTArrowOnEnd) {
				if ((NSNotFound != (i = [self indexOfLastAnchorPoint])) && (0 < i)) {
					p1 = [self pointAtIndex:i];
					p1 = NSMakePoint(p1.x - center.x,p1.y - center.y);
					p2 = [self pointAtIndex:i - 1];
					p2 = NSMakePoint(p2.x - center.x,p2.y - center.y);
					angle = atan2(p1.y - p2.y,p1.x - p2.x);
#ifdef ISFLIPPED
					[element addChild:svgArrowElement([self strokeColor],p1.x,p1.y, angle,[self strokeWidth],[self lineCap])];
#else
					[element addChild:svgArrowElement([self strokeColor],*(points + 2 * length) - cente.x,*(points + 2 * length + 1), 180.0 * angle * M_1_PI,[self strokeWidth],[self lineCap])];
#endif
				}
			}
			[elements addObject:element];
		}
		return elements;
	}
	else
		return nil;
}

@end
