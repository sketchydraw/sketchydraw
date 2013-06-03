//
//  ASDialKnob.m
//
//  Created by 佐藤昭 on Fri 1-Oct-1999.
//  Copyright (c) 2004 SatoAkira. All rights reserved.
//

#import "ASDialKnob.h"
#import "ASDialKnobCell.h"
#import "ASWebViewFunctions.h" // for UTI() //
#import <libc.h>	// for mktemp() //

#ifndef __APPLE__
void dialKnobCursor();
#endif
static Class _myStoredCellClass = nil;

@implementation ASDialKnob

NSString *ASDialKnobImageRepDidChangeNotification = @"ASDialKnobImageRepDidChange";
NSString *ASDialKnobRotateAngleKey = @"rotateAngle";

#ifdef __APPLE__
static NSBezierPath *dialKnobCursor(void)
{
	NSBezierPath *path = [NSBezierPath bezierPath];

	[NSBezierPath clipRect:NSMakeRect(0.0,0.0,16.0,16.0)];
	/* [path setAlpha:1.0]; */
	[path moveToPoint:NSMakePoint(15.6,8.0)];
	[path appendBezierPathWithArcWithCenter:NSMakePoint(8.0,8.0) radius:7.6 startAngle:0.0 endAngle:360.0];
	[[NSColor whiteColor] set];
	[path setLineWidth:0.8];
	[path stroke];
	[path moveToPoint:NSMakePoint(14.0,8.0)];
	[path appendBezierPathWithArcWithCenter:NSMakePoint(8.0,8.0) radius:6.0 startAngle:0.0 endAngle:360.0];
	[path stroke];
	[path moveToPoint:NSMakePoint(9.0,8.0)];
	[path appendBezierPathWithArcWithCenter:NSMakePoint(8.0,8.0) radius:1.0 startAngle:0.0 endAngle:360.0];
	[path stroke];
	path = [NSBezierPath bezierPath];
	[path moveToPoint:NSMakePoint(14.8,8.0)];
	[path appendBezierPathWithArcWithCenter:NSMakePoint(8.0,8.0) radius:6.8 startAngle:0.0 endAngle:360.0];
	[[NSColor blackColor] set];
	[path setLineWidth:0.8];
	[path stroke];
	[path moveToPoint:NSMakePoint(8.5,8.0)];
	[path appendBezierPathWithArcWithCenter:NSMakePoint(8.0,8.0) radius:0.5 startAngle:0.0 endAngle:360.0];
	[path setLineWidth:0.5];
	[path stroke];
	return path;
}
#endif

+ (void)initialize
{
	if (self == [ASDialKnob class])
		[self setCellClass:[ASDialKnobCell class]];
}

+ (Class)cellClass {
	return _myStoredCellClass;
}

+ (void)setCellClass:(Class)classId {
	_myStoredCellClass = classId;
	
}

