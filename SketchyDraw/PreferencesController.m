//
//  PreferencesController.m
//  Sketch
//
//  Created by me on Tue May 01 2001.
//  Copyright (c) 2001 SatoAkira. All rights reserved.
//

#import "PreferencesController.h"
#import "ColorSpacePanelController.h"
#import "SKTPageLayoutAccessory.h"

NSString *SKTBackgroundColorDidChangeNotification = @"SKTBackgroundColorDidChangeNotification";
NSString *SKTUseBackgroundColorDidChangeNotification = @"SKTUseBackgroundColorDidChangeNotification";
NSString *SKTKnobColorDidChangeNotification = @"SKTKnobColorDidChangeNotification";
NSString *SKTMeasurementUnitDidChangeNotification = @"SKTMeasurementUnitDidChangeNotification";

NSString *BackgroundColorKey = @"BackgroundColor";
NSString *UseBackgroundColorKey = @"UseBackgroundColor";
NSString *AntialiasKey = @"Antialias";
NSString *ImageInterpolationKey = @"ImageInterpolation";
NSString *MeasurementUnitKey = @"MeasurementUnit";
NSString *PointsPerUnitKey = @"PointsPerUnit";
NSString *TIFFCompressionKey = @"TIFFCompression";
NSString *TIFFColorSpaceKey = @"TIFFColorSpace";
NSString *TIFFResolutionKey = @"TIFFResolution";
NSString *ColorSpaceKey = @"ColorSpace";
NSString *DefaultFontDescriptorKey = @"DefaultFontDescriptor";
NSString *DefaultPageLayoutKey = @"DefaultPageLayout";
NSString *KnobColorKey = @"KnobColor";


static NSDictionary *defaultValues()
{
    static NSDictionary *dict = nil;

    if (nil == dict) {
		NSPrintInfo *tempPrintInfo = [[NSPrintInfo sharedPrintInfo] copy];
		NSSize dSize = [tempPrintInfo paperSize];
		NSFont *dFont = [NSFont userFixedPitchFontOfSize:12.0];
		NSFontDescriptor *fontDesc = [dFont fontDescriptor];
		NSMutableDictionary *fontDic = [NSMutableDictionary dictionaryWithDictionary:[fontDesc fontAttributes]];

		[tempPrintInfo setPaperSize:dSize]; // sharedPrintInfoにはpaperNameが設定されていない。また、プリンタ名も設定されていない。setPaperSizeをやると、paperNameとプリンタ名が設定される。 //
		NSRect imageable = [tempPrintInfo imageablePageBounds]; // setPaperSize:の後にやらないと機種毎に異なるrectを取得できない。Mac OS X 10.7 からimageablePageBoundsに影響を受けるようになった。 //
		dSize = [tempPrintInfo paperSize];
		[tempPrintInfo setLeftMargin:NSMinX(imageable)]; // sharedPrintInfoのデフォルト値は上下90.0、左右72.0ポイントである。 //
		[tempPrintInfo setTopMargin:dSize.height - NSMaxY(imageable)];
		[tempPrintInfo setRightMargin:dSize.width - NSMaxX(imageable)];
		[tempPrintInfo setBottomMargin:NSMinY(imageable)];
		[tempPrintInfo setHorizontallyCentered:NO];
		[tempPrintInfo setVerticallyCentered:NO];
		[fontDic setObject:[NSArchiver archivedDataWithRootObject:[NSColor blackColor]] forKey:NSForegroundColorAttributeName];
		[fontDic setObject:[fontDesc postscriptName] forKey:NSFontNameAttribute];
		[fontDic setObject:[NSString stringWithFormat:@"%g",[fontDesc pointSize]] forKey:NSFontSizeAttribute];

		NSColorSpace *colorSpace = [[NSColorSpace alloc] initWithICCProfileData:[NSData dataWithContentsOfFile:@"/System/Library/ColorSync/Profiles/sRGB Profile.icc"]];
		if (nil == colorSpace)
			colorSpace = [[NSColorSpace genericRGBColorSpace] retain];

        dict = [[NSDictionary alloc] initWithObjectsAndKeys:[NSColor textBackgroundColor],BackgroundColorKey,fontDic,DefaultFontDescriptorKey,tempPrintInfo,DefaultPageLayoutKey,colorSpace,ColorSpaceKey, [NSNumber numberWithInt:NSTIFFCompressionNone],TIFFCompressionKey,[NSNumber numberWithInt:SKTTIFFDocument],TIFFColorSpaceKey,[NSNumber numberWithFloat:72.0],TIFFResolutionKey, [NSNumber numberWithInt:NSOnState],UseBackgroundColorKey, [NSColor selectedKnobColor],KnobColorKey, nil];
		[colorSpace release];
		[tempPrintInfo release];
    }
    return dict;
}

