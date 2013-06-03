/*
     File: SKTGraphic.m
 Abstract: The base class for Sketch graphics objects.
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

#import "SKTGraphic.h"
#import "SKTError.h"
#import "SKTFoundationExtras.h" // SatoAkira add. //


// String constants declared in the header. A lot of them aren't used by any other class in the project, but it's a good idea to provide and use them, if only to help prevent typos in source code.
// Why are there @"drawingFill" and @"drawingStroke" keys here when @"isDrawingFill" and @"isDrawingStroke" would be a little more consistent with Cocoa convention for boolean values? Because we might want to add setter methods for these properties some day, and key-value coding isn't smart enough to ignore "is" when looking for setter methods, and having to give methods ugly names -setIsDrawingFill: and -setIsDrawingStroke: would be irritating. In general it's best to leave the "is" off the front of keys that identify boolean values.
NSString *SKTGraphicCanSetDrawingFillKey = @"canSetDrawingFill";
NSString *SKTGraphicCanSetDrawingStrokeKey = @"canSetDrawingStroke";
NSString *SKTGraphicIsDrawingFillKey = @"drawingFill";
NSString *SKTGraphicFillColorKey = @"fillColor";
NSString *SKTGraphicIsDrawingStrokeKey = @"drawingStroke";
NSString *SKTGraphicStrokeColorKey = @"strokeColor";
NSString *SKTGraphicStrokeWidthKey = @"strokeWidth";
NSString *SKTGraphicXPositionKey = @"xPosition";
NSString *SKTGraphicYPositionKey = @"yPosition";
NSString *SKTGraphicWidthKey = @"width";
NSString *SKTGraphicHeightKey = @"height";
NSString *SKTGraphicBoundsKey = @"bounds";
NSString *SKTGraphicDrawingBoundsKey = @"drawingBounds";
NSString *SKTGraphicDrawingContentsKey = @"drawingContents";
NSString *SKTGraphicKeysForValuesToObserveForUndoKey = @"keysForValuesToObserveForUndo";
// ↓SatoAkira add. //
NSString *SKTWindingRuleKey = @"windingRule";
NSString *SKTLineCapKey = @"lineCap";
NSString *SKTLineJoinKey = @"lineJoin";
NSString *SKTArrowStateKey = @"arrowState";
NSString *SKTArrowStyleKey = @"arrowStyle";
NSString *SKTFormEntryKey = @"formEntry";
NSString *SKTLocalizeFormEntryKey = @"localizeFormEntry";
NSString *SKTLockedKey = @"locked";
NSString *SKTRotateAngleKey = @"rotateAngle";
NSString *SKTShadowOffsetPointKey = @"shadowOffsetPoint";
NSString *SKTShadowBlurRadiusKey = @"shadowBlurRadiusValue";
NSString *SKTShadowColorKey = @"shadowColor";
NSString *SKTLineDashPhaseKey = @"lineDashPhase";
NSString *SKTLineDashPatternKey = @"lineDashPattern";
NSString *SKTShadingKey = @"shading";
NSString *SKTShadingModelKey = @"shadingModel";
NSString *SKTShadingStyleKey = @"shadingStyle";
NSString *SKTShadingAxialAngleKey = @"shadingAxialAngle";
NSString *SKTShadingColorPositionKey = @"shadingColorPosition";
NSString *SKTShadingRadialCenterKey = @"shadingRadialCenter";
NSString *SKTShadingColorKey = @"shadingColor";
NSString *SKTPatternModelKey = @"patternModel";
NSString *SKTCreatedPointsKey = @"createdPoints";
NSString *SKTPointsKey = @"points";
NSString *SKTCreatedBoundsKey = @"createdBounds";
NSString *SKTTestUndoKey = @"testUndo";
NSString *SKTImageCurrentPageKey = @"currentPage";
NSString *SKTIsSquareBoundsKey = @"isSquareBounds";
static NSString *SKTBoundsKey = @"Bounds"; // for sktd //
static NSString *SKTDrawsFillKey = @"DrawsFill"; // for sktd //
static NSString *SKTFillColorKey = @"FillColor"; // for sktd //
static NSString *SKTDrawsStrokeKey = @"DrawsStroke"; // for sktd //
static NSString *SKTStrokeColorKey = @"StrokeColor"; // for sktd //
static NSString *SKTStrokeLineWidthKey = @"StrokeLineWidth"; // for sktd //
static NSString *SKTWindingRuleSKTDKey = @"WindingRule"; // for sktd //
static NSString *SKTLineCapSKTDKey = @"LineCap"; // for sktd //
static NSString *SKTLineJoinSKTDKey = @"LineJoin"; // for sktd //
static NSString *SKTArrowAtStartKey = @"ArrowAtStart"; // for sktd //
static NSString *SKTArrowAtEndKey = @"ArrowAtEnd"; // for sktd //
static NSString *SKTArrowStyleSKTDKey = @"ArrowStyle"; // for sktd //
static NSString *SKTFormEntrySKTDKey = @"IsFormEntry"; // for Draw.app,sktd //
static NSString *SKTLocalizeFormEntrySKTDKey = @"LocalizeFormEntry"; // for Draw.app,sktd //
static NSString *SKTLockedSKTDKey = @"Locked"; // for sktd //
static NSString *SKTDashPatternSKTDKey = @"SetDashPattern"; // for sktd //
static NSString *SKTRotateAngleSKTDKey = @"RotateAngle"; // for sktd //
static NSString *SKTShadowOffsetSKTDKey = @"ShadowOffset"; // for sktd //
static NSString *SKTShadowBlurRadiusSKTDKey = @"ShadowBlurRadius"; // for sktd //
static NSString *SKTShadowColorSKTDKey = @"ShadowColor"; // for sktd //
static NSString *SKTShadingSKTDKey = @"Shading"; // for sktd //
static NSString *SKTShadingModelSKTDKey = @"ShadingModel"; // for sktd //
static NSString *SKTShadowOffsetXKey = @"shadowOffsetX"; // for skt3旧バージョン //
static NSString *SKTShadowOffsetYKey = @"shadowOffsetY"; // for skt3旧バージョン //
// ↑SatoAkira add. //

// Another constant that's declared in the header.
const NSInteger SKTGraphicNoHandle = 0;

// A key that's used in Sketch's property-list-based file and pasteboard formats.
/* static NSString *SKTGraphicClassNameKey = @"className"; */ // SatoAkira delete. //
NSString *SKTGraphicClassNameKey = @"className"; // SatoAkira add. //
static NSString *SKTClassKey = @"Class"; // SatoAkira add. for sktd //

/* // The values that might be returned by -[SKTGraphic creationSizingHandle] and -[SKTGraphic handleUnderPoint:], and that are understood by -[SKTGraphic resizeByMovingHandle:toPoint:]. We provide specific indexes in this enumeration so make sure none of them are zero (that's SKTGraphicNoHandle) and to make sure the flipping arrays in -[SKTGraphic resizeByMovingHandle:toPoint:] work.
enum {
    SKTGraphicUpperLeftHandle = 1,
    SKTGraphicUpperMiddleHandle = 2,
    SKTGraphicUpperRightHandle = 3,
    SKTGraphicMiddleLeftHandle = 4,
    SKTGraphicMiddleRightHandle = 5,
    SKTGraphicLowerLeftHandle = 6,
    SKTGraphicLowerMiddleHandle = 7,
    SKTGraphicLowerRightHandle = 8,
}; */ // SatoAkira delete. //

// The handles that graphics draw on themselves are 6 point by 6 point rectangles.
static CGFloat SKTGraphicHandleWidth = 6.0f;
static CGFloat SKTGraphicHandleHalfWidth = 6.0f / 2.0f;


@implementation SKTGraphic


- (void)dashPatternConvert:(NSInteger)direction propertyList:(id)plist
// SatoAkira add. for sktd //
{
	if (1 == direction) {
		NSArray *setDashValues;

		setDashValues = [plist objectForKey:SKTDashPatternSKTDKey];
		[_lineDashPattern release];
		if ((nil != setDashValues) && (0 < [setDashValues count])) {
			NSUInteger patternSize;
			_lineDashPhase = [[setDashValues objectAtIndex:0] floatValue];
			if (0 < (patternSize = [setDashValues count] - 1)) {
				NSUInteger j;
				NSMutableArray *tempPattern = [NSMutableArray array];

				for (j = 1; j <= patternSize; j++)
					[tempPattern addObject:[NSNumber numberWithFloat:[[setDashValues objectAtIndex:j] floatValue]]];
				_lineDashPattern = [[NSArray alloc] initWithArray:tempPattern];
			}
			else
				_lineDashPattern = [[NSArray array] retain];
		}
		else {
			_lineDashPhase = 0.0;
			_lineDashPattern = [[NSArray array] retain];
		}
	}
}
static void addDashStyleToPath(NSBezierPath *path,NSArray *pattern,CGFloat phase)
// SatoAkira add. pathがnilは許されない。patternはnilでも空配列でも良い。 //
{
	NSUInteger count;
	if ((nil != pattern) && (0 < (count = [pattern count]))) {
		CGFloat *p = malloc(count * sizeof(CGFloat));
		for (NSNumber *pNumber in pattern)
			*p++ = [pNumber floatValue];
		p -= count;
		[path setLineDash:p count:count phase:phase];
		free(p);
	}
	else
		[path setLineDash:(CGFloat *)NULL count:0 phase:0.0];
}
// An override of the superclass' designated initializer.
- (id)init {

    // Do the regular Cocoa thing.
    self = [super init];
    if (self) {
	
	// Set up decent defaults for a new graphic.
	_bounds = NSZeroRect;
	_isDrawingFill = NO;
	_fillColor = [[NSColor whiteColor] retain];
	_isDrawingStroke = YES;
	_strokeColor = [[NSColor blackColor] retain];
	_strokeWidth = 1.0f;
		// ↓SatoAkira add. //
		_windingRule = NSNonZeroWindingRule;
		_lineJoin = NSMiterLineJoinStyle;
		_lineCap = NSButtLineCapStyle;
		_arrowState = SKTArrowNone;
		_arrowStyle = 0;
		_formEntry = NO;
		_localizeFormEntry = NO;
		_locked = NO;
		_rotateAngle = 0.0;
		_lineDashPhase = 0.0;
		_lineDashPattern = [[NSArray array] retain];
		_shadowOffsetPoint = NSZeroPoint;
		_shadowBlurRadiusValue = 0.0;
		_shadowColor = [[NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.0 alpha:1.0] retain];
		_shading = NO;
		_shadingModel = nil;
		_patternModel = nil;
		_currentPage = 1;
		_editingView = nil;
		_isSquareBounds = NO;
		// ↑SatoAkira add. //
    }
    return self;
    
}


// Conformance to the NSCopying protocol. SKTGraphics are copyable for the sake of scriptability.
- (id)copyWithZone:(NSZone *)zone {

    // Pretty simple, but there's plenty of opportunity for mistakes. We use [self class] instead of SKTGraphic so that overrides of this method can invoke super. We copy instead of retaining the fill and stroke color even though it probably doesn't make a difference because that's the correct thing to do for attributes (to-one relationships, that's another story). We don't copy _scriptingContainer because the copy doesn't have any scripting container until it's added to one.
    SKTGraphic *copy = [[[self class] alloc] init];
    copy->_bounds = _bounds;
    copy->_isDrawingFill = _isDrawingFill;
    copy->_fillColor = [_fillColor copy];
    copy->_isDrawingStroke = _isDrawingStroke;
    copy->_strokeColor = [_strokeColor copy];
    copy->_strokeWidth = _strokeWidth;
	// ↓SatoAkira add. //
	copy->_windingRule = _windingRule;
	copy->_lineJoin = _lineJoin;
	copy->_lineCap = _lineCap;
	copy ->_arrowState = _arrowState;
	copy->_arrowStyle = _arrowStyle;
	copy->_formEntry = _formEntry;
	copy->_localizeFormEntry = _localizeFormEntry;
	copy->_locked = _locked;
	copy->_rotateAngle = _rotateAngle;
	copy->_lineDashPhase = _lineDashPhase;
	copy->_lineDashPattern = [_lineDashPattern copy];
	copy->_shadowOffsetPoint = _shadowOffsetPoint;
	copy->_shadowBlurRadiusValue = _shadowBlurRadiusValue;
	copy->_shadowColor = (nil != _shadowColor) ? [_shadowColor copy] : nil;
	copy->_shading = _shading; // setShadingModel:の前でなければならない。 //
	[copy setShadingModel:_shadingModel];
	copy->_currentPage = _currentPage;
	// ↑SatoAkira add. //
    return copy;

}


- (void)dealloc {

    // Do the regular Cocoa thing.
    [_strokeColor release];
    [_fillColor release];
	// ↓SatoAkira add. //
	[_lineDashPattern release];
	[_shadowColor release];
	[_shadingModel release];
	[_patternModel release];
	// ↑SatoAkira add. //
    [super dealloc];

}


#pragma mark *** Private KVC-Compliance for Public Properties ***


// An override of the NSObject(NSKeyValueObservingCustomization) method.
+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {

    // We don't want KVO autonotification for these properties. Because the setters for all of them invoke -setBounds:, and this class is KVO-compliant for "bounds," and we declared that the values of these properties depend on "bounds," we would up end up with double notifications for them. That would probably be unnoticable, but it's a little wasteful. Something you have to think about with codependent mutable properties like these (regardless of what notification mechanism you're using).
    BOOL automaticallyNotifies;
    if ([[NSSet setWithObjects:SKTGraphicXPositionKey, SKTGraphicYPositionKey, SKTGraphicWidthKey, SKTGraphicHeightKey, nil] containsObject:key]) {
	automaticallyNotifies = NO;
    } else {
	automaticallyNotifies = [super automaticallyNotifiesObserversForKey:key];
    }
    return automaticallyNotifies;

}


// In Mac OS 10.5 and newer KVO's dependency mechanism invokes class methods to find out what properties affect properties being observed, like these.
+ (NSSet *)keyPathsForValuesAffectingXPosition {
    return [NSSet setWithObject:SKTGraphicBoundsKey];
}
+ (NSSet *)keyPathsForValuesAffectingYPosition {
    return [NSSet setWithObject:SKTGraphicBoundsKey];
}
+ (NSSet *)keyPathsForValuesAffectingWidth {
    return [NSSet setWithObject:SKTGraphicBoundsKey];
}
+ (NSSet *)keyPathsForValuesAffectingHeight {
    return [NSSet setWithObject:SKTGraphicBoundsKey];
}
- (CGFloat)xPosition {
    return [self bounds].origin.x;
}
- (CGFloat)yPosition {
    return [self bounds].origin.y;
}
- (CGFloat)width {
    return [self bounds].size.width;
}
- (CGFloat)height {
    return [self bounds].size.height;
}
- (void)setXPosition:(CGFloat)xPosition {
	if (NO == _locked) { // SatoAkira add. //
    NSRect bounds = [self bounds];
    bounds.origin.x = xPosition;
    [self setBounds:bounds];
	} // SatoAkira add. //
}
- (void)setYPosition:(CGFloat)yPosition {
	if (NO == _locked) { // SatoAkira add. //
    NSRect bounds = [self bounds];
    bounds.origin.y = yPosition;
    [self setBounds:bounds];
	} // SatoAkira add. //
}
- (void)setWidth:(CGFloat)width {
	if (NO == _locked) { // SatoAkira add. //
    NSRect bounds = [self bounds];
    bounds.size.width = width;
		if (YES == _isSquareBounds) // SatoAkira add. //
			bounds.size.height = width; // SatoAkira add. //
    [self setBounds:bounds];
	} // SatoAkira add. //
}
- (void)setHeight:(CGFloat)height {
	if (NO == _locked) { // SatoAkira add. //
    NSRect bounds = [self bounds];
    bounds.size.height = height;
		if (YES == _isSquareBounds) // SatoAkira add. //
			bounds.size.width = height; // SatoAkira add. //
    [self setBounds:bounds];
	} // SatoAkira add. //
}


#pragma mark *** Convenience ***


