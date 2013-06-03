//
//  ASShadingModel.m
//
//  Created by 佐藤 昭 on  07/09/02.
//  Copyright 2007 SatoAkira. All rights reserved.
//

#import "ASShadingModel.h"

@implementation ASShadingModel

NSString *ASShadingStyleKey = @"ASShadingStyle";
NSString *ASShadingStartColorKey = @"ASShadingStartColor";
NSString *ASShadingMidColorKey = @"ASShadingMidColor";
NSString *ASShadingEndColorKey = @"ASShadingEndColor";
NSString *ASShadingAxialAngleKey = @"ASShadingAxialAngle";
NSString *ASShadingRadialCenterKey = @"ASShadingRadialCenter";
NSString *ASShadingColorPositionKey = @"ASShadingColorPosition";

- (void)makeMidColor:(ASShadingStyle)aValue
{
	NSUInteger i,count;
	CGFloat *tempStartC,*tempMidC,*tempEndC;
	CGFloat *startC = (CGFloat *)NULL;
	CGFloat *endC = (CGFloat *)NULL;
	CGFloat *midC = (CGFloat *)NULL;

	switch (aValue) {
		case ASNoneShading:
			[startColor release];
			[endColor release];
			count = [midColor numberOfComponents];
			tempMidC = (CGFloat *)NSZoneMalloc([self zone],count * sizeof(CGFloat));
			[midColor getComponents:tempMidC];
			
			switch ([[midColor colorSpace] colorSpaceModel]) {
				case NSCMYKColorSpaceModel:
					startColor = [[NSColor colorWithDeviceCyan:*tempMidC magenta:*(tempMidC + 1) yellow:*(tempMidC + 2) black:*(tempMidC + 3) alpha:*(tempMidC + 4)] retain];
					endColor = [[NSColor colorWithDeviceCyan:*tempMidC magenta:*(tempMidC + 1) yellow:*(tempMidC + 2) black:*(tempMidC + 3) alpha:*(tempMidC + 4)] retain];
					break;
				case NSRGBColorSpaceModel:
					startColor = [[NSColor colorWithCalibratedRed:*tempMidC green:*(tempMidC + 1) blue:*(tempMidC + 2) alpha:*(tempMidC + 3)] retain];
					endColor = [[NSColor colorWithCalibratedRed:*tempMidC green:*(tempMidC + 1) blue:*(tempMidC + 2) alpha:*(tempMidC + 3)] retain];
					break;
				case NSGrayColorSpaceModel:
					startColor = [[NSColor colorWithCalibratedWhite:*tempMidC alpha:*(tempMidC + 1)] retain];
					endColor = [[NSColor colorWithCalibratedWhite:*tempMidC alpha:*(tempMidC + 1)] retain];
					break;
				case NSLABColorSpaceModel: case NSDeviceNColorSpaceModel:
					startColor = [[NSColor colorWithColorSpace:[NSColorSpace genericRGBColorSpace] components:tempMidC count:count] retain];
					endColor = [[NSColor colorWithColorSpace:[NSColorSpace genericRGBColorSpace] components:tempMidC count:count] retain];
					break;
				default: // 無意味 //
					startColor = [[NSColor colorWithCalibratedRed:*tempMidC green:*(tempMidC + 1) blue:*(tempMidC + 2) alpha:*(tempMidC + 3)] retain];
					endColor = [[NSColor colorWithCalibratedRed:*tempMidC green:*(tempMidC + 1) blue:*(tempMidC + 2) alpha:*(tempMidC + 3)] retain];
					break;
			}
			NSZoneFree([self zone],tempMidC);
			startC = (CGFloat *)NSZoneMalloc([self zone],[startColor numberOfComponents] * sizeof(CGFloat));
			[startColor getComponents:startC];
			endC = (CGFloat *)NSZoneMalloc([self zone],[endColor numberOfComponents] * sizeof(CGFloat));
			[endColor getComponents:endC];
			break;
		case ASAxialShading: case ASRadialShading:
			[midColor release];
			count = [startColor numberOfComponents];
			tempStartC = (CGFloat *)NSZoneMalloc([self zone],[startColor numberOfComponents] * sizeof(CGFloat));
			tempMidC = (CGFloat *)NSZoneMalloc([self zone],count * sizeof(CGFloat));
			tempEndC = (CGFloat *)NSZoneMalloc([self zone],[endColor numberOfComponents] * sizeof(CGFloat));
			[startColor getComponents:tempStartC];
			[endColor getComponents:tempEndC];
			for (i = 0; i < count; i++)
				*tempMidC++ = 0.5 * (*tempStartC++ + *tempEndC++);
			tempStartC -= count;
			tempMidC -= count;
			tempEndC -= count;
			
			switch ([[startColor colorSpace] colorSpaceModel]) {
				case NSCMYKColorSpaceModel:
					midColor = [[NSColor colorWithDeviceCyan:*tempMidC magenta:*(tempMidC + 1) yellow:*(tempMidC + 2) black:*(tempMidC + 3) alpha:*(tempMidC + 4)] retain];
					break;
				case NSRGBColorSpaceModel:
					midColor = [[NSColor colorWithCalibratedRed:*tempMidC green:*(tempMidC + 1) blue:*(tempMidC + 2) alpha:*(tempMidC + 3)] retain];
					break;
				case NSGrayColorSpaceModel:
					midColor = [[NSColor colorWithCalibratedWhite:*tempMidC alpha:*(tempMidC + 1)] retain];
					break;
				case NSLABColorSpaceModel: case NSDeviceNColorSpaceModel:
					midColor = [[NSColor colorWithColorSpace:[NSColorSpace genericRGBColorSpace] components:tempMidC count:count] retain];
					break;
				default: // 無意味 //
					midColor = [[NSColor colorWithCalibratedRed:*tempMidC green:*(tempMidC + 1) blue:*(tempMidC + 2) alpha:*(tempMidC + 3)] retain];
					break;
			}
			NSZoneFree([self zone],tempStartC);
			NSZoneFree([self zone],tempMidC);
			NSZoneFree([self zone],tempEndC);
			midC = (CGFloat *)NSZoneMalloc([self zone],[midColor numberOfComponents] * sizeof(CGFloat));
			[midColor getComponents:midC];
			break;
		case ASDoubleAxialShading: case ASDoubleRadialShading:
			break;
		default:
			break;
	}
}

