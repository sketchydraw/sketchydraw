//
//  ASPointControlPluginView.m
//  ASPointControlPlugin
//
//  Created by 佐藤昭 on 11/02/05.
//  Copyright 2011 SatoAkira. All rights reserved.
//

#import "ASPointControl.h"
#import "ASPointControlCell.h"

static Class _myStoredCellClass = nil;

@implementation ASPointControl

@synthesize mousePoint;
NSString *ASPointControlMousePointKey = @"mousePoint";

+ (void)initialize
{
	if (self == [ASPointControl class])
		[self setCellClass:[ASPointControlCell class]];
}
+ (Class)cellClass {
	return _myStoredCellClass;
}

+ (void)setCellClass:(Class)classId {
	_myStoredCellClass = classId;
	
}
- (void)resetCursorRects
{
	NSRect visible = [self visibleRect]; // イメージ全体の大きさが返される。 //
	
	if( NO == NSIsEmptyRect(visible) ) {
		[self addCursorRect:visible cursor:theCursor];
		[theCursor setOnMouseEntered:YES]; // YES if the receiver accepts future mouseEntered: event messages; otherwise it ignores them. //
	}
}
- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent {
	// 最初のマウスダウンがあったときに一回だけ呼ばれる //
	return [[self window] makeFirstResponder:self];
}
- (BOOL)resignFirstResponder {
	// 最初にファーストレスポンダでなくなるときに一回だけ呼ばれるが、[self setNeedsDisplay:YES]はその都度実行される。 //
	[self updateCell:[self cell]];
	return YES;
}
- (id)initWithFrame:(NSRect)frameRect
// IBから作られた場合には、ここは呼ばれないのでmousePointを初期化しておかねばならない。 //
{
    BOOL error = (nil == [super initWithFrame:frameRect]);
	
	if (NO == error) {
		Class cellClass = [[self class] cellClass];
		ASPointControlCell *myCell = [[cellClass allocWithZone:[self zone]] initImageCell:nil];
		NSPoint minPoint = [[myCell valueForKey:@"minPoint"] pointValue];
		NSPoint maxPoint = [[myCell valueForKey:@"maxPoint"] pointValue];
		unichar arrows[] = {0xf703,0xf700,0xf702,0xf701}; // 矢印キーは /Uf700~/Uf703 //
		
		[self setCell:myCell];
		mousePoint = NSMakePoint(0.5 * (minPoint.x + maxPoint.x),0.5 * (minPoint.y + maxPoint.y));
		[myCell release];
		[theCursor release];
		theCursor = [[NSCursor crosshairCursor] retain];
		acceptsAllowKeys = YES;
		arrowKeysString = [[NSString alloc] initWithCharacters:arrows length:4];
    }
    return error ? nil : self;
}
- (id)init {
	return [self initWithFrame:NSMakeRect(0.0,0.0,64.0,64.0)];
}
- (void)dealloc {
	[observedObjectForPoint release];
	[observedKeyPathForPoint release];
	[theCursor release];
	[arrowKeysString release];
	[super dealloc];
}
- (id)initWithCoder:(NSCoder *)aDecoder
// IBから作られた場合には、ここだけで初期化する。 //
{
	[super initWithCoder:aDecoder];
	theCursor = [[aDecoder decodeObjectForKey:@"theCursorKey"] retain];
	mousePoint = [aDecoder decodePointForKey:@"mousePointKey"];
	observedObjectForPoint = [[aDecoder decodeObjectForKey:@"observedObjectForPointKey"] retain];
	observedKeyPathForPoint = [[aDecoder decodeObjectForKey:@"observedKeyPathForPointKey"] retain];
	return self; // このあとinitWithFrame:が呼ばれる。 //
}
- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[super encodeWithCoder:aCoder];
	[aCoder encodeObject:theCursor forKey:@"theCursorKey"];
	[aCoder encodePoint:mousePoint forKey:@"mousePointKey"];
	[aCoder encodeObject:observedObjectForPoint forKey:@"observedObjectForPointKey"];
	[aCoder encodeObject:observedKeyPathForPoint forKey:@"observedKeyPathForPointKey"];
}
- (void)keyDown:(NSEvent *)theEvent
{
	if (YES == acceptsAllowKeys) {
		if ((0 == [arrowKeysString rangeOfString:[theEvent charactersIgnoringModifiers]].length) || (NO == [self isEditable]) || (NO == [self isEnabled]))
			[super keyDown:theEvent];
	}
	else
		[super keyDown:theEvent];
}
- (void)keyUp:(NSEvent *)theEvent
{
	if ((YES == acceptsAllowKeys) && (YES == [self isEditable]) && (YES == [self isEnabled])) {
		NSString *aString = [theEvent charactersIgnoringModifiers];
		NSRange arrowRange = [arrowKeysString rangeOfString:aString];
		if (0 < arrowRange.length) {
			NSPoint minPoint = [[self cell] minPoint];
			NSPoint maxPoint = [[self cell] maxPoint];
			NSPoint midPoint = NSMakePoint(0.5 * (minPoint.x + maxPoint.x), 0.5 * (minPoint.y + maxPoint.y));
			NSPoint newPoint = mousePoint;
			switch (arrowRange.location) {
				case 0:
					newPoint.x = (YES == [self horizontalFlipped]) ? (mousePoint.x > midPoint.x) ? midPoint.x : minPoint.x  :  (mousePoint.x >= midPoint.x) ? maxPoint.x : midPoint.x;
					break;
				case 1:
					newPoint.y = (YES == [self verticalFlipped]) ? (mousePoint.y > midPoint.y) ? midPoint.y : minPoint.y  :  (mousePoint.y >= midPoint.y) ? maxPoint.y : midPoint.y;
					break;
				case 2:
					newPoint.x = (YES == [self horizontalFlipped]) ? (mousePoint.x >= midPoint.x) ? maxPoint.x : midPoint.x  :  (mousePoint.x > midPoint.x) ? midPoint.x : minPoint.x;
					break;
				case 3:
					newPoint.y = (YES == [self verticalFlipped]) ? (mousePoint.y >= midPoint.y) ? maxPoint.y : midPoint.y  :  (mousePoint.y > midPoint.y) ? midPoint.y : minPoint.y;
					break;
				default:
					break;
			}
			[self setMousePoint:newPoint]; // KVO //
			[self writeToOutlet];
			if (NO == [self isContinuous])
				[self drawCellInside:[self cell]];				
		}
		else
			[super keyUp:theEvent];
	}
	else
		[super keyUp:theEvent];
}
- (void)setBordered:(BOOL)flag {
	[[self cell] setBordered:flag];
}
- (BOOL)isBordered {
	return [[self cell] isBordered];
}
- (void)setEnabled:(BOOL)flag {
	[[self cell] setEnabled:flag];
}
- (BOOL)isEnabled {
	return [[self cell] isEnabled];
}
- (void)setEditable:(BOOL)flag {
	[[self cell] setEditable:flag];
}
- (BOOL)isEditable {
	return [[self cell] isEditable];
}
- (void)setDrawsTickMark:(BOOL)flag {
	[[self cell] setValue:[NSNumber numberWithBool:flag] forKey:@"drawsTickMark"];
}
- (BOOL)drawsTickMark {
	return [[[self cell] valueForKey:@"drawsTickMark"] boolValue];
}
- (void)setImage:(NSImage *)anImage {
	[[self cell] setImage:anImage];
}
- (NSImage *)image {
	return [[self cell] valueForKey:@"image"];
}
- (void)setHorizontalFlipped:(BOOL)flag {
	[[self cell] setValue:[NSNumber numberWithBool:flag] forKey:@"horizontalFlipped"];
}
- (BOOL)horizontalFlipped {
	return [[[self cell] valueForKey:@"horizontalFlipped"] boolValue];
}
- (void)setVerticalFlipped:(BOOL)flag {
	[[self cell] setValue:[NSNumber numberWithBool:flag] forKey:@"verticalFlipped"];
}
- (BOOL)verticalFlipped {
	return [[[self cell] valueForKey:@"verticalFlipped"] boolValue];
}
- (void)setSquare:(BOOL)flag {
	[[self cell] setSquare:flag];
}
- (BOOL)square {
	return [[self cell] square];
}
- (void)setMinPoint:(NSPoint)aPoint {
	[[self cell] setValue:[NSValue valueWithPoint:aPoint] forKey:@"minPoint"];
}
- (void)setMaxPoint:(NSPoint)aPoint {
	[[self cell] setValue:[NSValue valueWithPoint:aPoint] forKey:@"maxPoint"];
}
- (void)writeToOutlet
{
	if (nil != observedObjectForPoint)
		[observedObjectForPoint setValue:[NSValue valueWithPoint:mousePoint] forKeyPath:observedKeyPathForPoint];
	if (YES == [self isContinuous])
		[self drawCellInside:[self cell]];
}

