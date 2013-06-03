//
//  ASDialKnob.h
//
//  Created by 佐藤昭 on Fri 1-Oct-1999.
//  Copyright (c) 2004 SatoAkira. All rights reserved.
//

// ***** 使い方 ***** //
// これは、角度を設定する為のデバイスです。円形状のノブで構成し、場合によってはノブの周囲に30度刻みの目盛りが構成されます。このデバイスを直接操作するには、マウスクリック或はタブキーによりファーストレスポンダにして操作します。 //
// 描画されている領域の中の「C」ボタン以外のどこかにマウスカーソルを置き、左マウスボタンを押します。次にそのままマウスドラッグをすると連続的に角度が変更されます。マウスボタンを離すと、そのときの角度が決定されます。 //
// キーボードからは、スペースキー又はShift-スペースキーの操作により、角度を変更させます。矢印キーの操作が可能な場合には、4つの矢印キーにより操作できます。 //
// 「C」ボタンのマウスクリック・「C」キー・Command-cショートカットキーにより、円形状のノブ内部の画像をペーストボードにコピーすることができます。 //
// 場合によっては円形状のノブに描かれる画像を、アイコンドラッグによって変更することが可能になります。 //
// ***** プログラム法 ***** //
// InterfaceBuilder.appからカスタムビューを配置し、その属性をASDialKnobに設定します。そのカスタムビューへアウトレット接続するだけでとりあえずの外観は整います。リサイズ可能にするときは幅・高さ共にリサイズ可能にします。ユーザによって設定された角度の取得は、radianValue:メソッドなどでも取得できますが、ターゲット/アクションによりマウスドラッグと同時に取得するようにもできます。 //
// ノブの周囲に30度刻みの目盛りを設定するときは、setTickMarks:メソッドを使用します。画像ファイルからのアイコンドラッグを不可能にするときは、setEditable:NO とします。バンドル内のEPSファイルや外部EPSファイルから円形ノブの画像を設定するときはsetEPSImage:、setPDFImage:、setBitmapImage:メソッドを使用します。矢印キーの使用を許さないときは、setAcceptsArrowKeys:NOとしてください。その他の設定についてはそれぞれのメソッド宣言の下の欄に書いてあります。 //
// flippされているNSViewに描かれる画像に対して利用する場合には、setClockwise:YESとした方が使いやすくなります。このとき時計回りの角度数値が返されるようになります。デフォルトはNOで反時計回りの数値が返されます。 //
// 「再描画あり」とされているもの以外は再描画無し //

#import <AppKit/AppKit.h>

@interface ASDialKnob : NSControl
{
	NSCursor *theCursor;
	BOOL acceptsArrowKeys;	// 矢印キーの使用を許すか否か //
	NSString *arrowKeysString;	// right,up,left,downの順 //
	double increment;	// スペースキーが押されたときの増減角度。10進単位 //
	IBOutlet id radianTextField;	// アウトレット //
	IBOutlet id dmsTextField;	// アウトレット //
	IBOutlet id degTextField;	// アウトレット //
	id observedObjectForAngle; // for binding //
	NSString *observedKeyPathForAngle; // for binding //
}

// Class initialization //
+ (void)initialize;
+ (Class)cellClass;
+ (void)setCellClass:(Class)classId;

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent;
- (void)keyDown:(NSEvent *)theEvent;
- (void)keyUp:(NSEvent *)theEvent; // 再描画あり //
- (id)init;
- (id)initWithFrame:(NSRect)frameRect; // 初期設定。selfを返します。 //
- (void)dealloc;

- (void)setImageRep:(NSImageRep *)newImageRep; // ASDialKnobCellのsetImageRep:を呼び出す。newImageRepはNSImageRepのサブ゜クラスのうちのいずれかです。座標の原点を中心として回転するのに都合の良いデータになっていないときには見苦しくなります。又、正方形に納めるように縦横それぞれの縮尺で拡大縮小します。ファイルアイコンのドラッグによって取り込む場合にもこのメソッドが呼ばれます。 //
- (NSImageRep *)imageRep; // setImageRep:あるいはマウスドラッグにより指定されたリソースのNSImageRepを返します。setImageRep:,マウスドラッグが一度も成功していない場合にはnilが返されます。 //
- (BOOL)setImageRepWithContentsOfURL:(NSURL *)url; // ASDialKnobCellのsetImageRep:を呼び出す。 //
- (BOOL)setImageRepWithContentsOfFile:(NSString *)filename; // ASDialKnobCellのsetImageRep:を呼び出す。 //
- (BOOL)setImageRepWithData:(NSData *)aData ofType:(NSString *)type; // ASDialKnobCellのsetImageRep:を呼び出す。typeにはNSPasteboard.h,ASSVGImageRep.hに定義されているデータタイプを指定します。 //
- (BOOL)setImageRepWithImage:(NSImage *)image; // ASDialKnobCellのsetImageRep:を呼び出す。 //

