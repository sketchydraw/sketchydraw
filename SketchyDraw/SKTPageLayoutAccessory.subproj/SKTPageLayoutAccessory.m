//
//  SKTPageLayoutAccessory.m
//  SketchyDraw
//
//  Created by 佐藤 昭 on 平成 20/08/30.
//  Copyright 2008 SatoAkira. All rights reserved.
//

#import "SKTPageLayoutAccessory.h"
#import "PreferencesController.h" // for MeasurementUnit //

static NSString *PageLayoutLeftMarginKey = @"leftMargin";
static NSString *PageLayoutRightMarginKey = @"rightMargin";
static NSString *PageLayoutTopMarginKey = @"topMargin";
static NSString *PageLayoutBottomMarginKey = @"bottomMargin";
static NSString *PageLayoutHeaderAndFooterKey = @"headerAndFooter";
static NSString *PageLayoutImageableAreaOriginXKey = @"imageableAreaOriginX";
static NSString *PageLayoutImageableAreaOriginYKey = @"imageableAreaOriginY";
static NSString *PageLayoutLeftSpaceKey = @"leftSpace";
static NSString *PageLayoutBottomSpaceKey = @"bottomSpace";
static NSString *PageLayoutRightSpaceKey = @"rightSpace";
static NSString *PageLayoutTopSpaceKey = @"topSpace";


@implementation SKTPageLayoutAccessory

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [super initWithNibName:NSStringFromClass([self class]) bundle:nibBundleOrNil];
}
- (void)dealloc
{
	[super dealloc];
}
- (NSDictionary *)pointsPerUnit {
	return [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:28.35],@"cm",[NSNumber numberWithDouble:72.0],@"inch",[NSNumber numberWithDouble:12.0],@"pica",[NSNumber numberWithDouble:1.0],@"point",nil];
}
- (void)awakeFromNib
// setRepresentedObjectより前に呼ばれる。 //
{
	NSString *tableName = @"SKTPageLayoutAccessory";
	NSString *defaultUnit = (nil != [[NSUserDefaults standardUserDefaults] objectForKey:MeasurementUnitKey]) ? [[NSUserDefaults standardUserDefaults] objectForKey:MeasurementUnitKey] : @"point"; // point,mm,inch,pica //

	[[imageableAreaOriginForm cellAtIndex:0] bind:NSValueBinding toObject:self withKeyPath:PageLayoutImageableAreaOriginXKey options:[NSDictionary dictionary]];
	[[imageableAreaOriginForm cellAtIndex:1] bind:NSValueBinding toObject:self withKeyPath:PageLayoutImageableAreaOriginYKey options:[NSDictionary dictionary]];
	[[widthSpaceForm cellAtIndex:0] bind:NSValueBinding toObject:self withKeyPath:PageLayoutLeftSpaceKey options:[NSDictionary dictionary]];
	[[widthSpaceForm cellAtIndex:1] bind:NSValueBinding toObject:self withKeyPath:PageLayoutRightSpaceKey options:[NSDictionary dictionary]];
	[[heightSpaceForm cellAtIndex:0] bind:NSValueBinding toObject:self withKeyPath:PageLayoutTopSpaceKey options:[NSDictionary dictionary]];
	[[heightSpaceForm cellAtIndex:1] bind:NSValueBinding toObject:self withKeyPath:PageLayoutBottomSpaceKey options:[NSDictionary dictionary]];
	[unitsPopUp removeAllItems];
	[unitsPopUp addItemsWithTitles:[[self pointsPerUnit] allKeys]];
	[unitsPopUp selectItemWithTitle:(YES == [defaultUnit isEqualToString:@"mm"]) ? @"cm" : defaultUnit];
	[self changeUnits:unitsPopUp];
	[marginBox setTitle:NSLocalizedStringFromTable(@"Margin",tableName,@"")];
	[[leftMarginForm cellAtIndex:0] setTitle:NSLocalizedStringFromTable(@"Left",tableName,@"")];
	[[rightMarginForm cellAtIndex:0] setTitle:NSLocalizedStringFromTable(@"Right",tableName,@"")];
	[[topMarginForm cellAtIndex:0] setTitle:NSLocalizedStringFromTable(@"Top",tableName,@"")];
	[[bottomMarginForm cellAtIndex:0] setTitle:NSLocalizedStringFromTable(@"Bottom",tableName,@"")];
	[imageableAreaOriginForm setToolTip:NSLocalizedStringFromTable(@"The origin is in the lower-left corner of the orientated sheet.",tableName,@"原点はシートの左下隅にあります。")];
	[[imageableAreaOriginForm cellAtIndex:0] setTitle:NSLocalizedStringFromTable(PageLayoutImageableAreaOriginXKey,tableName,@"原点のX座標")];
	[[imageableAreaOriginForm cellAtIndex:1] setTitle:NSLocalizedStringFromTable(PageLayoutImageableAreaOriginYKey,tableName,@"原点のY座標")];
	[[widthSpaceForm cellAtIndex:0] setTitle:NSLocalizedStringFromTable(PageLayoutLeftSpaceKey,tableName,@"")];
	[[widthSpaceForm cellAtIndex:1] setTitle:NSLocalizedStringFromTable(PageLayoutRightSpaceKey,tableName,@"")];
	[[heightSpaceForm cellAtIndex:0] setTitle:NSLocalizedStringFromTable(PageLayoutTopSpaceKey,tableName,@"")];
	[[heightSpaceForm cellAtIndex:1] setTitle:NSLocalizedStringFromTable(PageLayoutBottomSpaceKey,tableName,@"")];
	[[leftMarginForm cellAtIndex:0] setSendsActionOnEndEditing:YES];
	[[rightMarginForm cellAtIndex:0] setSendsActionOnEndEditing:YES];
	[[topMarginForm cellAtIndex:0] setSendsActionOnEndEditing:YES];
	[[bottomMarginForm cellAtIndex:0] setSendsActionOnEndEditing:YES];
	[leftMarginForm calcSize];
	[rightMarginForm calcSize];
	[topMarginForm calcSize];
	[bottomMarginForm calcSize];
	[imageableAreaOriginForm calcSize];
	[widthSpaceForm calcSize];
	[heightSpaceForm calcSize];
	[headerAndFooterSwitch setTitle:NSLocalizedStringFromTable(@"HeaderAndFooter",tableName,@"")];
}

