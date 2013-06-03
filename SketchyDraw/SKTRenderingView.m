/*
     File: SKTRenderingView.m
 Abstract: A view to create TIFF and PDF representations of a collection of graphic objects.
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

#import "SKTRenderingView.h"
#import "SKTError.h"
#import "SKTGraphic.h"
#import <PDFKit/PDFDocument.h> // SatoAkira add. for PDFDocument //
#import "PreferencesController.h" // SatoAkira add. //
#import "SKTFoundationExtras.h" // SatoAkira add. //
#import "SKTsvg.h"


@implementation SKTRenderingView


/* + (NSData *)pdfDataWithGraphics:(NSArray *)graphics {

    // Create a view that will be used just for making PDF.
    NSRect bounds = [SKTGraphic drawingBoundsOfGraphics:graphics];
    SKTRenderingView *view = [[SKTRenderingView alloc] initWithFrame:bounds graphics:graphics printJobTitle:nil];
    NSData *pdfData = [view dataWithPDFInsideRect:bounds];
    [view release];
    return pdfData;

} */ // SatoAkira delete. //
+ (NSData *)pdfDataWithGraphics:(NSArray *)graphics color:(NSColorSpace *)aSpace attributes:(NSDictionary *)attrs { // SatoAkira add. //
    NSRect bounds = [SKTGraphic drawingBoundsOfGraphics:graphics];

	if (NSIsEmptyRect(bounds))
		return nil;
	else {
		SKTRenderingView *view = [[SKTRenderingView allocWithZone:[self zone]] initWithFrame:NSMakeRect(0.0, 0.0, NSMaxX(bounds), NSMaxY(bounds)) graphics:graphics printJobTitle:[[NSProcessInfo processInfo] processName] color:aSpace];
		NSWindow *window = [[NSWindow allocWithZone:[self zone]] initWithContentRect:NSMakeRect(0.0, 0.0, NSMaxX(bounds), NSMaxY(bounds)) styleMask:NSBorderlessWindowMask backing:NSBackingStoreNonretained defer:NO];
		NSMutableData *pdfData = [NSMutableData dataWithCapacity:10];
		NSPrintOperation *printOp;

		[[window contentView] addSubview:view];
		[view release];
		printOp = [NSPrintOperation PDFOperationWithView:view insideRect:bounds toData:pdfData printInfo:nil]; // dataWithPDFInsideRect:を使っても透明度は無視される。However, you'll quickly see that gradients with transparency don't output correctly in Mac OS X (everything else, including the shadows, work fine). The internets claim it's a limitation of PDF 1.4 (the PDF standard used in Mac OS X). //
		if (nil != printOp) {
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_4
			[printOp setShowsPrintPanel:NO];
#else
			[printOp setShowPanels:NO];
#endif

			if (![printOp runOperation])
				pdfData = nil;
		}
		else
			pdfData = nil;
		[window release];
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_4
		if ((nil != attrs) && (nil != pdfData)) {
			PDFDocument *pdfDoc = [[PDFDocument alloc] initWithData:pdfData]; // PDFDocumentCreationDateAttribute(NSDate),PDFDocumentModificationDateAttribute(NSDate),PDFDocumentProducerAttributeの3つの値はここで自動的にセットされる。 //
			NSMutableDictionary *originAttrs = [NSMutableDictionary dictionaryWithDictionary:[pdfDoc documentAttributes]];

			for (NSString *key in attrs)
					[originAttrs setObject:[attrs objectForKey:key] forKey:key]; // attrsにあるものは総て置き換えるので自動設定されるものはsetObject::させない方が良い。 //
			[pdfDoc setDocumentAttributes:originAttrs];
			NSData *addCreatorData = [NSData dataWithData:[pdfDoc dataRepresentation]];
			[pdfDoc release];
			return addCreatorData;
		}
		else
#endif
			return pdfData;
	}
}