- (id)initWithDictionary:(NSDictionary *)aDic
{
	id obj;
	CGFloat *startC,*midC,*endC;

	self = [super init];
	if (nil != (obj = [aDic objectForKey:ASShadingStyleKey]))
		shadingStyle = [obj intValue];
	else
		shadingStyle = ASDoubleAxialShading; // midColorを平均値にしないのでDoubleとなる。 //
	if (nil != (obj = [aDic objectForKey:ASShadingStartColorKey]))
		startColor = [[NSUnarchiver unarchiveObjectWithData:obj] retain];
	else
		startColor = [[NSColor colorWithCalibratedRed:1.0 green:0.0 blue:0.0 alpha:1.0] retain];
	startC = (CGFloat *)NSZoneMalloc([self zone],[startColor numberOfComponents] * sizeof(CGFloat));
	[startColor getComponents:startC];
	if (nil != (obj = [aDic objectForKey:ASShadingMidColorKey]))
		midColor = [[NSUnarchiver unarchiveObjectWithData:obj] retain];
	else
		midColor = [[NSColor colorWithCalibratedRed:0.0 green:1.0 blue:0.0 alpha:1.0] retain];
	midC = (CGFloat *)NSZoneMalloc([self zone],[midColor numberOfComponents] * sizeof(CGFloat));
	[midColor getComponents:midC];
	if (nil != (obj = [aDic objectForKey:ASShadingEndColorKey]))
		endColor = [[NSUnarchiver unarchiveObjectWithData:obj] retain];
	else
		endColor = [[NSColor colorWithCalibratedRed:0.0 green:0.0 blue:1.0 alpha:1.0] retain];
	endC = (CGFloat *)NSZoneMalloc([self zone],[endColor numberOfComponents] * sizeof(CGFloat));
	[endColor getComponents:endC];
	// 同じ色の場合に同じアドレスになってしまうので、非常に難しい。他のところで注意深くプログラムしなければならない。 //
	if (nil != (obj = [aDic objectForKey:ASShadingAxialAngleKey]))
		axialAngle = [obj doubleValue];
	else
		axialAngle = 0.0;
	if (nil != (obj = [aDic objectForKey:ASShadingRadialCenterKey]))
		radialCenter = NSPointFromString(obj);
	else
		radialCenter = NSZeroPoint;
	if (nil != (obj = [aDic objectForKey:ASShadingColorPositionKey]))
		colorPosition = [[NSArray allocWithZone:[self zone]] initWithArray:obj];
	else
		colorPosition = [[NSArray allocWithZone:[self zone]] initWithObjects:[NSNumber numberWithFloat:0.0],[NSNumber numberWithFloat:0.5],[NSNumber numberWithFloat:1.0],nil];
	return self;
}
- (id)init {
	return [self initWithDictionary:[NSDictionary dictionary]];
}
- (NSDictionary *)properties
{
	NSMutableDictionary *rDic = [NSMutableDictionary dictionary];
	[rDic setObject:[NSNumber numberWithInt:shadingStyle] forKey:ASShadingStyleKey];
	// 同じ色の場合に同じアドレスになってしまうので、非常に難しい。 //
	[rDic setObject:[NSArchiver archivedDataWithRootObject:startColor] forKey:ASShadingStartColorKey];
	[rDic setObject:[NSArchiver archivedDataWithRootObject:midColor] forKey:ASShadingMidColorKey];
	[rDic setObject:[NSArchiver archivedDataWithRootObject:endColor] forKey:ASShadingEndColorKey];
	[rDic setObject:[NSNumber numberWithDouble:axialAngle] forKey:ASShadingAxialAngleKey];
	[rDic setObject:NSStringFromPoint(radialCenter) forKey:ASShadingRadialCenterKey];
	[rDic setObject:colorPosition forKey:ASShadingColorPositionKey];
	return rDic;
}
- (id)objectForKey:(NSString *)key {
	return [self valueForKey:key];
}
- (void)dealloc
{
	[midColor release];
	[startColor release];
	[endColor release];
	[colorPosition release];
	[super dealloc];
}

