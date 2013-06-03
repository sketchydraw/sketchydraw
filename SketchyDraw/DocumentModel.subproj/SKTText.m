/*
     File: SKTText.m
 Abstract: A graphic object to represent a text area.
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

#import "SKTText.h"
#import "SKTFoundationExtras.h" // SatoAkira add. for svg...() //
#import "SKTDocument.h" // SatoAkira add. for SKTFontDescriptorKey //


// String constants declared in the header. They may not be used by any other class in the project, but it's a good idea to provide and use them, if only to help prevent typos in source code.
NSString *SKTTextScriptingContentsKey = @"scriptingContents";
NSString *SKTTextUndoContentsKey = @"undoContents";

// A key that's used in Sketch's property-list-based file and pasteboard formats.
NSString *SKTTextContentsKey = @"contents";


@implementation SKTText


- (NSTextStorage *)contents {

    // Never return nil.
    if (!_contents) {
	_contents = [[NSTextStorage alloc] init];

	// We need to be notified whenever the text storage changes.
	[_contents setDelegate:self];

    }
    return _contents;

}


- (id)copyWithZone:(NSZone *)zone {

    // Sending -copy or -mutableCopy to an NSTextStorage results in an NSAttributedString or NSMutableAttributedString, so we have to do something a little different. We go through [copy contents] to make sure delegation gets set up properly, and [self contents] to easily ensure we're not passing nil to -setAttributedString:.
    SKTText *copy = [super copyWithZone:zone];
    [[copy contents] setAttributedString:[self contents]];
    return copy;

}


- (void)dealloc {

    // Do the regular Cocoa thing.
    [_contents setDelegate:nil];
    [_contents release];
	[documentAttributes release];
    [super dealloc];

}


#pragma mark *** Text Layout ***


// This is a class method to ensure that it doesn't need to access the state of any particular SKTText.
+ (NSLayoutManager *)sharedLayoutManager {

    // Return a layout manager that can be used for any drawing.
    static NSLayoutManager *layoutManager = nil;
    if (!layoutManager) {
        NSTextContainer *textContainer = [[NSTextContainer alloc] initWithContainerSize:NSMakeSize(1.0e7f, 1.0e7f)];
	layoutManager = [[NSLayoutManager alloc] init];
	[textContainer setWidthTracksTextView:NO];
        [textContainer setHeightTracksTextView:NO];
        [layoutManager addTextContainer:textContainer];
        [textContainer release];
    }
    return layoutManager;

}


- (NSSize)naturalSize {

    // Figure out how big this graphic would have to be to show all of its contents. -glyphRangeForTextContainer: forces layout.
    NSRect bounds = [self bounds];
    NSLayoutManager *layoutManager = [[self class] sharedLayoutManager];
    NSTextContainer *textContainer = [[layoutManager textContainers] objectAtIndex:0];
    [textContainer setContainerSize:NSMakeSize(bounds.size.width, 1.0e7f)];
    NSTextStorage *contents = [self contents];
    [contents addLayoutManager:layoutManager];
    [layoutManager glyphRangeForTextContainer:textContainer];
    NSSize naturalSize = [layoutManager usedRectForTextContainer:textContainer].size;
    [contents removeLayoutManager:layoutManager];
	// NSLog(@"height=%f width=%f",naturalSize.height,naturalSize.width); 縦書きのとき、.widthが列の大きさ.heightが行数になるので横書きと同じ。縦書きのときnewEditingViewWithSuperviewBounds:と同じようにtextContainerのheightを極大にしておく必要がある。 //
    return naturalSize;

}

- (NSRect)naturalRect:(NSSize)naturalSize
// SatoAkira add. 回転移動に対応。回転の中心が変わるので座標変換が必要になる。 //
{
	NSRect bounds = [self bounds];
	NSRect naturalRect = NSMakeRect(NSMinX(bounds), NSMinY(bounds), naturalSize.width, naturalSize.height); // 変更後のbounds //
	double r = [self rotateAngle];
	if (0.0 != r) { // 0.0でも2*M_PIでも実行させても良いが、無駄な処理を省くためにこの判断をさせる。 //
		NSPoint center = NSMakePoint(NSMidX(bounds), NSMidY(bounds)); // bounds変更前の回転中心の座標値 //
		NSPoint oO = NSMakePoint((NSMinX(bounds) - center.x) * cos(r) - (NSMinY(bounds) - center.y) * sin(r) + center.x, (NSMinY(bounds) - center.y) * cos(r) + (NSMinX(bounds) - center.x) * sin(r) + center.y); // 左上の原点の変換後座標値 //
		NSPoint nC = NSMakePoint((NSMidX(naturalRect) - center.x) * cos(r) - (NSMidY(naturalRect) - center.y) * sin(r) + center.x , (NSMidY(naturalRect) - center.y) * cos(r) + (NSMidX(naturalRect) - center.x) * sin(r) + center.y); // 変更後の回転中心はNSMakePoint(NSMidX(newRect),NSMidY(newRect))。変更後の回転中心の座標変換 //
		NSPoint convertedPoint = NSMakePoint((oO.x - nC.x) * cos(-1.0 * r) - (oO.y - nC.y) * sin(-1.0 * r) + nC.x, (oO.y - nC.y) * cos(-1.0 * r) + (oO.x - nC.x) * sin(-1.0 * r) + nC.y); // 変更後の回転中心から見た左上の座標値。回転前の座標値。このあとの回転はdrawingの方で掛かる。縦書きもこのままで良い。 //
		naturalRect.origin.x = convertedPoint.x;
		naturalRect.origin.y = convertedPoint.y;
	}
	return naturalRect;
}

- (void)setHeightToMatchContents {

    // Update the bounds of this graphic to match the height of the text. Make sure that doesn't result in the registration of a spurious undo action.
    // There might be a noticeable performance win to be had during editing by making this object a delegate of the text views it creates, implementing -[NSObject(NSTextDelegate) textDidChange:], and using information that's already calculated by the editing text view instead of invoking -makeNaturalSize like this.
    [self willChangeValueForKey:SKTGraphicKeysForValuesToObserveForUndoKey];
    _boundsBeingChangedToMatchContents = YES;
    [self didChangeValueForKey:SKTGraphicKeysForValuesToObserveForUndoKey];
    /* NSRect bounds = [self bounds];
    NSSize naturalSize = [self naturalSize];
    [self setBounds:NSMakeRect(bounds.origin.x, bounds.origin.y, bounds.size.width, naturalSize.height)]; */ // SatoAkira delete. //
	NSSize matchingSize = NSMakeSize(NSWidth([self bounds]), [self naturalSize].height); // SatoAkira add. //
	NSRect naturalRect = [self naturalRect:matchingSize]; // SatoAkira add. //
	[self setBounds:NSMakeRect(NSMinX(naturalRect), NSMinY(naturalRect), matchingSize.width, matchingSize.height)]; // SatoAkira add. //
    [self willChangeValueForKey:SKTGraphicKeysForValuesToObserveForUndoKey];
    _boundsBeingChangedToMatchContents = NO;
    [self didChangeValueForKey:SKTGraphicKeysForValuesToObserveForUndoKey];

}


// Conformance to the NSTextStorageDelegate protocol.
- (void)textStorageDidProcessEditing:(NSNotification *)notification {

    // The work we're going to do here involves sending -glyphRangeForTextContainer: to a layout manager, but you can't send that message to a layout manager attached to a text storage that's still responding to -endEditing, so defer the work to a point where -endEditing has returned.
    [self performSelector:@selector(setHeightToMatchContents) withObject:nil afterDelay:0.0];

}

- (void)setDrawingStroke:(BOOL)aValue
// SatoAkira add. NSTextStorageのattributesをいじらなければならないので、オーバーライドする。 //
{
	NSRange aRange;
	NSRange contentsRange = NSMakeRange(0,[_contents length]);
	_isDrawingStroke = aValue;
	if (YES == _isDrawingStroke) {
		CGFloat topFontSize = [[[_contents fontAttributesInRange:NSMakeRange(0,1)] objectForKey:NSFontAttributeName] pointSize];
		if (0.0 == _strokeWidth)
			[_contents addAttributes:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:3.0] forKey:NSStrokeWidthAttributeName] range:contentsRange];
		else
			[_contents addAttributes:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:-100.0 * _strokeWidth / topFontSize] forKey:NSStrokeWidthAttributeName] range:contentsRange];
		[_contents addAttributes:[NSDictionary dictionaryWithObject:[self strokeColor] forKey:NSStrokeColorAttributeName] range:contentsRange];
	}
	else {
		if (nil != [_contents attribute:NSStrokeWidthAttributeName atIndex:0 effectiveRange:&aRange])
			[_contents removeAttribute:NSStrokeWidthAttributeName range:contentsRange];
		if (nil != [_contents attribute:NSStrokeColorAttributeName atIndex:0 effectiveRange:&aRange])
			[_contents removeAttribute:NSStrokeColorAttributeName range:contentsRange];
	}
}
- (void)setStrokeWidth:(CGFloat)aValue
// SatoAkira add. NSTextStorageのattributesをいじらなければならないので、オーバーライドする。 //
{
	NSRange contentsRange = NSMakeRange(0,[_contents length]);
	_strokeWidth = aValue;
	if (YES == _isDrawingStroke) {
		CGFloat topFontSize = [[[_contents fontAttributesInRange:NSMakeRange(0,1)] objectForKey:NSFontAttributeName] pointSize];
		if (0.0 == _strokeWidth)
			[_contents addAttributes:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:3.0] forKey:NSStrokeWidthAttributeName] range:contentsRange];
		else
			[_contents addAttributes:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:-100.0 * _strokeWidth / topFontSize] forKey:NSStrokeWidthAttributeName] range:contentsRange];
		[_contents addAttributes:[NSDictionary dictionaryWithObject:[self strokeColor] forKey:NSStrokeColorAttributeName] range:contentsRange];
	}	
}
- (void)setStrokeColor:(NSColor *)aValue
// SatoAkira add. NSTextStorageのattributesをいじらなければならないので、オーバーライドする。 //
{
	NSRange contentsRange = NSMakeRange(0,[_contents length]);
	[_strokeColor release];
	_strokeColor = [aValue copy];
	if (YES == _isDrawingStroke) {
		CGFloat topFontSize = [[[_contents fontAttributesInRange:NSMakeRange(0,1)] objectForKey:NSFontAttributeName] pointSize];
		if (0.0 == _strokeWidth)
			[_contents addAttributes:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:3.0] forKey:NSStrokeWidthAttributeName] range:contentsRange];
		else
			[_contents addAttributes:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:-100.0 * _strokeWidth / topFontSize] forKey:NSStrokeWidthAttributeName] range:contentsRange];
		[_contents addAttributes:[NSDictionary dictionaryWithObject:[self strokeColor] forKey:NSStrokeColorAttributeName] range:contentsRange];
	}	
}
- (void)setDrawingFill:(BOOL)aValue
// SatoAkira add. NSTextStorageのattributesをいじらなければならないので、オーバーライドする。 //
{
	NSRange contentsRange = NSMakeRange(0,[_contents length]);
	_isDrawingFill = aValue;
	if (YES == _isDrawingFill) {
		[_contents addAttributes:[NSDictionary dictionaryWithObject:[self fillColor] forKey:NSBackgroundColorAttributeName] range:contentsRange];
	}
	else {
		NSRange aRange;
		if (nil != [_contents attribute:NSBackgroundColorAttributeName atIndex:0 effectiveRange:&aRange])
			[_contents removeAttribute:NSBackgroundColorAttributeName range:contentsRange];
	}
}
- (void)setFillColor:(NSColor *)aValue
// SatoAkira add. NSTextStorageのattributesをいじらなければならないので、オーバーライドする。 //
{
	NSRange contentsRange = NSMakeRange(0,[_contents length]);
	[_fillColor release];
	_fillColor = [aValue copy];
	if (YES == _isDrawingFill) {
		[_contents addAttributes:[NSDictionary dictionaryWithObject:[self fillColor] forKey:NSBackgroundColorAttributeName] range:contentsRange];
	}
}

