//
//  ASWebImageRep.m
//  ASWebView
//
//  Created by 佐藤 昭 on 10/12/02.
//  Copyright 2010 SatoAkira. All rights reserved.
//

#import "ASWebImageRep.h"
#import "ASWebViewFunctions.h"
#import "NSData+CocoaDevUsersAdditions.h"

@implementation ASWebImageRep

#define SETFLIPPED 1

NSString *ASSVGDocumentTypeName = @"public.svg-image";
NSString *ASWebViewSVGZExtension = @"svgz";
NSString *ASSVGPboardType = @"Scalable Vector Graphics";
NSString *PDFImageRepDidLoadNotification = @"PDFImageRepDidLoad";
NSString *PDFImageRepDidLoadResultKey = @"PDFImageRepDidLoadResultKey";
NSString *PDFImageRepDidLoadErrorKey = @"PDFImageRepDidLoadErrorKey";
NSString *ASWebViewXMLDocumentKey = @"xmlDocument";
NSString *ASWebViewTypeKey = @"type";
NSString *ASWebViewMIMETypeKey = @"mimeType";
NSString *ASWebViewEncodingKey = @"encoding";
NSString *ASWebViewEncodingNumberKey = @"encodingNumber";
NSString *ASWebViewViewBoxKey = @"viewBox";
NSString *ASWebViewFileURLKey = @"fileURL";
NSString *ASWebViewBaseURLKey = @"baseURL";
NSString *ASWebViewDescKey = @"desc";
NSString *ASWebViewTitleKey = @"title";
NSString *ASWebViewPDFImageRepKey = @"pdfImageRep";
NSString *ASWebViewEPSImageRepKey = @"epsImageRep";
NSString *ASWebViewBitmapImageRepKey = @"bitmapImageRep";
NSString *ASWebViewFrameNameKey = @"frameName";
NSString *ASWebViewGroupNameKey = @"groupName";
NSString *ASWebViewFixedRatioXKey = @"fixedRatioX";
NSString *ASWebViewFixedRatioYKey = @"fixedRatioY";

// Convenience function to clear an NSBitmapImageRep's bits to zero. zeroではない値をセットすれば、SVGで描画されない部分の色を設定できる。 //
static void ClearBitmapImageRep(NSBitmapImageRep *bitmap) {
	unsigned char *bitmapData = [bitmap bitmapData];
	if (bitmapData != NULL) { // A fast alternative to filling with [NSColor clearColor]. [NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.0 alpha:0.0]で塗り潰すならばbzero()でなければならない。 //
		bzero(bitmapData, [bitmap bytesPerRow] * [bitmap pixelsHigh]);
	}
	/* NSInteger i,j;
	NSInteger bpr = [bitmap pixelsWide];
	NSInteger ph = [bitmap pixelsHigh];
	NSColor *white = [NSColor colorWithCalibratedRed:1.0 green:1.0 blue:1.0 alpha:1.0]; // 塗り潰す色を指定する場合はこっちを使う。[NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.0 alpha:0.0]とすると、黒の透明でも黒くなってしまう場合がある。 //
	for (i = 0; i < bpr; i++) {
		for (j = 0; j < ph; j++)
			[bitmap setColor:white atX:i y:j];
	} */
}

+ (NSArray *)imageUnfilteredFileTypes {
	static NSArray *types = nil;
	
	if (nil == types)
		types = [[NSArray allocWithZone:[self zone]] initWithObjects:@"svg",@"SVG",ASWebViewSVGZExtension,@"SVGZ",nil];
	return types;
}

