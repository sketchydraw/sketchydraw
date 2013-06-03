// SKTInspectorController.h
// Sketch Example
//
// ASShadingModelへの変更に関するundoは動作しない。破線パターンと塗り潰しに関するundoを実行しても回復値が表示されない。これらはバグでなくて仕様によるものである。 //

#import <AppKit/AppKit.h>
#import <ASWebView/ASDialKnob.h>
#import <ASPointControl/ASPointControl.h>

#define InspectorLineWidth @"InspectorLineWidth"
#define REAL_LINE_STRING @""
#define DefaultLineWidth 1.0

@class SKTGraphicView;

@interface SKTInspectorController : NSWindowController <NSWindowDelegate>
{
    @private
    IBOutlet NSButton *lineCheckbox; // value[mainWindow.windowController.graphicsController.selection.drawingStroke] availability[mainWindow.windowController.graphicsController.selection.canSetDrawingStroke] availability[mainWindow.windowController.graphicsController.selection.locked]NSNegateBoolean //
    IBOutlet NSColorWell *lineColorWell; // value[mainWindow.windowController.graphicsController.selection.strokeColor] availability[mainWindow.windowController.graphicsController.selection.drawingStroke] availability[mainWindow.windowController.graphicsController.selection.locked]NSNegateBoolean //
    IBOutlet NSSlider *lineWidthSlider; // value[mainWindow.windowController.graphicsController.selection.strokeWidth] availability[mainWindow.windowController.graphicsController.selection.drawingStroke] availability[mainWindow.windowController.graphicsController.selection.locked]NSNegateBoolean //
	IBOutlet NSForm *lineWidthForm; // value[mainWindow.windowController.graphicsController.selection.strokeWidth] availability[mainWindow.windowController.graphicsController.selection.drawingStroke] availability[mainWindow.windowController.graphicsController.selection.locked]NSNegateBoolean //
	IBOutlet NSBox *lineWidthBox;
	IBOutlet NSBox *dimensionsBox;
	IBOutlet NSForm *widthAndHeight; // value[mainWindow.windowController.graphicsController.selection.width] availability[mainWindow.windowController.graphicsController.selection.locked]NSNegateBoolean //
	IBOutlet NSForm *originForm; // value[mainWindow.windowController.graphicsController.selection.xPosition] availability[mainWindow.windowController.graphicsController.selection.locked]NSNegateBoolean //
	IBOutlet NSImageView *classImageView;
	IBOutlet NSImageView *smallClassImageView;
	IBOutlet NSButton *dashOffsetButton; // availavility[mainWindow.windowController.graphicsController.selection.canDrawDash] availability[mainWindow.windowController.graphicsController.selection.locked]NSNegateBoolean //
	IBOutlet NSTextField *dashOffsetField; // value[mainWindow.windowController.graphicsController.selection.lineDashPhase] availavility[mainWindow.windowController.graphicsController.selection.canDrawDash] availability[mainWindow.windowController.graphicsController.selection.locked]NSNegateBoolean //
	IBOutlet NSSlider *dashOffsetSlider; // value[mainWindow.windowController.graphicsController.selection.lineDashPhase] availavility[mainWindow.windowController.graphicsController.selection.canDrawDash] availability[mainWindow.windowController.graphicsController.selection.locked]NSNegateBoolean //
	IBOutlet NSBox *dashPatternBox;
	IBOutlet NSTextField *dashPatternField; // value[mainWindow.windowController.graphicsController.selection.lineDashPattern] availavility[mainWindow.windowController.graphicsController.selection.canDrawDash] availability[mainWindow.windowController.graphicsController.selection.locked]NSNegateBoolean //
	IBOutlet NSTextField *dashPatternTitle;
	IBOutlet NSPopUpButton *dashTemplatePopUp; // availavility[mainWindow.windowController.graphicsController.selection.canDrawDash] availability[mainWindow.windowController.graphicsController.selection.locked]NSNegateBoolean //
	IBOutlet NSPopUpButton *lineCapPopUp; // value[mainWindow.windowController.graphicsController.selection.lineCap] availability[mainWindow.windowController.graphicsController.selection.locked]NSNegateBoolean //
	IBOutlet NSTextField *lineCapTitle;
	IBOutlet NSPopUpButton *lineJoinPopUp; // value[mainWindow.windowController.graphicsController.selection.lineJoin] availability[mainWindow.windowController.graphicsController.selection.locked]NSNegateBoolean //
	IBOutlet NSTextField *lineJoinTitle;
	IBOutlet NSBox *arrowsOrCornerBox;
	IBOutlet NSBox *arrowsBox;
	IBOutlet NSPopUpButton *arrows; // value[mainWindow.windowController.graphicsController.selection.arrowState] availavility[mainWindow.windowController.graphicsController.selection.canDrawArrow] availability[mainWindow.windowController.graphicsController.selection.locked]NSNegateBoolean //
	IBOutlet NSTextField *arrowsTitle;
	IBOutlet NSBox *radiusBox;
	IBOutlet NSForm *radiusXForm; // value[mainWindow.windowController.graphicsController.selection.rx] availavility[mainWindow.windowController.graphicsController.selection.canDrawCorner] availability[mainWindow.windowController.graphicsController.selection.locked]NSNegateBoolean //
	IBOutlet NSForm *radiusYForm; // value[mainWindow.windowController.graphicsController.selection.ry] availavility[mainWindow.windowController.graphicsController.selection.canDrawCorner] availability[mainWindow.windowController.graphicsController.selection.locked]NSNegateBoolean //
	/* IBOutlet NSButton *formEntryButton; */
	IBOutlet NSTextField *imagePageField; // value[mainWindow.windowController.graphicsController.selection.currentPage] //
	IBOutlet NSTextField *imagePageCountField; // value[mainWindow.windowController.graphicsController.selection.currentPage] //
	IBOutlet NSSegmentedControl *imagePageControl;

