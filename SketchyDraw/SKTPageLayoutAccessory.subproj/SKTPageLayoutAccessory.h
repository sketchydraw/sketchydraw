//
//  SKTPageLayoutAccessory.h
//  SketchyDraw
//
//  Created by 佐藤 昭 on 平成 20/08/30.
//  Copyright 2008 SatoAkira. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SKTPageLayoutAccessoryView.h"


@interface SKTPageLayoutAccessory : NSViewController
{
	@private
	IBOutlet NSBox *marginBox;
	IBOutlet NSForm *leftMarginForm;
	IBOutlet NSForm *rightMarginForm;
	IBOutlet NSForm *topMarginForm;
	IBOutlet NSForm *bottomMarginForm;
	IBOutlet NSPopUpButton *unitsPopUp;
	IBOutlet SKTPageLayoutAccessoryView *layoutView;
	IBOutlet NSButton *headerAndFooterSwitch;
	IBOutlet NSForm *imageableAreaOriginForm;
	IBOutlet NSForm *widthSpaceForm;
	IBOutlet NSForm *heightSpaceForm;
	CGFloat _leftMargin;
	CGFloat _rightMargin;
	CGFloat _topMargin;
	CGFloat _bottomMargin;
	BOOL _headerAndFooter;
	CGFloat _imageableAreaOriginX;
	CGFloat _imageableAreaOriginY;
	CGFloat _leftSpace;
	CGFloat _bottomSpace;
	CGFloat _rightSpace;
	CGFloat _topSpace;
}

- (IBAction)changeUnits:(id)sender;

@end