+ (NSArray *)imageUnfilteredPasteboardTypes {
	static NSArray *types = nil;
	
	if (nil == types)
		types = [[NSArray allocWithZone:[self zone]] initWithObjects:ASSVGPboardType,nil];
	return types;
}
+ (NSArray *)imageUnfilteredTypes {
	static NSArray *types = nil;
	if (nil == types)
		types = [[NSArray allocWithZone:[self zone]] initWithObjects:ASSVGDocumentTypeName,nil];
	return types;
}
+ (NSArray *)imageTypes {
	static NSArray *types = nil;
	if (nil == types)
		types = [[NSArray allocWithZone:[self zone]] initWithObjects:ASSVGDocumentTypeName,nil];
	return types;
}
+ (id)imageRepWithContentsOfURL:(NSURL *)aURL
// override //
{
	NSData *data = [NSData dataWithContentsOfURL:aURL];
	if (nil != data) {
		NSError *err = nil;
		NSString *typeName = (nil != aURL) ? [[NSWorkspace sharedWorkspace] typeOfFile:[aURL path] error:&err] : nil;
		if ((nil != aURL) && (YES == [[[aURL pathExtension] lowercaseString] isEqualToString:ASWebViewSVGZExtension])) {
			err = nil;
			return [[[self alloc] initWithData:[data gzipInflate:&err] URL:aURL ofType:typeName frameName:nil groupName:nil] autorelease];
		}
		else
			return [[[self alloc] initWithData:data URL:aURL ofType:typeName frameName:nil groupName:nil] autorelease];
	}
	else
		return nil;
}
+ (NSArray *)imageRepsWithContentsOfURL:(NSURL *)aURL
// override //
{
	NSMutableArray *result = nil;
	NSData *data = [NSData dataWithContentsOfURL:aURL];
	if (nil != data) {
		ASWebImageRep *imageRep;
		NSError *err = nil;
		NSString *typeName = (nil != aURL) ? [[NSWorkspace sharedWorkspace] typeOfFile:[aURL path] error:&err] : nil;
		if ((nil != aURL) && (YES == [[[aURL pathExtension] lowercaseString] isEqualToString:ASWebViewSVGZExtension])) {
			err = nil;
			imageRep = [[[self alloc] initWithData:[data gzipInflate:&err] URL:aURL ofType:typeName frameName:nil groupName:nil] autorelease];
		}
		else
			imageRep = [[[self alloc] initWithData:data URL:aURL ofType:typeName frameName:nil groupName:nil] autorelease];
		if (nil != imageRep)
			result = [NSArray arrayWithObject:imageRep];
	}
	return result;
}
+ (id)imageRepWithContentsOfFile:(NSString *)filename
// override //
{
	NSData *data = [NSData dataWithContentsOfFile:filename];
	if (nil != data) {
		NSError *err = nil;
		NSString *typeName = (nil != filename) ? [[NSWorkspace sharedWorkspace] typeOfFile:filename error:&err] : nil;
		NSURL *url = (nil != filename) ? [NSURL fileURLWithPath:filename] : nil;
		if ((nil != url) && (YES == [[[url pathExtension] lowercaseString] isEqualToString:ASWebViewSVGZExtension])) {
			err = nil;
			return [[[self alloc] initWithData:[data gzipInflate:&err] URL:url ofType:typeName frameName:nil groupName:nil] autorelease];
		}
		else
			return [[[self alloc] initWithData:data URL:url ofType:typeName frameName:nil groupName:nil] autorelease];
	}
	else
		return nil;
}
+ (NSArray *)imageRepsWithContentsOfFile:(NSString *)filename
// override //
{
	NSMutableArray *result = nil;
	NSData *data = [NSData dataWithContentsOfFile:filename];
	if (nil != data) {
		ASWebImageRep *imageRep;
		NSError *err = nil;
		NSString *typeName = (nil != filename) ? [[NSWorkspace sharedWorkspace] typeOfFile:filename error:&err] : nil;
		NSURL *url = (nil != filename) ? [NSURL fileURLWithPath:filename] : nil;
		if ((nil != url) && (YES == [[[url pathExtension] lowercaseString] isEqualToString:ASWebViewSVGZExtension])) {
			err = nil;
			imageRep = [[[self alloc] initWithData:[data gzipInflate:&err] URL:url ofType:typeName frameName:nil groupName:nil] autorelease];
		}
		else
			imageRep = [[[self alloc] initWithData:data URL:url ofType:typeName frameName:nil groupName:nil] autorelease];
		if (nil != imageRep)
			result = [NSArray arrayWithObject:imageRep];
	}
	return result;
}
+ (id)imageRepWithData:(NSData *)data
// [[NSImage alloc] iniWithPasteboard:pasteboard]からの場合でもここが呼び出される。 //
// [NSImageRep imageRepWithContentsOfURL:],[NSImageRep imageRepWithPasteboard:],[NSImageRep imageRepWithContentsOfFile:]の場合にここが呼ばれるがoverrideする。 //
{
	if (nil != data) {
		ASWebImageRep *newInstance = [[self allocWithZone:[self zone]] initWithData:data URL:nil ofType:ASSVGDocumentTypeName frameName:nil groupName:nil]; // SVGに決め打ち //
		return [newInstance autorelease];
	}
	else
		return nil;
}
+ (id)imageRepsWithData:(NSData *)data
// [NSImageRep imageRepsWithPasteboard:pboard],[NSImageRep imageRepsWithContentsOfURL:],[NSImageRep imageRepsWithContentsOfFile:]からの場合、ここが呼ばれる。 //
{
	if (nil != data) {
		ASWebImageRep *newInstance = [[self allocWithZone:[self zone]] initWithData:data URL:nil ofType:ASSVGDocumentTypeName frameName:nil groupName:nil]; // URL:の引数をnilにすると*** -[NSURL initWithString:relativeToURL:]: nil string parameterという例外が発生してしまう。SVGに決め打ち //
		return [NSArray arrayWithObject:[newInstance autorelease]];
	}
	else
		return nil;
}
+ (BOOL)canInitWithData:(NSData *)data {
	// NSImageは最初にこれを呼び出し次に+ (id)imageRepWithData:または+ (id)imageRepsWithData:を呼び出す。[[NSImage alloc] iniWithPasteboard:pasteboard]からの場合でもここを呼び出す。 //
	return YES;
}
+ (id)imageRepsWithPasteboard:(NSPasteboard *)pasteboard
{
	NSArray *classes = [NSArray arrayWithObjects:[NSURL class],[NSPasteboardItem class],nil];
	NSDictionary *options = [NSDictionary dictionaryWithObject:[ASWebImageRep imageTypes] forKey:NSPasteboardURLReadingContentsConformToTypesKey];
	NSArray *copiedItems = [pasteboard readObjectsForClasses:classes options:options];
	if ((nil != copiedItems) && (0 < [copiedItems count])) {
		NSData *data;
		NSString *type;
		id item = [copiedItems lastObject];
		if ([NSURL class] == [item class]) {
			NSURL *url = [copiedItems lastObject];
			if ((nil != url) && (YES == [[[url pathExtension] lowercaseString] isEqualToString:ASWebViewSVGZExtension])) {
				NSError *err = nil;
				type = ASSVGDocumentTypeName;
				data = [[NSData dataWithContentsOfURL:url] gzipInflate:&err];
			}
			else {
				NSError *err = nil;
				type = [[NSWorkspace sharedWorkspace] typeOfFile:[url path] error:&err];
				data = [NSData dataWithContentsOfURL:url];
			}
			if (nil != data) {
				ASWebImageRep *newInstance = [[self allocWithZone:[self zone]] initWithData:data URL:url ofType:type frameName:nil groupName:nil];
				return (nil != newInstance) ? [NSArray arrayWithObject:[newInstance autorelease]] : nil;
			}
			else
				return nil;
		}
		else {
			type = [(NSPasteboardItem *)item availableTypeFromArray:[ASWebImageRep imageTypes]];
			if (nil != (data = [item dataForType:type])) {
				ASWebImageRep *newInstance = [[self allocWithZone:[self zone]] initWithData:data URL:nil ofType:type frameName:nil groupName:nil];
				return (nil != newInstance) ? [NSArray arrayWithObject:[newInstance autorelease]] : nil;
			}
			else
				return nil;
		}
	}
	else
		return nil;
}
+ (BOOL)canInitWithPasteboard:(NSPasteboard *)pasteboard
{
	NSArray *classes = [NSArray arrayWithObjects:[NSURL class],[NSPasteboardItem class],nil];
	NSDictionary *options = [NSDictionary dictionaryWithObject:[ASWebImageRep imageTypes] forKey:NSPasteboardURLReadingContentsConformToTypesKey];
	NSArray *copiedItems = [pasteboard readObjectsForClasses:classes options:options];
	return ((nil != copiedItems) && (0 < [copiedItems count])) ? YES : NO;
}

