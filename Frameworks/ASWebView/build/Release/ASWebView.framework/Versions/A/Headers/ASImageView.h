//
//  ASImageView.h
//
//  Copyright (c) 2004 SatoAkira. All rights reserved.
//
// NSImageViewとの相違点
// 1.copyしたときにimageFrameまで取り込む。
// 2.SVGをネイティブにサポートする。
// 3.背景色を設定できる。
// 4.fractionを設定できる。
// 5.PDFとTIFFのマルチページに対応。
// 6.ペースト・ドラッグ・プログラムからファイルオープンしたときに、ファイルのURLを取得できる。
// 7.元のデータを保持する機能がオプションとしてある。
// 8.animatesをサポートしない。SVGのanimateをサポートするにはASWebImageRepの方でanimateをサポートしなければならないが殆ど不可能である。

#import <AppKit/AppKit.h>
#import "ASImageViewCell.h"

@interface ASImageView : NSControl
{
	@private
	NSURL *currentURL; // openFileFor:とマウスドラッグによって自動的に設定される。 //
	NSData *imageData;
	BOOL dataRetained; // 元のデータを保持するかどうか。デフォルトはNOで保持しない。 //
	BOOL allowsCutCopyPaste;
	BOOL animates;
	BOOL treatsFilePackageAsDirectories; // openFile:を使うときのオプション //
	NSArray *allowedFileTypes; // openFile:を使うときのオプションと、マウスドラッグのときのチェックに使われる。 //

	id filenameViewer;	// 表示対象のファイル名を表示するオブジェクトに接続することができる。 //
	IBOutlet NSPathControl *currentURLcontrol; // setURL:currentURLを送信する。 //
	id enableState;	// 印刷あるいはコピーする内容があるか否かを示すオブジェクト。「印刷...」ボタンなどに使用することができる。 //
	IBOutlet NSMatrix *compositingOperationMatrix; // PDFやSVG画像を使っているとき、compositingOperationとfractionの設定が無視されるので、cellのcanUseFractionの値を基にsetEnabled:を自動設定させる。compositingOperationとfractionの値は変更しない。 //
	id fractionDevice; // sliderやtextFieldなど。PDFやSVG画像を使っているとき、compositingOperationとfractionの設定が無視されるので、cellのcanUseFractionの値を基にsetEnabled:を自動設定させる。compositingOperationとfractionの値は変更しない。 //
	IBOutlet NSColorWell *colorWell;	// NSColorWellに接続することができる。 //
	IBOutlet NSMatrix *imageFlameStyleMatrix;
	IBOutlet NSMatrix *imageAlignmentMatrix;
	IBOutlet NSMatrix *imageScalingMatrix;
	IBOutlet NSTextField *currentPageField;
	IBOutlet NSSegmentedControl *currentPageControl;
	IBOutlet NSStepper *currentPageStepper;
	IBOutlet NSTextField *pageCountField;
	id infoState;
	NSTextView *infoTextView;
}

