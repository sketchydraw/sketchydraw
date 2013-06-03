/*
     File: SKTZoomingScrollView.m
 Abstract: A controller to manage zooming of a Sketch graphics view.
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

#import "SKTZoomingScrollView.h"


// The name of the binding supported by this class, in addition to the ones whose support is inherited from NSView.
NSString *SKTZoomingScrollViewFactor = @"factor";

// Default labels and values for the menu items that will be in the popup button that we build.
static NSString * const SKTZoomingScrollViewLabels[] = {@"10%", @"25%", @"50%", @"75%", @"100%", @"125%", @"150%", @"200%", @"400%", @"800%", @"1600%"};
static const CGFloat SKTZoomingScrollViewFactors[] = {0.1f, 0.25f, 0.5f, 0.75f, 1.0f, 1.25f, 1.5f, 2.0f, 4.0f, 8.0f, 16.0f};
static const NSInteger SKTZoomingScrollViewPopUpButtonItemCount = sizeof(SKTZoomingScrollViewLabels) / sizeof(NSString *);

/* We're going to be passing SKTZoomingScrollViewLabels elements into NSLocalizedStringFromTable, but genstrings won't understand that. List the menu item labels in a way it will understand.
NSLocalizedStringFromTable(@"10%", @"SKTZoomingScrollView", @"A level of zooming in a view.")
NSLocalizedStringFromTable(@"25%", @"SKTZoomingScrollView", @"A level of zooming in a view.")
NSLocalizedStringFromTable(@"50%", @"SKTZoomingScrollView", @"A level of zooming in a view.")
NSLocalizedStringFromTable(@"75%", @"SKTZoomingScrollView", @"A level of zooming in a view.")
NSLocalizedStringFromTable(@"100%", @"SKTZoomingScrollView", @"A level of zooming in a view.")
NSLocalizedStringFromTable(@"125%", @"SKTZoomingScrollView", @"A level of zooming in a view.")
NSLocalizedStringFromTable(@"150%", @"SKTZoomingScrollView", @"A level of zooming in a view.")
NSLocalizedStringFromTable(@"200%", @"SKTZoomingScrollView", @"A level of zooming in a view.")
NSLocalizedStringFromTable(@"400%", @"SKTZoomingScrollView", @"A level of zooming in a view.")
NSLocalizedStringFromTable(@"800%", @"SKTZoomingScrollView", @"A level of zooming in a view.")
NSLocalizedStringFromTable(@"1600%", @"SKTZoomingScrollView", @"A level of zooming in a view.")
*/


@implementation SKTZoomingScrollView


- (void)validateFactorPopUpButton {

    // Ignore redundant invocations.
    if (!_factorPopUpButton) {

	// Create the popup button and configure its appearance. The initial size doesn't matter.
        _factorPopUpButton = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
	NSPopUpButtonCell *factorPopUpButtonCell = [_factorPopUpButton cell];
        [factorPopUpButtonCell setArrowPosition:NSPopUpArrowAtBottom];
        [factorPopUpButtonCell setBezelStyle:NSShadowlessSquareBezelStyle];
        [_factorPopUpButton setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];

        // Populate it and size it to fit the just-added menu item cells.
        for (NSInteger index = 0; index<SKTZoomingScrollViewPopUpButtonItemCount; index++) {
            [_factorPopUpButton addItemWithTitle:NSLocalizedStringFromTable(SKTZoomingScrollViewLabels[index], @"SKTZoomingScrollView", nil)];
            [[_factorPopUpButton itemAtIndex:index] setRepresentedObject:[NSNumber numberWithDouble:SKTZoomingScrollViewFactors[index]]];
        }
        [_factorPopUpButton sizeToFit];

	// Make it appear, and then release it right away, which is safe because -addSubview: retains it.
        [self addSubview:_factorPopUpButton];
	[_factorPopUpButton release];

    }
	/* if (nil == infoButton) {
		infoButton = [[NSButton allocWithZone:[self zone]] initWithFrame:NSMakeRect(0.0,0.0,64.0,12.0)];
		[infoButton setTitle:NSLocalizedStringFromTable(@"Show Info",@"SKTZoomingScrollView",@"情報を見る")];
		[infoButton setFont:[NSFont userFontOfSize:11.0]];
		[infoButton setBezelStyle:NSShadowlessSquareBezelStyle];
		[infoButton sizeToFit]; // ここで確保した幅がキープされる。高さは何でも良い。 //
		[self addSubview:infoButton];
		[infoButton release];
	} */
}


#pragma mark *** Bindings ***


- (void)setFactor:(CGFloat)factor {

    //The default implementation of key-value binding is informing this object that the value to which our "factor" property is bound has changed. Record the value, and apply the zoom factor by fooling with the bounds of the clip view that every scroll view has. (We leave its frame alone.)
    _factor = factor;
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ZoomingScrollViewFactorDidChange" object:self]; // SatoAkira add. //

    NSView *clipView = [[self documentView] superview];
    NSSize clipViewFrameSize = [clipView frame].size;
    [clipView setBoundsSize:NSMakeSize((clipViewFrameSize.width / factor), (clipViewFrameSize.height / factor))];
    
}