+ (NSRect)boundsOfGraphics:(NSArray *)graphics {

    // The bounds of an array of graphics is the union of all of their bounds.
    NSRect bounds = NSZeroRect;
    NSUInteger graphicCount = [graphics count];
    if (graphicCount>0) {
	/* bounds = [[graphics objectAtIndex:0] bounds]; */ // SatoAkira delete. //
		bounds = rotateRect([[graphics objectAtIndex:0] bounds], [[graphics objectAtIndex:0] rotateAngle]); // SatoAkira add.回転後のrectとする。+drawingBoundsOfGraphics:もdrawingBoundsを使っているので同じように回転後である。 //
	for (NSUInteger index = 1; index<graphicCount; index++) {
            /* bounds = NSUnionRect(bounds, [[graphics objectAtIndex:index] bounds]); */ // SatoAkira delete. //
		bounds = NSUnionRect(bounds,rotateRect(bounds, [[graphics objectAtIndex:index] rotateAngle])); // SatoAkira add. //
	}
    }
    return bounds;

}


+ (NSRect)drawingBoundsOfGraphics:(NSArray *)graphics {

    // The drawing bounds of an array of graphics is the union of all of their drawing bounds.
    NSRect drawingBounds = NSZeroRect;
    NSUInteger graphicCount = [graphics count];
    if (graphicCount>0) {
	drawingBounds = [[graphics objectAtIndex:0] drawingBounds];
	for (NSUInteger index = 1; index<graphicCount; index++) {
            drawingBounds = NSUnionRect(drawingBounds, [[graphics objectAtIndex:index] drawingBounds]);
	}
    }
    return drawingBounds;

}

+ (void)translateGraphics:(NSArray *)graphics byX:(CGFloat)deltaX y:(CGFloat)deltaY {

    // Pretty simple.
    /* NSUInteger graphicCount = [graphics count];
    for (NSUInteger index = 0; index<graphicCount; index++) {
	SKTGraphic *graphic = [graphics objectAtIndex:index];
	[graphic setBounds:NSOffsetRect([graphic bounds], deltaX, deltaY)];
    } */ // SatoAkira delete. //
	
	for (SKTGraphic *graphic in graphics) { // SatoAkira add. //
		if (NO == [graphic locked]) // SatoAkira add. //
			[graphic setBounds:NSOffsetRect([graphic bounds], deltaX, deltaY)]; // SatoAkira add. //
	} // SatoAkira add. //
}


#pragma mark *** Persistence ***


+ (NSArray *)graphicsWithPasteboardData:(NSData *)data error:(NSError **)outError {

    // Because this data may have come from outside this process, don't assume that any property list object we get back is the right type.
    NSArray *graphics = nil;
    /* NSArray *propertiesArray = [NSPropertyListSerialization propertyListFromData:data mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:NULL]; */ // SatoAkira delete. //
	NSArray *propertiesArray = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:NULL error:outError]; // SatoAkira add. //
    if (![propertiesArray isKindOfClass:[NSArray class]]) {
	propertiesArray = nil;
    }
    if (propertiesArray) {

	// Convert the array of graphic property dictionaries into an array of graphics.
	graphics = [self graphicsWithProperties:propertiesArray];

    } else if (outError) {

	// If property list parsing fails we have no choice but to admit that we don't know what went wrong. The error description returned by +[NSPropertyListSerialization propertyListFromData:mutabilityOption:format:errorDescription:] would be pretty technical, and not the sort of thing that we should show to a user.
	*outError = SKTErrorWithCode(SKTUnknownPasteboardReadError);

    }
    return graphics;

}


+ (NSArray *)graphicsWithProperties:(NSArray *)propertiesArray {

    // Convert the array of graphic property dictionaries into an array of graphics. Again, don't assume that property list objects are the right type.
    NSUInteger graphicCount = [propertiesArray count];
    NSMutableArray *graphics = [[NSMutableArray alloc] initWithCapacity:graphicCount];
    for (NSUInteger index = 0; index<graphicCount; index++) {
	NSDictionary *properties = [propertiesArray objectAtIndex:index];
	if ([properties isKindOfClass:[NSDictionary class]]) {

	    // Figure out the class of graphic to instantiate. The value of the SKTGraphicClassNameKey entry must be an Objective-C class name. Don't trust the type of something you get out of a property list unless you know your process created it or it was read from your application or framework's resources.
	    NSString *className = [properties objectForKey:SKTGraphicClassNameKey];
	    if ([className isKindOfClass:[NSString class]]) {
		Class class = NSClassFromString(className);
		if (class) {

		    // Create a new graphic. If it doesn't work then just do nothing. We could return an NSError, but doing things this way 1) means that a user might be able to rescue graphics from a partially corrupted document, and 2) is easier.
		    SKTGraphic *graphic = [[class alloc] initWithProperties:properties];
		    if (graphic) {
			[graphics addObject:graphic];
			[graphic release];
		    }

		}

	    }

	}
    }
    return [graphics autorelease];

}
+ (NSArray *)graphicsWithProperties_sktd:(NSArray *)propertiesArray
// SatoAkira add. //
{
	NSUInteger index;
	NSMutableDictionary *properties;
	NSString *className;
	Class class;
	SKTGraphic *graphic;
	NSSize aSize;
	NSRect bounds;
	NSPoint aPoint;
	ASShadingModel *shadingModel;
	NSData *shadingModelData;
	NSUInteger graphicCount = [propertiesArray count];
	NSMutableArray *graphics = [[NSMutableArray alloc] initWithCapacity:graphicCount];
	NSError *err = nil;

	for (index = 0; index<graphicCount; index++) {
		properties = [NSMutableDictionary dictionaryWithDictionary:[propertiesArray objectAtIndex:index]];
		if ((YES == [properties isKindOfClass:[NSDictionary class]]) && (nil != (className = [properties objectForKey:SKTClassKey])) && (YES == [className isKindOfClass:[NSString class]])) {
			if (YES == [className isEqualToString:@"TextArea"])
				className = @"Text"; // 従来のTextAreaをSKTTextクラスにするため //
			[properties setObject:[@"SKT" stringByAppendingString:className] forKey:SKTGraphicClassNameKey];
			[properties removeObjectForKey:SKTClassKey];
			if (nil != (class = NSClassFromString([properties objectForKey:SKTGraphicClassNameKey]))) {
				// skt3形式に変換してしまう。 //
				[properties setObject:[properties objectForKey:SKTDrawsFillKey] forKey:SKTGraphicIsDrawingFillKey];
				[properties removeObjectForKey:SKTDrawsFillKey];
				[properties setObject:[properties objectForKey:SKTFillColorKey] forKey:SKTGraphicFillColorKey];
				[properties removeObjectForKey:SKTFillColorKey];
				[properties setObject:[properties objectForKey:SKTDrawsStrokeKey] forKey:SKTGraphicIsDrawingStrokeKey];
				[properties removeObjectForKey:SKTDrawsStrokeKey];
				[properties setObject:[properties objectForKey:SKTStrokeColorKey] forKey:SKTGraphicStrokeColorKey];
				[properties removeObjectForKey:SKTStrokeColorKey];
				[properties setObject:[properties objectForKey:SKTStrokeLineWidthKey] forKey:SKTGraphicStrokeWidthKey];
				[properties removeObjectForKey:SKTStrokeLineWidthKey];
				if (nil != [properties objectForKey:SKTWindingRuleSKTDKey]) {
					[properties setObject:[properties objectForKey:SKTWindingRuleSKTDKey] forKey:SKTWindingRuleKey];
					[properties removeObjectForKey:SKTWindingRuleSKTDKey];
				}
				else
					[properties setObject:[NSNumber numberWithInteger:NSNonZeroWindingRule] forKey:SKTWindingRuleKey];
				if (nil != [properties objectForKey:SKTLineJoinSKTDKey]) {
					[properties setObject:[properties objectForKey:SKTLineJoinSKTDKey] forKey:SKTLineJoinKey];
					[properties removeObjectForKey:SKTLineJoinSKTDKey];
				}
				else
					[properties setObject:[NSNumber numberWithInteger:NSMiterLineJoinStyle] forKey:SKTLineJoinKey];
				if (nil != [properties objectForKey:SKTLineCapSKTDKey]) {
					[properties setObject:[properties objectForKey:SKTLineCapSKTDKey] forKey:SKTLineCapKey];
					[properties removeObjectForKey:SKTLineCapSKTDKey];
				}
				else
					[properties setObject:[NSNumber numberWithInteger:NSButtLineCapStyle] forKey:SKTLineCapKey];
				[properties setObject:[properties objectForKey:SKTBoundsKey] forKey:SKTGraphicBoundsKey];
				bounds = NSRectFromString([properties objectForKey:SKTBoundsKey]);
				[properties removeObjectForKey:SKTBoundsKey];
				if (nil != [properties objectForKey:SKTArrowStyleSKTDKey]) {
					[properties setObject:[properties objectForKey:SKTArrowStyleSKTDKey] forKey:SKTArrowStyleKey];
					[properties removeObjectForKey:SKTArrowStyleSKTDKey];
				}
				else
					[properties setObject:[NSNumber numberWithInteger:0] forKey:SKTArrowStyleKey];
				if (nil != [properties objectForKey:SKTFormEntrySKTDKey]) {
					[properties setObject:[properties objectForKey:SKTFormEntrySKTDKey] forKey:SKTFormEntryKey];
					[properties removeObjectForKey:SKTFormEntrySKTDKey];
				}
				else
					[properties setObject:[NSNumber numberWithBool:NO] forKey:SKTFormEntryKey];
				if (nil != [properties objectForKey:SKTLocalizeFormEntrySKTDKey]) {
					[properties setObject:[properties objectForKey:SKTLocalizeFormEntrySKTDKey] forKey:SKTLocalizeFormEntryKey];
					[properties removeObjectForKey:SKTLocalizeFormEntrySKTDKey];
				}
				else
					[properties setObject:[NSNumber numberWithBool:NO] forKey:SKTLocalizeFormEntryKey];
				if (nil != [properties objectForKey:SKTLockedSKTDKey]) {
					[properties setObject:[properties objectForKey:SKTLockedSKTDKey] forKey:SKTLockedKey];
					[properties removeObjectForKey:SKTLockedSKTDKey];
				}
				else
					[properties setObject:[NSNumber numberWithBool:NO] forKey:SKTLockedKey];
				if (nil != [properties objectForKey:SKTRotateAngleSKTDKey]) {
					[properties setObject:[properties objectForKey:SKTRotateAngleSKTDKey] forKey:SKTRotateAngleKey];
					[properties removeObjectForKey:SKTRotateAngleSKTDKey];
				}
				else
					[properties setObject:[NSNumber numberWithDouble:0.0] forKey:SKTRotateAngleKey];
				if (nil != [properties objectForKey:SKTShadowOffsetSKTDKey]) {
					aSize = NSSizeFromString([properties objectForKey:SKTShadowOffsetSKTDKey]);
					if (NO == NSEqualSizes(NSZeroSize, aSize)) {
						[properties setObject:NSStringFromPoint(NSMakePoint(aSize.width / NSWidth(bounds), aSize.height / NSHeight(bounds))) forKey:SKTShadowOffsetPointKey];
						if (nil != [properties objectForKey:SKTShadowBlurRadiusSKTDKey]) {
							[properties setObject:[properties objectForKey:SKTShadowBlurRadiusSKTDKey] forKey:SKTShadowBlurRadiusKey];
							[properties removeObjectForKey:SKTShadowBlurRadiusSKTDKey];
						}
						else
							[properties setObject:[NSNumber numberWithFloat:0.0] forKey:SKTShadowBlurRadiusKey];
					}
					else {
						[properties setObject:NSStringFromPoint(NSZeroPoint) forKey:SKTShadowOffsetPointKey];
						[properties setObject:[NSNumber numberWithFloat:0.0] forKey:SKTShadowBlurRadiusKey];
					}
					[properties removeObjectForKey:SKTShadowOffsetSKTDKey];
				}
				if (nil != [properties objectForKey:SKTShadowColorSKTDKey]) {
					[properties setObject:[properties objectForKey:SKTShadowColorSKTDKey] forKey:SKTShadowColorKey];
					[properties removeObjectForKey:SKTShadowColorSKTDKey];
				}
				else
					[properties setObject:[NSArchiver archivedDataWithRootObject:[NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.0 alpha:0.3]] forKey:SKTShadowColorKey];
				if (nil != [properties objectForKey:SKTShadingSKTDKey]) {
					[properties setObject:[properties objectForKey:SKTShadingSKTDKey] forKey:SKTShadingKey];
					[properties removeObjectForKey:SKTShadingSKTDKey];
				}
				else
					[properties setObject:[NSNumber numberWithBool:NO] forKey:SKTShadingKey];
				if (nil != (shadingModelData = [properties objectForKey:SKTShadingModelSKTDKey])) {
					NSPropertyListFormat format;
					NSLog(@"shadingModelData class=%@",NSStringFromClass([shadingModelData class]));
					shadingModel = [[ASShadingModel allocWithZone:[self zone]] initWithDictionary:[NSPropertyListSerialization propertyListWithData:shadingModelData options:NSPropertyListImmutable format:&format error:&err]];
					if (YES == [shadingModel respondsToSelector:@selector(radialCenter)]) {
						NSLog(@"radialCenter OK");
						aPoint = [shadingModel radialCenter];
						[shadingModel setRadialCenter:NSMakePoint(2.0 * (aPoint.x - 0.5),2.0 * (aPoint.y - 0.5))];
					}
					[properties setObject:[NSPropertyListSerialization dataWithPropertyList:[shadingModel properties] format:NSPropertyListXMLFormat_v1_0 options:NSPropertyListImmutable error:&err] forKey:SKTShadingModelKey];
					[properties removeObjectForKey:SKTShadingModelSKTDKey];
					[shadingModel release];
				}
				if (YES == [NSStringFromClass(class) isEqualToString:@"SKTsvg"]) {
					NSData *xmlData;
					if (nil != (xmlData = [properties objectForKey:@"ImageRepresentationKey"])) {
						NSXMLDocument *xmlDoc = [[NSXMLDocument alloc] initWithData:xmlData options:NSXMLNodeOptionsNone error:&err];
						if (nil == xmlDoc) {
							if (nil == (xmlDoc = [[NSXMLDocument alloc] initWithData:xmlData options:NSXMLDocumentTidyXML error:&err])) // <!DOCTYPEの中にあった注釈や<!ENTYTYなど総て消え去る。 //
								xmlDoc = [[NSXMLDocument alloc] initWithData:xmlData options:NSXMLDocumentValidate error:&err]; // 無限ループになる。 //
							else {
								if (nil == [[xmlDoc DTD] systemID])
									NSLog(@"SKTsvg:XMLDocument DTD systenID is nil. %lu",index);
							}
						}
						if (nil != xmlDoc) {
							if (nil == [[xmlDoc rootElement] namespaces]) {
								[[xmlDoc rootElement] addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:@"http://www.w3.org/2000/svg"]];
								[[xmlDoc rootElement] addNamespace:[NSXMLNode namespaceWithName:@"xlink" stringValue:@"http://www.w3.org/1999/xlink"]];
								[[xmlDoc rootElement] addAttribute:[NSXMLNode attributeWithName:@"id" stringValue:@"svg-root"]];
								[properties setObject:[xmlDoc XMLData] forKey:@"ImageRepresentationKey"];
								/* NSString *filePath = [NSString stringWithFormat:@"/Users/me/Desktop/aData%lu.svg",index];
								[[xmlDoc XMLDataWithOptions:NSXMLNodePrettyPrint] writeToFile:filePath atomically:YES]; */
							}
							[xmlDoc release];
						}
						else
							NSLog(@"SKTsvg:XMLDocument is nil. %lu",index);
					}
					else
						NSLog(@"SKTGraphic:xmlData is nil.");
				}
				if (nil != (graphic = [[class alloc] initWithProperties:properties])) {
					[graphics addObject:graphic];
					[graphic release];
				}
				else
					NSLog(@"SKT%@ initWithProperties is nil.",className);
			}
		}
		else
			NSLog(@"NSStringFromClass error.");
	}
	return [graphics autorelease];
}

+ (NSData *)pasteboardDataWithGraphics:(NSArray *)graphics {

    // Convert the contents of the document to a property list and then flatten the property list.
    /* return [NSPropertyListSerialization dataFromPropertyList:[self propertiesWithGraphics:graphics] format:NSPropertyListBinaryFormat_v1_0 errorDescription:NULL]; */ // SatoAkira delete. //
	return [NSPropertyListSerialization dataWithPropertyList:[self propertiesWithGraphics:graphics] format:NSPropertyListBinaryFormat_v1_0 options:NSPropertyListImmutable error:NULL]; // SatoAkira add. //

}