- (NSArray *)imageReps; // 要素はNSImageRep //
- (NSImageRep *)imageRep; // NSPDFImageRepの場合、全ページ分のNSPDFImageRepとなる。 //
- (void)setImageReps:(NSArray *)anArray; // currentURL,imageDataはnilになる。 //
- (void)setImageRep:(NSImageRep *)aRep; // currentURL,imageDataはnilになる。 //
- (void)setImage:(NSImage *)image; // currentURL,imageDataはnilになる。 //
- (NSImage *)image;
- (BOOL)openURLFor:(NSURL *)url; // urlにnilを指定すると画面クリアする。 //
- (BOOL)openFileFor:(NSString *)filename; // filenameに空文字又はnilを与えると、イメージは消去される。 //
- (BOOL)setImageWithData:(NSData *)aData url:(NSURL *)url; // aDataにnilを指定すると画面クリアする。 //
- (BOOL)setImageWithData:(NSData *)aData file:(NSString *)fullpath; // aDataにnilを指定すると画面クリアする。 //
- (BOOL)setImageWithData:(NSData *)aData ofType:(NSString *)type; // aDataにnilを指定すると画面クリアする。currentURLはnilとなる。 //
- (void)setImageFrameStyle:(NSImageFrameStyle)frameStyle;
- (NSImageFrameStyle)imageFrameStyle;
- (void)setImageScaling:(NSImageScaling)newScaling;
- (NSImageScaling)imageScaling;
- (void)setImageAlignment:(NSImageAlignment)newAlign;
- (NSImageAlignment)imageAlignment;
- (void)setEditable:(BOOL)yn; // Sets whether the user can drag a new image into the frame.マウスドラッグが可能か否かを設定する。allowsCutCopyPasteとは無関係。 //
- (BOOL)isEditable;
- (void)setBackgroundColor:(NSColor *)newColor; // newColorにnilを指定するとuseBackgroundColorをNOにする。nilでない場合にはuseBackgroundColorは変更しない。どちらの場合にも再描画はしない。imageFrameStyleがNSImageFrameGrayBezelで、useBackgroundColorがYESでbackgroundColorにRGBカラースペース以外のカラーが指定されたときMacOSX標準のNSImageViewと同じ背景色になる。 //
- (NSColor *)backgroundColor;
- (void)setUseBackgroundColor:(BOOL)yn;
- (BOOL)useBackgroundColor;
- (void)setCompositingOperation:(NSCompositingOperation)operator; // NSBitmapImageRepをNSCompositeCopyで描画すると透明部分が黒くなるので、NSCompositeSourceOverにした方が良い。ベクトル画像ならばデフォルトのNSCompositeCopyで良い。 //
- (NSCompositingOperation)compositingOperation;
- (NSSize)originalSize;
- (NSInteger)pageCount; // Return the number of pages in the receiver. //
- (void)setCurrentPage:(NSInteger)pageNum; // zero based. //
- (NSInteger)currentPage; // Get the currently displayed page. //
- (void)setFraction:(CGFloat)delta;
- (CGFloat)fraction;
- (BOOL)canUseFraction; // fractionとcompositingOperationの設定が可能かどうかを返す。 //
- (void)setAllowsCutCopyPaste:(BOOL)flag;
- (BOOL)allowsCutCopyPaste; // isEditableがNOのときはYESにしてもCutCopyPasteはできない。 //
- (void)setAnimates:(BOOL)flag; // Sets whether the receiver automatically plays an animated image that is assigned to it.未サポート。 //
- (BOOL)animates;
- (void)setOutlet;
- (IBAction)openFile:(id)sender;
- (IBAction)eraseInside:(id)sender; // Viewの矩形内をクリアする。ファイル名をnilにしてopenFileFor:を実行する。 //
- (IBAction)takeEditableFlagFrom:(id)sender;
- (IBAction)takeBackgroundColorFrom:(id)sender; // 再描画を行う。useBackgroundColorは変更しない。従ってuseBackgroundColorがNOのときは、画面上の変化は無い。 //
- (IBAction)takeBackgroundFlagFrom:(id)sender; // 再描画を行う。state,selectedTag,tagの優先順序で設定を変更する。backgroundColorがnilのとき及びsenderの値がNSOffStateのときNOにし、それ以外はYESに設定する。 //
- (IBAction)takeFractionValueFrom:(id)sender; // 再描画を行う。0.0~1.0のCGFloat //
- (IBAction)takeCompositingOperationFrom:(id)sender; // 再描画を行う。senderのtagの値をNSCompositingOperationの内のひとつと一致させておかなければならない。 //
- (IBAction)takeImageAlignmentFrom:(id)sender; // 再描画を行う。senderのtagの値をNSImageAlignmentの内のひとつと一致させておかなければならない。 //
- (IBAction)takeImageFrameStyleFrom:(id)sender; // 再描画を行う。senderのtagの値をNSImageFrameStyleの内のひとつと一致させておかなければならない。 //
- (IBAction)takeImageScalingFrom:(id)sender; // 再描画を行う。senderのtagの値をNSImageScalingの内のひとつと一致させておかなければならない。 //
- (IBAction)takeAllowsCutCopyPasteFrom:(id)sender;
- (IBAction)takeAnimatesFrom:(id)sender;
- (IBAction)takeCurrentPageFrom:(id)sender; // 再描画を行う。1 basedの値を与える。 //
- (IBAction)pageUp:(id)sender;
- (IBAction)pageDown:(id)sender;
- (IBAction)pageUpOrDown:(id)sender;

@end

extern NSString *ASImageViewDidConcludeDragOperaionNotification;
extern NSString *ASImageViewDidPasteNotification;
extern NSString *ASImageViewDidOpenNotification;
extern NSString *ASImageViewCurrentURLKey;
extern NSString *ASImageViewImageDataKey;
extern NSString *ASImageViewDataRetainedKey;
extern NSString *ASImageViewAllowsCutCopyPasteKey;
extern NSString *ASImageViewTreatsFilePackageAsDirectoriesKey;
extern NSString *ASImageViewAllowedFileTypesKey;