+ (NSCursor *)cursor
{
	NSSize cursorSize = NSMakeSize(16.0,16.0);
	NSPoint mySpot = NSMakePoint(8.0,8.0);
	NSImage *cursorImage = [[NSImage allocWithZone:[self zone]] initWithSize:cursorSize];

	[cursorImage lockFocus];
#ifdef __APPLE__
	dialKnobCursor();
#else
	dialKnobCursor();
#endif
	[cursorImage unlockFocus];
	NSCursor *dCursor = [[NSCursor allocWithZone:[self zone]] initWithImage:cursorImage hotSpot:mySpot];
	[cursorImage release];
	return [dCursor autorelease]; // hotSpotでカーソルの中心位置を設定する。 //
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
// 最初のマウスダウンがあったときに一回だけ呼ばれる //
{
	return [[self window] makeFirstResponder:self];
}
- (BOOL)resignFirstResponder
// 最初にファーストレスポンダでなくなるときに一回だけ呼ばれるが、[self setNeedsDisplay:YES]はその都度実行される。 //
{
	[self updateCell:[self cell]];
	return YES;
}
- (void)keyDown:(NSEvent *)theEvent
{
	if (YES == [[theEvent charactersIgnoringModifiers] isEqualToString:@" "]) {
		double deg = ([theEvent modifierFlags] & NSShiftKeyMask) ? ceil([[self cell] degValue] - increment) : floor([[self cell] degValue] + increment);;

		[[self cell] setDEGValue:deg];
		[self updateCellInside:[self cell]];
		[self performClick:nil];
		[self writeToOutlet];
	}
	else {
		if (YES == acceptsArrowKeys) {
			if (0 == [arrowKeysString rangeOfString:[theEvent charactersIgnoringModifiers]].length)
				[super keyDown:theEvent];
		}
		else
			[super keyDown:theEvent];
	}
}
- (void)keyUp:(NSEvent *)theEvent
{
	NSString *aString = [theEvent charactersIgnoringModifiers];

	if ((YES == [aString isEqualToString:@"c"]) || (YES == [aString isEqualToString:@"C"]))
		[[self cell] copy:self];
	else {
		if (YES == acceptsArrowKeys) {
			NSRange arrowRange = [arrowKeysString rangeOfString:aString];
			if (0 < arrowRange.length) {
				if (NO == [[self cell] clockwise])
					[[self cell] setDEGValue:90.0 * arrowRange.location];
				else {
					if (0 == arrowRange.location)
						[[self cell] setDEGValue:0.0];
					else
						[[self cell] setDEGValue:90.0 * (4 - arrowRange.location)];
				}
				[self updateCellInside:[self cell]];
				[self performClick:nil];
				[self writeToOutlet];
			}
			else
				[super keyUp:theEvent];
		}
		else
			[super keyUp:theEvent];
	}
}

- (id)initWithFrame:(NSRect)frameRect
{
    BOOL error = ([super initWithFrame:frameRect] == nil);

    if (NO == error) {
		Class cellClass = [[self class] cellClass];
		unichar arrows[] = {0xf703,0xf700,0xf702,0xf701}; // 矢印キーは /Uf700~/Uf703 //
		ASDialKnobCell *myCell = [[cellClass allocWithZone:[self zone]] initImageCell:nil];

		arrowKeysString = [[NSString allocWithZone:[self zone]] initWithCharacters:arrows length:4];
		[self setCell:myCell];
		[myCell setSelfFrame:[self frame]];
		theCursor = [[ASDialKnob cursor] retain];
		[self registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
		acceptsArrowKeys = YES;
		increment = 1.0 + 1e-10;
		[self setBoundsOrigin:NSMakePoint(-0.5 * NSWidth([self frame]),-0.5 * NSHeight([self frame]))];
		[self setContinuous:YES];
		[self setEditable:YES];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(superviewDidResize:) name:NSViewFrameDidChangeNotification object:[self superview]];
		[myCell release];
    }
    return error ? nil : self;
}
- (id)init {
	return [self initWithFrame:NSMakeRect(0.0,0.0,64.0,64.0)];
}

- (void)resetCursorRects
{
	NSRect visible = [self visibleRect]; // イメージ全体の大きさが返される。 //

	if( NO == NSIsEmptyRect(visible) )
		[self addCursorRect:visible cursor:theCursor];
}

- (void)superviewDidResize:(id)sender {
	[[self cell] sizeToFit];
}
- (void)sizeToFit {
	[[self cell] sizeToFit];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self]; // このremoveObserver:selfは重要。これをやらないとハングアップする。 //
	[theCursor release];
	[arrowKeysString release];
	[observedObjectForAngle release];
	[observedKeyPathForAngle release];
	[super dealloc];
}

- (void)setImageRep:(NSImageRep *)newImageRep {
	[[self cell] setImageRep:newImageRep];
	[[NSNotificationCenter defaultCenter] postNotificationName:ASDialKnobImageRepDidChangeNotification object:self];
}
- (NSImageRep *)imageRep {
	return [[self cell] imageRep];
}

