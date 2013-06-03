//
//  ASImageView.m
//
//  Copyright (c) 2004 SatoAkira. All rights reserved.
//

#import "ASImageView.h"
#import "ASWebViewFunctions.h" // for UTI() //
#import <libc.h>	// for mktemp() //

static Class _myStoredCellClass = nil;

@implementation ASImageView

NSString *ASImageViewDidConcludeDragOperaionNotification = @"ASImageViewDidConcludeDragOperaion";
NSString *ASImageViewDidPasteNotification = @"ASImageViewDidPaste";
NSString *ASImageViewDidOpenNotification = @"ASImageViewDidOpen";
NSString *ASImageViewDefaultFileURL = @"ASImageViewDefaultFileURL";
NSString *ASImageViewCurrentURLKey = @"currentURL";
NSString *ASImageViewImageDataKey = @"imageData";
NSString *ASImageViewDataRetainedKey = @"dataRetained";
NSString *ASImageViewAllowsCutCopyPasteKey = @"allowsCutCopyPaste";
NSString *ASImageViewTreatsFilePackageAsDirectoriesKey = @"treatsFilePackageAsDirectories";
NSString *ASImageViewAllowedFileTypesKey = @"allowedFileTypes";

+ (void)initialize
{
	if (self == [ASImageView class])
		[self setCellClass:[ASImageViewCell class]];
}
+ (Class)cellClass {
	return _myStoredCellClass;
}
+ (void)setCellClass:(Class)classId {
	_myStoredCellClass = classId;
}

- (id)initWithFrame:(NSRect)frameRect
{
	if (nil != (self = [super initWithFrame:frameRect])) {
		Class cellClass = [[self class] cellClass];
		ASImageViewCell *myCell = [[cellClass allocWithZone:[self zone]] initImageCell:nil];
		[self setCell:myCell];
		currentURL = nil;
		imageData = nil;
		dataRetained = NO;
		[myCell setEditable:YES]; // NSImageViewのデフォルトがYESになっているのでそれに合わせる。 //
		allowsCutCopyPaste = YES; // NSImageViewのデフォルトがYESになっているのでそれに合わせる。 //
		animates = YES; // 未完成。NSImageViewのデフォルトがYESになっているのでそれに合わせる。 //
		treatsFilePackageAsDirectories = NO;
		allowedFileTypes = [[NSArray alloc] initWithObjects:(NSString *)kUTTypeImage,(NSString *)kUTTypePDF,@"com.adobe.postscript",ASSVGDocumentTypeName, nil];
		[self registerForDraggedTypes:[NSArray arrayWithObjects:NSColorPboardType, NSFilenamesPboardType, nil]];
		[myCell release];
	}
	return self;
}
- (void)dealloc {
	[currentURL release];
	[imageData release];
	[allowedFileTypes release];
	[super dealloc];
}

