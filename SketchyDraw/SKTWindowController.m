/*
     File: SKTWindowController.m
 Abstract: A window controller to manage display of a Sketch window.
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

#import "SKTWindowController.h"
#import "SKTDocument.h"
#import "SKTGraphic.h"
#import "SKTGraphicView.h"
#import "SKTGrid.h"
#import "SKTToolPaletteController.h"
#import "SKTZoomingScrollView.h"
#import "PreferencesController.h" // SatoAkira add. //


// A value that's used as a context by this class' invocation of a KVO observer registration method. See the comment near the top of SKTGraphicView.m for a discussion of this.
static NSString *SKTWindowControllerCanvasSizeObservationContext = @"com.apple.SKTWindowController.canvasSize";


@implementation SKTWindowController


- (id)init {

    // Do the regular Cocoa thing, specifying a particular nib.
    self = [super initWithWindowNibName:@"DrawWindow"];
    if (self) {

	// Create a grid for use by graphic views whose "grid" property is bound to this object's "grid" property.
	_grid = [[SKTGrid alloc] init];

	// Set the zoom factor to a reasonable default (100%).
	_zoomFactor = 1.0f;

    }
    return self;

}


- (void)dealloc {

    // Stop observing the tool palette.
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SKTSelectedToolDidChangeNotification object:[SKTToolPaletteController sharedToolPaletteController]];
    
    // Stop observing the document's canvas size.
    [[self document] removeObserver:self forKeyPath:SKTDocumentCanvasSizeKey];

    // Do the regular Cocoa thing.
    [_grid release];
    [super dealloc];

}


#pragma mark *** Observing ***

- (NSSize)calcWindowMaxSize:(NSSize)viewSize
// SatoAkira add. rulerのサイズを取得しなくても自動的に算出される。 //
{
	NSRect windowRect = [[self window] frame];
	NSSize minSize = [[self window] minSize]; // InterfaceBuilderで最小値の設定をしておくこと //
    NSScrollView *enclosingScrollView = [_graphicView enclosingScrollView];
	NSSize contentsViewSize = [enclosingScrollView contentSize];
	CGFloat maxWidth = NSWidth(windowRect) - contentsViewSize.width + viewSize.width;
	CGFloat maxHeight = NSHeight(windowRect) - contentsViewSize.height + viewSize.height; // - ToolbarHeightForWindow([self window]); ツールバーを使ったときは、これを追加する。 //
	CGFloat newMaxWidth = (maxWidth > minSize.width) ? maxWidth : minSize.width;
	CGFloat newMaxHeight = (maxHeight > minSize.height) ? maxHeight : minSize.height;
	return NSMakeSize(newMaxWidth,newMaxHeight);
}
- (void)setWindowSize
// _graphicViewのサイズは_zoomFactorsと無関係
{
	NSSize paperSize = [[self document] canvasSize];
	NSSize graphicViewSize = NSMakeSize(_zoomFactor * paperSize.width, _zoomFactor * paperSize.height);
	NSSize maxSize = [self calcWindowMaxSize:graphicViewSize];
	[[self window] setMaxSize:maxSize];
	NSRect winFrame = [[self window] frame];
	if (winFrame.size.width >  maxSize.width)
		winFrame.size.width = maxSize.width;
	if (winFrame.size.height > maxSize.height) // + ToolbarHeightForWindow([self window]); ツールバーを使ったときは、これを追加する。 //
		winFrame.size.height = maxSize.height; // + ToolbarHeightForWindow([self window]); ツールバーを使ったときは、これを追加する。 //
	[[self window] setFrame:winFrame display:YES];
	// [graphicView setNeedsDisplay:YES]; はやらなくても良い。 //
}

- (void)observeDocumentCanvasSize:(NSSize)documentCanvasSize {
    
    // The document's canvas size changed. Invoking -setNeedsDisplay: twice like this makes sure everything gets redrawn if the view gets smaller in one direction or the other.
    [_graphicView setNeedsDisplay:YES];
    [_graphicView setFrameSize:documentCanvasSize];
    [_graphicView setNeedsDisplay:YES];
	[self setWindowSize]; // SatoAkira add. //

}


// An override of the NSObject(NSKeyValueObserving) method.
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(NSObject *)observedObject change:(NSDictionary *)change context:(void *)context {

    // Make sure we don't intercept an observer notification that's meant for NSWindowController. In Mac OS 10.5 and earlier NSWindowControllers don't observe anything, but that could change in the future. We can do a simple pointer comparison because KVO doesn't do anything at all with the context value, not even retain or copy it.
    if (context==SKTWindowControllerCanvasSizeObservationContext) {

	// The "new value" in the change dictionary will be NSNull, instead of just not existing, if the value for some key in the key path is nil. In this case there are times in an NSWindowController's life cycle when its document is nil. Don't update the graphic view's size when we get notifications about that.
	NSValue *documentCanvasSizeValue = [change objectForKey:NSKeyValueChangeNewKey];
	if (![documentCanvasSizeValue isEqual:[NSNull null]]) {
	    [self observeDocumentCanvasSize:[documentCanvasSizeValue sizeValue]];
	}

    } else {
	
	// In overrides of -observeValueForKeyPath:ofObject:change:context: always invoke super when the observer notification isn't recognized. Code in the superclass is apparently doing observation of its own. NSObject's implementation of this method throws an exception. Such an exception would be indicating a programming error that should be fixed.
	[super observeValueForKeyPath:keyPath ofObject:observedObject change:change context:context];

    }

}


- (void)selectedToolDidChange:(NSNotification *)notification {
    // Just set the correct cursor
    Class theClass = [[SKTToolPaletteController sharedToolPaletteController] currentGraphicClass];
    NSCursor *theCursor = nil;
    if (theClass) {
        theCursor = [theClass creationCursor];
    }
    if (!theCursor) {
        theCursor = [NSCursor arrowCursor];
    }
    [[_graphicView enclosingScrollView] setDocumentCursor:theCursor];
}


#pragma mark *** Overrides of NSWindowController Methods ***


- (void)setDocument:(NSDocument *)document {

    // Cocoa Bindings makes many things easier. Unfortunately, one of the things it makes easier is creation of reference counting cycles. In Mac OS 10.4 and later NSWindowController has a feature that keeps bindings to File's Owner, when File's Owner is a window controller, from retaining the window controller in a way that would prevent its deallocation. We're setting up bindings programmatically in -windowDidLoad though, so that feature doesn't kick in, and we have to explicitly unbind to make sure this window controller and everything in the nib it owns get deallocated. We do this here instead of in an override of -[NSWindowController close] because window controllers aren't sent -close messages for every kind of window closing. Fortunately, window controllers are sent -setDocument:nil messages during window closing.
    if (!document) {
	[_zoomingScrollView unbind:SKTZoomingScrollViewFactor];
	[_graphicView unbind:SKTGraphicViewGridBindingName];
	[_graphicView unbind:SKTGraphicViewGraphicsBindingName];
		[_graphicView unbind:SKTGraphicViewColorSpaceBindingName]; // SatoAkira add. //
	}
    
    // Redo the observing of the document's canvas size when the document changes. You would think we would just be able to observe self's "document.canvasSize" in -windowDidLoad or maybe even -init, but KVO wasn't really designed with observing of self in mind so things get a little squirrelly.
    [[self document] removeObserver:self forKeyPath:SKTDocumentCanvasSizeKey];
    [super setDocument:document];
    [[self document] addObserver:self forKeyPath:SKTDocumentCanvasSizeKey options:NSKeyValueObservingOptionNew context:SKTWindowControllerCanvasSizeObservationContext];

}

- (void)backgroundColorDidChange:(NSNotification *)notification
// SatoAkira add. //
{
	NSColor *viewFillColor;
	NSDictionary *userInfo = (nil != notification) ? [notification userInfo] : nil;
	NSInteger useBackgroundColor = (nil != userInfo) ? [[userInfo objectForKey:UseBackgroundColorKey] intValue] : NSMixedState;

	if ((nil == notification) || (NSMixedState == useBackgroundColor)) {
		PreferencesController *prefs = [PreferencesController sharedPreferencesController];
		NSDictionary *prefesDic = [prefs preferences];
		useBackgroundColor = [[prefesDic objectForKey:UseBackgroundColorKey] intValue];
		viewFillColor = [prefesDic objectForKey:BackgroundColorKey];
		if (NSOnState == useBackgroundColor) {
			[[_graphicView enclosingScrollView] setBackgroundColor:viewFillColor];
			[[self window] setBackgroundColor:[NSColor windowFrameColor]];
			[[self window] setOpaque:YES];
		}
		else {
			[[_graphicView enclosingScrollView] setBackgroundColor:[[NSColor windowFrameColor] colorWithAlphaComponent:0.0]];
			[[self window] setBackgroundColor:[[NSColor windowFrameColor] colorWithAlphaComponent:0.0]];
			[[self window] setOpaque:NO];
		}
		if (nil != notification)
			[[self window] display];
	}
	else {
		if (NSOnState == useBackgroundColor) {
			viewFillColor = [userInfo objectForKey:BackgroundColorKey];
			[[_graphicView enclosingScrollView] setBackgroundColor:viewFillColor];
			[[self window] display];
		}
	}
}

- (void)windowDidLoad {

    // Do the regular Cocoa thing.
    [super windowDidLoad];

    // Set up the graphic view and its enclosing scroll view.
    NSScrollView *enclosingScrollView = [_graphicView enclosingScrollView];
    [enclosingScrollView setHasHorizontalRuler:YES];
    [enclosingScrollView setHasVerticalRuler:YES];

    // We're already observing the document's canvas size in case it changes, but we haven't been able to size the graphic view to match until now.
    [self observeDocumentCanvasSize:[(SKTDocument *)[self document] canvasSize]];

    // Bind the graphic view's selection indexes to the controller's selection indexes. The graphics controller's content array is bound to the document's graphics in the nib, so it knows when graphics are added and remove, so it can keep the selection indexes consistent.
    [_graphicView bind:SKTGraphicViewSelectionIndexesBindingName toObject:_graphicsController withKeyPath:@"selectionIndexes" options:nil];

    // Bind the graphic view's graphics to the document's graphics. We do this instead of binding to the graphics controller because NSArrayController is not KVC-compliant enough for "arrangedObjects" to work properly when the graphic view sends its bound-to object a -mutableArrayValueForKeyPath: message. The binding to self's "document.graphics" is 1) easy and 2) appropriate for a window controller that may someday be able to show one of several documents in its window. If we instead bound the graphic view to [self document] then we would have to redo the binding in -setDocument:.
    [_graphicView bind:SKTGraphicViewGraphicsBindingName toObject:self withKeyPath:[NSString stringWithFormat:@"%@.%@", @"document", SKTDocumentGraphicsKey] options:nil];

    // Bind the graphic view's grid to this window controller's grid.
    [_graphicView bind:SKTGraphicViewGridBindingName toObject:self withKeyPath:@"grid" options:nil];

    // Bind the zooming scroll view's factor to this window's controller's zoom factor.
    [_zoomingScrollView bind:SKTZoomingScrollViewFactor toObject:self withKeyPath:@"zoomFactor" options:nil];
	// ↓SatoAkira add. //
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	PreferencesController *prefs = [PreferencesController sharedPreferencesController];
	[_graphicView bind:SKTGraphicViewColorSpaceBindingName toObject:self withKeyPath:[NSString stringWithFormat:@"%@.%@", @"document", SKTColorSpaceKey] options:nil];
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	NSString *measurementUnit = (nil != [defaults objectForKey:MeasurementUnitKey]) ? [defaults objectForKey:MeasurementUnitKey] : @"point"; // point,mm,inch,pica //
	NSDictionary *convert = [NSDictionary dictionaryWithObjectsAndKeys:@"Inches",@"inch",@"Centimeters",@"mm",@"Points",@"point",@"Picas",@"pica",nil];
	[[_zoomingScrollView horizontalRulerView] setMeasurementUnits:[convert objectForKey:measurementUnit]];
	[[_zoomingScrollView verticalRulerView] setMeasurementUnits:[convert objectForKey:measurementUnit]];
	[self backgroundColorDidChange:nil];
	[nc addObserver:self selector:@selector(backgroundColorDidChange:) name:SKTBackgroundColorDidChangeNotification object:prefs];
	[nc addObserver:self selector:@selector(backgroundColorDidChange:) name:SKTUseBackgroundColorDidChangeNotification object:prefs];
	[nc addObserver:self selector:@selector(knobColorDidChange:) name:SKTKnobColorDidChangeNotification object:prefs];
	[nc addObserver:self selector:@selector(measurementUnitDidChange:) name:SKTMeasurementUnitDidChangeNotification object:[PreferencesController sharedPreferencesController]];
	// ↑SatoAkira add. //
    
    // Start observing the tool palette.
    [self selectedToolDidChange:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectedToolDidChange:) name:SKTSelectedToolDidChangeNotification object:[SKTToolPaletteController sharedToolPaletteController]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(zoomingScrollViewFactorDidChange:) name:@"ZoomingScrollViewFactorDidChange" object:_zoomingScrollView]; // SatoAkira add. //
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rulerDidShowOrHide:) name:@"RulerDidShowOrHide" object:_graphicView]; // SatoAkira add. //
	// [[self window] setDelegate:self]; をやっていないので、IBからdelegate接続をしておかなければならない。これをやらないと、このSKTWindowControllerのdeallcが呼ばれなくなってしまう。さらにSKTGraphicViewへもdeallocがされなくなってしまう。[[self window] makeFirstResponder:_graphicView]; もやっていないのでIBからinitialFirstResponder接続をしておく。 //

}

// ↓SatoAkira add. //
- (void)knobColorDidChange:(NSNotification *)notification {
	[_graphicView setNeedsDisplay:YES];
}
- (void)zoomingScrollViewFactorDidChange:(NSNotification *)notification {
	[self setWindowSize];;
}
- (void)rulerDidShowOrHide:(NSNotification *)notification {
	[self setWindowSize];
}
- (NSFontDescriptor *)fontDescriptor {
	return [[self document] valueForKey:SKTFontDescriptorKey];
}
// ↑SatoAkira add. //

#pragma mark *** Actions ***


// Conformance to the NSObject(NSMenuValidation) informal protocol.
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {

    // Which menu item?
    BOOL enabled;
    SEL action = [menuItem action];
    if (action==@selector(newDocumentWindow:)) {

	// Give the menu item that creates new sibling windows for this document a reasonably descriptive title. It's important to use the document's "display name" in places like this; it takes things like file name extension hiding into account. We could do a better job with the punctuation!
	[menuItem setTitle:[NSString stringWithFormat:NSLocalizedStringFromTable(@"New window for '%@'", @"MenuItems", @"Formatter string for the new document window menu item. Argument is a the display name of the document."), [[self document] displayName]]];
	enabled = YES;

    } else if (action==@selector(toggleGridConstraining:) || action==@selector(toggleGridShowing:)) {

	// The grid can be in an unusable state, in which case the menu items that control it are disabled.
	enabled = [_grid isUsable];

	// The Snap to Grid and Show Grid menu items are toggles.
	BOOL menuItemIsOn = action==@selector(toggleGridConstraining:) ? [_grid isConstraining] : [_grid isAlwaysShown];
	[menuItem setState:(menuItemIsOn ? NSOnState : NSOffState)];

    } else {
	enabled = [super validateMenuItem:menuItem];
    }
    return enabled;

}


- (IBAction)newDocumentWindow:(id)sender {

    // Do the same thing that a typical override of -[NSDocument makeWindowControllers] would do, but then also show the window. This is here instead of in SKTDocument, though it would work there too, with one small alteration, because it's really view-layer code.
    SKTWindowController *windowController = [[SKTWindowController alloc] init];
    [[self document] addWindowController:windowController];
    [windowController showWindow:self];
    [windowController release];

}


- (IBAction)toggleGridConstraining:(id)sender {

    // Simple.
    [_grid setConstraining:![_grid isConstraining]];

}


- (IBAction)toggleGridShowing:(id)sender{

    // Simple.
    [_grid setAlwaysShown:![_grid isAlwaysShown]];

}
- (void)measurementUnitDidChange:(NSNotification *)notification
// SatoAkira add. //
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *measurementUnit = [defaults objectForKey:MeasurementUnitKey];
	NSDictionary *convert = [NSDictionary dictionaryWithObjectsAndKeys:@"Inches",@"inch",@"Centimeters",@"mm",@"Points",@"point",@"Picas",@"pica",nil];
	[[_zoomingScrollView horizontalRulerView] setMeasurementUnits:[convert objectForKey:measurementUnit]];
	[[_zoomingScrollView verticalRulerView] setMeasurementUnits:[convert objectForKey:measurementUnit]];
}

	/* [[whereForm cellAtRow:0 column:0] setTitle:NSLocalizedString(@"Where",@"")];
	[[sizeForm cellAtRow:0 column:0] setTitle:NSLocalizedString(@"Size",@"")];
	[[modifiedForm cellAtRow:0 column:0] setTitle:NSLocalizedString(@"Modofied",@"")];
	[[papersizeForm cellAtRow:0 column:0] setTitle:NSLocalizedString(@"Paper Size",@"")];
	[[orientationForm cellAtRow:0 column:0] setTitle:NSLocalizedString(@"Orientation",@"")];
	[[leftMarginForm cellAtRow:0 column:0] setTitle:NSLocalizedString(@"Left",@"")];
	[[topMarginForm cellAtRow:0 column:0] setTitle:NSLocalizedString(@"Top",@"")];
	[[bottomMarginForm cellAtRow:0 column:0] setTitle:NSLocalizedString(@"Bottom",@"")];
	[[rightMarginForm cellAtRow:0 column:0] setTitle:NSLocalizedString(@"Right",@"")];
	[whereForm calcSize];
	[sizeForm calcSize];
	[modifiedForm calcSize];
	[papersizeForm calcSize];
	[orientationForm calcSize];
	[leftMarginForm calcSize];
	[topMarginForm calcSize];
	[bottomMarginForm calcSize];
	[rightMarginForm calcSize];
	[marginTitleField setStringValue:NSLocalizedString(@"Margin",@"")];
	[[sizeForm cellAtRow:0 column:0] setEntryType:NSPositiveIntType];
	[unitsPopUp selectItemWithTitle:(YES == [measurementUnit isEqualToString:@"mm"]) ? @"cm" : measurementUnit];
	[oldUnitsField setStringValue:[unitsPopUp titleOfSelectedItem]];
	[self fileInfo]; */