+ (NSArray *)propertiesWithGraphics:(NSArray *)graphics {

    // Convert the array of graphics dictionaries into an array of graphic property dictionaries.
    /* NSUInteger graphicCount = [graphics count];
    NSMutableArray *propertiesArray = [[NSMutableArray alloc] initWithCapacity:graphicCount];
    for (NSUInteger index = 0; index<graphicCount; index++) {
	SKTGraphic *graphic = [graphics objectAtIndex:index]; */ // SatoAkira delete. //
	NSMutableArray *propertiesArray = [[NSMutableArray alloc] initWithCapacity:10]; // SatoAkira add. //
	for (SKTGraphic *graphic in graphics) { // SatoAkira add. //

	// Get the properties of the graphic, add the class name that can be used by +graphicsWithProperties: to it, and add the properties to the array we're building.
	NSMutableDictionary *properties = [graphic properties];
	[properties setObject:NSStringFromClass([graphic class]) forKey:SKTGraphicClassNameKey];
	[propertiesArray addObject:properties];

    }
    return [propertiesArray autorelease];

}

/* - (id)initWithProperties:(NSDictionary *)properties {

    // Invoke the designated initializer.
    self = [self init];
    if (self) {

	// The dictionary entries are all instances of the classes that can be written in property lists. Don't trust the type of something you get out of a property list unless you know your process created it or it was read from your application or framework's resources. We don't have to worry about KVO-compliance in initializers like this by the way; no one should be observing an unitialized object.
	Class dataClass = [NSData class];
	Class numberClass = [NSNumber class];
	Class stringClass = [NSString class];
	NSString *boundsString = [properties objectForKey:SKTGraphicBoundsKey];
	if ([boundsString isKindOfClass:stringClass]) {
	    _bounds = NSRectFromString(boundsString);
	}
	NSNumber *isDrawingFillNumber = [properties objectForKey:SKTGraphicIsDrawingFillKey];
	if ([isDrawingFillNumber isKindOfClass:numberClass]) {
	    _isDrawingFill = [isDrawingFillNumber boolValue];
	}
	NSData *fillColorData = [properties objectForKey:SKTGraphicFillColorKey];
	if ([fillColorData isKindOfClass:dataClass]) {
	    [_fillColor release];
	    _fillColor = [[NSUnarchiver unarchiveObjectWithData:fillColorData] retain];
	}
	NSNumber *isDrawingStrokeNumber = [properties objectForKey:SKTGraphicIsDrawingStrokeKey];
	if ([isDrawingStrokeNumber isKindOfClass:numberClass]) {
	    _isDrawingStroke = [isDrawingStrokeNumber boolValue];
	}
	NSData *strokeColorData = [properties objectForKey:SKTGraphicStrokeColorKey];
	if ([strokeColorData isKindOfClass:dataClass]) {
	    [_strokeColor release];
	    _strokeColor = [[NSUnarchiver unarchiveObjectWithData:strokeColorData] retain];
	}
	NSNumber *strokeWidthNumber = [properties objectForKey:SKTGraphicStrokeWidthKey];
	if ([strokeWidthNumber isKindOfClass:numberClass]) {
	    _strokeWidth = [strokeWidthNumber doubleValue];
	}

    }
    return self;

} */ // SatoAkira delete. //
- (id)initWithProperties:(NSDictionary *)properties
// SatoAkira add. //
{
	if (nil != (self = [super init])) {
		id obj;
		Class dataClass = [NSData class];
		Class numberClass = [NSNumber class];
		Class stringClass = [NSString class];
		NSError *err = nil;

		if ((nil != (obj = [properties objectForKey:SKTGraphicBoundsKey])) && (YES == [obj isKindOfClass:stringClass]))
			_bounds = NSRectFromString(obj);
		else
			_bounds = NSZeroRect;
		if (nil != (obj = [properties objectForKey:SKTGraphicIsDrawingFillKey]))
			_isDrawingFill = (YES == [obj isKindOfClass:numberClass]) ? [obj boolValue] : [obj isEqualToString:@"YES"]; // 旧バージョンに対応するため //
		if ((nil != (obj = [properties objectForKey:SKTGraphicFillColorKey])) && (YES == [obj isKindOfClass:dataClass]))
			_fillColor = [[NSUnarchiver unarchiveObjectWithData:obj] retain];
		if (nil != (obj = [properties objectForKey:SKTGraphicIsDrawingStrokeKey]))
			_isDrawingStroke = (YES == [obj isKindOfClass:numberClass]) ? [obj boolValue] : [obj isEqualToString:@"YES"];
		if ((nil != (obj = [properties objectForKey:SKTGraphicStrokeColorKey])) && (YES == [obj isKindOfClass:dataClass]))
			_strokeColor = [[NSUnarchiver unarchiveObjectWithData:obj] retain];
		if (nil != (obj = [properties objectForKey:SKTGraphicStrokeWidthKey]))
			_strokeWidth = [obj doubleValue];
		if (nil != (obj = [properties objectForKey:SKTWindingRuleKey]))
			_windingRule = (NSEvenOddWindingRule == [obj intValue]) ? NSEvenOddWindingRule : NSNonZeroWindingRule;
		if (nil != (obj = [properties objectForKey:SKTLineJoinKey]))
			_lineJoin = [obj intValue];
		if (nil != (obj = [properties objectForKey:SKTLineCapKey]))
			_lineCap = [obj intValue];
		if (nil != (obj = [properties objectForKey:SKTArrowStateKey]))
			_arrowState = (YES == [obj isKindOfClass:numberClass]) ? [obj integerValue] : SKTArrowNone;
		else {
			_arrowState = SKTArrowNone;
			if ((nil != (obj = [properties objectForKey:SKTArrowAtStartKey])) && (YES == [obj isEqualToString:@"YES"]))
				_arrowState += SKTArrowOnStart;
			if ((nil != (obj = [properties objectForKey:SKTArrowAtEndKey])) && (YES == [obj isEqualToString:@"YES"]))
				_arrowState += SKTArrowOnEnd;
		}
		if (nil != (obj = [properties objectForKey:SKTArrowStyleKey]))
			_arrowStyle = [obj intValue];
		if (nil != (obj = [properties objectForKey:SKTFormEntryKey]))
			_formEntry = (YES == [obj isKindOfClass:numberClass]) ? [obj boolValue] : [obj isEqualToString:@"YES"];
		if (nil != (obj = [properties objectForKey:SKTLocalizeFormEntryKey]))
			_localizeFormEntry = (YES == [obj isKindOfClass:numberClass]) ? [obj boolValue] : [obj isEqualToString:@"YES"];
		if (nil != (obj = [properties objectForKey:SKTLockedKey]))
			_locked = (YES == [obj isKindOfClass:numberClass]) ? [obj boolValue] : [obj isEqualToString:@"YES"];
		if (nil != (obj = [properties objectForKey:SKTLineDashPhaseKey]))
			_lineDashPhase = [obj floatValue];
		else
			_lineDashPhase = 0.0;
		if (nil != (obj = [properties objectForKey:SKTLineDashPatternKey])) {
			NSPropertyListFormat format;
			_lineDashPattern = [[NSArray allocWithZone:[self zone]] initWithArray:[NSPropertyListSerialization propertyListWithData:obj options:NSPropertyListImmutable format:&format error:&err]];
		}
		else {
			if (nil != [properties objectForKey:SKTDashPatternSKTDKey])
				[self dashPatternConvert:1 propertyList:properties]; // _lineDashPhase,_lineDashPatternがセットされる。 //
		}
		if (nil != (obj = [properties objectForKey:SKTRotateAngleKey]))
			_rotateAngle = [obj doubleValue];
		if ((nil != (obj = [properties objectForKey:SKTShadingModelKey])) && (YES == [obj isKindOfClass:dataClass])) {
			NSPropertyListFormat format;
			_shadingModel = [[ASShadingModel allocWithZone:[self zone]] initWithDictionary:[NSPropertyListSerialization propertyListWithData:obj options:NSPropertyListImmutable format:&format error:&err]];
			if (nil != (obj = [properties objectForKey:SKTShadingKey]))
				_shading = (YES == [obj isKindOfClass:numberClass]) ? [obj boolValue] : [obj isEqualToString:@"YES"];
			else
				_shading = NO;
		}
		else {
			_shading = NO;
			_shadingModel = nil;
		}
		if ((nil != (obj = [properties objectForKey:SKTShadowOffsetPointKey])) && (YES == [obj isKindOfClass:[NSString class]])) {
			_shadowOffsetPoint = NSPointFromString(obj);
			if (nil != (obj = [properties objectForKey:SKTShadowBlurRadiusKey]))
				_shadowBlurRadiusValue = [obj floatValue];
			else
				_shadowBlurRadiusValue = 0.0;					
		}
		else {
			if (nil != (obj = [properties objectForKey:SKTShadowOffsetXKey])) { // skt3の旧バージョン //
				_shadowOffsetPoint.x = (0.0 != NSWidth(_bounds)) ? [obj floatValue] / NSWidth(_bounds) : 0.0;
				if (nil != (obj = [properties objectForKey:SKTShadowOffsetYKey]))
					_shadowOffsetPoint.y = (0.0 != NSHeight(_bounds)) ? [obj floatValue] / NSHeight(_bounds) : 0.0;
				else
					_shadowOffsetPoint.y = 0.0;
			}
			else {
				if (nil != (obj = [properties objectForKey:SKTShadowOffsetSKTDKey])) { // sktd //
					NSSize shadowOffset = NSSizeFromString(obj);
					_shadowOffsetPoint.x = (0.0 != NSWidth(_bounds)) ? shadowOffset.width / NSWidth(_bounds) : 0.0;
					_shadowOffsetPoint.y = (0.0 != NSHeight(_bounds)) ? shadowOffset.height / NSHeight(_bounds) : 0.0;
				}
				else
					_shadowOffsetPoint = NSZeroPoint;
			}
			if (NO == NSEqualPoints(NSZeroPoint, _shadowOffsetPoint)) {
				if (nil != (obj = [properties objectForKey:SKTShadowBlurRadiusKey]))
					_shadowBlurRadiusValue = [obj floatValue];
				else
					_shadowBlurRadiusValue = 0.0;					
			}
			else
				_shadowBlurRadiusValue = 0.0;
			if (nil != _shadingModel) {
				NSPoint aPoint = [_shadingModel radialCenter];
				[_shadingModel setRadialCenter:NSMakePoint(2.0 * (aPoint.x - 0.5),2.0 * (aPoint.y - 0.5))];
			}
		}
		if ((nil != (obj = [properties objectForKey:SKTShadowColorKey])) && (YES == [obj isKindOfClass:dataClass]))
			_shadowColor = [[NSUnarchiver unarchiveObjectWithData:obj] retain];
		if (nil != (obj = [properties objectForKey:SKTIsSquareBoundsKey]))
			_isSquareBounds = [obj boolValue];
		else
			_isSquareBounds = NO;
		_currentPage = 1; // propertiesの中に無いので1に決めうち //
	}
	return self;
}

- (NSMutableDictionary *)properties {

    // Return a dictionary that contains nothing but values that can be written in property lists.
	// SatoAkira add. class名は+ (NSArray *)propertiesWithGraphics:で付けられる。NSNumber numberWithBoolを使ったので旧バージョンとは互換性が無い。OSの古いバージョンではNSNumber numberWithBoolがまともではなかったが、OS10.4からまともになったので使う。 //
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    [properties setObject:NSStringFromRect([self bounds]) forKey:SKTGraphicBoundsKey];
    [properties setObject:[NSNumber numberWithBool:[self isDrawingFill]] forKey:SKTGraphicIsDrawingFillKey];
    NSColor *fillColor = [self fillColor];
    if (fillColor) {
        [properties setObject:[NSArchiver archivedDataWithRootObject:fillColor] forKey:SKTGraphicFillColorKey];
    }
    [properties setObject:[NSNumber numberWithBool:[self isDrawingStroke]] forKey:SKTGraphicIsDrawingStrokeKey];
    NSColor *strokeColor = [self strokeColor];
    if (strokeColor) {
        [properties setObject:[NSArchiver archivedDataWithRootObject:strokeColor] forKey:SKTGraphicStrokeColorKey];
    }
    [properties setObject:[NSNumber numberWithDouble:[self strokeWidth]] forKey:SKTGraphicStrokeWidthKey];
// ↓SatoAkira add. //
	[properties setObject:[NSNumber numberWithInteger:_windingRule] forKey:SKTWindingRuleKey];
	[properties setObject:[NSNumber numberWithInteger:_lineJoin] forKey:SKTLineJoinKey];
	[properties setObject:[NSNumber numberWithInteger:_lineCap] forKey:SKTLineCapKey];
	[properties setObject:[NSNumber numberWithInteger:_arrowState] forKey:SKTArrowStateKey];
	[properties setObject:[NSNumber numberWithInteger:_arrowStyle] forKey:SKTArrowStyleKey];
	[properties setObject:[NSNumber numberWithBool:_formEntry] forKey:SKTFormEntryKey];
	[properties setObject:[NSNumber numberWithBool:_localizeFormEntry] forKey:SKTLocalizeFormEntryKey];
	[properties setObject:[NSNumber numberWithBool:_locked] forKey:SKTLockedKey];
	[properties setObject:[NSNumber numberWithFloat:_lineDashPhase] forKey:SKTLineDashPhaseKey];
	NSError *err = nil;
	[properties setObject:[NSPropertyListSerialization dataWithPropertyList:_lineDashPattern format:NSPropertyListXMLFormat_v1_0 options:NSPropertyListImmutable error:&err] forKey:SKTLineDashPatternKey];
	[properties setObject:[NSNumber numberWithDouble:_rotateAngle] forKey:SKTRotateAngleKey];
	[properties setObject:NSStringFromPoint(_shadowOffsetPoint) forKey:SKTShadowOffsetPointKey];
	[properties setObject:[NSNumber numberWithFloat:_shadowBlurRadiusValue] forKey:SKTShadowBlurRadiusKey];
	[properties setObject:[NSArchiver archivedDataWithRootObject:_shadowColor] forKey:SKTShadowColorKey];
	if (nil != _shadingModel) {
		[properties setObject:[NSPropertyListSerialization dataWithPropertyList:[_shadingModel properties] format:NSPropertyListXMLFormat_v1_0 options:NSPropertyListImmutable error:&err] forKey:SKTShadingModelKey];
		[properties setObject:[NSNumber numberWithBool:_shading] forKey:SKTShadingKey];
	}
	else
		[properties setObject:[NSNumber numberWithBool:NO] forKey:SKTShadingKey];
	[properties setObject:[NSNumber numberWithBool:_isSquareBounds] forKey:SKTIsSquareBoundsKey];
// ↑SatoAkira add. //
    return properties;

}


#pragma mark *** Simple Property Getting ***


