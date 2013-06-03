//
//  SKTPolygon.m
//  Sketch
//
//  Created by me on Sat Apr 28 2001.
//  Copyright (c) 2001 SatoAkira. All rights reserved.
//
// - (NSView *)newEditingViewWithSuperviewBounds:(NSRect)superviewBounds がnilを返さないことが他の物と大きく異なる。新規作成は- (BOOL)createWithEvent:(NSEvent *)theEvent inView:(SKTGraphicView *)view withGrid:(SKTGrid *)grid で、編集は- (BOOL)editWithEvent:(NSEvent*)theEvent inView:(SKTGraphicView *)view withGrid:(SKTGrid *)grid。 //
// 拡大・縮小・フリップはSKTGraphic.mのresizeByMovingHandle:で行われる。ここで座標値変更をすることはできない。サイズが極端に小さくなった時に座標値がすべて同じになってしまうからである。setBounds:をオーバーライドして対応する。縦横移動もsetBounds:をオーバーライドして対応する。 //

#import "SKTPolygon.h"
#import "SKTGrid.h"

static CGFloat	SKTPolygonHandleWidthHalf = 2.0;
NSString *SKTPolygonDrawingContentsKey = @"polygonDrawingContents";

@implementation SKTPolygon

#define POLYGON_MASK (NSLeftMouseDraggedMask | NSLeftMouseUpMask)
#define END_POLYGON_MASK (NSAppKitDefinedMask | NSLeftMouseDownMask | NSApplicationDefinedMask)

+ (NSCursor *)creationCursor {
    return [SKTGraphic creationCursor];
}

- (NSUInteger)pointUnderPoint:(NSPoint)point
// ここの_pointsは_createdPointsではない。 //
{
	NSUInteger i;
	NSPoint	pt;
	NSRect	rect;
	NSUInteger returnValue = NSNotFound;
	
	for (i = 0; i < [_points count]; i++) {
		pt = [[_points objectAtIndex:i] pointValue];
		rect.origin.x = pt.x - (SKTPolygonHandleWidthHalf + 1);
		rect.origin.y = pt.y - (SKTPolygonHandleWidthHalf + 1);
		rect.size.width = (SKTPolygonHandleWidthHalf + 1) * 2 + 1.0;
		rect.size.height = (SKTPolygonHandleWidthHalf + 1) * 2 + 1.0;
        if (YES == NSPointInRect(point, rect)) {
			returnValue = i;
			break;
		}
	}
	return returnValue;
}

