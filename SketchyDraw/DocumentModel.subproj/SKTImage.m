/*
     File: SKTImage.m
 Abstract: A graphic object to represent an image.
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

#import "SKTImage.h"
#import "SKTGraphicView.h" // SatoAkira add. for ISFLIPPED //
#import "SKTFoundationExtras.h" // SatoAkira add. for svg...() //


// String constants declared in the header. They may not be used by any other class in the project, but it's a good idea to provide and use them, if only to help prevent typos in source code.
NSString *SKTImageIsFlippedHorizontallyKey = @"flippedHorizontally";
NSString *SKTImageIsFlippedVerticallyKey = @"flippedVertically";
NSString *SKTImageFilePathKey = @"filePath";

// Another key, which is just used in persistent property dictionaries.
static NSString *SKTImageContentsKey = @"contents";
static NSString *SKTImageContentsSketch1Key = @"Image"; // SatoAlira add.sktd互換 //
static NSString *SKTImageTypeKey = @"ImageType"; // SatoAlira add.sktd互換 //
static NSString *SKTImageRepresentationKey = @"ImageRepresentationKey"; // SatoAlira add.sktd互換 //

@implementation SKTImage


- (id)copyWithZone:(NSZone *)zone {

    // Do the regular Cocoa thing.
    SKTImage *copy = [super copyWithZone:zone];
    /* copy->_contents = [_contents copy]; */ // SatoAkira delete. //
	// ↓SatoAkira add. //
	copy->_isFlippedHorizontally = _isFlippedHorizontally;
	copy->_isFlippedVertically = _isFlippedVertically;
	[copy setImageRepresentation:_imageRepresentation type:_imageType];
	// ↑SatoAkira add. //
    return copy;

}


- (void)dealloc {

    // Do the regular Cocoa thing.
    /* [_contents release]; */ // SatoAkira delete. //
	// ↓SatoAkira add. //
	[_cachedImage release];
	[_imageRepresentation release];
	[_imageType release];
	[_bitmapImageReps release];
	// ↑SatoAkira add. //
    [super dealloc];

}


#pragma mark *** Private KVC-Compliance for Public Properties ***


- (void)setFlippedHorizontally:(BOOL)isFlippedHorizontally {

    // Record the value and flush the transformed contents cache.
    _isFlippedHorizontally = isFlippedHorizontally;
	[_cachedImage release]; // Satoakira add. //
	_cachedImage = nil; // Satoakira add. //
}


- (void)setFlippedVertically:(BOOL)isFlippedVertically {

    // Record the value and flush the transformed contents cache.
    _isFlippedVertically = isFlippedVertically;
	[_cachedImage release]; // Satoakira add. //
	_cachedImage = nil; // Satoakira add. //
}


- (void)setFilePath:(NSString *)filePath {

    // If there's a transformed version of the contents being held as a cache, it's invalid now.
    /* NSImage *newContents = [[NSImage alloc] initWithContentsOfFile:[filePath stringByStandardizingPath]];
    if (_contents) {
	[_contents release];
    }
    _contents = [newContents retain]; */ // SatoAkira delete. //
	// ↓SatoAkira add. //
	NSError *err = nil;
	NSData *newData = [NSData dataWithContentsOfFile:[filePath stringByStandardizingPath] options:NSMappedRead error:&err];
	[self setImageRepresentation:newData type:[filePath pathExtension]];
	// ↑SatoAkira add. //
}

- (void)setCurrentPage:(NSNumber *)pageNumber
// 1-based. //
// SatoAkira add. //
{
	NSInteger page;
	if ((0 < [pageNumber integerValue]) && ((NSInteger)[_bitmapImageReps count] >= [pageNumber integerValue]))
		page = [pageNumber integerValue];
	else
		page = (0 >= [pageNumber integerValue]) ? 1 : [_bitmapImageReps count];
	if (_currentPage != page) {
		_currentPage = page;
		_bitmapImageRep = [_bitmapImageReps objectAtIndex:_currentPage - 1];
		hasColorSyncProfileData = (nil != [_bitmapImageRep valueForProperty:NSImageColorSyncProfileData]) ? YES : NO;
		[_cachedImage release];
		_cachedImage = nil;
	}
}
- (NSUInteger)pageCount { // SatoAkira add. //
	return [_bitmapImageReps count];
}
- (BOOL)hasColorSyncProfileData { // SatoAkira add. //
	return hasColorSyncProfileData;
}