// Do the regular Cocoa thing.
- (NSRect)bounds {
    return _bounds;
}
- (BOOL)isDrawingFill {
    return _isDrawingFill;
}
- (NSColor *)fillColor {
    return [[_fillColor retain] autorelease];
}
- (BOOL)isDrawingStroke {
    return _isDrawingStroke;
}
- (NSColor *)strokeColor {
    return [[_strokeColor retain] autorelease];
}
- (CGFloat)strokeWidth {
    return _strokeWidth;
}
// ↓SatoAkira add. //
- (NSWindingRule)windingRule {
	return _windingRule;
}
- (NSLineJoinStyle)lineJoin {
	return _lineJoin;
}
- (NSLineCapStyle)lineCap {
	return _lineCap;
}
- (SKTArrowState)arrowState {
	return _arrowState;
}
- (NSInteger)arrowStyle {
	return _arrowStyle;
}
- (BOOL)formEntry {
	return _formEntry;
}
- (BOOL)localizeFormEntry {
	return _localizeFormEntry;
}
- (BOOL)locked {
	return _locked;
}
- (double)rotateAngle {
	return _rotateAngle;
}
- (NSUInteger)pageCount {
	return 1;
}
- (void)setCurrentPage:(NSNumber *)aValue {
	_currentPage = 1;
}
- (CGFloat)lineDashPhase {
	return _lineDashPhase;
}
/* - (NSString *)dashPatternString:(double)pointsPerUnit
{
	NSUInteger i;
	NSMutableString *returnString = [NSMutableString string];

	for (i = 0; i < [_lineDashPattern count]; i++) {
		if (0 < i)
			[returnString appendString:@","];
		[returnString appendFormat:@"%g", [[_lineDashPattern objectAtIndex:i] floatValue] / pointsPerUnit];
	}
	return returnString;
} */
- (NSArray *)lineDashPattern {
	return _lineDashPattern;
}
/* - (void)setDashPattern:(NSArray *)anArray
{
	if ((CGFloat *)NULL != _dashPattern)
		NSZoneFree((NSZone *)[self zone], _dashPattern);
	if ((nil != anArray) && (0 < [anArray count])) {
		NSUInteger i;

		_patternSize = [anArray count];
		_dashPattern = (CGFloat *)NSZoneMalloc((NSZone *)[self zone], _patternSize * sizeof(CGFloat));
		for (i = 0; i < _patternSize; i++, _dashPattern++)
			*_dashPattern = [[anArray objectAtIndex:i] floatValue];
		_dashPattern -= _patternSize;
	}
	else {
		_patternSize = 0;
		_dashPattern = (CGFloat *)NULL;
	}
} */
- (NSPoint)shadowOffsetPoint {
	return _shadowOffsetPoint;
}
- (CGFloat)shadowBlurRadiusValue {
	return _shadowBlurRadiusValue;
}
- (NSColor *)shadowColor {
	return _shadowColor;
}
- (void)shadowSet
{
	double offsetX = _shadowOffsetPoint.x * NSWidth(_bounds);
	double offsetY = _shadowOffsetPoint.y * NSHeight(_bounds);
	double l = hypot(offsetY,offsetX);
	double angle = atan3(offsetY,offsetX);
	NSShadow *theShadow = [[[NSShadow allocWithZone:[self zone]] init] autorelease];
	[theShadow setShadowOffset:NSMakeSize(l * cos(angle - _rotateAngle),l * sin(angle - _rotateAngle))];
	[theShadow setShadowBlurRadius:_shadowBlurRadiusValue];
	[theShadow setShadowColor:[self convertColorSpace:[self shadowColor]]];
	[theShadow set];
}
- (BOOL)shading {
	return _shading;
}
- (ASShadingModel *)shadingModel {
	return _shadingModel;
}
- (void)setShadingStyle:(NSNumber *)aNumber
{
	_shadingStyle = [aNumber integerValue];
	switch (_shadingStyle) {
	case ASNoneShading:
		[self setValue:[NSNumber numberWithBool:YES] forKey:SKTGraphicIsDrawingFillKey];
		[self setValue:[NSNumber numberWithBool:NO] forKey:SKTShadingKey];
		break;
	case ASAxialShading: case ASRadialShading: case ASDoubleAxialShading: case ASDoubleRadialShading:
		[self setValue:[NSNumber numberWithBool:YES] forKey:SKTGraphicIsDrawingFillKey];
		[self setValue:[NSNumber numberWithBool:YES] forKey:SKTShadingKey];
		if (nil == _shadingModel)
			_shadingModel = [[ASShadingModel allocWithZone:[self zone]] init];
		[_shadingModel setShadingStyle:_shadingStyle];
		break;
	default: // NSNotFound //
		[self setValue:[NSNumber numberWithBool:NO] forKey:SKTGraphicIsDrawingFillKey];
		break;
	}
}
- (void)setShadingColor:(NSColor *)aColor order:(ASShadingColorOrder)anOrder {
	[_shadingModel setColor:aColor order:anOrder];
}
- (void)setShadingAxialAngle:(NSNumber *)aNumber {
	_shadingAxialAngle = [aNumber doubleValue];
	[_shadingModel setAxialAngle:[aNumber doubleValue]];
}
- (double)shadingAxialAngle {
	return (nil != _shadingModel) ? [_shadingModel axialAngle] : 0.0;
}
- (void)setShadingColorPosition:(NSArray *)anArray {
	[_shadingColorPosition release];
	_shadingColorPosition = [[NSArray alloc] initWithArray:anArray];
	[_shadingModel setColorPosition:anArray];
}
- (NSArray *)shadingColorPosition {
	return _shadingColorPosition;
}
- (void)setShadingRadialCenter:(NSPoint)aPoint { // 引数はNSValueでなくても良い。 //
	_shadingRadialCenter = aPoint;
	[_shadingModel setRadialCenter:aPoint];
}
- (NSPoint)shadingRadialCenter {
	return (nil != _shadingModel) ? [_shadingModel radialCenter] : NSZeroPoint;
}
- (void)setShadingModel:(ASShadingModel *)aModel {
	[_shadingModel release];
	_shadingModel = [[ASShadingModel allocWithZone:[self zone]] initWithDictionary:[aModel properties]];
}
- (void)drawShading:(NSBezierPath *)path transform:(NSAffineTransform *)transform
{
	ASShadingModel *aModel = [self shadingModel];
	NSArray *colorPositions = [aModel colorPosition];
	CGFloat *locations = (CGFloat *)malloc([colorPositions count] * sizeof(CGFloat));
	for (NSNumber *location in colorPositions)
		*locations++ = [location floatValue];
	locations -= [colorPositions count];
	NSGradient *gradient = [[NSGradient alloc] initWithColors:[NSArray arrayWithObjects:[aModel startColor],[aModel midColor],[aModel endColor],nil] atLocations:locations colorSpace:[self colorSpace]];
	ASShadingStyle style = [aModel shadingStyle];
	if (nil != transform) {
		[[NSGraphicsContext currentContext] saveGraphicsState];
		[transform concat];
	}
	switch (style) {
		case ASNoneShading:
			[[aModel midColor] setFill];
			[path fill];
			break;
		case ASAxialShading: case ASDoubleAxialShading:
			[gradient drawInBezierPath:path angle:360.0 - 180.0 * [aModel axialAngle] / M_PI]; // locationsをセットしておけばそのとおりになる。 //
			break;
		case ASRadialShading: case ASDoubleRadialShading:
			[gradient drawInBezierPath:path relativeCenterPosition:[aModel radialCenter]];
			break;
		default:
			break;
	}
	free(locations);
	[gradient release];
	if (nil != transform)
		[[NSGraphicsContext currentContext] restoreGraphicsState];
}
- (ASPatternModel *)patternModel
{
	if (nil == _patternModel) {
		NSImage *patternColorImage = [_fillColor patternImage];
		NSData *pData = [patternColorImage TIFFRepresentation]; // OS10.5のSDK10.5からTIFFRepresentationの仕様変更があった。sizeをいじられてしまう。_fillColorのclass名はNSPatternColor //
		Class pRepClass = [NSImageRep imageRepClassForData:pData];
		NSImageRep *pRep = [[pRepClass allocWithZone:[self zone]] initWithData:pData];
		// NSLog(@"patternModel:class=%@ size=%@ patternSize=%@",NSStringFromClass([_fillColor class]),NSStringFromSize([pRep size]),NSStringFromSize([patternColorImage size])); // // Debug //
		[pRep setSize:[patternColorImage size]]; // OS10.5から必要になった。 //
		_patternModel = [[ASPatternModel allocWithZone:[self zone]] init];
		[_patternModel setPatternImageRep:pRep];
		[pRep release];
	}
	return _patternModel;
}
- (void)setViewColorSpace:(NSColorSpace *)aSpace {
	viewColorSpace = aSpace;
}
- (NSColorSpace *)colorSpace {
	return (nil != viewColorSpace) ? viewColorSpace : [NSColorSpace sRGBColorSpace];
}

- (NSArray *)svgXMLElements:(NSRect)aRect name:(NSString *)unique_ID
// エラーが起きて書き出せなかったときはnil，書き出す必要が無かったときは空配列を返すようにサブクラスでオーバーライドする。 //
{
	return nil; // 実装されていないというエラーなのでnilを返す。 //
}
- (NSRect)svgAxialPointsWithAngle:(double)aValue
// originが(x1,y1),sizeが(x2,y2) //
{
	double x,y;
	NSPoint startPoint,endPoint;
	double w = NSWidth([self bounds]);
	double h = NSHeight([self bounds]);
	
	y = fabs(0.5 * w * tan(aValue));
	if (0.5 * h < y) {
		y = 0.5 * h;
		x = fabs(0.5 * h / tan(aValue));
	}
	else
		x = 0.5 * w;
	if (0.0 < sin(aValue)) {
		endPoint.y = -1.0 * y;
		startPoint.y = y;
	}
	else {
		endPoint.y = y;
		startPoint.y = -1.0 * y;
	}
	if (0.0 < cos(aValue)) {
		endPoint.x = x;
		startPoint.x = -1.0 * x;
	}
	else {
		endPoint.x = -1.0 * x;
		startPoint.x = x;
	}
	return NSMakeRect(startPoint.x,startPoint.y,endPoint.x,endPoint.y);
}
- (double)svgEndRadiusWithRelativeCenterPosition
{
	double r;
	NSRect bounds = [self bounds];
	NSPoint aPoint = [[self shadingModel] radialCenter];
	if ((0.0 > aPoint.x) && (0.0 > aPoint.y))
		r = hypot(0.5 * (1.0 - aPoint.x) * NSWidth(bounds), 0.5 * (1.0 - aPoint.y) * NSHeight(bounds));
	else {
		if ((0.0 < aPoint.x) && (0.0 > aPoint.y))
			r = hypot(0.5 * (1.0 + aPoint.x) * NSWidth(bounds), 0.5 * (1.0 - aPoint.y) * NSHeight(bounds));
		else {
			if ((0.0 > aPoint.x) && (0.0 < aPoint.y))
				r = hypot(0.5 * (1.0 - aPoint.x) * NSWidth(bounds),0.5 * (1.0 + aPoint.y )* NSHeight(bounds));
			else
				r = hypot(0.5 * (1.0 + aPoint.x) * NSWidth(bounds),0.5 * (1.0 + aPoint.y )* NSHeight(bounds));
		}
	}
	return r;
}
- (NSXMLNode *)svgFillNode:(NSString *)unique_ID transform:(NSAffineTransform *)aTrans
{
	double x,y;
	NSAffineTransformStruct s;
	NSXMLNode *element = nil;
	NSRect bounds = [self bounds];

	if ((YES == [self isDrawingFill]) && (YES == [self shading])) {
		ASShadingModel *shadingModel = [self shadingModel];

		if (nil != shadingModel) {
			NSPoint startPoint,endPoint;
			NSRect points;

			switch ([shadingModel shadingStyle]) {
				case ASAxialShading: case ASDoubleAxialShading:
					points = [self svgAxialPointsWithAngle:[shadingModel axialAngle]];
					startPoint = NSMakePoint(NSMinX(points),NSMinY(points));
					endPoint = NSMakePoint(NSWidth(points),NSHeight(points));
					if (nil != aTrans) {
						s = [aTrans transformStruct];
						x = s.m11 * startPoint.x + s.m21 * startPoint.y + s.tX;
						y = s.m12 * startPoint.x + s.m22 * startPoint.y + s.tY;
						startPoint.x = x;
						startPoint.y = y;
						x = s.m11 * endPoint.x + s.m21 * endPoint.y + s.tX;
						y = s.m12 * endPoint.x + s.m22 * endPoint.y + s.tY;
						endPoint.x = x;
						endPoint.y = y;
					}
					element = svgGradientNode(unique_ID,@"gradient",@"linearGradient",[NSArray arrayWithObjects:[NSNumber numberWithDouble:startPoint.x],[NSNumber numberWithDouble:startPoint.y],[NSNumber numberWithDouble:endPoint.x],[NSNumber numberWithDouble:endPoint.y],nil],[shadingModel colors],[shadingModel colorPosition]);
					break;
				case ASRadialShading: case ASDoubleRadialShading:
					endPoint = [shadingModel radialCenter]; // endという意味ではない。 //
					startPoint = NSMakePoint(0.5 * endPoint.x * NSWidth(bounds),0.5 * endPoint.y * NSHeight(bounds));
					if (nil != aTrans) {
						s = [aTrans transformStruct];
						x = s.m11 * startPoint.x + s.m21 * startPoint.y + s.tX;
						y = s.m12 * startPoint.x + s.m22 * startPoint.y + s.tY;
						startPoint.x = x;
						startPoint.y = y;
					}
					element = svgGradientNode(unique_ID,@"gradient",@"radialGradient",[NSArray arrayWithObjects:[NSNumber numberWithDouble:startPoint.x],[NSNumber numberWithDouble:startPoint.y],[NSNumber numberWithDouble:[self svgEndRadiusWithRelativeCenterPosition]],nil],[shadingModel colors],[shadingModel colorPosition]);
					break;
				default:
					break;
			}
		}
	}
	else {
		if ((YES == [self isDrawingFill]) && (YES == [[[self fillColor] colorSpaceName] isEqualToString:NSPatternColorSpace])) {
			NSPoint minPoint = NSMakePoint(-0.5 * NSWidth(bounds), -0.5 * NSHeight(bounds));
			if (nil != aTrans) {
				s = [aTrans transformStruct];
				x = s.m11 * minPoint.x + s.m21 * minPoint.y + s.tX;
				y = s.m12 * minPoint.x + s.m22 * minPoint.y + s.tY;
			}
			else {
				x = minPoint.x;
				y = minPoint.y;
			}
			element = svgPatternNode(unique_ID,@"fill",[[self fillColor] patternImage],NSMakePoint(x,y));
		}
	}
	return element;
}
- (NSXMLNode *)svgStrokeNode:(NSString *)unique_ID transform:(NSAffineTransform *)aTrans
{
	NSXMLNode *element = nil;
	if ((YES == [self isDrawingStroke]) && (YES == [[[self strokeColor] colorSpaceName] isEqualToString:NSPatternColorSpace])) {
		double x,y;
		NSPoint minPoint = NSMakePoint(-0.5 * NSWidth([self bounds]), -0.5 * NSHeight([self bounds]));
		if (nil != aTrans) {
			NSAffineTransformStruct s = [aTrans transformStruct];
			x = s.m11 * minPoint.x + s.m21 * minPoint.y + s.tX;
			y = s.m12 * minPoint.x + s.m22 * minPoint.y + s.tY;
		}
		else {
			x = minPoint.x;
			y = minPoint.y;
		}
		element = svgPatternNode(unique_ID,@"stroke",[[self strokeColor] patternImage],NSMakePoint(x,y));
	}
	return element;
}
- (NSArray *)svgFillAndStrokeAttributes:(NSString *)unique_ID
{
	NSMutableArray *attributes = [NSMutableArray array];
		if ((YES == [self isDrawingFill]) && (YES == [self shading]))
			[attributes addObjectsFromArray:svgColorNodes(unique_ID,@"fill",@"gradient",nil)];
		else
			[attributes addObjectsFromArray:(YES == [self isDrawingFill]) ? svgColorNodes(unique_ID,@"fill",@"fill",[self fillColor]) : svgColorNodes(unique_ID,@"fill",@"fill",nil)];
		if (YES == [self isDrawingFill])
			[attributes addObject:svgFillRuleNode(_windingRule)];
		[attributes addObjectsFromArray:(YES == [self isDrawingStroke]) ? svgColorNodes(unique_ID,@"stroke",@"stroke",[self strokeColor]) : svgColorNodes(unique_ID,@"stroke",@"stroke",nil)];
	return attributes;
}