- (BOOL)createWithEvent:(NSEvent *)theEvent inView:(SKTGraphicView *)view withGrid:(SKTGrid *)grid
// default implementation tracks until mouseUp: just setting the bounds of the new graphic. //
// マウスドラッグから開始し、3点目以後はマウスクリックでも良い。 //
{
	CGFloat ox,oy,bx,by;
	NSPoint point;
	NSUInteger index;
	BOOL done = NO;
	NSPoint start = [view convertPoint:[theEvent locationInWindow] fromView:nil];
	BOOL snapsToGrid = (nil != grid) ? [grid isConstraining] : NO;
	BOOL echoToRulers = [[view enclosingScrollView] rulersVisible];
	NSRect viewBounds = [view visibleRect];
	NSInteger windowNumber = [theEvent windowNumber];
	BOOL alternateFlag = ([theEvent modifierFlags] & NSAlternateKeyMask) ? YES : NO;

	_isCreating = YES;
	_isPathClosed = NO;
	[self setValue:[NSNumber numberWithDouble:0.0] forKey:SKTRotateAngleKey]; // 回転角は0.0として座標値を計算する。 //
	if (snapsToGrid)
 		start = [grid constrainedPoint:start];
	_createdBounds = NSZeroRect;
	[self setBounds:NSMakeRect(start.x, start.y, 0.0, 0.0)];
	ox = bx = start.x;
	oy = by = start.y;
	if (echoToRulers)
		[view beginEchoingMoveToRulers:[self bounds]];
	index = 0;
	point = start;
	[_createdPoints release];
	_createdPoints = [[NSMutableArray allocWithZone:[self zone]] initWithObjects:[NSValue valueWithPoint:point],nil];
	[_points release];
	_points = [[NSMutableArray allocWithZone:[self zone]] initWithObjects:[NSValue valueWithPoint:point],nil];
	index++;
	theEvent = [[view window] nextEventMatchingMask:POLYGON_MASK];
	while (NO == done) {
		if (NSLeftMouseDown == [theEvent type]) {
			if (1 < [theEvent clickCount]) { // ダブルクリック //
				done = YES;
				if ((YES == alternateFlag) && (NO == _isPathClosed))
					_isPathClosed = YES;
				else {
					index--;
					[_createdPoints removeLastObject];
					[_points removeLastObject];
				}
				[[view window] nextEventMatchingMask:NSLeftMouseUpMask];
			}
			else {
				if (windowNumber != [theEvent windowNumber]) { // 他のwindow上でクリックされた //
					done = YES;
				}
				else {
					point = [view convertPoint:[theEvent locationInWindow] fromView:nil];
					if (snapsToGrid)
						point = [grid constrainedPoint:point];
					if (NO == NSPointInRect(point,viewBounds)) { // viewの範囲外でクリックされた //
						done = YES;
					}
				}
			}
		} // if (NSLeftMouseDown == [theEvent type]) //
		else {
			if ((NSAppKitDefined == [theEvent type]) || (NSSystemDefined == [theEvent type])) {
				done = YES;
			}
		}
		if (NO == done) {
			while (NSLeftMouseUp != [theEvent type]) { // すなわちドラッグ中 //
				point = [view convertPoint:[theEvent locationInWindow] fromView:nil];
				if (snapsToGrid)
					point = [grid constrainedPoint:point];
				[view scrollRectToVisible:NSMakeRect(point.x - 5.0,point.y - 5.0,10.0,10.0)];
				if (YES == echoToRulers)
					[view continueEchoingMoveToRulers:[self bounds]];
				if (index >= [_createdPoints count]) {
					[_createdPoints addObject:[NSValue valueWithPoint:point]];
					[_points addObject:[NSValue valueWithPoint:point]];
				}
				else {
					[_createdPoints replaceObjectAtIndex:index withObject:[NSValue valueWithPoint:point]];
					[_points replaceObjectAtIndex:index withObject:[NSValue valueWithPoint:point]];
				}
				ox = MIN(ox,point.x);
				bx = MAX(bx,point.x);
				oy = MIN(oy,point.y);
				by = MAX(by,point.y);
				_createdBounds = NSMakeRect(ox,oy,fabs(bx - ox),fabs(by - oy));
				[self setBounds:_createdBounds];
				theEvent = [[view window] nextEventMatchingMask:POLYGON_MASK];
				// _pointsはまだ確定されていない。 //
			} // while (NSLeftMouseUp != type) //
			// 下の判断を入れると、最初がマウスドラッグでない場合に、このメソッドの最終のreturnへ飛ぶようになる。入れないと、閉じたパスを作れなくなる。 //
			if (0 == [self pointUnderPoint:point]) {
				done = YES;
				_isPathClosed = YES;
				index++;
			}
		} // if (NO == done) //
		if ((NO == done) || ((YES == _isPathClosed) && (1 < index))) {
			if (YES == _isPathClosed) {
				point = [[_createdPoints objectAtIndex:0] pointValue];
				index--;
			}
			[view scrollRectToVisible:NSMakeRect(point.x - 5.0,point.y - 5.0,10.0,10.0)];
			if (YES == echoToRulers)
				[view continueEchoingMoveToRulers:[self bounds]];
			if (index >= [_createdPoints count]) {
				[_createdPoints addObject:[NSValue valueWithPoint:point]];
				[_points addObject:[NSValue valueWithPoint:point]];
			}
			else {
				[_createdPoints replaceObjectAtIndex:index withObject:[NSValue valueWithPoint:point]];
				[_points replaceObjectAtIndex:index withObject:[NSValue valueWithPoint:point]];
			}
			index++; // _createdPoints,_pointsは確定された。 //
			ox = MIN(ox,point.x);
			bx = MAX(bx,point.x);
			oy = MIN(oy,point.y);
			by = MAX(by,point.y);
			_createdBounds = NSMakeRect(ox,oy,fabs(bx - ox),fabs(by - oy));
			[self setBounds:_createdBounds];
			if (NO == done)
				theEvent = [[view window] nextEventMatchingMask:END_POLYGON_MASK];
		}
	} // while (NO == done) //
	if (1 < index) {
		if (YES == _isPathClosed) {
			index--;
			[_createdPoints removeLastObject]; // ダブルクリックされたpointを抜いてしまう。 //
			[_points removeLastObject]; // ダブルクリックされたpointを抜いてしまう。 //
		}
		ox = bx = start.x;
		oy = by = start.y;
		for (NSValue *pointObj in _createdPoints) {
			point = [pointObj pointValue];
			ox = MIN(ox,point.x);
			bx = MAX(bx,point.x);
			oy = MIN(oy,point.y);
			by = MAX(by,point.y);
		}
		_createdBounds = NSMakeRect(ox,oy,fabs(bx - ox),fabs(by - oy));
		[self setBounds:_createdBounds];
	}
	if (YES == echoToRulers)
        [view stopEchoingMoveToRulers];
	return YES;
}