- (void)setRepresentedObject:(id)printInfo
// printInfoがnilになることはないようだ。 //
{
	[super setRepresentedObject:printInfo];
	if (nil != printInfo) {
		NSNumber *hAndFNumber = [[printInfo dictionary] objectForKey:NSPrintHeaderAndFooter]; // printInfoがnilでなくてもNSPrintHeaderAndFooterの値がnilのときがある。 //
		BOOL hAndF = (nil != hAndFNumber) ? [hAndFNumber boolValue] : NO;
		NSRect imageable = [printInfo imageablePageBounds];
		[self setValue:[NSNumber numberWithDouble:[printInfo leftMargin]] forKey:PageLayoutLeftMarginKey];
		[self setValue:[NSNumber numberWithDouble:[printInfo rightMargin]] forKey:PageLayoutRightMarginKey];
		[self setValue:[NSNumber numberWithDouble:[printInfo topMargin]] forKey:PageLayoutTopMarginKey];
		[self setValue:[NSNumber numberWithDouble:[printInfo bottomMargin]] forKey:PageLayoutBottomMarginKey];
		[self setValue:[NSNumber numberWithBool:hAndF] forKey:PageLayoutHeaderAndFooterKey];
		[self setValue:[NSNumber numberWithDouble:NSMinX(imageable)] forKey:PageLayoutImageableAreaOriginXKey];
		[self setValue:[NSNumber numberWithDouble:NSMinY(imageable)] forKey:PageLayoutImageableAreaOriginYKey];
		[self setValue:[NSNumber numberWithDouble:[printInfo leftMargin] - NSMinX(imageable)] forKey:PageLayoutLeftSpaceKey];
		[self setValue:[NSNumber numberWithDouble:[printInfo rightMargin] - [printInfo paperSize].width + NSMaxX(imageable)] forKey:PageLayoutRightSpaceKey];
		[self setValue:[NSNumber numberWithDouble:[printInfo topMargin] - [printInfo paperSize].height + NSMaxY(imageable)] forKey:PageLayoutTopSpaceKey];
		[self setValue:[NSNumber numberWithDouble:[printInfo bottomMargin] - NSMinY(imageable)] forKey:PageLayoutBottomSpaceKey];
		[layoutView setPaperSize:[printInfo paperSize]];
		[layoutView setLeftMargin:[printInfo leftMargin]];
		[layoutView setRightMargin:[printInfo rightMargin]];
		[layoutView setTopMargin:[printInfo topMargin]];
		[layoutView setBottomMargin:[printInfo bottomMargin]];
	}
	else
		NSLog(@"printInfo is nil in SKTPageLayoutAccessory.");
}

