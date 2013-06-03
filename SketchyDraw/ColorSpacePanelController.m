//
//  ColorSpacePanelController.m
//  SketchyDraw
//
//  Created by 佐藤 昭 on  06/12/06.
//  Copyright 2006 SatoAkira. All rights reserved.
//

#import "ColorSpacePanelController.h"
#import "SKTWindowController.h"


@implementation ColorSpacePanelController

+ (id)sharedColorSpacePanelController
{
    static ColorSpacePanelController *newInstance = nil;

    if (!newInstance)
        newInstance = [[ColorSpacePanelController allocWithZone:NULL] init];
    return newInstance;
}
- (id)init {
    self = [self initWithWindowNibName:@"ColorSpacePanel"];
    if (self) {
		NSColorSpace *aSpace,*tempColorSpace;
		NSString *iccProfile;
		BOOL found;
		NSFileManager *manager = [NSFileManager defaultManager];
		NSString *iccProfileDir = @"/System/Library/ColorSync";
		NSDirectoryEnumerator *enumerator = [manager enumeratorAtPath:iccProfileDir];

		colorProfiles = [[NSMutableArray allocWithZone:[self zone]] initWithCapacity:10];
		for (iccProfile in enumerator) {
			if (nil != (aSpace = [[NSColorSpace alloc] initWithICCProfileData:[NSData dataWithContentsOfFile:[iccProfileDir stringByAppendingPathComponent:iccProfile]]])) {
				found = NO;
				for (tempColorSpace in colorProfiles) {
					if (([aSpace colorSpaceModel] == [tempColorSpace colorSpaceModel]) && (YES == [[aSpace localizedName] isEqualToString:[tempColorSpace localizedName]])) {
						found = YES;
						break;
					}
				}
				if (NO == found)
					[colorProfiles addObject:aSpace];
				[aSpace release];
			}
			else
				NSLog(@"%@ aSpace is nil.",[iccProfileDir stringByAppendingPathComponent:iccProfile]);
		}
		iccProfileDir = @"/Library/ColorSync";
		enumerator = [manager enumeratorAtPath:iccProfileDir];
		for (iccProfile in enumerator) {
			if (nil != (aSpace = [[NSColorSpace alloc] initWithICCProfileData:[NSData dataWithContentsOfFile:[iccProfileDir stringByAppendingPathComponent:iccProfile]]])) {
				found = NO;
				for (tempColorSpace in colorProfiles) {
					if (([aSpace colorSpaceModel] == [tempColorSpace colorSpaceModel]) && (YES == [[aSpace localizedName] isEqualToString:[tempColorSpace localizedName]])) {
						found = YES;
						break;
					}
				}
				if (NO == found)
					[colorProfiles addObject:aSpace];
				[aSpace release];
			}
			else
				NSLog(@"%@ aSpace is nil.",[iccProfileDir stringByAppendingPathComponent:iccProfile]);
		}
		iccProfileDir = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/ColorSync"];
		enumerator = [manager enumeratorAtPath:iccProfileDir];
		for (iccProfile in enumerator) {
			if (nil != (aSpace = [[NSColorSpace alloc] initWithICCProfileData:[NSData dataWithContentsOfFile:[iccProfileDir stringByAppendingPathComponent:iccProfile]]])) {
				found = NO;
				for (tempColorSpace in colorProfiles) {
					if (([aSpace colorSpaceModel] == [tempColorSpace colorSpaceModel]) && (YES == [[aSpace localizedName] isEqualToString:[tempColorSpace localizedName]])) {
						break;
					}
				}
				if (NO == found)
					[colorProfiles addObject:aSpace];
				[aSpace release];
			}
			else
				NSLog(@"%@ aSpace is nil.",[iccProfileDir stringByAppendingPathComponent:iccProfile]);
		}
		[self setWindowFrameAutosaveName:@"ColorSpace"];
    }
    return self;
}
- (NSArray *)colorProfiles {
	return colorProfiles;
}
- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[colorProfiles release];
	[super dealloc];
}
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_4
- (NSString *)colorSpaceModelString:(NSColorSpaceModel)model
{
	NSString *modelStr;

	switch (model) {
	case NSUnknownColorSpaceModel:
		modelStr = @"UnknownColorSpaceModel";
		break;
	case NSGrayColorSpaceModel:
		modelStr = @"GrayColorSpaceModel";
		break;
	case NSRGBColorSpaceModel:
		modelStr = @"RGBColorSpaceModel";
		break;
	case NSCMYKColorSpaceModel:
		modelStr = @"CMYKColorSpaceModel";
		break;
	case NSLABColorSpaceModel:
		modelStr = @"LABColorSpaceModel";
		break;
	case NSDeviceNColorSpaceModel:
		modelStr = @"DeviceNColorSpaceModel";
		break;
	default:
		modelStr = @"UnknownColorSpaceModel";
		break;
	}
	return modelStr;
}
#endif
- (void)setMainWindow:(NSWindow *)mainWindow
{
	if (nil != mainWindow) {
		NSWindowController *controller = [mainWindow windowController];

		if ((nil != controller) && (YES == [controller isKindOfClass:[SKTWindowController class]])) {
			NSUInteger i;

			sktDocument = [controller document];
			NSColorSpace *tempColorSpace, *aSpace = [sktDocument valueForKey:SKTColorSpaceKey];
			[[selectedProfileForm cellAtRow:0 column:0] setStringValue:[NSString stringWithFormat:@"%@ %@ [%ld]",[aSpace localizedName],[self colorSpaceModelString:[aSpace colorSpaceModel]],[aSpace numberOfColorComponents]]];
			for (i = 0; i < [colorProfiles count]; i++) {
				tempColorSpace = [colorProfiles objectAtIndex:i];
				if (([aSpace colorSpaceModel] == [tempColorSpace colorSpaceModel]) && (YES == [[aSpace localizedName] isEqualToString:[tempColorSpace localizedName]])) {
					[profilesTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:i] byExtendingSelection:NO];
					[profilesTableView scrollRowToVisible:i];
					break;
				}
			}
			if (i >= [colorProfiles count]) {
				[selectedProfileForm setBackgroundColor:[NSColor redColor]];
				[selectedProfileForm setDrawsBackground:YES];
			}
			else
				[selectedProfileForm setDrawsBackground:NO];
		}
		else {
			[[selectedProfileForm cellAtRow:0 column:0] setStringValue:@""];
			[profilesTableView deselectAll:nil];
			sktDocument = nil;
		}
	}
	else {
		[[selectedProfileForm cellAtRow:0 column:0] setStringValue:@""];
		[profilesTableView deselectAll:nil];
		sktDocument = nil;
	}
}
- (void)windowDidLoad
{
	NSArray *tc = [profilesTableView tableColumns];

	[[tc objectAtIndex:0] setIdentifier:@"LocalizedName"];
	[[tc objectAtIndex:1] setIdentifier:@"ColorSpaceModel"];
	[[tc objectAtIndex:2] setIdentifier:@"NumberOfColorComponents"];
	[[[tc objectAtIndex:0] headerCell] setStringValue:NSLocalizedString(@"LocalizedName",@"")];
	[[[tc objectAtIndex:1] headerCell] setStringValue:NSLocalizedString(@"ColorSpaceModel",@"")];
	[[[tc objectAtIndex:2] headerCell] setStringValue:NSLocalizedString(@"NumberOfColorComponents",@"")];
	[[[tc objectAtIndex:0] dataCell] setDrawsBackground:NO];
	[[[tc objectAtIndex:1] dataCell] setDrawsBackground:NO];
	[[[tc objectAtIndex:2] dataCell] setDrawsBackground:NO];
	[profilesTableView setGridColor:[NSColor gridColor]];
	[profilesTableView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleSourceList];
	[profilesTableView setGridStyleMask:NSTableViewSolidVerticalGridLineMask];
	[profilesTableView setUsesAlternatingRowBackgroundColors:YES];
	[profilesTableView setDelegate:self]; // for tableViewSelectionDidChange: //
	[profilesTableView setDataSource:self];
	[[selectedProfileForm cellAtRow:0 column:0] setTitle:NSLocalizedString(@"ColorSpace",@"")];
	[selectedProfileForm calcSize];
    [(NSPanel *)[self window] setFloatingPanel:YES];
	[self setMainWindow:[NSApp mainWindow]];
	[[self window] setTitle:NSLocalizedString(@"ColorSpace",@"")];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mainWindowChanged:) name:NSWindowDidBecomeMainNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mainWindowResigned:) name:NSWindowDidResignMainNotification object:nil];
}
- (void)windowWillClose:(NSNotification *)aNotification
{
	[profilesTableView deselectAll:nil];
}