#pragma mark *** Private KVC-Compliance for Public Properties ***


- (void)willChangeScriptingContents {

    // Tell any object that would observe this one to record undo operations to start observing. In Sketch, each SKTDocument is observing all of its graphics' "keysForValuesToObserveForUndo" values.
    [self willChangeValueForKey:SKTGraphicKeysForValuesToObserveForUndoKey];
    _contentsBeingChangedByScripting = YES;
    [self didChangeValueForKey:SKTGraphicKeysForValuesToObserveForUndoKey];

    // Do the first part of notifying observers. It's OK if no changes are actually done by scripting before the matching invocation of -didChangeValueForKey:. Key-value observers aren't allowed to assume that every observer notification is about a real change (that's why the KVO notification method's name starts with -observeValueForKeyPath:, not -observeChangeOfValueForKeyPath:).
    [self willChangeValueForKey:SKTTextUndoContentsKey];

}


- (void)didChangeScriptingContents {

    // Any changes that might have been done by the scripting command are done.
    [self didChangeValueForKey:SKTTextUndoContentsKey];

    // Tell observers to stop observing to record undo operations.
    // This isn't strictly necessary in Sketch: we could just let the SKTDocument keep observing, because we know that no other objects are observing "undoContents." Partial KVO-compliance like this that only works some of the time is a dangerous game though, and it's a good idea to be very explicit about it. This class is very explictily only KVO-compliant for "undoContents" while -keysForValuesToObserveForUndo is returning a set that contains "undoContents."
    [self willChangeValueForKey:SKTGraphicKeysForValuesToObserveForUndoKey];
    _contentsBeingChangedByScripting = NO;
    [self didChangeValueForKey:SKTGraphicKeysForValuesToObserveForUndoKey];

}


- (NSTextStorage *)scriptingContents {

    // Before returning an NSTextStorage that Cocoa's scripting support can work with, do the first part of notifying observers, and then schedule the second part of notifying observers for after all potential scripted changes caused by the current scripting command have been done.
    // An alternative to the way we notify key-value observers here would be to return an NSTextStorage that's a proxy to the one held by this object, and make it send this object the -willChangeValueForKey:/-didChangeValueForKey: messages around forwarding of mutation messages (sort of like what the collection proxy objects returned by KVC for sets and arrays do), but that wouldn't gain us anything as far as we know right now, and might even lead to performance problems (because one scripting command could result in potentially many KVO notifications).
    [self willChangeScriptingContents];
    [self performSelector:@selector(didChangeScriptingContents) withObject:nil afterDelay:0.0];
    return [self contents];

}


- (id)coerceValueForScriptingContents:(id)contents {

    // Make sure that NSStrings aren't coerced to NSAttributedStrings by Cocoa's coercion machinery. -setScriptingContents: will do something special with them.
    id coercedContents;
    if ([contents isKindOfClass:[NSString class]]) {
        coercedContents = contents;
    } else {
        coercedContents = [[NSScriptCoercionHandler sharedCoercionHandler] coerceValue:contents toClass:[NSTextStorage class]];
    }
    return coercedContents;

}


- (void)setScriptingContents:(id)newContents {

    // If an attributed string is passed then then do a simple replacement. If a string is passed in then reuse the character style that's already there. Either way, we must notify observers of "undoContents" that its value is changing here.
    // By the way, if this method actually changed the value of _contents we would have to move any layout managers attached to the old value of _contents to the new value, so as not to break editing if it's being done at this moment.
    [self willChangeScriptingContents];
    NSMutableAttributedString *contents = [self contents];
    NSRange allContentsRange = NSMakeRange(0, [contents length]);
    if ([newContents isKindOfClass:[NSAttributedString class]]) {
	[contents replaceCharactersInRange:allContentsRange withAttributedString:newContents];
    } else {
	[contents replaceCharactersInRange:allContentsRange withString:newContents];
    }
    [self didChangeScriptingContents];

}


- (NSAttributedString *)undoContents {

    // Never return an object whose value will change after it's been returned. This is generally good behavior for any getter method that returns the value of an attribute or a to-many relationship. (For to-one relationships just returning the related object is the right thing to do, as in this class' -contents method.) However, this particular implementation of this good behavior might not be fast enough for all situations. If the copying here causes a performance problem, an alternative might be to return [[contents retain] autorelease], set a bit that indicates that the contents should be lazily replaced with a copy before any mutation, and then heed that bit in other methods of this class.
    return [[[self contents] copy] autorelease];

}


- (void)setUndoContents:(NSAttributedString *)newContents {

    // When undoing a change that could have only been done by scripting, behave exactly if scripting is doing another change, for the benefit of redo.
    [self setScriptingContents:newContents];

}


#pragma mark *** Overrides of SKTGraphic Methods ***


/* - (id)initWithProperties:(NSDictionary *)properties
{

    // Let SKTGraphic do its job and then handle the one additional property defined by this subclass.
    self = [super initWithProperties:properties];
    if (self) {

	// The dictionary entries are all instances of the classes that can be written in property lists. Don't trust the type of something you get out of a property list unless you know your process created it or it was read from your application or framework's resources. We don't have to worry about KVO-compliance in initializers like this by the way; no one should be observing an unitialized object.
	NSData *contentsData = [properties objectForKey:SKTTextContentsKey];
	if ([contentsData isKindOfClass:[NSData class]]) {
	    NSTextStorage *contents = [NSUnarchiver unarchiveObjectWithData:contentsData];
	    if ([contents isKindOfClass:[NSTextStorage class]]) {
		_contents = [contents retain];

		// We need to be notified whenever the text storage changes.
		[_contents setDelegate:self];

	    }
	}

    }
    return self;

} */
NSString *SKTTextAreaContentsKey = @"Text"; // SatoAkira add.Sketch1との互換性を取る為。 //
NSString *DRAWRichTextKey = @"TheText"; // SatoAkira add. //
NSString *TextDocumentAttributes = @"documentAttributes"; // SatoAkira add. propertiesとKeyValueと兼用してしまう。 //

- (void)updateDocumentAttributes:(NSTextLayoutOrientation)orientation
// SatoAkira add. //
{
	NSRange contentsRange = (nil != _contents) ? NSMakeRange(0,[_contents length]) : NSMakeRange(0, 0);
	NSMutableDictionary *docAttributes = (nil != documentAttributes) ? [NSMutableDictionary dictionaryWithDictionary:documentAttributes] : [NSMutableDictionary dictionary];
	NSMutableArray *layoutSections = (nil != [docAttributes objectForKey:NSTextLayoutSectionsAttribute]) ? [NSMutableArray arrayWithArray:[docAttributes objectForKey:NSTextLayoutSectionsAttribute]] : nil;
	NSMutableDictionary *orientationDic = [NSMutableDictionary dictionary];
	NSUInteger index = 0;
	for (id layoutSection in layoutSections) {
		if (YES == [layoutSection isKindOfClass:[NSDictionary class]]) {
			if (nil != [layoutSection objectForKey:NSTextLayoutSectionOrientation]) {
				orientationDic = [NSMutableDictionary dictionaryWithDictionary:layoutSection];
				break;
			}
		}
		index++;
	}
	[orientationDic setObject:[NSNumber numberWithInteger:orientation] forKey:NSTextLayoutSectionOrientation];
	[orientationDic setObject:[NSValue valueWithRange:contentsRange] forKey:NSTextLayoutSectionRange];
	[_contents addAttributes:[NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:orientation] forKey:NSVerticalGlyphFormAttributeName] range:contentsRange]; // NSTextViewへの描画ならば、setLayoutOrientation:でNSVerticalGlyphFormAttributeNameも自動的に追加される。 //
	if ((nil != layoutSections) && (0 < [layoutSections count])) {
		if (index >= [layoutSections count])
			[layoutSections addObject:orientationDic];
		else
			[layoutSections replaceObjectAtIndex:index withObject:orientationDic];
	}
	else
		layoutSections = [NSMutableArray arrayWithObject:orientationDic];
	[docAttributes setObject:layoutSections forKey:NSTextLayoutSectionsAttribute];
	[documentAttributes release];
	documentAttributes = [[NSDictionary alloc] initWithDictionary:docAttributes];
}
- (id)initWithProperties:(NSDictionary *)properties
// SatoAkira add. //
{
	if (nil != (self = [super initWithProperties:properties])) {
		NSTextStorage *contents = nil;
		NSData *contentsData = [properties objectForKey:SKTTextContentsKey];
		[documentAttributes release];
		documentAttributes = nil;
		if ((nil != contentsData) && (YES == [contentsData isKindOfClass:[NSData class]]))
			contents = [NSUnarchiver unarchiveObjectWithData:contentsData]; // sketch2 and skt3. NSTextStorage. //
		else {
			contentsData = [properties objectForKey:SKTTextAreaContentsKey];
			if ((nil != contentsData) && (YES == [contentsData isKindOfClass:[NSData class]])) {
				id unarchiveObj;
				if (nil == (unarchiveObj = [NSUnarchiver unarchiveObjectWithData:contentsData])) // sketch1 //
					NSLog(@"SKTText:unarchiveObject is nil with sketch1 format. Data length=%lu",[contentsData length]);
				else {
					if (YES == [unarchiveObj isKindOfClass:[NSTextStorage class]])
						contents = unarchiveObj;
					else {
						if (YES == [unarchiveObj isKindOfClass:[NSAttributedString class]]) {
							NSLayoutManager *lM = [[NSLayoutManager allocWithZone:[self zone]] init];
							NSTextContainer *tC = [[NSTextContainer allocWithZone:[self zone]] initWithContainerSize:[self bounds].size];
							contents = [[[NSTextStorage allocWithZone:[self zone]] init] autorelease];
							[contents replaceCharactersInRange:NSMakeRange(0, [contents length]) withAttributedString:unarchiveObj];
							[lM setTypesetterBehavior:NSTypesetterLatestBehavior];
							[lM addTextContainer:tC];
							[contents addLayoutManager:lM];
							[lM release];
							[tC release];
						}
					}
				}
			}
			else {
				if ((nil != (contentsData = [properties objectForKey:DRAWRichTextKey])) && (YES == [contentsData isKindOfClass:[NSData class]])) { // sktd。sktdだけでなく表形式すなわちNSTextBlockがあったならば、これになる。 //
					NSDictionary *attrs;
					NSAttributedString *attrStr = [[NSAttributedString allocWithZone:[self zone]] initWithRTF:contentsData documentAttributes:&attrs];
					if (nil != attrStr) { // NSTextStorageとしての体裁を整える。 //
						NSLayoutManager *lM = [[NSLayoutManager allocWithZone:[self zone]] init];
						NSTextContainer *tC = [[NSTextContainer allocWithZone:[self zone]] initWithContainerSize:[self bounds].size];
						contents = [[[NSTextStorage allocWithZone:[self zone]] init] autorelease];
						[contents replaceCharactersInRange:NSMakeRange(0, [contents length]) withAttributedString:attrStr];
						[lM setTypesetterBehavior:NSTypesetterLatestBehavior];
						[lM addTextContainer:tC];
						[contents addLayoutManager:lM];
						[lM release];
						[tC release];
						[attrStr release];
						if (nil != attrs) {
							[documentAttributes release];
							documentAttributes = [attrs retain];
						}
					}
				}
				else
					contents = nil;
			}
		}
		if ((nil != contents) && (YES == [contents isKindOfClass:[NSTextStorage class]])) {
			if (0 < [contents length]) {
				_contents = [contents retain];
				[_contents setDelegate:self];
			}
			else
				_contents = nil;
		}
		else
			_contents = nil;
		if (nil == documentAttributes) {
			NSData *aData = [properties objectForKey:TextDocumentAttributes];
			if (nil != aData) {
				NSDictionary *docAttributes = [NSUnarchiver unarchiveObjectWithData:aData];
				if (nil != docAttributes)
					documentAttributes = [[NSDictionary alloc] initWithDictionary:docAttributes];
			}
			else
				[self updateDocumentAttributes:NSTextLayoutOrientationHorizontal];
		}
	}
	return self;
}


