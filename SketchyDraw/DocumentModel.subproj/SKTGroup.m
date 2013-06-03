//
//  SKTGroup.m
//  Sketch
//
//  Created by me on Wed May 16 2001.
//  Copyright (c) 2001 SatoAkira. All rights reserved.
//
// paste できないバグがある。 //

#import "SKTGroup.h"
#import "SKTGraphicView.h"	// for ISFLIPPED //
#import "SKTFoundationExtras.h" // for atan3() //

@implementation SKTGroup

NSRect groupRotateRect(NSRect bounds,NSRect lastrect,double lastangle,SKTGraphic *component,CGFloat sx,CGFloat sy,double angle)
{
	NSRect b;
	double tx,ty,aa,rr;

	b = [component bounds];
	tx = NSMidX(b) - NSMidX(lastrect);
	ty = NSMidY(b) - NSMidY(lastrect);
	aa = atan3(ty,tx);
	rr = hypot(ty,tx);
	b.origin.x += rr * cos(aa - lastangle) - tx; // 回転が無かったときのb.originを再現する。 //
	b.origin.y += rr * sin(aa - lastangle) - ty;
	tx = (NSMidX(b) - NSMidX(lastrect)) * sx; // 回転が無いときの中心の離れ //
	ty = (NSMidY(b) - NSMidY(lastrect)) * sy;
	b.size.width *= sx;
	b.size.height *= sy;
	b.origin.x = NSMidX(bounds) - 0.5 * NSWidth(b) + (tx * cos(angle) - ty * sin(angle));
	b.origin.y = NSMidY(bounds) - 0.5 * NSHeight(b) + (tx * sin(angle) + ty * cos(angle));
	return b;
}

- (id)initList:(NSArray *)list
{
	NSRect r;
	SKTArrowState arrowState = SKTArrowNone;
	NSRect bounds = NSZeroRect;
	NSEnumerator *enumerator = [list reverseObjectEnumerator];

	self = [super init];
	for (SKTGraphic *graphic in enumerator) {
		r = rotateRect([graphic bounds], [graphic rotateAngle]);
		if (YES == NSEqualRects(NSZeroRect, bounds)) {
			bounds = r;
			arrowState = [graphic arrowState];
			[self setValue:[NSNumber numberWithBool:YES] forKey:SKTGraphicIsDrawingStrokeKey];
			[self setValue:[NSNumber numberWithFloat:[graphic strokeWidth]] forKey:SKTGraphicStrokeWidthKey];
		}
		else { // NSUnionRect()の考え方と違うので使うべきでない。片一方の領域のうち幅・高さのどちらかが0のとき計算不能になるからである。OpenStepのDrawでは1.0を吹かしてNSUnionRect()でやっていた。領域とかで考えるのでなく、位置として考えた方が良い。 //
			bounds.size.width = MAX(NSMaxX(bounds), NSMaxX(r)) - MIN(NSMinX(bounds),NSMinX(r));
			bounds.size.height = MAX(NSMaxY(bounds), NSMaxY(r)) - MIN(NSMinY(bounds),NSMinY(r));
			bounds.origin.x = MIN(NSMinX(bounds),NSMinX(r));
			bounds.origin.y = MIN(NSMinY(bounds),NSMinY(r));
			if ([graphic arrowState] & SKTArrowOnStart) {
				if (!(arrowState & SKTArrowOnStart))
					arrowState += SKTArrowOnStart;
			}
			if ([graphic arrowState] & SKTArrowOnEnd) {
				if (!(arrowState & SKTArrowOnEnd))
					arrowState += SKTArrowOnEnd;
			}
			if ([self strokeWidth] < [graphic strokeWidth])
				[self setValue:[NSNumber numberWithFloat:[graphic strokeWidth]] forKey:SKTGraphicStrokeWidthKey];
		}
	}
	[self setValue:[NSNumber numberWithInteger:arrowState] forKey:SKTArrowStateKey];
	[self setBounds:bounds];
	_components = [[NSMutableArray allocWithZone:[self zone]] initWithArray:list];
	_lastRect = bounds;
	_lastAngle = [self rotateAngle];
	_isDrawingStroke = NO;
	return self;
}