#pragma mark *** Public Methods ***


/* - (id)initWithPosition:(NSPoint)position contents:(NSImage *)contents {

    // Do the regular Cocoa thing.
    self = [self init];
    if (self) {
	_contents = [contents retain];

	// Leave the image centered on the mouse pointer.
	NSSize contentsSize = [_contents size];
	[self setBounds:NSMakeRect((position.x - (contentsSize.width / 2.0f)), (position.y - (contentsSize.height / 2.0f)), contentsSize.width, contentsSize.height)];
    }
    return self;

} */ // SatoAkira delete. //
- (id)initWithPosition:(NSPoint)position data:(NSData *)contents type:(NSString *)type
// SatoAkira add. //
{
	if (nil != (self = [self init])) {
		NSSize contentsSize = [self setImageRepresentation:contents type:type];
		[self setBounds:NSMakeRect((position.x - (contentsSize.width / 2.0f)), (position.y - (contentsSize.height / 2.0f)), contentsSize.width, contentsSize.height)];
	}
	return self;
}


#pragma mark *** Overrides of SKTGraphic Methods ***


- (NSSize)setImageRepresentation:(NSData *)aData type:(NSString *)aString
// SatoAkira add. //
{
	NSArray *tempImageReps = nil;

	if (YES == [NSBitmapImageRep canInitWithData:aData]) {
		if (nil == (tempImageReps = [NSBitmapImageRep imageRepsWithData:aData]))
			NSLog(@"SKTImage.m:NSBitmapImageRep is unable to create an image representation");
		else {
			if (1 > [tempImageReps count]) // colorspace nameがNSCustomColorSpaceのときこける。Bad colorspace name NSCustomColorSpace. Image 0 has invalid parameters. //
				NSLog(@"SKTImage.m:NSBitmapImageRep instance is empty.");
		}
	}
	/* else {
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6
		NSURL *tempFileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"SketchTemp.%@",aString]]]; // aStringは拡張子ではないので無意味。 //
		if (YES == [aData writeToURL:tempFileURL atomically:NO]) {
			NSError *err = nil;
			NSBitmapImageRep *tempFileImageRep = [NSBitmapImageRep imageRepWithContentsOfURL:tempFileURL]; // ここでfilterプログラムが起動していたが、ToyViewerのPCD用のフィルターはOS10.5になってから動作しなくなってnilを返すようになってしまった。我がScrollEPSのsvg用のフィルターも同じようにOS10.5になって動作しなくなってしまった。imageRepWithContentsOfFileとしても同じ。 //
			if (nil != tempFileImageRep) {
				tempImageReps = [NSBitmapImageRep imageRepsWithData:[tempFileImageRep representationUsingType:NSTIFFFileType properties:nil]];
			}
			else {
				NSLog(@"%@ tempFileImageRep is nil.",[NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"SketchTemp.%@",aString]]);
				tempImageReps = nil;
			}			
			[[NSFileManager defaultManager] removeItemAtURL:tempFileURL error:&err];
		}
#else
		NSString *tempFile = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"SketchTemp.%@",aString]];

		if (YES == [aData writeToFile:tempFile atomically:YES]) {
			NSBitmapImageRep *tempFileImageRep = [NSBitmapImageRep imageRepWithContentsOfFile:tempFile]; // ここでfilterプログラムが起動する。ToyViewerのPCD用のフィルターはOS10.5になってから動作しなくなってnilを返すようになってしまった。我がScrollEPSのsvg用のフィルターも同じようにOS10.5になって動作しなくなってしまった。imageRepWithContentsOfURLとしても同じ。 //

			if (nil != tempFileImageRep) {
				tempImageReps = [NSBitmapImageRep imageRepsWithData:[tempFileImageRep representationUsingType:NSTIFFFileType properties:nil]];
			}
			else {
				tempImageReps = nil;
			}
			[[NSFileManager defaultManager] removeFileAtPath:tempFile handler:nil];
		}
#endif
		else
			tempImageReps = nil;
	} */
	if ((nil != tempImageReps) && (0 < [tempImageReps count])) {
		[_bitmapImageReps release];
		_bitmapImageReps = [[NSArray allocWithZone:[self zone]] initWithArray:tempImageReps];
		_currentPage = 1;
		_bitmapImageRep = [_bitmapImageReps objectAtIndex:(NSUInteger)_currentPage - 1];
		hasColorSyncProfileData = (nil != [_bitmapImageRep valueForProperty:NSImageColorSyncProfileData]) ? YES : NO;
		originalSize = [_bitmapImageRep size];
		[_imageType release];
		[_imageRepresentation release];
		_imageRepresentation = [[NSData allocWithZone:[self zone]] initWithData:aData];
		_imageType = [[NSString allocWithZone:[self zone]] initWithString:aString];
		return originalSize;
	}
	else {
		originalSize = NSZeroSize;
		_currentPage = 1;
		[_imageType release];
		[_imageRepresentation release];
		[_bitmapImageReps release];
		_imageRepresentation = nil;
		_imageType = [[NSString alloc] initWithString:aString];
		_bitmapImageReps = [[NSArray allocWithZone:[self zone]] initWithArray:[NSArray array]];
		_bitmapImageRep = nil;
		hasColorSyncProfileData = NO;
		return NSZeroSize;
	}
}
- (id)initWithProperties:(NSDictionary *)properties {
    
    // Let SKTGraphic do its job and then handle the additional properties defined by this subclass.
    self = [super initWithProperties:properties];
    if (self) {

	// The dictionary entries are all instances of the classes that can be written in property lists. Don't trust the type of something you get out of a property list unless you know your process created it or it was read from your application or framework's resources. We don't have to worry about KVO-compliance in initializers like this by the way; no one should be observing an unitialized object.
	/* NSData *contentsData = [properties objectForKey:SKTImageContentsKey];
	if ([contentsData isKindOfClass:[NSData class]]) {
	    NSImage *contents = [NSUnarchiver unarchiveObjectWithData:contentsData];
	    if ([contents isKindOfClass:[NSImage class]]) {
		_contents = [contents retain];
	    }
	} */ // SatoAkira delete. //
		
	NSNumber *isFlippedHorizontallyNumber = [properties objectForKey:SKTImageIsFlippedHorizontallyKey];
	if ([isFlippedHorizontallyNumber isKindOfClass:[NSNumber class]]) {
	    _isFlippedHorizontally = [isFlippedHorizontallyNumber boolValue];
	}
	NSNumber *isFlippedVerticallyNumber = [properties objectForKey:SKTImageIsFlippedVerticallyKey];
	if ([isFlippedVerticallyNumber isKindOfClass:[NSNumber class]]) {
	    _isFlippedVertically = [isFlippedVerticallyNumber boolValue];
	}
		// ↓SatoAkira add. //
		id obj;
		NSString *aString;
		if ((nil != (obj = [properties objectForKey:SKTImageTypeKey])) && (YES == [obj isKindOfClass:[NSString class]])) {
			aString = [NSString stringWithString:obj];
		}
		else
			aString = @"unknown";
		if (nil != (obj = [properties objectForKey:SKTImageRepresentationKey])) {
			[self setImageRepresentation:obj type:aString];
			if (YES == [self respondsToSelector:@selector(pdfImageRepDidLoad:)]) {
				// mainThreadではないのでWebKitに起動を掛けられない。従って_imageRepresentationはnilのままである。この状態で保存されるとproperties:において_imageRepresentationが保存されなくなる。この不具合を解消する為に、pdfImageRepDidLoad:の中で_imageRepresentationを初期化するタイプのSKTImageについてはここで初期化する。このタイプではmainThreadになったときを見てもう一度_imageRepresentationを初期化することになる。 //
				[_imageRepresentation release];
				_imageRepresentation = [[NSData allocWithZone:[self zone]] initWithData:obj];
			}
		}
		else {
			if (nil == (obj = [properties objectForKey:SKTImageContentsKey]))
				obj = [properties objectForKey:SKTImageContentsSketch1Key];
			if ((nil != obj) && ([obj isKindOfClass:[NSData class]])) {
				NSImage *tempImage = [NSUnarchiver unarchiveObjectWithData:obj];
				[_imageType release];
				[_imageRepresentation release];
				[_bitmapImageReps release];
				_imageRepresentation = [[NSData allocWithZone:[self zone]] initWithData:[tempImage TIFFRepresentation]];
				_imageType = [[NSString allocWithZone:[self zone]] initWithString:@"tiff"];
				_bitmapImageReps = [[NSArray allocWithZone:[self zone]] initWithArray:[NSBitmapImageRep imageRepsWithData:_imageRepresentation]];
				_currentPage = 1;
				_bitmapImageRep = [_bitmapImageReps objectAtIndex:(NSUInteger)_currentPage - 1];
				originalSize = [tempImage size];
				hasColorSyncProfileData = (nil != [_bitmapImageRep valueForProperty:NSImageColorSyncProfileData]) ? YES : NO;
			}
			else {
				NSLog(@"SKTImage:image of type %@ is nil.",aString);
				return nil;
			}
		}
		// ↑SatoAkira add. //
    }
    return self;
    
}