/* - (NSMutableDictionary *)properties {
	
    // Let SKTGraphic do its job and then handle the one additional property defined by this subclass. The dictionary must contain nothing but values that can be written in old-style property lists.
    NSMutableDictionary *properties = [super properties];
    [properties setObject:[NSArchiver archivedDataWithRootObject:[self contents]] forKey:SKTTextContentsKey];
    return properties;
	
} */ // SatoAkira delete. //
- (NSMutableDictionary *)properties
// SatoAkira add.表形式が混じっていた場合にNSTextStorageのarchiveでは対応できない。従ってRTFのdataにする。 //
{
    NSMutableDictionary *properties = [super properties];
	NSRange aRange;
	NSArray *textBlocks;
	NSParagraphStyle *paragraphStyle;
	BOOL isTextBlock = NO;
	NSArray *paragraphs = [[self contents] paragraphs]; // paragraphsがnilになることはない。 //
	for (NSTextStorage *sub in paragraphs) { // NSSubTextStroage //
		paragraphStyle = [sub attribute:NSParagraphStyleAttributeName atIndex:0 effectiveRange:&aRange];
		if ((nil != paragraphStyle) && (nil != (textBlocks = [paragraphStyle textBlocks])) && (0 < [textBlocks count])) {
			isTextBlock = YES;
			break;
		}
	}
	if (YES == isTextBlock) {
		NSUInteger length = [[self contents] length];
		[properties setObject:[[self contents] RTFFromRange:NSMakeRange(0,length) documentAttributes:(nil != documentAttributes) ? documentAttributes : NULL] forKey:DRAWRichTextKey]; // [properties setObject:[NSPropertyListSerialization dataFromPropertyList:paragraphs format:NSPropertyListXMLFormat_v1_0 errorDescription:&errStr]  forKey:@"SKTParagraphs"] とやると良く分からないが、paragraphsの中にnilが混じっているようでエラーになる。 //
	}
	else
		[properties setObject:[NSArchiver archivedDataWithRootObject:[self contents]] forKey:SKTTextContentsKey];
	if (nil != documentAttributes) {
		[properties setObject:[NSArchiver archivedDataWithRootObject:documentAttributes] forKey:TextDocumentAttributes]; // [NSPropertyListSerialization dataWithPropertyList:documentAttributes format:NSPropertyListBinaryFormat_v1_0 options:NSPropertyListImmutable error:&err]; Property list invalid for format: 200 (property lists cannot contain objects of type 'CFType') //
	}
	return properties;
}



/* - (BOOL)isDrawingStroke {

    // We never draw a stroke on this kind of graphic.
    return NO;

}


- (NSRect)drawingBounds {

    // The drawing bounds must take into account the focus ring that might be drawn by this class' override of -drawContentsInView:isBeingCreatedOrEdited:. It can't forget to take into account drawing done by -drawHandleInView:atPoint: though. Because this class doesn't override -drawHandleInView:atPoint:, it should invoke super to let SKTGraphic take care of that, and then alter the results.
    return NSUnionRect([super drawingBounds], NSInsetRect([self bounds], -1.0f, -1.0f));

}


- (void)drawContentsInView:(NSView *)view isBeingCreateOrEdited:(BOOL)isBeingCreatedOrEditing {

    // Draw the fill color if appropriate.
    NSRect bounds = [self bounds];
    if ([self isDrawingFill]) {
        [[self fillColor] set];
        NSRectFill(bounds);
    }

    // If this graphic is being created it has no text. If it is being edited then the editor returned by -newEditingViewWithSuperviewBounds: will draw the text.
    if (isBeingCreatedOrEditing) {

	// Just draw a focus ring.
	[[NSColor knobColor] set];
	NSFrameRect(NSInsetRect(bounds, -1.0, -1.0));

    } else {

	// Don't bother doing anything if there isn't actually any text.
	NSTextStorage *contents = [self contents]; 
	if ([contents length]>0) {

	    // Get a layout manager, size its text container, and use it to draw text. -glyphRangeForTextContainer: forces layout and tells us how much of text fits in the container.
	    NSLayoutManager *layoutManager = [[self class] sharedLayoutManager];
	    NSTextContainer *textContainer = [[layoutManager textContainers] objectAtIndex:0];
	    [textContainer setContainerSize:bounds.size];
	    [contents addLayoutManager:layoutManager];
	    NSRange glyphRange = [layoutManager glyphRangeForTextContainer:textContainer];
	    if (glyphRange.length>0) {
		[layoutManager drawBackgroundForGlyphRange:glyphRange atPoint:bounds.origin];
		[layoutManager drawGlyphsForGlyphRange:glyphRange atPoint:bounds.origin];
	    }
	    [contents removeLayoutManager:layoutManager];

        }

    }

} */ // SatoAkira delete. - (NSRect)drawingBoindsは縦書きのとき幅方向に大きくなりすぎてしまうので削除した。 //
- (void)drawContentsInView:(NSView *)view isBeingCreateOrEdited:(BOOL)isBeingCreatedOrEditing
// SatoAkira add. //
{
	NSRect bounds = [self bounds];
	NSGraphicsContext *currentContext = [NSGraphicsContext currentContext];

	if ((YES == [currentContext isDrawingToScreen]) && ((nil != view) && (YES == isBeingCreatedOrEditing))) {
		NSRect rectangleRect = NSMakeRect(-0.5 * NSWidth(bounds),-0.5 * NSHeight(bounds),NSWidth(bounds),NSHeight(bounds));
		NSAffineTransform *transform = [NSAffineTransform transform];
		[transform translateXBy:NSMidX(bounds) yBy:NSMidY(bounds)];
		[transform rotateByRadians:[self rotateAngle]];
		[transform concat];
		[(NSColor *)[PreferencesController objectForKey:KnobColorKey] setFill];
		NSFrameRect(NSInsetRect(rectangleRect, -1.0, -1.0));
	}
	else {
		NSTextStorage *contents = [self contents];
// ColorSpaceを合わせるには以下のコメント部分を使えば良いが、実用速度を得られなくなる。またモデルが保存されないようだ。 //
/* #if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_4
		NSTextStorage *contents = [[NSTextStorage alloc] initWithAttributedString:[self contents]];
		unsigned int length = [contents length];
		NSColorSpace *aSpace = [self colorSpace]; //　何故だか分からないが[self document]の_colorSpaceがnilになっていなくても、aSpaceがnilになることがある。　//
		 // 何故ここでやらなければならないかというと、lmを設定した後でcontentsのattributesをいじってdrawさせると例外発生してしまうからである。従ってここで、contentsをいじるだけにしてdrawさせない。 //
		if ((nil != aSpace) && (length > 0)) {
			unsigned int i,j;
			float *colorCompo;
			NSRange lfr;
			NSRect aRect;
			NSDictionary *fontAttributes;
			NSColor *c,*newC;
			NSLayoutManager *lm = [[NSLayoutManager allocWithZone:[self zone]] init];
			NSTextContainer *tc = [[NSTextContainer allocWithZone:[self zone]] initWithContainerSize:bounds.size];
			float blackcolor[4] = {0.0,0.0,0.0,1.0};
			NSRange contentsRange = NSMakeRange(0,length);

			if (YES == [self drawsFill])
				[contents addAttributes:[NSDictionary dictionaryWithObject:[self convertColorSpace:[self fillColor]] forKey:NSBackgroundColorAttributeName] range:contentsRange];
			if (YES == [self drawsStroke])
				[contents addAttributes:[NSDictionary dictionaryWithObject:[self convertColorSpace:[self strokeColor]] forKey:NSStrokeColorAttributeName] range:contentsRange];
			[lm setTypesetterBehavior:NSTypesetterLatestBehavior];
			[lm addTextContainer:tc];
			[contents addLayoutManager:lm];
			unsigned int glyphCount = [lm numberOfGlyphs];
			NSPoint glyphLocation = [lm locationForGlyphAtIndex:0];
			for (i = 0; i < glyphCount; i += lfr.length) {
				aRect = [lm lineFragmentRectForGlyphAtIndex:i effectiveRange:&lfr];
				for (j = i; j < i + lfr.length; j++) {
					if (NO == [lm notShownAttributeForGlyphAtIndex:j]) {
						fontAttributes = [contents fontAttributesInRange:NSMakeRange(j,1)];
						glyphLocation = [lm locationForGlyphAtIndex:j];
						if (nil == (c = [fontAttributes objectForKey:NSForegroundColorAttributeName]))
							newC = [NSColor colorWithColorSpace:aSpace components:blackcolor count:4];
						else {
							if ([aSpace colorSpaceModel] == [[c colorSpace] colorSpaceModel]) {
								colorCompo = (float *)malloc([c numberOfComponents] * sizeof(float));
								[c getComponents:colorCompo];
								if ([aSpace colorSpaceModel] == [[c colorSpace] colorSpaceModel])
								newC = [NSColor colorWithColorSpace:aSpace components:colorCompo count:[c numberOfComponents]];
								free(colorCompo);
								NSLog(@"number=%d %@",[c numberOfComponents],[[c colorSpace] localizedName]);
							}
							else
								newC = c;
						}
						if (nil != newC)
							[contents addAttributes:[NSDictionary dictionaryWithObject:newC forKey:NSForegroundColorAttributeName] range:NSMakeRange(j,1)];
					}
				}
			}
		}
#endif
		if (length > 0) { */
		if (0 < [contents length]) {
			NSLayoutManager *layoutManager = [[self class] sharedLayoutManager];
			// NSLayoutManager *layoutManager = ((nil != [_contents layoutManagers]) && (0 < [[_contents layoutManagers] count])) ? [[_contents layoutManagers] objectAtIndex:0] : [[self class] sharedLayoutManager];
			NSTextContainer *textContainer = [[layoutManager textContainers] objectAtIndex:0];
			NSAffineTransform *transform = [NSAffineTransform transform];
			[transform translateXBy:NSMidX(bounds) yBy:NSMidY(bounds)];
			[transform rotateByRadians:[self rotateAngle]];
			[layoutManager setTypesetterBehavior:NSTypesetterLatestBehavior];
			[textContainer setContainerSize:bounds.size]; // layoutOrientationは常に0 //
			[contents addLayoutManager:layoutManager];
			NSRange glyphRange = [layoutManager glyphRangeForTextContainer:textContainer];
			if (0 < glyphRange.length) {
				NSPoint textOrigin = NSMakePoint(-0.5 * NSWidth(bounds),-0.5 * NSHeight(bounds));
				[transform concat];
				if (YES == [self isDrawingFill]) {
					NSRect bRect = [layoutManager boundingRectForGlyphRange:glyphRange inTextContainer:textContainer];
					NSBezierPath *bPath = [NSBezierPath bezierPathWithRect:NSMakeRect(NSMinX(bRect) - 0.5 * NSWidth(bounds),NSMinY(bRect) - 0.5 * NSHeight(bounds),NSWidth(bRect),NSHeight(bRect))];
					BOOL shadowFlag = (0.1 > [self shadowBlurRadiusValue]) ? NO : YES;
					if ((YES == [self shading]) || (YES == [[[self fillColor] colorSpaceName] isEqualToString:NSPatternColorSpace])) {
						if (YES == shadowFlag) {
							[currentContext saveGraphicsState];
							[self shadowSet];
							[[NSColor whiteColor] setFill];
							[bPath setWindingRule:[self windingRule]];
							[bPath fill];
							[currentContext restoreGraphicsState];
						}
						if (YES == [self shading]) {
							[self drawShading:bPath transform:nil];
							// [layoutManager drawBackgroundForGlyphRange:glyphRange atPoint:textOrigin]; をやってはいけない。 //
						}
						else {
							ASPatternModel *pModel = [self patternModel];
							[pModel setBounds:bounds clip:bPath transform:nil colorSpace:[self colorSpace] winding:[self windingRule]];
							[pModel fill];
							// [layoutManager drawBackgroundForGlyphRange:glyphRange atPoint:textOrigin]; 表の罫線がぐちゃぐちゃになるのでいっそやらない方が良い。 //
						}
					}
					else {
						if (YES == shadowFlag) {
							[currentContext saveGraphicsState];
							[self shadowSet];
							[self fillColorSet];
							[bPath setWindingRule:[self windingRule]];
							[bPath fill];
							[currentContext restoreGraphicsState];
						}
						else {
							[self fillColorSet];
							[bPath setWindingRule:[self windingRule]];
							[bPath fill];
							// [layoutManager drawBackgroundForGlyphRange:glyphRange atPoint:textOrigin]; [bPath fill]をやらなくても、これだけで塗りつぶせるが、表の罫線がぐちゃぐちゃになるのでやらない方が良い。[bPath fill]の前にやっても結果は同じ。 //
						}
					}
				} // if (YES == [self isDrawingFill]) //
				else
					[layoutManager drawBackgroundForGlyphRange:glyphRange atPoint:textOrigin]; // NSBackgroundColorAttributeNameで塗りつぶす。[contents attribute:NSBackgroundColorAttributeName atIndex:0 longestEffectiveRange:NULL inRange:NSMakeRange(0,1)]と同じ色。nilのときは透明であるが表形式のときこれをやらないと罫線が表示されない。 //
				[layoutManager drawGlyphsForGlyphRange:glyphRange atPoint:textOrigin];
			} // if (0 < glyphRange.length) //
			else
				[transform concat]; // NSLog(@"glyphRange=%@",NSStringFromRange(glyphRange)); NSHeight(bounds)が1行の高さより小さいときにglyphRange.lengthが0になる。 //
			[contents removeLayoutManager:layoutManager];
		}
	}
}