- (NSArray *)svgDefsAndRect:(NSString *)unique_ID allGraphics:(NSRect)allRect bounds:(NSRect)bounds transform:(NSAffineTransform *)transform
// allRectにNSZeroRectを与えるとbounds矩形を表示しない。 //
// idは[NSString stringWithFormat:@"url(#shadow_%@)",unique_ID]という約束にする。 //
// allRectは[SKTGraphic drawingBoundsOfGraphics:(NSArray *)graphics]で取得できるが、documentからのgraphicsを得るためにSKTDocument.hをimportしていない。boundsの値の通常は[self bounds] //
{
	NSMutableArray *elements = [NSMutableArray array];
	BOOL shadowFlag = (0.1 > _shadowBlurRadiusValue) ? NO : YES;
	NSXMLElement *defsElement = [NSXMLElement elementWithName:@"defs"];
	NSXMLElement *rectElement = nil;
	if (YES == shadowFlag) { // boundsのoriginとは無関係でsizeのみに影響される。 //
		NSXMLElement *filterElement = [NSXMLElement elementWithName:@"filter"];
		NSMutableArray *filterAttributes = [NSMutableArray arrayWithObjects:[NSXMLNode attributeWithName:@"id" stringValue:[NSString stringWithFormat:@"shadow_%@",unique_ID]],[NSXMLNode attributeWithName:@"filterUnits" stringValue:@"objectBoundingBox"],nil];
		// おおむねdrawingBoundsと同じアルゴリズム。回転は掛けなくてもSVGの方で回転が掛かる。 //
		CGFloat lineWidth = (YES == [self isDrawingStroke]) ? _strokeWidth : 0.0;
		NSRect outlineRect = NSInsetRect(bounds, -0.5 * lineWidth, -0.5 * lineWidth);
		double dx = _shadowOffsetPoint.x * NSWidth(bounds); // _shadowOffsetPointの値により左右のdrawingの値を変えて良い。変えないと無駄に大きくなってしまう。 //
		double dy = -1.0 * _shadowOffsetPoint.y * NSHeight(bounds);
		NSSize shadowArea = NSMakeSize(_shadowBlurRadiusValue, _shadowBlurRadiusValue);
		NSRect shadowBounds  = NSInsetRect(outlineRect, -1.0 * shadowArea.width, -1.0 * shadowArea.height); // -1.0で両側になるので2倍。 //
		if (0.0 < dx)
			shadowBounds.size.width += dx;
		else {
			if (0.0 > dx) {
				shadowBounds.origin.x += dx;
				shadowBounds.size.width -= dx;
			}
		}
		if (0.0 > dy)
			shadowBounds.size.height -= dy;
		else {
			if (0.0 < dy) {
				shadowBounds.origin.y += dy;
				shadowBounds.size.height += dy;
			}
		}
		NSRect drawing = NSInsetRect(shadowBounds, -1.0 * lineWidth, -1.0 * lineWidth);
		double width = 100.0 * NSWidth(drawing) / NSWidth(bounds); // %単位 //
		double height = 100.0 * NSHeight(drawing) / NSHeight(bounds); // %単位 //
		double x = (0.0 < dx) ? -100.0 * (shadowArea.width + 0.5 * lineWidth) / NSWidth(bounds) : 100.0 * (dx - shadowArea.width - 0.5 * lineWidth) / NSWidth(bounds); // %単位 //
		double y = (0.0 > dy) ? -100.0 * (shadowArea.height + 0.5 * lineWidth) / NSHeight(bounds) : -100.0 * (dy + shadowArea.height + 0.5 * lineWidth) / NSHeight(bounds); // %単位。Webkitはこの向きで良い。Inkscapeは反対向きになってしまう。Inkscapeではこの値とwidth,heightは殆ど意味を持たないようである。 //
		// NSLog(@"dx=%f blur=%f drawing=%f width=%f",dx,_shadowBlurRadiusValue,NSWidth(drawing),width); //
		NSColor *shadowColor = [self shadowColor];
		NSString *shadowColorSpace = [shadowColor colorSpaceName];
		CGFloat alpha,r,g,b;
		if ((NO == [shadowColorSpace isEqualToString:NSPatternColorSpace]) && (NO == [shadowColorSpace isEqualToString:NSNamedColorSpace])) {
			if ((YES == [shadowColorSpace isEqualToString:NSCalibratedRGBColorSpace]) || (YES == [shadowColorSpace isEqualToString:NSDeviceRGBColorSpace])) {
				[shadowColor getRed:&r green:&g blue:&b alpha:&alpha];
			}
			else {
				if ((YES == [shadowColorSpace isEqualToString:NSCalibratedWhiteColorSpace]) || (YES == [shadowColorSpace isEqualToString:NSDeviceWhiteColorSpace])) { // NSCalibratedBlackColorSpaceとNSDeviceBlackColorSpaceはOS10.6から削除されている。 //
					[shadowColor getWhite:&r alpha:&alpha];
					g = b = r;
				}
				else { // NSCustomColorSpace //
					NSInteger nc = [shadowColor numberOfComponents];
					if (2 == nc) { // カラーパネルのグレースケールを使って設定した直後はNSCustomColorSpaceになる。そうでないグレースケールはNSCalibratedWhiteColorSpaceになる。 //
						r = g = b = [shadowColor whiteComponent];
						alpha = [shadowColor alphaComponent];
					}
					else {
						if (4 == nc) { // これになることは無いと思われる。 //
							CGFloat *components = (CGFloat *)malloc(nc * sizeof(CGFloat));
							[shadowColor getComponents:components];
							r = components[0];
							g = components[1];
							b = components[2];
							alpha = components[3];
							free(components);
						}
						else {
							NSLog(@"colorSpace=%@ numberOfComponents=%ld",shadowColorSpace,nc);
							r = g = b = 0.0;
							alpha = [shadowColor alphaComponent]; // アルファのみを変換するマトリクス //
						}
					}
				}
			}
		}
		else {
			alpha = 1.0;
			r = g = b = 0.0;
		}
		double stdDeviation = (1.0 > _shadowBlurRadiusValue) ? _shadowBlurRadiusValue : 2.0 * sqrt(_shadowBlurRadiusValue); // 2.0 * sqrt()は根拠無し。2.0は2倍の2ではない。shadowAreaとは無関係に定める。 //
		NSString *matrixStr = [NSString stringWithFormat:@"1 0 0 %g 0 0 1 0 %g 0 0 0 1 %g 0 0 0 0 %g 0",r,g,b,alpha];
		[filterAttributes addObject:[NSXMLNode attributeWithName:@"x" stringValue:[NSString stringWithFormat:@"%g%%",x]]]; // 単位無し //
		[filterAttributes addObject:[NSXMLNode attributeWithName:@"y" stringValue:[NSString stringWithFormat:@"%g%%",y]]]; // 単位無し //
		[filterAttributes addObject:[NSXMLNode attributeWithName:@"width" stringValue:[NSString stringWithFormat:@"%g%%",width]]];
		[filterAttributes addObject:[NSXMLNode attributeWithName:@"height" stringValue:[NSString stringWithFormat:@"%g%%",height]]];
		[filterElement setAttributes:filterAttributes];
		[filterElement addChild:[NSXMLNode elementWithName:@"feGaussianBlur" children:nil attributes:[NSArray arrayWithObjects:[NSXMLNode attributeWithName:@"in" stringValue:@"SourceAlpha"],[NSXMLNode attributeWithName:@"stdDeviation" stringValue:[NSString stringWithFormat:@"%g",stdDeviation]],[NSXMLNode attributeWithName:@"result" stringValue:@"black"], nil]]]; // CocoaのBlurRadiusは0.0以上。標準偏差への換算は概略値。resultのshadowは黒1色でアルファがinと同じなRGBA画像である。 //
		[filterElement addChild:[NSXMLNode elementWithName:@"feColorMatrix" children:nil attributes:[NSArray arrayWithObjects:[NSXMLNode attributeWithName:@"type" stringValue:@"matrix"],[NSXMLNode attributeWithName:@"result" stringValue:@"blurAlpha"],[NSXMLNode attributeWithName:@"values" stringValue:matrixStr],nil]]]; // 黒1色からアルファのみを変換するので黒い影しかできない。 //
		[filterElement addChild:[NSXMLNode elementWithName:@"feOffset" children:nil attributes:[NSArray arrayWithObjects:[NSXMLNode attributeWithName:@"in" stringValue:@"blurAlpha"],[NSXMLNode attributeWithName:@"dx" stringValue:[NSString stringWithFormat:@"%g",dx]],[NSXMLNode attributeWithName:@"dy" stringValue:[NSString stringWithFormat:@"%g",dy]],[NSXMLNode attributeWithName:@"result" stringValue:@"movedShadow"],nil]]]; // dx,dyに単位を与えるとBatikは文句を言ってくる。 //
		[filterElement addChild:[NSXMLNode elementWithName:@"feMerge" children:[NSArray arrayWithObjects:[NSXMLNode elementWithName:@"feMergeNode" children:nil attributes:[NSArray arrayWithObject:[NSXMLNode attributeWithName:@"in" stringValue:@"movedShadow"]]],[NSXMLNode elementWithName:@"feMergeNode" children:nil attributes:[NSArray arrayWithObject:[NSXMLNode attributeWithName:@"in" stringValue:@"SourceGraphic"]]],nil] attributes:nil]];
		[defsElement addChild:filterElement];
	}
	if (YES == [self isDrawingFill]) {
		NSXMLNode *fillNode = [self svgFillNode:unique_ID transform:transform];
		NSXMLNode *strokeNode = [self svgStrokeNode:unique_ID transform:transform];
		if (nil != fillNode)
			[defsElement addChild:fillNode];
		if (nil != strokeNode)
			[defsElement addChild:strokeNode];
		if (NO == NSEqualRects(NSZeroRect, allRect)) {
			CGFloat translateX = NSMidX(bounds) - NSMinX(allRect);
			CGFloat translateY = NSMidY(bounds) - NSMinY(allRect);
			NSMutableArray *attributes = [NSMutableArray arrayWithObjects:svgTransformNode(translateX,translateY,[self rotateAngle],1.0,1.0),[NSXMLNode attributeWithName:@"x" stringValue:[NSString stringWithFormat:@"%g%@",-0.5 * NSWidth(bounds),svgUnit]],[NSXMLNode attributeWithName:@"y" stringValue:[NSString stringWithFormat:@"%g%@",-0.5 * NSHeight(bounds),svgUnit]],[NSXMLNode attributeWithName:@"width" stringValue:[NSString stringWithFormat:@"%g%@",NSWidth(bounds),svgUnit]],[NSXMLNode attributeWithName:@"height" stringValue:[NSString stringWithFormat:@"%g%@",NSHeight(bounds),svgUnit]],nil];
			NSArray *fillAndStrokeAttributes = [self svgFillAndStrokeAttributes:unique_ID];

			rectElement = [NSXMLElement elementWithName:@"rect"];
			[attributes addObjectsFromArray:fillAndStrokeAttributes];
			if (YES == [self isDrawingStroke]) {
				[attributes addObject:svgStrokeWidthNode([self strokeWidth])];
				[attributes addObject:svgLineJoinNode([self lineJoin])];
				[attributes addObject:svgLineCapNode([self lineCap])];
				[attributes addObjectsFromArray:(0 < [[self lineDashPattern] count]) ? svgDashArrayNodes([self lineDashPattern],[self lineDashPhase]) : svgDashArrayNodes(nil,0.0)];
			}
			if (YES == shadowFlag)
				[attributes addObject:[NSXMLNode attributeWithName:@"filter" stringValue:[NSString stringWithFormat:@"url(#shadow_%@)",unique_ID]]];
			// rx,ryは無いところがこのrectを背景として使うので、rx,ryは見ない。 //
			[rectElement setAttributes:attributes];
		}
	}
	if (0 < [defsElement childCount])
		[elements addObject:defsElement];
	if (nil != rectElement)
		[elements addObject:rectElement];
	return elements;
}
- (BOOL)createWithEvent:(NSEvent *)theEvent inView:(SKTGraphicView *)view withGrid:(SKTGrid *)grid { // setBoundsだけでcreateできるならば何もせずにNOを返す。 //
	return NO;
}
- (BOOL)editWithEvent:(NSEvent*)theEvent inView:(SKTGraphicView *)view withGrid:(SKTGrid *)grid { // editableでないものは何もせずにNOを返す。 //
	return NO;
}
- (void)deleteForEditingInView:(SKTGraphicView *)view {
}
- (void)insertForEditingInView:(SKTGraphicView *)view {
}
- (BOOL)isCreating {
	return NO;
}
- (BOOL)isEditing {
	return NO;
}
- (void)drawAnchorHandles {
}
- (void)drawControlHandles {
}
- (BOOL)canDrawLineJoin {
    return YES;
}
- (BOOL)canDrawLineCap {
    return YES;
}
- (BOOL)canDrawArrow {
    return YES;
}
- (BOOL)canDrawFormEntry {
	return NO;
}
- (BOOL)canDrawDash {
    return YES;
}
- (BOOL)canDrawRotate {
    return YES;
}
- (BOOL)canDrawCorner {
	return NO;
}
- (CGFloat)rx {
	return 0.0;
}
- (CGFloat)ry {
	return 0.0;
}
// ↑SatoAkira add. //


#pragma mark *** Drawing ***


/* + (NSSet *)keyPathsForValuesAffectingDrawingBounds {
    
    // The only properties managed by SKTGraphic that affect the drawing bounds are the bounds and the the stroke width.
    return [NSSet setWithObjects:SKTGraphicBoundsKey, SKTGraphicStrokeWidthKey, nil];

} */ // SatoAkira delete. //
+ (NSSet *)keyPathsForValuesAffectingDrawingBounds { // SatoAkira add. //
	return [NSSet setWithObjects:SKTGraphicBoundsKey, SKTGraphicStrokeWidthKey, SKTArrowStateKey,SKTLineCapKey,SKTRotateAngleKey,SKTShadowOffsetXKey,SKTShadowOffsetYKey,SKTShadingRadialCenterKey, nil];
}


/* + (NSSet *)keyPathsForValuesAffectingDrawingContents {
    
    // The only properties managed by SKTGraphic that affect drawing but not the drawing bounds are the fill and stroke parameters.
    return [NSSet setWithObjects:SKTGraphicIsDrawingFillKey, SKTGraphicFillColorKey, SKTGraphicIsDrawingStrokeKey, SKTGraphicStrokeColorKey, nil];
    
} */ // SatoAkira delete. //
+ (NSSet *)keyPathsForValuesAffectingDrawingContents { // SatoAkira add. //
	return [NSSet setWithObjects:SKTGraphicIsDrawingFillKey, SKTGraphicFillColorKey, SKTGraphicIsDrawingStrokeKey, SKTGraphicStrokeColorKey, SKTWindingRuleKey,SKTLineJoinKey,SKTShadowBlurRadiusKey,SKTShadowOffsetPointKey, SKTShadowColorKey,SKTShadingKey,SKTLockedKey,SKTLineDashPhaseKey,SKTLineDashPatternKey,SKTShadingStyleKey,SKTShadingAxialAngleKey,SKTShadingColorPositionKey,SKTShadingRadialCenterKey,SKTShadingColorKey, nil]; // サブクラスにoverrideしたものがあるので注意すること。ここに登録されているものが変換したときに再描画が実行される。undoとは無関係。undoへ登録させるにはkeysForValuesToObserveForUndo で定義する。 //
}


/* - (NSRect)drawingBounds {

    // Assume that -[SKTGraphic drawContentsInView:] and -[SKTGraphic drawHandlesInView:] will be doing the drawing. Start with the plain bounds of the graphic, then take drawing of handles at the corners of the bounds into account, then optional stroke drawing.
    CGFloat outset = SKTGraphicHandleHalfWidth;
    if ([self isDrawingStroke]) {
	CGFloat strokeOutset = [self strokeWidth] / 2.0f;
	if (strokeOutset>outset) {
	    outset = strokeOutset;
	}
    }
    CGFloat inset = 0.0f - outset;
    NSRect drawingBounds = NSInsetRect([self bounds], inset, inset);
    
    // -drawHandleInView:atPoint: draws a one-unit drop shadow too.
    drawingBounds.size.width += 1.0f;
    drawingBounds.size.height += 1.0f;
    return drawingBounds;

} */ // SatoAkira delete. //
- (NSRect)drawingBounds
// SatoAkira add. //
// 回転移動に対応 //
{
	CGFloat inset = -1.0 * SKTGraphicHandleHalfWidth;

	if (YES == [self isDrawingStroke]) {
        CGFloat halfLineWidth = 0.5 * _strokeWidth + 1.0;
		if (-1.0 * halfLineWidth < inset) {
			inset = -1.0 * halfLineWidth;
		}
	}
	if (SKTArrowNone != _arrowState) {
		inset = (0.0 != _strokeWidth) ? -1.0 * _strokeWidth * 2.5 : -13.0;
	}
	inset -= 1.0;
	if (0.1 > _shadowBlurRadiusValue)
		return rotateRect(NSInsetRect(_bounds,inset, inset),_rotateAngle);
	else {
		double offsetX = _shadowOffsetPoint.x * NSWidth(_bounds);
		double offsetY = _shadowOffsetPoint.y * NSHeight(_bounds);
		double l = hypot(offsetX,offsetY);
		double angle = atan3(offsetY,offsetX);
		double x = l * cos(angle - _rotateAngle);
		double y = l * sin(angle - _rotateAngle);
		double blurOffset = _shadowBlurRadiusValue; // blurが100.0までならば大体これでいける。 //
		NSRect shadowBounds = NSInsetRect(_bounds, -1.0 * blurOffset, -1.0 * blurOffset); // blur(ぼかし)の分を両側に広げる。 //

		if (0.0 < x) shadowBounds.size.width += x; // 幅だけ増やす。  //
		else if (0.0 > x)  { shadowBounds.origin.x += x; shadowBounds.size.width -= x; }  // 原点を移動しその分だけ幅を増やす。 //
		// ISFLIPPED 1 のとき //
		if (0.0 > y) shadowBounds.size.height -= y;
		else if (0.0 < y)  { shadowBounds.origin.y -= y; shadowBounds.size.height += y; }
		// ISFLIPPED でないときは上のwidth方向と同じアルゴリズムになる。 //
		return rotateRect(NSInsetRect(shadowBounds,inset, inset),_rotateAngle); // 線幅に見合う分を増やす。 //
	}
}