- (id)initWithData:(NSData *)data URL:(NSURL *)url ofType:(NSString *)typeName frameName:(NSString *)fName groupName:(NSString *)gName
{
	type = nil;
	xmlDocument = nil;
	encoding = nil;
	encodingNumber = NSNotFound;
	mimeType = nil;
	baseURL = nil;
	fileURL = nil;
	desc = nil;
	title = nil;
	pdfImageRep = nil;
	epsImageRep = nil;
	bitmapImageRep = nil;
	view = nil;
	frameName = nil;
	groupName = nil;
	if ((nil != url) && (YES == [url isFileURL]) && (nil == typeName)) {
		NSError *err = nil;
		NSString *tempType = [[NSWorkspace sharedWorkspace] typeOfFile:[url path] error:&err];
		type = (nil != tempType) ? [[NSString alloc] initWithString:tempType] : nil;
	}
	else
		type = (nil != typeName) ? [[NSString alloc] initWithString:typeName] : nil;
	// typeがnilならば何もしない。urlがnilの場合はSVGの動作に制限が付けられるだけ。 //
	if ((nil != data) && (nil != type) && (nil != (self = [super init]))) {
		NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
		BOOL useTypeConformance = [workspace respondsToSelector:@selector(type:conformsToType:)];
		if ((YES == useTypeConformance) && (YES == [workspace type:type conformsToType:ASSVGDocumentTypeName])) {
			NSString *xmlStr;
			NSStringEncoding enc;
			NSData *svgData;
			NSError *error = nil;
			fileURL = (nil != url) ? [[NSURL alloc] initWithString:[url absoluteString]] : nil;
			mimeType = [[NSString alloc] initWithString:@"image/svg+xml"];
			if ((nil != url) && (YES == [[[url pathExtension] lowercaseString] isEqualToString:ASWebViewSVGZExtension])) {
				NSRange range = [data rangeOfNullTerminatedBytesFrom:0];
				if (0 < range.length) {
					svgData = [data gzipInflate:&error];
					if (nil != error)
						NSLog(@"%@",[error localizedDescription]);
				}
				else
					svgData = data;
			}
			else
				svgData = data;
			xmlDocument = [[NSXMLDocument alloc] initWithData:svgData options:NSXMLNodeOptionsNone error:&error];
			if ((nil != xmlDocument) && (nil == [xmlDocument characterEncoding]))
				[xmlDocument setCharacterEncoding:@"utf-8"]; // encoding=の指定がないときnilになってしまう。OKならばユニコードである。 //
			if ((nil == xmlDocument) || ((nil != error) && (9 == [error code]))) { // encoding=の指定があって、それが間違っているとき[error code]は32となるが、initWithXMLString:でエラーになってしまうので対応できない。 //
				if (nil != (xmlStr = guessEncoding(svgData,&enc))) {
					error = nil;
					xmlDocument = [[NSXMLDocument alloc] initWithXMLString:xmlStr options:NSXMLNodeOptionsNone error:&error]; // dataでerrorになれば、これでもerrorになる。 //
					if ((nil != xmlDocument) && (nil == error)) {
						[xmlDocument setCharacterEncoding:[[characterSets() allKeysForObject:[NSNumber numberWithUnsignedInteger:enc]] objectAtIndex:0]]; // これをやると自動的にencoding=が付加される。 //
						NSLog(@"encoding=%@",[[characterSets() allKeysForObject:[NSNumber numberWithUnsignedInteger:enc]] objectAtIndex:0]);
					}
				}
			}
			if ((nil == xmlDocument) || (nil != error)) {
				NSLog(@"0 error=%ld %@",[error code],[error localizedDescription]); // [error code]は201となっていた //
				error = nil;
				xmlDocument = [[NSXMLDocument alloc] initWithData:svgData options:NSXMLDocumentTidyXML error:&error]; // <!DOCTYPEの中にあった注釈や<!ENTYTYなど総て消え去る。 //
				if ((nil != xmlDocument) && (nil == [xmlDocument characterEncoding]))
					[xmlDocument setCharacterEncoding:@"utf-8"]; // encoding=の指定がないときnilになってしまう。OKならばユニコードである。 //
			}
			if ((nil == xmlDocument) || ((nil != error) && (9 == [error code]))) {
				NSLog(@"1 error=%ld %@",[error code],[error localizedDescription]);
				if (nil != (xmlStr = guessEncoding(svgData,&enc))) {
					error = nil;
					xmlDocument = [[NSXMLDocument alloc] initWithXMLString:xmlStr options:NSXMLDocumentTidyXML error:&error];
					if ((nil != xmlDocument) && (nil == error))
						[xmlDocument setCharacterEncoding:[[characterSets() allKeysForObject:[NSNumber numberWithUnsignedInteger:enc]] objectAtIndex:0]];
				}
			}
			if ((nil == xmlDocument) || (nil != error)) { // ここまでerrorになると、クラッシュしてしまう。 //
				NSLog(@"2 error=%ld %@",[error code],[error localizedDescription]);
				error = nil;
				xmlDocument = [[NSXMLDocument alloc] initWithData:svgData options:NSXMLDocumentValidate error:&error];
				if ((nil != xmlDocument) && (nil == [xmlDocument characterEncoding]))
					[xmlDocument setCharacterEncoding:@"utf-8"]; // encoding=の指定がないときnilになってしまう。OKならばユニコードである。 //
			}
			if ((nil == xmlDocument) || ((nil != error) && (9 == [error code]))) {
				NSLog(@"3 error=%ld %@",[error code],[error localizedDescription]);
				if (nil != (xmlStr = guessEncoding(svgData,&enc))) {
					error = nil;
					xmlDocument = [[NSXMLDocument alloc] initWithXMLString:xmlStr options:NSXMLDocumentValidate error:&error];
					if ((nil != xmlDocument) && (nil == error))
						[xmlDocument setCharacterEncoding:[[characterSets() allKeysForObject:[NSNumber numberWithUnsignedInteger:enc]] objectAtIndex:0]];
				}
			}
			if ((nil == xmlDocument) || (nil != error)) {
				NSLog(@"4 error=%ld %@",[error code],[error localizedDescription]);
				error = nil;
			}
			encoding = [[NSString alloc] initWithString:[[xmlDocument characterEncoding] lowercaseString]];
			encodingNumber = [[characterSets() objectForKey:[[xmlDocument characterEncoding] lowercaseString]] unsignedIntegerValue];
			NSDictionary *svgRect = getSVGRect(xmlDocument);
			viewBox = [[svgRect objectForKey:@"ViewBox"] rectValue];
			bounds = [[svgRect objectForKey:@"Bounds"] rectValue];
			size = bounds.size;
			// desc,title 要素からそれぞれの値を読み出す。 //
			desc = [[NSString alloc] initWithString:[svgRect objectForKey:@"desc"]];
			title = [[NSString alloc] initWithString:[svgRect objectForKey:@"title"]];
			fixedRatioX = [[svgRect objectForKey:@"FixedRatioX"] boolValue];
			fixedRatioY = [[svgRect objectForKey:@"FixedRatioY"] boolValue];
		}
		else { // メモのために書いてあるだけ。 //
			if ((YES == useTypeConformance) && (YES == [workspace type:typeName conformsToType:(NSString *)kUTTypePDF])) {
				// pdfImageRep = [[NSPDFImageRep alloc] initWithData:data]; //
				fileURL = (nil != url) ? [[NSURL alloc] initWithString:[url absoluteString]] : nil;
				mimeType = [[NSString alloc] initWithString:@"application/pdf"];
				encoding = nil;
				encodingNumber = NSNotFound;
				desc = [[NSString alloc] initWithString:@""];
				title = [[NSString alloc] initWithString:@""];
				fixedRatioX = fixedRatioY = YES;
			}
			else {
				if ((YES == useTypeConformance) && (YES == [workspace type:typeName conformsToType:@"com.adobe.encapsulated-postscript"])) {
					fileURL = (nil != url) ? [[NSURL alloc] initWithString:[url absoluteString]] : nil;
					mimeType = [[NSString alloc] initWithString:@"application/postscript"];
					encoding = [[NSString alloc] initWithString:@"utf-8"];
					encodingNumber = [[characterSets() objectForKey:@"utf-8"] unsignedIntegerValue];
					desc = [[NSString alloc] initWithString:@""];
					title = [[NSString alloc] initWithString:@""];
					fixedRatioX = fixedRatioY = YES;
				}
			}
		}
		if ((nil != url) && (YES == [url isFileURL])) {
			NSString *fileURLStr = [url absoluteString];
			NSRange range = [fileURLStr rangeOfString:@"/" options:NSBackwardsSearch];
			NSString *baseStr = [fileURLStr substringToIndex:range.location + 1];
			baseURL = [[NSURL alloc] initWithString:baseStr]; // SVGについてはbaseURLが重要。PDFについてもbaseURLがnilだとURLエラーになる。 //
			;
			// NSLog(@"baseURL=%@",[baseURL absoluteString]); //
		}
		else {
			if (nil == url)
				baseURL = nil;
			else {
				NSURL *tempURL = [url baseURL];
				baseURL = (nil != tempURL) ? [tempURL retain] : nil;
			}
		}
		frameName = (nil != fName) ? [[NSString alloc] initWithString:fName] : nil;
		groupName = (nil != gName) ? [[NSString alloc] initWithString:gName] : nil;
		if (YES == [NSThread isMainThread])
			[self setupWebView];
	}
	return self;
}
- (void)setupWebView
{
	if ((nil == view) && (YES == [NSThread isMainThread])) {
		if (nil != (view = [[WebView allocWithZone:[self zone]] initWithFrame:bounds frameName:frameName groupName:groupName])) {
			[view setDrawsBackground:NO]; // 背景色が透明になるかどうかが決まる。YESにすると不透明の白になる。 //
			[[[view mainFrame] frameView] setAllowsScrolling:NO];
			[view setResourceLoadDelegate:self]; // setUIDelegate: setFrameLoadDelegate: setResourceLoadDelegate: //
			[[view mainFrame] loadData:[xmlDocument XMLData] MIMEType:mimeType textEncodingName:encoding baseURL:baseURL];
			// while ([webView isLoading]) CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0, true); としてsetResourceLoadDelegate:を無くしても良いがinit:のときに[NSThread isMainThread]がNOだった場合このメソッドを呼ぶことに変わりない。またエラーの通知をする方法が無いのでdelegateを使うことにする。 //
		}
		else
			NSLog(@"ASWebImageRep:setupWebView did failed.");
	}
}
- (id)initWithXMLDocument:(NSXMLDocument *)xmlDoc URL:(NSURL *)url {
	return [self initWithData:[xmlDoc XMLData] URL:url ofType:ASSVGDocumentTypeName frameName:nil groupName:nil];
}
- (id)initWithXMLDocument:(NSXMLDocument *)xmlDoc {
	return [self initWithData:[xmlDoc XMLData] URL:nil ofType:ASSVGDocumentTypeName  frameName:nil groupName:nil];
}
- (id)initWithData:(NSData *)data URL:(NSURL *)url ofType:(NSString *)typeName {
	NSError *err = nil;
	return ((nil != url) && (YES == [[[url pathExtension] lowercaseString] isEqualToString:ASWebViewSVGZExtension])) ? [self initWithData:[data gzipInflate:&err] URL:url ofType:typeName frameName:nil groupName:nil] : [self initWithData:data URL:url ofType:typeName frameName:nil groupName:nil];
}
- (id)initWithData:(NSData *)data URL:(NSURL *)url {
	NSError *err = nil;
	return ((nil != url) && (YES == [[[url pathExtension] lowercaseString] isEqualToString:ASWebViewSVGZExtension])) ? [self initWithData:[data gzipInflate:&err] URL:url ofType:ASSVGDocumentTypeName frameName:nil groupName:nil] : [self initWithData:data URL:url ofType:ASSVGDocumentTypeName frameName:nil groupName:nil];
}
- (id)initWithData:(NSData *)data {
	return [self initWithData:data URL:nil ofType:ASSVGDocumentTypeName  frameName:nil groupName:nil];
}
- (void)dealloc
{
	if (nil != view) {
		[view setResourceLoadDelegate:nil];
		[view release];
	}
	[xmlDocument release];
	[type release];
	[mimeType release];
	[encoding release];
	[baseURL release];
	[fileURL release];
	[desc release];
	[title release];
	[pdfImageRep release];
	[epsImageRep release];
	[bitmapImageRep release];
	[super dealloc];
}
- (id)webView:(WebView *)sender identifierForInitialRequest:(NSURLRequest *)request fromDataSource:(WebDataSource *)dataSource {
	// delegate //
	return (nil != request) ? [request URL] : nil;
}
- (void)webView:(WebView *)sender resource:(id)identifier didFailLoadingWithError:(NSError *)error fromDataSource:(WebDataSource *)dataSource
// delegate //
{
	NSMutableDictionary *userInfoDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO],PDFImageRepDidLoadResultKey,error,PDFImageRepDidLoadErrorKey,nil];
	if (nil != fileURL)
		[userInfoDic setObject:fileURL forKey:ASWebViewFileURLKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:PDFImageRepDidLoadNotification object:self userInfo:userInfoDic];
	[sender setResourceLoadDelegate:nil]; // viewの役目はここで終了する。 //
	[view release];
	view = nil;
}
- (void)webView:(WebView *)sender resource:(id)identifier didFinishLoadingFromDataSource:(WebDataSource *)dataSource
// delegate //
{
	if (NO == [sender isLoading]) { // 複数回呼ばれるので、isLoadingにより終了を確認する。NOにならずに2回だけ呼ばれて止まってしまうことがある。 //
		[pdfImageRep release];
		pdfImageRep = [[NSPDFImageRep alloc] initWithData:[sender dataWithPDFInsideRect:bounds]]; // OS10.8でfilterが良くなった。その他いろいろ良くなったのでエラーが出難くなった。hasAlphaはYESになったりNOになったり掴みようが無い。だいたいはNOになる。透明色が使われていてもnilにならない。従って全くおかしな画像になる。 //
		[epsImageRep release];
		epsImageRep = [[NSEPSImageRep alloc] initWithData:[sender dataWithEPSInsideRect:bounds]]; // 透明色が使われたときやグラデーションが使われたときなど、必ずnilになる。epsImageRepの方が高速であるが文字がアンチエイリアスされない。initWithData:がnilでもdataWithEPSInsideRect:はnilになっていない。 //
		[bitmapImageRep release];
		if (nil != (bitmapImageRep = [sender bitmapImageRepForCachingDisplayInRect:bounds])) { // autoreleaseされているNSBitmapImageRepのインスタンスが返る。OS10.8からおかしくなった。ClearBitmapImageRep()が必要である。PDFImageRepとepsImageRepがまともでなければ、bitmapImageRepが必要になる。 //
			[bitmapImageRep setAlpha:YES];
			ClearBitmapImageRep(bitmapImageRep); // OS10.8から必要になった。 //
			[sender cacheDisplayInRect:bounds toBitmapImageRep:bitmapImageRep];
			[bitmapImageRep retain];
			// NSLog(@"bitmapFormat=%lu",[bitmapImageRep bitmapFormat]); // bitmapFormatは0が返るのでNSAlphaFirstBitmapFormatではないはずである。 //
		}
		NSMutableString *dataError = [NSMutableString string];
		if (nil == pdfImageRep)
			[dataError appendString:@"dataWithPDFInsideRect is nil."];
		if (nil == epsImageRep)
			[dataError appendString:@"dataWithEPSInsideRect is nil."];
		if (nil == bitmapImageRep)
			[dataError appendString:@"bitmapImageRepForCachingDisplayInRect is nil."];
		if (NO == [dataError isEqualToString:@""])
			NSLog(@"%@",dataError);
		/* NSData *pdfData = [pdfImageRep PDFRepresentation]; // 透明色が使われたときPDF4の仕様により透明色は無視される。PDFからbitmapを取り出すとそのまま透明色が無視されてしまう。 //
		if (nil != pdfData) {
			NSImage *image = [[NSImage alloc] initWithData:pdfData];
			if (nil == image) {
				if (nil != (image = [[NSImage alloc] initWithSize:bounds.size]))
					[image addRepresentation:pdfImageRep];
			}
			if (nil != image) {
				NSData *rData = [image TIFFRepresentation];
				[image release];
				bitmapImageRep = [[NSBitmapImageRep alloc] initWithData:rData];
			}
			else
				bitmapImageRep = nil;
		}
		else
			bitmapImageRep = nil; */
		NSMutableDictionary *userInfoDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],PDFImageRepDidLoadResultKey,nil];
		if (nil != fileURL)
			[userInfoDic setObject:fileURL forKey:ASWebViewFileURLKey];
		[[NSNotificationCenter defaultCenter] postNotificationName:PDFImageRepDidLoadNotification object:self userInfo:userInfoDic];
		[sender setResourceLoadDelegate:nil]; // viewの役目はここで終了する。 //
		[view release];
		 view = nil;
		// NSLog(@"didFinishLoadingFromDataSource"); //
	}
}
/* - (void)webView:(WebView *)sender resource:(id)identifier didReceiveContentLength:(NSInteger)length fromDataSource:(WebDataSource *)dataSource {
 NSLog(@"didReceiveContentLength=%ld",length);
}
- (void)webView:(WebView *)sender resource:(id)identifier didReceiveResponse:(NSURLResponse *)response fromDataSource:(WebDataSource *)dataSource {
 NSLog(@"didReceiveResponse");
} */
- (void)webView:(WebView *)sender plugInFailedWithError:(NSError *)error dataSource:(WebDataSource *)dataSource {
	NSLog(@"plugInFailedWithError"); // これは呼ばれない。 //
}