- (void)drawAnchorHandles
{
	NSUInteger i;
	NSPoint point,pt;
	NSRect rect = NSMakeRect(0.0,0.0,SKTPolygonHandleWidthHalf * 2 + 1.0,SKTPolygonHandleWidthHalf * 2 + 1.0);
	NSRect bounds = [self bounds];
	NSPoint center = NSMakePoint(NSMidX(bounds),NSMidY(bounds));

	for (i = 0; i < [_points count]; i++) {
		if (YES == [self isCreating]) {
			pt = [[_points objectAtIndex:i] pointValue];
			point = NSMakePoint(pt.x - center.x,pt.y - center.y);
			rect.origin = NSMakePoint(point.x - SKTPolygonHandleWidthHalf,point.y - SKTPolygonHandleWidthHalf);
			[[NSColor blackColor] set];
			NSRectFill(rect);
		}
		else {
			if (YES == _isEditing) {
				pt = [[_points objectAtIndex:i] pointValue];
				point = NSMakePoint(pt.x - center.x,pt.y - center.y);
				rect.origin = NSMakePoint(point.x - SKTPolygonHandleWidthHalf,point.y - SKTPolygonHandleWidthHalf);
				[[NSColor whiteColor] set];
				NSRectFill(rect);
				[[NSColor blackColor] set];
				NSFrameRect(rect);
				if ((i == _selectedPointIndex) && (NSNotFound != _selectedPointIndex)) {
					if (YES == _isPathClosed)
						[[NSColor orangeColor] set];
					else
						[[NSColor redColor] set];
					NSRectFill(NSInsetRect(rect, 1.0, 1.0));
				}
			}
		}
	}
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
		// The invoker doesn't have to release this object.
		/* return [editorView autorelease]; */
		return _editingView;
	}
}