// ↓SatoAkira add. //
- (NSColor *)convertColorSpace:(NSColor *)aColor
// ここだけでないところで変換が起きている。どこだか判らない。 //
{
	NSString *name = [aColor colorSpaceName];

	if ((NO == [name isEqualToString:NSPatternColorSpace]) && (NO == [name isEqualToString:NSNamedColorSpace])) {
		NSColorSpace *pColorSpace = [self colorSpace];
		NSColorSpaceModel pColorSpaceModel = (nil != pColorSpace) ? [pColorSpace colorSpaceModel] : NSUnknownColorSpaceModel;
	
		if ((NSUnknownColorSpaceModel != pColorSpaceModel) && (pColorSpaceModel == [[aColor colorSpace] colorSpaceModel])) {
			NSColor *pColor;
			NSInteger compo = [aColor numberOfComponents];
			CGFloat *colorCompo = NSZoneMalloc([self zone],compo * sizeof(CGFloat));

			[aColor getComponents:colorCompo];
			pColor = [NSColor colorWithColorSpace:pColorSpace components:colorCompo count:compo];
			NSZoneFree([self zone],colorCompo);
			return pColor;
		}
		else
			return aColor;
	}
	else
		return aColor;
}
- (void)fillColorSet {
	[[self convertColorSpace:[self fillColor]] setFill];
}
- (void)strokeColorSet {
	[[self convertColorSpace:[self strokeColor]] setStroke];
}
/* - (void)setRotateAngle:(NSNumber *)aRadian {
	_rotateAngle = [aRadian doubleValue];
	[self setBounds:[self bounds]];
} */
- (NSRect)origBounds {
	return _origBounds;
	
}
- (NSBezierPath *)arrowBezierPath:(BOOL)isAtStart {
	return nil;
}
// ↑SatoAkira add. //

/* - (void)drawContentsInView:(NSView *)view isBeingCreateOrEdited:(BOOL)isBeingCreatedOrEditing {

    // If the graphic is so so simple that it can be boiled down to a bezier path then just draw a bezier path. It's -bezierPathForDrawing's responsibility to return a path with the current stroke width.
    NSBezierPath *path = [self bezierPathForDrawing];
    if (path) {
	if ([self isDrawingFill]) {
	    [[self fillColor] set];
	    [path fill];
	}
	if ([self isDrawingStroke]) {
	    [[self strokeColor] set];
	    [path stroke];
	}
    }

} */ // SatoAkira delete. //

- (void)strokeContentsInView:(NSBezierPath *)path
// SatoAkira add. //
{
	if (YES == [self isDrawingStroke]) {
		[self strokeColorSet];
		[path setLineWidth:((YES == [NSGraphicsContext currentContextDrawingToScreen]) && (LIMITWIDTH > [self strokeWidth])) ? LIMITWIDTH : [self strokeWidth]]; // NSImageInterpolationの設定とは無関係。antialiasの影響は受ける。 //
		[path setLineCapStyle:_lineCap];
		[path setLineJoinStyle:_lineJoin];
		addDashStyleToPath(path, _lineDashPattern, _lineDashPhase);
		[path stroke];
	}
}
- (void)drawContentsInView:(NSView *)view isBeingCreateOrEdited:(BOOL)isBeingCreatedOrEditing
// SatoAkira add. //
{
	NSBezierPath *path;
	NSGraphicsContext *currentContext = [NSGraphicsContext currentContext];
	BOOL stroked = NO;
	
	[self setViewColorSpace:[(SKTGraphicView *)view viewColorSpace]];
	path = [self bezierPathForDrawing]; // transformはクリアーしないまま //
	if (nil != path) {
		BOOL shadowFlag = (0.1 > _shadowBlurRadiusValue) ? NO : YES;
		if ((YES == [self isDrawingFill]) && (NO == [self isEditing])) {
			if ((YES == [self shading]) || (YES == [[[self fillColor] colorSpaceName] isEqualToString:NSPatternColorSpace])) {
				if (YES == shadowFlag) {
					[currentContext saveGraphicsState];
					/* NSAffineTransform *transform = [NSAffineTransform transform];
					 [transform rotateByRadians:-1.0 * [self rotateAngle]];
					 [transform concat]; */
					[self shadowSet];
					[[NSColor whiteColor] setFill];
					[path setWindingRule:_windingRule];
					[path fill];
					[self strokeContentsInView:path];
					[currentContext restoreGraphicsState];
					shadowFlag = NO; // FillのみでShadowする。 //
				}
				if (YES == [self shading])
					[self drawShading:path transform:nil];
				else {
					ASPatternModel *pModel = [self patternModel];
					[pModel setBounds:[self bounds] clip:path transform:nil colorSpace:[self colorSpace] winding:_windingRule];
					[pModel fill];
				}
			}
			else {
				[currentContext saveGraphicsState];
				if (YES == shadowFlag) {
					[self shadowSet];
					[self fillColorSet];
					[path setWindingRule:_windingRule];
					[path fill];
					[self strokeContentsInView:path];
					[currentContext restoreGraphicsState];
					[self fillColorSet];
					[path setWindingRule:_windingRule];
					[path fill];
					shadowFlag = NO; // FillのみでShadowする。 //
				}
				else {
					[self fillColorSet];
					[path setWindingRule:_windingRule];
					[path fill];
					[currentContext restoreGraphicsState];
				}
			}
		}
		BOOL saveGraphics = NO; // _shadowBlurRadiusValueがセットされていて、isDrawingFillとisDrawingStrokeが共にセットされていないときrestoreGraphicsStateが実行されないようにするため //
		if ((YES == [self isDrawingStroke]) && (NO == stroked)) {
			// fillしているならばshadowFlagが落ちているのでgraphicStateをshadow有りにすることはない。 //
			if ((YES == shadowFlag) && (NO == [self isEditing])) { // shadow無しの状態になっているgraphicStateなのでshadow有りにする。 //
				[currentContext saveGraphicsState]; // drawHandlesInView:がshadow付きになることを防ぐ為。 //
				[self shadowSet];
				saveGraphics = YES;
			}
			[self strokeContentsInView:path];
		}
		if (_arrowState & SKTArrowOnStart) { // Postscriptと違って一度に両方の処理はできない。 //
			[currentContext saveGraphicsState];
			[self arrowBezierPath:YES]; // fillしているとshadow無しの状態になっている。 //
			[currentContext restoreGraphicsState];
		}
		if (_arrowState & SKTArrowOnEnd) {
			[currentContext saveGraphicsState];
			[self arrowBezierPath:NO];
			[currentContext restoreGraphicsState];
		}
		if ((YES == saveGraphics) && (NO == [self isEditing]))
			[currentContext restoreGraphicsState]; // drawHandlesInView:がshadow付きになることを防ぐ為。 //
		if ((YES == [currentContext isDrawingToScreen]) && ((YES == [self isEditing]) || (YES == [self isCreating]))) {
			[self drawAnchorHandles];
			[self drawControlHandles];
		}
	}
}

- (NSBezierPath *)bezierPathForDrawing {
    
    // Live to be overriden.
    [NSException raise:NSInternalInconsistencyException format:@"Neither -drawContentsInView: nor -bezierPathForDrawing has been overridden."];
    return nil;
    
}

/* - (void)drawHandlesInView:(NSView *)view {

    // Draw handles at the corners and on the sides.
    NSRect bounds = [self bounds];
    [self drawHandleInView:view atPoint:NSMakePoint(NSMinX(bounds), NSMinY(bounds))];
    [self drawHandleInView:view atPoint:NSMakePoint(NSMidX(bounds), NSMinY(bounds))];
    [self drawHandleInView:view atPoint:NSMakePoint(NSMaxX(bounds), NSMinY(bounds))];
    [self drawHandleInView:view atPoint:NSMakePoint(NSMinX(bounds), NSMidY(bounds))];
    [self drawHandleInView:view atPoint:NSMakePoint(NSMaxX(bounds), NSMidY(bounds))];
    [self drawHandleInView:view atPoint:NSMakePoint(NSMinX(bounds), NSMaxY(bounds))];
    [self drawHandleInView:view atPoint:NSMakePoint(NSMidX(bounds), NSMaxY(bounds))];
    [self drawHandleInView:view atPoint:NSMakePoint(NSMaxX(bounds), NSMaxY(bounds))];

} */ // SatoAkira delete. //
- (void)drawHandlesInView:(NSView *)view
// SatoAkira add. //
{
	NSRect bounds = [self bounds];
	NSPoint midPoint = NSMakePoint(NSMidX(bounds),NSMidY(bounds));
	NSPoint knobPoint = NSMakePoint(NSMinX(bounds) - midPoint.x, NSMinY(bounds) - midPoint.y); // UpperLeft //

	[self drawHandleInView:view atPoint:knobPoint];
	knobPoint = NSMakePoint(0.0, NSMinY(bounds) - midPoint.y); // UpperMiddle //
	[self drawHandleInView:view atPoint:knobPoint];
	knobPoint = NSMakePoint(NSMaxX(bounds) - midPoint.x, NSMinY(bounds) - midPoint.y); // UpperRight //
	[self drawHandleInView:view atPoint:knobPoint];
	knobPoint = NSMakePoint(NSMinX(bounds) - midPoint.x, 0.0);
	[self drawHandleInView:view atPoint:knobPoint];
	knobPoint = NSMakePoint(NSMaxX(bounds) - midPoint.x, 0.0);
	[self drawHandleInView:view atPoint:knobPoint];
	knobPoint = NSMakePoint(NSMinX(bounds) - midPoint.x, NSMaxY(bounds) - midPoint.y);
	[self drawHandleInView:view atPoint:knobPoint];
	knobPoint = NSMakePoint(0.0, NSMaxY(bounds) - midPoint.y);
	[self drawHandleInView:view atPoint:knobPoint];
	knobPoint = NSMakePoint(NSMaxX(bounds) - midPoint.x, NSMaxY(bounds) - midPoint.y);
	[self drawHandleInView:view atPoint:knobPoint];
}


- (void)drawHandleInView:(NSView *)view atPoint:(NSPoint)point {

    // Figure out a rectangle that's centered on the point but lined up with device pixels.
    NSRect handleBounds;
    handleBounds.origin.x = point.x - SKTGraphicHandleHalfWidth;
    handleBounds.origin.y = point.y - SKTGraphicHandleHalfWidth;
    handleBounds.size.width = SKTGraphicHandleWidth;
    handleBounds.size.height = SKTGraphicHandleWidth;
    handleBounds = [view centerScanRect:handleBounds];
    
    // Draw the shadow of the handle.
    NSRect handleShadowBounds = NSOffsetRect(handleBounds, 1.0f, 1.0f);
    [[NSColor controlDarkShadowColor] set];
    NSRectFill(handleShadowBounds);

    // Draw the handle itself.
    /* [[NSColor knobColor] set]; */ // SatoAkira delete. //
	[[PreferencesController objectForKey:KnobColorKey] setFill]; // SatoAkira add. //
    NSRectFill(handleBounds);

}


#pragma mark *** Editing ***


+ (NSCursor *)creationCursor {

    // By default we use the crosshairs cursor.
    static NSCursor *crosshairsCursor = nil;
    if (!crosshairsCursor) {
        NSImage *crosshairsImage = [NSImage imageNamed:@"Cross"];
        NSSize crosshairsImageSize = [crosshairsImage size];
        crosshairsCursor = [[NSCursor alloc] initWithImage:crosshairsImage hotSpot:NSMakePoint((crosshairsImageSize.width / 2.0), (crosshairsImageSize.height / 2.0))];
    }
    return crosshairsCursor;

}


+ (NSInteger)creationSizingHandle {

    // Return the number of the handle for the lower-right corner. If the user drags it so that it's no longer in the lower-right, -resizeByMovingHandle:toPoint: will deal with it.
    return SKTGraphicLowerRightHandle;

}


- (BOOL)canSetDrawingFill {

    // The default implementation of -drawContentsInView: can draw fills.
    return YES;

}


- (BOOL)canSetDrawingStroke {

    // The default implementation of -drawContentsInView: can draw strokes.
    return YES;

}


- (BOOL)canMakeNaturalSize {

    // Only return YES if -makeNaturalSize would actually do something.
    NSRect bounds = [self bounds];
    return bounds.size.width!=bounds.size.height;

}


/* - (BOOL)isContentsUnderPoint:(NSPoint)point {

    // Just check against the graphic's bounds.
    return NSPointInRect(point, [self bounds]);

} */ // SatoAkira delete. //
- (BOOL)isContentsUnderPoint:(NSPoint)point
// SatoAkira add. //
// 回転移動に対応。bezierPathForDrawingによる判断をしなくてもよい場合。 //
{
    if (NO == _locked) {
		NSPoint center = NSMakePoint(NSMidX(_bounds),NSMidY(_bounds));
		CGFloat x = (point.x - center.x) * cos(_rotateAngle) + (point.y - center.y) * sin(_rotateAngle);
		CGFloat y = -1.0 * (point.x - center.x) * sin(_rotateAngle) + (point.y - center.y) * cos(_rotateAngle);
#ifdef ISFLIPPED
		return NSPointInRect(NSMakePoint(x,y),NSMakeRect(-0.5 * NSWidth(_bounds),-0.5 * NSHeight(_bounds),NSWidth(_bounds),NSHeight(_bounds)));
#else
		return NSMouseInRect(NSMakePoint(x,y),NSMakeRect(-0.5 * NSWidth(_bounds),-0.5 * NSHeight(_bounds),NSWidth(_bounds),NSHeight(_bounds)),NO);
#endif
	}
	else
		return NO;
}