- (BOOL)setImageRepWithContentsOfURL:(NSURL *)url
// エラーが起きたら何もしない。 //
{
	BOOL result;
	if (nil == url) {
		[[self cell] setImageRep:nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:ASDialKnobImageRepDidChangeNotification object:self];
		result = YES;
	}
	else {
		NSArray *tempReps;
		NSError *err = nil;
		NSString *utiType = (YES == [url isFileURL]) ? [[NSWorkspace sharedWorkspace] typeOfFile:[url path] error:&err] : nil;
#ifdef USESVG
		[NSImageRep registerImageRepClass:[ASWebImageRep class]];
#endif
		Class imageRepClass = (nil != utiType) ? [NSImageRep imageRepClassForType:utiType] : nil;
		if (nil != imageRepClass) {
			if ((nil != (tempReps = [imageRepClass imageRepsWithContentsOfURL:url])) && (0 < [tempReps count])) {
				[[self cell] setImageRep:[tempReps objectAtIndex:0]];
				[[NSNotificationCenter defaultCenter] postNotificationName:ASDialKnobImageRepDidChangeNotification object:self];
				result = YES;
			}
			else
				result = NO;
		}
		else
			result = NO;
#ifdef USESVG
		[NSImageRep unregisterImageRepClass:[ASWebImageRep class]];
#endif
	}
	return result;
}
- (BOOL)setImageRepWithContentsOfFile:(NSString *)filename {
	return [self setImageRepWithContentsOfURL:[NSURL fileURLWithPath:filename]];
}
- (BOOL)setImageRepWithData:(NSData *)aData ofType:(NSString *)type
{
	BOOL result;

	if (nil != aData) {
		NSArray *tempReps;
		Class imageRepClass;
#ifdef USESVG
		[NSImageRep registerImageRepClass:[ASWebImageRep class]];
#endif
		if (YES == [[NSImage imageUnfilteredPasteboardTypes] containsObject:type]) {
			if (nil != (imageRepClass = [NSImageRep imageRepClassForPasteboardType:type])) {
				if (YES == [imageRepClass respondsToSelector:@selector(imageRepsWithData:)])
					tempReps = [imageRepClass imageRepsWithData:aData];
				else {
					if (YES == [imageRepClass respondsToSelector:@selector(imageRepWithData:)])
						tempReps = [NSArray arrayWithObject:[imageRepClass imageRepWithData:aData]];
					else
						tempReps = nil;
				}
			}
			else
				tempReps = nil;
		}
		else {
			if (YES == [[NSImage imagePasteboardTypes] containsObject:type]) { // フィルタプログラムはこのクライアントが属するワークスペースに依って決定されるので要注意 //
				NSPasteboard *pboard = [NSPasteboard pasteboardByFilteringData:aData ofType:type]; // [pasteboardByFilteringData: ofType:NSCreateFileContentsPboardType()]のPasteboardのtypesは、サポートしているフィルターがあるときは、"NXTypedFileContentsPboardType:"+拡張子と"NeXT TIFF v4.0 pasteboard type"の?個の文字列になる。 //
				NSArray *typesArray = [pboard types];

				if (0 < [typesArray count]) {
					tempReps = [NSImageRep imageRepsWithPasteboard:pboard]; // [[NSImage allocWithZone:[self zone]] initWithPasteboard:pboard]によって、フィルタープログラムに起動がかかる。 //
				}
				else {
					// [pboard types]の戻り値が空のときは、サポートしているフィルターが見つからないときである。 //
					// このとき、pboardからreadFileContentsType:をしてもデータが空なのでファイルが作られない。 //
					const char *template = [[NSTemporaryDirectory() stringByAppendingPathComponent:@"filteredImageXXXXXX"] UTF8String];
					NSURL *tempFileURL = [NSURL fileURLWithPath:[[NSString stringWithUTF8String:mktemp((char *)template)] stringByAppendingPathExtension:@"temp"]]; // この場合はほとんど駄目になると思う。 //
					NSError *err = nil;

					[aData writeToURL:tempFileURL atomically:YES];
					tempReps = [NSImageRep imageRepsWithContentsOfURL:tempFileURL];
					[[NSFileManager defaultManager] removeItemAtURL:tempFileURL error:&err];
				}
			}
			else {
				if (nil != (imageRepClass = [NSImageRep imageRepClassForType:type]))
					tempReps = [imageRepClass imageRepsWithData:aData]; // imageRepsWithData:はあるものと決め打ち //
				else
					tempReps = nil;
			}
		}
#ifdef USESVG
		[NSImageRep unregisterImageRepClass:[ASWebImageRep class]];
#endif
		if ((nil != tempReps) && (0 < [tempReps count])) {
			[[self cell] setImageRep:[tempReps objectAtIndex:0]];
			[[NSNotificationCenter defaultCenter] postNotificationName:ASDialKnobImageRepDidChangeNotification object:self];
			result = YES;
		}
		else // エラーが起きたら何もしない。 //
			result = NO;
	}
	else {
		[[self cell] setImageRep:nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:ASDialKnobImageRepDidChangeNotification object:self];
		result = YES;
	}
	return result;
}

