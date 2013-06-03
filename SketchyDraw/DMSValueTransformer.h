//
//  DMSValueTransformer.h
//  SketchyDraw
//
//  Created by 佐藤 昭 on 平成 20/08/18.
//  Copyright 2008 SatoAkira. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface DMSValueTransformer : NSValueTransformer {

}

+ (Class)transformedValueClass;
+ (BOOL)allowsReverseTransformation;

- (id)transformedValue:(id)value;
- (id)reverseTransformedValue:(id)value;

@end