/* - (BOOL)canSetDrawingStroke {

    // Don't let the user think we would even try to draw a stroke on this kind of graphic.
    return NO;

} */ // SatoAkira delete. //
- (BOOL)canDrawLineJoin { // SatoAkira add. //
	return NO;
}
- (BOOL)canDrawLineCap { // SatoAkira add. //
	return NO;
}
- (BOOL)canDrawArrow { // SatoAkira add. //
    return NO;
}
- (BOOL)canDrawFormEntry { // SatoAkira add. //
	return YES;
}
- (BOOL)canDrawDash { // SatoAkira add. //
    return NO;
}
- (NSTextLayoutOrientation)layoutOrientation
// SatoAkira add. NSVerticalGlyphFormAttributeNameで判断しない方が良い。TextEdit.appでもNSVerticalGlyphFormAttributeNameで判断はしていない。 //
{
	NSTextLayoutOrientation orientation = NSTextLayoutOrientationHorizontal;
	if (nil != documentAttributes) {
		NSArray *layoutSections = [documentAttributes objectForKey:NSTextLayoutSectionsAttribute];
		for (id layoutSection in layoutSections) {
			if (YES == [layoutSection isKindOfClass:[NSDictionary class]]) {
				if (nil != [layoutSection objectForKey:NSTextLayoutSectionOrientation]) {
					orientation = [[layoutSection objectForKey:NSTextLayoutSectionOrientation] integerValue];
					break;
				}
			}
		}
	}
	return orientation;
}
- (void)setTextLayoutOrientation:(NSTextLayoutOrientation)newOrientation
// SatoAkira add. //
{
	double newRotate;
	NSTextLayoutOrientation oldOrientation = [self layoutOrientation];
	double oldRotate = [self rotateAngle];
	if ((NSTextLayoutOrientationVertical == oldOrientation) && (newOrientation != oldOrientation))
		newRotate = oldRotate - M_PI_2;
	else {
		if ((NSTextLayoutOrientationHorizontal == oldOrientation) && (newOrientation != oldOrientation))
			newRotate = oldRotate + M_PI_2;
		else
			newRotate = oldRotate;
	}
	while (0.0 > newRotate)
		newRotate += 2.0 * M_PI;
	while (2.0 * M_PI < newRotate)
		newRotate -= 2.0 * M_PI;
	[self setValue:[NSNumber numberWithDouble:newRotate] forKey:SKTRotateAngleKey];
	[self updateDocumentAttributes:newOrientation];
}

- (void)makeNaturalSize {

    // The real work is done in code shared with -setHeightToMatchContents:.
    /* NSRect bounds = [self bounds];
    NSSize naturalSize = [self naturalSize];
	[self setBounds:NSMakeRect(bounds.origin.x, bounds.origin.y, naturalSize.width, naturalSize.height)]; */ // SatoAkira delete. //
	[self setBounds:[self naturalRect:[self naturalSize]]]; // SatoAkira add. 回転移動に対応。width,height共にnaturalSizeに変更する。回転の中心が変わるので座標変換が必要になる。 //

}


- (void)setBounds:(NSRect)bounds {

    // In Sketch the user can change the bounds of a text area while it's being edited using the graphics inspector, scripting, or undo. When that happens we have to update the editing views (there might be more than one, in different windows) to keep things consistent. We don't need to do this when the bounds is being changed to keep up with changes to the contents, because the text views we set up take care of that themselves.
    [super setBounds:bounds];
    if (!_boundsBeingChangedToMatchContents) {
	NSArray *layoutManagers = [[self contents] layoutManagers];
	NSUInteger layoutManagerCount = [layoutManagers count];
	for (NSUInteger index = 0; index<layoutManagerCount; index++) {
	    NSLayoutManager *layoutManager = [layoutManagers objectAtIndex:index];

	    // We didn't set up any multiple-text-view layout managers in -newEditingViewWithSuperviewBounds:, so we're not expecting to have to deal with any here.
	    [[layoutManager firstTextView] setFrame:bounds];

	}
    }

}