- (id)copyWithZone:(NSZone *)zone {
    id newObj = [super copyWithZone:zone];

	[newObj setComponents:_components];
	[newObj setLastRect:_lastRect];
	[newObj setLastAngle:_lastAngle];
	return newObj;
}
- (void)setComponents:(NSArray *)newArray
{
	[_components release];
	_components = [[NSMutableArray allocWithZone:[self zone]] initWithArray:newArray];
}
- (void)setLastRect:(NSRect)newRect
{
	_lastRect = newRect;
}
- (void)setLastAngle:(double)newAngle
{
	_lastAngle = newAngle;
}

- (NSArray *)components
{
	return _components;
}

- (void)dealloc
{
	[_components release];
	[super dealloc];
}

- (BOOL)canSetDrawingStroke {
    return NO;
}
- (BOOL)canDrawLineJoin {
	return NO;
}
- (BOOL)canDrawLineCap {
	return NO;
}
- (BOOL)canDrawArrow {
	return NO;
}
- (BOOL)canDrawDash {
    return NO;
}
- (NSRect)drawingBounds
// _componentsの中にshadowが無ければ、superのdrawingBoundsのままで良い。 //
{
	double gRotate;
	NSRect sDrawingBounds = [super drawingBounds]; // drawContentsInView:isBeingCreateOrEdited:でchanged,changedSizeをチェックしているが、ここではチェックしない。表示が遅れることもあるが、そのままにしておく。 //
	double rotateAngle = [self rotateAngle];

	for (SKTGraphic *g in _components) {
		gRotate = [g rotateAngle];
		[g setValue:[NSNumber numberWithDouble:rotateAngle + gRotate] forKey:SKTRotateAngleKey];
		sDrawingBounds = NSUnionRect(sDrawingBounds, [g drawingBounds]);
		[g setValue:[NSNumber numberWithDouble:gRotate] forKey:SKTRotateAngleKey]; // 個々の回転角に戻す。 //
	}
	return sDrawingBounds;
}