// An override of the NSObject(NSKeyValueBindingCreation) method.
- (void)bind:(NSString *)bindingName toObject:(id)observableObject withKeyPath:(NSString *)observableKeyPath options:(NSDictionary *)options {
    
    // For the one binding that this class recognizes, automatically bind the zoom factor popup button's value to the same object...
    if ([bindingName isEqualToString:SKTZoomingScrollViewFactor]) {
	[self validateFactorPopUpButton];
	[_factorPopUpButton bind:NSSelectedObjectBinding toObject:observableObject withKeyPath:observableKeyPath options:options];
    }

    // ...but still use NSObject's default implementation, which will send _this_ object -setFactor: messages (via key-value coding) whenever the bound-to value changes, for whatever reason, including the user changing it with the zoom factor popup button. Also, NSView supports a few simple bindings of its own, and there's no reason to get in the way of those.
    [super bind:bindingName toObject:observableObject withKeyPath:observableKeyPath options:options];
    
}


// An override of the NSObject(NSKeyValueBindingCreation) method.
- (void)unbind:(NSString *)bindingName {
    
    // Undo what we did in our override of -bind:toObject:withKeyPath:options:.
    [super unbind:bindingName];
    if ([bindingName isEqualToString:SKTZoomingScrollViewFactor]) {
	[_factorPopUpButton unbind:NSSelectedObjectBinding];
    }

}


#pragma mark *** View Customization ***


// An override of the NSScrollView method.
- (void)tile {

    // This class lives to put a popup button next to a horizontal scroll bar.
    NSAssert([self hasHorizontalScroller], @"SKTZoomingScrollView doesn't support use without a horizontal scroll bar.");

    // Do NSScrollView's regular tiling, and find out where it left the horizontal scroller.
    [super tile];
    NSScroller *horizontalScroller = [self horizontalScroller];
    NSRect horizontalScrollerFrame = [horizontalScroller frame];

    // Place the zoom factor popup button to the left of where the horizontal scroller will go, creating it first if necessary, and leaving its width alone.
    [self validateFactorPopUpButton];
    /* NSRect factorPopUpButtonFrame = [_factorPopUpButton frame];
    factorPopUpButtonFrame.origin.x = horizontalScrollerFrame.origin.x;
    factorPopUpButtonFrame.origin.y = horizontalScrollerFrame.origin.y;
    factorPopUpButtonFrame.size.height = horizontalScrollerFrame.size.height;
    [_factorPopUpButton setFrame:factorPopUpButtonFrame];

    // Adjust the scroller's frame to make room for the zoom factor popup button next to it.
    horizontalScrollerFrame.origin.x += factorPopUpButtonFrame.size.width;
    horizontalScrollerFrame.size.width -= factorPopUpButtonFrame.size.width;
    [horizontalScroller setFrame:horizontalScrollerFrame]; */ // SatoAkira delete. //
	// ↓SatoAkira add. //
	/* NSArray *horizontalOptions = [NSArray arrayWithObjects:_factorPopUpButton,infoButton,nil]; */ // NSArrayに付け加え、- (void)validateFactorPopUpButtonの中で有効化すると付け加えた分も使えるようになる。 //
	NSArray *horizontalOptions = [NSArray arrayWithObjects:_factorPopUpButton,nil];
    if (0 < [horizontalOptions count]) {
		NSRect optionRect;

		for (NSButton *button in horizontalOptions) {
			optionRect = [button frame];
			if (72 < NSWidth(horizontalScrollerFrame) - NSWidth(optionRect))
#ifdef __APPLE__
				NSDivideRect(horizontalScrollerFrame,&optionRect,&horizontalScrollerFrame,NSWidth(optionRect),NSMinXEdge);
#else
				NSDivideRect(horizontalScrollerFrame,&optionRect,&horizontalScrollerFrame,NSWidth(optionRect),NSMaxXEdge);
#endif
			else {
				optionRect.origin.x = -1000;
				optionRect.origin.y = -1000;
			}
			[button setFrame:optionRect];
		}
		[horizontalScroller setFrame:horizontalScrollerFrame];
	}
	NSArray *verticalOptions = [NSArray array];
	if (0 < [verticalOptions count]) {
		NSRect vOptionRect;
		NSScroller *vScroller = [self verticalScroller];
		NSRect vRect = [vScroller frame];

		for (NSButton *button in verticalOptions) {
			vOptionRect = [button frame];
			if (72 < NSHeight(vRect) - NSHeight(vOptionRect))
				NSDivideRect(vRect,&vOptionRect,&vRect,NSHeight(vOptionRect),NSMinYEdge);
			else {
				vOptionRect.origin.x = -1000;
				vOptionRect.origin.y = -1000;
			}
			[button setFrame:vOptionRect];
		}
		[vScroller setFrame:vRect];
	}
	// ↑SatoAkira add. //
}

@end
