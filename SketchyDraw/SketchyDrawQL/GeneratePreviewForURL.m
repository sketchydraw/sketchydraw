#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#import "SKTDocument.h"
#import "SKTRenderingView.h" // for svgDataWithGraphics:filename: //
#import "SKTGraphic.h" // for svgDataWithGraphics:filename: //

/* -----------------------------------------------------------------------------
   Generate a preview for file

   This function's job is to create preview for designated file
   ----------------------------------------------------------------------------- */

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	if (true == QLPreviewRequestIsCancelled(preview)) {
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
	NSData *svgData = [SKTRenderingView svgDataWithGraphics:[document valueForKey:@"_graphics"] filename:(NSURL *)url]; // SKTRenderingViewのdrawRect:を呼び出さないのでSKTsvgはnotification待ちにはならない。notification待ちになってもならなくてもWebKitに描かせてしまうのでこれがベストである。 //
	if (nil == svgData) {
		[document release];
		[pool release];
		return noErr;
	}
	// QLPreviewRequestCreatePDFContextはあっても、QLPreviewRequestCreateSVGContextは無い。 //
	// 第3引数のkey(QL_EXPORT const CFStringRef)には、kQLPreviewPropertyDisplayNameKey,kQLPreviewPropertyWidthKey,kQLPreviewPropertyHeightKey,kQLPreviewPropertyStringEncodingKey,kQLPreviewPropertyMIMETypeKey,kQLPreviewPropertyTextEncodingNameKey,kQLPreviewPropertyAttachmentDataKey,kQLPreviewPropertyAttachmentsKey,kQLPreviewContentIDScheme がある。 //
	NSSize svgSize = [SKTGraphic drawingBoundsOfGraphics:[document valueForKey:@"_graphics"]].size;
	QLPreviewRequestSetDataRepresentation(preview, (CFDataRef)svgData, kUTTypeXML, (CFDictionaryRef)[NSDictionary dictionaryWithObjectsAndKeys:@"image/svg+xml",(NSString *)kQLPreviewPropertyMIMETypeKey,@"UTF-8",(NSString *)kQLPreviewPropertyTextEncodingNameKey,[NSNumber numberWithFloat:svgSize.width],(NSString *)kQLPreviewPropertyWidthKey,[NSNumber numberWithFloat:svgSize.height],(NSString *)kQLPreviewPropertyHeightKey,nil]); // 第3引数に"public.svg-image"を指定すると駄目である。kUTTypeXMLであることには間違いないのでこうしておく。第4引数をNULLとして省略してもSVG形式と認識するようである。第4引数を指定するならば、kQLPreviewPropertyMIMETypeKeyに"image/svg+xml"としなければならない。kQLPreviewPropertyTextEncodingNameKeyはSKTRenderingView.mの中でUTF-8に決め打ちしているのでUTF-8へ決め打ちする。 //
	// [document release]; // // ここにreleaseを入れるとクラッシュする。何故だか判らない。 //
	[pool release];
	return noErr;
	// QL_EXPORT void QLPreviewRequestSetDataRepresentation(QLPreviewRequest preview,CFDataRef data,CFStringRef contentTypeUTI,CFDictionary properties);に関するDiscussionは以下のとおり。 //
	// This function returns preview data to the client. The data is either extracted from a document (where the document’s application has saved it,) or it is dynamically generated. How Quick Look handles the data depends upon the value of contentTypeUTI. The content data of the preview must be of a native Quick Look type. Currently supported UTIs for these types are: kUTTypeImage, kUTTypePDF, kUTTypeHTML, kUTTypeXML, kUTTypePlainText, kUTTypeRTF, kUTTypeMovie, and kUTTypeAudio. If the UTI type is kUTTypeHTML, you can have the WebKit handle the layout and display of your preview. You must provide the HTML in data plus any attachments (for example, Address Book cards, Mail messages, or Omni Outliner documents) in the properties dictionary. This dictionary takes kQLPreviewPropertyAttachmentsKey as its key and consists of one ore more subdictionaries (one per attachment). Each subdictionary uses an arbitrary string identifier as a key; the attachment should be referenced within the HTML data using the kQLPreviewContentIDScheme URL scheme (“cid”) and the identifier as the URL resource specifier—for example, “cid:the_identifier”. The keys of the subdictionary properties are kQLPreviewPropertyMIMETypeKey, kQLPreviewPropertyTextEncodingNameKey, and kQLPreviewPropertyAttachmentDataKey. //
}

void CancelPreviewGeneration(void* thisInterface, QLPreviewRequestRef preview)
{
    // implement only if supported
}