- (void)setBackgroundColor:(NSColor *)newColor; // スクリーンに描画されるときのみ、背景としてbackgroundColorで円形内を塗りつぶす。nil(デフォルト)を指定すれば背景は透明になる。 //
- (NSColor *)backgroundColor; // 背景色を返します。 //
- (void)setTickMarks:(NSColor *)aColor background:(NSColor *)bColor width:(NSInteger)wValue; // 30度刻みの目盛りの線色をaColorで設定しその背景色をbColorで設定し、目盛り領域の幅をwValue(ピクセル単位)で設定します。aColor,bColor共にnil(デフォルト設定)を指定すると画像はフルサイズになり、wValueの値は無視されます。どちらか有効な色を指定すると、画像のサイズは目盛り領域の幅だけ小さくなります。 //
- (void)setRadianValue:(double)aRadian; // aRadianで指定された回転角度をレシーバの見かけ上の回転角度としてラジアン単位で設定します。再描画あり //
- (void)setDMSValue:(double)aDouble; // aDoubleで指定された回転角度をレシーバの見かけ上の回転角度として60進単位(DDD.MMSS...形式)で設定します。再描画あり //
- (void)setDEGValue:(double)aDouble;
- (void)setDoubleValue:(double)aDouble; // aDoubleで指定された回転角度をレシーバの見かけ上の回転角度として10進単位で設定します。再描画あり //
- (void)takeRadianValueFrom:(id)sender; // マウスドラッグ以外の他のコントロールからの連動処理によって、回転させるときに利用します。ラジアン単位。再描画あり //
- (void)takeDMSValueFrom:(id)sender; // 60進単位(DDD.MMSS...形式) 再描画あり //
- (void)takeDEGValueFrom:(id)sender; // 10進単位 //
- (void)takeDoubleValueFrom:(id)sender; // 10進単位 再描画あり //
- (double)radianValue; // レシーバの見かけ上の回転角度をラジアン単位で返します。 //
- (double)dmsValue; // レシーバの見かけ上の回転角度を60進単位(DDD.MMSS...形式)で返します。 //
- (double)degValue; // レシーバの見かけ上の回転角度を10進単位で返します。 //
- (double)doubleValue; // レシーバの見かけ上の回転角度を10進単位で返します。 //
- (void)writeToOutlet; // 内部で自動的に呼ばれますので使用しないでください。 //
- (void)setEditable:(BOOL)flag; // EPSファイルアイコンのドラッグ処理を拒否するか否かを設定します。 //
- (BOOL)isEditable; // EPSファイルアイコンのドラッグ処理の可否を返します。 //
- (void)setBordered:(BOOL)flag;
- (BOOL)isBordered;
- (void)setTag:(NSInteger)anInt; // タグの設定。NSControlをオーバーライドしないとうまく動かない。 //
- (NSInteger)tag; // タグの取得 //
- (BOOL)acceptsArrowKeys; // 矢印キーの使用を許すか否かを返します。 //
- (void)setAcceptsArrowKeys:(BOOL)flag; // 矢印キーの使用を許すか否かを設定します。 //
- (NSString *)arrowKeysString; // 矢印キーの文字コード列 //
- (void)setArrowKeysString:(NSString *)aString; // 0,90,180,270度の順で設定する矢印キーの文字コードを設定します。 //
- (double)increment; // スペースキーが押されたときの増減角度を10進単位で返します。 //
- (void)setIncrement:(double)newValue; // スペースキーが押されたときの増減角度を10進単位で設定します。 //
- (void)setClockwise:(BOOL)flag; // 角度の回転方向を設定します。反時計回りのときNO、時計回りのときYESです。デフォルトはNOです。 //
- (BOOL)clockwise; // 角度の回転方向を返します。反時計回りのときNO、時計回りのときYESです。 //

- (NSUInteger)draggingEntered:(id <NSDraggingInfo>)sender;
- (NSUInteger)draggingUpdated:(id <NSDraggingInfo>)sender;
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender;
- (void)concludeDragOperation:(id <NSDraggingInfo>)sender;

- (void)copy:(id)sender; // 背景色、目盛り、周囲の枠は除かれます。 //
- (void)print:(id)sender; // 背景色、目盛り、周囲の枠は除かれます。 //

// バインディングの確立方法。[此のオブジェクトのインスタンス bind:ASDialKnobRotateAngleKey toObject:バインド先のプロパティーを格納しているオブジェクト withKeyPath:バインド先のプロパティーを指定するキーパス options:プレースホルダーなど任意のオプションを指定するNSDictionary]; というメッセージをプログラムから送信する。optionsが無いときはnilでも良い。 //
@property double rotateAngle;

@end

extern NSString *ASDialKnobImageRepDidChangeNotification;
extern NSString *ASDialKnobRotateAngleKey;