- (void)movePoint:(NSUInteger)index toPoint:(NSPoint)point
{
	NSPoint pt;
	CGFloat maxX = -1.0 * MAXFLOAT;
	CGFloat maxY = -1.0 * MAXFLOAT;
	CGFloat minX = MAXFLOAT;
	CGFloat minY = MAXFLOAT;

	[_points replaceObjectAtIndex:index withObject:[NSValue valueWithPoint:point]];
	[_createdPoints replaceObjectAtIndex:index withObject:[NSValue valueWithPoint:point]];
	for (NSValue *pointObj in _points) {
		pt = [pointObj pointValue];
		maxX = MAX(maxX,pt.x);
		maxY = MAX(maxY,pt.y);
		minX = MIN(minX,pt.x);
		minY = MIN(minY,pt.y);
	}
	_createdBounds = NSMakeRect(minX,minY,maxX - minX,maxY - minY);
}
- (BOOL)editWithEvent:(NSEvent*)theEvent inView:(SKTGraphicView *)view withGrid:(SKTGrid *)grid
{
	NSRect bounds = [self bounds];
	NSPoint center = NSMakePoint(NSMidX(bounds), NSMidY(bounds));
	double r = [self rotateAngle]; // 通常は回転移動が無い状態で編集モードになるので0.0になるのが普通である。undoを複数回実行すると回転角がもとの状態に戻ってそのまま編集モードに居ると回転角が与えられた状態での編集となるので回転角の調整は必要である。 //
	NSPoint mousePoint = [view convertPoint:[theEvent locationInWindow] fromView:nil];
	NSPoint convertedPoint = NSMakePoint((mousePoint.x - center.x) * cos(r) + (mousePoint.y - center.y) * sin(r) + center.x, (mousePoint.y - center.y) * cos(r) - (mousePoint.x - center.x) * sin(r) + center.y);
	NSUInteger pointIndex = [self pointUnderPoint:convertedPoint];
    
	if (NSNotFound == pointIndex)
		return NO;
	else {
		_selectedPointIndex = pointIndex;
		if (NSNotFound == _selectedPointIndex)
			return NO;
		else {
			NSPoint point;
			BOOL hasDragged = NO;
			BOOL snapsToGrid = [grid isConstraining];
			NSPoint oldPoint = [[_points objectAtIndex:_selectedPointIndex] pointValue];
			BOOL echoToRulers = [[view enclosingScrollView] rulersVisible];

			while (1) {
				theEvent = [[view window] nextEventMatchingMask:POLYGON_MASK];
				if (NSLeftMouseDragged == [theEvent type]) {
					point = [view convertPoint:[theEvent locationInWindow] fromView:nil];
					if (YES == snapsToGrid)
						point = [grid constrainedPoint:point];
					convertedPoint.x = (point.x - center.x) * cos(r) + (point.y - center.y) * sin(r) + center.x;
					convertedPoint.y = (point.y - center.y) * cos(r) - (point.x - center.x) * sin(r) + center.y;
					[_points replaceObjectAtIndex:_selectedPointIndex withObject:[NSValue valueWithPoint:convertedPoint]];
					hasDragged = YES;
				} // if (NSLeftMouseDragged == [event type]) //
				if ((YES == hasDragged) && (NO == NSEqualPoints(oldPoint,convertedPoint))) {
					[self movePoint:_selectedPointIndex toPoint:convertedPoint]; // ここで_createdPointsが確定される。 //
					if (NO == NSEqualRects([self bounds],_createdBounds))
						[self setBounds:_createdBounds];
					else
						[view setNeedsDisplayInRect:[self drawingBounds]];
					if (echoToRulers)
						[view continueEchoingMoveToRulers:[self bounds]];
				}
				// else 何もしない。 //
				if (NSLeftMouseUp == [theEvent type])
					break;
			} // while(1) //
			if (YES == hasDragged) {
				// 以下はundoの為だけの処理。undoの必要がなければ総て削除しても良い。削除してもmovePoint:toPoint:の中でsetBounds:しているので一応はundoできるが、見た目に戸惑うようになる。 //
				NSRect newBounds = _createdBounds; // convertedPointによる新しいbounds //
				NSMutableArray *newCreatedArray = [NSMutableArray arrayWithArray:_createdPoints]; // convertPointに置き換わった物。 //
				NSMutableArray *newPointsArray = [NSMutableArray arrayWithArray:_points]; // convertPointに置き換わった物。 //

				_createdBounds = bounds; // 元に戻す。 //
				[_createdPoints replaceObjectAtIndex:_selectedPointIndex withObject:[NSValue valueWithPoint:oldPoint]]; // 元に戻す。 //
				[_points replaceObjectAtIndex:_selectedPointIndex withObject:[NSValue valueWithPoint:oldPoint]]; // 元に戻す。 //
				[self setValue:newCreatedArray forKey:SKTCreatedPointsKey]; // convertPointに置き換えた物をsetValueしてundoに対応させる。 //
				[self setValue:newPointsArray forKey:SKTPointsKey]; // convertPointに置き換えた物をsetValueしてundoに対応させる。 //
				if (NO == NSEqualRects(newBounds, bounds))
					[self setValue:[NSValue valueWithRect:newBounds] forKey:SKTCreatedBoundsKey]; // convertPointに置き換えた物をsetValueしてundoに対応させる。 //
				// undoの為の処理終了 //
			}
			else {
				[view setNeedsDisplayInRect:[self drawingBounds]]; // _selectedPointIndexを赤色表示させるため //
				if (YES == echoToRulers)
					[view continueEchoingMoveToRulers:[self bounds]];
			}
			return YES;
		}
	}
}

- (void)finalizeEditingView:(NSView *)editingView view:(NSView *)graphicView { // SatoAkira add. //
	_isEditing = NO;
	_selectedPointIndex = NSNotFound;
	[_editingView release];
	_editingView = nil;
}

