//
//  DocumentInfoController.h
//  SketchyDraw
//
//  Created by 佐藤 昭 on 平成 20/08/08.
//  Copyright 2008 SatoAkira. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface DocumentInfoController : NSWindowController {
	IBOutlet NSForm *whereForm;
	IBOutlet NSForm *sizeForm;
	IBOutlet NSForm *modifiedForm;
	IBOutlet NSForm *papersizeForm;
	IBOutlet NSForm *orientationForm;
	IBOutlet NSForm *leftMarginForm;
	IBOutlet NSForm *topMarginForm;
	IBOutlet NSForm *bottomMarginForm;
	IBOutlet NSForm *rightMarginForm;
	IBOutlet NSTextField *marginTitleField;
	IBOutlet NSPopUpButton *unitsPopUp;
	IBOutlet NSTextField *oldUnitsField;
	IBOutlet NSForm *colorSpaceForm;
}

@end