- (NSView *)newEditingViewWithSuperviewBounds:(NSRect)superviewBounds view:(NSView *)graphicView {

    // superviewBoundsは常に{{0, 0}, {450.99, 661.98}} //
    // Create a text view that has the same frame as this graphic. We use -[NSTextView initWithFrame:textContainer:] instead of -[NSTextView initWithFrame:] because the latter method creates the entire collection of objects associated with an NSTextView - its NSTextContainer, NSLayoutManager, and NSTextStorage - and we already have an NSTextStorage. The text container should be the width of this graphic but very high to accomodate whatever text is typed into it.
    NSRect bounds = [self bounds];
    NSTextContainer *textContainer = [[NSTextContainer alloc] initWithContainerSize:NSMakeSize(bounds.size.width, 1.0e7f)];
    /* NSTextView *textView = [[NSTextView alloc] initWithFrame:bounds textContainer:textContainer]; */ // SatoAkira delete. //
	// ↓SatoAkira add. //
	[_editingView release];
	if (NSTextLayoutOrientationVertical == [self layoutOrientation]) {
		NSRect rRect = rotateRect([self bounds], 0.5 * M_PI);
		// [textContainer setWidthTracksTextView:YES]; 効果無し //
		// [textContainer setHeightTracksTextView:YES]; 効果無し //
		_editingView = [[NSTextView alloc] initWithFrame:NSMakeRect(NSMinX(rRect),NSMinY(rRect),NSHeight(bounds),NSWidth(bounds)) textContainer:textContainer]; // rotateRect()でframeを作っておくとsetLayoutOrientation:をやってもクラッシュしなくなる。縦書きのときは本体の回転角とは無関係に90度回転させる。setFrameCenterRotation:で本体の回転角に合わせてもrulerが使い物にならなくなるので回転無しか90度回転のどちらかとする。 //
		// [(NSTextView *)_editingView setBoundsOrigin:NSMakePoint(NSMinX(rRect) + NSHeight(bounds),NSMinY(rRect))]; 効果無し //
		// [(NSTextView *)_editingView setBaseWritingDirection:NSWritingDirectionRightToLeft]; // はwidthの端すなわち下端に揃えられる。縦書きの向きとは違う。デフォルトはNSWritingDirectionNatural とNSWritingDirectionLeftToRight は同じ動作。 //
		// _editingViewの中ではアンダーラインが右側に引かれるが、drawさせると左側になってしまう。SVGに書き出すと一文字ずつ下側に引かれる。 //
	}
	else
		_editingView = [[NSTextView alloc] initWithFrame:bounds textContainer:textContainer];
	// ↑SatoAkira add. //
    // Create a layout manager that will manage the communication between our text storage and the text container, and hook it up.
	
    NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
    [layoutManager addTextContainer:textContainer];
    [textContainer release];
    NSTextStorage *contents = [self contents]; 
    [contents addLayoutManager:layoutManager];
    [layoutManager release];

    // Of course text editing should be as undoable as anything else.
    /* [textView setAllowsUndo:YES]; */ // SatoAkira delete. //
	[(NSTextView *)_editingView setAllowsUndo:YES]; // SatoAkira add. //

    // This kind of graphic shouldn't appear opaque just because it's being edited.
    /* [textView setDrawsBackground:NO]; */ // SatoAkira delete. //
	[(NSTextView *)_editingView setDrawsBackground:NO]; // SatoAkira add. //
	[(NSTextView *)_editingView setUsesInspectorBar:YES]; // SatoAkira add. usesRulerはデフォルトでYES. _editingViewをsetFrameRotation:してしまうとrulerは非常に使いにくくなる。 //

/*
    // This is has been handy for debugging text editing view size problems though.
    [textView setBackgroundColor:[NSColor greenColor]];
    [textView setDrawsBackground:YES];
*/

    // Start off with the all of the text selected.
    /* [textView setSelectedRange:NSMakeRange(0, [contents length])]; */ // SatoAkira delete. //
	[(NSTextView *)_editingView setSelectedRange:NSMakeRange(0, [contents length])]; // SatoAkira add. //

    // Specify that the text view should grow and shrink to fit the text as text is added and removed, but only in the vertical direction. With these settings the NSTextView will always be large enough to show an extra line fragment but never so large that the user won't be able to see just-typed text on the screen. Sending -setVerticallyResizable:YES to the text view without also sending -setMinSize: or -setMaxSize: would be useless by the way; the default minimum and maximum sizes of a text view are the size of the frame that is specified at initialization time.
    /* [textView setMinSize:NSMakeSize(bounds.size.width, 0.0)];
    [textView setMaxSize:NSMakeSize(bounds.size.width, superviewBounds.size.height - bounds.origin.y)];
    [textView setVerticallyResizable:YES]; */ // SatoAkira delete. //
	// ↓SatoAkira add. //
	if (NSTextLayoutOrientationVertical == [self layoutOrientation])
		[(NSTextView *)_editingView setLayoutOrientation:NSTextLayoutOrientationVertical];
	[(NSTextView *)_editingView setMinSize:NSMakeSize(NSWidth(bounds), 0.0)];
    [(NSTextView *)_editingView setMaxSize:NSMakeSize(NSWidth(bounds), NSHeight(superviewBounds) - NSMinY(bounds))];
	if (NSTextLayoutOrientationVertical == [self layoutOrientation]) {
		[(NSTextView *)_editingView setVerticallyResizable:NO]; // 列方向 //
		[(NSTextView *)_editingView setHorizontallyResizable:YES]; // 行方向 //
	}
	else {
		[(NSTextView *)_editingView setVerticallyResizable:YES]; // 行方向 //
		[(NSTextView *)_editingView setHorizontallyResizable:NO]; // 列方向 //
	}
	[[graphicView enclosingScrollView] setHasHorizontalRuler:(NSTextLayoutOrientationHorizontal == [self layoutOrientation]) ? YES : NO];// Also, if -enclosingScrollView returns non-nil, it reconfigures horizontal and vertical ruler views, horizontal and vertical scrollers, and the frame. horizontalRuler,verticalRulerの両方ともYESにすると、NSTextLayoutOrientationVerticalのときクラッシュしてしまう。 //
	[[graphicView enclosingScrollView] setHasVerticalRuler:(NSTextLayoutOrientationHorizontal == [self layoutOrientation]) ? NO : YES];
	if (0 == [[self contents] length]) { // 最初にSKTTextを作ったとき //
		NSFontDescriptor *descriptor = [[[[graphicView window] windowController] document] valueForKey:SKTFontDescriptorKey];
		NSDictionary *fontPanelAttributes = [descriptor fontAttributes];
		NSData *colorData = [fontPanelAttributes objectForKey:NSForegroundColorAttributeName];

		[(NSTextView *)_editingView setFont:[NSFont fontWithDescriptor:descriptor textTransform:[descriptor matrix]]];
		if (nil != colorData)
			[(NSTextView *)_editingView setTextColor:[NSUnarchiver unarchiveObjectWithData:colorData]];
		_isDrawingStroke = NO; // SKTGraphicのデフォルトがYESなのでTextとして通常のNOにする。undoが動かないように直接代入してしまう。 //
	}
	// ↑SatoAkira add. //

    // The invoker doesn't have to release this object.
    /* return [textView autorelease]; */ // SatoAkira delete. //
	return _editingView;

}


/* - (void)finalizeEditingView:(NSView *)editingView {
 
 // Tell our text storage that it doesn't have to talk to the editing view's layout manager anymore.
 [[self contents] removeLayoutManager:[(NSTextView *)editingView layoutManager]];
 
} */ // SatoAkira delete. //
- (void)finalizeEditingView:(NSView *)editingView view:(NSView *)graphicView
// SatoAkira add. //
{
	NSTextStorage *contents = [self contents];
	NSUInteger length = [contents length];

    [contents removeLayoutManager:[(NSTextView *)_editingView layoutManager]];
	if (0 == length) {
		NSRect bounds = [self bounds];
		[self setBounds:NSMakeRect(NSMinX(bounds),NSMinY(bounds),0.0,0.0)];
		// [[self document] removeGraphic:self]; 以前 //
	}
	else {
		NSDictionary *attributes = [[self contents] attributesAtIndex:length - 1 effectiveRange:NULL];
		NSFont *font = [attributes objectForKey:NSFontAttributeName];
		NSMutableDictionary *fontAttributes = [NSMutableDictionary dictionaryWithDictionary:[[font fontDescriptor] fontAttributes]];
		NSColor *fillColor = [attributes objectForKey:NSForegroundColorAttributeName];
		// [fontAttributes objectForKey:NSForegroundColorAttributeName]; はnilになる。 //
		
		if (nil != fillColor)
			[fontAttributes setObject:[NSArchiver archivedDataWithRootObject:fillColor] forKey:NSForegroundColorAttributeName];
		[[[[graphicView window] windowController] document] setValue:[NSFontDescriptor fontDescriptorWithFontAttributes:fontAttributes] forKey:SKTFontDescriptorKey];
	}
	[_editingView release];
	_editingView = nil;
	[[graphicView enclosingScrollView] setHasHorizontalRuler:YES]; // 元に戻す。 //
	[[graphicView enclosingScrollView] setHasVerticalRuler:YES]; // 元に戻す。 //
}

- (NSSet *)keysForValuesToObserveForUndo {

    // Observation of "undoContents," and the observer's resulting registration of changes with the undo manager, is only valid when changes are made to text contents via scripting. When changes are made directly by the user in a text view the text view will register better, more specific, undo actions. Also, we don't want some changes of bounds to result in undo actions.
    NSSet *keysToReturn = [super keysForValuesToObserveForUndo];
    if (_contentsBeingChangedByScripting || _boundsBeingChangedToMatchContents) {
	NSMutableSet *keys = [keysToReturn mutableCopy];
	if (_contentsBeingChangedByScripting) {
	    [keys addObject:SKTTextUndoContentsKey];
	}
	if (_boundsBeingChangedToMatchContents) {
	    [keys removeObject:SKTGraphicBoundsKey];
	}
	keysToReturn = [keys autorelease];
    }
    return keysToReturn;

}


