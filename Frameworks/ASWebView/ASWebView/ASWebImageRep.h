//
//  ASWebImageRep.h
//  ASWebView
//
//  Created by 佐藤 昭 on 10/12/02.
//  Copyright 2010 SatoAkira. All rights reserved.
//
/*
 ASWebImageRepは、SVGコードのイメージのレンダリングを行うためのオブジェクトです。SVGコードの解析と描画にはWebViewを利用します。
 使い方
 [NSImageRep registerImageRepClass:[ASWebImageRep class]];
 をフェッチして、ASWebImageRepが使用できるようにする。
 次に
 NSImage *image = [[NSImage alloc] initWithData:]
 NSImage *image = [[NSImage alloc] initWithPasteboard:]
 NSImage *image = [[NSImage alloc] initWithContentsOfFile:]
 の3種類の内のいずれかの方法で、NSImageを取得する。+ (BOOL)canInitWithData:(NSData *)data,+ (id)imageRepWithData:(NSData *)dataが順に呼ばれてTIFFデータから成るNSBitmapImageRepが取得される。
 ASWebImageRep *imageRep = [[ASWebImageRep alloc] initWithData:URL:ofType:frameName:groupName:]とすればNSImageRepのサブクラスであるこのオブジェクトのインスタンスが作られる。PDFImageRepDidLoadNotificationを受け取るようにして、エラー通知または描画用のPDFImageRep(valueForKey:ASWebViewPDFImageRepKey)を取得する。呼び出し側において[NSThread isMainThread]がNOのときは、レンダリング用のWebViewが起動できないので、呼び出し側で[NSThread isMainThread]がYESになったときに[imageRep setupWebView]をフェッチする。そのあとPDFImageRepDidLoadNotificationを受け取るようにすることは同じ。
 このインスタンスに対して
 [imageRep draw]、[imageRep drawAtPoint:]、[imageRep drawInRect:]とすれば、従来のPostscriptと同じような出力が得られる。ただしNSPDFImageRepを代替に使うのでanimateなどはやらなくなる。
 registerImageRepClass:が必要になる場合があります。そのような状況では、registerImageRepClass:が有効な間は他のNSImageRepが使えなくなるので、適当なところで[NSImageRep unregisterImageRepClass:[ASWebImageRep class]];を必ずフェッチしてください。
 */

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface ASWebImageRep : NSImageRep {
	NSXMLDocument *xmlDocument; // SVGドキュメントの内容。 //
	WebView *view; // pdfImageRepとepsImageRepとを作成するためだけに使われる。作成後はただちにnilになる。 //
	NSString *type,*mimeType;
	NSString *encoding;
	NSStringEncoding encodingNumber;
	NSRect bounds; // (0,0)をoriginとする。 //
	NSSize size;
	NSRect viewBox; // 最初のsvgエレメントで指定あるいは計算された矩形。 //
	NSURL *fileURL,*baseURL; // SVGドキュメントの位置とSVGドキュメントのひとつ上層の位置。 //
	NSString *desc,*title; // svgエレメント直下のdescエレメントとtitleエレメントのうちのいずれかの値 //
	NSPDFImageRep *pdfImageRep; // 描画用とxmlDocument以外のNSData作成に使われる。 //
	NSEPSImageRep *epsImageRep; // 描画用とxmlDocument以外のNSData作成に使われる。 //
	NSBitmapImageRep *bitmapImageRep; // 描画用とxmlDocument以外のNSData作成に使われる。 //
	NSString *frameName,*groupName;
	BOOL fixedRatioX,fixedRatioY; // 最も外側のsvg要素でwidth,height属性が指定され、その値が%以外ならばYES。そうでない場合はsizeを640*480にしてNOとします。 //
}

// Instance Methods
// + (id)imageRepWithContentsOfURL:(NSURL *)aURL, + (NSArray *)imageRepsWithContentsOfURL:(NSURL *)aURL, + (id)imageRepWithContentsOfFile:(NSString *)filename, + (NSArray *)imageRepsWithContentsOfFile:(NSString *)filename, + (id)imageRepsWithPasteboard:(NSPasteboard *)pasteboard はaURLまたはfilenameがnilでないときsvgzの展開機能付き。圧縮データの形式はgzip形式でなければならない。zlib形式はサポートしない。 //
- (id)initWithData:(NSData *)data URL:(NSURL *)url ofType:(NSString *)typeName frameName:(NSString *)fName groupName:(NSString *)gName; // fNameとgNameとはそれぞれWebViewのframeNameとgroupNameの値として設定されます。urlがnilでないときsvgzの展開機能付き。 //
- (id)initWithXMLDocument:(NSXMLDocument *)xmlDoc URL:(NSURL *)url; // SVGのみ。urlがnilでないときsvgzの展開機能付き。 //
- (id)initWithXMLDocument:(NSXMLDocument *)xmlDoc; // SVGのみ //
- (id)initWithData:(NSData *)data URL:(NSURL *)url ofType:(NSString *)typeName; // urlがnilでないときsvgzの展開機能付き。 //
- (id)initWithData:(NSData *)data URL:(NSURL *)url; // SVGのみ。urlがnilでないときsvgzの展開機能付き。 //
- (id)initWithData:(NSData *)data;
- (void)setupWebView; // 呼び出し側で[NSThread isMainThread]がNOになったら、InitWith...のあとこのメソッドを呼び出します。このメソッドを呼ばないと描画用のデータは作成されません。 //