- (NSMutableDictionary *)properties {

    // Let SKTGraphic do its job and then handle the one additional property defined by this subclass. The dictionary must contain nothing but values that can be written in old-style property lists.
    NSMutableDictionary *properties = [super properties];
	/* [properties setObject:[NSArchiver archivedDataWithRootObject:_contents] forKey:SKTImageContentsKey]; */ // SatoAkira delete. //
    [properties setObject:[NSNumber numberWithBool:_isFlippedHorizontally] forKey:SKTImageIsFlippedHorizontallyKey];
    [properties setObject:[NSNumber numberWithBool:_isFlippedVertically] forKey:SKTImageIsFlippedVerticallyKey];
	if (nil != _imageRepresentation) // SatoAkira add. //
		[properties setObject:_imageRepresentation forKey:SKTImageRepresentationKey]; // SatoAkira add.ここで複数ページ分のデータならばそのまま複数ページ分のデータがコピーされる。 //
	else
		NSLog(@"SKTImage:_imageRepresentation is nil."); // SatoAkira add. //
	if (nil != _imageType) // SatoAkira add. //
		[properties setObject:_imageType forKey:SKTImageTypeKey]; // SatoAkira add. //
	else
		NSLog(@"SKTImage:_imageType is nil."); // SatoAkira add. //
    return properties;

}