	IBOutlet NSPopUpButton *shadingStylePopUp;
	IBOutlet NSBox *fillBox;
	IBOutlet NSTextField *fillBoxTitle;
	IBOutlet NSMatrix *windingRuleMatrix; // value[mainWindow.windowController.graphicsController.selection.windingRule] //
	IBOutlet NSTextField *windingRuleTitle;
    IBOutlet NSColorWell *startColorWell;
    IBOutlet NSColorWell *midColorWell;
    IBOutlet NSColorWell *endColorWell;
	IBOutlet NSSlider *colorPositionSlider;
	IBOutlet ASPointControl *centerControl; // bind: //
	IBOutlet ASDialKnob *shadingAngleKnob; // bind: //

	IBOutlet NSBox *rotateBox;
	IBOutlet NSTextField *rotateField; // value[mainWindow.windowController.graphicsController.selection.rotateAngle] availavility[mainWindow.windowController.graphicsController.selection.canDrawRotate] availability[mainWindow.windowController.graphicsController.selection.locked]NSNegateBoolean //
	IBOutlet ASDialKnob *dialKnob; // bind: //
	IBOutlet NSTabView *tabView;
	IBOutlet NSBox *shadowBox;
	IBOutlet ASPointControl *shadowOffsetControl; // bind: //
	IBOutlet NSForm *shadowBlurForm; // value[mainWindow.windowController.graphicsController.selection.shadowBlurRadiusValue] availability[mainWindow.windowController.graphicsController.selection.locked]NSNegateBoolean //
	IBOutlet NSSlider *shadowBlurSlider; // value[mainWindow.windowController.graphicsController.selection.shadowBlurRadiusValue] availability[mainWindow.windowController.graphicsController.selection.locked]NSNegateBoolean //
	IBOutlet NSColorWell *shadowColorWell; // value[mainWindow.windowController.graphicsController.selection.shadowColor] availability[mainWindow.windowController.graphicsController.selection.locked]NSNegateBoolean //
	IBOutlet NSTextField *shadowColorTitle;
	IBOutlet NSForm *measurementUnitForm;
	double pointsPerUnit;
	NSArrayController *_selectionIndexesContainer;
	NSString *_selectionIndexesKeyPath;
    SKTGraphicView *_inspectingGraphicView;
    BOOL needsUpdate;
}

+ (id)sharedInspectorController;

- (IBAction)fillColorWellAction:(id)sender;
- (IBAction)formEntryButtonAction:(id)sender;
- (IBAction)imagePageUpOrDownAction:(id)sender;
- (NSImage *)imageForClass:(NSString *)aString;
- (NSArray *)dashTemplate:(NSInteger)item;
- (IBAction)setDashTemplate:(id)sender;
- (IBAction)setOptimalOffset:(id)sender;
- (void)setOffsetSliderMaxValue:(NSArray *)pattern;
- (NSDictionary *)displayedValues;
- (IBAction)shadingStyleAction:(id)sender;
- (IBAction)colorPositionAction:(id)sender;

@end
