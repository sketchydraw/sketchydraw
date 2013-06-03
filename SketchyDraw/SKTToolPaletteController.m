/*
     File: SKTToolPaletteController.m
 Abstract: A controller to manage the tools palette.
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

#import "SKTToolPaletteController.h"
#import "SKTCircle.h"
#import "SKTLine.h"
#import "SKTRectangle.h"
#import "SKTText.h"
#import "SKTCurve.h" // SatoAkira add. //
#import "SKTPolygon.h" // SatoAkira add. //
#import "SKTBezierCurve.h" // SatoAkira add. //
#import <ASWebView/ASWebImageRep.h>  // SatoAkira add. //

/* enum {
    SKTArrowToolRow = 0,
    SKTRectToolRow,
    SKTCircleToolRow,
    SKTLineToolRow,
    SKTTextToolRow,
}; */ // Satoakira delete. //
enum {
    SKTArrowToolRow = 0,
	SKTCircleToolRow,
	SKTLineToolRow,
	SKTScribbleToolRow,
	SKTTextToolRow,
	SKTRectToolRow,
	SKTCurveToolRow,
	SKTPolygonToolRow,
	SKTBezierCurveRow
}; // SatoAkira add. //

NSString *SKTSelectedToolDidChangeNotification = @"SKTSelectedToolDidChange";

@implementation SKTToolPaletteController

+ (id)sharedToolPaletteController {
    static SKTToolPaletteController *sharedToolPaletteController = nil;

    if (!sharedToolPaletteController) {
        sharedToolPaletteController = [[SKTToolPaletteController allocWithZone:NULL] init];
    }

    return sharedToolPaletteController;
}

- (id)init {
    self = [self initWithWindowNibName:@"ToolPalette"];
    if (self) {
        [self setWindowFrameAutosaveName:@"ToolPalette"];
    }
    return self;
}

- (void)windowDidLoad {
    NSArray *cells = [toolButtons cells];
    NSUInteger i, c = [cells count];
	NSArray *classes = [NSArray arrayWithObjects:@"Arrow",NSStringFromClass([SKTCircle class]),NSStringFromClass([SKTLine class]),NSStringFromClass([SKTScribble class]),NSStringFromClass([SKTText class]),NSStringFromClass([SKTRectangle class]),NSStringFromClass([SKTCurve class]),NSStringFromClass([SKTPolygon class]),NSStringFromClass([SKTBezierCurve class]),nil]; // SatoAkira add. //
    
    [super windowDidLoad];
    for (i=0; i<c; i++) {
		/* [[cells objectAtIndex:i] setImageScaling:NSScaleProportionally]; */ // SatoAkira delete. Deprecated in OS X v10.6. //
		[[cells objectAtIndex:i] setImageScaling:NSImageScaleProportionallyDown]; // SatoAkira add. //
		[[cells objectAtIndex:i] setImage:[NSImage imageNamed:[classes objectAtIndex:i]]]; // SatoAkira add. Cell Size 46*42 //
		[[cells objectAtIndex:i] setButtonType:NSPushOnPushOffButton]; // SatoAkira add. //
        [[cells objectAtIndex:i] setRefusesFirstResponder:YES];
    }
		[(NSPanel *)[self window] setFloatingPanel:YES]; // SatoAkira add. //
    [(NSPanel *)[self window] setBecomesKeyOnlyIfNeeded:YES];

		[toolButtons setIntercellSpacing:NSMakeSize(0.0, 0.0)]; // SatoAkira add. [toolButtons sizeToFit];をやると.icnsの内の最大サイズの画像になってしまう。 //
    // Interface Builder (IB 2.4.1, anyway) won't let us set the window's width to less than 59 pixels, but we really only need 42.
    [[self window] setContentSize:[toolButtons frame].size];
		[toolButtons setFrameOrigin:NSMakePoint(0.0, 0.0)]; // SatoAkira add. IBで(5.0,7.0)となっているがここで変更しないと中央に来ない。 //
		[toolButtons setAllowsEmptySelection:NO]; // SatoAkira add. //
		[toolButtons setMode:NSRadioModeMatrix]; // SatoAkira add. //
		[[self window] setTitle:NSLocalizedString(@"Tool",@"ツール")]; // SatoAkira add. //
		[[NSColorPanel sharedColorPanel] setShowsAlpha:YES]; // SatoAkira add.他でやるところがないのでここでやる。 //
		[patternColorButton setTitle:NSLocalizedString(@"Open pattern file...",@"パターンファイルを開く...")]; // SatoAkira add. //
		[[NSColorPanel sharedColorPanel] setAccessoryView:patternColorAccessoryView]; // SatoAkira add. //
}

- (IBAction)selectToolAction:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:SKTSelectedToolDidChangeNotification object:self];
}