- (void)rotateByRadians:(double)angle; // SVGのみ。angleラジアン回転した画像をWebViewに描画します。元のSVGRepresentationは変更されません。angleは時計回りです。SVGの回転は時計回りとされているので御注意ください。
- (NSXMLDocument *)transformedDocument:(double)angle scaleXBy:(double)scaleX yBy:(double)scaleY; // SVGのみ。angleラジアン回転したSVGのNSXMLDocumentを返します。元のSVGRepresentationは変更されません。angleは時計回りです。SVGの回転は時計回りとされているので御注意ください。最も外側のsvg要素のwidth,height,viewBox属性の値を変更し、svg要素直下が<g transform="rotate(angleの10進数)">要素であるように変更します。このg要素以下はもとの内容と同じです。 //
- (NSXMLDocument *)xmlDocumentWithSVGInsideRect:(NSRect)clipRect rotate:(double)angle; // SVGのみ。angleラジアン回転し、clipRectでクリップされた画像を表示させるSVGのNSXMLDocumentを返します。最も外側のsvg要素のwidth,height,viewBox属性の値を変更し、svg要素直下が<g transform="rotate(angleの10進数)">要素であるように変更します。このg要素以下はもとの内容と同じです。 //
- (NSData *)SVGRepresentation; // [xmlDocument XMLData]を返します。animeなどの情報も含まれます。 //
- (NSData *)SVGPrettyRepresentation; // [xmlDocument XMLDataWithOptions:NSXMLNodePrettyPrint]を返します。animeなどの情報も含まれます。 //
- (NSData *)PDFRepresentation; // 元のSVGRepresentationを使ったデータです。animeなどの情報は消滅します。 //
- (NSData *)EPSRepresentation; // 元のSVGRepresentationを使ったデータです。animeなどの情報は消滅します。 //
- (NSData *)TIFFRepresentation; // デフォルトの圧縮方法で圧縮されたTIFFになっているデータオブジェクトを返します。元のSVGRepresentationを使ったデータです。animeなどの情報は消滅します。 //
- (NSRect)bounds; // イメージの境界線を指定している矩形を返します。SVGソースに記された数値あるいはSVGソースを基にした計算値が返されます。 //
- (NSColorSpace *)colorSpace; // sRGBColorSpaceを返します。 //
- (BOOL)isFlipped;
+ (NSData *)gunzip:(NSData *)gzipData error:(NSError **)outError;
+ (NSData *)gzip:(NSData *)xmlData;
- (NSImageRep *)bestRepresantion;

@end

extern NSString *ASSVGDocumentTypeName; // const CFStringRef としても良い。 //
extern NSString *ASSVGPboardType;
extern NSString *PDFImageRepDidLoadNotification; // このnotificationを受け取れば描画データの作成に成功したかどうかが判ります。 //
extern NSString *PDFImageRepDidLoadResultKey; // PDFImageRepDidLoadNotificationのuserInfo。描画データの作成に成功したときはNSNumberのYES。失敗したときはNO。ファイル位置に依存するようなSVGの場合にファイル位置が適正でないとNOになる。 //
extern NSString *PDFImageRepDidLoadErrorKey; // PDFImageRepDidLoadNotificationのuserInfo。NSError //
extern NSString *ASWebViewXMLDocumentKey;
extern NSString *ASWebViewSVGZExtension;
extern NSString *ASWebViewTypeKey;
extern NSString *ASWebViewMIMETypeKey;
extern NSString *ASWebViewEncodingKey;
extern NSString *ASWebViewEncodingNumberKey;
extern NSString *ASWebViewViewBoxKey;
extern NSString *ASWebViewFileURLKey;
extern NSString *ASWebViewBaseURLKey;
extern NSString *ASWebViewDescKey;
extern NSString *ASWebViewTitleKey;
extern NSString *ASWebViewPDFImageRepKey;
extern NSString *ASWebViewEPSImageRepKey;
extern NSString *ASWebViewBitmapImageRepKey;
extern NSString *ASWebViewFrameNameKey;
extern NSString *ASWebViewGroupNameKey;
extern NSString *ASWebViewFixedRatioXKey;
extern NSString *ASWebViewFixedRatioYKey;