#pragma mark Binding

static void *PointControlBindContext = (void *)@"PointControl";

- (void)bind:(NSString *)binding toObject:(id)observableObject withKeyPath:(NSString *)keyPath options:(NSDictionary *)options
{
	if (YES == [binding isEqualToString:ASPointControlMousePointKey]) {
		if (![[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.InterfaceBuilder3"]) {
			[observableObject addObserver:self forKeyPath:keyPath options:0 context:PointControlBindContext];
			observedObjectForPoint = [observableObject retain];
			observedKeyPathForPoint = [keyPath copy];
		}
	}
	[super bind:binding toObject:observableObject withKeyPath:keyPath options:options];
}
- (void)unbind:(NSString *)bindingName
{
	if (YES == [bindingName isEqualToString:ASPointControlMousePointKey]) {
		if (![[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.InterfaceBuilder3"]) {
			[observedObjectForPoint release];
			observedObjectForPoint = nil;
			[observedKeyPathForPoint release];
			observedKeyPathForPoint = nil;
		}
	}
	[super unbind:bindingName];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == PointControlBindContext) {
		id newPoint = [observedObjectForPoint valueForKeyPath:observedKeyPathForPoint];
		if ((nil != newPoint) && (YES == [newPoint isKindOfClass:[NSValue class]])) {
			mousePoint = [newPoint pointValue];
			[self drawCellInside:[self cell]];
		}
		// newPointがNSStateMarkerクラスになることが頻繁にある。 //
	}
	else
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

@end