/* - (Class)currentGraphicClass {
    NSInteger row = [toolButtons selectedRow];
    Class theClass = nil;
    if (row == SKTRectToolRow) {
        theClass = [SKTRectangle class];
    } else if (row == SKTCircleToolRow) {
        theClass = [SKTCircle class];
    } else if (row == SKTLineToolRow) {
        theClass = [SKTLine class];
    } else if (row == SKTTextToolRow) {
        theClass = [SKTText class];
    }
    return theClass;
} */
- (Class)currentGraphicClass
// SatoAkira change. classの配列を使えばもっと簡単になる。 //
{
    int row = [toolButtons selectedRow];
	int column = [toolButtons selectedColumn];
    Class theClass = nil;

	switch (row * [toolButtons numberOfColumns] + column) {
	case SKTArrowToolRow:
		theClass = nil;
		break;
	case SKTCircleToolRow:
		theClass = [SKTCircle class];
		break;
	case SKTLineToolRow:
		theClass = [SKTLine class];
		break;
	case SKTScribbleToolRow:
		theClass = [SKTScribble class];
		break;
	case SKTTextToolRow:
		theClass = [SKTText class];
		break;
	case SKTRectToolRow:
		theClass = [SKTRectangle class];
		break;
	case SKTCurveToolRow:
		theClass = [SKTCurve class];
		break;
	case SKTPolygonToolRow:
		theClass = [SKTPolygon class];
		break;
	case SKTBezierCurveRow:
		theClass = [SKTBezierCurve class];
		break;
	default:
		theClass = nil;
		break;
	}
	if (nil == theClass)
		[toolButtons selectCellAtRow:0 column:0];
    return theClass;
}

- (void)selectArrowTool {
    [toolButtons selectCellAtRow:SKTArrowToolRow column:0];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKTSelectedToolDidChangeNotification object:self];
}

- (IBAction)openPatternColorFile:(id)sender
// SatoAkira add. //
{
	NSOpenPanel *oPanel = [NSOpenPanel openPanel];
	NSURL *tempURL = [[NSUserDefaults standardUserDefaults] URLForKey:@"OpenPatternColorFile"];
	NSError *err = nil;
	NSURL *tempDirectory = ((nil != tempURL) && (YES == [tempURL isFileURL])) ? [NSURL fileURLWithPath:[[tempURL path] stringByDeletingLastPathComponent]] : nil;
	NSURL *defaultDirectory = ((nil != tempDirectory) && (YES == [tempDirectory checkResourceIsReachableAndReturnError:&err])) ? tempDirectory : nil;
	NSString *defaultName = ((nil != tempURL) && (YES == [tempURL isFileURL])) ? [tempURL lastPathComponent] : @"";
	
	[oPanel setDirectoryURL:defaultDirectory];
	[oPanel setNameFieldStringValue:defaultName];
	[oPanel setCanChooseDirectories:NO];
	[oPanel beginSheetModalForWindow:[NSColorPanel sharedColorPanel] completionHandler:^(NSInteger result)
	 {
		 if (NSFileHandlingPanelOKButton == result) {
			 NSImageRep *imageRep;
			 NSImage *anImage;
			 NSURL *url = [[oPanel URLs] objectAtIndex:0];
			 
			 [NSImageRep registerImageRepClass:[ASWebImageRep class]];
			 if (nil != (imageRep = [NSImageRep imageRepWithContentsOfURL:url])) {
				 if ((NO == [[imageRep colorSpaceName] isEqualToString:NSCalibratedRGBColorSpace]) && (NO == [[imageRep colorSpaceName] isEqualToString:NSDeviceRGBColorSpace])) {
					 if (YES == [imageRep isKindOfClass:[ASWebImageRep class]]) {
						 [NSImageRep unregisterImageRepClass:[ASWebImageRep class]]; // ここが重要。NSImageのinitWithData:の前にやらなければならない。 //
						 anImage = [[NSImage allocWithZone:[self zone]] initWithData:[(ASWebImageRep *)imageRep PDFRepresentation]]; // "Bad colorspace name NSCustomColorSpace"という警告メッセージが出されることを避ける為の処置。 //
					 }
					 else {
						 if (nil != (anImage = [[NSImage alloc] initWithSize:[imageRep size]]))
							 [anImage addRepresentation:imageRep];
						 [NSImageRep unregisterImageRepClass:[ASWebImageRep class]];
					 }
				 }
				 else {
					 if (nil != (anImage = [[NSImage alloc] initWithSize:[imageRep size]])) {
						 [anImage setScalesWhenResized:YES]; // 効き目無し。 //
						 [anImage addRepresentation:imageRep]; // addRepresentationをしても72dpiに固定されてしまう。 //
						 [anImage setSize:[imageRep size]]; // 効き目無し。 //
					 }
					 [NSImageRep unregisterImageRepClass:[ASWebImageRep class]];
				 }
			 }
			 else
				 anImage = nil;
			 if (nil != anImage) {
				 NSColor *aColor = [NSColor colorWithPatternImage:anImage];
				 [anImage release];
				 if (nil != aColor)
					 [[NSColorPanel sharedColorPanel] setColor:aColor];
				 else
					 NSBeginAlertSheet(NSLocalizedStringFromTable(@"An unknown error occured.",@"ErrorStrings",@"未知のエラーが発生しました。"),nil,nil,nil,nil,self,NULL,NULL,NULL,[NSString string],nil);
			 }
			 else
				 NSBeginAlertSheet(NSLocalizedStringFromTable(@"An unknown error occured.",@"ErrorStrings",@"未知のエラーが発生しました。"),nil,nil,nil,nil,self,NULL,NULL,NULL,[NSString string],nil);
			 [[NSUserDefaults standardUserDefaults] setURL:url forKey:@"OpenPatternColorFile"];
		 }
	 }
	 ];
}

@end
