// SKTInspectorController.m
// Sketch Example
//

#import "SKTInspectorController.h"
#import "SKTWindowController.h"
#import "SKTGraphicView.h"
#import "SKTGraphic.h"
#import "SKTImage.h"
#import "SKTFoundationExtras.h"
#import "PreferencesController.h" // 単位取得 //
#define MINIMUM_LINEWIDTH 0.001 // 破線パターンの指定に制限を与えるときのパラメータおよび「線の太さ」を指定するTextFieldの小数点の位置を決めるパラメータ //

@implementation SKTInspectorController


+ (id)sharedInspectorController {
    static SKTInspectorController *_sharedInspectorController = nil;

	if (!_sharedInspectorController) {
        _sharedInspectorController = [[SKTInspectorController allocWithZone:[self zone]] init];
    }
    return _sharedInspectorController;
}

- (id)initWithWindowNibName:(NSString *)windowNibName owner:(id)owner {
	if (nil != (self = [super initWithWindowNibName:windowNibName owner:owner])) {
		[self setWindowFrameAutosaveName:windowNibName];
		needsUpdate = NO;
	}
	return self;
}
- (id)initWithWindowNibName:(NSString *)windowNibName {
	return [self initWithWindowNibName:windowNibName owner:self];
}
- (id)init {
    return [self initWithWindowNibName:@"Inspector" owner:self];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[self unbind:SKTGraphicViewSelectionIndexesBindingName];
	[dialKnob unbind:ASDialKnobRotateAngleKey];
	[shadowOffsetControl unbind:ASPointControlMousePointKey];
	[centerControl unbind:ASPointControlMousePointKey];
	[shadingAngleKnob unbind:ASDialKnobRotateAngleKey];
    [super dealloc];
}