/* - (NSInteger)handleUnderPoint:(NSPoint)point {
    
    // Check handles at the corners and on the sides.
    NSInteger handle = SKTGraphicNoHandle;
    NSRect bounds = [self bounds];
    if ([self isHandleAtPoint:NSMakePoint(NSMinX(bounds), NSMinY(bounds)) underPoint:point]) {
	handle = SKTGraphicUpperLeftHandle;
    } else if ([self isHandleAtPoint:NSMakePoint(NSMidX(bounds), NSMinY(bounds)) underPoint:point]) {
	handle = SKTGraphicUpperMiddleHandle;
    } else if ([self isHandleAtPoint:NSMakePoint(NSMaxX(bounds), NSMinY(bounds)) underPoint:point]) {
	handle = SKTGraphicUpperRightHandle;
    } else if ([self isHandleAtPoint:NSMakePoint(NSMinX(bounds), NSMidY(bounds)) underPoint:point]) {
	handle = SKTGraphicMiddleLeftHandle;
    } else if ([self isHandleAtPoint:NSMakePoint(NSMaxX(bounds), NSMidY(bounds)) underPoint:point]) {
	handle = SKTGraphicMiddleRightHandle;
    } else if ([self isHandleAtPoint:NSMakePoint(NSMinX(bounds), NSMaxY(bounds)) underPoint:point]) {
	handle = SKTGraphicLowerLeftHandle;
    } else if ([self isHandleAtPoint:NSMakePoint(NSMidX(bounds), NSMaxY(bounds)) underPoint:point]) {
	handle = SKTGraphicLowerMiddleHandle;
    } else if ([self isHandleAtPoint:NSMakePoint(NSMaxX(bounds), NSMaxY(bounds)) underPoint:point]) {
	handle = SKTGraphicLowerRightHandle;
    }
    return handle;

} */ // SatoAkira delete. //
- (NSInteger)handleUnderPoint:(NSPoint)point
// SatoAkira add. ここで座標変換をする。 //
{
	NSInteger handle = SKTGraphicNoHandle;
	NSPoint center = NSMakePoint(NSMidX(_bounds),NSMidY(_bounds));
	double rr = 0.5 * hypot(NSHeight(_bounds),NSWidth(_bounds));
	double aa = (0.0 == NSWidth(_bounds)) ? _rotateAngle + M_PI_2 : _rotateAngle + atan(NSHeight(_bounds) / NSWidth(_bounds));
	CGFloat dx = rr * cos(aa);
	CGFloat dy = rr * sin(aa);

	if (YES == [self isHandleAtPoint:NSMakePoint(center.x - dx, center.y - dy) underPoint:point])
		handle = SKTGraphicUpperLeftHandle;
	else {
		if (YES == [self isHandleAtPoint:NSMakePoint(center.x + dx, center.y + dy) underPoint:point])
			handle = SKTGraphicLowerRightHandle;
	else {
		aa = (0.0 == NSWidth(_bounds)) ? _rotateAngle - M_PI_2 : _rotateAngle - atan (NSHeight(_bounds) / NSWidth(_bounds));
		dx = rr * cos(aa);
		dy = rr * sin(aa);
		if (YES == [self isHandleAtPoint:NSMakePoint(center.x - dx, center.y - dy) underPoint:point])
			handle = SKTGraphicLowerLeftHandle;
	else {
		if (YES == [self isHandleAtPoint:NSMakePoint(center.x + dx, center.y + dy) underPoint:point])
			handle = SKTGraphicUpperRightHandle;
	else {
		rr = 0.5 * NSWidth(_bounds);
		aa = _rotateAngle;
		dx = rr * cos(aa);
		dy = rr * sin(aa);
		if (YES == [self isHandleAtPoint:NSMakePoint(center.x - dx, center.y - dy) underPoint:point])
			handle = SKTGraphicMiddleLeftHandle;
	else {
		if (YES == [self isHandleAtPoint:NSMakePoint(center.x + dx, center.y + dy) underPoint:point])
			handle = SKTGraphicMiddleRightHandle;
	else {
		rr = 0.5 * NSHeight(_bounds);
		aa = _rotateAngle + M_PI_2;
		dx = rr * cos(aa);
		dy = rr * sin(aa);
		if (YES == [self isHandleAtPoint:NSMakePoint(center.x + dx, center.y + dy) underPoint:point])
			handle = SKTGraphicLowerMiddleHandle;
	else {
		if (YES == [self isHandleAtPoint:NSMakePoint(center.x - dx, center.y - dy) underPoint:point])
			handle = SKTGraphicUpperMiddleHandle;
	}}}}}}}
	return handle;
}


- (BOOL)isHandleAtPoint:(NSPoint)handlePoint underPoint:(NSPoint)point {
    
    // Check a handle-sized rectangle that's centered on the handle point.
	// 座標変換無し。 //
    NSRect handleBounds;
    handleBounds.origin.x = handlePoint.x - SKTGraphicHandleHalfWidth;
    handleBounds.origin.y = handlePoint.y - SKTGraphicHandleHalfWidth;
    handleBounds.size.width = SKTGraphicHandleWidth;
    handleBounds.size.height = SKTGraphicHandleWidth;
    return NSPointInRect(point, handleBounds);

}

/* - (NSInteger)resizeByMovingHandle:(NSInteger)handle toPoint:(NSPoint)point {

    // Start with the original bounds.
    NSRect bounds = [self bounds];

	// Is the user changing the width of the graphic?
    if (handle==SKTGraphicUpperLeftHandle || handle==SKTGraphicMiddleLeftHandle || handle==SKTGraphicLowerLeftHandle) {

	// Change the left edge of the graphic.
        bounds.size.width = NSMaxX(bounds) - point.x;
        bounds.origin.x = point.x;

    } else if (handle==SKTGraphicUpperRightHandle || handle==SKTGraphicMiddleRightHandle || handle==SKTGraphicLowerRightHandle) {

	// Change the right edge of the graphic.
        bounds.size.width = point.x - bounds.origin.x;

    }

    // Did the user actually flip the graphic over?
    if (bounds.size.width<0.0f) {

	// The handle is now playing a different role relative to the graphic.
	static NSInteger flippings[9];
	static BOOL flippingsInitialized = NO;
	if (!flippingsInitialized) {
	    flippings[SKTGraphicUpperLeftHandle] = SKTGraphicUpperRightHandle;
	    flippings[SKTGraphicUpperMiddleHandle] = SKTGraphicUpperMiddleHandle;
	    flippings[SKTGraphicUpperRightHandle] = SKTGraphicUpperLeftHandle;
	    flippings[SKTGraphicMiddleLeftHandle] = SKTGraphicMiddleRightHandle;
	    flippings[SKTGraphicMiddleRightHandle] = SKTGraphicMiddleLeftHandle;
	    flippings[SKTGraphicLowerLeftHandle] = SKTGraphicLowerRightHandle;
	    flippings[SKTGraphicLowerMiddleHandle] = SKTGraphicLowerMiddleHandle;
	    flippings[SKTGraphicLowerRightHandle] = SKTGraphicLowerLeftHandle;
	    flippingsInitialized = YES;
	}
        handle = flippings[handle];

	// Make the graphic's width positive again.
        bounds.size.width = 0.0f - bounds.size.width;
        bounds.origin.x -= bounds.size.width;

	// Tell interested subclass code what just happened.
        [self flipHorizontally];

    }
    
    // Is the user changing the height of the graphic?
    if (handle==SKTGraphicUpperLeftHandle || handle==SKTGraphicUpperMiddleHandle || handle==SKTGraphicUpperRightHandle) {

	// Change the top edge of the graphic.
        bounds.size.height = NSMaxY(bounds) - point.y;
        bounds.origin.y = point.y;

    } else if (handle==SKTGraphicLowerLeftHandle || handle==SKTGraphicLowerMiddleHandle || handle==SKTGraphicLowerRightHandle) {

	// Change the bottom edge of the graphic.
	bounds.size.height = point.y - bounds.origin.y;

    }

    // Did the user actually flip the graphic upside down?
    if (bounds.size.height<0.0f) {

	// The handle is now playing a different role relative to the graphic.
	static NSInteger flippings[9];
	static BOOL flippingsInitialized = NO;
	if (!flippingsInitialized) {
	    flippings[SKTGraphicUpperLeftHandle] = SKTGraphicLowerLeftHandle;
	    flippings[SKTGraphicUpperMiddleHandle] = SKTGraphicLowerMiddleHandle;
	    flippings[SKTGraphicUpperRightHandle] = SKTGraphicLowerRightHandle;
	    flippings[SKTGraphicMiddleLeftHandle] = SKTGraphicMiddleLeftHandle;
	    flippings[SKTGraphicMiddleRightHandle] = SKTGraphicMiddleRightHandle;
	    flippings[SKTGraphicLowerLeftHandle] = SKTGraphicUpperLeftHandle;
	    flippings[SKTGraphicLowerMiddleHandle] = SKTGraphicUpperMiddleHandle;
	    flippings[SKTGraphicLowerRightHandle] = SKTGraphicUpperRightHandle;
	    flippingsInitialized = YES;
	}
        handle = flippings[handle];
	
	// Make the graphic's height positive again.
        bounds.size.height = 0.0f - bounds.size.height;
        bounds.origin.y -= bounds.size.height;

	// Tell interested subclass code what just happened.
        [self flipVertically];

    }

    // Done.
    [self setBounds:bounds];
    return handle;

} */ // SatoAkira delete. //
- (NSInteger)resizeByMovingHandle:(NSInteger)handle toPoint:(NSPoint)point
// SatoAkira add. //
// 回転移動対応。createWithEvent:からも呼ばれるので要注意。handleは見た目とは異なる。回転移動していれば見た目がlowerLeftでもupperRightになる。 //
{
	CGFloat dw;
	NSRect bounds = [self bounds];
	double angle = _rotateAngle;
	NSPoint center = NSMakePoint(NSMidX(bounds),NSMidY(bounds));
	NSPoint p = NSMakePoint((point.x - center.x) * cos(angle) + (point.y - center.y) * sin(angle),-1.0 * (point.x - center.x) * sin(angle) + (point.y - center.y) * cos(angle));

	if ((SKTGraphicUpperRightHandle == handle) || (SKTGraphicMiddleRightHandle == handle) || (SKTGraphicLowerRightHandle == handle)) { // Change the right edge of the graphic. //
		dw = p.x - 0.5 * NSWidth(bounds);
		bounds.size.width += dw;
		bounds.origin.x += 0.5 * dw * (cos(angle) - 1.0);
		bounds.origin.y += 0.5 * dw * sin(angle);
		if (YES == _isSquareBounds) {
			if (SKTGraphicMiddleRightHandle == handle) { // heightの増減もwidthの増減と同じなのでheight方向への補正もしてしまう。 //
				bounds.origin.x -= 0.5 * dw * sin(angle); // MiddleRightHandleのときOK。LowerRightHandleのときangleが0.0ならばOK。 //
				bounds.origin.y += 0.5 * dw * (cos(angle) - 1.0); // MiddleRightHandleのときOK //
			}
		}
	}
	else {
		if ((SKTGraphicUpperLeftHandle == handle) || (SKTGraphicMiddleLeftHandle == handle) || (SKTGraphicLowerLeftHandle == handle)) { // Change the left edge of the graphic. //
			dw = -0.5 * NSWidth(bounds) - p.x;
			bounds.size.width += dw;
			bounds.origin.x -= 0.5 * dw * (cos(angle) + 1.0);
			bounds.origin.y -= 0.5 * dw * sin(angle);
			if (YES == _isSquareBounds) {
				if (SKTGraphicMiddleLeftHandle == handle) {
					bounds.origin.x -= 0.5 * dw * sin(angle); // MiddleLeftHandleのときOK。LowerLeftHandleのときangleが0.0ならばOK。 //
					bounds.origin.y += 0.5 * dw * (cos(angle) - 1.0); // MiddleLeftHandleのときOK //
				}
			}
		}
	}
	if (NSWidth(bounds) < 0.0) {
		static NSInteger flippings[9];
		static BOOL flippingsInitialized = NO;
		if (NO == flippingsInitialized) {
			flippings[SKTGraphicUpperLeftHandle] = SKTGraphicUpperRightHandle;
			flippings[SKTGraphicUpperMiddleHandle] = SKTGraphicUpperMiddleHandle;
			flippings[SKTGraphicUpperRightHandle] = SKTGraphicUpperLeftHandle;
			flippings[SKTGraphicMiddleLeftHandle] = SKTGraphicMiddleRightHandle;
			flippings[SKTGraphicMiddleRightHandle] = SKTGraphicMiddleLeftHandle;
			flippings[SKTGraphicLowerLeftHandle] = SKTGraphicLowerRightHandle;
			flippings[SKTGraphicLowerMiddleHandle] = SKTGraphicLowerMiddleHandle;
			flippings[SKTGraphicLowerRightHandle] = SKTGraphicLowerLeftHandle;
			flippingsInitialized = YES;
		}
		handle = flippings[handle];
		bounds.origin.x += NSWidth(bounds);
		bounds.size.width *= -1.0;
		[self flipHorizontally];
	}

	if ((SKTGraphicLowerLeftHandle == handle) || (SKTGraphicLowerMiddleHandle == handle) || (SKTGraphicLowerRightHandle == handle)) { // Change the bottom edge of the graphic. //
		dw = p.y - 0.5 * NSHeight(bounds);
		bounds.size.height += dw;
		bounds.origin.x -= 0.5 * dw * sin(angle);
		bounds.origin.y += 0.5 * dw * (cos(angle) - 1.0);
		if (YES == _isSquareBounds) {
			if (SKTGraphicLowerMiddleHandle == handle) {
				bounds.origin.x += 0.5 * dw * (cos(angle) - 1.0); // LowerMiddleHandleのときOK //
				bounds.origin.y += 0.5 * dw * sin(angle); // LowerMiddleHandleのときOK //
			}
		}
	}
	else {
		if ((SKTGraphicUpperLeftHandle == handle) || (SKTGraphicUpperMiddleHandle == handle) || (SKTGraphicUpperRightHandle == handle)) { // Change the top edge of the graphic. //
			dw = -0.5 * NSHeight(bounds) - p.y;
			bounds.size.height += dw;
			bounds.origin.x += 0.5 * dw * sin(angle);
			bounds.origin.y -= 0.5 * dw * (cos(angle) + 1.0);
			if (YES == _isSquareBounds) {
				if (SKTGraphicUpperMiddleHandle == handle) {
					bounds.origin.x += 0.5 * dw * (cos(angle) - 1.0); // UpperMiddleHandleのときOK //
					bounds.origin.y += 0.5 * dw * sin(angle); // UpperMiddleHandleのときOK //
				}
			}
		}
	}
	if (NSHeight(bounds) < 0.0) {
		static NSInteger flippings[9];
		static BOOL flippingsInitialized = NO;
		if (NO == flippingsInitialized) {
			flippings[SKTGraphicUpperLeftHandle] = SKTGraphicLowerLeftHandle;
			flippings[SKTGraphicUpperMiddleHandle] = SKTGraphicLowerMiddleHandle;
			flippings[SKTGraphicUpperRightHandle] = SKTGraphicLowerRightHandle;
			flippings[SKTGraphicMiddleLeftHandle] = SKTGraphicMiddleLeftHandle;
			flippings[SKTGraphicMiddleRightHandle] = SKTGraphicMiddleRightHandle;
			flippings[SKTGraphicLowerLeftHandle] = SKTGraphicUpperLeftHandle;
			flippings[SKTGraphicLowerMiddleHandle] = SKTGraphicUpperMiddleHandle;
			flippings[SKTGraphicLowerRightHandle] = SKTGraphicUpperRightHandle;
			flippingsInitialized = YES;
		}
		handle = flippings[handle];
		bounds.origin.y += NSHeight(bounds);
		bounds.size.height *= -1.0;
		[self flipVertically];
	}
	if (YES == _isSquareBounds) {
		if ((SKTGraphicMiddleRightHandle == handle) || (SKTGraphicMiddleLeftHandle == handle))
			bounds.size.height = NSWidth(bounds);
		else {
			if ((SKTGraphicUpperMiddleHandle == handle) || (SKTGraphicLowerMiddleHandle == handle))
				bounds.size.width = NSHeight(bounds);
			else {
				if (YES == [self isCreating])
					bounds.size.height = NSWidth(bounds);
			}
		}
	}
	[self setBounds:bounds];
	return handle;
}
- (void)constrainCorner:(NSInteger)knob toAspectRatio:(CGFloat)aspect
// SatoAkira add. //
/*
 * Modifies the bounds rectangle by moving the specified corner so that
 * the Graphic maintains the specified aspect ratio.  This is used during
 * constrained resizing.  Can be overridden if the aspect ratio is not
 * sufficient to constrain resizing.
 */
{
	NSRect bounds = [self bounds];

	if ((0.0 != NSHeight(bounds) * NSWidth(bounds)) && (0.0 != aspect)) {
		CGFloat actualAspect = NSWidth(bounds) / NSHeight(bounds);

		if (actualAspect != aspect) {
			NSInteger recursiveKnob;

			switch (knob) {
				case SKTGraphicMiddleLeftHandle:
					bounds.origin.x -= NSHeight(bounds) * aspect - NSWidth(bounds);
					// non break; //
				case SKTGraphicMiddleRightHandle:
					bounds.size.width = NSHeight(bounds) * aspect;
					[self setBounds:bounds];
					recursiveKnob = SKTGraphicNoHandle;
					break;
				case SKTGraphicUpperMiddleHandle: // flippedでないときは下のcaseと入れ替える。 //bounds	9;
					bounds.origin.y -= NSWidth(bounds) / aspect - NSHeight(bounds); // ISFLIPPED //
					// non break //
				case SKTGraphicLowerMiddleHandle:
					bounds.size.height = NSWidth(bounds) / aspect; // ISFLIPPED //
					[self setBounds:bounds];
					recursiveKnob = SKTGraphicNoHandle;
					break;
				case SKTGraphicLowerLeftHandle:
					recursiveKnob = (actualAspect > aspect) ? SKTGraphicMiddleLeftHandle : SKTGraphicLowerMiddleHandle;
					break;
				case SKTGraphicUpperRightHandle:
					recursiveKnob = (actualAspect > aspect) ? SKTGraphicMiddleRightHandle : SKTGraphicUpperMiddleHandle;
					break;
				case SKTGraphicUpperLeftHandle:
					recursiveKnob = (actualAspect > aspect) ? SKTGraphicMiddleLeftHandle : SKTGraphicUpperMiddleHandle;
					break;
				case SKTGraphicLowerRightHandle:
					recursiveKnob = (actualAspect > aspect) ? SKTGraphicMiddleRightHandle : SKTGraphicLowerMiddleHandle;
					break;
				default:
					recursiveKnob = SKTGraphicNoHandle;
					break;
			}
			if (SKTGraphicNoHandle != recursiveKnob)
				[self constrainCorner:recursiveKnob toAspectRatio:aspect];
		}
	}
}