- (void)drawContentsInView:(NSView *)view isBeingCreateOrEdited:(BOOL)isBeingCreatedOrEditing
{
	NSRect bounds = [self bounds];

	if (((0.0 < NSWidth(bounds)) || (0.0 < NSHeight(bounds))) && (nil != _components)) {
		NSInteger i;
		SKTGraphic *g;
		CGFloat sx,sy;
		double gRotate;
		double rotateAngle = [self rotateAngle];
		BOOL shadowFlag = (0.1 > [self shadowBlurRadiusValue]) ? NO : YES;
		BOOL changedSize = NSWidth(_lastRect) != NSWidth(bounds) || NSHeight(_lastRect) != NSHeight(bounds);
		BOOL changed = changedSize || NSMinX(_lastRect) != NSMinX(bounds) || NSMinY(_lastRect) != NSMinY(bounds) || _lastAngle != [self rotateAngle];
		NSGraphicsContext *currentContext = [NSGraphicsContext currentContext];

		if (YES == [self isDrawingFill]) {
			NSRect fillRect = NSMakeRect(-0.5 * NSWidth(bounds),-0.5 * NSHeight(bounds),NSWidth(bounds), NSHeight(bounds));
			NSBezierPath *fillPath = [NSBezierPath bezierPathWithRect:fillRect];
			NSAffineTransform *fillTransform = [NSAffineTransform transform];

			[currentContext saveGraphicsState]; // translate,rotate無しの状態を保存する。 //
			[fillTransform translateXBy:NSMidX(bounds) yBy:NSMidY(bounds)];
			if (0.0 != rotateAngle)
				[fillTransform rotateByRadians:rotateAngle];
			[fillTransform concat];
			if ((YES == [self shading]) || (YES == [[[self fillColor] colorSpaceName] isEqualToString:NSPatternColorSpace])) {
				if (YES == shadowFlag) {
					[currentContext saveGraphicsState];
					[self shadowSet];
					[[NSColor whiteColor] setFill];
					[fillPath fill];
					[currentContext restoreGraphicsState];
				}
				if (YES == [self shading]) {
					[self drawShading:fillPath transform:nil];
				}
				else {
					ASPatternModel *pModel = [self patternModel];
					[pModel setBounds:bounds clip:fillPath transform:nil colorSpace:[self colorSpace] winding:[self windingRule]];
					[pModel fill];
				}
			}
			else {
				if (YES == shadowFlag) {
					[currentContext saveGraphicsState];
					[self shadowSet];
					[self fillColorSet];
					[fillPath setWindingRule:[self windingRule]];
					[fillPath fill];
					[currentContext restoreGraphicsState];
				}
				else {
					[self fillColorSet];
					[fillPath fill]; // [path closePath]されていなくても正しくfillされる。 //
				}				
			}
			[currentContext restoreGraphicsState]; // translate,rotate無しの状態にする。 //
		}
		// else fillが無いときは、個々にshadowを付けると不自然になってしまうので強制的にshadowを消す。以後groupに関しては、shadowに関することを何もしないのでNOにしなくても良い。 //
		if (YES == changedSize) {
			sx = NSWidth(bounds) / NSWidth(_lastRect);
			sy = NSHeight(bounds) / NSHeight(_lastRect);
		}
		else
			sx = sy = 1.0;
		i = [_components count];
		while (i-- > 0) {
			[currentContext saveGraphicsState]; // translate,rotate無しの状態を保存する。 //
			g = [_components objectAtIndex:i];
			gRotate = [g rotateAngle];
			/* [g setRotateAngle:[NSNumber numberWithDouble:rotateAngle + gRotate]]; // 回転角を与える。 // */
			[g setValue:[NSNumber numberWithDouble:rotateAngle + gRotate] forKey:SKTRotateAngleKey]; // 回転角を与える。 //
			if (YES == changed) { // ここでGraphicViewの座標系の回転角が0度のときの座標値を与える //
				[g setBounds:groupRotateRect(bounds,_lastRect,_lastAngle,g,sx,sy,rotateAngle)];
			}
			[g drawContentsInView:view isBeingCreateOrEdited:NO];
			[g setValue:[NSNumber numberWithDouble:gRotate] forKey:SKTRotateAngleKey]; // 個々の回転角に戻す。 //
			[currentContext restoreGraphicsState]; // translate,rotate無しの状態にする。 //
		}
		if (YES == changed) {
			_lastRect = bounds;
			_lastAngle = rotateAngle;
		}
		NSAffineTransform *transform = [NSAffineTransform transform]; // fillTransformとは別にここで初期化しなければならない。 //
		[transform translateXBy:NSMidX(bounds) yBy:NSMidY(bounds)];
		[transform rotateByRadians:[self rotateAngle]];
		[transform concat]; // translate,rotate付きの状態で終了する。 //
	}
}

- (BOOL)isContentsUnderPoint:(NSPoint)point
 // Groupを構成しているそれぞれのGraphicに - (BOOL)hitTest: を送るので、ここでは回転による座標変換をしてはならない。 //
{
    if (NO == [self locked]) {
			NSUInteger i;
			BOOL result;
			NSRect bounds = [self bounds];
			NSUInteger c = [_components count];
			NSPoint p = NSMakePoint(((point.x - NSMinX(bounds)) / NSWidth(bounds)) * NSWidth(_lastRect) + NSMinX(_lastRect),((point.y - NSMinY(bounds)) / NSHeight(bounds)) * NSHeight(_lastRect) + NSMinY(_lastRect));

			for (result = NO, i = 0; (i < c) && (NO == result); i++)
				result = [[_components objectAtIndex:i] isContentsUnderPoint:p ];
			return result;
	}
	else
		return NO;
}

NSString *SKTComponentsKey = @"Components";
/* NSString *SKTDontCacheKey = @"DontCache"; */
NSString *SKTLastPositionKey = @"LastPosition";

- (NSSet *)keysForValuesToObserveForUndo {
	NSMutableSet *keys = [[super keysForValuesToObserveForUndo] mutableCopy];
	[keys addObject:SKTComponentsKey];
	[keys addObject:SKTLastPositionKey];
	return [keys autorelease];
}