- (NSImageRep *)bestRepresantion
// pdfの方が良いかepsの方が良いか簡単には分からない。それぞれ一長一短がある。OS10.8からはpdfのエラーが出難くなったのでpdf優先で良い。 //
{
	if ((nil != pdfImageRep) && (nil != epsImageRep)) { // とすれば、透明色が使われたときのぐちゃぐちゃを回避できるが、グラデーションが使われているときにビットマップになってしまって使い難くなる。 //
	// if (nil != pdfImageRep) { // 透明色が使われたときぐちゃぐちゃになってしまう。グラデーションが使われているときでもベクトルになる。 //
		return pdfImageRep;
	}
	else {
		if (nil != epsImageRep) {
			return epsImageRep;
		}
		else {
			return bitmapImageRep;
		}
	}
}
- (NSImageRep *)bestRepresantion_test
// pdfの方が良いかepsの方が良いか簡単には分からない。それぞれ一長一短がある。OS10.8からはpdfのエラーが出難くなったのでpdf優先で良い。 //
{
	if (nil != epsImageRep) {
		return epsImageRep;
	}
	else {
		if (nil != pdfImageRep) {
			return pdfImageRep;
		}
		else {
			return bitmapImageRep;
		}
	}
}
- (BOOL)draw
// override //
// カレントの座標系の(0.0,0.0)の位置にイメージを描画する。イメージが正常に描画できたときにはYESを返し、できなかったときにはNOを返す。 //
{
	NSImageRep *bestRep = [self bestRepresantion];
	return (nil != bestRep) ? [bestRep draw] : NO;
}
- (BOOL)drawInRect:(NSRect)rect {
// override //
// rectで指定された矩形の内部にフィットするようにイメージを描画します。このメソッドは、カレントの座標系を矩形で指定された位置に設定してから、その矩形内にイメージがフィットするように座標系の縮尺を行い、その後、レシーバに設定されているdrawメソッドを呼び出してイメージを描画します。イメージの描画が終了すると、座標系の原点や縮尺率は、元の状態に戻されます。イメージのサイズが設定されていないと、座標変換や縮尺、描画といった処理はいっさい行わず、単純にNOを返します。その他の場合には、drawメソッドによって返された値(イメージが正常に描画できたかどうか)が返されます。 //
	NSImageRep *bestRep = [self bestRepresantion];
	return (nil != bestRep) ? [bestRep drawInRect:rect] : NO;
}
- (BOOL)drawAtPoint:(NSPoint)aPoint {
// override //
// カレントの座標系をaPointで示される位置に設定し、drawメソッドを呼び出してその位置にイメージを描画した後、座標系を元の状態に戻します。aPointで指定され対置が(0.0,0.0)の場合、このメソッドは、単純にdrawメソッドを呼び出すという処理だけを行います。イメージのサイズが設定されていないと、座標変換や縮尺、描画といった処理はいっさい行わず、単純にNOを返します。その他の場合には、drawメソッドによって返された値(イメージが正常に描画できたかどうか)が返されます。 //
	NSImageRep *bestRep = [self bestRepresantion];
	return (nil != bestRep) ? [bestRep drawAtPoint:aPoint] : NO;
}
- (BOOL)drawInRect:(NSRect)dstSpacePortionRect fromRect:(NSRect)srcSpacePortionRect operation:(NSCompositingOperation)op fraction:(CGFloat)requestedAlpha respectFlipped:(BOOL)respectContextIsFlipped hints:(NSDictionary *)hints {
// override //
	NSImageRep *bestRep = [self bestRepresantion];
	return (nil != bestRep) ? [bestRep drawInRect:dstSpacePortionRect fromRect:srcSpacePortionRect operation:op fraction:requestedAlpha respectFlipped:respectContextIsFlipped hints:hints] : NO;
}
static NSRect flippedRotateRect(NSRect originalRect,double angle)
// 回転無しの座標系での座標値を求める。 //
{
	double sine = sin(angle);
	double cosine = cos(angle);
	double llx = NSMinX(originalRect) * cosine - NSMinY(originalRect) * sine;
	double lly = NSMinX(originalRect) * sine + NSMinY(originalRect) * cosine;
	double urx = llx;
	double ury = lly;
	
	switch ((NSInteger)(angle * M_2_PI)) {
		case 3:	// 360 - 270 //
			lly += NSWidth(originalRect) * sine;
			urx += NSWidth(originalRect) * cosine - NSHeight(originalRect) * sine;
			ury += NSHeight(originalRect) * cosine;
			break;
		case 2:	// 270 - 180 //
			llx += NSWidth(originalRect) * cosine;
			lly += NSWidth(originalRect) * sine + NSHeight(originalRect) * cosine;
			urx -= NSHeight(originalRect) * sine;
			break;
		case 1:	// 180 - 90 //
			llx += NSWidth(originalRect) * cosine - NSHeight(originalRect) * sine;
			lly += NSHeight(originalRect) * cosine;
			ury += NSWidth(originalRect) * sine;
			break;
		default:	// 90以下 and 360以上 //
			llx -= NSHeight(originalRect) * sine;
			urx += NSWidth(originalRect) * cosine;
			ury += NSWidth(originalRect) * sine + NSHeight(originalRect) * cosine;
			break;
	}
	return NSMakeRect(llx,lly,urx - llx,ury - lly);
}
static NSRect rotateRect(NSRect originalRect,double angle)
{
	double sine = sin(angle);
	double cosine = cos(angle);
	double llx = NSMinX(originalRect) * cosine + NSMinY(originalRect) * sine;
	double lly = -1.0 * NSMinX(originalRect) * sine + NSMinY(originalRect) * cosine;
	double urx = llx;
	double ury = lly;
	
	switch ((NSInteger)(angle * M_2_PI)) {
		case 3:	// 360 - 270 //
			llx += NSHeight(originalRect) * sine;
			urx += NSWidth(originalRect) * cosine;
			ury -= NSWidth(originalRect) * sine - NSHeight(originalRect) * cosine;
			break;
		case 2:	// 270 - 180 //
			llx += NSWidth(originalRect) * cosine + NSHeight(originalRect) * sine;
			lly += NSHeight(originalRect) * cosine;
			ury -= NSWidth(originalRect) * sine;
			break;
		case 1:	// 180 - 90 //
			llx += NSWidth(originalRect) * cosine;
			lly -= NSWidth(originalRect) * sine - NSHeight(originalRect) * cosine;
			urx += NSHeight(originalRect) * sine;
			break;
		default:	// 90以下 and 360以上 //
			lly -= NSWidth(originalRect) * sine;
			urx += NSHeight(originalRect) * sine + NSWidth(originalRect) * cosine;
			ury += NSHeight(originalRect) * cosine;
			break;
	}
	return NSMakeRect(llx,lly,urx - llx,ury - lly);
}
- (NSXMLDocument *)transform:(NSRect)newRect viewBox:(NSRect)newViewBoxRect rotate:(double)angle scaleXBy:(double)scaleX yBy:(double)scaleY // SVGのみ。fixedScaleがNOの場合は縮小されるがしかたない。 //
{
	NSXMLDocument *xmlDoc = [xmlDocument copy]; // DTDの部分は総て解析され、消滅している。 //
	NSXMLElement *rootElement = [xmlDoc rootElement];

	if ((0.000004 < angle) && (6.283181 > angle)) { // 回転移動の必要があるならば //
		NSXMLElement *gElement = [NSXMLElement elementWithName:@"g"];
		NSMutableString *rotateString = [NSMutableString stringWithFormat:@"rotate(%g)",180.0 * angle * M_1_PI];
		NSArray *rootChildren = [NSArray arrayWithArray:[rootElement children]];
		for (NSXMLNode *node in rootChildren) { // [gElement setChildren:rootChildren]; はOS10.5から使えなくなった。 //
			[node detach];
			[gElement addChild:node];
		}
		[gElement addAttribute:[NSXMLNode attributeWithName:@"transform" stringValue:rotateString]];
		[gElement addAttribute:[NSXMLNode attributeWithName:@"id" stringValue:[NSString stringWithFormat:@"RotateBy%@-SatoAkira.",NSStringFromClass([self class])]]];
		[rootElement setChildren:[NSArray arrayWithObject:gElement]];
	}
	// width,height,viewBoxの変更 //
	NSString *viewBoxString = [NSString stringWithFormat:@"%g %g %g %g",NSMinX(newViewBoxRect),NSMinY(newViewBoxRect),NSWidth(newViewBoxRect),NSHeight(newViewBoxRect)]; // scaleX,scaleYは盛り込まれるようにviewBoxを設定しなければならない。 //
	if (nil != [rootElement attributeForName:@"viewBox"])
		[rootElement removeAttributeForName:@"viewBox"];
	[rootElement addAttribute:[NSXMLNode attributeWithName:@"viewBox" stringValue:viewBoxString]];
	if (nil != [rootElement attributeForName:@"width"])
		[rootElement removeAttributeForName:@"width"];
	[rootElement addAttribute:[NSXMLNode attributeWithName:@"width" stringValue:[NSString stringWithFormat:@"%gpx",scaleX * NSWidth(newRect)]]];
	if (nil != [rootElement attributeForName:@"height"])
		[rootElement removeAttributeForName:@"height"];
	[rootElement addAttribute:[NSXMLNode attributeWithName:@"height" stringValue:[NSString stringWithFormat:@"%gpx",scaleY * NSHeight(newRect)]]];
	// この時点でxmlDocのretainCountは1 //
	return [xmlDoc autorelease];
}
- (NSPoint)backwordViewBoxOrigin:(double)angle bounds:(NSRect)newRect origin:(NSPoint)origin
{
	double vx,vy;
	double x = origin.x; // newOXの調整用と考える。 //
	double y = origin.y; // newOyの調整用と考える。 //
	double vw = NSWidth(viewBox) * NSWidth(newRect) / NSWidth(bounds);
	double vh = NSHeight(viewBox) * NSHeight(newRect) / NSHeight(bounds);
	NSDictionary *svgRect = getSVGRect(xmlDocument);
	double gRatioX = [[svgRect objectForKey:@"GRatioX"] doubleValue]; // preserveAspectRatioのalignがnone以外の場合は、gRatioXとgRatioYとは同じ値。 //
	double gRatioY = [[svgRect objectForKey:@"GRatioY"] doubleValue];
	double ox = [[svgRect objectForKey:@"Ox"] doubleValue];
	double oy = [[svgRect objectForKey:@"Oy"] doubleValue];
	double newOx = ox * cos(angle) - oy * sin(angle) - NSMinX(newRect);
	double newOy = ox * sin(angle) + oy * cos(angle) - NSMinY(newRect);
	NSString *align = [svgRect objectForKey:@"Align"];
	
	if (0 != [values() indexOfObject:align]) {
		switch ([values() indexOfObject:align]) {
			case 1: // xMinYMin //
				vx = (x - newOx) / gRatioX;
				vy = (y - newOy) / gRatioY;
				break;
			case 2: // xMinYMid //
				vx = (x - newOx) * gRatioX;
				vy = (y + 0.5 * NSHeight(newRect) - newOy) / gRatioY - 0.5 * vh;
				break;
			case 3: // xMinYMax //
				vx = (x - newOx) / gRatioX;
				vy = (y + NSHeight(newRect) - newOy) / gRatioY - vh;
				break;
			case 4: // xMidYMin //
				vx = (x + 0.5 * NSWidth(newRect) - newOx) / gRatioX - 0.5 * vw;
				vy = (y - newOy) / gRatioY;
				break;
			case 6: // xMidYMax //
				vx = (x + 0.5 * NSWidth(newRect) - newOx) / gRatioX - 0.5 * vw;
				vy = (y + NSHeight(newRect) - newOy) / gRatioY - vh;
				break;
			case 7: // xMaxYMin //
				vx = (x + NSWidth(newRect) - newOx) / gRatioX - vw;
				vy = (y - newOy) / gRatioY;
				break;
			case 8: // xMaxYMid //
				vx = (x + NSWidth(newRect) - newOx) / gRatioX - vw;
				vy = (y + 0.5 * NSHeight(newRect) - newOy) / gRatioY - 0.5 * vh;
				break;
			case 9: // xMaxYMax //
				vx = (x + NSWidth(newRect) - newOx) / gRatioX - vw;
				vy = (y + NSHeight(newRect) - newOy) / gRatioY - vh;
				break;
			default: // case5: xMidYMid //
				vx = (x + 0.5 * NSWidth(newRect) - newOx) / gRatioX - 0.5 * vw;
				vy = (y + 0.5 * NSHeight(newRect) - newOy) / gRatioY - 0.5 * vh;
				break;
		}
	}
	else {
		vx = (x - newOx) / gRatioX;
		vy = (y - newOy) / gRatioY;
		// xmlDocumentにviewBoxが定義されていなくても、このオブジェクト中ではviewBoxの値は必ず定義されている。定義されていなければやりようが無い。 //
	}
	// NSLog(@"newox=%f newoy=%f vx=%f vy=%f",newOx,newOy,vx,vy); //
	return NSMakePoint(vx,vy);
}
- (void)rotateByRadians:(double)angle // SVGのみ。PDFを代替にするときはこれを呼ばない。 //
{
#ifdef SETFLIPPED
	NSRect newRect = flippedRotateRect(bounds,angle);
#else
	NSRect newRect = rotateRect(bounds,angle);
#endif
	double ratioX = NSWidth(newRect) / NSWidth(bounds);
	double ratioY = NSHeight(newRect) / NSHeight(bounds);
	NSPoint newViewBoxOrigin = [self backwordViewBoxOrigin:angle bounds:newRect origin:bounds.origin];
	NSRect newViewBoxRect = NSMakeRect(newViewBoxOrigin.x, newViewBoxOrigin.y, NSWidth(viewBox) * ratioX, NSHeight(viewBox) * ratioY);
	NSXMLDocument *xmlDoc = [self transform:newRect viewBox:newViewBoxRect rotate:angle scaleXBy:1.0 yBy:1.0];
	[[view mainFrame] loadData:[xmlDoc XMLData] MIMEType:mimeType textEncodingName:encoding baseURL:baseURL];
}
- (NSXMLDocument *)transformedDocument:(double)angle scaleXBy:(double)scaleX yBy:(double)scaleY
{
#ifdef SETFLIPPED
	NSRect newRect = flippedRotateRect(bounds,angle);
#else
	NSRect newRect = rotateRect(bounds,angle);
#endif
	double ratioX = NSWidth(newRect) / NSWidth(bounds);
	double ratioY = NSHeight(newRect) / NSHeight(bounds);
	NSPoint newViewBoxOrigin = [self backwordViewBoxOrigin:angle bounds:newRect origin:bounds.origin];
	// NSLog(@"bounds=%@ calc=%@",NSStringFromPoint(bounds.origin),NSStringFromPoint(newRect.origin)); //
	NSRect newViewBoxRect = NSMakeRect(newViewBoxOrigin.x, newViewBoxOrigin.y, NSWidth(viewBox) * ratioX, NSHeight(viewBox) * ratioY);
	return [self transform:newRect viewBox:newViewBoxRect rotate:angle scaleXBy:scaleX yBy:scaleY];
}
- (NSXMLDocument *)xmlDocumentWithSVGInsideRect:(NSRect)clipRect rotate:(double)angle
{
#ifdef SETFLIPPED
	NSRect newRect = flippedRotateRect(bounds,angle);
#else
	NSRect newRect = rotateRect(bounds,angle);
#endif
	double ratioX = NSWidth(clipRect) / NSWidth(bounds);
	double ratioY = NSHeight(clipRect) / NSHeight(bounds);
	NSPoint newViewBoxOrigin = [self backwordViewBoxOrigin:angle bounds:clipRect origin:newRect.origin];
	// NSLog(@"clipRect=%@ calc=%@",NSStringFromPoint(clipRect.origin),NSStringFromPoint(newRect.origin)); //
	NSRect newViewBoxRect = NSMakeRect(newViewBoxOrigin.x, newViewBoxOrigin.y, NSWidth(viewBox) * ratioX, NSHeight(viewBox) * ratioY);
	return [self transform:clipRect viewBox:newViewBoxRect rotate:angle scaleXBy:1.0 yBy:1.0];
}
- (NSData *)SVGRepresentation { // 回転無し //
	return [xmlDocument XMLData];
}
- (NSData *)SVGPrettyRepresentation { // 回転無し //
	return [xmlDocument XMLDataWithOptions:NSXMLNodePrettyPrint];
}
- (NSData *)PDFRepresentation { // 回転無し //
	return (nil != pdfImageRep) ? [pdfImageRep PDFRepresentation] : nil;
}
- (NSData *)EPSRepresentation { // 回転無し //
	return (nil != epsImageRep) ? [epsImageRep EPSRepresentation] : nil;
}
- (NSData *)TIFFRepresentation { // デフォルトの圧縮方法で圧縮されたTIFFになっているデータオブジェクトを返します。元のSVGRepresentationを使ったデータです。
	return (nil != bitmapImageRep) ? [bitmapImageRep TIFFRepresentation] :nil;
}