@implementation PreferencesController

+ (id)objectForKey:(id)key { // 使わないようにすべし //
    return [[[self sharedPreferencesController] preferences] objectForKey:key];
}

+ (PreferencesController *)sharedPreferencesController
{
    static PreferencesController *sharedPreferencesController = nil;

    if (nil == sharedPreferencesController) {
        sharedPreferencesController = [[PreferencesController allocWithZone:NULL] init];
    }
    return sharedPreferencesController;
}

- (void)setMeasurementUnit:(NSString *)muStr
{
	NSDictionary *pointsPerUnitDic = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:2.835],@"mm",[NSNumber numberWithDouble:72.0],@"inch",[NSNumber numberWithDouble:12.0],@"pica",[NSNumber numberWithDouble:1.0],@"point",nil];

	[[NSUserDefaults standardUserDefaults] setObject:[pointsPerUnitDic objectForKey:muStr] forKey:PointsPerUnitKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:SKTMeasurementUnitDidChangeNotification object:self];
}
- (id)init
{
    if (nil != (self = [self initWithWindowNibName:@"Preferences"])) {
		NSUserDefaultsController *userDefaultsController = [NSUserDefaultsController sharedUserDefaultsController];
		BOOL usesMetric = [[[NSLocale currentLocale] objectForKey:NSLocaleUsesMetricSystem
] boolValue];
		NSString *defaultUnit = (YES == usesMetric) ? @"Metric" : [[NSLocale currentLocale] objectForKey:NSLocaleMeasurementSystem
]; // U.S.,Picas,Metric //
		NSDictionary *pointsPerUnitDic = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:2.835],@"mm",[NSNumber numberWithDouble:72.0],@"inch",[NSNumber numberWithDouble:12.0],@"pica",[NSNumber numberWithDouble:1.0],@"point",nil];
		NSString *defaultMeasurement;
		NSNumber *defaultPointsPerUnit;

		if (YES == [defaultUnit isEqualToString:@"Metric"])
			defaultMeasurement = @"mm";
		else {
			if (YES == [defaultUnit isEqualToString:@"U.S."])
				defaultMeasurement = @"inch";
			else {
				if (YES == [defaultUnit isEqualToString:@"Picas"])
					defaultMeasurement = @"pica";
				else
					defaultMeasurement = @"point";
			}
		}
		defaultPointsPerUnit = [pointsPerUnitDic objectForKey:defaultMeasurement];
		[userDefaultsController setInitialValues:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],AntialiasKey, [NSNumber numberWithBool:NO],ImageInterpolationKey, defaultMeasurement,MeasurementUnitKey, defaultPointsPerUnit,PointsPerUnitKey, [NSNumber numberWithBool:YES],UseBackgroundColorKey,  nil]];
		[self bind:MeasurementUnitKey toObject:userDefaultsController withKeyPath:[@"values." stringByAppendingString:MeasurementUnitKey] options:nil]; // としなければsetMeasurementUnit:(NSString *) が呼ばれない。PointsPerUnitsを設定する為にその呼び出しが必要になる。 //
		curValues = [[NSMutableDictionary alloc] initWithDictionary:[[self class] preferencesFromDefaults]];
		[self setWindowFrameAutosaveName:@"Preferences"];
	}
	else
		NSLog(@"PreferencesController couldn't init.");
    return self;
}

- (void)dealloc
{
	[curValues release];
	[super dealloc];
}

