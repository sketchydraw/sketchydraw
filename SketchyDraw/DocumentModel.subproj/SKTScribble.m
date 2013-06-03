//
//  SKTScribble.m
//  Sketch
//
//  Created by me on Sat Apr 28 2001.
//  Copyright (c) 2008 SatoAkira. All rights reserved.
//  OS10.5において大改造。_pointsをresizeやmoveの度に計算し直すようにした。これをしないと元のSketchのアルゴリズムも大改造しなければならないので、こっちのSKTScribbleを大改造した。 //
//

#import "SKTScribble.h"
#import "SKTGraphicView.h" // for ISFLIPPED //
#import "SKTFoundationExtras.h" // for svg...() //
#import "SKTGrid.h"
NSString *SKTScribbleIsFlippedHorizontallyKey = @"flippedHorizontally";
NSString *SKTScribbleIsFlippedVerticallyKey = @"flippedVertically";

@implementation SKTScribble

+ (NSCursor *)creationCursor
{
	static NSCursor *cursor = nil;

	if (!cursor) {
		cursor = [[NSCursor allocWithZone:[self zone]] initWithImage:[NSImage imageNamed:@"Pencil"] hotSpot:NSMakePoint(0.0,15.0)];
	}
    return cursor ? cursor : [super creationCursor];
}

- (BOOL)canDrawArrow {
	return (YES == _isPathClosed) ? NO : YES;
}

