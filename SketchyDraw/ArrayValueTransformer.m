//
//  ArrayValueTransformer.m
//  SketchyDraw
//
//  Created by 佐藤 昭 on 平成 20/08/24.
//  Copyright 2008 SatoAkira. All rights reserved.
//

#import "ArrayValueTransformer.h"
#import "PreferencesController.h"

@implementation ArrayValueTransformer

+ (Class)transformedValueClass
{
	return [NSString class];
}
+ (BOOL)allowsReverseTransformation
{
	return YES;
}

- (id)transformedValue:(id)value
{
	if (value == nil) return nil;
	if (NO == [value respondsToSelector: @selector(objectAtIndex:)])
		[NSException raise:NSInternalInconsistencyException format:@"Value does not respond to -objectAtIndex:.  No idea what to do. (Value is an instance of %@).",[value class]];
	NSUInteger i;
	NSMutableString *returnString = [NSMutableString string];
	double pointsPerUnit = (nil != [[NSUserDefaults standardUserDefaults] objectForKey:PointsPerUnitKey]) ? [[[NSUserDefaults standardUserDefaults] objectForKey:PointsPerUnitKey] doubleValue] : 1.0;

	for (i = 0; i < [value count]; i++) {
		if (0 < i)
			[returnString appendString:@", "];
		[returnString appendFormat:@"%g", [[value objectAtIndex:i] floatValue] / pointsPerUnit];
	}
	return returnString;
}
- (id)reverseTransformedValue:(id)value
{
	if (value == nil) return nil;
	if (NO == [value isKindOfClass:[NSString class]])
		[NSException raise:NSInternalInconsistencyException format:@"Value is not NSString class.  No idea what to do. (Value is an instance of %@).",[value class]];
	float element;
	BOOL allZeroFlag = YES;
	double pointsPerUnit = (nil != [[NSUserDefaults standardUserDefaults] objectForKey:PointsPerUnitKey]) ? [[[NSUserDefaults standardUserDefaults] objectForKey:PointsPerUnitKey] doubleValue] : 1.0;
	NSScanner *scanner = [NSScanner scannerWithString:value];
	NSString *separator = @",";	// コンマでなくても区切り文字になる //
	NSMutableArray *patternArray = [NSMutableArray array];
	while (NO == [scanner isAtEnd]) {
		if (YES == [scanner scanFloat:&element]) {
			if (0.0 > element) {
				patternArray = [NSMutableArray array];
				break;
			}
			else {
				if ((YES == allZeroFlag) && (0.0 < element))
					allZeroFlag = NO;
				[patternArray addObject:[NSNumber numberWithFloat:element * pointsPerUnit]]; // point単位 //
			}
		}
		[scanner scanString:separator intoString:NULL];
	}
	if (YES == allZeroFlag)
		patternArray = [NSMutableArray array];
	return patternArray;
}

@end