- (void)windowDidLoad
{
	NSString *message;
	NSPrintInfo *printInfo = [curValues objectForKey:DefaultPageLayoutKey];
	NSPrintingOrientation ori = [printInfo orientation];
	NSDictionary *fontDict = [curValues objectForKey:DefaultFontDescriptorKey];
	NSFont *font = [NSFont fontWithName:[fontDict objectForKey:NSFontNameAttribute] size:[[fontDict objectForKey:NSFontSizeAttribute] floatValue]];
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_4
	NSColor *fontColor = (nil != [fontDict objectForKey:NSForegroundColorAttributeName]) ? [NSUnarchiver unarchiveObjectWithData:[fontDict objectForKey:NSForegroundColorAttributeName]] : [NSColor blackColor];
	NSColorSpace *tempColorSpace, *colorSpace = [curValues objectForKey:ColorSpaceKey];
#elif MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_3
	NSColor *fontColor = (nil != [fontDict objectForKey:NSFontColorAttribute]) ? [NSUnarchiver unarchiveObjectWithData:[fontDict objectForKey:NSFontColorAttribute]] : [NSColor blackColor];
#else
	NSColor *fontColor = [NSColor blackColor];
#endif

	[super windowDidLoad];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[antialiasSwitch setState:(YES == [[defaults objectForKey:AntialiasKey] boolValue]) ? NSOnState : NSOffState];
	[imageInterpolationSwitch setState:(YES == [[defaults objectForKey:ImageInterpolationKey] boolValue]) ? NSOnState : NSOffState]; // bindでやると、クラッシュしてしまう。 //
	[[tabView tabViewItemAtIndex:0] setLabel:NSLocalizedString(@"General",@"")];
	[[tabView tabViewItemAtIndex:1] setLabel:NSLocalizedString(@"Defaults",@"")];
	[antialiasSwitch setTitle:NSLocalizedString(AntialiasKey,@"")];
	[imageInterpolationSwitch setTitle:NSLocalizedString(@"HighQualityImageOnScreen",@"")];
	[backgroundColorSwitch setTitle:NSLocalizedString(BackgroundColorKey,@"")];
	[backgroundColorWell setColor:(nil != [curValues objectForKey:BackgroundColorKey]) ? [curValues objectForKey:BackgroundColorKey] : [defaultValues() objectForKey:BackgroundColorKey]];
	[backgroundColorSwitch setState:(nil != [curValues objectForKey:UseBackgroundColorKey]) ? [[curValues objectForKey:UseBackgroundColorKey] intValue] : [[defaultValues() objectForKey:UseBackgroundColorKey] intValue]];
	[knobColorTitle setStringValue:NSLocalizedString(@"KnobColor",@"")];
	[knobColorWell setColor:(nil != [curValues objectForKey:KnobColorKey]) ? [curValues objectForKey:KnobColorKey] : [defaultValues() objectForKey:KnobColorKey]];
	[revertBackgroundColorButton setTitle:NSLocalizedString(@"Revert to Default Settings",@"")];
	[revertKnobColorButton setTitle:NSLocalizedString(@"Revert to Default Settings",@"")];
	[textFontTitle setStringValue:NSLocalizedString(@"DefaultTextFont",@"")];
	[setTextFontButton setTitle:[NSString stringWithFormat:@"%@...",NSLocalizedString(@"Set",@"")]];
	[fontColorWell setColor:fontColor];
	[[textFontContents cell] setFont:font];
	[[textFontContents cell] setTextColor:fontColor];
	[textFontContents setStringValue:[NSString stringWithFormat:@"%@ (%@) %0.1f%@",[font displayName],[fontDict objectForKey:NSFontNameAttribute],[[fontDict objectForKey:NSFontSizeAttribute] floatValue],NSLocalizedString(@"Point",@"")]];
	[pageLayoutDescriptionView setString:[printInfo description]];
	switch (ori) {
	case NSPortraitOrientation:
		message = NSLocalizedString(@"PortraitOrientation",@"");
		break;
	case NSLandscapeOrientation:
		message = NSLocalizedString(@"LandscapeOrientation",@"");
		break;
	default:
		message = NSLocalizedString(@"PortraitOrientation",@"");
		NSLog(@"ori=%ld",ori);
		break;
	}
	[pageLayoutContents setStringValue:[NSString stringWithFormat:@"%@ %@ %@",[printInfo paperName],message,[[printInfo printer] name]]];
	[pageLayoutTitle setStringValue:NSLocalizedString(DefaultPageLayoutKey,@"")];
	[setPageLayoutButton setTitle:[NSString stringWithFormat:@"%@...",NSLocalizedString(@"Set",@"")]];
	[measurementUnitTitle setStringValue:NSLocalizedString(MeasurementUnitKey,@"")]; // measurementUnitPopUpのtitleはIBで、"point","mm","inch","pica"にしておかなければならない。"Selected Value"でbindしておかなければならない。 "Selected Value"なので順番はどうでも良い。どうせLocalizedできないので此の方法で良い。"Selected Value"なのでsetMeasurementUnit:にはNSStringが渡される。 //
	[tiffOptionsBox setTitle:NSLocalizedString(@"SaveToTIFF options",@"TIFF書き出しオプション")];
	[tiffCompressionPopUp removeAllItems];
	[tiffCompressionPopUp addItemWithTitle:[NSBitmapImageRep localizedNameForTIFFCompressionType:NSTIFFCompressionNone]];
	[tiffCompressionPopUp addItemWithTitle:[NSBitmapImageRep localizedNameForTIFFCompressionType:NSTIFFCompressionLZW]];
	[tiffCompressionPopUp addItemWithTitle:[NSBitmapImageRep localizedNameForTIFFCompressionType:NSTIFFCompressionPackBits]];
	[tiffCompressionPopUp addItemWithTitle:[NSBitmapImageRep localizedNameForTIFFCompressionType:NSTIFFCompressionCCITTFAX3]]; // 白黒2値を強制的に選択 //
	[tiffCompressionPopUp addItemWithTitle:[NSBitmapImageRep localizedNameForTIFFCompressionType:NSTIFFCompressionCCITTFAX4]]; // 白黒2値を強制的に選択 //
	[[tiffCompressionPopUp itemAtIndex:0] setTag:NSTIFFCompressionNone];
	[[tiffCompressionPopUp itemAtIndex:1] setTag:NSTIFFCompressionLZW];
	[[tiffCompressionPopUp itemAtIndex:2] setTag:NSTIFFCompressionPackBits];
	[[tiffCompressionPopUp itemAtIndex:3] setTag:NSTIFFCompressionCCITTFAX3];
	[[tiffCompressionPopUp itemAtIndex:4] setTag:NSTIFFCompressionCCITTFAX4];
	[tiffCompressionPopUp selectItemWithTag:(nil != [curValues objectForKey:TIFFCompressionKey]) ? [[curValues objectForKey:TIFFCompressionKey] intValue] : [[defaultValues() objectForKey:TIFFCompressionKey] intValue]];
	[tiffColorSpacePopUp removeAllItems];
	/* [tiffColorSpacePopUp addItemWithTitle:[[NSColorSpace genericRGBColorSpace] localizedName]]; */
	[tiffColorSpacePopUp addItemWithTitle:NSLocalizedString(@"Colorspace of document",@"ドキュメントのカラースペース")];
	[tiffColorSpacePopUp addItemWithTitle:NSLocalizedString(@"Gray scale",@"グレイスケール")];
	[tiffColorSpacePopUp addItemWithTitle:NSLocalizedString(@"1-bit fax image",@"白黒2値")];
	/* [[tiffColorSpacePopUp itemAtIndex:0] setTag:SKTTIFFGenericRGB]; */
	[[tiffColorSpacePopUp itemAtIndex:0] setTag:SKTTIFFDocument];
	[[tiffColorSpacePopUp itemAtIndex:1] setTag:SKTTIFFGrayscale];
	[[tiffColorSpacePopUp itemAtIndex:2] setTag:SKTTIFFMonochrome];
	[tiffColorSpacePopUp selectItemWithTag:(nil != [curValues objectForKey:TIFFColorSpaceKey]) ? [[curValues objectForKey:TIFFColorSpaceKey] intValue] : [[defaultValues() objectForKey:TIFFResolutionKey] intValue]];
	if ((NSTIFFCompressionCCITTFAX3 == [tiffCompressionPopUp selectedTag]) || (NSTIFFCompressionCCITTFAX4 == [tiffCompressionPopUp selectedTag]))
		[tiffColorSpacePopUp setEnabled:NO];
	else
		[tiffColorSpacePopUp setEnabled:YES];
	[tiffResolutionCombo removeAllItems];
	[tiffResolutionCombo addItemsWithObjectValues:[NSArray arrayWithObjects:[NSNumber numberWithFloat:72.0],[NSNumber numberWithFloat:90.0],[NSNumber numberWithFloat:180.0],[NSNumber numberWithFloat:300.0],[NSNumber numberWithFloat:400.0],[NSNumber numberWithFloat:600.0],[NSNumber numberWithFloat:1200.0],[NSNumber numberWithFloat:2400.0],nil]];
	[tiffResolutionCombo setObjectValue:(nil != [curValues objectForKey:TIFFResolutionKey]) ? [curValues objectForKey:TIFFResolutionKey] : [defaultValues() objectForKey:TIFFResolutionKey]];
	
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_4
	ColorSpacePanelController *colorP = [ColorSpacePanelController sharedColorSpacePanelController];
	NSArray *tc = [profilesTableView tableColumns];
	[selectedProfileField setStringValue:[NSString stringWithFormat:@"%@ [%ld]",[colorSpace localizedName],[colorSpace numberOfColorComponents]]];
	[[tc objectAtIndex:0] setIdentifier:@"LocalizedName"];
	[[tc objectAtIndex:1] setIdentifier:@"NumberOfColorComponents"];
	[[[tc objectAtIndex:0] headerCell] setStringValue:NSLocalizedString(@"LocalizedName",@"")];
	[[[tc objectAtIndex:1] headerCell] setStringValue:NSLocalizedString(@"NumberOfColorComponents",@"")];
	[[[tc objectAtIndex:0] dataCell] setDrawsBackground:NO];
	[[[tc objectAtIndex:1] dataCell] setDrawsBackground:NO];
	[profilesTableView setGridColor:[NSColor gridColor]];
	[profilesTableView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleSourceList];
	[profilesTableView setGridStyleMask:NSTableViewSolidVerticalGridLineMask];
	[profilesTableView setUsesAlternatingRowBackgroundColors:YES];
	[profilesTableView setDataSource:colorP];
	NSUInteger i;
	NSArray *colorProfiles = [colorP colorProfiles];
	for (i = 0; i < [colorProfiles count]; i++) {
		tempColorSpace = [colorProfiles objectAtIndex:i];
		if (([colorSpace colorSpaceModel] == [tempColorSpace colorSpaceModel]) && (YES == [[colorSpace localizedName] isEqualToString:[tempColorSpace localizedName]])) {
			break;
		}
	}
	if (i < [colorProfiles count]) {
		[profilesTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:i] byExtendingSelection:NO];
		[profilesTableView scrollRowToVisible:i];
	}
	[profilesTableView setDelegate:self]; // for tableViewSelectionDidChange: //