- (BOOL)setImageRepWithImage:(NSImage *)image
{
	BOOL result;

	if (nil != image) {
		[[self cell] setImage:image];
		[[NSNotificationCenter defaultCenter] postNotificationName:ASDialKnobImageRepDidChangeNotification object:self];
		result = YES;
	}
	else {
		[[self cell] setImage:nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:ASDialKnobImageRepDidChangeNotification object:self];
		result = YES;
	}
	return result;
}

- (void)setBackgroundColor:(NSColor *)newColor {
	[[self cell] setBackgroundColor:newColor];
}
- (NSColor *)backgroundColor {
	return [[self cell] backgroundColor];
}

- (void)setTickMarks:(NSColor *)aColor background:(NSColor *)bColor width:(NSInteger)wValue {
	[[self cell] setTickMarks:aColor background:bColor width:wValue];
}

- (void)setRadianValue:(double)aRadian
{
	[[self cell] setRadianValue:aRadian];
	[self updateCellInside:[self cell]];
	[self writeToOutlet];
}
- (void)setDMSValue:(double)aDouble
{
	[[self cell] setDMSValue:aDouble];
	[self updateCellInside:[self cell]];
	[self writeToOutlet];
}
- (void)setDEGValue:(double)aDouble
{
	[[self cell] setDEGValue:aDouble];
	[self updateCellInside:[self cell]];
	[self writeToOutlet];
}
- (void)setDoubleValue:(double)aDouble
// 10進単位 //
{
	[[self cell] setDoubleValue:aDouble];
	[self updateCellInside:[self cell]];
	[self writeToOutlet];
}
- (void)takeRadianValueFrom:(id)sender
{
	[[self cell] setRadianValue:[sender doubleValue]];
	[self updateCellInside:[self cell]];
	[self writeToOutlet];
}
- (void)takeDMSValueFrom:(id)sender
{
	[[self cell] setDMSValue:[sender doubleValue]];
	[self updateCellInside:[self cell]];
	[self writeToOutlet];
}
- (void)takeDEGValueFrom:(id)sender
{
	[[self cell] setDEGValue:[sender doubleValue]];
	[self updateCellInside:[self cell]];
	[self writeToOutlet];
}
- (void)takeDoubleValueFrom:(id)sender
{
	[[self cell] setDoubleValue:[sender doubleValue]];
	[self updateCellInside:[self cell]];
	[self writeToOutlet];
}

- (double)radianValue {
	return [[self cell] radianValue];
}
- (double)dmsValue {
	return [[self cell] dmsValue];
}
- (double)degValue {
	return [[self cell] degValue];
}
- (double)doubleValue { // 10進単位 //
	return [[self cell] doubleValue];
}

- (void)writeToOutlet
{
	if (nil != radianTextField)
		[radianTextField setDoubleValue:[[self cell] radianValue]];
	if (nil != dmsTextField)
		[dmsTextField setDoubleValue:[[self cell] dmsValue]];
	if (nil != degTextField)
		[degTextField setDoubleValue:[[self cell] degValue]];
	if (nil != observedObjectForAngle)
		[observedObjectForAngle setValue:[NSNumber numberWithDouble:self.rotateAngle] forKeyPath:observedKeyPathForAngle];
}