- (BOOL)isCreating {
	return _isCreating;
}
- (BOOL)isEditing
// SKTGraphicViewのeditingGraphicではうまくいかない。堂々回りになってしまうところがある。 //
{
	return _isEditing;
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

- (BOOL)createWithEvent:(NSEvent *)theEvent inView:(SKTGraphicView *)view withGrid:(SKTGrid *)grid
// - (void)createGraphicOfClass:(Class)graphicClass withEvent:(NSEvent *)event から呼ばれる。 //
{
	CGFloat ox,oy,bx,by;
    NSPoint point = [view convertPoint:[theEvent locationInWindow] fromView:nil];
    BOOL snapsToGrid = (nil != grid) ? [grid isConstraining] : NO;
    BOOL echoToRulers = [[view enclosingScrollView] rulersVisible];
	BOOL alternateFlag = ([theEvent modifierFlags] & NSAlternateKeyMask) ? YES : NO;

	_isCreating = YES; // setBounds: が何度も呼ばれるので、setBounds:の中で_pointsを計算しないようにする為の設定 //
	_isPathClosed = NO;
	if (snapsToGrid)
		point = [grid constrainedPoint:point];
	_createdBounds = NSMakeRect(point.x, point.y, 0.0, 0.0);
    [self setBounds:NSMakeRect(point.x, point.y, 0.0, 0.0)];
	ox = bx = point.x;
	oy = by = point.y;
	if (YES == echoToRulers)
		[view beginEchoingMoveToRulers:[self bounds]];
	[_createdPoints release];
	_createdPoints = [[NSMutableArray allocWithZone:[self zone]] initWithCapacity:10];
	[_points release];
	_points = [[NSMutableArray allocWithZone:[self zone]] initWithCapacity:10];	
    while (1) {
		theEvent = [[view window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask)];
		point = [view convertPoint:[theEvent locationInWindow] fromView:nil];
        if (YES == snapsToGrid)
 			point = [grid constrainedPoint:point];
		[view scrollRectToVisible:NSMakeRect(point.x - 5.0,point.y - 5.0,10.0,10.0)];
        if (echoToRulers)
			[view continueEchoingMoveToRulers:[self bounds]];
		[_createdPoints addObject:[NSValue valueWithPoint:point]];
		[_points addObject:[NSValue valueWithPoint:point]];
		ox = MIN(ox,point.x);
		bx = MAX(bx,point.x);
		oy = MIN(oy,point.y);
		by = MAX(by,point.y);
		[self setBounds:NSMakeRect(ox,oy,fabs(bx - ox),fabs(by - oy))];
		_createdBounds = NSMakeRect(ox,oy,fabs(bx - ox),fabs(by - oy));
		if ([theEvent type] == NSLeftMouseUp) {
			if ((YES == alternateFlag) && (NO == _isPathClosed))
				_isPathClosed = YES;
			break;
		}
	}
	if (YES == echoToRulers)
		[view stopEchoingMoveToRulers];
	_isCreating = NO;
	if ((0.0 < NSWidth(_createdBounds)) || (0.0 < NSHeight(_createdBounds))) {
		return YES;
	}
	else
		return NO;
}

/* - (NSView *)newEditingViewWithSuperviewBounds:(NSRect)superviewBounds view:(NSView *)graphicView
// 何もする必要がないので実装しない。 //
{
	NSLog(@"newEditingViewWithSuperviewBounds _length=%lu",_length);
	return nil;
}
 - (void)finalizeEditingView:(NSView *)editingView view:(NSView *)graphicView
// 何もする必要がないので実装しない。 //
{
	if (nil != editingView)
		NSLog(@"Scribble:finalizeEditingView bounds=%@",NSStringFromRect([editingView bounds]));
	else
		NSLog(@"Scribble:finalizeEditingView editingView is nil.");
} */

- (id)init {
	self = [super init];
	_createdPoints = nil;
	_createdBounds = NSZeroRect;
	_isCreating = NO;
	_isEditing = NO;
	return self;
}
- (void)dealloc {
	[_points release];
	[_createdPoints release];
	[_cachedBezierPath release];
	[super dealloc];
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

- (void)drawAnchorHandles {
}

- (NSBezierPath *)bezierPathForDrawing
{
	NSRect bounds = [self bounds];
    
	if ((0.0 < NSWidth(bounds)) || (0.0 < NSHeight(bounds))) {
		NSAffineTransform *transform = [NSAffineTransform transform];
		NSPoint center = NSMakePoint(NSMidX(bounds),NSMidY(bounds));
		NSBezierPath *path = [NSBezierPath bezierPath];

		[transform translateXBy:NSMidX(bounds) yBy:NSMidY(bounds)];
		[transform rotateByRadians:[self rotateAngle]];
		[transform scaleXBy:(YES == _isFlippedHorizontally) ? -1.0 : 1.0 yBy:(YES == _isFlippedVertically) ? -1.0 : 1.0]; // ここは必須のようだ //
		[transform concat];
		if ((nil != _points) && (1 < [_points count])) {
			NSPoint last;
			NSPoint point = [[_points objectAtIndex:0] pointValue];
			NSPoint start = NSMakePoint(point.x - center.x, point.y - center.y);

			[path moveToPoint:start];
			for (NSValue *pValue in _points) {
				point = [pValue pointValue];
				last = NSMakePoint(point.x - center.x, point.y - center.y);
				[path lineToPoint:last];
			}
			if (YES == _isPathClosed)
				[path closePath];
		}
		if (2 < [_points count]) { // - (BOOL)isContentsUnderPoint:(NSPoint)pointに使うため //
			[_cachedBezierPath release];
			_cachedBezierPath = [path copy];
		}
		else {
			if (nil != _cachedBezierPath) {
				[_cachedBezierPath release];
				_cachedBezierPath = nil; // - (BOOL)isContentsUnderPoint:(NSPoint)point 以外に使い途が無いのでnilにしてしまう。 //
			}
		}
		return path;
	}
	else
		return nil;
}

- (NSBezierPath *)arrowBezierPath:(BOOL)isAtStart
// shadowの状態は継承される。 //
{
    NSBezierPath *path = [NSBezierPath bezierPath];
    NSRect bounds = [self bounds];
    
	if ((nil != _points) && (1 < [_points count]) && ((0.0 < NSWidth(bounds)) || (0.0 < NSHeight(bounds)))) {
		NSPoint center = NSMakePoint(NSMidX(bounds),NSMidY(bounds));
		[self strokeColorSet];
		[[self convertColorSpace:[self strokeColor]] setFill]; // [self fillColorSet]; とすれば矢印の内部がfillColorとなる。 //
		[path setLineWidth:1.0];
		[path setLineJoinStyle:NSMiterLineJoinStyle];
		[path setLineDash:(CGFloat *)NULL count:0 phase:0.0];
		if (SKTArrowNone != [self arrowState]) {
			NSUInteger i;
			double angle;
			NSPoint point,p1,p2;
			if (YES == isAtStart) {
				i = 0;
				point = [[_points objectAtIndex:i] pointValue];
				p1 = NSMakePoint(point.x - center.x, point.y - center.y);
				i++;
				point = [[_points objectAtIndex:i] pointValue];
				for (p2 = NSMakePoint(point.x - center.x, point.y - center.y); (hypot(p2.x - p1.x, p2.y - p1.y) < 7.0) && ([_points count] > i); i++) {
					point = [[_points objectAtIndex:1] pointValue];
					p2 = NSMakePoint(point.x - center.x, point.y - center.y);
				}
				angle = atan2(p1.y - p2.y,p1.x - p2.x);
#ifdef ISFLIPPED
				pdfArrow(nil,p1.x,p1.y,angle,[self strokeWidth],[self lineCap]);
#else
				pdfArrow(nil,[[_points objectAtIndex:0] pointValue].x - center.x,[[_points objectAtIndex:0] pointValue].y - center.y,180.0 * angle * M_1_PI,[self strokeLineWidth],[self lineCap]);
#endif
			}
			else {
				NSInteger pCount = [_points count] - 1;
				point = [[_points objectAtIndex:pCount] pointValue];
				p1 = NSMakePoint(point.x - center.x, point.y - center.y);
				pCount--;
				point = [[_points objectAtIndex:pCount] pointValue];
				for (p2 = NSMakePoint(point.x - center.x, point.y - center.y); (hypot(p2.x - p1.x, p2.y - p1.y) < 7.0) && (pCount >= 0); pCount--) {
					point = [[_points objectAtIndex:pCount] pointValue];
					p2 = NSMakePoint(point.x - center.x, point.y - center.y);
				}
				angle = atan2(p1.y - p2.y,p1.x - p2.x);
#ifdef ISFLIPPED
				pdfArrow(nil,p1.x,p1.y, angle,[self strokeWidth],[self lineCap]);
#else
				pdfArrow(nil,[[_points objectAtIndex:[_points count] - 1] pointValue].x - cente.x,[[_points objectAtIndex:[_points count] - 1] pointValue].y - center.y, 180.0 * angle * M_1_PI,[self strokeLineWidth],[self lineCap]);
#endif
			}
		}
	}
	return path;
}

- (BOOL)isContentsUnderPoint:(NSPoint)point
// 回転移動に対応。 //
{
    if (NO == [self locked]) {
			NSRect bounds = [self bounds];
			double rotateAngle = [self rotateAngle];
			NSPoint center = NSMakePoint(NSMidX(bounds),NSMidY(bounds));
			CGFloat scaleX = (YES == _isFlippedHorizontally) ? -1.0 : 1.0;
			CGFloat scaleY = (YES == _isFlippedVertically) ? -1.0 : 1.0;
			CGFloat x = ((point.x - center.x) * cos(rotateAngle) + (point.y - center.y) * sin(rotateAngle)) / scaleX;
			CGFloat y = (-1.0 * (point.x - center.x) * sin(rotateAngle) + (point.y - center.y) * cos(rotateAngle)) / scaleY;

#ifdef ISFLIPPED
			return (nil != _cachedBezierPath) ? [_cachedBezierPath containsPoint:NSMakePoint(x,y)] : NSPointInRect(NSMakePoint(x,y),NSMakeRect(-0.5 * NSWidth(bounds),-0.5 * NSHeight(bounds),NSWidth(bounds),NSHeight(bounds)));
#else
			return (nil != _cachedBezierPath) ? [_cachedBezierPath containsPoint:NSMakePoint(x,y)] : NSMouseInRect(NSMakePoint(x,y),NSMakeRect(-0.5 * NSWidth(bounds),-0.5 * NSHeight(bounds),NSWidth(bounds),NSHeight(bounds)),NO);
#endif
	}
	else
		return NO;
}

static NSString *SKTPointsSKTDKey = @"ScribblePoints"; // for sktd //
static NSString *SKTCreatedBoundsSKTDKey = @"CreatedBounds"; // for sktd //
static NSString *SKTScribbleFlippedHorizontallyKey = @"ScribbleFlippedHorizontally"; // for sktd //
static NSString *SKTScribbleFlippedVerticallyKey = @"ScribbleFlippedVertically"; // for sktd //
NSString *SKTIsPathClosedKey = @"IsPathClosed"; // sktd 互換 //

- (id)initWithProperties:(NSDictionary *)properties
{
    if (nil != (self = [super initWithProperties:properties])) {
		id obj;

		if (nil != (obj = [properties objectForKey:SKTScribbleIsFlippedHorizontallyKey]))
			_isFlippedHorizontally = [obj boolValue];
		else {
			if (nil != (obj = [properties objectForKey:SKTScribbleFlippedHorizontallyKey])) // for sktd //
				_isFlippedHorizontally = [obj isEqualToString:@"YES"];
			else
				_isFlippedHorizontally = NO;
		}
		if (nil != (obj = [properties objectForKey:SKTScribbleIsFlippedVerticallyKey]))
			_isFlippedVertically = [obj boolValue];
		else {
			if (nil != (obj = [properties objectForKey:SKTScribbleFlippedVerticallyKey])) // for sktd //
				_isFlippedVertically = [obj isEqualToString:@"YES"];
			else
				_isFlippedVertically = NO;
		}
		if (nil != (obj = [properties objectForKey:SKTCreatedPointsKey])) {
			NSMutableArray *array = [NSMutableArray arrayWithCapacity:[obj count]];
			for (NSString *pStr in obj)
				[array addObject:[NSValue valueWithPoint:NSPointFromString(pStr)]];
			[_createdPoints release];
			_createdPoints = [[NSMutableArray allocWithZone:[self zone]] initWithArray:array];
		}
		else {
			if (nil != (obj = [properties objectForKey:SKTPointsSKTDKey])) {
				NSUInteger i;
				NSArray *pointsArray = obj;

				[_createdPoints release];
				_createdPoints = [[NSMutableArray allocWithZone:[self zone]] initWithCapacity:10];
				for (i = 0; i < [pointsArray count] / 2; i++) {
					[_createdPoints addObject:[NSValue valueWithPoint:NSMakePoint([[pointsArray objectAtIndex:2 * i] floatValue], [[pointsArray objectAtIndex:2 * i + 1] floatValue])]];
				}
			}
		}
		if (nil == (obj = [properties objectForKey:SKTCreatedBoundsKey]))
			obj = [properties objectForKey:SKTCreatedBoundsSKTDKey];
		if (nil != obj) {
			_createdBounds = NSRectFromString(obj);
			[self calcNewPoints:NSZeroRect];
		}
		if (nil != (obj = [properties objectForKey:SKTIsPathClosedKey]))
			_isPathClosed = [obj boolValue];
		else
			_isPathClosed = NO;
	}
    return self;
}
- (NSMutableDictionary *)properties
{
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:[_createdPoints count]];
	NSMutableDictionary *properties = [super properties];

    [properties setObject:[NSNumber numberWithBool:_isFlippedHorizontally] forKey:SKTScribbleIsFlippedHorizontallyKey];
    [properties setObject:[NSNumber numberWithBool:_isFlippedVertically] forKey:SKTScribbleIsFlippedVerticallyKey];
	for (NSValue *pValue in _createdPoints)
		[array addObject:NSStringFromPoint([pValue pointValue])];
	[properties setObject:array forKey:SKTCreatedPointsKey];
	[properties setObject:NSStringFromRect(_createdBounds) forKey:SKTCreatedBoundsKey];
	[properties setObject:[NSNumber numberWithBool:_isPathClosed] forKey:SKTIsPathClosedKey];
	return properties;
}

- (id)copyWithZone:(NSZone *)zone {
    SKTScribble *copy = [super copyWithZone:zone];

    copy->_isFlippedHorizontally = _isFlippedHorizontally;
    copy->_isFlippedVertically = _isFlippedVertically;
	copy->_createdPoints = [_createdPoints copy];
	copy->_isPathClosed = _isPathClosed;
    return copy;
}

- (NSSet *)keysForValuesToObserveForUndo {
	NSMutableSet *keys = [[super keysForValuesToObserveForUndo] mutableCopy];
	[keys addObject:SKTScribbleIsFlippedHorizontallyKey];
	[keys addObject:SKTScribbleIsFlippedVerticallyKey];
	return [keys autorelease];
}

+ (NSString *)presentablePropertyNameForKey:(NSString *)key
{
	static NSDictionary *presentablePropertyNamesByKey = nil;
	
	if (nil == presentablePropertyNamesByKey)
		presentablePropertyNamesByKey = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
			NSLocalizedStringFromTable(@"Horizontal Flipping", @"UndoStrings", @""), SKTScribbleIsFlippedHorizontallyKey,
			NSLocalizedStringFromTable(@"Vertical Flipping", @"UndoStrings",@""), SKTScribbleIsFlippedVerticallyKey,
			NSLocalizedStringFromTable(@"WindingRule", @"UndoStrings",@""),SKTWindingRuleKey, nil];
	NSString *presentablePropertyName = [presentablePropertyNamesByKey objectForKey:key];
	if (nil == presentablePropertyName)
		presentablePropertyName = [super presentablePropertyNameForKey:key];
	return presentablePropertyName;
}