#else
	colorProfiles = nil;
	[selectedProfileField setStringValue:@""];
#endif
	[[self window] setTitle:NSLocalizedString(@"Preferences",@"")];
	[[self window] setDelegate:self]; // for windowDidResignMain: //
}
- (void)windowWillClose:(NSNotification *)aNotification
{
	[profilesTableView deselectAll:nil];
}
- (void)windowDidResignMain:(NSNotification *)aNotification {
	[self tiffResolutionChanged:tiffResolutionCombo];
}

- (NSDictionary *)preferences {
   return curValues;
}

+ (NSDictionary *)preferencesFromDefaults
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:10];

	[dict setObject:(nil != [defaults objectForKey:BackgroundColorKey]) ? [NSUnarchiver unarchiveObjectWithData:[defaults objectForKey:BackgroundColorKey]] : [defaultValues() objectForKey:BackgroundColorKey] forKey:BackgroundColorKey];
	[dict setObject:(nil != [defaults objectForKey:UseBackgroundColorKey]) ? [defaults objectForKey:UseBackgroundColorKey] : [defaultValues() objectForKey:UseBackgroundColorKey] forKey:UseBackgroundColorKey];
	[dict setObject:(nil != [defaults objectForKey:KnobColorKey]) ? [NSUnarchiver unarchiveObjectWithData:[defaults objectForKey:KnobColorKey]] : [defaultValues() objectForKey:KnobColorKey] forKey:KnobColorKey];
	[dict setObject:(nil != [defaults objectForKey:DefaultPageLayoutKey]) ? [NSUnarchiver unarchiveObjectWithData:[defaults objectForKey:DefaultPageLayoutKey]] : [defaultValues() objectForKey:DefaultPageLayoutKey] forKey:DefaultPageLayoutKey];
	[dict setObject:(nil != [defaults objectForKey:DefaultFontDescriptorKey]) ? [NSDictionary dictionaryWithDictionary:[defaults objectForKey:DefaultFontDescriptorKey]] : [defaultValues() objectForKey:DefaultFontDescriptorKey] forKey:DefaultFontDescriptorKey];
	[dict setObject:(nil != [defaults objectForKey:ColorSpaceKey]) ? [NSUnarchiver unarchiveObjectWithData:[defaults objectForKey:ColorSpaceKey]] : [defaultValues() objectForKey:ColorSpaceKey] forKey:ColorSpaceKey];
	[dict setObject:(nil != [defaults objectForKey:TIFFCompressionKey]) ? [defaults objectForKey:TIFFCompressionKey] : [defaultValues() objectForKey:TIFFCompressionKey] forKey:TIFFCompressionKey];
	[dict setObject:(nil != [defaults objectForKey:TIFFColorSpaceKey]) ? [defaults objectForKey:TIFFColorSpaceKey] : [defaultValues() objectForKey:TIFFColorSpaceKey] forKey:TIFFColorSpaceKey];
	[dict setObject:(nil != [defaults objectForKey:TIFFResolutionKey]) ? [defaults objectForKey:TIFFResolutionKey] : [defaultValues() objectForKey:TIFFResolutionKey] forKey:TIFFResolutionKey];
	return dict;
}

