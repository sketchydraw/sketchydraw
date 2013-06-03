//
//  ArrayValueTransformer.h
//  SketchyDraw
//
//  Created by 佐藤 昭 on 平成 20/08/24.
//  Copyright 2008 SatoAkira. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ArrayValueTransformer : NSValueTransformer {

}

+ (Class)transformedValueClass;
+ (BOOL)allowsReverseTransformation;

- (id)transformedValue:(id)value;
- (id)reverseTransformedValue:(id)value;

@end
