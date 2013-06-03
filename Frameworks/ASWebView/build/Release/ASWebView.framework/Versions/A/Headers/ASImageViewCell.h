//
//  ASImageViewCell.h
//  ASImageView
//
//  Created by 佐藤 昭 on 平成 21/02/11.
//  Copyright 2009 SatoAkira. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#ifdef __APPLE__
#define NEXTSTEPImageFrameGrayBezel 255
#endif
#define USESVG 1
#ifdef USESVG
#import "ASWebImageRep.h"
#endif


@interface ASImageViewCell : NSActionCell {
	@private
	NSArray *_imageReps; // NSImageRepを要素とする配列 //
	NSInteger currentPage; // NSPDFImageRepの場合、_imageRepsのcountは常に0であるが、このcurrentPageはページ番号を指定すること。zero based。 //
	NSSize originalSize; // 内部的。setImageWithArray:で設定される初期値 //
	NSImageScaling imageScaling;
	NSImageFrameStyle imageFrameStyle;
	NSImageAlignment imageAlignment;
	NSColor *backgroundColor;
	BOOL useBackgroundColor;
	NSCompositingOperation compositingOperation;
	CGFloat delta; // fractionという変数名を使うとコンパイラの動作がおかしくなる。 //
	BOOL canUseFraction; // 内部的。compositingOperationとfractionの設定が可能か否か //
	BOOL isFlipped; // 内部的。 //
	NSSize bottomLeft; // 内部的。 //
	NSSize topRight; // 内部的。 //
	// NSArray *imageDataCopyRequiredTypes = [[NSArray alloc] initWithObjects:@"bmp",@"BMP",@"dib",@"DIB",nil]; OSの古いバージョンでは「NSData オブジェクトからデータを読み込む場合には、NSImage オブジェクトが自分自身の中にデータを保存しておかなければならないことがあります。」ということだった。自分自身の中にデータを保存しておかなければならないタイプを列挙する。bmp以外にもあるかもしれないが、判定する方法がない。使い途が無くなった。 //
	NSString *frameName; // ASWebImageRepの制御に使うだけ //
}

- (NSImageRep *)imageRep; // NSPDFImageRepの場合、_imageReps countを見てもページ数がわからないので必ずこれをフェッチすること。NSPDFImageRepでない場合はcurrentPageに対応するNSImageRepを返す。 //
- (void)setImageWithArray:(NSArray *)anArray; // setImage:の代わり //
- (void)setImageRep:(NSImageRep *)imageRep; // setImage:の代わり //
- (NSDictionary *)generalProperties; // NSBitmapImageRepの一般的な属性値の取得。NSPDFImageRepの場合にはPDFDocumentのdocumentAttributes:のフロントエンド。 //
- (NSDictionary *)metadataFromSource:(id)source;
- (NSDictionary *)CGImagePropertyInMetadata:(NSDictionary *)metadata key:(NSString *)property; // NSBitmapImageRepの場合のkeyに対応する属性を取得する。keyは(NSString *)kCGImageProperty...Dictionary //

@end

extern NSString *ASImageViewImageRepsKey;
extern NSString *ASImageViewCurrentPageKey;
extern CGFloat ASImageViewDefaultFraction;
extern NSString *ASImageViewFractionKey;
extern NSString *ASImageViewCanUseFractionKey;
extern NSCompositingOperation ASImageViewDefaultCompositeOperation;
extern NSString *ASImageViewCompositingOperationKey;
extern NSString *ASImageViewImageScalingKey;
extern NSString *ASImageViewImageFrameStyleKey;
extern NSString *ASImageViewImageAlignmentKey;
extern NSString *ASImageViewBackgroundColorKey;
extern NSString *ASImageViewUseBackgroundColorKey;