/* + (NSData *)tiffDataWithGraphics:(NSArray *)graphics error:(NSError **)outError {

    // How big a of a TIFF are we going to make? Regardless of what NSImage supports, Sketch doesn't support the creation of TIFFs that are 0 by 0 pixels. (We have to demonstrate a custom saving error somewhere, and this is an easy place to do it...)
    NSData *tiffData = nil;
    NSRect bounds = [SKTGraphic drawingBoundsOfGraphics:graphics];
    if (!NSIsEmptyRect(bounds)) {
	
	// Create a new image and prepare to draw in it. Get the graphics context for it after we lock focus, not before.
	NSImage *image = [[NSImage alloc] initWithSize:bounds.size];
	[image setFlipped:YES];
	[image lockFocus];
	NSGraphicsContext *currentContext = [NSGraphicsContext currentContext];
	
	// We're not drawing a page image here, just the rectangle that contains the graphics being drawn, so make sure they get drawn in the right place.
	NSAffineTransform *transform = [NSAffineTransform transform];
	[transform translateXBy:(0.0f - bounds.origin.x) yBy:(0.0f - bounds.origin.y)];
	[transform concat];
	
	// Draw the graphics back to front.
	NSUInteger graphicIndex = [graphics count];
	while (graphicIndex-->0) {
	    SKTGraphic *graphic = [graphics objectAtIndex:graphicIndex];
	    [currentContext saveGraphicsState];
	    [NSBezierPath clipRect:[graphic drawingBounds]];
	    [graphic drawContentsInView:nil isBeingCreateOrEdited:NO];
	    [currentContext restoreGraphicsState];
	}
	
	// We're done drawing.
	[image unlockFocus];
	tiffData = [image TIFFRepresentation];
	[image release];
	
    } else if (outError) {
	
	// In Sketch there are lots of places to catch this situation earlier. For example, we could have overridden -writableTypesForSaveOperation: and made it not return NSTIFFPboardType, but then the user would have no idea why TIFF isn't showing up in the save panel's File Format popup. This way we can present a nice descriptive errror message.
	*outError = SKTErrorWithCode(SKTWriteCouldntMakeTIFFError);
	
    }
    return tiffData;
    
} */ // SatoAkira delete. //
+ (NSData *)tiffDataWithGraphics:(NSArray *)graphics color:(NSColorSpace *)aSpace error:(NSError **)outError
// SatoAkira add. //
{
    NSData *tiffData;
    NSRect bounds = [SKTGraphic drawingBoundsOfGraphics:graphics];
	if (NO == NSIsEmptyRect(bounds)) {
		NSInteger convert = [[PreferencesController objectForKey:TIFFColorSpaceKey] integerValue];
		CGFloat scale = [[PreferencesController objectForKey:TIFFResolutionKey] floatValue] / 72.0;
		NSTIFFCompression compress = [[PreferencesController objectForKey:TIFFCompressionKey] intValue];
		NSImage *image = [[NSImage allocWithZone:[self zone]] initWithSize:NSMakeSize(scale * NSWidth(bounds), scale * NSHeight(bounds))];
		[image setFlipped:YES];
		[image lockFocus];
		NSGraphicsContext *currentContext = [NSGraphicsContext currentContext];
		
		NSAffineTransform *transform = [NSAffineTransform transform];
		[transform scaleXBy:scale yBy:scale];
		[transform translateXBy:(0.0f - bounds.origin.x) yBy:(0.0f - bounds.origin.y)];
		[transform concat];
		NSUInteger graphicIndex = [graphics count];
		while (graphicIndex-- > 0) {
			SKTGraphic *graphic = [graphics objectAtIndex:graphicIndex];
			[currentContext saveGraphicsState];
			[NSBezierPath clipRect:[graphic drawingBounds]];
			[graphic drawContentsInView:nil isBeingCreateOrEdited:NO];
			[currentContext restoreGraphicsState];
		}
		[image unlockFocus];
		if (nil != image) {
			NSData *tempTIFFData = [image TIFFRepresentation];
			NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:tempTIFFData];
			
			if (nil != imageRep) {
				/* CGImageRef convertImageRef;
				 NSImage *convertImage; */
				NSBitmapImageRep *convertImageRep;
				NSColorSpaceModel cModel = (nil != aSpace) ? [aSpace colorSpaceModel] : NSRGBColorSpaceModel; // colorSpaceがnilになるのは、SKTGraphicView.mからcopy:(id)senderが呼ばれたとき。 //
				
				switch (convert) {
					case SKTTIFFDocument:
						switch (cModel) {
							case NSCMYKColorSpaceModel:
								convertImageRep = rgbToCMYKImageRep(imageRep,aSpace);
								break;
							case NSRGBColorSpaceModel:
								[imageRep setProperty:NSImageColorSyncProfileData withValue:[aSpace ICCProfileData]];
								convertImageRep = imageRep;
								break;
							case NSGrayColorSpaceModel:
								if (nil != (convertImageRep = colorToGrayImageRep(imageRep)))
									[convertImageRep setProperty:NSImageColorSyncProfileData withValue:[aSpace ICCProfileData]];
								break;
							case NSLABColorSpaceModel: case NSDeviceNColorSpaceModel:
								[imageRep setProperty:NSImageColorSyncProfileData withValue:[aSpace ICCProfileData]];
								convertImageRep = imageRep;
								break;
							default:
								convertImageRep = nil;
								break;
						}
						/* convertImageRef = convertBitmapImageRep(imageRep,tempColorSpace);
						 if ((nil != (convertImage = imageFromCGImageRef(convertImageRef))) && (nil != (convertImageRep = [NSBitmapImageRep imageRepWithData:[convertImage TIFFRepresentation]]))) {
						 [convertImageRep setProperty:NSImageColorSyncProfileData withValue:[tempColorSpace ICCProfileData]];
						 } */
						break;
					case SKTTIFFGrayscale:
						convertImageRep = colorToGrayImageRep(imageRep);
						break;
					case SKTTIFFMonochrome:
						convertImageRep = colorToMonoImageRep(imageRep,compress);
						break;
					default:
						convertImageRep = nil;
						break;
				}
				if (nil != convertImageRep) {
					[convertImageRep setSize:bounds.size];
					tiffData = [convertImageRep TIFFRepresentationUsingCompression:compress factor:0.0];
				}
				else
					tiffData = nil;
			}
			else
				tiffData = nil;
		}
		else
			tiffData = nil;
		if (nil == tiffData) {
			if ((NSError **)NULL != outError)
				*outError = SKTErrorWithCode(SKTWriteCouldntMakeTIFFError);
		}
		[image release];
		
    } else {
		tiffData = nil;
		if ((NSError **)NULL != outError) {
			/* NSDictionary *errorUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:
			 
			 // This localized description won't be presented to the user. In code that's more reusable it might be though, so it's a good idea to always provide a decent one that's a full sentence.
			 NSLocalizedStringFromTable(@"A TIFF image could not be made because it would be empty.", @"SKTError", @"Description of can't-make-TIFF error."), NSLocalizedDescriptionKey,
			 
			 // This localized failure reason _will_ be presented to the user. NSDocument will take it and tack it onto the end of a "The document "so-and-so" could not be saved." message and use the whole thing as an error description. Full sentence!
			 NSLocalizedStringFromTable(@"The TIFF image would be empty.", @"SKTError", @"Reason for can't-make-TIFF error."), NSLocalizedFailureReasonErrorKey,
			 
			 nil]; */
			*outError = SKTErrorWithCode(SKTWriteCouldntMakeTIFFError);
		}
	}
	return tiffData;
}
+ (NSData *)epsDataWithGraphics:(NSArray *)graphics color:(NSColorSpace *)aSpace
{
    NSRect bounds = [SKTGraphic drawingBoundsOfGraphics:graphics];

	if (NSIsEmptyRect(bounds))
		return nil;
	else {
		SKTRenderingView *view = [[SKTRenderingView allocWithZone:[self zone]] initWithFrame:NSMakeRect(0.0, 0.0, NSMaxX(bounds), NSMaxY(bounds)) graphics:graphics printJobTitle:[[NSProcessInfo processInfo] processName] color:aSpace];
		NSWindow *window = [[NSWindow allocWithZone:[self zone]] initWithContentRect:NSMakeRect(0.0, 0.0, NSMaxX(bounds), NSMaxY(bounds)) styleMask:NSBorderlessWindowMask backing:NSBackingStoreNonretained defer:NO];
		/* NSPrintInfo *printInfo = [self printInfo]; */
		NSMutableData *epsData = [NSMutableData data];
		NSPrintOperation *printOp;

		[[window contentView] addSubview:view];
		[view release];
		printOp = [NSPrintOperation EPSOperationWithView:view insideRect:bounds toData:epsData printInfo:nil];
		if (nil != printOp) {
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_4
			[printOp setShowsPrintPanel:NO];
#else
			[printOp setShowPanels:NO];
#endif

			if (NO == [printOp runOperation]) // SVGデータにtextエレメントがあると printOp runOperationのところでハングアップする。OS10.5からの現象で10.4では発生しない。 //
				epsData =nil;
		}
		[window release];
		return epsData;
	}
}
void idWalk(NSArray *uniqueNumbers,NSMutableString *idStr,NSUInteger index)
// for uniqueID. 再帰 //
{
	BOOL recursive = NO;
	for (NSString *search in uniqueNumbers) {
		if (YES == [search hasSuffix:idStr]) {
			recursive = YES;
			[idStr appendFormat:@"_%lu",index];
			break;
		}
	}
	if (YES == recursive)
		idWalk(uniqueNumbers,idStr,index);
	else
		return;
}
+ (NSData *)svgDataWithGraphics:(NSArray *)graphics filename:(NSURL *)url
// SatoAkira add. //
{
	NSRect bounds = [SKTGraphic drawingBoundsOfGraphics:graphics];

	if (NSIsEmptyRect(bounds))
		return nil;
	else {
		NSData *xmlData;
		NSXMLDocument *xmlDoc;
		NSArray *elements;
		double width = NSWidth(bounds);
		double height = NSHeight(bounds);
		NSUInteger i = [graphics count];
		NSUInteger errorsCount = 0;
		NSXMLDTD *theDTD = [[NSXMLDTD allocWithZone:[self zone]] init];
		NSXMLElement *root = [NSXMLNode elementWithName:@"svg"];
		NSMutableArray *children = [NSMutableArray array];
		NSMutableArray *uniqueNumbers = [NSMutableArray array]; // for uniqueID //
		NSData *searchXMLdata; // for uniqueID //
		NSXMLDocument *searchXMLDoc; // for uniqueID //
		ASWebImageRep *imageRep; // for uniqueID //
		NSError *err = nil; // for uniqueID //
		NSXMLNode *aNode; // for uniqueID //
		NSXMLElement *anElement; // for uniqueID //
		NSArray *attributes; // for uniqueID //
		NSMutableString *idStr; // for uniqueID //

		[theDTD setName:@"svg"];
		// svg1.1のとき //
		/* [theDTD setPublicID:@"-//W3C//DTD SVG 1.1 Tiny//EN"];
		[theDTD setSystemID:@"http://www.w3.org/Graphics/SVG/1.1/DTD/svg11-tiny.dtd"];
		[root addAttribute:[NSXMLNode attributeWithName:@"version" stringValue:@"1.1"]];
		[root addAttribute:[NSXMLNode attributeWithName:@"baseProfile" stringValue:@"tiny"]]; // svg11-tiny.dtdのときはtiny。svg11-basicのときはbasic。svg11-fullのときはfull。 // */
		// svg1.0のとき //
		[theDTD setPublicID:@"-//W3C//DTD SVG 1.0//EN"];
		[theDTD setSystemID:@"http://www.w3.org/TR/2001/REC-SVG-20010904/DTD/svg10.dtd"];
		// 1.0,1.1共通 //
		[root addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:@"http://www.w3.org/2000/svg"]]; // Name:の引数を空文字にしておくと、デフォルトのxmlnsがセットされる。 //
		[root addNamespace:[NSXMLNode namespaceWithName:@"xlink" stringValue:@"http://www.w3.org/1999/xlink"]]; // xmlns:xlink属性がセットされる。 //
		[root addAttribute:[NSXMLNode attributeWithName:@"id" stringValue:@"svg-root"]];
		// cmでやるとき //
		/* [root addAttribute:[NSXMLNode attributeWithName:@"width" stringValue:[NSString stringWithFormat:@"%gcm",width * 0.035277777777777777]]];
		[root addAttribute:[NSXMLNode attributeWithName:@"height" stringValue:[NSString stringWithFormat:@"%gcm",height * 0.035277777777777777]]]; */
		// pxでやるとき //
		[root addAttribute:[NSXMLNode attributeWithName:@"width" stringValue:[NSString stringWithFormat:@"%lfpx",width]]];
		[root addAttribute:[NSXMLNode attributeWithName:@"height" stringValue:[NSString stringWithFormat:@"%lfpx",height]]];
		// cm,px共通 //
		[root addAttribute:[NSXMLNode attributeWithName:@"viewBox" stringValue:[NSString stringWithFormat:@"%lf %lf %lf %lf",0.0,0.0,width,height]]];
		[children addObject:[NSXMLNode commentWithStringValue:[NSString stringWithFormat:@"Generator: SatoAkira's %@ %@ application",[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"],[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]]]];
		if (nil != url)
			[children addObject:[NSXMLNode elementWithName:@"title" stringValue:[url path]]];
		for (SKTGraphic *graphic in graphics) { // for uniqueID. 既に存在するSVGで使われているidを拾い出す。 //
			if ((YES == [graphic isKindOfClass:[SKTsvg class]]) && (nil != (imageRep = [graphic valueForKey:@"_SVGImageRep"])) && (nil != (searchXMLdata = [imageRep SVGRepresentation]))) {
				err = nil;
				searchXMLDoc = [[NSXMLDocument allocWithZone:[self zone]] initWithData:searchXMLdata options:NSXMLNodeOptionsNone error:&err];
				aNode = [searchXMLDoc rootElement];
				while (nil != (aNode = [aNode nextNode])) {
					if ([aNode kind] == NSXMLElementKind) {
						anElement = (NSXMLElement *)aNode;
						if ((nil != (attributes = [anElement attributes])) && (0 < [attributes count])) {
							for (NSXMLNode *node in attributes) {
								if (YES == [[node name] isEqualToString:@"id"]) {
									[uniqueNumbers addObject:[node stringValue]];
								}
							}
						}
					}
				}
			}
		}
		while (i-- > 0) {
			idStr = [NSMutableString stringWithFormat:@"_%lu",i];
			idWalk(uniqueNumbers, idStr, i); // for uniqueID //
			if (nil != (elements = [[graphics objectAtIndex:i] svgXMLElements:bounds name:[idStr substringFromIndex:1]])) {
				if (0 < [elements count])
					[children addObjectsFromArray:elements];
			}
			else
				errorsCount++;
		}
		[root setChildren:children];
		xmlDoc = [[NSXMLDocument allocWithZone:[self zone]] initWithRootElement:root];
		[xmlDoc setVersion:@"1.0"];
		[xmlDoc setCharacterEncoding:@"UTF-8"];
		[xmlDoc setDTD:theDTD];
		xmlData = [xmlDoc XMLDataWithOptions:NSXMLNodePrettyPrint];
		[xmlDoc release];
		[theDTD release];
		if (0 < errorsCount) {
			NSString *message = [NSString stringWithFormat:NSLocalizedStringFromTable(@"%u objects are not written out, was.",@"SKTError",@""),errorsCount];
			NSBeginAlertSheet(message,nil,nil,nil,nil,self,NULL,NULL,NULL,[NSString string],nil);
		}
		return xmlData;
	}
}
- (NSColorSpace *)viewColorSpace { // SatoAkira add.SKTGraphicのdrawInView::から呼ばれる。 //
	return colorSpace;
}

/* - (id)initWithFrame:(NSRect)frame graphics:(NSArray *)graphics printJobTitle:(NSString *)printJobTitle {

    // Do the regular Cocoa thing.
    self = [super initWithFrame:frame];
    if (self) {
	_graphics = [graphics copy];
	_printJobTitle = [printJobTitle copy];
    }
    return self;

} */ // SatoAkira delete. //
- (id)initWithFrame:(NSRect)frame graphics:(NSArray *)graphics printJobTitle:(NSString *)printJobTitle color:(NSColorSpace *)aSpace
// SatoAkira add. //
{
	if (nil != (self = [super initWithFrame:frame])) {
		_graphics = (nil != graphics) ? [[NSArray allocWithZone:[self zone]] initWithArray:graphics] : nil; // _graphics = [graphics copy];でも良い //
		_printJobTitle = (nil != printJobTitle) ? [[NSString allocWithZone:[self zone]] initWithString:printJobTitle] : nil;
		title = nil;
		colorSpace = aSpace;
	}
    return self;
}

- (void)dealloc {

    // Do the regular Cocoa thing.
    [_printJobTitle release];
    [_graphics release];
	[title release]; // SatoAkira add. //
    [super dealloc];

}


// An override of the NSView method.
- (void)drawRect:(NSRect)rect {

    // Draw the background background.
    /* [[NSColor whiteColor] set];
    NSRectFill(rect); */ // SatoAkira delete. //
    
    // Draw every graphic that intersects the rectangle to be drawn. In Sketch the frontmost graphics have the lowest indexes.
    NSGraphicsContext *currentContext = [NSGraphicsContext currentContext];
    NSInteger graphicCount = [_graphics count];
    for (NSInteger index = graphicCount - 1; index>=0; index--) {
        SKTGraphic *graphic = [_graphics objectAtIndex:index];
        NSRect graphicDrawingBounds = [graphic drawingBounds];
        if (NSIntersectsRect(rect, graphicDrawingBounds)) {

	    // Draw the graphic.
            [currentContext saveGraphicsState];
            [NSBezierPath clipRect:graphicDrawingBounds];
            [graphic drawContentsInView:self isBeingCreateOrEdited:NO];
            [currentContext restoreGraphicsState];
	    
        }
    }
    // 64ビットのプリンタードライバーにバグがあったときは、SKTDocumentのprintOperationWithSettings:のあとここまで来て、この後でハングアップするのでどうにもならなかった。 //
}


// An override of the NSView method.
- (BOOL)isFlipped {

    // Put (0, 0) at the top-left of the view.
    return YES;

}


// An override of the NSView method.
- (BOOL)isOpaque {

    // Our override of -drawRect: always draws a background.
    return YES;

}


// An override of the NSView method.
- (NSString *)printJobTitle {
    
    // Do the regular Cocoa thing.
    return [[_printJobTitle retain] autorelease];

}

- (NSAttributedString *)pageHeader
// SatoAkira add. titleがnilでNSPrintHeaderAndFooterがYESのときは何も印字しない。　//
{
	if (nil != title) {
		NSMutableAttributedString *aStr = [[NSMutableAttributedString allocWithZone:[self zone]] initWithAttributedString:[super pageHeader]];
		NSDateFormatter *dateTimeFormatter = [[NSDateFormatter allocWithZone:[self zone]] init];
		[dateTimeFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
		[dateTimeFormatter setCalendar:[NSCalendar autoupdatingCurrentCalendar]];
		[dateTimeFormatter setDateStyle:NSDateFormatterFullStyle];
		[dateTimeFormatter setTimeStyle:NSDateFormatterFullStyle];
		
		[aStr replaceCharactersInRange:NSMakeRange(0,[aStr length]) withString:[NSString stringWithFormat:@"\t\t%@",[dateTimeFormatter stringFromDate:[NSDate date]]]];
		[dateTimeFormatter release];
		return [aStr autorelease];
	}
	else
		return nil;
}
- (NSAttributedString *)pageFooter
// SatoAkira add. 1ページものなのでページ数は意味が無い。省略させるときはnilを返せば良い。 //
{
	if (nil != title) {
		NSMutableAttributedString *aStr = [[NSMutableAttributedString allocWithZone:[self zone]] initWithAttributedString:[super pageFooter]];

		[aStr replaceCharactersInRange:NSMakeRange(0,[aStr length]) withString:[NSString stringWithFormat:@"%@\t\t",title]];
		return [aStr autorelease];
	}
	else
		return nil;
}

@end