- (IBAction)backgroundColorChanged:(id)sender
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSColor *newColor = [sender color];

	[defaults setObject:[NSArchiver archivedDataWithRootObject:newColor] forKey:BackgroundColorKey];
	[curValues setObject:newColor forKey:BackgroundColorKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:SKTBackgroundColorDidChangeNotification object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:[backgroundColorSwitch state]],UseBackgroundColorKey,newColor,BackgroundColorKey, nil]];
}
- (IBAction)useBackgroundColor:(id)sender
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:[NSNumber numberWithInt:[sender state]] forKey:UseBackgroundColorKey];
	[curValues setObject:[NSNumber numberWithInt:[sender state]] forKey:UseBackgroundColorKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:SKTUseBackgroundColorDidChangeNotification object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:NSMixedState],UseBackgroundColorKey,[backgroundColorWell color],BackgroundColorKey, nil]]; // windowの初期化をさせる為にNSMixedStateを送る。 //
}

- (IBAction)knobColorChanged:(id)sender
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSColor *newColor = [sender color];

	[defaults setObject:[NSArchiver archivedDataWithRootObject:newColor] forKey:KnobColorKey];
	[curValues setObject:newColor forKey:KnobColorKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:SKTKnobColorDidChangeNotification object:self];
}
- (IBAction)antialiasChanged:(id)sender
// postNotificationしてやらせることは、knobColorChanged:と同じなのでnotificationNameは同じにしてしまう。 //
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	BOOL flag = (NSOnState == [sender state]) ? YES : NO;
	
	[defaults setBool:flag forKey:AntialiasKey];
	[curValues setObject:[NSNumber numberWithBool:flag] forKey:AntialiasKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:SKTKnobColorDidChangeNotification object:self];
}
- (IBAction)imageInterpolationChanged:(id)sender
// postNotificationしてやらせることは、knobColorChanged:と同じなのでnotificationNameは同じにしてしまう。 //
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	BOOL flag = (NSOnState == [sender state]) ? YES : NO;
	
	[defaults setBool:flag forKey:ImageInterpolationKey];
	[curValues setObject:[NSNumber numberWithBool:flag] forKey:ImageInterpolationKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:SKTKnobColorDidChangeNotification object:self];
}