- (void)setContinuous:(BOOL)flag {
	[[self cell] setContinuous:flag];
}
- (void)setEditable:(BOOL)flag {
	[[self cell] setEditable:flag];
}
- (BOOL)isEditable {
	return [[self cell] isEditable];
}
- (void)setBordered:(BOOL)flag
{
	if (flag != [[self cell] isBordered])
		[[self cell] setBordered:flag];
}
- (BOOL)isBordered {
	return [[self cell] isBordered];
}
- (void)setTag:(NSInteger)anInt {
	[[self cell] setTag:anInt];
}
- (NSInteger)tag {
	return [[self cell] tag];
}
- (BOOL)acceptsArrowKeys {
	return acceptsArrowKeys;
}
- (void)setAcceptsArrowKeys:(BOOL)flag {
	acceptsArrowKeys = flag;
}
- (NSString *)arrowKeysString {
	return arrowKeysString;
}
- (void)setArrowKeysString:(NSString *)aString
{
	[arrowKeysString release];
	arrowKeysString = [[NSString allocWithZone:[self zone]] initWithString:aString];
}
- (double)increment {
	return increment;
}
- (void)setIncrement:(double)newValue {
	increment = newValue;
}
- (void)setClockwise:(BOOL)flag {
	[[self cell] setClockwise:flag];
}
- (BOOL)clockwise {
	return [[self cell] clockwise];
}

- (BOOL)isFlipped { // override. setFlipped:されても何もしない。 //
	return [[self cell] isFlipped];
}

- (NSUInteger)draggingEntered:(id <NSDraggingInfo>)sender {
	return [self draggingUpdated:sender];
}
- (NSUInteger)draggingUpdated:(id <NSDraggingInfo>)sender
{
	NSDragOperation sourceDragMask = [sender draggingSourceOperationMask];
	if ((YES == [[self cell] isEnabled]) && (YES == [[self cell] isEditable]) && (sourceDragMask & NSDragOperationGeneric)) {
		NSArray *classes = [NSArray arrayWithObjects:[NSURL class], nil];
#ifdef USESVG
		[NSImageRep registerImageRepClass:[ASWebImageRep class]];
#endif
		NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSImage imageTypes],NSPasteboardURLReadingContentsConformToTypesKey, nil];
		NSPasteboard *pasteboard = [sender draggingPasteboard];
		NSArray *imageURLs = [pasteboard readObjectsForClasses:classes options:options];
#ifdef USESVG
		[NSImageRep unregisterImageRepClass:[ASWebImageRep class]];
#endif
		if (nil != imageURLs) {
			if ([NSURL class] == [[imageURLs objectAtIndex:0] class]) {
				if (sourceDragMask & NSDragOperationCopy)
					return NSDragOperationCopy; // + //
				else {
					if (sourceDragMask & NSDragOperationLink)
						return NSDragOperationLink; // 時計回り矢印 //
					else
						return NSDragOperationGeneric; // 通常の矢印 //
				}
			}
			else
				return NSDragOperationGeneric;
		}
		else
			return NSDragOperationNone;
	}
	else
		return NSDragOperationNone;
}
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
	return (NSDragOperationNone == [self draggingUpdated:sender]) ? NO : YES;
}
- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
	NSArray *classes = [NSArray arrayWithObjects:[NSURL class], nil];
#ifdef USESVG
	[NSImageRep registerImageRepClass:[ASWebImageRep class]];
