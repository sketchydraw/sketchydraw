//
//  ASPointControlCell.h
//  ASPointControlPlugin
//
//  Created by 佐藤 昭 on 11/02/05.
//  Copyright 2011 SatoAkira. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ASPointControlCell : NSActionCell {
	@private
	NSPoint minPoint,maxPoint;
	BOOL horizontalFlipped;
	BOOL verticalFlipped;
	BOOL drawsTickMark;
	BOOL square;
}

#define THICKNESS 2.0
// Class initialization //
+ (void)initialize;
+ (BOOL)prefersTrackingUntilMouseUp;
- (void)setHorizontalFlipped:(BOOL)flag;
- (BOOL)horizontalFlipped;
@property (nonatomic) BOOL horizontalFlipped;
@property (nonatomic) BOOL verticalFlipped;
@property (nonatomic) BOOL drawsTickMark;
@property (nonatomic) BOOL square;
@property (nonatomic) NSPoint minPoint;
@property (nonatomic) NSPoint maxPoint;

@end