- (void)setShadingStyle:(ASShadingStyle)aValue
{
	shadingStyle = aValue;
	[self makeMidColor:aValue]; // 中間色の色調整が必要 //
}

- (void)setColor:(NSColor *)aColor order:(ASShadingColorOrder)anOrder
{
	NSColorSpace *newSpace;
	NSColorSpaceModel newSpaceModel;
	NSColor *targetColor,*tempStartColor,*tempEndColor,*tempMidColor;
	NSString *nsColorName;

	switch (anOrder) {
	case ASStartColor:
		targetColor = startColor;
		break;
	case ASMidColor:
		targetColor = midColor;
		break;
	case ASEndColor:
		targetColor = endColor;
		break;
	default:
		targetColor = startColor;
		break;
	}
	nsColorName = [aColor colorSpaceName];
	if (YES == [nsColorName isEqualToString:NSPatternColorSpace])
		return;
	newSpace = [aColor colorSpace]; // 入力 //
	newSpaceModel = [newSpace colorSpaceModel];
	// 入力にあわせてコンバートする。カラーパネルから与えられるカラースペースはCalibratedなので、それにあわせる。 //
	CGFloat *startC = (CGFloat *)NULL;
	if ((targetColor != startColor) && ([[startColor colorSpace] colorSpaceModel] != newSpaceModel)) {
		switch (newSpaceModel) {
		case NSCMYKColorSpaceModel:
			tempStartColor = [startColor colorUsingColorSpaceName:NSDeviceCMYKColorSpace];
			break;
		case NSRGBColorSpaceModel:
			tempStartColor = [startColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
			break;
		case NSGrayColorSpaceModel:
			tempStartColor = [startColor colorUsingColorSpaceName:NSCalibratedWhiteColorSpace];
			break;
		case NSLABColorSpaceModel: case NSDeviceNColorSpaceModel:
			tempStartColor = [startColor colorUsingColorSpace:newSpace];
			break;
		default: // 無意味 //
			tempStartColor = [startColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
			break;
		}
		[startColor release];
		startColor = [tempStartColor retain];
		startC = (CGFloat *)NSZoneMalloc([self zone],[startColor numberOfComponents] * sizeof(CGFloat));
		[startColor getComponents:startC];
	}
	else {
		if (targetColor == startColor) {
			[startColor release];
			startColor = [aColor retain];
			startC = (CGFloat *)NSZoneMalloc([self zone],[startColor numberOfComponents] * sizeof(CGFloat));
			[startColor getComponents:startC];
			targetColor = startColor;
		}
	}
	CGFloat *endC = (CGFloat *)NULL;
	if ((targetColor != endColor) && ([[endColor colorSpace] colorSpaceModel] != newSpaceModel)) {
		switch (newSpaceModel) {
		case NSCMYKColorSpaceModel:
			tempEndColor = [endColor colorUsingColorSpaceName:NSDeviceCMYKColorSpace];
			break;
		case NSRGBColorSpaceModel:
			tempEndColor = [endColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
			break;
		case NSGrayColorSpaceModel:
			tempEndColor = [endColor colorUsingColorSpaceName:NSCalibratedWhiteColorSpace];
			break;
		case NSLABColorSpaceModel: case NSDeviceNColorSpaceModel:
			tempEndColor = [endColor colorUsingColorSpace:newSpace];
			break;
		default: // 無意味 //
			tempEndColor = [[endColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace] retain];
			break;
		}
		[endColor release];
		endColor = [tempEndColor retain];
		endC = (CGFloat *)NSZoneMalloc([self zone],[endColor numberOfComponents] * sizeof(CGFloat));
		[endColor getComponents:endC];
	}
	else {
		if (targetColor == endColor) {
			[endColor release];
			endColor = [aColor retain];
			endC = (CGFloat *)NSZoneMalloc([self zone],[endColor numberOfComponents] * sizeof(CGFloat));
			[endColor getComponents:endC];
			targetColor = endColor;
		}
	}
	CGFloat *midC = (CGFloat *)NULL;
	if ((targetColor != midColor) && ([[midColor colorSpace] colorSpaceModel] != newSpaceModel)) {
		switch (newSpaceModel) {
		case NSCMYKColorSpaceModel:
			tempMidColor = [midColor colorUsingColorSpaceName:NSDeviceCMYKColorSpace];
			break;
		case NSRGBColorSpaceModel:
			tempMidColor = [midColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
			break;
		case NSGrayColorSpaceModel:
			tempMidColor = [midColor colorUsingColorSpaceName:NSCalibratedWhiteColorSpace];
			break;
		case NSLABColorSpaceModel: case NSDeviceNColorSpaceModel:
			tempMidColor = [midColor colorUsingColorSpace:newSpace];
			break;
		default: // 無意味 //
			tempMidColor = [midColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
			break;
		}
		[midColor release];
		midColor = [tempMidColor retain];
		midC = (CGFloat *)NSZoneMalloc([self zone],[midColor numberOfComponents] * sizeof(CGFloat));
		[midColor getComponents:midC];
	}
	else {
		if (targetColor == midColor) {
			[midColor release];
			midColor = [aColor retain];
			midC = (CGFloat *)NSZoneMalloc([self zone],[midColor numberOfComponents] * sizeof(CGFloat));
			[midColor getComponents:midC];
		}
	}
	if ((nil == startColor) || (nil == midColor) || (nil == endColor)) { // colorUsingColorSpaceName:でエラーが起きたら規定値にしてしまう。 //
		[startColor release];
		[midColor release];
		[endColor release];
		startColor = [[NSColor colorWithCalibratedRed:1.0 green:0.0 blue:0.0 alpha:1.0] retain];
		midColor = [[NSColor colorWithCalibratedRed:0.0 green:1.0 blue:0.0 alpha:1.0] retain];
		endColor = [[NSColor colorWithCalibratedRed:0.0 green:0.0 blue:1.0 alpha:1.0] retain];
		if ((CGFloat *)NULL != startC)
			NSZoneFree([self zone],startC);
		startC = (CGFloat *)NSZoneMalloc([self zone],[startColor numberOfComponents] * sizeof(CGFloat));
		[startColor getComponents:startC];
		if ((CGFloat *)NULL != midC)
			NSZoneFree([self zone],midC);
		midC = (CGFloat *)NSZoneMalloc([self zone],[midColor numberOfComponents] * sizeof(CGFloat));
		[midColor getComponents:midC];
		if ((CGFloat *)NULL != endC)
			NSZoneFree([self zone],endC);
		endC = (CGFloat *)NSZoneMalloc([self zone],[endColor numberOfComponents] * sizeof(CGFloat));
		[endColor getComponents:endC];
	}
	[self makeMidColor:shadingStyle];
}

- (void)setColorPosition:(NSArray *)pArray {
	[colorPosition release];
	colorPosition = [[NSArray allocWithZone:[self zone]] initWithArray:pArray];
}
- (void)setAxialAngle:(double)aValue {
	axialAngle = aValue;
}
- (void)setRadialCenter:(NSPoint)aPoint {
	radialCenter = aPoint;
}

- (ASShadingStyle)shadingStyle {
	return shadingStyle;
}
- (NSColor *)startColor {
	return startColor;
}
- (NSColor *)midColor {
	return midColor;
}
- (NSColor *)endColor {
	return endColor;
}
- (NSArray *)colors {
	return [NSArray arrayWithObjects:startColor,midColor,endColor,nil];
}
- (NSColor *)color:(ASShadingColorOrder)anOrder {
	NSColor *aColor;
	switch (anOrder) {
	case ASStartColor:
		aColor = startColor;
		break;
	case ASMidColor:
		aColor = midColor;
		break;
	case ASEndColor:
		aColor = endColor;
		break;
	default:
		aColor = startColor;
		break;
	}
	return aColor;
}
- (NSPoint)radialCenter {
	return radialCenter;
}
- (NSArray *)colorPosition {
	return colorPosition;
}
- (double)axialAngle {
	return axialAngle;
}

@end