#endif
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSImage imageTypes],NSPasteboardURLReadingContentsConformToTypesKey, nil];
	NSPasteboard *pasteboard = [sender draggingPasteboard];
	NSArray *imageURLs = [pasteboard readObjectsForClasses:classes options:options];
	if ((nil != imageURLs) && (0 < [imageURLs count])) {
		if (YES == [[imageURLs lastObject] isKindOfClass:[NSURL class]]) { // 複数のobjectに対応しても意味が無いのでlastObjectの一つにしてしまう。 //
			NSURL *url = [imageURLs lastObject];
			NSError *err = nil;
			NSString *utiType = [[NSWorkspace sharedWorkspace] typeOfFile:[url path] error:&err];
			Class imageRepClass = (nil != utiType) ? [NSImageRep imageRepClassForType:utiType] : nil;
			NSArray *tempReps = (nil != imageRepClass) ? [imageRepClass imageRepsWithContentsOfURL:url] : nil;
			
			if ((nil != tempReps) && (0 < [tempReps count])) {
				[[self cell] setImageRep:[tempReps objectAtIndex:0]];
				[self updateCellInside:[self cell]];
				[[NSNotificationCenter defaultCenter] postNotificationName:ASDialKnobImageRepDidChangeNotification object:self];
			} // エラーが起きたら何もしない。 //
		}
	}
#ifdef USESVG
	[NSImageRep unregisterImageRepClass:[ASWebImageRep class]];
#endif
}

-(void)copy:(id)sender {
	[[self cell] copy:sender];
}
- (void)print:(id)sender {
	[[self cell] print:sender];
}
- (NSString *)printJobTitle {
	return NSStringFromClass([self class]);
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	[super initWithCoder:aDecoder];
	arrowKeysString = [[aDecoder decodeObjectForKey:@"arrowKeysString"] retain];
	theCursor = [[aDecoder decodeObjectForKey:@"theCursor"] retain];
	radianTextField = [[aDecoder decodeObjectForKey:@"radianTextField"] retain];
	dmsTextField = [[aDecoder decodeObjectForKey:@"dmsTextField"] retain];
	degTextField = [[aDecoder decodeObjectForKey:@"degTextField"] retain];
	acceptsArrowKeys = [aDecoder decodeBoolForKey:@"acceptsArrowKeys"] ;
	increment = [aDecoder decodeDoubleForKey:@"increment"];
	return self;
}
- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[super encodeWithCoder:aCoder];
	[aCoder encodeObject:arrowKeysString forKey:@"arrowKeysString"];
	[aCoder encodeObject:theCursor forKey:@"theCursor"];
	[aCoder encodeObject:radianTextField forKey:@"radianTextField"];
	[aCoder encodeObject:dmsTextField forKey:@"dmsTextField"];
	[aCoder encodeObject:degTextField forKey:@"degTextField"];
	[aCoder encodeBool:acceptsArrowKeys forKey:@"acceptsArrowKeys"];
	[aCoder encodeDouble:increment forKey:@"increment"];
}

#pragma mark Property

- (void)setRotateAngle:(double)aValue {
	[[self cell] setRotateAngle:aValue];
}

- (double)rotateAngle {
	return [[self cell] rotateAngle];
}

#pragma mark Binding

static void *AngleBindContext = (void *)@"DialKnobAngle";

- (void)bind:(NSString *)binding toObject:(id)observableObject withKeyPath:(NSString *)keyPath options:(NSDictionary *)options
{
	if (YES == [binding isEqualToString:ASDialKnobRotateAngleKey]) {
		[observableObject addObserver:self forKeyPath:keyPath options:0 context:AngleBindContext];
		observedObjectForAngle = [observableObject retain];
		observedKeyPathForAngle = [keyPath copy];
	}
}
- (void)unbind:(NSString *)bindingName
{
	if (YES == [bindingName isEqualToString:ASDialKnobRotateAngleKey]) {
		[observedObjectForAngle release];
		observedObjectForAngle = nil;
		[observedKeyPathForAngle release];
		observedKeyPathForAngle = nil;
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == AngleBindContext) {
		id newAngle = [observedObjectForAngle valueForKeyPath:observedKeyPathForAngle];
		[[self cell] setRotateAngle:((nil != newAngle) && (YES == [newAngle isKindOfClass:[NSNumber class]])) ? [newAngle doubleValue] : 0.0]; // newAngleがNSStateMarkerクラスになることが頻繁にある。 //
	}
}

@end