- (void)awakeFromNib {
	[self setOutlet];
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
// 最初のマウスダウンがあったときに一回だけ呼ばれる //
{
	return [[self window] makeFirstResponder:self] ;
}
- (BOOL)resignFirstResponder
// 最初にファーストレスポンダでなくなるときに一回だけ呼ばれるが、[self setNeedsDisplay:YES]はその都度実行される。 //
{
	[self updateCell:[self cell]];
	return YES;
}
/* - (BOOL)acceptsFirstResponder {
	return ((YES == [self isEnabled]) && [[self window] makeFirstResponder:self]); // NSControlのサブクラスにするとこれをフェッチしないとbecomeFirstResponder:が呼ばれなくなる。従ってcopy:,paste:,print:も不可能になる。NSCellを作っておけば実装しなくても良い。 //
}
- (BOOL)becomeFirstResponder {
    return YES;
} */

- (NSString *)printJobTitle {
	return NSStringFromClass([self class]);
}
- (BOOL)isFlipped {
	return [[[self cell] valueForKey:@"isFlipped"] boolValue];
}
- (BOOL)isOpaque {
	return NO;
}
- (void)setStringValue:(NSString *)aString { // overwride //
	[self openFileFor:aString];
}
- (IBAction)takeStringValueFrom:(id)sender { // overwride //
	[self openFileFor:[sender stringValue]];
}

- (IBAction)copy:(id)sender
// overwride.オリジナルの画像ファイルのデータとはかなり画質が落ちることになるが、このデバイスの性格からするとこの方法で良い。 //
{
	if ((YES == [[self cell] isEditable]) && (YES == allowsCutCopyPaste)) {
#ifdef __APPLE__
		NSPasteboardItem *pasteboardItem = [[NSPasteboardItem alloc] init];
		[pasteboardItem setData:[self dataWithPDFInsideRect:[self bounds]] forType:(NSString *)kUTTypePDF];
		[pasteboardItem setData:[self dataWithEPSInsideRect:[self bounds]] forType:@"com.adobe.encapsulated-postscript"];
		if (0 < [[pasteboardItem types] count]) {
			NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
			[pasteboard clearContents];
			if (NO == [pasteboard writeObjects:[NSArray arrayWithObject:pasteboardItem]])
				NSLog(@"ASWebImageView:pasteboard error.");
		}
		[pasteboardItem release];
#else
		NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
		[pasteboard declareTypes:[NSArray arrayWithObject:NSPostScriptPboardType] owner:nil];
		[self writeEPSInsideRect:[self bounds] toPasteboard:pasteboard];
#endif
	}
	else
		NSBeep();
}

- (IBAction)paste:(id)sender // override. //
{
	NSPasteboard *pboard = [NSPasteboard generalPasteboard];

	if ((YES == [[self cell] isEditable]) && (YES == allowsCutCopyPaste) && (YES == [NSImageRep canInitWithPasteboard:pboard])) {
		NSArray *tempReps = [NSImageRep imageRepsWithPasteboard:pboard];

		if ((nil != tempReps) && (0 < [tempReps count])) { // 元のものとはかなり違う形式になる。NSImageViewも同じ。  //
			[currentURL release];
			currentURL = nil; // nilのままにしておく。imageDataは更新される。 //
			[[self cell] setImageWithArray:tempReps];
			[self updateCellInside:[self cell]];
			[self setOutlet];
			[imageData release];
			if (YES == dataRetained) {
				// [pboard types]のうちのどれを使ってtempRepsが生成されたか分からないのでtempRepsのclassから判断する。imageDataを利用する側でも、currentURLがnilのときという判断をして、NSImageRepのclassから判断して拡張子やURIなどを決定する。 //
				// [pboard types]はdyn.agu8yc6durvwway5pqz4gg4bagkuha2pxsvw0e55bsmwca7d3sbwu とかcom.adobe.encapsulated-postscript,com.adobe.pdf,NeXT TIFF v4.0 pasteboard typeとかいろいろ混じっている。 //
				NSImageRep *tempRep = [tempReps objectAtIndex:0];
#ifdef USESVG
				if (YES == [tempRep isKindOfClass:[ASWebImageRep class]])
					imageData = [[NSData alloc] initWithData:[(ASWebImageRep *)tempRep SVGRepresentation]];
				else {
#endif
				if (YES == [tempRep isKindOfClass:[NSPDFImageRep class]])
					imageData = [[NSData alloc] initWithData:[(NSPDFImageRep *)tempRep PDFRepresentation]];
				else { if (YES == [tempRep isKindOfClass:[NSEPSImageRep class]])
					imageData = [[NSData alloc] initWithData:[(NSEPSImageRep *)tempRep EPSRepresentation]];
				else { if (YES == [tempRep isKindOfClass:[NSPICTImageRep class]])
					imageData = [[NSData alloc] initWithData:[(NSPICTImageRep *)tempRep PICTRepresentation]];
				else { if (YES == [tempRep isKindOfClass:[NSBitmapImageRep class]])
					imageData = [[NSData alloc] initWithData:[NSBitmapImageRep TIFFRepresentationOfImageRepsInArray:tempReps]];
				else
					imageData = nil;
				}
				}
				}
#ifdef USESVG
				}
#endif
			}
			else
				imageData = nil;
			[[NSNotificationCenter defaultCenter] postNotificationName:ASImageViewDidPasteNotification object:self];
		}
	}
	else
		NSBeep();
}

- (IBAction)cut:(id)sender { // overwride. //
	if ((YES == [[self cell] isEditable]) && (YES == allowsCutCopyPaste)) {
		[self copy:sender];
		[self eraseInside:sender];
	}
	else
		NSBeep();
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	[super initWithCoder:aDecoder];
	currentURL = [[aDecoder decodeObjectForKey:ASImageViewCurrentURLKey] retain];
	imageData = [[aDecoder decodeObjectForKey:ASImageViewImageDataKey] retain];
	allowsCutCopyPaste = [aDecoder decodeBoolForKey:ASImageViewAllowsCutCopyPasteKey];
	animates = [aDecoder decodeBoolForKey:@"animates"];
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[super encodeWithCoder:aCoder];
	[aCoder encodeObject:[currentURL absoluteString] forKey:ASImageViewCurrentURLKey];
	[aCoder encodeObject:imageData forKey:ASImageViewImageDataKey];
	[aCoder encodeBool:allowsCutCopyPaste forKey:ASImageViewAllowsCutCopyPasteKey];
	[aCoder encodeBool:animates forKey:@"animates"];
}
- (NSDragOperation)dragOperationForDraggingInfo:(id <NSDraggingInfo>)sender
// 自分が実行するドラッグ操作を返さなければならない。 //
{
	if (YES == [[self cell] isEditable]) {
		NSArray *classes = [NSArray arrayWithObjects:[NSURL class],[NSColor class], nil];
		NSArray *raw_imageTypes = [NSArray arrayWithObjects:@"com.phaseone.raw-image", nil];
		NSMutableArray *imageTypes = [NSMutableArray arrayWithArray:[NSImage imageTypes]];
		[imageTypes addObjectsFromArray:raw_imageTypes];
		[imageTypes addObject:@"com.adobe.illustrator.ai-image"];
		NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:imageTypes,NSPasteboardURLReadingContentsConformToTypesKey, nil]; // NSColorに関するoptionは特に無い。 //
		NSDragOperation sourceDragMask = [sender draggingSourceOperationMask];
		NSPasteboard *pasteboard = [sender draggingPasteboard];
		NSArray *imageURLs = [pasteboard readObjectsForClasses:classes options:options];
		
		if (nil != imageURLs) {
			if ([NSURL class] == [[imageURLs lastObject] class]) {
				NSURL *url = [imageURLs lastObject];
				NSError *err = nil;
				NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
				NSString *utiType = [workspace typeOfFile:[url path] error:&err];
				BOOL conformsToType = NO;
				for (NSString *tempUTI in allowedFileTypes) { // concludeDragOperation:と同じように[NSImageRep imageRepClassForType:utiType];でチェックする方法もある。 //
					if (YES == [workspace type:utiType conformsToType:tempUTI]) {
						conformsToType = YES;
						break;
					}
				}
				if (YES == conformsToType) {
					if (sourceDragMask & NSDragOperationCopy)
						return NSDragOperationCopy; // + //
					else {
						if (sourceDragMask & NSDragOperationLink)
							return NSDragOperationLink; // 時計回り矢印 //
						else
							return NSDragOperationGeneric; // 通常の矢印 //
					}
				}
				else
					return NSDragOperationNone;
			}
			else
				return NSDragOperationGeneric;
		}
		else
			return NSDragOperationNone;
	}
	else
		return NSDragOperationNone;
}
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
// Conformance to the NSObject(NSDraggingDestination) informal protocol. //
{
#ifdef USESVG
	[NSImageRep registerImageRepClass:[ASWebImageRep class]];
#endif
    return [self dragOperationForDraggingInfo:sender];
}
- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender {
	return [self dragOperationForDraggingInfo:sender];
}
- (void)draggingExited:(id <NSDraggingInfo>)sender {
    return;
}
- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender {
    return YES;
}
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
	return ([self draggingUpdated:sender] == NSDragOperationNone) ? NO : YES;
}
- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
// ドラッグ処理が完了し、直前の performDragOperation: が YES を返したときに呼び出されます。このメソッドは、ドラッグによって実装されたデータを視覚的に表現するための更新処理などの終了処理を行うために、デスティネーションに実装します。このメッセージは、ドラッグセッション内で、センダからデスティネーションに送信される最後のメッセージとなります。 //
// useBackgroundColorがNOのときはカラーをドラッグしても背景色は設定されるけれども表示はされない。[[pboard types] count]は19くらいになる。 //
{
	NSArray *classes = [NSArray arrayWithObjects:[NSURL class],[NSColor class], nil];
	NSArray *raw_imageTypes = [NSArray arrayWithObjects:@"com.phaseone.raw-image", nil];
	NSMutableArray *imageTypes = [NSMutableArray arrayWithArray:[NSImage imageTypes]];
	[imageTypes addObjectsFromArray:raw_imageTypes];
	[imageTypes addObject:@"com.adobe.illustrator.ai-image"];
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:imageTypes,NSPasteboardURLReadingContentsConformToTypesKey, nil]; // NSColorに関するoptionは特に無い。 //
	NSPasteboard *pasteboard = [sender draggingPasteboard];
	NSArray *imageURLs = [pasteboard readObjectsForClasses:classes options:options];
	if ((nil != imageURLs) && (0 < [imageURLs count])) {
		if (YES == [[imageURLs lastObject] isKindOfClass:[NSURL class]]) { // 複数のobjectに対応しても意味が無いのでlastObjectの一つにしてしまう。 //
			NSArray *tempReps = nil;
			NSImageRep *tempRep;
			NSURL *url = [imageURLs lastObject];
			NSError *err = nil;
			NSData *aData = [NSData dataWithContentsOfURL:url options:NSDataReadingUncached error:&err];
			if (nil != aData) {
				NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
				NSString *utiType = [workspace typeOfFile:[url path] error:&err];
				if (YES == [workspace type:utiType conformsToType:ASSVGDocumentTypeName])
					tempReps = [ASWebImageRep imageRepsWithContentsOfURL:url];
				else {
					if (YES == [workspace type:utiType conformsToType:@"com.adobe.illustrator.ai-image"]) {
						if (nil == (tempRep = [NSEPSImageRep imageRepWithData:aData])) {
							if (nil != (tempRep = [NSPDFImageRep imageRepWithData:aData]))
								tempReps = [NSArray arrayWithObject:tempRep];
						}
						else
							tempReps = [NSArray arrayWithObject:tempRep];
					}
					else {
						NSString *imageType = nil;
						for (NSString *type in imageTypes) {
							if (YES == [workspace type:utiType conformsToType:type]) {
								imageType = type;
								break;
							}
						}
						if (nil != imageType) {
							if (YES == [workspace type:imageType conformsToType:@"com.adobe.encapsulated-postscript"]) {
								if (nil != (tempRep = [NSEPSImageRep imageRepWithData:aData]))
									tempReps = [NSArray arrayWithObject:tempRep];
							}
							else {
								if (YES == [workspace type:imageType conformsToType:(NSString *)kUTTypePDF]) {
									if (nil != (tempRep = [NSPDFImageRep imageRepWithData:aData]))
										tempReps = [NSArray arrayWithObject:tempRep];
								}
								else {
									if (YES == [workspace type:imageType conformsToType:(NSString *)kUTTypePICT]) {
										if (nil != (tempRep = [NSPICTImageRep imageRepWithData:aData]))
											tempReps = [NSArray arrayWithObject:tempRep];
									}
									else {
										NSMutableArray *imageRepTypes = [NSMutableArray arrayWithArray:[NSBitmapImageRep imageTypes]];
										[imageRepTypes addObjectsFromArray:raw_imageTypes];
										if (YES == [imageRepTypes containsObject:imageType]) 
											tempReps = [NSBitmapImageRep imageRepsWithData:aData];
									}
								}
							}
						}
					}
				}
			}
			if ((nil != tempReps) && (0 < [tempReps count])) { // NSImageRepからだとinitWithData:を呼んでしまいurlが消えてしまう。 //
				[currentURL release];
				currentURL = [url retain];
				[imageData release];
				imageData = (YES == dataRetained) ? [aData retain] : nil;
				[[self cell] setImageWithArray:tempReps];
				[self updateCellInside:[self cell]];
				[self setOutlet];
				[[NSNotificationCenter defaultCenter] postNotificationName:ASImageViewDidConcludeDragOperaionNotification object:self];
			}
			// else NSLog(@"tempReps is empty."); //
		}
		else {
			if (YES == [[imageURLs lastObject] isKindOfClass:[NSColor class]]) {
				[[self cell] setValue:[imageURLs lastObject] forKey:ASImageViewBackgroundColorKey];
				[self updateCellInside:[self cell]];
				[self setOutlet];
			}
		}

	}