- (NSRect)bounds {
	return bounds;
}
- (BOOL)isFlipped {
#ifdef SETFLIPPED
	return YES; // webViewのisFlippedとは無関係。 //
#else
	return NO;
#endif
}
- (NSColorSpace *)colorSpace {
	return [NSColorSpace sRGBColorSpace];
}
+ (NSData *)gunzip:(NSData *)gzipData error:(NSError **)outError {
	return [gzipData gzipInflate:outError];
}
+ (NSData *)gzip:(NSData *)xmlData {
	return [xmlData gzipDeflate];
}

- (BOOL)hasAlpha { // override //
	return YES;
}
- (NSSize)size { // override //
	return size;
}
- (NSString *)colorSpaceName { // override //
	return [[self colorSpace] localizedName];
}
- (void)setSize:(NSSize)aSize
// override //
{
	;
}
- (id)copyWithZone:(NSZone *)zone {
	// override。新しいオブジェクトに対してnotification待ちにしなければならないので非常に使いにくい。 //
	ASWebImageRep *newInstance = [[[self class] allocWithZone:zone] initWithXMLDocument:xmlDocument URL:fileURL];
	return newInstance; // autoreleaseしないのが普通のやり方 //
}
- (id)initWithCoder:(NSCoder *)aDecoder
// override //
{
	[super initWithCoder:aDecoder];
	xmlDocument = [[aDecoder decodeObjectForKey:@"_xmlDocument"] retain]; // viewはpdfImageRepがあるので不要。 //
	type = [[aDecoder decodeObjectForKey:@"_type"] retain];
	mimeType = [[aDecoder decodeObjectForKey:@"_mimeType"] retain];
	encoding = [[aDecoder decodeObjectForKey:@"_encoding"] retain];
	encodingNumber = [aDecoder decodeIntegerForKey:@"_encodingNumber"];
	bounds = [aDecoder decodeRectForKey:@"_bounds"];
	size = [aDecoder decodeSizeForKey:@"_size"];
	viewBox = [aDecoder decodeRectForKey:@"viewBox"];
	baseURL = [[aDecoder decodeObjectForKey:@"_baseURL"] retain];
	fileURL = [[aDecoder decodeObjectForKey:@"_fileURL"] retain];
	desc = [[aDecoder decodeObjectForKey:@"_desc"] retain];
	title = [[aDecoder decodeObjectForKey:@"_title"] retain];
	fixedRatioX = [aDecoder decodeBoolForKey:@"_fixedRatioX"];
	fixedRatioY = [aDecoder decodeBoolForKey:@"_fixedRatioY"];
	pdfImageRep = [[aDecoder decodeObjectForKey:@"_pdfImageRep"] retain];
	epsImageRep = [[aDecoder decodeObjectForKey:@"_epsImageRep"] retain];
	bitmapImageRep = [[aDecoder decodeObjectForKey:@"_bitmapImageRep"] retain];
	frameName = [[aDecoder decodeObjectForKey:@"_frameName"] retain];
	groupName = [[aDecoder decodeObjectForKey:@"_groupName"] retain];
	return self;
}
- (void)encodeWithCoder:(NSCoder *)aCoder
// override //
{
	[super encodeWithCoder:aCoder];
	[aCoder encodeObject:xmlDocument forKey:@"_xmlDocument"];
	[aCoder encodeObject:type forKey:@"_type"];
	[aCoder encodeObject:mimeType forKey:@"_mimeType"];
	[aCoder encodeObject:encoding forKey:@"_encoding"];
	[aCoder encodeInteger:encodingNumber forKey:@"_encodingNumber"];
	[aCoder encodeRect:bounds forKey:@"_bounds"];
	[aCoder encodeSize:size forKey:@"_size"];
	[aCoder encodeRect:viewBox forKey:@"_viewBox"];
	[aCoder encodeObject:baseURL forKey:@"_baseURL"];
	[aCoder encodeObject:fileURL forKey:@"_fileURL"];
	[aCoder encodeObject:desc forKey:@"_desc"];
	[aCoder encodeObject:title forKey:@"_title"];
	[aCoder encodeBool:fixedRatioX forKey:@"_fixedRatioX"];
	[aCoder encodeBool:fixedRatioY forKey:@"_fixedRatioY"];
	[aCoder encodeObject:pdfImageRep forKey:@"_pdfImageRep"];
	[aCoder encodeObject:epsImageRep forKey:@"_epsImageRep"];
	[aCoder encodeObject:bitmapImageRep forKey:@"_bitmapImageRep"];
	[aCoder encodeObject:frameName forKey:@"_frameName"];
	[aCoder encodeObject:groupName forKey:@"_groupName"];
}

@end