- (void)insertForEditingInView:(SKTGraphicView *)view
{
	if ((NSNotFound != _selectedPointIndex) && (0 < [_createdPoints count]) && ([_createdPoints count] > _selectedPointIndex)) {
		NSPoint convert, point = [[_createdPoints objectAtIndex:_selectedPointIndex] pointValue];
		NSRect bounds = [self bounds];
		double r = [self rotateAngle];
		NSPoint center = NSMakePoint(NSMidX(bounds), NSMidY(bounds));
		NSMutableArray *newCreatedArray = [NSMutableArray arrayWithArray:_createdPoints];
		NSMutableArray *newPointsArray = [NSMutableArray arrayWithArray:_points];

		convert.x = (point.x - center.x) * cos(r) + (point.y - center.y) * sin(r) + center.x;
		convert.y = (point.y - center.y) * cos(r) - (point.x - center.x) * sin(r) + center.y;
		[newCreatedArray insertObject:[NSValue valueWithPoint:convert] atIndex:_selectedPointIndex];
		[newPointsArray insertObject:[NSValue valueWithPoint:convert] atIndex:_selectedPointIndex];
		[self setValue:newCreatedArray forKey:SKTCreatedPointsKey];
		[self setValue:newPointsArray forKey:SKTPointsKey];
		_selectedPointIndex++;
	}
}

- (void)deleteForEditingInView:(SKTGraphicView *)view
{
	if ((NSNotFound != _selectedPointIndex) && (2 < [_points count]) && ([_points count] > _selectedPointIndex)) {
		NSPoint pt;
		CGFloat maxX = -1.0 * MAXFLOAT;
		CGFloat maxY = -1.0 * MAXFLOAT;
		CGFloat minX = MAXFLOAT;
		CGFloat minY = MAXFLOAT;
		NSRect newBounds;
		NSMutableArray *newCreatedArray = [NSMutableArray arrayWithArray:_createdPoints];
		NSMutableArray *newPointsArray = [NSMutableArray arrayWithArray:_points];
			
		[newCreatedArray removeObjectAtIndex:_selectedPointIndex];
		[newPointsArray removeObjectAtIndex:_selectedPointIndex];
		for (NSValue *pointObj in newPointsArray) {
			pt = [pointObj pointValue];
			maxX = MAX(maxX,pt.x);
			maxY = MAX(maxY,pt.y);
			minX = MIN(minX,pt.x);
			minY = MIN(minY,pt.y);
		}
		newBounds = NSMakeRect(minX,minY,maxX - minX,maxY - minY);
		if (NO == NSEqualRects(newBounds, [self bounds])) {
			[self setBounds:newBounds];
			[self setValue:[NSValue valueWithRect:newBounds] forKey:SKTCreatedBoundsKey];
		}
		[self setValue:newCreatedArray forKey:SKTCreatedPointsKey];
		[self setValue:newPointsArray forKey:SKTPointsKey];
		_selectedPointIndex = NSNotFound;
		[view setNeedsDisplayInRect:[self drawingBounds]];
	}
}

+ (NSSet *)keyPathsForValuesAffectingDrawingContents
{
	NSMutableSet *keys = [NSMutableSet setWithSet:[super keyPathsForValuesAffectingDrawingContents]];
	[keys addObject:SKTCreatedPointsKey];
	[keys addObject:SKTPointsKey];
	[keys addObject:SKTCreatedBoundsKey];
	return keys;
}
- (NSSet *)keysForValuesToObserveForUndo
{
	NSMutableSet *keys = [[super keysForValuesToObserveForUndo] mutableCopy];
	[keys addObject:SKTCreatedPointsKey];
	[keys addObject:SKTPointsKey];
	[keys addObject:SKTCreatedBoundsKey];
	return [keys autorelease];
}
+ (NSString *)presentablePropertyNameForKey:(NSString *)key
{
	static NSDictionary *presentablePropertyNamesByKey = nil;
	if (nil == presentablePropertyNamesByKey)
		presentablePropertyNamesByKey = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
			NSLocalizedStringFromTable(SKTCreatedPointsKey,@"UndoStrings",@""),SKTCreatedPointsKey,
			NSLocalizedStringFromTable(SKTPointsKey,@"UndoStrings",@""),SKTPointsKey,
			NSLocalizedStringFromTable(SKTCreatedBoundsKey,@"UndoStrings",@""),SKTCreatedBoundsKey,
			nil];
	NSString *presentablePropertyName = [presentablePropertyNamesByKey objectForKey:key];
	if (nil == presentablePropertyName)
		presentablePropertyName = [super presentablePropertyNameForKey:key];
	return presentablePropertyName;
}

@end
