//
//  ColorSpacePanelController.h
//  SketchyDraw
//
//  Created by 佐藤 昭 on  06/12/06.
//  Copyright 2006 SatoAkira. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SKTDocument.h"

@interface ColorSpacePanelController : NSWindowController <NSTableViewDataSource,NSTableViewDelegate>
{
    @private
	IBOutlet NSForm *selectedProfileForm;
	IBOutlet NSTableView *profilesTableView;
	NSMutableArray *colorProfiles;
	SKTDocument *sktDocument;
}

+ (id)sharedColorSpacePanelController;
- (NSArray *)colorProfiles;

@end