+ (NSString *)presentablePropertyNameForKey:(NSString *)key
{
	static NSDictionary *presentablePropertyNamesByKey = nil;
	
	if (!presentablePropertyNamesByKey)
		presentablePropertyNamesByKey = [[NSMutableDictionary alloc] initWithObjectsAndKeys:NSLocalizedStringFromTable(@"Components", @"UndoStrings", @""), SKTComponentsKey,NSLocalizedStringFromTable(@"LastPosition", @"UndoStrings",@""), SKTLastPositionKey,nil];
	NSString *presentablePropertyName = [presentablePropertyNamesByKey objectForKey:key];
	if (!presentablePropertyName)
		presentablePropertyName = [super presentablePropertyNameForKey:key];
	return presentablePropertyName;
}

- (NSMutableDictionary *)properties
{
    NSMutableDictionary *properties = [super properties];
	NSMutableArray *componentsProperties = [NSMutableArray array];
	
	for (SKTGraphic *graphic in _components)
		[componentsProperties addObject:[graphic properties]];
	[properties setObject:[SKTGraphic propertiesWithGraphics:_components] forKey:SKTComponentsKey];
	[properties setObject:NSStringFromRect(_lastRect) forKey:SKTLastPositionKey];
    return properties;
}

- (id)initWithProperties:(NSDictionary *)properties {
	if (nil != (self = [super initWithProperties:properties])) {
		id obj;
		if (nil != (obj = [properties objectForKey:SKTComponentsKey])) {
			[_components release];
			if (nil != [[obj objectAtIndex:0] objectForKey:SKTGraphicClassNameKey]) {
				_components = [[NSMutableArray alloc] initWithArray:[SKTGraphic graphicsWithProperties:obj]];
			}
			else {
				if (nil != [[obj objectAtIndex:0] objectForKey:@"Class"]) { // SKTClassNameKey. for sktd //
					_components = [[NSMutableArray alloc] initWithArray:[SKTGraphic graphicsWithProperties_sktd:obj]];
				}
				else
					_components = nil;
			}
		}
		if (nil != (obj = [properties objectForKey:SKTLastPositionKey]))
			_lastRect = NSRectFromString(obj);
		_lastAngle = [self rotateAngle]; // super loadPropertyListRepresentation:によって既にrotateAngleが取り込まれている。 //
		_isDrawingStroke = NO;
	}
	return self;
}

- (NSArray *)svgXMLElements:(NSRect)aRect name:(NSString *)unique_ID
{
	NSRect bounds = [self bounds];
	
	if ((0.0 < NSWidth(bounds)) || (0.0 < NSHeight(bounds))) {
		NSMutableArray *elements = [NSMutableArray arrayWithObject:[NSXMLNode commentWithStringValue:NSStringFromClass([self class])]];
		NSArray *defsAndRect = [self svgDefsAndRect:unique_ID allGraphics:aRect bounds:bounds transform:nil];
		if (0 < [defsAndRect count])
			[elements addObjectsFromArray:defsAndRect];
		SKTGraphic *g;
		NSArray *childElements;
		double gRotate;
		double rotateAngle = [self rotateAngle];
		NSUInteger i = [_components count];
		NSXMLElement *element = [NSXMLElement elementWithName:@"g"];
		NSMutableArray *children = [NSMutableArray array];
		
		while (0 < i) {
			g = [_components objectAtIndex:--i];
			gRotate = [g rotateAngle];
			[g setValue:[NSNumber numberWithDouble:rotateAngle + gRotate] forKey:SKTRotateAngleKey]; // 回転角を与える。 //
			if (nil != (childElements = [g svgXMLElements:aRect name:[NSString stringWithFormat:@"%@_%lu",unique_ID,i]]))
				[children addObjectsFromArray:childElements];
			[g setValue:[NSNumber numberWithDouble:gRotate] forKey:SKTRotateAngleKey]; // 個々の回転角に戻す。 //
		}
		[element setChildren:children];
		[elements addObject:element];
		return elements;
	}
	else
		return nil;
}

@end
