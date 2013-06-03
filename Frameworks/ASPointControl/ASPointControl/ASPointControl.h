//
//  ASPointControlPluginView.h
//  ASPointControlPlugin
//
//  Created by 佐藤昭 on 11/02/05.
//  Copyright 2011 SatoAkira. All rights reserved.
//

// ***** 使い方 ***** //
// これは、2次元の位置を指定する為のデバイスです。このデバイスを直接操作するには、マウスクリック或はタブキーによりファーストレスポンダにします。 //
// 描画されている領域の中で、左マウスボタンを押します。次にそのままマウスドラッグをすると位置が変更されます。マウスボタンを離すと、そのときの位置が決定されます。 //
// 矢印キーの操作が可能な場合には、4つの矢印キーにより操作できます。中央又は端へ位置を合わせるときに操作しやすくなります。 //

#import <Cocoa/Cocoa.h>

@interface ASPointControl : NSControl <NSCoding> {
@private
	NSPoint mousePoint; // 画面の座標系とは全く無関係 //
	NSCursor *theCursor;
	id observedObjectForPoint; // for binding //
	NSString *observedKeyPathForPoint; // for binding //
	BOOL acceptsAllowKeys;	// 矢印キーの使用を許すか否か。デフォルトはYES。 //
	NSString *arrowKeysString;	// right,up,left,downの順 //
}

// setContinuous:のYESとNOとでははかなり使い勝手が異なるがNSControl標準なのでここに挙げていない。 //
- (void)setBordered:(BOOL)flag;
- (BOOL)isBordered;
- (void)setEnabled:(BOOL)flag;
- (BOOL)isEnabled;
- (void)setEditable:(BOOL)flag;
- (BOOL)isEditable;
- (void)setDrawsTickMark:(BOOL)flag;
- (BOOL)drawsTickMark;
- (void)setImage:(NSImage *)anImage;
- (NSImage *)image; // デフォルトではnilが返る。ASPointControlCellのデフォルトイメージは返らない。 //
- (void)setHorizontalFlipped:(BOOL)flag; // 画面の右から左へ向かってxを増加させる場合にYESを指定する。 //
- (BOOL)horizontalFlipped;
- (void)setVerticalFlipped:(BOOL)flag; // 画面の上から下へ向かってyを増加させる場合にYESを指定する。 //
- (BOOL)verticalFlipped;
- (void)setSquare:(BOOL)flag; // YESにすると、自乗した値によりマウスをコントロールする。中央の値を0.0とし、中央付近での値の変化を小さくしたいときに効果的である。 //
- (BOOL)square;
- (void)setMinPoint:(NSPoint)aPoint; // 画面左下という意味ではなく、単純にx,yとも最小値を指定する。 //
- (void)setMaxPoint:(NSPoint)aPoint; // 画面右上という意味ではなく、単純にx,yとも最大値を指定する。 //
- (void)writeToOutlet; // 内部的。外から呼び出してはいけない。 //
@property NSPoint mousePoint;

@end

extern NSString *ASPointControlMousePointKey;