- (void)mainWindowChanged:(NSNotification *)notification {
    [self setMainWindow:[notification object]]; // NSStringFromClass([[notification object] class]) はNSWindow //
}

- (void)mainWindowResigned:(NSNotification *)notification {
    [self setMainWindow:nil];
}
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
	return (nil != colorProfiles) ? (NSInteger)[colorProfiles count] : 0;
}
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_4
	if (nil != colorProfiles) {
		NSParameterAssert(rowIndex >= 0 && rowIndex < (NSInteger)[colorProfiles count]);
		NSString *identifier = [aTableColumn identifier];
		if (YES == [identifier isEqualToString:@"LocalizedName"])
			return [[colorProfiles objectAtIndex:(NSUInteger)rowIndex] localizedName];
		else {
			if (YES == [identifier isEqualToString:@"ColorSpaceModel"])
				return [self colorSpaceModelString:[[colorProfiles objectAtIndex:(NSUInteger)rowIndex] colorSpaceModel]];
			else
				return [NSNumber numberWithInt:[[colorProfiles objectAtIndex:(NSUInteger)rowIndex] numberOfColorComponents]];
		}
	}
	else
		return nil;
#else
	return nil;
#endif
}
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	NSInteger row = [[aNotification object] selectedRow];

	if (0 <= row) {
		if (nil != sktDocument) {
			NSColorSpace *oldSpace = [sktDocument valueForKey:SKTColorSpaceKey];
			NSColorSpace *aSpace = [colorProfiles objectAtIndex:(NSUInteger)row];
			if (NO == [[oldSpace localizedName] isEqualToString:[aSpace localizedName]]) {
				[sktDocument setValue:aSpace forKey:SKTColorSpaceKey];
				[[selectedProfileForm cellAtRow:0 column:0] setStringValue:[NSString stringWithFormat:@"%@ %@ [%ld]",[aSpace localizedName],[self colorSpaceModelString:[aSpace colorSpaceModel]],[aSpace numberOfColorComponents]]];
			}
		}
	}
}
- (IBAction)showHelp:(id)sender
{
	NSString *locBookName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleHelpBookName"];
	[[NSHelpManager sharedHelpManager] openHelpAnchor:@"Window_ColorSpace" inBook:locBookName];
}

@end