- (NSData *)imageRepresentation { // SatoAkira add. //
	return _imageRepresentation;
}
- (NSString *)imageType { // SatoAkira add. //
	return _imageType;
}

/* - (BOOL)isDrawingFill {

    // We never fill an image with color.
    return NO;

} */ // SatoAkira delete. //


- (BOOL)isDrawingStroke {

    // We never draw a stroke on an image.
    return NO;

}


+ (NSSet *)keyPathsForValuesAffectingDrawingContents {

    // Flipping affects drawing but not the drawing bounds. So of course do the properties managed by the superclass.
    NSMutableSet *keys = [[super keyPathsForValuesAffectingDrawingContents] mutableCopy];
    [keys addObject:SKTImageIsFlippedHorizontallyKey];
    [keys addObject:SKTImageIsFlippedVerticallyKey];
	[keys addObject:SKTImageCurrentPageKey]; // for self,SKTpdf,SKTeps //
    return [keys autorelease];

}


/* - (void)drawContentsInView:(NSView *)view isBeingCreateOrEdited:(BOOL)isBeingCreatedOrEditing {

    // Fill the background with the fill color. Maybe it will show, if the image has an alpha channel.
    NSRect bounds = [self bounds];
    if ([self isDrawingFill]) {
        [[self fillColor] set];
        NSRectFill(bounds);
    }

    // Surprisingly, NSImage's -draw... methods don't take into account whether or not the view is flipped. In Sketch, SKTGraphicViews are flipped (and this model class is not supposed to have dependencies on the oddities of any particular view class anyway). So, just do our own transformation matrix manipulation.
    NSAffineTransform *transform = [NSAffineTransform transform];

    // Translating to actually place the image (as opposed to translating as part of flipping).
    [transform translateXBy:bounds.origin.x yBy:bounds.origin.y];

    // Flipping according to the user's wishes.
    [transform translateXBy:(_isFlippedHorizontally ? bounds.size.width : 0.0f) yBy:(_isFlippedVertically ? bounds.size.height : 0.0f)];
    [transform scaleXBy:(_isFlippedHorizontally ? -1.0f : 1.0f) yBy:(_isFlippedVertically ? -1.0f : 1.0f)];

    // Scaling to actually size the image (as opposed to scaling as part of flipping).
    NSSize contentsSize = [_contents size];
    [transform scaleXBy:(bounds.size.width / contentsSize.width) yBy:(bounds.size.height / contentsSize.height)];

    // Flipping to accomodate -[NSImage drawAtPoint:fromRect:operation:fraction:]'s odd behavior.
    if ([view isFlipped]) {
	[transform translateXBy:0.0f yBy:contentsSize.height];
	[transform scaleXBy:1.0f yBy:-1.0f];
    }

    // Do the actual drawing, saving and restoring the graphics state so as not to interfere with the drawing of selection handles or anything else in the same view.
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [transform concat];
    [_contents drawAtPoint:NSZeroPoint fromRect:NSMakeRect(0.0f, 0.0f, contentsSize.width, contentsSize.height) operation:NSCompositeSourceOver fraction:1.0f];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    
} */ // SatoAkira delete. //
- (void)drawContentsInView:(NSView *)view isBeingCreateOrEdited:(BOOL)isBeingCreatedOrEditing
// SatoAkira add. //
{
	if (nil != _bitmapImageRep) {
		NSRect bounds = [self bounds];
		double rotateAngle = [self rotateAngle];
		NSRect imageRect = NSMakeRect(-0.5 * NSWidth(bounds),-0.5 * NSHeight(bounds),NSWidth(bounds), NSHeight(bounds));
		NSAffineTransform *transform = [NSAffineTransform transform];
		NSGraphicsContext *currentContext = [NSGraphicsContext currentContext];
		float scaleX = (YES == _isFlippedHorizontally) ? -1.0: 1.0;
#ifdef ISFLIPPED
		float scaleY = (YES == _isFlippedVertically) ? 1.0 : -1.0;
#else
		float scaleY = (YES == _isFlippedVertically) ? -1.0 : 1.0;
#endif
		BOOL shadowFlag = (0.1 > [self shadowBlurRadiusValue]) ? NO : YES;

		[transform translateXBy:NSMidX(bounds) yBy:NSMidY(bounds)];
		if (0.0 != rotateAngle)
			[transform rotateByRadians:rotateAngle];
		[transform scaleXBy:scaleX yBy:scaleY];
		[transform concat];
		if ([self isDrawingFill]) {
			NSRect fillRect = imageRect;
			NSBezierPath *fillPath = [NSBezierPath bezierPathWithRect:fillRect]; // NSRectFill(fillRect)を使うと暗くなってしまう。 //

			if ((YES == [self shading]) || (YES == [[[self fillColor] colorSpaceName] isEqualToString:NSPatternColorSpace])) {
				NSAffineTransform *fillTransform = [NSAffineTransform
												 transform];
				[fillTransform scaleXBy:1.0 yBy:-1.0];
				if (YES == shadowFlag) {
					[currentContext saveGraphicsState];
					[self shadowSet];
					[[NSColor whiteColor] setFill];
					[fillPath fill];
					[currentContext restoreGraphicsState];
					shadowFlag = NO;
				}
				if (YES == [self shading])
					[self drawShading:[NSBezierPath bezierPathWithRect:fillRect] transform:fillTransform];
				else {
					ASPatternModel *pModel = [self patternModel];
					[pModel setBounds:bounds clip:[NSBezierPath bezierPathWithRect:fillRect] transform:fillTransform colorSpace:[self colorSpace] winding:[self windingRule]];
					[pModel fill];
				}
			}
			else {
				if (YES == shadowFlag) {
					[currentContext saveGraphicsState]; // この方法でないと影が暗くなってしまう。 //
					[self shadowSet];
					[self fillColorSet];
					[fillPath fill];
					[currentContext restoreGraphicsState];
					shadowFlag = NO;
				}
				else {
					[self fillColorSet];
					[fillPath fill]; // [path closePath]されていなくても正しくfillされる。 //
				}
			}
		}
		if (YES == shadowFlag) {
			[currentContext saveGraphicsState];
			[self shadowSet];
		}
		if ((nil != view) && (YES == [currentContext isDrawingToScreen]) && (NSImageInterpolationHigh != [currentContext imageInterpolation])) {
			if (nil == _cachedImage) {
				if (nil != (_cachedImage = [[NSImage allocWithZone:[self zone]] initWithSize:imageRect.size])) {
					if (NO == hasColorSyncProfileData)
						[_bitmapImageRep setProperty:NSImageColorSyncProfileData withValue:[[self colorSpace] ICCProfileData]];
					[_cachedImage addRepresentation:_bitmapImageRep];
					[_cachedImage setScalesWhenResized:YES];
				}
			}
			if (nil != _cachedImage)
				[_cachedImage drawAtPoint:imageRect.origin fromRect:NSMakeRect(0.0,0.0,NSWidth(imageRect),NSHeight(imageRect)) operation:NSCompositeSourceOver fraction:1.0]; // imageをcompsiteする点はflipされていても見た目の左下である。 //
		}
		else { // 以下の方法でシグナル 11（SIGSEGV）により終了するような画像ファイルは、標準のNSImageView,TextEdit.app,Preview.appでやっても同じようにこける。 //
			// TIFFの古いファイルがよく落ちる。 //
			BOOL canInitWithData = [NSBitmapImageRep canInitWithData:[_bitmapImageRep TIFFRepresentation]];
			BOOL hasAlpha = [_bitmapImageRep hasAlpha];

			if (YES == canInitWithData) {
				if (NO == hasColorSyncProfileData)
					[_bitmapImageRep setProperty:NSImageColorSyncProfileData withValue:[[self colorSpace] ICCProfileData]];
				if (YES == hasAlpha) { // alphaがあるのに透過にならないTIFFが稀にあるが直し方が判らない。 //
					if (NO == [_bitmapImageRep drawInRect:imageRect fromRect:NSMakeRect(0.0,0.0,originalSize.width,originalSize.height) operation:NSCompositeSourceOver fraction:1.0 respectFlipped:NO hints:[NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:NSImageInterpolationHigh] forKey:NSImageHintInterpolation]])
						NSLog(@"SKTImage:drawInRect fail has alpha.");
				}
				else {
					if (NO == [_bitmapImageRep drawInRect:imageRect fromRect:NSMakeRect(0.0,0.0,originalSize.width,originalSize.height) operation:NSCompositeSourceOver fraction:1.0 respectFlipped:NO hints:[NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:NSImageInterpolationHigh] forKey:NSImageHintInterpolation]])
						NSLog(@"SKTImage:drawInRect fail no alpha.");
				}
			}
			else {
				if (YES == hasAlpha) {
					// ここでシグナル 11（SIGSEGV）により終了するような画像ファイルは下の方法でやっても同じようにこける。 //
					// (YES == [currentContext isDrawingToScreen])と同じ方法ではできない。 //
					NSImage *tempImage = [[NSImage allocWithZone:[self zone]] initWithSize:imageRect.size];
					if (NO == hasColorSyncProfileData)
						[_bitmapImageRep setProperty:NSImageColorSyncProfileData withValue:[[self colorSpace] ICCProfileData]];
					[tempImage addRepresentation:_bitmapImageRep];

					if (nil != tempImage) {
						[tempImage setScalesWhenResized:YES];
						[tempImage setSize:imageRect.size];
NS_DURING
						[tempImage drawAtPoint:imageRect.origin fromRect:NSMakeRect(0.0,0.0,NSWidth(imageRect),NSHeight(imageRect)) operation:NSCompositeSourceOver fraction:1.0];
NS_HANDLER
						NSLog(@"SKTImage:drawAtPoint fail in drawInView.");
NS_ENDHANDLER
						[tempImage release];
					}
					else
						NSLog(@"SKTImage:tempImage is nil in drawInView.");
				}
				else { // ((NO == canInitWithData) && (NO == hasAlpha)) //
					// ここでシグナル 11（SIGSEGV）により終了するような画像ファイルは上の方法でやっても同じようにこける。 //
					if (NO == hasColorSyncProfileData)
						[_bitmapImageRep setProperty:NSImageColorSyncProfileData withValue:[[self colorSpace] ICCProfileData]];
					if (NO == [_bitmapImageRep drawInRect:imageRect fromRect:NSMakeRect(0.0,0.0,originalSize.width,originalSize.height) operation:NSCompositeSourceOver fraction:1.0 respectFlipped:NO hints:nil])
						NSLog(@"SKTImage:drawInRect fail not canInitWithData and no alpha.");
				}
			}
		}
		if (YES == shadowFlag)
			[currentContext restoreGraphicsState];
	}
}