/* - (void)fileInfo
// SatoAkira add. //
{
	NSString *empty = @"";
	NSString *filename = (nil != [[self document] fileName]) ? [[self document] fileName] : empty;
	NSPrintInfo *pInfo = [[self document] printInfo];

	[[whereForm cellAtRow:0 column:0] setStringValue:filename];
	if (NO == [filename isEqualToString:empty]) {
		NSDictionary *fattrs = [[NSFileManager defaultManager] fileAttributesAtPath:filename traverseLink:YES];
		NSDateFormatter *dateTimeFormatter = [[NSDateFormatter allocWithZone:[self zone]] init];

		[dateTimeFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
		[dateTimeFormatter setLocale:[NSLocale currentLocale]];
		[dateTimeFormatter setDateStyle:NSDateFormatterFullStyle];
		[dateTimeFormatter setTimeStyle:NSDateFormatterFullStyle];
		[[modifiedForm cellAtRow:0 column:0] setStringValue:[dateTimeFormatter stringFromDate:[fattrs fileModificationDate]]];
		[[sizeForm cellAtRow:0 column:0] setIntValue:[fattrs fileSize]];
	}
	else {
		[[modifiedForm cellAtRow:0 column:0] setStringValue:empty];
		[[sizeForm cellAtRow:0 column:0] setStringValue:empty];
	}
	if (nil != pInfo) {
		NSString *ori;
		NSString *paperName = [pInfo paperName];
		NSDictionary *pointsPerUnit = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:28.35],@"cm",[NSNumber numberWithFloat:72.0],@"inch",[NSNumber numberWithFloat:12.0],@"pica",[NSNumber numberWithFloat:1.0],@"point",nil];
		NSString *lastUnits = [unitsPopUp titleOfSelectedItem];
		float ratio = [[pointsPerUnit objectForKey:lastUnits] floatValue];

		if ((nil != paperName) && (NO == [paperName isEqualToString:empty]))
			[[papersizeForm cellAtRow:0 column:0] setStringValue:[pInfo paperName]];
		else
			[[papersizeForm cellAtRow:0 column:0] setStringValue:NSStringFromSize([pInfo paperSize])];
		switch ([pInfo orientation]) {
		case NSPortraitOrientation:
			ori = NSLocalizedString(@"PortraitOrientation",@"ポートレイト");
			break;
		case NSLandscapeOrientation:
			ori = NSLocalizedString(@"LandscapeOrientation",@"ランドスケープ");
			break;
		default:
			ori = NSLocalizedString(@"M LandscapeOrientation",@"逆ランドスケープ");
			break;
		}
		[[orientationForm cellAtRow:0 column:0] setStringValue:ori];
		[[leftMarginForm cellAtRow:0 column:0] setFloatValue:[pInfo leftMargin] / ratio];
		[[topMarginForm cellAtRow:0 column:0] setFloatValue:[pInfo topMargin] / ratio];
		[[bottomMarginForm cellAtRow:0 column:0] setFloatValue:[pInfo bottomMargin] / ratio];
		[[rightMarginForm cellAtRow:0 column:0] setFloatValue:[pInfo rightMargin] / ratio];
	}
	else {
		[[papersizeForm cellAtRow:0 column:0] setStringValue:empty];
		[[orientationForm cellAtRow:0 column:0] setStringValue:empty];
		[[leftMarginForm cellAtRow:0 column:0] setStringValue:empty];
		[[topMarginForm cellAtRow:0 column:0] setStringValue:empty];
		[[bottomMarginForm cellAtRow:0 column:0] setStringValue:empty];
		[[rightMarginForm cellAtRow:0 column:0] setStringValue:empty];
	}
	if (NO == [filename isEqualToString:empty])
		[[colorSpaceForm cellAtRow:0 column:0] setStringValue:[NSString stringWithFormat:@"%@ [%d]",[[[self document] valueForKey:SKTColorSpaceKey] localizedName],[[[self document] valueForKey:SKTColorSpaceKey] numberOfColorComponents]]];
	else
		[[colorSpaceForm cellAtRow:0 column:0] setStringValue:empty];
}
- (IBAction)showInfo:(id)sender
// SKTDrawDocumentではinfoDrawerを定義できないのでここでやる。 //
// SatoAkira add. //
{
	[infoDrawer toggle:sender];
}
- (IBAction)changeUnits:(id)sender
// SatoAkira add. //
{
	NSDictionary *pointsPerUnit = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:28.35],@"cm",[NSNumber numberWithFloat:72.0],@"inch",[NSNumber numberWithFloat:12.0],@"pica",[NSNumber numberWithFloat:1.0],@"point",nil];
	float lastRatio = [[pointsPerUnit objectForKey:[oldUnitsField stringValue]] floatValue];
	float l = [[leftMarginForm cellAtRow:0 column:0] floatValue] * lastRatio;
	float r = [[rightMarginForm cellAtRow:0 column:0] floatValue] * lastRatio;
	float t = [[topMarginForm cellAtRow:0 column:0] floatValue] * lastRatio;
	float b = [[bottomMarginForm cellAtRow:0 column:0] floatValue] * lastRatio;
	NSString *selectedUnits = [unitsPopUp titleOfSelectedItem];
	float ratio = [[pointsPerUnit objectForKey:selectedUnits] floatValue];

	[oldUnitsField setStringValue:selectedUnits];
	[[leftMarginForm cellAtRow:0 column:0] setFloatValue:l / ratio];
	[[rightMarginForm cellAtRow:0 column:0] setFloatValue:r / ratio];
	[[topMarginForm cellAtRow:0 column:0] setFloatValue:t / ratio];
	[[bottomMarginForm cellAtRow:0 column:0] setFloatValue:b / ratio];
} */

@end