- (NSArray *)svgXMLElements:(NSRect)aRect name:(NSString *)unique_ID
// ここは_createdPointsを使う必要はない。総て_pointsのみ。 //
{
	NSRect bounds = [self bounds];
	NSMutableArray *elements = [NSMutableArray arrayWithObject:[NSXMLNode commentWithStringValue:NSStringFromClass([self class])]];

	if ((0.0 < NSWidth(bounds)) || (0.0 < NSHeight(bounds))) {
		NSPoint center = NSMakePoint(NSMidX(bounds),NSMidY(bounds));
		BOOL shadowFlag = (0.1 > [self shadowBlurRadiusValue]) ? NO : YES;
		NSArray *defsAndRect = [self svgDefsAndRect:unique_ID allGraphics:NSZeroRect bounds:bounds transform:nil];
		if (0 < [defsAndRect count])
			[elements addObjectsFromArray:defsAndRect];
		CGFloat translateX = NSMidX(bounds) - NSMinX(aRect);
		CGFloat translateY = NSMidY(bounds) - NSMinY(aRect);
		NSMutableString *transformStr = [NSMutableString stringWithFormat:@"translate(%g %g) rotate(%g)",translateX,translateY,180.0 * [self rotateAngle] * M_1_PI];
		CGFloat scaleX = (YES == _isFlippedHorizontally) ? -1.0 : 1.0;
		CGFloat scaleY = (YES == _isFlippedVertically) ? -1.0 : 1.0;
		[transformStr appendFormat:@" scale(%g %g)",scaleX,scaleY];
		if ((nil != _points) && (1 < [_points count])) {
			NSXMLElement *element; 
			NSMutableArray *attributes;
			NSUInteger i;
			NSPoint last;
			NSPoint point = [[_points objectAtIndex:0] pointValue];
			NSPoint start = NSMakePoint(point.x - center.x,point.y - center.y);
			NSMutableString *coordStr = [NSMutableString stringWithFormat:@"%g %g",start.x,start.y];
			NSArray *fillAndStrokeAttributes = [self svgFillAndStrokeAttributes:unique_ID];

			for (i = 1; i < [_points count]; i++) {
				point = [[_points objectAtIndex:i] pointValue];
				last = NSMakePoint(point.x - center.x, point.y - center.y);
				[coordStr appendFormat:@" %g %g",last.x,last.y];
			}
			if (YES == _isPathClosed)
				element = [[NSXMLElement allocWithZone:[self zone]] initWithName:@"polygon"];
			else
				element = [[NSXMLElement allocWithZone:[self zone]] initWithName:@"polyline"]; // isDrawingFillのときは閉じたpathになっていなくても良い。 //
			attributes = [NSMutableArray arrayWithObjects:[NSXMLNode attributeWithName:@"transform" stringValue:transformStr],nil];
			[attributes addObjectsFromArray:fillAndStrokeAttributes];
			if (YES == [self isDrawingStroke]) {
				[attributes addObject:svgStrokeWidthNode([self strokeWidth])];
				[attributes addObject:svgLineJoinNode([self lineJoin])];
				[attributes addObject:svgLineCapNode([self lineCap])];
				[attributes addObjectsFromArray:(0 < [[self lineDashPattern] count]) ? svgDashArrayNodes([self lineDashPattern],[self lineDashPhase]) : svgDashArrayNodes(nil,0.0)];
			}
			[attributes addObject:[NSXMLNode attributeWithName:@"points" stringValue:coordStr]];
			if (YES == shadowFlag)
				[attributes addObject:[NSXMLNode attributeWithName:@"filter" stringValue:[NSString stringWithFormat:@"url(#shadow_%@)",unique_ID]]];
			[element setAttributes:attributes];
			[elements addObject:element];
			[element release];
			if (SKTArrowNone != [self arrowState]) {
				double angle;
				NSPoint p1,p2;
					
				element = [[NSXMLElement allocWithZone:[self zone]] initWithName:@"g"];
				attributes = [NSMutableArray arrayWithObject:svgTransformNode(translateX,translateY,[self rotateAngle],scaleX,scaleY)];
				[attributes addObjectsFromArray:svgColorNodes(unique_ID,@"fill",@"stroke",[self strokeColor])];
				[attributes addObject:svgFillRuleNode(NSNonZeroWindingRule)];
				[attributes addObjectsFromArray:svgColorNodes(unique_ID,@"stroke",@"stroke",nil)];
				if (YES == shadowFlag)
					[attributes addObject:[NSXMLNode attributeWithName:@"filter" stringValue:[NSString stringWithFormat:@"url(#shadow_%@)",unique_ID]]];
				[element setAttributes:attributes];
				[element addChild:[NSXMLNode commentWithStringValue:[NSString stringWithFormat:@"%@/arrow",NSStringFromClass([self class])]]];
				if ([self arrowState] & SKTArrowOnStart) {
					i = 0;
					point = [[_points objectAtIndex:i] pointValue];
					p1 = NSMakePoint(point.x - center.x, point.y - center.y);
					i++;
					point = [[_points objectAtIndex:i] pointValue];
					for (p2 = NSMakePoint(point.x - center.x, point.y - center.y); (hypot(p2.x - p1.x, p2.y - p1.y) < 7.0) && ([_points count] > i); i++) {
						point = [[_points objectAtIndex:i] pointValue];
						p2 = NSMakePoint(point.x - center.x, point.y - center.y);
					}
					angle = atan2(p1.y - p2.y,p1.x - p2.x);
					[element addChild:svgArrowElement([self strokeColor],p1.x,p1.y,angle,[self strokeWidth],[self lineCap])];
				}
				if ([self arrowState] & SKTArrowOnEnd) {
					NSInteger pCount = [_points count] - 1;
					point = [[_points objectAtIndex:pCount] pointValue];
					p1 = NSMakePoint(point.x - center.x, point.y - center.y);
					pCount--;
					point = [[_points objectAtIndex:pCount] pointValue];
					for (p2 = NSMakePoint(point.x - center.x, point.y - center.y); (hypot(p2.x - p1.x,p2.y - p1.y) < 7.0) && (pCount >= 0); pCount--) {
						point = [[_points objectAtIndex:pCount] pointValue];
						p2 = NSMakePoint(point.x - center.x, point.y - center.y);
					}
					angle = atan2(p1.y - p2.y,p1.x - p2.x);
					[element addChild:svgArrowElement([self strokeColor],p1.x,p1.y,angle,[self strokeWidth],[self lineCap])];
				}
				[elements addObject:element];
				[element release];
			}
		}
		return elements;
	}
	else
		return nil;
}

@end