- (void)flipHorizontally {
    
    // Live to be overridden.

}


- (void)flipVertically {
    
    // Live to be overridden.

}


- (void)makeNaturalSize {

    // Just make the graphic square.
    NSRect bounds = [self bounds];
    if (bounds.size.width<bounds.size.height) {
        bounds.size.height = bounds.size.width;
        [self setBounds:bounds];
    } else if (bounds.size.width>bounds.size.height) {
        bounds.size.width = bounds.size.height;
        [self setBounds:bounds];
    }
    
}


- (void)setBounds:(NSRect)bounds {

    // Simple.
    _bounds = bounds;

}

// fillColor専用。SKTGraphicViewのperformDragOperationから使われる。changeColor:からも使われていたが廃止した。changeColor:の方はNSColorPanelからなのでfillColor以外にもcolorPanelが使われると駄目なのだ。 //
- (void)setColor:(NSColor *)color {

    // This method demonstrates something interesting: we haven't bothered to provide setter methods for the properties we want to change, but we can still change them using KVC. KVO autonotification will make sure observers hear about the change (it works with -setValue:forKey: as well as -set<Key>:). Of course, if we found ourselvings doing this a little more often we would go ahead and just add the setter methods. The point is that KVC direct instance variable access very often makes boilerplate accessors unnecessary but if you want to just put them in right away, eh, go ahead.

    // Can we fill the graphic?
    if ([self canSetDrawingFill]) {

	// Are we filling it? If not, start, using the new color.
	if (![self isDrawingFill]) {
	    [self setValue:[NSNumber numberWithBool:YES] forKey:SKTGraphicIsDrawingFillKey];
	}
	[self setValue:color forKey:SKTGraphicFillColorKey];

    }

}


/* - (NSView *)newEditingViewWithSuperviewBounds:(NSRect)superviewBounds {
    
    // Live to be overridden.
    return nil;

} */
- (NSView *)newEditingViewWithSuperviewBounds:(NSRect)superviewBounds view:(NSView *)graphicView { // SatoAkira add. //
	return nil;
}


/* - (void)finalizeEditingView:(NSView *)editingView {
    
    // Live to be overridden.
    
} */ // SatoAkira delete. //
- (void)finalizeEditingView:(NSView *)editingView view:(NSView *)grpahicView { // SatoAkira add. //
	// 何もしない。 //
}


#pragma mark *** Undo ***


- (NSSet *)keysForValuesToObserveForUndo {

    // Of the properties managed by SKTGraphic, "drawingingBounds," "drawingContents," "canSetDrawingFill," and "canSetDrawingStroke" aren't anything that the user changes, so changes of their values aren't registered undo operations. "xPosition," "yPosition," "width," and "height" are all derived from "bounds," so we don't need to register those either. Changes of any other property are undoable.
    /* return [NSSet setWithObjects:SKTGraphicIsDrawingFillKey, SKTGraphicFillColorKey, SKTGraphicIsDrawingStrokeKey, SKTGraphicStrokeColorKey, SKTGraphicStrokeWidthKey, SKTGraphicBoundsKey, nil]; */
    return [NSSet setWithObjects:SKTGraphicIsDrawingFillKey, SKTGraphicFillColorKey, SKTGraphicIsDrawingStrokeKey, SKTGraphicStrokeColorKey, SKTGraphicStrokeWidthKey, SKTGraphicBoundsKey, SKTArrowStateKey,SKTWindingRuleKey,SKTLineJoinKey,SKTLineCapKey,SKTShadowBlurRadiusKey,SKTShadowOffsetPointKey,SKTShadowColorKey,SKTRotateAngleKey,SKTLockedKey,SKTShadowOffsetXKey,SKTShadowOffsetYKey,SKTLineDashPhaseKey,SKTLineDashPatternKey,SKTShadingKey,SKTShadingStyleKey,SKTShadingAxialAngleKey,SKTShadingColorPositionKey,SKTShadingRadialCenterKey,SKTShadingColorKey, nil];

}


+ (NSString *)presentablePropertyNameForKey:(NSString *)key {
    
    // Pretty simple. Don't be surprised if you never see "Bounds" appear in an undo action name in Sketch. SKTGraphicView invokes -[NSUndoManager setActionName:] for things like moving, resizing, and aligning, thereby overwriting whatever SKTDocument sets with something more specific.
    static NSDictionary *presentablePropertyNamesByKey = nil;
    if (!presentablePropertyNamesByKey) {
	/* presentablePropertyNamesByKey = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
	    NSLocalizedStringFromTable(@"Filling", @"UndoStrings", @"Action name part for SKTGraphicIsDrawingFillKey."), SKTGraphicIsDrawingFillKey,
	    NSLocalizedStringFromTable(@"Fill Color", @"UndoStrings",@"Action name part for SKTGraphicFillColorKey."), SKTGraphicFillColorKey,
	    NSLocalizedStringFromTable(@"Stroking", @"UndoStrings", @"Action name part for SKTGraphicIsDrawingStrokeKey."), SKTGraphicIsDrawingStrokeKey,
	    NSLocalizedStringFromTable(@"Stroke Color", @"UndoStrings", @"Action name part for SKTGraphicStrokeColorKey."), SKTGraphicStrokeColorKey,
	    NSLocalizedStringFromTable(@"Stroke Width", @"UndoStrings", @"Action name part for SKTGraphicStrokeWidthKey."), SKTGraphicStrokeWidthKey,
	    NSLocalizedStringFromTable(@"Bounds", @"UndoStrings", @"Action name part for SKTGraphicBoundsKey."), SKTGraphicBoundsKey,
	    nil]; */ // SatoAkira delete. //
		NSString *tableName = @"UndoStrings";
		presentablePropertyNamesByKey = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
	    NSLocalizedStringFromTable(@"Filling", tableName, @"Action name part for SKTGraphicIsDrawingFillKey."), SKTGraphicIsDrawingFillKey,
	    NSLocalizedStringFromTable(@"Fill Color", tableName,@"Action name part for SKTGraphicFillColorKey."), SKTGraphicFillColorKey,
	    NSLocalizedStringFromTable(@"Stroking", tableName, @"Action name part for SKTGraphicIsDrawingStrokeKey."), SKTGraphicIsDrawingStrokeKey,
	    NSLocalizedStringFromTable(@"Stroke Color", tableName, @"Action name part for SKTGraphicStrokeColorKey."), SKTGraphicStrokeColorKey,
	    NSLocalizedStringFromTable(@"Stroke Width", tableName, @"Action name part for SKTGraphicStrokeWidthKey."), SKTGraphicStrokeWidthKey,
	    NSLocalizedStringFromTable(@"Bounds", tableName, @"Action name part for SKTGraphicBoundsKey."), SKTGraphicBoundsKey,
		NSLocalizedStringFromTable(SKTArrowStateKey,tableName,@""),SKTArrowStateKey,
		NSLocalizedStringFromTable(SKTWindingRuleKey,tableName,@""),SKTWindingRuleKey,
		NSLocalizedStringFromTable(SKTLineJoinKey,tableName,@""),SKTLineJoinKey,
		NSLocalizedStringFromTable(SKTLineCapKey,tableName,@""),SKTLineCapKey,
		NSLocalizedStringFromTable(SKTShadowBlurRadiusKey,tableName,@""),SKTShadowBlurRadiusKey,
		NSLocalizedStringFromTable(SKTShadowColorKey,tableName,@""),SKTShadowColorKey,
		NSLocalizedStringFromTable(SKTRotateAngleKey,tableName,@""),SKTRotateAngleKey,
		NSLocalizedStringFromTable(SKTLockedKey,tableName,@""),SKTLockedKey,
		NSLocalizedStringFromTable(SKTShadowOffsetPointKey,tableName,@""),SKTShadowOffsetPointKey,
		NSLocalizedStringFromTable(SKTLineDashPhaseKey,tableName,@""),SKTLineDashPhaseKey,
		NSLocalizedStringFromTable(SKTLineDashPatternKey,tableName,@""),SKTLineDashPatternKey,
		NSLocalizedStringFromTable(SKTShadingKey,tableName,@""),SKTShadingKey,
		NSLocalizedStringFromTable(SKTShadingStyleKey,tableName,@""),SKTShadingStyleKey,
		NSLocalizedStringFromTable(SKTShadingAxialAngleKey,tableName,@""),SKTShadingAxialAngleKey,
		NSLocalizedStringFromTable(SKTShadingColorPositionKey,tableName,@""),SKTShadingColorPositionKey,
		NSLocalizedStringFromTable(SKTShadingRadialCenterKey,tableName,@""),SKTShadingRadialCenterKey,
		NSLocalizedStringFromTable(SKTShadingColorKey,tableName,@""),SKTShadingColorKey,
	    nil]; // SatoAkira add. //
    }
    return [presentablePropertyNamesByKey objectForKey:key];

}


#pragma mark *** Scripting ***


- (void)setScriptingContainer:(NSObject *)scriptingContainer {

    // Don't retain the container. It's supposed to be retaining this object.
    _scriptingContainer = scriptingContainer;

}


// Conformance to the NSObject(NSScriptObjectSpecifiers) informal protocol.
- (NSScriptObjectSpecifier *)objectSpecifier {

    // This object can't create an object specifier for itself, so ask its scriptable container to do it.
    NSScriptObjectSpecifier *objectSpecifier = [_scriptingContainer objectSpecifierForGraphic:self];
    if (!objectSpecifier) {
	[NSException raise:NSInternalInconsistencyException format:@"A scriptable graphic has no scriptable container, or one that doesn't implement -objectSpecifierForGraphic: correctly."];
    }
    return objectSpecifier;

}


- (NSColor *)scriptingFillColor {

    // Return nil if the graphic is not filled. The scripter will see that as "missing value."
    return [self isDrawingFill] ? [self fillColor] : nil;

}


- (NSColor *)scriptingStrokeColor {

    // Return nil if the graphic is not stroked. The scripter will see that as "missing value."
    return [self isDrawingStroke] ? [self strokeColor] : nil;

}


- (NSNumber *)scriptingStrokeWidth {

    // Return nil if the graphic is not stroked. The scripter will see that as "missing value."
    return [self isDrawingStroke] ? [NSNumber numberWithDouble:[self strokeWidth]] : nil;

}


- (void)setScriptingFillColor:(NSColor *)fillColor {

    // See the comment in -setColor: about using KVC like we do here.

    // For the convenience of scripters, turn filling on or off if necessary, if that's allowed. Don't forget that -isDrawingFill can return YES or NO regardless of what -canSetDrawingFill is returning.
    if (fillColor) {
	BOOL canSetFillColor = YES;
	if (![self isDrawingFill]) {
	    if ([self canSetDrawingFill]) {
		[self setValue:[NSNumber numberWithBool:YES] forKey:SKTGraphicIsDrawingFillKey];
	    } else {

		// Not allowed. Tell the scripter what happened.
		NSScriptCommand *currentScriptCommand = [NSScriptCommand currentCommand];
		[currentScriptCommand setScriptErrorNumber:errAEEventFailed];
		[currentScriptCommand setScriptErrorString:NSLocalizedStringFromTable(@"You can't set the fill color of this kind of graphic.", @"SKTGraphic", @"A scripting error message.")];
		canSetFillColor = NO;

	    }
	}
	if (canSetFillColor) {
	    [self setValue:fillColor forKey:SKTGraphicFillColorKey];
	}
    } else {
	if ([self isDrawingFill]) {
	    if ([self canSetDrawingFill]) {
		[self setValue:[NSNumber numberWithBool:NO] forKey:SKTGraphicIsDrawingFillKey];
	    } else {

		// Not allowed. Tell the scripter what happened.
		NSScriptCommand *currentScriptCommand = [NSScriptCommand currentCommand];
		[currentScriptCommand setScriptErrorNumber:errAEEventFailed];
		[currentScriptCommand setScriptErrorString:NSLocalizedStringFromTable(@"You can't remove the fill from this kind of graphic.", @"SKTGraphic", @"A scripting error message.")];

	    }
	}
    }

}


// The same as above, but for stroke color instead of fill color.
- (void)setScriptingStrokeColor:(NSColor *)strokeColor {
    if (strokeColor) {
	BOOL canSetStrokeColor = YES;
	if (![self isDrawingStroke]) {
	    if ([self canSetDrawingStroke]) {
		[self setValue:[NSNumber numberWithBool:YES] forKey:SKTGraphicIsDrawingStrokeKey];
	    } else {
		NSScriptCommand *currentScriptCommand = [NSScriptCommand currentCommand];
		[currentScriptCommand setScriptErrorNumber:errAEEventFailed];
		[currentScriptCommand setScriptErrorString:NSLocalizedStringFromTable(@"You can't set the stroke color of this kind of graphic.", @"SKTGraphic", @"A scripting error message.")];
		canSetStrokeColor = NO;
	    }
	}
	if (canSetStrokeColor) {
	    [self setValue:strokeColor forKey:SKTGraphicStrokeColorKey];
	}
    } else {
	if ([self isDrawingStroke]) {
	    if ([self canSetDrawingStroke]) {
		[self setValue:[NSNumber numberWithBool:NO] forKey:SKTGraphicIsDrawingStrokeKey];
	    } else {
		NSScriptCommand *currentScriptCommand = [NSScriptCommand currentCommand];
		[currentScriptCommand setScriptErrorNumber:errAEEventFailed];
		[currentScriptCommand setScriptErrorString:NSLocalizedStringFromTable(@"You can't remove the stroke from this kind of graphic.", @"SKTGraphic", @"A scripting error message.")];
	    }
	}
    }
}


- (void)setScriptingStrokeWidth:(NSNumber *)strokeWidth {

    // See the comment in -setColor: about using KVC like we do here.

    // For the convenience of scripters, turn stroking on or off if necessary, if that's allowed. Don't forget that -isDrawingStroke can return YES or NO regardless of what -canSetDrawingStroke is returning.
    if (strokeWidth) {
	BOOL canSetStrokeWidth = YES;
	if (![self isDrawingStroke]) {
	    if ([self canSetDrawingStroke]) {
		[self setValue:[NSNumber numberWithBool:YES] forKey:SKTGraphicIsDrawingStrokeKey];
	    } else {

		// Not allowed. Tell the scripter what happened.
		NSScriptCommand *currentScriptCommand = [NSScriptCommand currentCommand];
		[currentScriptCommand setScriptErrorNumber:errAEEventFailed];
		[currentScriptCommand setScriptErrorString:NSLocalizedStringFromTable(@"You can't set the stroke thickness of this kind of graphic.", @"SKTGraphic", @"A scripting error message.")];
		canSetStrokeWidth = NO;

	    }
	}
	if (canSetStrokeWidth) {
	    [self setValue:strokeWidth forKey:SKTGraphicStrokeWidthKey];
	}
    } else {
	if ([self isDrawingStroke]) {
	    if ([self canSetDrawingStroke]) {
		[self setValue:[NSNumber numberWithBool:NO] forKey:SKTGraphicIsDrawingStrokeKey];
	    } else {

		// Not allowed. Tell the scripter what happened.
		NSScriptCommand *currentScriptCommand = [NSScriptCommand currentCommand];
		[currentScriptCommand setScriptErrorNumber:errAEEventFailed];
		[currentScriptCommand setScriptErrorString:NSLocalizedStringFromTable(@"You can't remove the stroke from this kind of graphic.", @"SKTGraphic", @"A scripting error message.")];

	    }
	}
    }

}


#pragma mark *** Debugging ***


// An override of the NSObject method.
- (NSString *)description {

    // Make 'po aGraphic' do something useful in gdb.
    return [[self properties] description];

}


@end