+ (NSString *)presentablePropertyNameForKey:(NSString *)key {

    // Pretty simple. As is usually the case when a key is passed into a method like this, we have to invoke super if we don't recognize the key.
    static NSDictionary *presentablePropertyNamesByKey = nil;
    if (!presentablePropertyNamesByKey) {
	presentablePropertyNamesByKey = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
	    NSLocalizedStringFromTable(@"Text", @"UndoStrings", @"Action name part for SKTTextUndoContentsKey."), SKTTextUndoContentsKey,
	    nil];
    }
    NSString *presentablePropertyName = [presentablePropertyNamesByKey objectForKey:key];
    if (!presentablePropertyName) {
	presentablePropertyName = [super presentablePropertyNameForKey:key];
    }
    return presentablePropertyName;

}
- (NSXMLElement *)textShadowFilter:(NSString *)unique_ID textShadow:(NSShadow *)textShadow effectRect:(NSRect)bounds
// SatoAkira add.textのDropShadowはInkscapeと互換性が無い。Batik,Operaとも互換性が無い。 //
{
	if (nil != textShadow) {
		NSSize textShadowOffset = (nil != textShadow) ? [textShadow shadowOffset] : NSZeroSize;
		CGFloat textShadowBlurRadius = (nil != textShadow) ? [textShadow shadowBlurRadius] : MAXFLOAT;
		NSXMLElement *filterElement = [NSXMLElement elementWithName:@"filter"];
		NSMutableArray *filterAttributes = [NSMutableArray arrayWithObjects:[NSXMLNode attributeWithName:@"id" stringValue:unique_ID],[NSXMLNode attributeWithName:@"filterUnits" stringValue:@"objectBoundingBox"],nil];
		CGFloat dx = textShadowOffset.width;
		CGFloat dy = -1.0 * textShadowOffset.height;
		// NSLog(@"dx=%f dy=%f",dx,dy); //
		double l = hypot(dy,dx);
		double angle = atan3(dy, dx);
		double x = l * cos(angle - [self rotateAngle]);
		double y = l * sin(angle - [self rotateAngle]);
		double blurOffset = (MAXFLOAT - 1e32 > textShadowBlurRadius) ? textShadowBlurRadius / 3.5 : 0.0; // 3.5は根拠が無い。blurが100.0までならば大体これでいける。 //
		NSRect shadowBounds = NSInsetRect(bounds, -1.0 * blurOffset, -1.0 * blurOffset);
		if (0.0 < x) shadowBounds.size.width += x;
		else if (0.0 > x)  { shadowBounds.origin.x += x; shadowBounds.size.width -= x; } 
		// ISFLIPPED 1 のとき //
		if (0.0 > y) shadowBounds.size.height -= y;
		else if (0.0 < y)  { shadowBounds.origin.y -= y; shadowBounds.size.height += y; }
		x = (0.0 >= dx) ? 100.0 * (dx - blurOffset) / NSWidth(bounds) : (dx < blurOffset) ? 100.0 * (dx - blurOffset) / NSWidth(bounds) : 0.0;
		y = (0.0 >= dy) ? 100.0 * (dy - blurOffset) / NSHeight(bounds) : (dy < blurOffset) ? 100.0 * (dy - blurOffset) / NSHeight(bounds) : 0.0;
		double width = 100.0 * NSWidth(shadowBounds) / NSWidth(bounds);
		double height = 100.0 * NSHeight(shadowBounds) / NSHeight(bounds);
		NSColor *shadowColor = (nil != textShadow) ? [textShadow shadowColor] : [NSColor blackColor];
		if (nil == shadowColor)
			shadowColor = [NSColor blackColor];
		CGFloat alpha = (NO == [[shadowColor colorSpaceName] isEqualToString:NSPatternColorSpace]) ? [shadowColor alphaComponent] : 0.5;
		NSString *matrixStr = [NSString stringWithFormat:@"1 0 0 0 0 0 1 0 0 0 0 0 1 0 0 0 0 0 %g 0",(1.0 > alpha) ? alpha : 1.0]; // アルファのみを変換するマトリクス //
		double stdDeviation = (MAXFLOAT - 1e32 > textShadowBlurRadius) ? (1.0 > textShadowBlurRadius) ? textShadowBlurRadius : sqrt(textShadowBlurRadius) : 0.0;
		[filterAttributes addObject:[NSXMLNode attributeWithName:@"x" stringValue:[NSString stringWithFormat:@"%g%%",x]]];
		[filterAttributes addObject:[NSXMLNode attributeWithName:@"y" stringValue:[NSString stringWithFormat:@"%g%%",y]]];
		[filterAttributes addObject:[NSXMLNode attributeWithName:@"width" stringValue:[NSString stringWithFormat:@"%g%%",width]]];
		[filterAttributes addObject:[NSXMLNode attributeWithName:@"height" stringValue:[NSString stringWithFormat:@"%g%%",height]]];
		[filterElement setAttributes:filterAttributes];
		[filterElement addChild:[NSXMLNode elementWithName:@"feGaussianBlur" children:nil attributes:[NSArray arrayWithObjects:[NSXMLNode attributeWithName:@"in" stringValue:@"SourceAlpha"],[NSXMLNode attributeWithName:@"stdDeviation" stringValue:[NSString stringWithFormat:@"%g",stdDeviation]],[NSXMLNode attributeWithName:@"result" stringValue:@"black"], nil]]]; // CocoaのBlurRadiusは0.0以上。 //
		[filterElement addChild:[NSXMLNode elementWithName:@"feColorMatrix" children:nil attributes:[NSArray arrayWithObjects:[NSXMLNode attributeWithName:@"type" stringValue:@"matrix"],[NSXMLNode attributeWithName:@"result" stringValue:@"blurAlpha"],[NSXMLNode attributeWithName:@"values" stringValue:matrixStr],nil]]]; // 黒1色からアルファのみを変換するので黒い影しかできない。 //
		[filterElement addChild:[NSXMLNode elementWithName:@"feOffset" children:nil attributes:[NSArray arrayWithObjects:[NSXMLNode attributeWithName:@"in" stringValue:@"blurAlpha"],[NSXMLNode attributeWithName:@"dx" stringValue:[NSString stringWithFormat:@"%g",dx]],[NSXMLNode attributeWithName:@"dy" stringValue:[NSString stringWithFormat:@"%g",dy]],[NSXMLNode attributeWithName:@"result" stringValue:@"movedShadow"],nil]]]; // dx,dyに単位を与えるとBatikは文句を言ってくる。 //
		[filterElement addChild:[NSXMLNode elementWithName:@"feMerge" children:[NSArray arrayWithObjects:[NSXMLNode elementWithName:@"feMergeNode" children:nil attributes:[NSArray arrayWithObject:[NSXMLNode attributeWithName:@"in" stringValue:@"movedShadow"]]],[NSXMLNode elementWithName:@"feMergeNode" children:nil attributes:[NSArray arrayWithObject:[NSXMLNode attributeWithName:@"in" stringValue:@"SourceGraphic"]]],nil] attributes:nil]];
		return filterElement;
	}
	else
		return nil;
}
- (NSArray *)svgXMLElements:(NSRect)aRect name:(NSString *)unique_ID
// SatoAkira add. NSLayoutManagerからは、表形式に関する情報は取れない。また、_contentsにはNSLayoutManagerをくっつけていない。わざわざ、外している。rtfDataの中に、表に関するデータがあるようだ。なぜなら、NSTextStorageで保存させると表形式がすっとんでしまうからである。 //
{
	NSRect bounds = [self bounds];
			
	if ((NO == [[self contents] containsAttachments]) && (0 < [[self contents] length]) && (1.0 <= NSWidth(bounds)) && (1.0 <= NSHeight(bounds))) {
		NSMutableArray *elements = [NSMutableArray arrayWithObject:[NSXMLNode commentWithStringValue:NSStringFromClass([self class])]];
		NSTextStorage *contents = [self contents];
		NSLayoutManager *lm = [[self class] sharedLayoutManager];
		NSTextContainer *tc = [[lm textContainers] objectAtIndex:0];
		
		[lm setTypesetterBehavior:NSTypesetterLatestBehavior];
		[lm setUsesScreenFonts:YES]; // NOにするとnaturalSizeになっているときに幅が足りなくなってずっこける。 //
		// [tc setLineFragmentPadding:0.0]; を絶対にしてはいけない。通常では5.0ピクセルになっている。 //
		[tc setContainerSize:bounds.size];
		[contents addLayoutManager:lm];
		NSRange glyphRange = [lm glyphRangeForTextContainer:tc];
		NSTextLayoutOrientation orientation = [self layoutOrientation];
		CGFloat translateX = NSMidX(bounds) - NSMinX(aRect); // 回転の中心であって文字列の中心ではない。 //
		CGFloat translateY = NSMidY(bounds) - NSMinY(aRect);
		CGFloat lineFragmentPadding = [tc lineFragmentPadding];
		NSRect bRect = [lm boundingRectForGlyphRange:glyphRange inTextContainer:tc]; // bRectの原点は(0.0,0.0) //
		NSArray *defsAndRect = [self svgDefsAndRect:unique_ID allGraphics:aRect bounds:NSMakeRect(NSMinX(bounds) + lineFragmentPadding,NSMinY(bounds),NSWidth(bRect),NSHeight(bRect)) transform:nil];
		if (0 < [defsAndRect count])
			[elements addObjectsFromArray:defsAndRect];
		// 表形式が混じっているかどうかの検証開始 //
		NSRange aRange;
		NSArray *textBlocks;
		NSParagraphStyle *paragraphStyle;
		BOOL isTextBlock = NO;
		NSArray *paragraphs = [[self contents] paragraphs];
		for (NSTextStorage *sub in paragraphs) { // NSSubTextStroage //
			paragraphStyle = [sub attribute:NSParagraphStyleAttributeName atIndex:0 effectiveRange:&aRange];
			if ((nil != paragraphStyle) && (nil != (textBlocks = [paragraphStyle textBlocks])) && (0 < [textBlocks count])) {
				isTextBlock = YES;
				break;
			}
		}
		// 表形式が混じっているかどうかの検証終了 //
		if (NO == isTextBlock) { // 表形式が混じっていなければ //
			if (0 < glyphRange.length) {
				NSUInteger i,j,numberOfLines;
				NSRange lfr;
				NSRect lfRect,shadowRect;
				NSColor *tempColor;
				NSData *fillColorData;
				NSFont *tempFont;
				NSDictionary *tempFontAttributes,*tempAttr;
				NSString *aStr,*tempFontName;
				CGFloat tempFontSize;
				NSNumber *tempUnderline,*tempStrikethrough;
				NSShadow *tempShadow,*textShadow;
				NSPoint gl,movePoint;
				NSMutableArray *attributes = [NSMutableArray arrayWithObjects:svgTransformNode(translateX,translateY,[self rotateAngle],1.0,1.0),nil];
				NSXMLElement *element = [NSXMLElement elementWithName:@"text"];
				CGFloat tempLfRectY = 0.0;
				NSDictionary *attr = [contents attributesAtIndex:0 effectiveRange:NULL]; // 先頭文字のattribute //
				NSFont *font = [attr objectForKey:NSFontAttributeName];
				NSDictionary *fontAttributes = [[font fontDescriptor] fontAttributes];
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_4
				NSString *fontName = [font fontName];
				CGFloat fontSize = [font pointSize]; // [[font fontDescriptor] pointSize]は結果不定。 //
#else
				NSString *fontName = [fontAttributes objectForKey:NSFontNameAttribute];
				float fontSize = [[fontAttributes objectForKey:NSFontSizeAttribute] floatValue];
#endif
				NSColor *strokeColor = (YES == [self isDrawingStroke]) ? [self  strokeColor] : nil; // SKTTextArea.mの仕様によりstrokeColorが途中で変わることはない。 //
				CGFloat strokeWidth = (nil != [attr objectForKey:NSStrokeWidthAttributeName]) ? fabs(0.01 * fontSize * [[attr objectForKey:NSStrokeWidthAttributeName] floatValue]) : -1.0;
				BOOL tspanFlag = NO;
				NSColor *fillColor = [attr objectForKey:NSForegroundColorAttributeName]; //　黒のときnilとなるので要注意。 //
				// SVGにはNSUnderlineColorAttributeNameを指定する方法がない。 //
				// SVGにはNSStrikethroughColorAttributeNameを指定する方法がない。 //
				// NSBaselineOffsetAttributeNameの値は，総てy座標が吸収するのでbaseline-shiftは設定しない。<text の中でstyle="baseline-shift:baseline"としても無視されるので指定しない。 //
				NSInteger fillAndStroke = 1;
				NSDictionary *tspanAttr = [NSDictionary dictionary]; // <text>で指定した属性と比較するのは，それぞれの変数の値なので空でも良い。 //
				NSMutableString *xStr = [NSMutableString string]; // 総ての文字の位置を指定するのでkerning:0としてautoでなくする。 //
				NSMutableString *yStr = [NSMutableString string];
				NSArray *fillNodes = nil;
				NSMutableString *styleStr = [NSMutableString string];
				NSMutableString *stringStr = [NSMutableString string];
				NSXMLElement *tspanElement = nil;
				NSXMLNode *xmlSpaceNode = [NSXMLNode attributeWithName:@"xml:space" stringValue:@"preserve"]; // <text の中でやるとinvalid contextというerrorになるものがある。Seashoreなど。 //
				NSMutableCharacterSet *wsAndNewline = [NSCharacterSet whitespaceAndNewlineCharacterSet]; // notShownAttributeForGlyphAtIndex:で判断するのは、Some glyphs are not shown. For example, a tab, newline, or attachment glyph is not shown; notShownAttributeForGlyphAtIndex:以外の文字もこのcharacterSetで判断する。 //
				
				if ((nil != [attr objectForKey:NSCharacterShapeAttributeName]) && (0.0 != [[attr objectForKey:NSCharacterShapeAttributeName] integerValue])) {
					NSLog(@"%ld",[[attr objectForKey:NSCharacterShapeAttributeName] integerValue]);
				}
				if ((0.0 == [self strokeWidth]) && (YES == [self isDrawingStroke]))
					fillAndStroke = 2; // fill=noneのときアンダーラインが表示されなくなるがSVGの仕様によりアンダーラインのカラーを指定できないので仕方ない。 //
				else {
					if ((0.0 < [self strokeWidth]) && (YES == [self isDrawingStroke])) {
						fillAndStroke = 3;
					}
				}
				if (nil == fillColor)
					fillColor = [NSColor blackColor]; // nilのままだとequalなどの比較が面倒なのでblackにしてしまう。 //			
				fillColorData = [NSArchiver archivedDataWithRootObject:fillColor];
				NSXMLNode *fillNode;
				NSMutableArray *textColorNodes = [NSMutableArray array];
				if ((2 != fillAndStroke) && (YES == [[fillColor colorSpaceName] isEqualToString:NSPatternColorSpace]))
					[textColorNodes addObject:svgPatternNode([NSString stringWithFormat:@"%@_textFill", unique_ID],@"fill",[fillColor patternImage],NSMakePoint(-0.5 * NSWidth([self bounds]),-0.5 * NSHeight([self bounds])))];
				if (YES == [[strokeColor colorSpaceName] isEqualToString:NSPatternColorSpace])
					[textColorNodes addObject:svgPatternNode([NSString stringWithFormat:@"%@_textStroke", unique_ID],@"stroke",[strokeColor patternImage],NSMakePoint(-0.5 * NSWidth([self bounds]),-0.5 * NSHeight([self bounds])))];
				[attributes addObjectsFromArray:(2 == fillAndStroke) ? svgColorNodes([NSString stringWithFormat:@"%@_textFill", unique_ID],@"fill",@"fill",nil) : svgColorNodes([NSString stringWithFormat:@"%@_textFill", unique_ID],@"fill",@"fill",fillColor)];
				[attributes addObjectsFromArray:svgColorNodes([NSString stringWithFormat:@"%@_textStroke", unique_ID],@"stroke",@"stroke",strokeColor)];
				if (YES == [self isDrawingStroke])
					[attributes addObject:svgStrokeWidthNode(strokeWidth)];
				if (NSTextLayoutOrientationVertical == orientation) {
					// 縦書きのときは、なかなかうまく行かない。回転角から90度少ない角度でrotate()させ、x座標とy座標とを入れ替え、glyph-orientation-vertical:をautoにすると、やや近くなるが、漢字の向きが変わらないので横書き用のグリフとなってしまう。横書き用のグリフとなってしまい、いろいろいじっても価値がないのでやめる。 //
					// rotate()は回転角そのままの値とし、writing-mode:tb とする。rotate()による回転角が掛かっているためglyph-orientation-vertical:270　としてグリフの向きを修正する。1文字ごとにx,y座標値を指定することは必須である。これが無いと、回転角が掛かっているため縦方向に進まなくなる。glyph-orientation-vertical が有るのでBasicLatin が縦向きになってしまうのでSketchyDrawの設定と異なってしまう。現在のところ、この方法が最もSketchyDrawの設定と近いところに配置される。 //
					// Webkit では句読点が縦書き用のグリフにならない。Opera では縦書き用のグリフになる。 //
					[attributes addObject:[NSXMLNode attributeWithName:@"style" stringValue:[NSString stringWithFormat:@"%@;kerning:0%@;writing-mode:tb;glyph-orientation-vertical:270;",svgFontFrom(font),svgUnit]]];
				}
				else
					[attributes addObject:[NSXMLNode attributeWithName:@"style" stringValue:[NSString stringWithFormat:@"%@;kerning:0%@;",svgFontFrom(font),svgUnit]]];
				[element setAttributes:attributes];
				textShadow = nil;
				tempFontSize = fontSize;
				for (numberOfLines = 0, i = 0; i < [lm numberOfGlyphs]; numberOfLines++) {
					lfRect = [lm lineFragmentUsedRectForGlyphAtIndex:i effectiveRange:&lfr]; // attributesが変わってもlfrの区切り目にはならない。 //
					gl = [lm locationForGlyphAtIndex:i]; // 単なる初期値で行の最初がnotShownAttributeForGlyphAtIndex:になったときに暴走することを防ぐため。 //
					if (tempLfRectY > lfRect.origin.y)
						break;
					else
						tempLfRectY = lfRect.origin.y;
					for (j = i; j < i + lfr.length; j++) {
						aStr = [[contents attributedSubstringFromRange:NSMakeRange(j,1)] string];
						if (NO == [lm notShownAttributeForGlyphAtIndex:j]) { // WebKitに描かせるとスペース文字が数多く繋がったときにずっこけるので、対象外とする。 //
							if ((nil != (tempAttr = [contents attributesAtIndex:j effectiveRange:NULL])) && (NO == [tspanAttr isEqualToDictionary:tempAttr])) {
								if (YES == tspanFlag) {
									[tspanElement addAttribute:[xmlSpaceNode copy]];
									if (NO == [xStr isEqualToString:@""])
										[tspanElement addAttribute:[NSXMLNode attributeWithName:@"x" stringValue:xStr]];
									if (NO == [yStr isEqualToString:@""])
										[tspanElement addAttribute:[NSXMLNode attributeWithName:@"y" stringValue:yStr]];
									if (nil != fillNodes) {
										for (fillNode in fillNodes)
											[tspanElement addAttribute:fillNode];
									}
									if (NO == [styleStr isEqualToString:@""])
										[tspanElement addAttribute:[NSXMLNode attributeWithName:@"style" stringValue:styleStr]];
									if (nil != tempShadow) {
										[tspanElement addAttribute:[NSXMLNode attributeWithName:@"filter" stringValue:[NSString stringWithFormat:@"url(#dropShadow_%@)",unique_ID]]];
										textShadow = tempShadow;
										shadowRect = lfRect;
									}
									[tspanElement setStringValue:stringStr];
									[element addChild:tspanElement]; // </tspan>のうしろに改行がついてしまうので余分なスペースがつくはずである。直しようがないのでこのままにしておく。 //
									[tspanElement release];
									tspanElement = nil;
								}
								tspanElement = [[NSXMLElement allocWithZone:[self zone]] initWithName:@"tspan"]; // 最初のものとの違いがなければ<tspan>となる。 //
								xStr = [NSMutableString string];
								yStr = [NSMutableString string];
								fillNodes = nil;
								styleStr = [NSMutableString string];
								stringStr = [NSMutableString string];
								if (nil == (tempColor = [tempAttr objectForKey:NSForegroundColorAttributeName]))
									tempColor = [NSColor blackColor];
								if ((2 != fillAndStroke) && (NO == [fillColorData isEqualToData:[NSArchiver archivedDataWithRootObject:tempColor]]))
									fillNodes = svgColorNodes(unique_ID,@"fill",@"fill",tempColor);
								tempUnderline = [tempAttr objectForKey:NSUnderlineStyleAttributeName]; // nilかNSUnderlineStyleNoneのとき無し，ある場合はMaskのかかったint //
								tempStrikethrough = [tempAttr objectForKey:NSStrikethroughStyleAttributeName]; // nilかNSUnderlineStyleNoneのとき無し，ある場合はMaskのかかったint //
								if (nil == tempUnderline)
									tempUnderline = [NSNumber numberWithInt:NSUnderlineStyleNone];
								if (nil == tempStrikethrough)
									tempStrikethrough = [NSNumber numberWithInt:NSUnderlineStyleNone];
								if (NO == [svgUnderlineFrom(tempUnderline,tempStrikethrough) isEqualToString:@""])
									[styleStr appendFormat:@"%@;",svgUnderlineFrom(tempUnderline,tempStrikethrough)]; // 途中でアンダーラインが無くなったとき，Adobe SVGViewerのtext-decoration:noneでは対応できないので，tspanとしなければならない。 //
								tempFont = [tempAttr objectForKey:NSFontAttributeName];
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_4
								tempFontAttributes = [[tempFont fontDescriptor] fontAttributes];
								tempFontName = [tempFont fontName];
								tempFontSize = [tempFont pointSize];
#else
								tempFontAttributes = [[tempFont fontDescriptor] fontAttributes];
								tempFontName = [tempFontAttributes objectForKey:NSFontNameAttribute];
								tempFontSize = [[tempFontAttributes objectForKey:NSFontSizeAttribute] floatValue];
#endif
								tempShadow = [tempAttr objectForKey:NSShadowAttributeName]; // nilもある。 //
								if (NO == [fontAttributes isEqualToDictionary:tempFontAttributes]) {
									if (NO == [fontName isEqualToString:tempFontName])
										[styleStr appendFormat:@"%@;",svgFontFrom(tempFont)]; // font-family //
									if (fontSize != tempFontSize) {
										[styleStr appendFormat:@"font-size:%g%@;",tempFontSize,svgUnit]; // Opera,Firefoxでは単位が必須。Operaでは単位が無いと1pxくらいにしてしまう。Firefoxでは何も表示しなくなる。tempFontSizeがfontSizeと異なったときにgl.xがずっこける。 //
									}
								}
								tspanAttr = [NSDictionary dictionaryWithDictionary:tempAttr];
								tspanFlag = YES;
								// NSLog(@"descender=%f ascender=%f pad=%f",[tempFont descender],[tempFont ascender],lineFragmentPadding); //
							}
						}
						if (NO == [wsAndNewline characterIsMember:[aStr characterAtIndex:0]]) { // WebKitに描かせるとスペース文字が数多く繋がったときにずっこけるので、対象外とする。 //
							if (YES == [lm notShownAttributeForGlyphAtIndex:j]) { // [lm locationForGlyphAtIndex:j]は次の文字位置を指してしまう。[lm locationForGlyphAtIndex:j - 1].x + [tempFont advancementForGlyph:[lm glyphAtIndex:j - 1]].widthも次の文字位置を指してしまう。[tempFont boundingRectForGlyph:[lm glyphAtIndex:j]]もまともな値が返ってこない。gl.yはしかたないので前の値をそのまま使う。行の最初や最後でnotShownAttributeForGlyphAtIndex:になってしまったらどうしようもない。ASSVGImageRepに読ませるとずっこける。WebKit,Opera,Batikなどの仕様にあわせるしかないのでこのようにする。 //
								gl.x = (0 < j) ? [lm locationForGlyphAtIndex:j - 1].x : [lm locationForGlyphAtIndex:0].x;
								gl.x += (i + lfr.length - 1 > j) ? [lm locationForGlyphAtIndex:j + 1].x : [lm locationForGlyphAtIndex:j].x;
								gl.x *= 0.5;
							}
							else
								gl = [lm locationForGlyphAtIndex:j];
							// -0.5 * NSWidth(bounds) + NSWidth([lm boundingRectForGlyphRange:NSMakeRange(i,j - i) inTextContainer:tc]);   -0.5 * NSWidth(bounds) + NSMinX(lfRect) + gl.x;  結果は同じ。 //
							// Webkit,Opera,Firefoxとの間にはかなり相違があって総てに互換なものを作ることが困難である。x=,y=の属性値については、直しようがない。 //
							// rotate(90) //
							if (NSTextLayoutOrientationVertical == orientation) {
								// 縦書きメトリックが使用されたフォントにおいては、Baselineは通常、グリフの中央にひかれた垂直線である。原点は中央上である。 //
								movePoint.x = -0.5 * NSWidth(bounds) + gl.x + 0.5 * tempFontSize; // 中央上なのでAscenderかもしれない。 //
								movePoint.y = -0.5 * NSHeight(bounds) + NSMinY(lfRect) + gl.y - 0.5 * tempFontSize; // tempFontSizeはNSHeight(lfRect) - gl.y とは値が異なる。 //
								// NSLog(@"gl.y=%f heightOflfRect=%f fontSize=%f tempFontSize=%f",gl.y,NSHeight(lfRect),fontSize,tempFontSize); //
							}
							else {
								movePoint.x = -0.5 * NSWidth(bounds) + gl.x; // 左下を指す。0.5 * NSWidth(bounds) == NSMinX(lfRect) + 0.5 * NSWidth(lfRect)である。gl.xはNSMinX(lfRect) + LineFlagmentPaddingから始まる。SVGの方ではLineFlagmentPaddingが無いのでLineFragmentを引かなければ一致する。 //
								movePoint.y = -0.5 * NSHeight(bounds) + NSMinY(lfRect) + gl.y; // 左下を指す。SVGではBaselineの位置が基準になるのでgl.yの分だけずらす。 //
							}
							if (0 < [xStr length]) {
								[xStr appendFormat:@" %g%@",movePoint.x,svgUnit];
								[yStr appendFormat:@" %g%@",movePoint.y,svgUnit];
							}
							else { // WebKitでは、先頭にスペースがあるとずっこける。 //
								[xStr appendFormat:@"%g%@",movePoint.x,svgUnit];
								[yStr appendFormat:@"%g%@",movePoint.y,svgUnit];
							}
							[stringStr appendString:aStr];
						}
					}
					i = NSMaxRange(lfr);
				}
				if (YES == tspanFlag) {
					[tspanElement addAttribute:[xmlSpaceNode copy]];
					if (NO == [xStr isEqualToString:@""])
						[tspanElement addAttribute:[NSXMLNode attributeWithName:@"x" stringValue:xStr]];
					if (NO == [yStr isEqualToString:@""])
						[tspanElement addAttribute:[NSXMLNode attributeWithName:@"y" stringValue:yStr]];
					if (nil != fillNodes) {
						for (fillNode in fillNodes)
							[tspanElement addAttribute:fillNode];
					}
					if (NO == [styleStr isEqualToString:@""])
						[tspanElement addAttribute:[NSXMLNode attributeWithName:@"style" stringValue:styleStr]];
					if (nil != tempShadow) {
						[tspanElement addAttribute:[NSXMLNode attributeWithName:@"filter" stringValue:[NSString stringWithFormat:@"url(#dropShadow_%@)",unique_ID]]];
						textShadow = tempShadow;
						shadowRect = lfRect;
					}
					[tspanElement setStringValue:stringStr];
					[element addChild:tspanElement]; // </tspan>のうしろに改行がついてしまうので余分なスペースがつくはずである。直しようがないのでこのままにしておく。 //
					[tspanElement release];
					tspanElement = nil;
				}
				if (nil != textShadow) { // 面倒くさいので一番最後のtextShadowを使う。配列を使って丁寧にやれば良いがそれほどの価値はないのでやめる。 //
					NSXMLElement *shadowFilter = [self textShadowFilter:[NSString stringWithFormat:@"dropShadow_%@" ,unique_ID] textShadow:textShadow effectRect:shadowRect];
					if (nil != shadowFilter)
						[textColorNodes addObject:shadowFilter];
				}
				if (0 < [textColorNodes count])
					[elements addObject:[NSXMLNode elementWithName:@"defs" children:textColorNodes attributes:nil]];
				[elements addObject:element];
			}
			// else NSHeight(bounds)が1行の高さより小さいときがここになる。文字列が表示されていないので空配列を返す。 //
			[contents removeLayoutManager:lm];
		} // if (NO == isTextBlock) //
		if (YES == isTextBlock) {
			NSRect renderingRect = NSMakeRect(0.0,0.0,NSWidth(bounds),NSHeight(bounds)); // 拡大してもフォントサイズが拡大されないので駄目である。従って72dpiにしかならない。 //
			NSTextView *textView = [[NSTextView alloc] initWithFrame:renderingRect textContainer:tc];
			[lm setTypesetterBehavior:NSTypesetterLatestBehavior];
			[tc setContainerSize:bounds.size];
			[contents addLayoutManager:lm];
			[textView setDrawsBackground:NO];
			NSData *pdfData = [textView dataWithPDFInsideRect:renderingRect]; // PDFの方が小さい。SVGがimage/pdfをサポートしていれば、これを使える。 //
			NSImage *rasterImage = [[NSImage allocWithZone:[self zone]] initWithData:pdfData];
			[rasterImage setDataRetained:YES];
			[rasterImage setFlipped:NO];
			NSData *tiffData = [rasterImage TIFFRepresentationUsingCompression:NSTIFFCompressionNone factor:1.0];
			NSBitmapImageRep *anImageImageRep = [NSBitmapImageRep imageRepWithData:tiffData];
			[anImageImageRep setSize:bounds.size];
			NSString *base64Str = (nil != anImageImageRep) ? imageRepToBase64(anImageImageRep) : nil;
			[textView release];
			[rasterImage release];
			if (nil != base64Str) {
				CGFloat translateX = NSMidX(bounds) - NSMinX(aRect);
				CGFloat translateY = NSMidY(bounds) - NSMinY(aRect);
				NSXMLElement *element = [NSXMLElement elementWithName:@"image"];
				NSArray *attributes = [NSArray arrayWithObjects:svgTransformNode(translateX,translateY,[self rotateAngle],1.0,1.0),[NSXMLNode attributeWithName:@"x" stringValue:[NSString stringWithFormat:@"%g%@",-0.5 * NSWidth(bounds),svgUnit]],[NSXMLNode attributeWithName:@"y" stringValue:[NSString stringWithFormat:@"%g%@",-0.5 * NSHeight(bounds),svgUnit]],[NSXMLNode attributeWithName:@"width" stringValue:[NSString stringWithFormat:@"%g%@",NSWidth(bounds),svgUnit]],[NSXMLNode attributeWithName:@"height" stringValue:[NSString stringWithFormat:@"%g%@",NSHeight(bounds),svgUnit]],[NSXMLNode attributeWithName:@"preseveAspectRatio" stringValue:@"none"],[NSXMLNode attributeWithName:@"xlink:href" stringValue:[NSString stringWithFormat:@"data:%@",base64Str]],nil];
				[element setAttributes:attributes];
				[elements addObject:element];
			}
			/* NSArray *textLists,*tabStops;
			NSTextTableBlock *textTableBlock;
			NSTextTable *textTable;
			NSTextTab *textTab;
			NSUInteger j;

			for (i = 0; i < [paragraphs count]; i++) {
				sub = [paragraphs objectAtIndex:i]; // NSSubTextStroage //
				paragraphStyle = [sub attribute:NSParagraphStyleAttributeName atIndex:0 effectiveRange:&aRange];
				textLists = [paragraphStyle textLists]; // 表のみの場合、何も無いcount0 //
				tabStops = [paragraphStyle tabStops];
				if ((nil != paragraphStyle) && (nil != (textBlocks = [paragraphStyle textBlocks])) && (0 < [textBlocks count])) { // NSTextTableBlock //
					for (j = 0; j < [textBlocks count]; j++) { // 通常はcount1 //
						// [textTableBlock valueForDimension:NSTextBlockWidth]は等分割のとき総て0.0になる。高さはフォントサイズによって決まる。 //
						textTableBlock = [textBlocks objectAtIndex:j];
						textTable = [textTableBlock table];
						NSLog(@"i=%lu j=%lu columns=%lu contentWidth=%f",i,j,[textTable numberOfColumns],[textTableBlock valueForDimension:NSTextBlockWidth]);
						// NSLog(@"j=%lu length=%lu %@",j,glyphRange.length,NSStringFromRect([lm boundsRectForTextBlock:textTableBlock glyphRange:glyphRange])); //

					}
				}
				if ((nil != tabStops) && (0 < [tabStops count])) {
					for (j = 0; j < [tabStops count]; j++) {
						textTab = [tabStops objectAtIndex:j];
						// NSLog(@"j=%lu location=%f tabStopType=%ld alignment=%ld",j,[textTab location],[textTab tabStopType],[textTab alignment]); //
					}
				}
				// NSLog(@"i=%lu textLists count=%lu",i,[textLists count]); //
			} */
		}
		return elements;
	}
	else {
		if ((YES == [[self contents] containsAttachments]) && (0 < [[self contents] length]) && (1.0 <= NSWidth(bounds)) && (1.0 <= NSHeight(bounds))) { // SKTeps.mやSKTpdf.mとだいたい同じ //
			NSMutableArray *elements = nil;
			CGFloat translateX = NSMidX(bounds) - NSMinX(aRect); // 回転の中心であって文字列の中心ではない。 //
			CGFloat translateY = NSMidY(bounds) - NSMinY(aRect);
			// tcをセットするのに必要。 //
			NSTextStorage *contents = [self contents];
			NSLayoutManager *lm = [[self class] sharedLayoutManager];
			NSTextContainer *tc = [[lm textContainers] objectAtIndex:0];
			[lm setTypesetterBehavior:NSTypesetterLatestBehavior];
			[lm setUsesScreenFonts:YES]; // NOにするとnaturalSizeになっているときに幅が足りなくなってずっこける。 //
			[tc setContainerSize:bounds.size];
			[contents addLayoutManager:lm];
			// tcセット終了 //
			NSTextView *renderingView = [[NSTextView alloc] initWithFrame:bounds textContainer:tc];
			NSData *aData = [renderingView dataWithPDFInsideRect:NSMakeRect(0.0, 0.0, NSWidth(bounds), NSHeight(bounds))];
			NSPDFImageRep *pdfImageRep = (nil != aData) ? [NSPDFImageRep imageRepWithData:aData] : nil;
			NSImage *anImage = [[NSImage alloc] initWithSize:bounds.size];
			if ((nil != pdfImageRep) && (nil != anImage)) {
				BOOL shadowFlag = (0.1 > [self shadowBlurRadiusValue]) ? NO : YES;
				NSArray *defsAndRect = [self svgDefsAndRect:unique_ID allGraphics:aRect bounds:bounds transform:nil];
				if (0 < [defsAndRect count])
					[elements addObjectsFromArray:defsAndRect];
				[anImage setScalesWhenResized:YES];
				[anImage addRepresentation:pdfImageRep];
				NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:[anImage TIFFRepresentation]];
				NSString *base64Str = (nil != imageRep) ? imageRepToBase64(imageRep) : nil;
				if (nil != base64Str) {
					NSXMLElement *element = [NSXMLElement elementWithName:@"image"];
					NSMutableArray *attributes = [NSMutableArray arrayWithObjects:svgTransformNode(translateX,translateY,[self rotateAngle],1.0,1.0),[NSXMLNode attributeWithName:@"x" stringValue:[NSString stringWithFormat:@"%g%@",-0.5 * NSWidth(bounds),svgUnit]],[NSXMLNode attributeWithName:@"y" stringValue:[NSString stringWithFormat:@"%g%@",-0.5 * NSHeight(bounds),svgUnit]],[NSXMLNode attributeWithName:@"width" stringValue:[NSString stringWithFormat:@"%g%@",NSWidth(bounds),svgUnit]],[NSXMLNode attributeWithName:@"height" stringValue:[NSString stringWithFormat:@"%g%@",NSHeight(bounds),svgUnit]],[NSXMLNode attributeWithName:@"preserveAspectRatio" stringValue:@"none"],[NSXMLNode attributeWithName:@"xlink:href" stringValue:[NSString stringWithFormat:@"data:%@",base64Str]],nil]; // WebKit,OPera,BatikなどではpreserveAspectRatio="none"がデフォルトでない。 //
					if ((YES == shadowFlag) && (NO == [self isDrawingFill]))
						[attributes addObject:[NSXMLNode attributeWithName:@"filter" stringValue:[NSString stringWithFormat:@"url(#shadow_%@)",unique_ID]]];
					[element setAttributes:attributes];
					elements = [NSMutableArray arrayWithObject:[NSXMLNode commentWithStringValue:NSStringFromClass([self class])]];
					[elements addObject:element];
				}
			}
			[anImage release];
			[renderingView release];
			return elements;
		}
		else
			return nil;
	}
}

@end