- (void)setLeftMargin:(CGFloat)aNumber {
	NSPrintInfo *printInfo = [self representedObject];
	NSRect imageable = [printInfo imageablePageBounds];
	_leftMargin = aNumber;
	[self setValue:[NSNumber numberWithDouble:aNumber - NSMinX(imageable)] forKey:PageLayoutLeftSpaceKey];
	[printInfo setLeftMargin:aNumber];
	[layoutView setLeftMargin:aNumber];
	[layoutView setNeedsDisplay:YES];
}
- (void)setRightMargin:(CGFloat)aNumber {
	NSPrintInfo *printInfo = [self representedObject];
	NSRect imageable = [printInfo imageablePageBounds];
	_rightMargin = aNumber;
	[self setValue:[NSNumber numberWithDouble:aNumber - [printInfo paperSize].width + NSMaxX(imageable)] forKey:PageLayoutRightSpaceKey];
	[printInfo setRightMargin:aNumber];
	[layoutView setRightMargin:aNumber];
	[layoutView setNeedsDisplay:YES];
}
- (void)setTopMargin:(CGFloat)aNumber {
	NSPrintInfo *printInfo = [self representedObject];
	NSRect imageable = [printInfo imageablePageBounds];
	_topMargin = aNumber;
	[self setValue:[NSNumber numberWithDouble:aNumber - [printInfo paperSize].height + NSMaxY(imageable)] forKey:PageLayoutTopSpaceKey];
	[printInfo setTopMargin:aNumber];
	[layoutView setTopMargin:aNumber];
	[layoutView setNeedsDisplay:YES];
}
- (void)setBottomMargin:(CGFloat)aNumber {
	NSPrintInfo *printInfo = [self representedObject];
	NSRect imageable = [printInfo imageablePageBounds];
	_bottomMargin = aNumber;
	[self setValue:[NSNumber numberWithDouble:aNumber - NSMinY(imageable)] forKey:PageLayoutBottomSpaceKey];
	[printInfo setBottomMargin:aNumber];
	[layoutView setBottomMargin:aNumber];
	[layoutView setNeedsDisplay:YES];
}
- (void)setHeaderAndFooter:(BOOL)flag {
    NSPrintInfo *printInfo = [self representedObject];
	_headerAndFooter = flag;
    [[printInfo dictionary] setObject:[NSNumber numberWithBool:flag] forKey:NSPrintHeaderAndFooter];
}