- (NSArray *)selectedGraphics {
	return (nil != _selectionIndexesContainer) ? [_selectionIndexesContainer selectedObjects] : nil;
}
- (void)setMainWindow:(NSWindow *)mainWindow
{
	if (nil != mainWindow) {
		NSWindowController *controller = [mainWindow windowController];

		if (nil != _inspectingGraphicView) {
			[self unbind:SKTGraphicViewSelectionIndexesBindingName];
			[dialKnob unbind:ASDialKnobRotateAngleKey];
			[shadowOffsetControl unbind:ASPointControlMousePointKey];
			[centerControl unbind:ASPointControlMousePointKey];
		}
		if (controller && [controller isKindOfClass:[SKTWindowController class]]) {
			_inspectingGraphicView = [(SKTWindowController *)controller valueForKey:@"graphicView"];
			[self bind:SKTGraphicViewSelectionIndexesBindingName toObject:[_inspectingGraphicView valueForKey:@"selectionIndexesContainer"] withKeyPath:@"selectionIndexes" options:nil]; // keyPathはSKTGraphicViewSelectionIndexesObservationContextに定義されている。valueForKeyは_selectionIndexesContainerでNSArrayController。 //
			[dialKnob bind:ASDialKnobRotateAngleKey toObject:[_inspectingGraphicView valueForKey:@"selectionIndexesContainer"] withKeyPath:[NSString stringWithFormat:@"selection.%@",SKTRotateAngleKey] options:nil];
			[shadowOffsetControl bind:ASPointControlMousePointKey toObject:[_inspectingGraphicView valueForKey:@"selectionIndexesContainer"] withKeyPath:[NSString stringWithFormat:@"selection.%@",SKTShadowOffsetPointKey] options:nil];
			[centerControl bind:ASPointControlMousePointKey toObject:[_inspectingGraphicView valueForKey:@"selectionIndexesContainer"] withKeyPath:[NSString stringWithFormat:@"selection.%@",SKTShadingRadialCenterKey] options:nil]; // shadingModel.radialCenterとしても良いように見えるがshadingModelがnilになることがあるので良くない。 //
			[shadingAngleKnob bind:ASDialKnobRotateAngleKey toObject:[_inspectingGraphicView valueForKey:@"selectionIndexesContainer"] withKeyPath:[NSString stringWithFormat:@"selection.%@",SKTShadingAxialAngleKey] options:nil];
		} else {
			_inspectingGraphicView = nil;
		}
	}
	else {
		_inspectingGraphicView = nil;
		[self unbind:SKTGraphicViewSelectionIndexesBindingName];
		[dialKnob unbind:ASDialKnobRotateAngleKey];
		[shadowOffsetControl unbind:ASPointControlMousePointKey];
		[centerControl unbind:ASPointControlMousePointKey];
		[shadingAngleKnob unbind:ASDialKnobRotateAngleKey];
	}
	needsUpdate = YES;
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(NSObject *)observedObject change:(NSDictionary *)change context:(void *)context
{
	if (YES == [_selectionIndexesKeyPath isEqualToString:keyPath]) {
		needsUpdate = YES;
	}
}
- (void)bind:(NSString *)bindingName toObject:(id)observableObject withKeyPath:(NSString *)observableKeyPath options:(NSDictionary *)options
{

	if (YES == [SKTGraphicViewSelectionIndexesBindingName isEqualToString:bindingName]) {
		[_selectionIndexesContainer release];
		_selectionIndexesContainer = [observableObject retain];
		[_selectionIndexesKeyPath release];
		_selectionIndexesKeyPath = [observableKeyPath copy];
		[observableObject addObserver:self forKeyPath:observableKeyPath options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
	}
}
- (void)unbind:(NSString *)bindingName
{
	if (YES == [SKTGraphicViewSelectionIndexesBindingName isEqualToString:bindingName]) {
		[_selectionIndexesContainer removeObserver:self forKeyPath:_selectionIndexesKeyPath];
		[_selectionIndexesKeyPath release];
		_selectionIndexesKeyPath = nil;
		[_selectionIndexesContainer release];
		_selectionIndexesContainer = nil;
	}
}

- (void)displayArrowsOrCornerBox:(NSArray *)graphics
// enabledはbindによりlockedを見て設定される。 //
{
	NSView *boxContent = [arrowsOrCornerBox contentView];
	if (radiusBox == boxContent) {
		[radiusBox retain];
		[radiusBox removeFromSuperview];
	}
	if (arrowsBox == boxContent) {
		[arrowsBox retain];
		[arrowsBox removeFromSuperview];
	}
	if ((nil != graphics) && (0 < [graphics count])) {
		SKTGraphic *graphic;
		BOOL arrowsFlag = YES;
		BOOL cornerFlag = YES;
		for (graphic in graphics) {
			if (NO == [graphic canDrawArrow])
				arrowsFlag = NO;
			if (NO == [graphic canDrawCorner])
				cornerFlag = NO;
		}
		if (YES == arrowsFlag) // arrowsBoxを優先とする。 //
			[arrowsOrCornerBox setContentView:arrowsBox];
		else {
			if (YES == cornerFlag)
				[arrowsOrCornerBox setContentView:radiusBox];
		}
	}
}
- (void)displayDashPatternSymbol:(NSArray *)graphics
// windowDidLoadでlineCapPopUpのtag設定が終わっているものとする。dashTemplatePopUpに5個の要素を持たせてimageOnlyに設定してあるものとする。lineCapが変化したときにはKVOしていないので対応できない。 //
{
	SKTGraphic *graphic = ((nil != graphics) && (0 < [graphics count])) ? [graphics objectAtIndex:0] : nil;
	NSLineCapStyle lineCapKind = (nil != graphic) ? [graphic lineCap] : [lineCapPopUp selectedTag];
	if (NSRoundLineCapStyle == lineCapKind) {
		[[dashTemplatePopUp itemAtIndex:0] setImage:[NSImage imageNamed:@"line_real_round"]];
		[[dashTemplatePopUp itemAtIndex:1] setImage:[NSImage imageNamed:@"line_broken_round"]];
		[[dashTemplatePopUp itemAtIndex:2] setImage:[NSImage imageNamed:@"line_dotted_round"]];
		[[dashTemplatePopUp itemAtIndex:3] setImage:[NSImage imageNamed:@"line_onedotted_round"]];
		[[dashTemplatePopUp itemAtIndex:4] setImage:[NSImage imageNamed:@"line_twodotted_round"]];
	}
	else {
		[[dashTemplatePopUp itemAtIndex:0] setImage:[NSImage imageNamed:@"line_real_butt"]];
		[[dashTemplatePopUp itemAtIndex:1] setImage:[NSImage imageNamed:@"line_broken_butt"]];
		[[dashTemplatePopUp itemAtIndex:2] setImage:[NSImage imageNamed:@"line_dotted_butt"]];
		[[dashTemplatePopUp itemAtIndex:3] setImage:[NSImage imageNamed:@"line_onedotted_butt"]];
		[[dashTemplatePopUp itemAtIndex:4] setImage:[NSImage imageNamed:@"line_twodotted_butt"]];
	}
}
- (void)displayFillBox:(BOOL)enabled graphic:(SKTGraphic *)graphic
{
	ASShadingStyle shadingStyle;
	ASShadingModel *shadingModel;
	CGFloat midColorPosition = 0.0;
	NSArray *colors = nil;
	NSView *boxContent = [fillBox contentView];
	NSResponder *firstResponder = [[self window] firstResponder];
	NSPoint customviewOrigin = NSMakePoint(89.5,9.0);

	if (nil != graphic) {
		if (YES == [graphic canSetDrawingFill]) {
			if (YES == [graphic isDrawingFill]) {
				if (NO == [graphic shading]) {
					shadingStyle = ASNoneShading;
					colors = [NSArray arrayWithObject:[graphic fillColor]];
				}
				else {
					if (nil != (shadingModel = [graphic shadingModel])) {
						shadingStyle = [shadingModel shadingStyle];
						colors = [shadingModel colors];
						midColorPosition = [[[shadingModel colorPosition] objectAtIndex:1] floatValue];
					}
					else {
						shadingStyle = ASNoneShading;
						colors = [NSArray arrayWithObject:[NSColor whiteColor]];
					}
				}
			}
			else
				shadingStyle = ASShadingError;
		}
		else
			shadingStyle = ASShadingError;
	}
	else
		shadingStyle = ASShadingError;
	if ([startColorWell superview] == boxContent) {
		[startColorWell retain];
		[startColorWell removeFromSuperview];
	}
	if ([midColorWell superview] == boxContent) {
		[midColorWell retain];
		[midColorWell removeFromSuperview];
	}
	if ([endColorWell superview] == boxContent) {
		[endColorWell retain];
		[endColorWell removeFromSuperview];
	}
	if ([windingRuleMatrix superview] == boxContent) {
		[windingRuleMatrix retain];
		[windingRuleMatrix removeFromSuperview];
	}
	if ([windingRuleTitle superview] == boxContent) {
		[windingRuleTitle retain];
		[windingRuleTitle removeFromSuperview];
	}
	if ([colorPositionSlider superview] == boxContent) {
		[colorPositionSlider retain];
		[colorPositionSlider removeFromSuperview];
	}
	if ([shadingAngleKnob superview] == boxContent) {
		[shadingAngleKnob retain];
		[shadingAngleKnob removeFromSuperview];
	}
	if ([centerControl superview] == boxContent) {
		[centerControl retain];
		[centerControl removeFromSuperview];
	}
	switch (shadingStyle) {
		case ASNoneShading:
			[fillBox addSubview:midColorWell];
			[fillBox addSubview:windingRuleMatrix];
			[fillBox addSubview:windingRuleTitle];
			[midColorWell setEnabled:enabled];
			[windingRuleMatrix setEnabled:enabled];
			[shadingStylePopUp selectItemAtIndex:1];
			[windingRuleMatrix selectCellAtRow:(NSEvenOddWindingRule == [graphic windingRule]) ? 1 : 0 column:0];
			[midColorWell setColor:[colors objectAtIndex:0]];
			break;
		case ASAxialShading:
			[fillBox addSubview:startColorWell];
			[fillBox addSubview:endColorWell];
			[fillBox addSubview:colorPositionSlider];
			[fillBox addSubview:shadingAngleKnob];
			[startColorWell setEnabled:enabled];
			[endColorWell setEnabled:enabled];
			[colorPositionSlider setEnabled:enabled];
			[shadingAngleKnob setEnabled:enabled];
			[shadingStylePopUp selectItemAtIndex:2];
			[startColorWell setColor:[colors objectAtIndex:0]];
			[endColorWell setColor:[colors objectAtIndex:2]];
			[colorPositionSlider setFloatValue:midColorPosition];
			[shadingAngleKnob setFrameOrigin:customviewOrigin];
			break;
		case ASRadialShading:
			[fillBox addSubview:startColorWell];
			[fillBox addSubview:endColorWell];
			[fillBox addSubview:colorPositionSlider];
			[fillBox addSubview:centerControl];
			[startColorWell setEnabled:enabled];
			[endColorWell setEnabled:enabled];
			[colorPositionSlider setEnabled:enabled];
			[centerControl setEnabled:enabled];
			[shadingStylePopUp selectItemAtIndex:3];
			[startColorWell setColor:[colors objectAtIndex:0]];
			[endColorWell setColor:[colors objectAtIndex:2]];
			[colorPositionSlider setFloatValue:midColorPosition];
			[centerControl setFrameOrigin:customviewOrigin];
			break;
		case ASDoubleAxialShading:
			[fillBox addSubview:startColorWell];
			[fillBox addSubview:midColorWell];
			[fillBox addSubview:endColorWell];
			[fillBox addSubview:colorPositionSlider];
			[fillBox addSubview:shadingAngleKnob];
			[startColorWell setEnabled:enabled];
			[midColorWell setEnabled:enabled];
			[endColorWell setEnabled:enabled];
			[colorPositionSlider setEnabled:enabled];
			[shadingAngleKnob setEnabled:enabled];
			[shadingStylePopUp selectItemAtIndex:4];
			[startColorWell setColor:[colors objectAtIndex:0]];
			[midColorWell setColor:[colors objectAtIndex:1]];
			[endColorWell setColor:[colors objectAtIndex:2]];
			[colorPositionSlider setFloatValue:midColorPosition];
			[shadingAngleKnob setFrameOrigin:customviewOrigin];
			break;
		case ASDoubleRadialShading:
			[fillBox addSubview:startColorWell];
			[fillBox addSubview:midColorWell];
			[fillBox addSubview:endColorWell];
			[fillBox addSubview:colorPositionSlider];
			[fillBox addSubview:centerControl];
			[startColorWell setEnabled:enabled];
			[midColorWell setEnabled:enabled];
			[endColorWell setEnabled:enabled];
			[colorPositionSlider setEnabled:enabled];
			[centerControl setEnabled:enabled];
			[shadingStylePopUp selectItemAtIndex:5];
			[startColorWell setColor:[colors objectAtIndex:0]];
			[midColorWell setColor:[colors objectAtIndex:1]];
			[endColorWell setColor:[colors objectAtIndex:2]];
			[colorPositionSlider setFloatValue:midColorPosition];
			[centerControl setFrameOrigin:customviewOrigin];
			break;
		default: // drawsFillがNOのとき //
			[shadingStylePopUp selectItemAtIndex:0];
			break;
	}
	[shadingStylePopUp setEnabled:enabled];
	if (nil != firstResponder)
		[[self window] makeFirstResponder:firstResponder];
}
- (void)measurementUnitDidChange:(NSNotification *)notification
{
	NSNumber *ppu = (nil != [[NSUserDefaults standardUserDefaults] objectForKey:PointsPerUnitKey]) ? [[NSUserDefaults standardUserDefaults] objectForKey:PointsPerUnitKey] : [NSNumber numberWithDouble:1.0];
	NSNumber *_ppu = [NSNumber numberWithDouble:1.0 / [ppu doubleValue]];
	NSNumberFormatter *sizeFormatter = [[NSNumberFormatter alloc] init];
	[sizeFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
	[sizeFormatter setFormat:@"#,##0.000"];
	[sizeFormatter setMultiplier:_ppu];
	[[widthAndHeight cellAtIndex:0] setFormatter:sizeFormatter];
	[[widthAndHeight cellAtIndex:1] setFormatter:sizeFormatter];
	[[lineWidthForm cellAtIndex:0] setFormatter:sizeFormatter]; // setFloatingPointFormat:NO left:0 right:(int)(-1.0 * log10(MINIMUM_LINEWIDTH)) //
	[[dashOffsetField cell] setFormatter:sizeFormatter];
	[sizeFormatter release];

	NSNumberFormatter *radiusFormatter = [[NSNumberFormatter alloc] init]; // 幅が小さくなってしまうので別のformatにする。 //
	[radiusFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
	[radiusFormatter setFormat:@"#,##0.00"];
	[radiusFormatter setMultiplier:_ppu];
	[[radiusXForm cellAtIndex:0] setFormatter:radiusFormatter];
	[[radiusYForm cellAtIndex:0] setFormatter:radiusFormatter];
	[radiusFormatter release];
	
	NSNumberFormatter *positionFormatter = [[NSNumberFormatter alloc] init];
	[positionFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
	[positionFormatter setFormat:@"#,##0.00"];
	[positionFormatter setMultiplier:_ppu];
	[[originForm cellAtIndex:0] setFormatter:positionFormatter];
	[[originForm cellAtIndex:1] setFormatter:positionFormatter];
	[positionFormatter release];

	pointsPerUnit = [ppu doubleValue];
	if (nil == [[NSUserDefaults standardUserDefaults] objectForKey:MeasurementUnitKey])
		[[measurementUnitForm cellAtIndex:0] setStringValue:@"point"];
	else
		[[measurementUnitForm cellAtIndex:0] setStringValue:[[NSUserDefaults standardUserDefaults] objectForKey:MeasurementUnitKey]];
	if (nil != notification)
		needsUpdate = YES;
}

- (void)windowDidLoad
{
	NSString *undoTableName = @"UndoStrings";

	[self setMainWindow:[NSApp mainWindow]];
	[self measurementUnitDidChange:nil];
	[[measurementUnitForm cellAtIndex:0] setTitle:[NSString stringWithFormat:@"%@:",NSLocalizedString(MeasurementUnitKey,@"")]];
	[measurementUnitForm calcSize];
	[lineCheckbox setTitle:NSLocalizedString(@"Line",@"Line")];
	[lineWidthBox setTitle:NSLocalizedString(@"Line",@"Line")];
	[[lineWidthForm cellAtIndex:0] setTitle:NSLocalizedString(@"Line Width",@"Line Width")];
	[lineWidthForm calcSize];
	[lineWidthForm setToolTip:NSLocalizedStringFromTable(@"Stroke Width",undoTableName,@"線幅")];
	[dimensionsBox setTitle:NSLocalizedString(@"Dimensions",@"Dimensions")];
	[[originForm cellAtIndex:0] setTitle:NSLocalizedString(@"X",@"X")];
	[[originForm cellAtIndex:1] setTitle:NSLocalizedString(@"Y",@"Y")];
	[originForm calcSize];
	[[widthAndHeight cellAtIndex:0] setTitle:NSLocalizedString(@"Width",@"Width")];
	[[widthAndHeight cellAtIndex:1] setTitle:NSLocalizedString(@"Height",@"Height")];
	[widthAndHeight calcSize];
	[widthAndHeight setToolTip:NSLocalizedStringFromTable(@"Resize",undoTableName,@"")];
	[lineWidthSlider setToolTip:NSLocalizedStringFromTable(@"Stroke Width",undoTableName,@"線幅")];
	[lineColorWell setToolTip:NSLocalizedStringFromTable(@"Stroke Color",undoTableName,@"線の色")];
	[lineCapTitle setStringValue:NSLocalizedStringFromTable(SKTLineCapKey,undoTableName,@"")];

	[shadingStylePopUp removeAllItems];
	[shadingStylePopUp addItemWithTitle:NSLocalizedString(@"NoFill",@"NoFill")];
	[shadingStylePopUp addItemWithTitle:NSLocalizedString(@"NonShading",@"1")];
	[shadingStylePopUp addItemWithTitle:NSLocalizedString(@"AxialShading",@"2")];
	[shadingStylePopUp addItemWithTitle:NSLocalizedString(@"RadialShading",@"3")];
	[shadingStylePopUp addItemWithTitle:NSLocalizedString(@"DoubleAxialShading",@"4")];
	[shadingStylePopUp addItemWithTitle:NSLocalizedString(@"DoubleRadialShading",@"5")];
	[fillBoxTitle setStringValue:NSLocalizedString(@"Fill",@"塗り潰し")];
	[self displayFillBox:NO graphic:nil];
	[midColorWell setToolTip:NSLocalizedStringFromTable(@"Fill Color",undoTableName,@"塗り潰し色")];
	[startColorWell setToolTip:NSLocalizedString(@"StartColor",@"")];
	[endColorWell setToolTip:NSLocalizedString(@"EndColor",@"終点の色")];
	[windingRuleTitle setStringValue:NSLocalizedStringFromTable(@"windingRule",undoTableName,@"")];
	[[windingRuleMatrix cellAtRow:0 column:0] setTitle:NSLocalizedString(@"Non-Zero",@"0")];
	[[windingRuleMatrix cellAtRow:1 column:0] setTitle:NSLocalizedString(@"Even/Odd",@"1")];
	[windingRuleMatrix setToolTip:NSLocalizedStringFromTable(SKTWindingRuleKey,undoTableName,@"")];
	[shadingAngleKnob setTickMarks:[NSColor blackColor] background:nil width:3];
	[shadingAngleKnob setToolTip:NSLocalizedString(@"Angle change in linear gradation.",@"線形グラデーションの角度変更")];
	[colorPositionSlider setMinValue:0.0];
	[colorPositionSlider setMaxValue:1.0];
	[colorPositionSlider setToolTip:NSLocalizedString(@"Positional change in neutral tints.",@"中間色の位置変更")];
	[centerControl setSquare:NO];
	[centerControl setEditable:YES];
	[centerControl setHorizontalFlipped:NO];
	[centerControl setVerticalFlipped:YES];
	[centerControl setContinuous:YES];
	[centerControl setMinPoint:NSMakePoint(-1.0,-1.0)];
	[centerControl setMaxPoint:NSMakePoint(1.0,1.0)];
	[centerControl setToolTip:NSLocalizedString(@"Change radial center.",@"円形グラデーションの中心変更")];

	[lineJoinTitle setStringValue:NSLocalizedStringFromTable(SKTLineJoinKey,undoTableName,@"")];
	/* [formEntryButton setTitle:NSLocalizedString(@"FormEntry",@"FormEntry")]; */
	[imagePageCountField setStringValue:@""];
	NSNumberFormatter *positiveIntFormatter = [[NSNumberFormatter allocWithZone:[self zone]] init];
	[positiveIntFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
	[positiveIntFormatter setFormat:@"#,##0;0;-#,##0"];
	[positiveIntFormatter setMinimum:[NSNumber numberWithUnsignedInteger:1]];
	[[imagePageField cell] setFormatter:positiveIntFormatter];
	[positiveIntFormatter release];
	[imagePageField setToolTip:NSLocalizedString(@"PDFCurrentPage",@"PDFCurrentPage")];
	[imagePageCountField setToolTip:NSLocalizedString(@"PDFPageCount",@"PDFPageCount")];
	[imagePageControl setToolTip:NSLocalizedString(@"PDFPageUp",@"PDFPageUp")];
	[lineJoinPopUp removeAllItems];
	[lineJoinPopUp insertItemWithTitle:NSLocalizedString(@"Miter",@"Miter") atIndex:NSMiterLineJoinStyle]; // 連番になっている物とする。 //
	[lineJoinPopUp insertItemWithTitle:NSLocalizedString(@"Round",@"Round") atIndex:NSRoundLineJoinStyle];
	[lineJoinPopUp insertItemWithTitle:NSLocalizedString(@"Bevel",@"･Bevel") atIndex:NSBevelLineJoinStyle];
	[lineJoinPopUp setToolTip:NSLocalizedStringFromTable(SKTLineJoinKey,undoTableName,@"")];
	[lineCapPopUp removeAllItems];
	[lineCapPopUp insertItemWithTitle:NSLocalizedString(@"Chopped",@"Chopped") atIndex:NSButtLineCapStyle]; // 連番になっている物とする。 //
	[lineCapPopUp insertItemWithTitle:NSLocalizedString(@"Round",@"Round") atIndex:NSRoundLineCapStyle];
	[lineCapPopUp insertItemWithTitle:NSLocalizedString(@"Square",@"Square") atIndex:NSSquareLineCapStyle];
	[[lineCapPopUp itemAtIndex:0] setTag:NSButtLineCapStyle];
	[[lineCapPopUp itemAtIndex:1] setTag:NSRoundLineCapStyle];
	[[lineCapPopUp itemAtIndex:2] setTag:NSSquareLineCapStyle];
	[lineCapPopUp setToolTip:NSLocalizedStringFromTable(SKTLineCapKey,undoTableName,@"")];
	[arrows removeAllItems];
	[arrows insertItemWithTitle:NSLocalizedString(@"None",@"None") atIndex:0];
	[arrows insertItemWithTitle:NSLocalizedString(@"AtStart",@"AtStart") atIndex:1];
	[arrows insertItemWithTitle:NSLocalizedString(@"AtEnd",@"AtEnd") atIndex:2];
	[arrows insertItemWithTitle:NSLocalizedString(@"BothEnds",@"BothEnds") atIndex:3];
	[arrowsTitle setStringValue:NSLocalizedStringFromTable(SKTArrowStateKey,undoTableName,@"")];
	[radiusXForm setToolTip:NSLocalizedStringFromTable(@"Set CornerRadiusX",undoTableName,@"")];
	[radiusYForm setToolTip:NSLocalizedStringFromTable(@"Set CornerRadiusY",undoTableName,@"")];
	[arrowsOrCornerBox setContentView:arrowsBox];
	[arrowsOrCornerBox setContentViewMargins:NSMakeSize(0.0,12.0)];
	[dashPatternBox setTitle:NSLocalizedString(@"BrokenPattern",@"BrokenPattern")];
	[dashOffsetButton setTitle:NSLocalizedString(@"Offset",@"Offset")];
	[dashOffsetButton  setToolTip:NSLocalizedStringFromTable(SKTLineDashPhaseKey,undoTableName,@"")];
	[dashOffsetField setToolTip:NSLocalizedStringFromTable(SKTLineDashPhaseKey,undoTableName,@"")];
	[dashOffsetField setFloatValue:0];
	[dashOffsetSlider setMinValue:0.0];
	[dashOffsetSlider setMaxValue:100.0]; // point単位 //
	[dashOffsetSlider setToolTip:NSLocalizedStringFromTable(SKTLineDashPhaseKey,undoTableName,@"")];
	[dashOffsetSlider setContinuous:YES];
	[dashPatternTitle setStringValue:NSLocalizedString(@"Pattern",@"Pattern")];
	[dashTemplatePopUp removeAllItems];
	[dashTemplatePopUp addItemsWithTitles:[NSArray arrayWithObjects:@"",@"",@"",@"",@"",nil]];
	[dashTemplatePopUp setImagePosition:NSImageOnly];
	// [dashTemplatePopUp setImageScaling:NSImageScaleProportionallyDown]; // // やり方不明 //
	[dashTemplatePopUp selectItemAtIndex:0];
	[dashTemplatePopUp setToolTip:NSLocalizedStringFromTable(SKTLineDashPatternKey,undoTableName,@"")];
	[dashPatternField setToolTip:[NSString stringWithFormat:@"%@\n%@",NSLocalizedStringFromTable(SKTLineDashPatternKey,undoTableName,@""),NSLocalizedString(@"DashPattern bug",@"単位を変更したときに変更が即座に反映されません。")]];
	[classImageView setToolTip:NSLocalizedString(@"SelectedGraphics",@"SelectedGraphics")];
	[rotateBox setTitle:NSLocalizedString(@"Rotate",@"Rotate")];
	[dialKnob setClockwise:YES];
	[dialKnob setToolTip:NSLocalizedStringFromTable(SKTRotateAngleKey,undoTableName,@"")];
	[dialKnob setTickMarks:[NSColor blackColor] background:nil width:3];
	NSNumberFormatter *dmsFormatter = [[NSNumberFormatter allocWithZone:[self zone]] init];
	[dmsFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
	[dmsFormatter setFormat:@"#,##0.0000;0.0000;-#,##0.0000"];
	[dmsFormatter setMinimum:[NSNumber numberWithDouble:0.0]];
	[dmsFormatter setMaximum:[NSNumber numberWithDouble:360.0]];
	[[rotateField cell] setFormatter:dmsFormatter];
	[dmsFormatter release];
	[rotateField setToolTip:NSLocalizedString(@"As for unit of angle D.MMSS",@"角度の単位はD.MMSS")];
	[dialKnob setBordered:NO];
	[arrowsOrCornerBox setTitle:NSLocalizedString(@"Arrow/Radius",@"矢印またはコーナー")];
	[[tabView tabViewItemAtIndex:0] setLabel:NSLocalizedString(@"Dimension",@"位置と寸法")];
	[[tabView tabViewItemAtIndex:1] setLabel:NSLocalizedString(@"Stroke&Fill",@"線と塗り潰し")];
	[[tabView tabViewItemAtIndex:2] setLabel:NSLocalizedString(@"DashPattern&Shadow",@"破線と影")];
	[shadowBox setTitle:NSLocalizedString(@"Shadow",@"影")];
	NSNumberFormatter *positiveFloatFormatter = [[NSNumberFormatter allocWithZone:[self zone]] init];
	[positiveFloatFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
	[positiveFloatFormatter setFormat:@"#,##0.00;0;-#,##0.00"];
	[positiveFloatFormatter setMinimum:[NSNumber numberWithFloat:0.00]];
	[[shadowBlurForm cellAtIndex:0] setFormatter:positiveFloatFormatter];
	[positiveFloatFormatter release];
	[[shadowBlurForm cellAtIndex:0] setTitle:NSLocalizedString(@"Blur",@"ぼかし")];
	[shadowBlurForm calcSize];
	[shadowBlurForm setToolTip:NSLocalizedString(@"Degree of shadeing off(blur value).\nThe shadow disappears at 0.",@"ぼかしの度合い(ブロア値)。\n0のとき影は無くなる。")];
	[shadowOffsetControl setEditable:YES];
	[shadowOffsetControl setHorizontalFlipped:NO];
	[shadowOffsetControl setVerticalFlipped:NO];
	[shadowOffsetControl setContinuous:YES];
	[shadowOffsetControl setMinPoint:NSMakePoint(-1.0,-1.0)];
	[shadowOffsetControl setMaxPoint:NSMakePoint(1.0,1.0)];
	[shadowOffsetControl setToolTip:NSLocalizedString(@"Offset",@"オフセット")];
	[shadowOffsetControl setSquare:YES];
	[shadowColorTitle setStringValue:NSLocalizedStringFromTable(SKTShadowColorKey,undoTableName,@"影の色")];
	[[self window] setHidesOnDeactivate:YES];
	[[self window] setBackgroundColor:[NSColor colorWithCalibratedRed:0.55 green:0.55 blue:0.55 alpha:0.9]];
	[[self window] setOpaque:NO];
	[[self window] setDelegate:self];
	[[self window] setTitle:NSLocalizedString(@"Inspector",@"Inspector")];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mainWindowChanged:) name:NSWindowDidBecomeMainNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mainWindowResigned:) name:NSWindowDidResignMainNotification object:nil];
    /* [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(graphicChanged:) name:SKTGraphicDrawingContentsKey object:nil]; // bounds,group,ungroup,lock関係は済み // */
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(measurementUnitDidChange:) name:SKTMeasurementUnitDidChangeNotification object:nil];
}

- (void)mainWindowChanged:(NSNotification *)notification {
	[self setMainWindow:[notification object]];
}

- (void)mainWindowResigned:(NSNotification *)notification {
    [self setMainWindow:nil];
}

/* - (void)graphicChanged:(NSNotification *)notification {
	NSLog(@"graphicChanged");
    if (_inspectingGraphicView) {
		id obj = [_inspectingGraphicView valueForKey:SKTGraphicViewSelectionIndexesBindingName];
		if (nil != obj) {
            needsUpdate = YES;
        }
    }
} */

- (void)windowDidUpdate:(NSNotification *)notification
{
	if (YES == needsUpdate) {
		SKTGraphic *graphic;
		ASShadingModel *shadingModel;
		NSMutableArray *colors;
		BOOL isLocked;
		NSArray *selectedGraphics = [self selectedGraphics];
		NSUInteger c = (nil != selectedGraphics) ? [selectedGraphics count] : 0;

		needsUpdate = NO;
		[self displayArrowsOrCornerBox:selectedGraphics];
		[self displayDashPatternSymbol:selectedGraphics];
		switch (c) {
			case 0: // 何も選択されていないとき //
				[self displayFillBox:NO graphic:nil];
				[classImageView setImage:[self imageForClass:nil]];
				[smallClassImageView setImage:[self imageForClass:nil]];
				[[self window] setTitle:NSLocalizedString(@"Inspector",@"Inspector")];
				[dialKnob setEnabled:NO];
				break;
			case 1: // 1個のオブジェクトが選択されているとき //
				graphic = [selectedGraphics objectAtIndex:0];
				colors = [NSMutableArray array];
				isLocked = [graphic locked];
				if (YES == [graphic canSetDrawingFill]) {
					if (YES == [graphic isDrawingFill]) {
						if (NO == [graphic shading]) {
							[colors addObject:[graphic fillColor]];
						}
						else {
							if (nil != (shadingModel = [graphic shadingModel])) {
								[colors addObject:[shadingModel startColor]];
								[colors addObject:[shadingModel midColor]];
								[colors addObject:[shadingModel endColor]];
							}
						}
					}
					[self displayFillBox:!isLocked graphic:graphic];
				}
				else
					[self displayFillBox:NO graphic:graphic];
				[classImageView setImage:[self imageForClass:NSStringFromClass([graphic class])]];
				[smallClassImageView setImage:[self imageForClass:NSStringFromClass([graphic class])]];
				[[self window] setTitle:[NSString stringWithFormat:@"%@ %@",NSLocalizedStringFromTable(NSStringFromClass(([graphic class])),@"GraphicClassNames",@""),NSLocalizedString(@"Inspector",@"Inspector")]];
				/* [lineJoinPopUp selectItemAtIndex:[graphic lineJoin]]; // ここは手抜き。Indexと戻り値が同じとしている。 //
				 [lineCapPopUp selectItemAtIndex:[graphic lineCap]]; // ここは手抜き。Indexと戻り値が同じとしている。 // */
				[dashOffsetField setFloatValue:[graphic lineDashPhase]]; // NSNumberFormatterで単位調整 //
				[self setOffsetSliderMaxValue:[graphic lineDashPattern]];
				[dashOffsetSlider setFloatValue:[graphic lineDashPhase]];
				/* if (YES == [[graphic dashPatternString:pointsPerUnit] isEqualToString:empty])
				 [dashTemplatePopUp selectItemAtIndex:0];
				 [dashPatternField setStringValue:[graphic dashPatternString:pointsPerUnit]]; */
				/* [arrows selectItemAtIndex:[graphic arrowState]];
				 [[radiusXForm cellAtIndex:0] setFloatValue:[graphic rx]]; // NSNumberFormatterで単位調整 //
				 [[radiusYForm cellAtIndex:0] setFloatValue:[graphic ry]]; // NSNumberFormatterで単位調整 //
				 [shadowOffsetSlider setFloatValue:hypot([graphic shadowOffsetY],[graphic shadowOffsetX])];
				 [[shadowOffsetForm cellAtIndex:0] setFloatValue:hypot([graphic shadowOffsetY],[graphic shadowOffsetX])];
				 [shadowOffsetDialKnob setRadianValue:atan3([graphic shadowOffsetY], [graphic shadowOffsetX])]; */
				/* [shadowOffsetControl setMousePoint:[graphic shadowOffsetPoint]]; */
				if (NO == isLocked)
					[dialKnob setEnabled:[graphic canDrawRotate]];
				else
					[dialKnob setEnabled:NO];
				break;
			default: // 複数のオブジェクトが選択されているとき //
				[self displayFillBox:NO graphic:nil];
				[classImageView setImage:[self imageForClass:@"Multiple"]];
				[smallClassImageView setImage:[self imageForClass:@"Multiple"]];
				[[self window] setTitle:NSLocalizedString(@"Inspector",@"Inspector")];
				[dialKnob setEnabled:NO];
				break;
		}
	}
}

- (IBAction)fillColorWellAction:(id)sender
// ここでundoを実装すると、[<NSUndoManager 0x119a434f0> setValue:forUndefinedKey:]: this class is not key value coding-compliant for the key fillColor.　というエラーが発生する。 //
{
	NSArray *selectedGraphics = [self selectedGraphics];
	NSUInteger i, c = [selectedGraphics count];

    if (c > 0) {
		SKTGraphic *graphic;
		NSColor *oldColor;
		ASShadingColorOrder order;
		NSColor *newColor = [sender color];

		if (startColorWell == sender)
			order = ASStartColor;
		else {
			if (midColorWell == sender)
				order = ASMidColor;
			else
				order = ASEndColor;
		}
		for (i = 0; i < c; i++) {
			graphic = [selectedGraphics objectAtIndex:i];
			if (NO == [graphic locked]) {
				if (NO == [graphic shading]) {
					oldColor = [graphic fillColor];
					if (oldColor != newColor) {
						[graphic setValue:nil forKey:SKTPatternModelKey];
						[graphic setValue:newColor forKey:SKTGraphicFillColorKey];
					}
				}
				else {
					[graphic setShadingColor:newColor order:order];
					[graphic setValue:newColor forKey:SKTShadingColorKey]; // 描画更新とドキュメント・ダーティーのため //
				}
			}
		}
	}
}

- (IBAction)formEntryButtonAction:(id)sender
{
	NSArray *selectedGraphics = [self selectedGraphics];
	NSUInteger i, c = [selectedGraphics count];

	if (c > 0) {
		SKTGraphic *graphic;
		BOOL oldState;
		BOOL newState = (NSOnState == [sender state]) ? YES : NO;

		for (i = 0; i < c; i++) {
			graphic = [selectedGraphics objectAtIndex:i];
			if (NO == [graphic locked]) {
				oldState = [graphic formEntry];
				if (oldState != newState)
					[graphic setValue:[NSNumber numberWithBool:newState] forKey:SKTFormEntryKey];
			}
		}
	}
}

- (IBAction)imagePageUpOrDownAction:(id)sender
{
	NSArray *selectedGraphics = [self selectedGraphics];
	NSUInteger c = [selectedGraphics count];

	if (1 == c) { // locked は無関係 //
		SKTGraphic *graphic = [selectedGraphics objectAtIndex:0];
		NSInteger currentPage = [[graphic valueForKey:SKTImageCurrentPageKey] integerValue];

		if ((0 == [sender selectedSegment]) && (1 < currentPage))
			[graphic setValue:[NSNumber numberWithInteger:currentPage - 1] forKey:SKTImageCurrentPageKey];
		else {
			if ((1 == [sender selectedSegment]) && ([graphic pageCount] > currentPage))
				[graphic setValue:[NSNumber numberWithInteger:currentPage + 1] forKey:SKTImageCurrentPageKey];
		}
	}
}

- (NSImage *)imageForClass:(NSString *)aString
{
	NSImage *anImage;
	NSString *className;

	if (nil != aString)
		className = [NSString stringWithString:aString];
	else
		className = @"Null";
	if (nil == (anImage = [NSImage imageNamed:className])) {
		// classNameとicnsファイルの名称が同じならば、anImageがnilになることはない //
		NSString *path = [[NSBundle mainBundle] pathForResource:className ofType:nil]; // ファイル名はclassName以外にしても良い。ofTypeの引数はextensionであるがnilにすれば、名前が一致した最初のファイルへのpathを取得できる。 //

		NSLog(@"SKTInspectorController:Icon file of class[%@] does not exists.",className);
		if (nil != path) {
			NSImage *newImage = [[NSImage alloc] initWithContentsOfFile:path];
			if (nil != newImage) {
				[newImage setName:className];
				anImage = [NSImage imageNamed:className];
				[newImage release];
			}
			else
				anImage = [NSImage imageNamed:NSImageNameStatusNone]; // どうしようもないのでnilにする。 //
		}
		else
			anImage = [NSImage imageNamed:NSImageNameStatusNone]; // どうしようもないのでnilにする。 //
	}
	return anImage;
}

- (NSArray *)dashTemplate:(NSInteger)item
{
	NSArray *patternArray;
	NSNumber *dotLength,*spaceLength,*lineLength;
	NSArray *selectedGraphics = [self selectedGraphics];
	SKTGraphic *graphic = [selectedGraphics objectAtIndex:0];
	CGFloat lineWidth = (nil != graphic) ? [graphic strokeWidth] : (NO == [[[lineWidthForm cellAtIndex:0] stringValue] isEqualToString:@""]) ? [[lineWidthForm cellAtIndex:0] floatValue] * pointsPerUnit : 0.0;
	NSLineCapStyle lineCapKind = (nil != graphic) ? [graphic lineCap] : [lineCapPopUp selectedTag];

	switch (item) {
	case 1: // 破線 //
		lineLength = [NSNumber numberWithFloat:5.0 + 5.0 * lineWidth];
		spaceLength = [NSNumber numberWithFloat:[lineLength floatValue] / (2.0 + lineWidth / 10.0)];
		patternArray = [NSArray arrayWithObjects:lineLength,spaceLength,nil];
		break;
	case 2:	// 点線 //
	case 3:	// 一点鎖線 //
	case 4:	// 二点鎖線 //
#ifdef __APPLE__
		dotLength = [NSNumber numberWithFloat:(NSButtLineCapStyle == lineCapKind) ? lineWidth : MINIMUM_LINEWIDTH];
		if (MINIMUM_LINEWIDTH > [dotLength floatValue])
			dotLength = [NSNumber numberWithFloat:MINIMUM_LINEWIDTH];
#else
		dotLength = [NSNumber numberWithFloat:(NSButtLineCapStyle == lineCapKind) ? lineWidth : 0.0];
#endif
		lineLength = [NSNumber numberWithFloat:15.0 + 15.0 * lineWidth];
		if (1.0 > lineWidth)
			spaceLength = [NSNumber numberWithFloat:3.0];
		else {
			if (2.0 > lineWidth)
				spaceLength = [NSNumber numberWithFloat:4.0];
			else
				spaceLength = [NSNumber numberWithFloat:(NSButtLineCapStyle == lineCapKind) ? lineWidth : 2.0 * lineWidth];
		}
		switch (item) {
		case 3:
			patternArray = [NSArray arrayWithObjects:lineLength,spaceLength,dotLength,spaceLength,nil];
			break;
		case 4:
			patternArray = [NSArray arrayWithObjects:lineLength,spaceLength,dotLength,spaceLength,dotLength,spaceLength,nil];
			break;
		default:	// 点線 //
			patternArray = [NSArray arrayWithObjects:dotLength,spaceLength,nil];
			break;
		}
		break;
	default: // 実線 //
		patternArray = [NSArray array];
		break;
	}
	return patternArray;
}

- (IBAction)setDashTemplate:(id)sender
{
	if ((0 < [[self selectedGraphics] count]) && (NO == [[[self selectedGraphics] objectAtIndex:0] locked])) {
		NSArray *pArray = [self dashTemplate:[sender indexOfSelectedItem]];

		[[[self selectedGraphics] objectAtIndex:0] setValue:pArray forKey:SKTLineDashPatternKey];
		/* [dashPatternField setStringValue:[self patternStringFrom:pArray]];
		[self changeDashPattern:dashPatternField]; */
		// dashTemplatePopUpのメニュー更新。タイミングとしてはlineCapPopUpを変更したときにやらなければならないが、bind:でやらせているので無理。しかたないのでここでやる。 //
		[dashOffsetButton performClick:sender];
	}
}

- (IBAction)setOptimalOffset:(id)sender
{
	SKTGraphic *graphic = [[self selectedGraphics] objectAtIndex:0];
	if ((nil != graphic) && (NO == [graphic locked])) {
		NSArray *pattern = [graphic lineDashPattern];
		NSUInteger patternCount = (nil != pattern) ? [pattern count] : 0;

		if (0 < patternCount) {
			NSUInteger i,n;
			CGFloat patternLength,endpart,offset;
			NSRect lineBounds = [graphic bounds];
			CGFloat pathLen = hypot(NSWidth(lineBounds), NSHeight(lineBounds)); // この計算では直線パスにしか対応できない。 //
			// 以下の注釈は「PostScriptチュートリアルブック」の例題のスクリプト //
			CGFloat first = [[pattern objectAtIndex:0] floatValue]; // /first pattern 0 get def //
			CGFloat last = 0.0;

			if (1 < patternCount) {
				for (i = 1; i < patternCount; i++)
					last += [[pattern objectAtIndex:i] floatValue];
			}
			patternLength = first + last; // /last patternlength first sub def //
			if (0 != patternCount % 2) // patternlength 2 mod 0 ne { patternlength patternlength 2 mul def } if //
				patternLength *= 2.0;
			if (pathLen > last) { // 「PostScriptチュートリアルブック」に無い判断 //
				n = (NSUInteger)floor((pathLen - last) / patternLength); // /n pathlen last sub patternlength idiv def //
				endpart = 0.5 * (pathLen - (patternLength * (CGFloat)n) - last); // /endpart pathlen patternlength n mul sub last sub 2 div def //
				offset = first - endpart; // /offset first endpart sub def //
				if (0.0 > offset)
					offset += patternLength;
			}
			else
				offset = 0.0;
			[graphic setValue:[NSNumber numberWithFloat:offset] forKey:SKTLineDashPhaseKey];
		}
	}
}

- (void)setOffsetSliderMaxValue:(NSArray *)pattern
{
	if ((nil != pattern) && (0 < [pattern count])) {
		NSUInteger i;
		CGFloat patternLength = 0.0;

		for (i = 0; i < [pattern count]; i++)
			patternLength += [[pattern objectAtIndex:i] floatValue];
		[dashOffsetSlider setMaxValue:patternLength]; // point単位 //
	}
	else
		[dashOffsetSlider setMaxValue:100.0]; // point単位 //
}

- (NSDictionary *)displayedValues
{
	NSMutableDictionary *returnDic = [NSMutableDictionary dictionary];
	[returnDic setObject:[NSNumber numberWithFloat:(nil == lineWidthForm) ? DefaultLineWidth : [[lineWidthForm cellAtRow:0 column:0] floatValue]] forKey:InspectorLineWidth]; // NSNumberFormatterで単位調整 //
	return returnDic;
}

- (IBAction)shadingStyleAction:(id)sender
{
	/* ASShadingStyle shadingStyle = NSNotFound; */
	NSInteger shadingStyle = NSNotFound;
	NSInteger row = [sender indexOfSelectedItem];

	switch (row) {
		case 1:
			shadingStyle = ASNoneShading;
			break;
		case 2:
			shadingStyle = ASAxialShading;
			break;
		case 3:
			shadingStyle = ASRadialShading;
			break;
		case 4:
			shadingStyle = ASDoubleAxialShading;
			break;
		case 5:
			shadingStyle = ASDoubleRadialShading;
			break;
		default:
			shadingStyle = NSNotFound;
			break;
	}
	SKTGraphic *graphic;
	NSArray *selectedGraphics = [self selectedGraphics];
	NSUInteger i, c = [selectedGraphics count];

	if (c > 0) {
		if (NSNotFound != shadingStyle) {
			for (i = 0; i < c; i++) {
				graphic = [selectedGraphics objectAtIndex:i];
				if (NO == [graphic locked])
					[graphic setValue:[NSNumber numberWithInteger:shadingStyle] forKey:SKTShadingStyleKey];
			}
		}
		else {
			for (i = 0; i < c; i++) {
				graphic = [selectedGraphics objectAtIndex:i];
				if (NO == [graphic locked])
					[graphic setValue:[NSNumber numberWithBool:NO] forKey:SKTGraphicIsDrawingFillKey];
			}
		}
		[self displayFillBox:YES graphic:[selectedGraphics objectAtIndex:0]];
	}
}
- (IBAction)colorPositionAction:(id)sender
{
	NSArray *selectedGraphics = [self selectedGraphics];
	NSUInteger i, c = [selectedGraphics count];
	
	if (c > 0) {
		SKTGraphic *graphic;
		CGFloat newPosition = [sender floatValue];

		for (i = 0; i < c; i++) {
			graphic = [selectedGraphics objectAtIndex:i];
			if ((NO == [graphic locked]) && (nil != [graphic shadingModel]))
				[graphic setValue:[NSArray arrayWithObjects:[NSNumber numberWithFloat:0.0],[NSNumber numberWithFloat:newPosition],[NSNumber numberWithFloat:1.0],nil] forKey:SKTShadingColorPositionKey];
		}
	}
}

- (IBAction)showHelp:(id)sender
{
	NSString *locBookName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleHelpBookName"];
	[[NSHelpManager sharedHelpManager] openHelpAnchor:@"Window_InspectorPanel" inBook:locBookName];
}

@end