- (BOOL)canSetDrawingFill {

    // Don't let the user think we would even try to fill an image with color.
    /* return NO; */ // SatoAkira delete. //
	return YES; // SatoAkira add. //

}


- (BOOL)canSetDrawingStroke {

    // Don't let the user think we would even try to draw a stroke on image.
    return NO;

}
- (BOOL)canDrawLineJoin { // SatoAkira add. //
	return NO;
}
- (BOOL)canDrawLineCap { // SatoAkira add. //
	return NO;
}
- (BOOL)canDrawArrow { // SatoAkira add. //
	return NO;
}
- (BOOL)canDrawDash { // SatoAkira add. //
    return NO;
}


- (void)flipHorizontally {

    // Simple.
    [self setFlippedHorizontally:(_isFlippedHorizontally ? NO : YES)];

}

- (void)flipVertically {

    // Simple.
    [self setFlippedVertically:(_isFlippedVertically ? NO : YES)];
    
}


/* - (void)makeNaturalSize {

    // Return the image to its natural size and stop flipping it.
    NSRect bounds = [self bounds];
    bounds.size = [_contents size];
    [self setBounds:bounds];
    [self setFlippedHorizontally:NO];
    [self setFlippedVertically:NO];

} */ // SatoAklira delete. //
- (void)makeNaturalSize
// SatoAkira add. //
{
	NSRect bounds = [self bounds];
	NSSize requiredSize = (YES == NSEqualSizes(NSZeroSize,originalSize)) ? NSMakeSize(10.0, 10.0) : originalSize;

	bounds.size = requiredSize;
	[self setBounds:bounds];
	[self setFlippedHorizontally:NO];
	[self setFlippedVertically:NO];
}


