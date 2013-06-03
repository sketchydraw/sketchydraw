#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#import <Cocoa/Cocoa.h>
#import "SKTDocument.h"
#import "SKTGraphic.h" // for svgDataWithGraphics:filename: //

/* -----------------------------------------------------------------------------
    Generate a thumbnail for file

   This function's job is to create thumbnail for designated file as fast as possible
   ----------------------------------------------------------------------------- */

OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	if (true == QLThumbnailRequestIsCancelled(thumbnail)) {
		[pool release];
		return noErr;
	}
	NSError *err = nil;
	NSData *data = [NSData dataWithContentsOfURL:(NSURL *)url options:NSMappedRead error:&err];
	SKTDocument *document = [[SKTDocument alloc] init];
	if (NO == [document readFromData:data ofType:(NSString *)contentTypeUTI error:&err]) {
		[document release];
		[pool release];
		return noErr;
	}
	if (YES == [document respondsToSelector:@selector(thumbnail)]) {
		NSData *tiffData = [document thumbnail];
		if (nil != tiffData) {
			NSDictionary *props = [NSDictionary dictionaryWithObject:(NSString *)kUTTypeTIFF forKey:(NSString *)kCGImageSourceTypeIdentifierHint];
			QLThumbnailRequestSetImageWithData(thumbnail, (CFDataRef)tiffData, (CFDictionaryRef)props);
			[document release];
			[pool release];
			return noErr;
		}
	} // SKTDocumentにthumbnailメソッドを実装したならば、コメントアウトして動くようにしても良い。thumnailの実装の他にdataOfType:error:も追加修正する必要がある。詳しくは「Quick Lookプログラミングガイド」を参照する。 //
	// thumbnailアクセサメソッドが実装されていないか、または[document thumbnail]がnilを返したときは、この後、ビッマップデータを取得してQuickLookに渡す。 //
	/* NSSize canvasSize = [SKTGraphic drawingBoundsOfGraphics:[document valueForKey:@"_graphics"]].size; */
	NSSize svgSize = [SKTGraphic drawingBoundsOfGraphics:[document valueForKey:@"_graphics"]].size;
	CGContextRef cgContext = QLThumbnailRequestCreateContext(thumbnail, *(CGSize *)&svgSize, false, NULL);
	if (cgContext) {
		NSGraphicsContext *context = [NSGraphicsContext graphicsContextWithGraphicsPort:(void *)cgContext flipped:YES];
		if (context) {
			if (false == QLThumbnailRequestIsCancelled(thumbnail))
				[document drawDocumentInContext:context];
		}
		QLThumbnailRequestFlushContext(thumbnail, cgContext);
		CFRelease(cgContext);
	}
	// 上のdrawDocumentInContextWithoutSVG:を使うとSKTsvgの描画を省略する。QLThumbnailRequest...()がSVGをサポートするようになれば下の方が良い。 //
	/*　NSData *svgData = [SKTRenderingView svgDataWithGraphics:[document valueForKey:@"_graphics"] filename:(NSURL *)url];
	if (nil == svgData) {
		[document release];
		[pool release];
		return noErr;
	}
	// 第3引数のkey(QL_EXPORT const CFStringRef)には、kCGImageSourceTypeIdentifierHint,kCGImageSourceShouldAllowFloat,kCGImageSourceShouldCache,kCGImageSourceCreateThumbnailFromImageIfAbsent,kCGImageSourceCreateThumbnailFromImageAlways,kCGImageSourceThumbnailMaxPixelSize,kCGImageSourceCreateThumbnailWithTransform がある //
	
	QLThumbnailRequestSetImageWithData(thumbnail, (CFDataRef)svgData, (CFDictionaryRef)[NSDictionary dictionaryWithObjectsAndKeys:(NSString *)kUTTypeTIFF,(NSString *)kCGImageSourceTypeIdentifierHint,nil]); // SVGをそのままベクトル処理することはできない。TIFF,JPG,PNGなどImageI/Oフレームワークで処理できる形式にしなければならない。SVGをWebKitで描画させるときにマルチスレッドになってしまうのでビットマップを取得することは面倒くさくてやってられないのでやめる。 //　*/
	// [document autorelease]; // // ここにreleaseを入れるとクラッシュする。何故だか判らない。 //
	[pool release];
	return noErr;
}

void CancelThumbnailGeneration(void* thisInterface, QLThumbnailRequestRef thumbnail)
{
    // implement only if supported
}