- (IBAction)revertBackgroundColor:(id)sender
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	[defaults setObject:[NSArchiver archivedDataWithRootObject:[defaultValues() objectForKey:BackgroundColorKey]] forKey:BackgroundColorKey];
	[curValues setObject:[defaultValues() objectForKey:BackgroundColorKey] forKey:BackgroundColorKey];
	[backgroundColorWell setColor:[defaultValues() objectForKey:BackgroundColorKey]];
	[[NSNotificationCenter defaultCenter] postNotificationName:SKTBackgroundColorDidChangeNotification object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:[backgroundColorSwitch state]],UseBackgroundColorKey,[defaultValues() objectForKey:BackgroundColorKey],BackgroundColorKey, nil]];
}

- (IBAction)revertKnobColor:(id)sender
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	[defaults setObject:[NSArchiver archivedDataWithRootObject:[defaultValues() objectForKey:KnobColorKey]] forKey:KnobColorKey];
	[curValues setObject:[defaultValues() objectForKey:KnobColorKey] forKey:KnobColorKey];
	[knobColorWell setColor:[defaultValues() objectForKey:KnobColorKey]];
	[[NSNotificationCenter defaultCenter] postNotificationName:SKTKnobColorDidChangeNotification object:self];
}

- (IBAction)runPageLayout:(id)sender
{
	NSPrintInfo *tempPrintInfo = [[curValues objectForKey:DefaultPageLayoutKey] copy];
	NSPageLayout *pageLayout = [NSPageLayout pageLayout];
	SKTPageLayoutAccessory *accessory = [[SKTPageLayoutAccessory alloc] initWithNibName:@"SKTPageLayoutAccessory" bundle:[NSBundle bundleForClass:[SKTPageLayoutAccessory class]]];
#ifdef WIN32
	float lm = [tempPrintInfo leftMargin] * 2.540000;
	float rm = [tempPrintInfo rightMargin] * 2.540000;
	float tm = [tempPrintInfo topMargin] * 2.540000;
	float bm = [tempPrintInfo bottomMargin] * 2.540000;

	[tempPrintInfo setLeftMargin:lm];
	[tempPrintInfo setRightMargin:rm];
	[tempPrintInfo setTopMargin:tm];
	[tempPrintInfo setBottomMargin:bm];
#endif
	[pageLayout addAccessoryController:accessory];
	[accessory release];
	[pageLayout beginSheetWithPrintInfo:tempPrintInfo modalForWindow:[self window] delegate:self didEndSelector:@selector(pageLayoutDidEnd:returnCode:contextInfo:) contextInfo:NULL];
	[tempPrintInfo release];
}
- (void)pageLayoutDidEnd:(NSPageLayout *)pageLayout returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	NSPrintInfo *tempPrintInfo = [pageLayout printInfo];

	if (NSOKButton == returnCode) {
#ifdef WIN32
		float lm = [tempPrintInfo leftMargin] / 2.540000;
		float rm = [tempPrintInfo rightMargin] / 2.540000;
		float tm = [tempPrintInfo topMargin] / 2.540000;
		float bm = [tempPrintInfo bottomMargin] / 2.540000;

		[tempPrintInfo setLeftMargin:lm];
		[tempPrintInfo setRightMargin:rm];
		[tempPrintInfo setTopMargin:tm];
		[tempPrintInfo setBottomMargin:bm];
#else
		NSString *message;
		NSPrintingOrientation ori = [tempPrintInfo orientation];
		
		[[NSUserDefaults standardUserDefaults] setObject:[NSArchiver archivedDataWithRootObject:tempPrintInfo] forKey:DefaultPageLayoutKey]; // archiveをしないとSIGUPエラーになる。archiveをするとpaperNameの情報は消え去る。 //
		[curValues setObject:tempPrintInfo forKey:DefaultPageLayoutKey];
		switch (ori) {
		case NSPortraitOrientation:
			message = NSLocalizedString(@"PortraitOrientation",@"");
			break;
		case NSLandscapeOrientation:
			message = NSLocalizedString(@"LandscapeOrientation",@"");
			break;
		default:
			message = NSLocalizedString(@"M LandscapeOrientation",@"");
			NSLog(@"ori=%ld",ori);
			break;
		}
		[pageLayoutContents setStringValue:[NSString stringWithFormat:@"%@ %@ %@",[tempPrintInfo paperName],message,[[tempPrintInfo printer] name]]];
#endif
	}
	[pageLayoutDescriptionView setString:[tempPrintInfo description]];
}

