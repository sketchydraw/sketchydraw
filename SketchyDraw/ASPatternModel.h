//
//  ASPatternModel.h
//  SketchyDraw
//
//  Created by 佐藤 昭 on  平成19/10/20.
//  Copyright 2007 SatoAkira. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ASPatternModel : NSObject {
	NSRect bounds;
	NSWindingRule windingRule;
	NSColorSpace *colorSpace;
	NSImageRep *patternImageRep;
	NSImage *cachedImage;
	NSAffineTransform *transform;
	NSBezierPath *clipPath;
}

- (void)setPatternImageRep:(NSImageRep *)imageRep;
- (void)setBounds:(NSRect)aRect clip:(NSBezierPath *)aPath transform:(NSAffineTransform *)aTrans colorSpace:(NSColorSpace *)aSpace winding:(NSWindingRule)aRule;
- (void)fill;

@end