- (void)setBounds:(NSRect)bounds {

    // Flush the transformed contents cache and then do the regular SKTGraphic thing.
    [super setBounds:bounds];
	// ↓SatoAkira add. //
	NSArray *representations = [_cachedImage representations];
	if ((nil != representations) && (0 < [representations count])) {
		for (NSImageRep *rep in representations)
			[_cachedImage removeRepresentation:rep];
	}
	[_cachedImage release];
	_cachedImage = nil;
	// ↑SatoAkira add. //
}


- (NSSet *)keysForValuesToObserveForUndo {

    // This class defines a few properties for which changes are undoable, in addition to the ones inherited from SKTGraphic.
    NSMutableSet *keys = [[super keysForValuesToObserveForUndo] mutableCopy];
    [keys addObject:SKTImageIsFlippedHorizontallyKey];
    [keys addObject:SKTImageIsFlippedVerticallyKey];
    return [keys autorelease];
    
}


+ (NSString *)presentablePropertyNameForKey:(NSString *)key {

    // Pretty simple. As is usually the case when a key is passed into a method like this, we have to invoke super if we don't recognize the key.
    static NSDictionary *presentablePropertyNamesByKey = nil;
    if (!presentablePropertyNamesByKey) {
	presentablePropertyNamesByKey = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
	    NSLocalizedStringFromTable(@"Horizontal Flipping", @"UndoStrings", @"Action name part for SKTImageIsFlippedHorizontallyKey."), SKTImageIsFlippedHorizontallyKey,
	    NSLocalizedStringFromTable(@"Vertical Flipping", @"UndoStrings",@"Action name part for SKTImageIsFlippedVerticallyKey."), SKTImageIsFlippedVerticallyKey,
	    nil];
    }
    NSString *presentablePropertyName = [presentablePropertyNamesByKey objectForKey:key];
    if (!presentablePropertyName) {
	presentablePropertyName = [super presentablePropertyNameForKey:key];
    }
    return presentablePropertyName;

}
- (NSArray *)svgXMLElements:(NSRect)aRect name:(NSString *)unique_ID
// SatoAkira add. //
{
	NSRect bounds = [self bounds];

	if ((0.0 < NSWidth(bounds)) || (0.0 < NSHeight(bounds))) {
		NSMutableArray *elements = [NSMutableArray arrayWithObject:[NSXMLNode commentWithStringValue:NSStringFromClass([self class])]];
		BOOL shadowFlag = (0.1 > [self shadowBlurRadiusValue]) ? NO : YES;
		NSArray *defsAndRect = [self svgDefsAndRect:unique_ID allGraphics:aRect bounds:bounds transform:nil];
		if (0 < [defsAndRect count])
			[elements addObjectsFromArray:defsAndRect];
		CGFloat translateX = NSMidX(bounds) - NSMinX(aRect);
		CGFloat translateY = NSMidY(bounds) - NSMinY(aRect);
		NSBitmapImageRep *imageRep = ((nil != _bitmapImageRep) && (YES == [_bitmapImageRep isKindOfClass:[NSBitmapImageRep class]])) ? _bitmapImageRep : (nil != _cachedImage) ? [NSBitmapImageRep imageRepWithData:[_cachedImage TIFFRepresentation]] : nil;
		NSString *base64Str = (nil != imageRep) ? imageRepToBase64(imageRep) : nil;

		if (nil != base64Str) {
			NSXMLElement *element = [[NSXMLElement allocWithZone:[self zone]] initWithName:@"image"];
			NSMutableArray *attributes = [NSMutableArray arrayWithObjects:svgTransformNode(translateX,translateY,[self rotateAngle],1.0,1.0),[NSXMLNode attributeWithName:@"x" stringValue:[NSString stringWithFormat:@"%g%@",-0.5 * NSWidth(bounds),svgUnit]],[NSXMLNode attributeWithName:@"y" stringValue:[NSString stringWithFormat:@"%g%@",-0.5 * NSHeight(bounds),svgUnit]],[NSXMLNode attributeWithName:@"width" stringValue:[NSString stringWithFormat:@"%g%@",NSWidth(bounds),svgUnit]],[NSXMLNode attributeWithName:@"height" stringValue:[NSString stringWithFormat:@"%g%@",NSHeight(bounds),svgUnit]],[NSXMLNode attributeWithName:@"preserveAspectRatio" stringValue:@"none"],[NSXMLNode attributeWithName:@"xlink:href" stringValue:[NSString stringWithFormat:@"data:%@",base64Str]],nil]; // WebKit,OPera,BatikなどではpreserveAspectRatio="none"がデフォルトでない。 //

			if ((YES == shadowFlag) && (NO == [self isDrawingFill]))
				[attributes addObject:[NSXMLNode attributeWithName:@"filter" stringValue:[NSString stringWithFormat:@"url(#shadow_%@)",unique_ID]]];
			[element setAttributes:attributes];
			[elements addObject:element];
			[element release];
			return elements;
		}
		else
			return nil;
	}
	else
		return nil;
}


@end