#ifdef USESVG
	[NSImageRep unregisterImageRepClass:[ASWebImageRep class]];
#endif
}

- (NSArray *)imageReps {
	return [[self cell] valueForKey:ASImageViewImageRepsKey];
}
- (NSImageRep *)imageRep {
	return [[[self cell] valueForKey:ASImageViewImageRepsKey] objectAtIndex:(NSUInteger)[[[self cell] valueForKey:ASImageViewCurrentPageKey] integerValue]];
}

- (void)setImageReps:(NSArray *)anArray
{
	[currentURL release];
	currentURL = nil;
	[imageData release];
	imageData = nil;
	if (nil != anArray) {
		[[self cell] setImageWithArray:anArray];
	}
	else {
		[[self cell] setImageWithArray:nil];
	}
	[self updateCellInside:[self cell]];
	[self setOutlet];
}
- (void)setImageRep:(NSImageRep *)aRep
{
	[currentURL release];
	currentURL = nil;
	[imageData release];
	imageData = nil;
	if (nil != aRep)
		[[self cell] setImageRep:aRep];
	else
		[[self cell] setImageWithArray:nil];
	[self updateCellInside:[self cell]];
	[self setOutlet];
}
- (void)setImage:(NSImage *)image
// imageがnilのときはイメージをクリアする。 //
{
	[currentURL release];
	currentURL = nil;
	[imageData release];
	imageData = nil;
	if (nil != image)
		[[self cell] setImage:image];
	else
		[[self cell] setImageWithArray:nil];
	[self updateCellInside:[self cell]];
	[self setOutlet];
}
- (NSImage *)image { // 元のサイズのNSImageを返す。 //
	return [[self cell] image];
}

- (BOOL)openURLFor:(NSURL *)url
//　urlにnilを指定すると画面をクリアする。エラーが起きたときの戻り値とイメージの設定が分かりにくいが、これを利用している物がたくさんあるので変更できない。 　//
{
	BOOL returnValue;

	if (nil == url) {
		[currentURL release];
		[imageData release];
		currentURL = nil;
		imageData = nil;
		[[self cell] setImageWithArray:nil];
		[self updateCellInside:[self cell]];
		[self setOutlet];
		returnValue = YES;
	}
	else {
		if (YES == [url isFileURL]) {
			NSError *err = nil;
			NSString *utiType = [[NSWorkspace sharedWorkspace] typeOfFile:[url path] error:&err];
#ifdef USESVG
			[NSImageRep registerImageRepClass:[ASWebImageRep class]];
#endif
			Class imageRepClass = (nil != utiType) ? [NSImageRep imageRepClassForType:utiType] : nil;
			NSArray *tempReps = (nil != imageRepClass) ? [imageRepClass imageRepsWithContentsOfURL:url] : nil; // 拡張子がjpegのとき、nilになってしまう。imageRepsWithPasteboard:やimageRepWithData:でやってもnilになってしまう。 //
			
			if ((nil != tempReps) && (0 < [tempReps count])) {
				[currentURL release];
				currentURL = [url retain];
				[imageData release];
				currentURL = [[NSURL allocWithZone:[self zone]] initWithString:[url absoluteString]];
				imageData = (YES == dataRetained) ? [[NSData alloc] initWithContentsOfURL:url] : nil;
				[[self cell] setImageWithArray:tempReps];
				[self updateCellInside:[self cell]];
				[self setOutlet];
				returnValue = YES;
			}
			else
				returnValue = NO;
#ifdef USESVG
			[NSImageRep unregisterImageRepClass:[ASWebImageRep class]];
#endif
		}
		else {
			NSData *uData = [NSData dataWithContentsOfURL:url];
			if (nil != uData)
				return [self setImageWithData:uData url:url];
			else
				returnValue = NO;
		}
	}
	return returnValue;
}
- (BOOL)openFileFor:(NSString *)filename
//　filenameにnilか空文字を指定すると画面をクリアする。エラーが起きたときの戻り値とイメージの設定が分かりにくいが、これを利用している物がたくさんあるので変更できない。 　//
{
	BOOL returnValue;

	if ((nil == filename) || (YES == [filename isEqualToString:@""])) {
		[currentURL release];
		currentURL = nil;
		[imageData release];
		imageData = nil;
		[[self cell] setImageWithArray:nil];
		[self updateCellInside:[self cell]];
		[self setOutlet];
		returnValue = YES;
	}
	else {
		NSString *fullpath;

		if (NO == [[filename stringByExpandingTildeInPath] hasPrefix:@"/"])
			fullpath = [[[NSFileManager defaultManager] currentDirectoryPath] stringByAppendingPathComponent:[filename stringByExpandingTildeInPath]];
		else
			fullpath = [filename stringByExpandingTildeInPath];
		if (YES == [[NSFileManager defaultManager] fileExistsAtPath:fullpath])
			return [self openURLFor:[NSURL fileURLWithPath:fullpath]];
		else // 何も変更しない。元の画像のまま。 //
			returnValue = NO;
	}
	return returnValue;
}

