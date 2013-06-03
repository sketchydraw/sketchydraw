//
//  ASShadingModel.h
//
//  Created by 佐藤 昭 on  07/09/02.
//  Copyright 2007 SatoAkira. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ASShadingModel : NSObject
{
	NSColor *startColor;
	NSColor *midColor;
	NSColor *endColor;
	NSArray *colorPosition; // 現在のところshadingFunction:で3要素と決めうちしている。 //
	NSInteger shadingStyle;
	double axialAngle;
	NSPoint radialCenter; // 0.0から1.0までの値 //
}

typedef enum _ASShadingStyle {
	ASNoneShading,
	ASAxialShading,
	ASRadialShading,
	ASDoubleAxialShading,
	ASDoubleRadialShading,
	ASShadingError
} ASShadingStyle;
typedef enum _ASShadingColorOrder {
	ASStartColor,
	ASMidColor,
	ASEndColor
} ASShadingColorOrder;

- (id)initWithDictionary:(NSDictionary *)aDic;
- (NSDictionary *)properties;
- (id)objectForKey:(NSString *)key;
- (void)setShadingStyle:(ASShadingStyle)aValue;
- (void)setColor:(NSColor *)aColor order:(ASShadingColorOrder)anOrder;
- (void)setColorPosition:(NSArray *)pArray;
- (void)setAxialAngle:(double)aValue;
- (void)setRadialCenter:(NSPoint)aPoint;
- (ASShadingStyle)shadingStyle;
- (NSColor *)startColor;
- (NSColor *)midColor;
- (NSColor *)endColor;
- (NSArray *)colors;
- (NSColor *)color:(ASShadingColorOrder)anOrder;
- (NSPoint)radialCenter;
- (NSArray *)colorPosition;
- (double)axialAngle;

@end