- (IBAction)setDefaultTextFont:(id)sender
{
	NSFontManager *sharedFM = [NSFontManager sharedFontManager];
	NSDictionary *fontDict = [curValues objectForKey:DefaultFontDescriptorKey];
	NSFont *dFont = [NSFont fontWithName:[fontDict objectForKey:NSFontNameAttribute] size:[[fontDict objectForKey:NSFontSizeAttribute] floatValue]];

	[[self window] makeFirstResponder:[self window]]; // これをやらないとchangeFont:が呼び出されない。 //
	[sharedFM setSelectedFont:dFont isMultiple:NO];
	[sharedFM setSelectedAttributes:fontDict isMultiple:NO];
    [sharedFM orderFrontFontPanel:self];
}

- (void)changeFont:(id)fontManager
// NSFontManager Delegate //
{
	NSFont *convertFont = [fontManager convertFont:[fontManager selectedFont]];
	NSFontDescriptor *newDesc = [convertFont fontDescriptor];
	NSMutableDictionary *newDic = [NSMutableDictionary dictionaryWithDictionary:[newDesc fontAttributes]];
	
	if (nil == [newDic objectForKey:NSForegroundColorAttributeName])
		[newDic setObject:[NSArchiver archivedDataWithRootObject:[fontColorWell color]] forKey:NSForegroundColorAttributeName];
	else
		NSLog(@"NSForegroundColorAttributeName is exists.");
	// optionalであることがはっきりしたので、ここで定義する。 //
	[newDic setObject:[newDesc postscriptName] forKey:NSFontNameAttribute];
	[newDic setObject:[NSString stringWithFormat:@"%g",[newDesc pointSize]] forKey:NSFontSizeAttribute];
	[[NSUserDefaults standardUserDefaults] setObject:newDic forKey:DefaultFontDescriptorKey];
	[curValues setObject:newDic forKey:DefaultFontDescriptorKey];
	[[textFontContents cell] setFont:convertFont];
	[[textFontContents cell] setTextColor:[fontColorWell color]];
	[textFontContents setStringValue:[NSString stringWithFormat:@"%@ (%@) %0.1f%@",[convertFont displayName],[newDic objectForKey:NSFontNameAttribute],[[newDic objectForKey:NSFontSizeAttribute] floatValue],NSLocalizedString(@"Point",@"")]];
	[[NSFontManager sharedFontManager] setSelectedFont:nil isMultiple:[[NSFontManager sharedFontManager] isMultiple]];
}