- (BOOL)setImageWithData:(NSData *)aData ofType:(NSString *)type
// imageRepsWithData:を直接呼び出す方法が推奨されていないようであるが、強引にやらせる。aDataにnilを指定すると画面クリアする。typeはUTIまたはpasteboard type //
{
	if (nil != aData) {
		NSArray *tempReps;
		Class imageRepClass;
#ifdef USESVG
		[NSImageRep registerImageRepClass:[ASWebImageRep class]];
#endif
		if (YES == [[NSImage imageUnfilteredPasteboardTypes] containsObject:type]) {
			if (nil != (imageRepClass = [NSImageRep imageRepClassForPasteboardType:type])) {
				if (YES == [imageRepClass respondsToSelector:@selector(imageRepsWithData:)])
					tempReps = [imageRepClass imageRepsWithData:aData];
				else {
					if (YES == [imageRepClass respondsToSelector:@selector(imageRepWithData:)])
						tempReps = [NSArray arrayWithObject:[imageRepClass imageRepWithData:aData]];
					else
						tempReps = nil;
				}
			}
			else
				tempReps = nil;
		}
		else {
			if (YES == [[NSImage imagePasteboardTypes] containsObject:type]) { // フィルタプログラムはこのクライアントが属するワークスペースに依って決定されるので要注意 //
				NSPasteboard *pboard = [NSPasteboard pasteboardByFilteringData:aData ofType:type]; // [pasteboardByFilteringData: ofType:NSCreateFileContentsPboardType()]のPasteboardのtypesは、サポートしているフィルターがあるときは、"NXTypedFileContentsPboardType:"+拡張子と"NeXT TIFF v4.0 pasteboard type"の?個の文字列になる。 //
				NSArray *typesArray = [pboard types];

				if (0 < [typesArray count]) {
					tempReps = [NSImageRep imageRepsWithPasteboard:pboard]; // [[NSImage allocWithZone:[self zone]] initWithPasteboard:pboard]によって、フィルタープログラムに起動がかかる。 //
				}
				else {
					// [pboard types]の戻り値が空のときは、サポートしているフィルターが見つからないときである。 //
					// このとき、pboardからreadFileContentsType:をしてもデータが空なのでファイルが作られない。 //
					const char *template = [[NSTemporaryDirectory() stringByAppendingPathComponent:@"filteredImageXXXXXX"] UTF8String];
					NSURL *tempFileURL = [NSURL fileURLWithPath:[[NSString stringWithUTF8String:mktemp((char *)template)] stringByAppendingPathExtension:@"temp"]]; // この場合はほとんど駄目になると思う。 //
					NSError *err = nil;

					[aData writeToURL:tempFileURL atomically:YES];
					tempReps = [NSImageRep imageRepsWithContentsOfURL:tempFileURL];
					[[NSFileManager defaultManager] removeItemAtURL:tempFileURL error:&err];
				}
			}
			else {
				if (nil != (imageRepClass = [NSImageRep imageRepClassForType:type])) {
					if (YES == [imageRepClass respondsToSelector:@selector(imageRepsWithData:)])
						tempReps = [imageRepClass imageRepsWithData:aData];
					else {
						if (YES == [imageRepClass respondsToSelector:@selector(imageRepWithData:)])
							tempReps = [NSArray arrayWithObject:[imageRepClass imageRepWithData:aData]];
						else
							tempReps = nil;
					}
				}
				else
					tempReps = nil;
			}
		}
#ifdef USESVG
		[NSImageRep unregisterImageRepClass:[ASWebImageRep class]];
#endif
		if ((nil != tempReps) && (0 < [tempReps count])) {
			[currentURL release];
			[imageData release];
			currentURL = nil;
			imageData = (YES == dataRetained) ? [[NSData alloc] initWithData:aData] : nil;
			[[self cell] setImageWithArray:tempReps];
			[self updateCellInside:[self cell]];
			[self setOutlet];
			return YES;
		}
		else
			return NO;
	}
	else {
		[currentURL release];
		[imageData release];
		currentURL = nil;
		imageData = nil;
		[[self cell] setImageWithArray:nil];
		[self updateCellInside:[self cell]];
		[self setOutlet];
		return YES;
	}
}
- (BOOL)setImageWithData:(NSData *)aData url:(NSURL *)url
{
	if (nil != aData) {
		NSArray *tempReps;
		Class imageRepClass;
		NSError *err = nil;
		NSString *utiType = (YES == [url isFileURL]) ? [[NSWorkspace sharedWorkspace] typeOfFile:[url path] error:&err] : nil;
#ifdef USESVG
		[NSImageRep registerImageRepClass:[ASWebImageRep class]];
#endif
        NSMutableArray *imageTypes = (0 < [[NSImageRep imageTypes] count]) ? [NSMutableArray arrayWithArray:[NSImageRep imageTypes]] : [NSMutableArray arrayWithArray:[NSImage imageTypes]]; // Xcode 4.0 では[NSImageRep imageTypes]がnilではないがcountが0になってしまう。[NSImage imageTypes]にはsvgも含まれているようだ。 //
		NSArray *raw_imageTypes = [NSArray arrayWithObjects:@"com.phaseone.raw-image", nil];
		[imageTypes addObjectsFromArray:raw_imageTypes];
		if ((nil != utiType) && (YES == [imageTypes containsObject:utiType])) {
			if (nil != (imageRepClass = [NSImageRep imageRepClassForType:utiType])) {
				if (YES == [imageRepClass respondsToSelector:@selector(imageRepsWithContentsOfURL:)])
					tempReps = [imageRepClass imageRepsWithContentsOfURL:url];
				else {
					if (YES == [imageRepClass respondsToSelector:@selector(imageRepWithContentsOfURL:)])
						tempReps = [imageRepClass imageRepWithContentsOfURL:url];
					else {
						if (YES == [imageRepClass respondsToSelector:@selector(imageRepsWithData:)])
							tempReps = [imageRepClass imageRepsWithData:aData];
						else {
							if (YES == [imageRepClass respondsToSelector:@selector(imageRepWithData:)])
								tempReps = [NSArray arrayWithObject:[imageRepClass imageRepWithData:aData]];
							else
								tempReps = nil;
						}
					}
				}
			}
			else
				tempReps = nil;
		}
		else {
			if ((nil != url) && (YES == [[NSImage imageFileTypes] containsObject:[[url path] pathExtension]])) { // フィルタプログラムはこのクライアントが属するワークスペースに依って決定されるので要注意 //
				NSString *typeString = NSCreateFileContentsPboardType([[url path] pathExtension]);
				NSPasteboard *pboard = [NSPasteboard pasteboardByFilteringData:aData ofType:typeString]; // [pasteboardByFilteringData: ofType:NSCreateFileContentsPboardType()]のPasteboardのtypesは、サポートしているフィルターがあるときは、"NXTypedFileContentsPboardType:"+拡張子と"NeXT TIFF v4.0 pasteboard type"の?個の文字列になる。 //
				NSArray *typesArray = [pboard types];

                if (1 < [typesArray count]) {
					tempReps = [NSImageRep imageRepsWithPasteboard:pboard]; // [[NSImage allocWithZone:[self zone]] initWithPasteboard:pboard]によって、フィルタープログラムに起動がかかる。 //
				}
				else {
					// [pboard types]の戻り値が空のときは、サポートしているフィルターが見つからないときである。 //
					// このとき、pboardからreadFileContentsType:をしてもデータが空なのでファイルが作られない。 //
					const char *template = [[NSTemporaryDirectory() stringByAppendingPathComponent:@"filteredImageXXXXXX"] UTF8String];
					NSURL *tempFileURL = [NSURL fileURLWithPath:[[NSString stringWithUTF8String:mktemp((char *)template)] stringByAppendingPathExtension:[[url path] pathExtension]]];
					NSError *err = nil;

					[aData writeToURL:tempFileURL atomically:YES];
					tempReps = [NSImageRep imageRepsWithContentsOfURL:tempFileURL];
					[[NSFileManager defaultManager] removeItemAtURL:tempFileURL error:&err];
				}
			}
			else {
				if ((nil != utiType) && (nil != (imageRepClass = [NSImageRep imageRepClassForType:utiType]))) {
					if (YES == [imageRepClass respondsToSelector:@selector(imageRepsWithData:)])
						tempReps = [imageRepClass imageRepsWithData:aData];
					else {
						if (YES == [imageRepClass respondsToSelector:@selector(imageRepWithData:)])
							tempReps = [NSArray arrayWithObject:[imageRepClass imageRepWithData:aData]];
						else
							tempReps = nil;
					}
				}
				else
					tempReps = nil;
 			}
		}
#ifdef USESVG
		[NSImageRep unregisterImageRepClass:[ASWebImageRep class]];
#endif
		if (nil != tempReps) {
			[currentURL release];
			[imageData release];
			// initFileURLWithPath:とinitWithString:とでは結果が異なる。fileURLWithPathだとfile:://アプリケーションのパスが先頭に付加される。 //
			// currentURL = [[NSURL allocWithZone:[self zone]] initFileURLWithPath:[url absoluteString]]; //
			currentURL = [[NSURL allocWithZone:[self zone]] initWithString:[url absoluteString]];
			// NSLog(@"%@ result=%@",[url absoluteString],[currentURL absoluteString]); //
			imageData = (YES == dataRetained) ? [[NSData alloc] initWithData:aData] : nil;
			[[self cell] setImageWithArray:tempReps];
			[self updateCellInside:[self cell]];
			[self setOutlet];
			return YES;
		}
		else // 何も変更しない。元の画像のまま。 //
			return NO;
	}
	else {
		[currentURL release];
		[imageData release];
		currentURL = nil;
		imageData = nil;
		[[self cell] setImageWithArray:nil];
		[self updateCellInside:[self cell]];
		[self setOutlet];
		return YES;
	}
}
- (BOOL)setImageWithData:(NSData *)aData file:(NSString *)fullpath
// fullpathはリモートマシンのファイルシステム上のパスを指すこともある //
{
	return [self setImageWithData:aData url:[NSURL fileURLWithPath:fullpath]];
}

