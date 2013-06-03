//
//  PreferencesController.h
//  Sketch
//
//  Created by me on Tue May 01 2001.
//  Copyright (c) 2001 SatoAkira. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface PreferencesController : NSWindowController <NSTableViewDelegate,NSTableViewDataSource,NSWindowDelegate>
{
	IBOutlet NSTabView *tabView;
	IBOutlet NSButton *antialiasSwitch;
	IBOutlet NSButton *imageInterpolationSwitch; // sktdとの互換性を廃止した。boolにしてしまった。NSImageInterpolationHighにするかどうかはSKTGraphicViewにやらせる。 //
	IBOutlet NSButton *revertBackgroundColorButton;
	IBOutlet NSColorWell *backgroundColorWell;
	IBOutlet NSButton *backgroundColorSwitch;
	IBOutlet NSButton *revertKnobColorButton;
	IBOutlet NSTextField *knobColorTitle;
	IBOutlet NSColorWell *knobColorWell;
	IBOutlet NSPopUpButton *measurementUnitPopUp;
	IBOutlet NSTextField *measurementUnitTitle;
	IBOutlet NSPopUpButton *tiffCompressionPopUp;
	IBOutlet NSPopUpButton *tiffColorSpacePopUp;
	IBOutlet NSComboBox *tiffResolutionCombo;
	IBOutlet NSBox *tiffOptionsBox;
	IBOutlet NSTextField *pageLayoutTitle;
	IBOutlet NSTextField *pageLayoutContents;
	IBOutlet NSTextView *pageLayoutDescriptionView;
	IBOutlet NSButton *setPageLayoutButton;
	IBOutlet NSTextField *textFontTitle;
	IBOutlet NSTextField *textFontContents;
	IBOutlet NSButton *setTextFontButton;
	IBOutlet NSColorWell *fontColorWell;
	IBOutlet NSTableView *profilesTableView;
	IBOutlet NSTextField *selectedProfileField;
	IBOutlet NSButton *autosaveSwitch;
	/* IBOutlet NSTextField *autosaveEveryField;
	IBOutlet NSTextField *autosaveSecondsField; */
    NSMutableDictionary *curValues;
    /* BOOL _autosaves;
    NSTimeInterval _autosavingDelay; */
	NSData *_KnobColor;
	NSColor *_KnobColorContents;
	NSString *_MeasurementUnit; // - (void)setMeasurementUnit:(NSString *)を呼び出してもらう為に必要なだけで他に使い途は無い。 //
}

typedef enum _SKTTIFFColorSpace {
	SKTTIFFDocument,
	SKTTIFFGrayscale,
	SKTTIFFMonochrome
} SKTTIFFColorSpace;

+ (id)objectForKey:(id)key;	// Convenience for getting global preferences //
+ (NSDictionary *)preferencesFromDefaults;

+ (PreferencesController *)sharedPreferencesController;

- (NSDictionary *)preferences;	// The current preferences; contains values for the documented keys //

- (IBAction)backgroundColorChanged:(id)sender;
- (IBAction)useBackgroundColor:(id)sender;
- (IBAction)knobColorChanged:(id)sender;
- (IBAction)revertKnobColor:(id)sender;
- (IBAction)revertBackgroundColor:(id)sender;
- (IBAction)runPageLayout:(id)sender;
- (IBAction)setDefaultTextFont:(id)sender;
- (void)changeFont:(id)fontManager;
- (IBAction)changeFontColor:(id)sender;
- (IBAction)tiffCompressionChanged:(id)sender;
- (IBAction)tiffColorSpaceChanged:(id)sender;
- (IBAction)tiffResolutionChanged:(id)sender;
- (IBAction)antialiasChanged:(id)sender;
- (IBAction)imageInterpolationChanged:(id)sender;

@end

extern NSString *SKTBackgroundColorDidChangeNotification;
extern NSString *SKTUseBackgroundColorDidChangeNotification;
extern NSString *SKTKnobColorDidChangeNotification;
extern NSString *SKTMeasurementUnitDidChangeNotification;
extern NSString *BackgroundColorKey;
extern NSString *UseBackgroundColorKey;
extern NSString *AntialiasKey;
extern NSString *ImageInterpolationKey;
extern NSString *MeasurementUnitKey;
extern NSString *PointsPerUnitKey;
extern NSString *TIFFCompressionKey;
extern NSString *TIFFColorSpaceKey;
extern NSString *TIFFResolutionKey;
extern NSString *ColorSpaceKey;
extern NSString *DefaultFontDescriptorKey;
extern NSString *DefaultPageLayoutKey;
extern NSString *KnobColorKey;
