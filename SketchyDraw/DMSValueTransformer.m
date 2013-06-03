//
//  DMSValueTransformer.m
//  SketchyDraw
//
//  Created by 佐藤 昭 on 平成 20/08/18.
//  Copyright 2008 SatoAkira. All rights reserved.
//

#import "DMSValueTransformer.h"
/* #define USEASSCIENCELIBRARY 1 */
#ifdef USEASSCIENCELIBRARY
#import <ASScienceLibrary/ASScienceLibrary.h>
#endif


@implementation DMSValueTransformer

+ (Class)transformedValueClass {
	return [NSNumber class];
}
+ (BOOL)allowsReverseTransformation {
	return YES;
}

#ifndef USEASSCIENCELIBRARY
double dtor(double x)
{
	double a,b,c;
	NSInteger sgn = 1;	
	double error = 1.0e-11; // modf()が1.0を返してしまうことを防ぐ為の数値。 //
	
	if (x < 0.0) {
		x = fabs(x);
		sgn = -1;
	}
	/* x = modf(modf(modf(x,&a) * 100.0 + error, &b) * 100.0 + error, &c) * 2.777777777777777777e-4; // 4.896618179206312657133e-15くらいの誤差を引きずってしまう。 //
	 x += c * 2.777777777777777777e-4;
	 x += a + b * 1.666666666666666666e-2;
	 x *= 1.745329251994329547437e-2; */
	x = modf(modf(modf(x,&a) * 100.0 + error, &b) * 100.0 + error, &c) * M_PI / 648000.0 - 4.896618179206312657133e-15;
	x += (a + b / 60.0 + c / 3600.0) * M_PI / 180.0;
	return ((sgn == -1) ? -x : x);
}
double rtod(double x)
{
	double rx,a,b;
	
	if (0.0 > x) {
		rx = modf( modf(fabs(x) * 180.0 * M_1_PI, &a) * 60.0, &b ) * 0.006;
		rx += a + b * 0.01;
		return -rx;
	}
	else {
		rx = modf( modf(x * 180.0 * M_1_PI, &a) * 60.0, &b ) * 0.006;
		rx += a + b * 0.01;
		return rx;
	}
}
#endif
- (id)transformedValue:(id)value
{
	if (value == nil) return nil;
	if (NO == [value respondsToSelector: @selector(doubleValue)]) {
		[NSException raise:NSInternalInconsistencyException format:@"Value does not respond to -doubleValue.  No idea what to do. (Value is an instance of %@).",[value class]];
		return nil;
	}
	else {
		double d = [value doubleValue];
		if (MAXFLOAT - 1e32 > d) return [NSNumber numberWithDouble:rtod(d)];
		else return nil;
	}
}
- (id)reverseTransformedValue:(id)value
// 空文字が与えられるとvalueはnilが与えられる。nilを返すと、そのオブジェクトもnilになってしまう。nilになることを避けるためにMAXFLOATを返す。 //
{
	if (value == nil)
		return [NSNumber numberWithDouble:MAXFLOAT];
	else {
		if (NO == [value respondsToSelector: @selector(doubleValue)]) {
			[NSException raise:NSInternalInconsistencyException format:@"Value does not respond to -doubleValue.  No idea what to do. (Value is an instance of %@).",[value class]];
			return [NSNumber numberWithDouble:MAXFLOAT];
		}
		else {
			double r = [value doubleValue];
			if (MAXFLOAT - 1e32 > r) return [NSNumber numberWithDouble:dtor(r)];
			else return [NSNumber numberWithDouble:MAXFLOAT]; // MAXFLOATでも何らかの角度を表す。 //
		}
	}
}

@end