- (void)setImageFrameStyle:(NSImageFrameStyle)newStyle {
	[[self cell] setValue:[NSNumber numberWithInteger:newStyle] forKey:ASImageViewImageFrameStyleKey];
	[self setOutlet];
}
- (NSImageFrameStyle)imageFrameStyle {
	return [[[self cell] valueForKey:ASImageViewImageFrameStyleKey] integerValue];
}

- (void)setImageScaling:(NSImageScaling)newScaling {
	[[self cell] setValue:[NSNumber numberWithInteger:newScaling] forKey:ASImageViewImageScalingKey];
	[self setOutlet];
}
- (NSImageScaling)imageScaling {
	return [[[self cell] valueForKey:ASImageViewImageScalingKey] integerValue];
}

- (void)setImageAlignment:(NSImageAlignment)newAlign {	
	[[self cell] setValue:[NSNumber numberWithInteger:newAlign] forKey:ASImageViewImageAlignmentKey];
	[self setOutlet];
}
- (NSImageAlignment)imageAlignment {
	return [[[self cell] valueForKey:ASImageViewImageAlignmentKey] integerValue];
}

- (void)setEditable:(BOOL)yn {
	[[self cell] setEditable:yn];
}
- (BOOL)isEditable {
	return [[self cell] isEditable];
}

- (void)setBackgroundColor:(NSColor *)newColor
{
	if (nil != newColor) {
		[[self cell] setValue:newColor forKey:ASImageViewBackgroundColorKey];
		[colorWell setColor:newColor];
	}
	else {
		[[self cell] setValue:[NSNumber numberWithBool:NO] forKey:ASImageViewUseBackgroundColorKey];
		[self setOutlet];
	}
}
- (NSColor *)backgroundColor {
	return [[self cell] valueForKey:ASImageViewBackgroundColorKey];
}
- (void)setUseBackgroundColor:(BOOL)yn
{
	if (nil != [[self cell] valueForKey:ASImageViewBackgroundColorKey]) {
		[[self cell] setValue:[NSNumber numberWithBool:yn] forKey:ASImageViewUseBackgroundColorKey];
		[self setOutlet];
	}
}
- (BOOL)useBackgroundColor {
	return [[[self cell] valueForKey:ASImageViewUseBackgroundColorKey] boolValue];
}

- (void)setCompositingOperation:(NSCompositingOperation)operator {
	[[self cell] setValue:[NSNumber numberWithInteger:operator] forKey:ASImageViewCompositingOperationKey];
	[self setOutlet];
}
- (NSCompositingOperation)compositingOperation {
	return [[[self cell] valueForKey:ASImageViewCompositingOperationKey] integerValue];
}

- (NSSize)originalSize {
	return [[[self cell] valueForKey:@"originalSize"] sizeValue];
}

- (NSInteger)pageCount
{
	NSImageRep *imageRep = [[self cell] imageRep];

	if (nil != imageRep) {
		if (YES == [imageRep isKindOfClass:[NSPDFImageRep class]])
			return [(NSPDFImageRep *)imageRep pageCount];
		else
			return [[[self cell] valueForKey:ASImageViewImageRepsKey] count];
	}
	else
		return 0;
}
- (void)setCurrentPage:(NSInteger)pageNum // zero based. //
{
	NSArray *imageReps = [[self cell] valueForKey:ASImageViewImageRepsKey];
	NSImageRep *imageRep = (nil != imageReps) ? [imageReps objectAtIndex:0] : nil;
	if (nil != imageRep) {
		if (0 > pageNum)
			pageNum = 0;
		if (YES == [imageRep isKindOfClass:[NSPDFImageRep class]]) {
			if ([(NSPDFImageRep *)imageRep pageCount] <= pageNum)
				pageNum = [(NSPDFImageRep *)imageRep pageCount] - 1;
			[(NSPDFImageRep *)imageRep setCurrentPage:pageNum];
		}
		else {
			if ([imageReps count] <= (NSUInteger)pageNum)
				pageNum = (NSInteger)([imageReps count] - 1);
		}
		[[self cell] setValue:[NSNumber numberWithInteger:pageNum] forKey:ASImageViewCurrentPageKey];
		[self setOutlet];
	}
}
- (NSInteger)currentPage {
	return [[[self cell] valueForKey:ASImageViewCurrentPageKey] integerValue];
}

- (void)setFraction:(CGFloat)delta {
	CGFloat newValue = ((0.0 <= delta) && (1.0 >= delta)) ? delta : (0.0 > delta) ? 0.0 : 1.0;
	[[self cell] setValue:[NSNumber numberWithDouble:newValue] forKey:ASImageViewFractionKey];
	[self setOutlet];
}
- (CGFloat)fraction {
	return [[[self cell] valueForKey:ASImageViewFractionKey] floatValue];
}
- (BOOL)canUseFraction {
	return [[[self cell] valueForKey:ASImageViewCanUseFractionKey] boolValue];
}

