//
//  ASDialKnobCell.h
//
//  Created by 佐藤昭 on Fri 1-Oct-1999.
//  Copyright (c) 2004 SatoAkira. All rights reserved.
//

#import <AppKit/AppKit.h>
#define USESVG 1
#ifdef USESVG
#import "ASWebImageRep.h"
#endif

@interface ASDialKnobCell : NSActionCell
{
	@private
	NSImageRep *imageRep;
	NSColor *backgroundColor;	// 背景色 //
	double rotateAngle;			// 回転角のRadian //
	double startAngle,baseAngle;
	NSRect selfFrame;			// winDidResize:の比較用 //
	CGFloat viewRadius;			// 描画する大きさの半分 //
	NSColor *tickColor;			// 目盛りの線色 //
	NSColor *tickBackgroundColor; // 目盛り領域の色 //
	NSInteger tickWidth;				// 目盛り領域の幅 //
	NSRect printButtonRect;	// プリントボタンの位置 //
	NSRect copyButtonRect;	// コピーボタンの位置 //
	BOOL printFlag;
	BOOL copyFlag;
	BOOL clockwise;
	BOOL isFlipped;
	NSString *frameName; // ASWebImageRepの制御に使うだけ //
}

// Class initialization //
+ (void)initialize;
+ (BOOL)prefersTrackingUntilMouseUp;

// Our state //
- (void)setSelfFrame:(NSRect)aRect; // これは重要。イニシャライズの後必ず呼び出すこと。 //
- (void)setImageRep:(NSImageRep *)newImageRep;
- (NSImageRep *)imageRep;

- (void)setBackgroundColor:(NSColor *)newColor;
- (NSColor *)backgroundColor;
- (void)setTickMarks:(NSColor *)aColor background:(NSColor *)bColor width:(NSInteger)wValue;
- (void)setRadianValue:(double)aRadian; // 再描画あり //
- (void)setDMSValue:(double)aDouble; // 再描画あり //
- (void)setDEGValue:(double)aDouble; // 再描画あり //
- (void)setDoubleValue:(double)aDouble; // 再描画あり。10進単位。 //
- (double)radianValue;
- (double)dmsValue;
- (double)degValue;
- (double)doubleValue; // 10進単位 //
- (void)setClockwise:(BOOL)flag; // 角度の回転方向を設定します。反時計回りのときNO、時計回りのときYESです。デフォルトはNOです。 //
- (BOOL)clockwise; // 角度の回転方向を返します。反時計回りのときNO、時計回りのときYESです。 //

// Displaying //
- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;
- (BOOL)trackMouse:(NSEvent *)theEvent inRect:(NSRect)cellFrame ofView:(NSView *)controlView untilMouseUp:(BOOL)flag;
- (BOOL)startTrackingAt:(NSPoint)startPoint inView:(NSView *)controlView;
- (BOOL)continueTracking:(NSPoint)lastPoint at:(NSPoint)currentPoint inView:(NSView *)controlView;
- (void)sizeToFit;

- (void)copy:(id)sender;

// Archiving //
- (id)initWithCoder:(NSCoder*)aDecoder;
- (void)encodeWithCoder:(NSCoder*)aCoder;

@property double rotateAngle;

@end