- (IBAction)changeFontColor:(id)sender
{
	NSMutableDictionary *newDic = [NSMutableDictionary dictionaryWithDictionary:[curValues objectForKey:DefaultFontDescriptorKey]];
	NSString *contents = [textFontContents stringValue];

	[newDic setObject:[NSArchiver archivedDataWithRootObject:[sender color]] forKey:NSForegroundColorAttributeName];
	[[NSUserDefaults standardUserDefaults] setObject:newDic forKey:DefaultFontDescriptorKey];
	[curValues setObject:newDic forKey:DefaultFontDescriptorKey];
	[[textFontContents cell] setTextColor:[fontColorWell color]];
	[textFontContents setStringValue:contents];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_4
	NSInteger row = [[aNotification object] selectedRow];

	if (0 <= row) {
		ColorSpacePanelController *colorP = [ColorSpacePanelController sharedColorSpacePanelController];
		NSColorSpace *colorSpace = [[colorP colorProfiles] objectAtIndex:(NSUInteger)row];
		[selectedProfileField setStringValue:[NSString stringWithFormat:@"%@ [%ld]",[colorSpace localizedName],[colorSpace numberOfColorComponents]]];
		[[NSUserDefaults standardUserDefaults] setObject:[NSArchiver archivedDataWithRootObject:colorSpace] forKey:ColorSpaceKey];
	}
#endif
}

- (IBAction)tiffCompressionChanged:(id)sender
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSInteger compressionTag = [sender selectedTag];
	if ((NSTIFFCompressionCCITTFAX3 == compressionTag) || (NSTIFFCompressionCCITTFAX4 == compressionTag)) {
		if (SKTTIFFMonochrome != [tiffColorSpacePopUp selectedTag]) {
			[tiffColorSpacePopUp selectItemWithTag:SKTTIFFMonochrome];
			[curValues setObject:[NSNumber numberWithInt:SKTTIFFMonochrome] forKey:TIFFColorSpaceKey];
			[defaults setObject:[NSNumber numberWithInt:SKTTIFFMonochrome] forKey:TIFFColorSpaceKey];
		}
		[tiffColorSpacePopUp setEnabled:NO];
	}
	else
		[tiffColorSpacePopUp setEnabled:YES];
	[curValues setObject:[NSNumber numberWithInt:compressionTag] forKey:TIFFCompressionKey];
	[defaults setObject:[NSNumber numberWithInt:compressionTag] forKey:TIFFCompressionKey];
}
- (IBAction)tiffColorSpaceChanged:(id)sender
{
	NSInteger compressionTag = [tiffCompressionPopUp selectedTag];
	if ((NSTIFFCompressionCCITTFAX3 == compressionTag) || (NSTIFFCompressionCCITTFAX4 == compressionTag))
		[sender selectItemWithTag:SKTTIFFMonochrome];
	else {
		int colorSpaceTag = [sender selectedTag];
		[curValues setObject:[NSNumber numberWithInt:colorSpaceTag] forKey:TIFFColorSpaceKey];
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:colorSpaceTag] forKey:TIFFColorSpaceKey];
	}
}
- (IBAction)tiffResolutionChanged:(id)sender
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	CGFloat defaultR = (nil != [defaults objectForKey:TIFFResolutionKey]) ? [[defaults objectForKey:TIFFResolutionKey] floatValue] : [[defaultValues() objectForKey:TIFFResolutionKey] floatValue];
	CGFloat newR = [[sender objectValue] floatValue];
	if (defaultR != newR) {
		if ((72.0 > newR) || (2400.0 < newR)) {
			[sender setObjectValue:[NSNumber numberWithFloat:defaultR]];
			NSBeep();
		}
		else {
			[curValues setObject:[NSNumber numberWithFloat:newR] forKey:TIFFResolutionKey];
			[defaults setObject:[NSNumber numberWithFloat:newR] forKey:TIFFResolutionKey];
		}
	}
}

- (IBAction)showHelp:(id)sender
{
	NSString *locBookName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleHelpBookName"];
	[[NSHelpManager sharedHelpManager] openHelpAnchor:@"Window_Preference" inBook:locBookName];
}

@end