- (void)setAllowsCutCopyPaste:(BOOL)flag {
	allowsCutCopyPaste = flag;
}
- (BOOL)allowsCutCopyPaste {
	return allowsCutCopyPaste;
}

- (void)setAnimates:(BOOL)flag {
	animates = flag;
}
- (BOOL)animates {
	return animates;
}

- (void)setOutlet
{
	if (nil != colorWell)
		[colorWell setColor:[[self cell] valueForKey:ASImageViewBackgroundColorKey]];
	if (nil != enableState)
		[enableState setEnabled:((nil == [[self cell] valueForKey:ASImageViewImageRepsKey]) && (NSImageFrameNone == [[[self cell] valueForKey:ASImageViewImageFrameStyleKey] integerValue]) && (NO == [[[self cell] valueForKey:ASImageViewUseBackgroundColorKey] boolValue])) ? NO : YES];
	if (nil != filenameViewer)
		[filenameViewer setStringValue:(nil != currentURL) ? [currentURL absoluteString] : @""];
	if (nil != currentURLcontrol) {
		if ((nil != currentURL) && (YES == [currentURL respondsToSelector:@selector(isFileURL)])) {
			if (YES == [currentURL isFileURL])
				[currentURLcontrol setURL:currentURL];
			else
				[currentURLcontrol setURL:currentURL]; // 相対パスのようなとき。ファイルアイコン無しで表示される。 //
		}
		else {
			if ((nil != currentURL) && (YES == [currentURL isKindOfClass:[NSString class]])) {
				[currentURLcontrol setURL:[NSURL fileURLWithPath:(NSString *)currentURL]]; // stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncodingはしなくても良い。currentURLの先頭にfile:が付いていなくても良い。呼び出し側のバグによりcurrentURLがNSStringになってしまったときの対応。currentURLは変更しない。 //
			}
			else
				[currentURLcontrol setURL:nil];
		}
	}
	if (nil != currentPageField) {
		if (1 < [self pageCount]) {
			NSNumberFormatter *positiveIntFormatter = [[NSNumberFormatter alloc] init];
			[positiveIntFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
			[positiveIntFormatter setFormat:@"#,##0;0;-#,##0"];
			[positiveIntFormatter setMinimum:[NSNumber numberWithUnsignedInteger:1]];
			[[currentPageField cell] setFormatter:positiveIntFormatter];
			[positiveIntFormatter release];
			[currentPageField setIntegerValue:[self currentPage] + 1];
			[currentPageField setEnabled:YES];
		}
		else {
			[currentPageField setStringValue:@""];
			[currentPageField setEnabled:NO];
		}
	}
	if (nil != pageCountField) {
		[pageCountField setEditable:NO];
		if (1 < [self pageCount])
			[pageCountField setIntegerValue:[self pageCount]];
		else
			[pageCountField setStringValue:@""];
	}
	if (nil != currentPageControl)
		[currentPageControl setEnabled:(1 < [self pageCount]) ? YES : NO];
	if (nil != currentPageStepper) {
		[currentPageStepper setMaxValue:(double)([self pageCount] - 1)];
		[currentPageStepper setMinValue:0.0];
		[currentPageStepper setDoubleValue:(double)[[[self cell] valueForKey:ASImageViewCurrentPageKey] integerValue]];
		if (1 < [self pageCount])
			[currentPageStepper setEnabled:YES];
		else
			[currentPageStepper setEnabled:NO];
	}
	if (nil != compositingOperationMatrix) {
		[compositingOperationMatrix selectCellWithTag:[[[self cell] valueForKey:ASImageViewCompositingOperationKey] integerValue]];
		[compositingOperationMatrix setEnabled:[[[self cell] valueForKey:ASImageViewCanUseFractionKey] boolValue]];
	}
	if (nil != fractionDevice) {
		[fractionDevice setFloatValue:[[[self cell] valueForKey:ASImageViewFractionKey] floatValue]];
		[fractionDevice setEnabled:[[[self cell] valueForKey:ASImageViewCanUseFractionKey] boolValue]];
	}
	if (nil != imageFlameStyleMatrix)
		[imageFlameStyleMatrix selectCellWithTag:[[[self cell] valueForKey:ASImageViewImageFrameStyleKey] integerValue]];
	if (nil != imageAlignmentMatrix)
		[imageAlignmentMatrix selectCellWithTag:[[[self cell] valueForKey:ASImageViewImageAlignmentKey] integerValue]];
	if (nil != imageScalingMatrix)
		[imageScalingMatrix selectCellWithTag:[[[self cell] valueForKey:ASImageViewImageScalingKey] integerValue]];
	if ((nil != infoState) || (nil != infoTextView)) {
		id obj;
		NSMutableString *textViewString = [NSMutableString string];
		NSDictionary *pDic = [[self cell] generalProperties];
		NSDateFormatter *dateTimeFormatter = [[NSDateFormatter allocWithZone:[self zone]] init];
		[dateTimeFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
		[dateTimeFormatter setCalendar:[NSCalendar autoupdatingCurrentCalendar]];
		[dateTimeFormatter setDateStyle:NSDateFormatterFullStyle];
		[dateTimeFormatter setTimeStyle:NSDateFormatterFullStyle];
		for (NSString *key in pDic) {
			obj = [pDic objectForKey:key];
			[textViewString appendFormat:@"%@ : ",key];
			if (YES == [obj isKindOfClass:[NSArray class]]) {
				[textViewString appendString:@"{"];
				for (NSString *infoString in obj)
					[textViewString appendFormat:@" %@,",infoString];
				[textViewString appendString:@"}\n"];
			}
			else {
				if (YES == [obj isKindOfClass:[NSString class]])
					[textViewString appendFormat:@"%@\n",obj];
				else {
					if (YES == [obj isKindOfClass:[NSNumber class]])
						[textViewString appendFormat:@"%@\n",[obj stringValue]];
					else {
						if (YES == [obj isKindOfClass:[NSDate class]])
							[textViewString appendFormat:@"%@\n",[dateTimeFormatter stringFromDate:obj]];
						else
							[textViewString appendFormat:@"class=%@[%@]\n",NSStringFromClass([obj class]),obj];
					}
				}
			}
		}
		NSDictionary *metadata = nil;
		NSArray *keys = nil;		
		if ((nil != currentURL) && (YES == [currentURL isFileURL])) {
			if (nil != (metadata = [[self cell] metadataFromSource:currentURL]))
				keys = [NSArray arrayWithObjects:(NSString *)kCGImagePropertyTIFFDictionary,(NSString *)kCGImagePropertyGIFDictionary,(NSString *)kCGImagePropertyJFIFDictionary,(NSString *)kCGImagePropertyExifDictionary,(NSString *)kCGImagePropertyPNGDictionary,(NSString *)kCGImagePropertyIPTCDictionary,(NSString *)kCGImagePropertyGPSDictionary,(NSString *)kCGImagePropertyRawDictionary,(NSString *)kCGImagePropertyCIFFDictionary,(NSString *)kCGImageProperty8BIMDictionary,(NSString *)kCGImagePropertyDNGDictionary,(NSString *)kCGImagePropertyExifAuxDictionary,(NSString *)kCGImagePropertyMakerCanonDictionary,(NSString *)kCGImagePropertyMakerNikonDictionary,(NSString *)kCGImagePropertyMakerMinoltaDictionary,(NSString *)kCGImagePropertyMakerFujiDictionary,(NSString *)kCGImagePropertyMakerOlympusDictionary,(NSString *)kCGImagePropertyMakerPentaxDictionary, nil]; // NSImageEXIFDataとkCGImagePropertyExifDictionaryとは同じ内容のNSDictionary。iPhoto.appから「書き出し...」をすると30個くらいになる。iPhotoの場合はオリジナル写真(ライブラリ内の写真)には位置情報が付加されないし、書き出す場合もオリジナル写真に位置情報を付加するのではなく、再度JPEG圧縮して位置情報を付加するので画質の劣化が起きます。 //
		}
		// else 画像が空っぽのとき //
		if ((nil != metadata) && (nil != keys)) {
			NSDictionary *properties;
			for (NSString *key in keys) {
				properties = [[self cell] CGImagePropertyInMetadata:metadata key:key];
				if (nil != properties) {
					if (nil != infoTextView) {
						NSMutableString *infoStr = [NSMutableString string];
						if (0 < [properties count])
							[infoStr appendFormat:@"%@\n",key];
						for (NSString *pKey in properties) {
							obj = [properties objectForKey:pKey];
							[infoStr appendFormat:@"%@ : ",pKey];
							if (YES == [obj isKindOfClass:[NSArray class]]) {
								[infoStr appendString:@"{"];
								for (NSString *infoString in obj)
									[infoStr appendFormat:@" %@,",infoString];
								[infoStr appendString:@"}\n"];
							}
							else { // NSDate は無いようだ。 //
								if (YES == [obj isKindOfClass:[NSString class]])
									[infoStr appendFormat:@"%@\n",obj];
								else {
									if (YES == [obj isKindOfClass:[NSNumber class]]) {
										[infoStr appendFormat:@"%@\n",[obj stringValue]];
									}
									else {
										if (YES == [obj isKindOfClass:[NSDate class]])
											[infoStr appendFormat:@"%@\n",[dateTimeFormatter stringFromDate:obj]];
										else
											[infoStr appendFormat:@"class=%@[%@]\n",NSStringFromClass([obj class]),obj];
									}
								}
							}
						}
						[textViewString appendString:infoStr];
					}
				}
			}
		}
		[infoTextView setString:textViewString];
		if (YES == [textViewString isEqualToString:@""]) {
			if (nil != infoState)
				[infoState setEnabled:NO];
		}
		else {
			if (nil != infoState)
				[infoState setEnabled:YES];
		}
		[dateTimeFormatter release];
	}
}

- (IBAction)openFile:(id)sender
{
	NSOpenPanel *oPanel = [NSOpenPanel openPanel];
	NSURL *tempURL = [[NSUserDefaults standardUserDefaults] URLForKey:ASImageViewDefaultFileURL];
	NSError *err = nil;
	NSURL *tempDirectory = ((nil != tempURL) && (YES == [tempURL isFileURL])) ? [NSURL fileURLWithPath:[[tempURL path] stringByDeletingLastPathComponent]] : nil;
	NSURL *defaultDirectory = ((nil != tempDirectory) && (YES == [tempDirectory checkResourceIsReachableAndReturnError:&err])) ? tempDirectory : nil;
	NSString *defaultName = ((nil != tempURL) && (YES == [tempURL isFileURL])) ? [tempURL lastPathComponent] : @"";
	
	[oPanel setDirectoryURL:defaultDirectory];
	[oPanel setNameFieldStringValue:defaultName];
	[oPanel setCanChooseDirectories:NO];
	[oPanel setAllowsMultipleSelection:NO];
	// [[NSArray alloc] initWithObjects:(NSString *)kUTTypeImage,(NSString *)kUTTypePDF,@"com.adobe.postscript",ASSVGDocumentTypeName, nil]
	[oPanel setAllowedFileTypes:allowedFileTypes];
	[oPanel setTreatsFilePackagesAsDirectories:treatsFilePackageAsDirectories];
	[oPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result)
	 {
		 if (NSFileHandlingPanelOKButton == result) {
			 NSURL *url = [[oPanel URLs] lastObject];
			 if (YES == [self openURLFor:url]) {
				 [[NSNotificationCenter defaultCenter] postNotificationName:ASImageViewDidOpenNotification object:self]; 
				 [[NSUserDefaults standardUserDefaults] setURL:url forKey:ASImageViewDefaultFileURL];
			 }
		 }
	 }
	 ];
}

- (IBAction)eraseInside:(id)sender {
	[self openURLFor:nil];
}

- (IBAction)takeEditableFlagFrom:(id)sender
{
	if (YES == [sender respondsToSelector:@selector(state)])
		[[self cell] setEditable:(0 == [sender state]) ? NO : YES];
	else {
		if (YES == [sender respondsToSelector:@selector(selectedTag)]) {
			if (-1 != [sender selectedTag])
				[[self cell] setEditable:(0 == [sender selectedTag]) ? NO : YES];
		}
		else {
			if (YES == [sender respondsToSelector:@selector(tag)])
				[[self cell] setEditable:(0 == [sender tag]) ? NO : YES];
		}
	}
}
- (IBAction)takeBackgroundColorFrom:(id)sender
{
	[[self cell] setValue:[sender color] forKey:ASImageViewBackgroundColorKey];
	[self updateCell:[self cell]];
}
- (IBAction)takeBackgroundFlagFrom:(id)sender
{
	BOOL changeFlag = NO;

	if (nil != [[self cell] valueForKey:ASImageViewBackgroundColorKey]) {
		if (YES == [sender respondsToSelector:@selector(state)]) {
			[[self cell] setValue:[NSNumber numberWithBool:(0 == [sender state]) ? NO : YES] forKey:ASImageViewUseBackgroundColorKey];
			changeFlag = YES;
		}
		else {
			if (YES == [sender respondsToSelector:@selector(selectedTag)]) {
				if (-1 != [sender selectedTag]) {
					[[self cell] setValue:[NSNumber numberWithBool:(0 == [sender selectedTag]) ? NO : YES] forKey:ASImageViewUseBackgroundColorKey];
					changeFlag = YES;
				}
			}
			else {
				if (YES == [sender respondsToSelector:@selector(tag)]) {
					[[self cell] setValue:[NSNumber numberWithBool:(0 == [sender tag]) ? NO : YES] forKey:ASImageViewUseBackgroundColorKey];
					changeFlag = YES;
				}
			}
		}
	}
	if (YES == changeFlag)
		[self updateCell:[self cell]];
}

- (IBAction)takeFractionValueFrom:(id)sender
{
	CGFloat delta = [sender floatValue];
	CGFloat newValue = ((0.0 <= delta) && (1.0 >= delta)) ? delta : (0.0 > delta) ? 0.0 : 1.0;
	[[self cell] setValue:[NSNumber numberWithDouble:newValue] forKey:ASImageViewFractionKey];
	[self updateCellInside:[self cell]];
}
- (IBAction)takeCompositingOperationFrom:(id)sender
{
	BOOL changeFlag = NO;

	if (YES == [sender respondsToSelector:@selector(selectedTag)]) {
		[[self cell] setValue:[NSNumber numberWithInteger:[sender selectedTag]] forKey:ASImageViewCompositingOperationKey];
		changeFlag = YES;
	}
	else {
		if (YES == [sender respondsToSelector:@selector(tag)]) {
			[[self cell] setValue:[NSNumber numberWithInteger:[sender tag]] forKey:ASImageViewCompositingOperationKey];
			changeFlag = YES;
		}
	}
	if (YES == changeFlag)
		[self updateCellInside:[self cell]];
}
- (IBAction)takeImageAlignmentFrom:(id)sender
{
	BOOL changeFlag = NO;

	if (YES == [sender respondsToSelector:@selector(selectedTag)]) {
		[[self cell] setValue:[NSNumber numberWithInteger:[sender selectedTag]] forKey:ASImageViewImageAlignmentKey];
		changeFlag = YES;
	}
	else {
		if (YES == [sender respondsToSelector:@selector(tag)]) {
			[[self cell] setValue:[NSNumber numberWithInteger:[sender tag]] forKey:ASImageViewImageAlignmentKey];
			changeFlag = YES;
		}
	}
	if (YES == changeFlag)
		[self updateCellInside:[self cell]];
}
- (IBAction)takeImageFrameStyleFrom:(id)sender
{
	BOOL changeFlag = NO;

	if (YES == [sender respondsToSelector:@selector(selectedTag)]) {
		[[self cell] setValue:[NSNumber numberWithInteger:[sender selectedTag]] forKey:ASImageViewImageFrameStyleKey];
		changeFlag = YES;
	}
	else {
		if (YES == [sender respondsToSelector:@selector(tag)]) {
			[[self cell] setValue:[NSNumber numberWithInteger:[sender tag]] forKey:ASImageViewImageFrameStyleKey];
			changeFlag = YES;
		}
	}
	if (YES == changeFlag)
		[self updateCell:[self cell]];
}
- (IBAction)takeImageScalingFrom:(id)sender
{
	BOOL changeFlag = NO;

	if (YES == [sender respondsToSelector:@selector(selectedTag)]) {
		[[self cell] setValue:[NSNumber numberWithInteger:[sender selectedTag]] forKey:ASImageViewImageScalingKey];
		changeFlag = YES;
	}
	else {
		if (YES == [sender respondsToSelector:@selector(tag)]) {
			[[self cell] setValue:[NSNumber numberWithInteger:[sender tag]] forKey:ASImageViewImageScalingKey];
			changeFlag = YES;
		}
	}
	if (YES == changeFlag)
		[self updateCellInside:[self cell]];
}
- (IBAction)takeAllowsCutCopyPasteFrom:(id)sender
{
	if (YES == [sender respondsToSelector:@selector(state)])
		allowsCutCopyPaste = (0 == [sender state]) ? NO : YES;
	else {
		if (YES == [sender respondsToSelector:@selector(selectedTag)]) {
			if (-1 != [sender selectedTag])
				allowsCutCopyPaste = (0 == [sender selectedTag]) ? NO : YES;
		}
		else {
			if (YES == [sender respondsToSelector:@selector(tag)])
				allowsCutCopyPaste = (0 == [sender tag]) ? NO : YES;
		}
	}
}
- (IBAction)takeAnimatesFrom:(id)sender
{
	if (YES == [sender respondsToSelector:@selector(state)])
		animates = (0 == [sender state]) ? NO : YES;
	else {
		if (YES == [sender respondsToSelector:@selector(selectedTag)]) {
			if (-1 != [sender selectedTag])
				animates = (0 == [sender selectedTag]) ? NO : YES;
		}
		else {
			if (YES == [sender respondsToSelector:@selector(tag)])
				animates = (0 == [sender tag]) ? NO : YES;
		}
	}
}

- (IBAction)takeCurrentPageFrom:(id)sender
{
	NSImageRep *imageRep = [[self cell] imageRep];
	if (nil != imageRep) {
		NSInteger p = (YES == [sender respondsToSelector:@selector(increment)]) ? (NSInteger)[sender doubleValue] + 1 : [sender integerValue];

		if (0 >= p)
			p = 1;
		else {
			if (YES == [imageRep isKindOfClass:[NSPDFImageRep class]]) {
				if ([(NSPDFImageRep *)imageRep pageCount] < (NSUInteger)p)
					p = [(NSPDFImageRep *)imageRep pageCount];
			}
			else {
				if ([[[self cell] valueForKey:ASImageViewImageRepsKey] count] < (NSUInteger)p)
					p = (NSInteger)[[[self cell] valueForKey:ASImageViewImageRepsKey] count];
			}
		}
		[sender setIntegerValue:p];
		NSInteger currentPage = p - 1;
		[[self cell] setValue:[NSNumber numberWithInteger:currentPage] forKey:ASImageViewCurrentPageKey];
		[self updateCellInside:[self cell]];
	}
	else
		[[self cell] setValue:[NSNumber numberWithInteger:0] forKey:ASImageViewCurrentPageKey];
}
- (IBAction)pageUp:(id)sender
{
	NSImageRep *imageRep = [[self cell] imageRep];
	if (nil != imageRep) {
		NSInteger p;
	 	if (YES == [imageRep isKindOfClass:[NSPDFImageRep class]])
			p = [(NSPDFImageRep *)imageRep currentPage] + 1;
		else
			p = [[[self cell] valueForKey:ASImageViewCurrentPageKey] integerValue] + 1; // 1 based. //
		if (nil != currentPageField) {
			[currentPageField setIntegerValue:--p]; // decrement //
			[self takeCurrentPageFrom:currentPageField];
		}
		else {
			[self setCurrentPage:p - 2];
			[self updateCellInside:[self cell]];
		}
	}
}
- (IBAction)pageDown:(id)sender
{
	NSImageRep *imageRep = [[self cell] imageRep];
	if (nil != imageRep) {
		NSInteger p;

		if (YES == [imageRep isKindOfClass:[NSPDFImageRep class]])
			p = [(NSPDFImageRep *)imageRep currentPage] + 1;
		else
			p = [[[self cell] valueForKey:ASImageViewCurrentPageKey] integerValue] + 1; // 1 based. //
		if (nil != currentPageField) {
			[currentPageField setIntegerValue:++p]; // increment //
			[self takeCurrentPageFrom:currentPageField];
		}
		else {
			[self setCurrentPage:p];
			[self updateCellInside:[self cell]];
		}
	}
}

- (IBAction)pageUpOrDown:(id)sender
{
	if (YES == [sender respondsToSelector:@selector(selectedSegment)]) { // NSSegmentedControl //
		if (0 == [sender selectedSegment])
			[self pageUp:sender];
		else
			[self pageDown:sender];
	}
	else {
		if (YES == [sender respondsToSelector:@selector(increment)]) { // NSStepper。doubleValueで判断するのが正当かもしれないが対象が多すぎてしまう。 //
			NSInteger cp = [[[self cell] valueForKey:ASImageViewCurrentPageKey] integerValue];
			NSInteger p = (NSInteger)[sender doubleValue];
			if ((cp - 1 == p) || (cp + 1 == p)) { // 初期化がされていないときもあるので、チェックして合ってなければ、1度何もしないでelse以下を実行して修正する。 //
				if (nil != currentPageField) {
					[currentPageField setIntegerValue:++p];
					[self takeCurrentPageFrom:currentPageField];
				}
				else
					[self takeCurrentPageFrom:sender];
			}
			else
				[sender setDoubleValue:(double)[[[self cell] valueForKey:ASImageViewCurrentPageKey] integerValue]];
		}
	}
}

@end