- (IBAction)changeUnits:(id)sender
{
	NSString *units = [sender titleOfSelectedItem];
	NSNumber *ppu = [[self pointsPerUnit] objectForKey:units];
	NSNumber *_ppu = [NSNumber numberWithDouble:1.0 / [ppu doubleValue]];
	NSNumberFormatter *sizeFormatter = [[NSNumberFormatter alloc] init];
	NSString *tableName = @"SKTPageLayoutAccessory";
	NSString *sizeFormat = [NSString stringWithFormat:@"#,##0.000;0.000;%@-#,##0.000",NSLocalizedStringFromTable(@"THUMBS DOWN SIGN",tableName,@"👎")];

	[sizeFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
	[sizeFormatter setFormat:sizeFormat];
	[sizeFormatter setMultiplier:_ppu];
	[[leftMarginForm cellAtIndex:0] setFormatter:sizeFormatter];
	[[rightMarginForm cellAtIndex:0] setFormatter:sizeFormatter];
	[[topMarginForm cellAtIndex:0] setFormatter:sizeFormatter];
	[[bottomMarginForm cellAtIndex:0] setFormatter:sizeFormatter];
	[[imageableAreaOriginForm cellAtIndex:0] setFormatter:sizeFormatter];
	[[imageableAreaOriginForm cellAtIndex:1] setFormatter:sizeFormatter];
	[[widthSpaceForm cellAtIndex:0] setFormatter:sizeFormatter];
	[[widthSpaceForm cellAtIndex:1] setFormatter:sizeFormatter];
	[[heightSpaceForm cellAtIndex:0] setFormatter:sizeFormatter];
	[[heightSpaceForm cellAtIndex:1] setFormatter:sizeFormatter];
	[sizeFormatter release];
	[leftMarginForm setNeedsDisplay:YES];
	[rightMarginForm setNeedsDisplay:YES];
	[topMarginForm setNeedsDisplay:YES];
	[bottomMarginForm setNeedsDisplay:YES];
	[imageableAreaOriginForm setNeedsDisplay:YES];
	[widthSpaceForm setNeedsDisplay:YES];
	[heightSpaceForm setNeedsDisplay:YES];
}

- (NSForm *)leftMarginForm {
	return leftMarginForm;
}
- (NSForm *)rightMarginForm {
	return rightMarginForm;
}
- (NSForm *)topMarginForm {
	return topMarginForm;
}
- (NSForm *)bottomMarginForm {
	return bottomMarginForm;
}
- (NSPopUpButton *)unitsPopUp {
    return unitsPopUp;
}
- (SKTPageLayoutAccessoryView *)layoutView {
	return layoutView;
}
- (NSButton *)headerAndFooterSwitch {
	return headerAndFooterSwitch;
}
/* - (BOOL)commitEditing
{
	NSLog(@"commitEditing"); // 抜けて行くときまたは、表示されていて、かつOKボタンがクリックされたときに呼ばれる。 //
	return YES;
}
- (void)discardEditing
// 表示されていて、かつキャンセルボタンがクリックされたときに呼ばれる。 //
{
	NSLog(@"discardEditing");
}
- (void)scrollWheel:(NSEvent *)theEvent
{
	NSLog(@"scrollWheel");
}
- (BOOL)validateProposedFirstResponder:(NSResponder *)responder forEvent:(NSEvent *)event
{
	NSLog(@"validate");
	return YES;
} */
- (void)cursorUpdate:(NSEvent *)event
// cursorUpdate:を使うのには意味が無い。ただ画面に表示されるときに呼び出されるからである。 //
{
	[super cursorUpdate:event];
	NSPrintInfo *printInfo = [self representedObject];
	NSRect imageable = [[self representedObject] imageablePageBounds];
	
	[self setValue:[NSNumber numberWithDouble:NSMinX(imageable)] forKey:PageLayoutImageableAreaOriginXKey];
	[self setValue:[NSNumber numberWithDouble:NSMinY(imageable)] forKey:PageLayoutImageableAreaOriginYKey];
	[self setValue:[NSNumber numberWithDouble:[printInfo leftMargin] - NSMinX(imageable)] forKey:PageLayoutLeftSpaceKey];
	[self setValue:[NSNumber numberWithDouble:[printInfo rightMargin] - [printInfo paperSize].width + NSMaxX(imageable)] forKey:PageLayoutRightSpaceKey];
	[self setValue:[NSNumber numberWithDouble:[printInfo topMargin] - [printInfo paperSize].height + NSMaxY(imageable)] forKey:PageLayoutTopSpaceKey];
	[self setValue:[NSNumber numberWithDouble:[printInfo bottomMargin] - NSMinY(imageable)] forKey:PageLayoutBottomSpaceKey];
	[layoutView setPaperSize:[printInfo paperSize]];
	[layoutView setLeftMargin:[printInfo leftMargin]];
	[layoutView setRightMargin:[printInfo rightMargin]];
	[layoutView setTopMargin:[printInfo topMargin]];
	[layoutView setBottomMargin:[printInfo bottomMargin]];
	[layoutView setNeedsDisplay:YES];
}

@end
