//
//  SBSendEmail.m
//  SketchyDraw
//
//  Created by 佐藤 昭 on 2012/10/04.
//
//

#import <CoreServices/CoreServices.h>
#import "SBSendEmail.h"
#import "Mail.h"

@interface SBSendEmail (delegate) <SBApplicationDelegate>
@end

@implementation SBSendEmail

@synthesize messageContent;

+ (id)sharedSBSendEmail
// Sketch流のsharedInstanceは、NSPanelをwindowにすることを前提とした作りになっている。NSWindowをwindowにしてしまうと、KVOのエラーが発生してしまう。SKTInspectorControllerから起きてくるが防ぎようが無いのでNSPanelにするしか無い。 //
{
	static SBSendEmail *sharedInstance = nil;
	if (!sharedInstance)
		sharedInstance = [[SBSendEmail alloc] init];
	return sharedInstance;
}
- (id)initWithWindowNibName:(NSString *)windowNibName owner:(id)owner {
	if (nil != (self = [super initWithWindowNibName:windowNibName owner:owner])) {
		pdfData = nil;
	}
	return self;
}
- (id)initWithWindowNibName:(NSString *)windowNibName {
	return [self initWithWindowNibName:windowNibName owner:self];
}
- (id)init {
	return [self initWithWindowNibName:NSStringFromClass([self class]) owner:self]; // windowNibNameがclass名と同じならばこのinitで良い。 //
}
- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}
- (void)dealloc
{
	[pdfData release];
	[super dealloc];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
	[sendBotton setToolTip:NSLocalizedString(@"Send",@"")];
	[[headerForm cellAtIndex:0] setTitle:NSLocalizedString(@"To",@"")];
	[[headerForm cellAtIndex:0] setEditable:YES];
	[[headerForm cellAtIndex:1] setTitle:NSLocalizedString(@"From",@"")];
	[[headerForm cellAtIndex:1] setEditable:YES];
	[[headerForm cellAtIndex:2] setTitle:NSLocalizedString(@"Subject",@"")];
	[[headerForm cellAtIndex:2] setEditable:YES];
	[[headerForm cellAtIndex:3] setTitle:NSLocalizedString(@"Attachment",@"")];
	[[headerForm cellAtIndex:3] setEditable:NO];
	[headerForm calcSize];
	[messageContent setFieldEditor:NO];
	[messageContent setFont:[NSFont userFontOfSize:13.0]];
	[messageContent setString:NSLocalizedString(@"messageContent", @"")];
	[[headerForm cellAtIndex:0] setStringValue:NSLocalizedString(@"type destination address here",@"")];
	[[headerForm cellAtIndex:1] setStringValue:NSLocalizedString(@"type your address here",@"")];
	[[self window] setTitle:NSLocalizedString(@"Mail PDF",@"")];
}
- (void)setPdfData:(NSData *)aData
// これだけのことで、KVOを使う必要は無い。 //
{
	[pdfData release];
	if (nil != aData) {
		NSImage *image = [[NSImage alloc] initWithData:aData];
		pdfData = [[NSData alloc] initWithData:aData];
		[[headerForm cellAtIndex:3] setStringValue:[NSString stringWithFormat:@"%lu bytes",[pdfData length]]];
		[attachmentView setImage:image];
		[image release];
	}
	else {
		pdfData = nil;
		[[headerForm cellAtIndex:3] setStringValue:@""];
		[attachmentView setImage:nil];
	}
}
// Part of the SBApplicationDelegate protocol.  Called when an error occurs in Scripting Bridge method. //
- (id)eventDidFail:(const AppleEvent *)event withError:(NSError *)error
{
    [[NSAlert alertWithMessageText:@"SBSendEmail Error" defaultButton:@"OK" alternateButton:nil otherButton:nil
         informativeTextWithFormat: @"%@", [error localizedDescription]] runModal];
    return nil;
}

/* - (IBAction)chooseFileAttachment:(id)sender { // 不要 //
	NSOpenPanel *op = [NSOpenPanel openPanel];
	
	// allow directories //
	[op setCanChooseDirectories:YES];
	
	// single file selections //
	[op setAllowsMultipleSelection:NO];
	[op setCanChooseFiles: YES];
    
    [op setAllowedFileTypes:[NSArray arrayWithObjects: @"gif", @"jpg", @"pdf", @"png", @"rtf", @"txt", @"zip", nil]];
	
	// run the open panel //
	NSInteger openResult = [op runModal];
	
	// save the selection, if a file/directory was chosen //
	if ( NSOKButton == openResult ) {
		[self.fileAttachmentField setStringValue: [[op URLs] objectAtIndex:0]];
	}
} */
- (IBAction)sendEmailMessage:(id)sender
{
	MailApplication *mail = [SBApplication applicationWithBundleIdentifier:@"com.apple.mail"]; // create a Scripting Bridge object for talking to the Mail application //
    mail.delegate = self; // set ourself as the delegate to receive any errors //
    if ( [mail lastError] != nil ) // Test for errors //
        return;
	MailOutgoingMessage *emailMessage = [[[mail classForScriptingClass:@"outgoing message"] alloc] initWithProperties:[NSDictionary dictionaryWithObjectsAndKeys:[[headerForm cellAtIndex:2] stringValue], @"subject",[[self.messageContent textStorage] string], @"content", nil]]; // create a new outgoing message object. subjectが空文字の場合はMail.appが警告パネルを出して一時停止する。 //
	[[mail outgoingMessages] addObject: emailMessage]; // add the object to the mail app  //
	emailMessage.sender = [[headerForm cellAtIndex:1] stringValue]; // set the sender, show the message. 空文字の場合はMail.appのデフォルト値になる。Sandboxを有効にした場合、com.apple.security.temporary-exception.apple-events を com.apple.mail していないとdenyされる。 //
	emailMessage.visible = YES;
    if ( [mail lastError] != nil ) { // Test for errors //
		[emailMessage release];
        return;
	}
	MailToRecipient *theRecipient = [[[mail classForScriptingClass:@"to recipient"] alloc] initWithProperties:[NSDictionary dictionaryWithObjectsAndKeys:[[headerForm cellAtIndex:0] stringValue], @"address",nil]];
	[emailMessage.toRecipients addObject: theRecipient]; // create a new recipient and add it to the recipients list. 空の配列の場合はMail.appが警告パネルを出して一時停止する。 //
    [theRecipient release];
    if ( [mail lastError] != nil ) { // Test for errors //
		[emailMessage release];
        return;
	}
	
	// add an attachment, if one was specified //
	/* NSString *attachmentFilePath = [self.fileAttachmentField stringValue];
	if ( [attachmentFilePath length] > 0 ) { */
	if ((nil != pdfData) && (0 < [pdfData length])) {
        MailAttachment *theAttachment;
		NSURL *tempURL = [[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:@"SBSendEmail.pdf"]; // NSDataをMailAttachmentあるいはMailMailAttachmentへ渡す方法が判らないのでtempURLへファイルを作る。。 //
        
		[pdfData writeToURL:tempURL atomically:YES];
		// In Snow Leopard, the fileName property requires an NSString representing the path to the attachment.  In Lion, the property has been changed to require an NSURL.   //
        /* SInt32 osxMinorVersion;
		 Gestalt(gestaltSystemVersionMinor, &osxMinorVersion); */ // Deprecated in OS X v10.8. //
		// create an attachment object //
        /* if ( osxMinorVersion >= 7 ) */
		if (floor(NSAppKitVersionNumber) >= NSAppKitVersionNumber10_7)
			theAttachment = [[[mail classForScriptingClass:@"attachment"] alloc] initWithProperties:[NSDictionary dictionaryWithObjectsAndKeys:tempURL, @"fileName",nil]];
        else
			theAttachment = [[[mail classForScriptingClass:@"attachment"] alloc] initWithProperties:[NSDictionary dictionaryWithObjectsAndKeys:[tempURL path], @"fileName",nil]]; // The string we read from the text field is a URL so we must create an NSURL instance with it and retrieve the old style file path from the NSURL instance. //
		[[emailMessage.content attachments] addObject: theAttachment]; // add it to the list of attachments //
        [theAttachment release];
		if ( [mail lastError] != nil ) { // Test for errors //
			[emailMessage release];
			return;
		}
	}
	else
		NSLog(@"SBSendmail:pdfData nil");
	[emailMessage send]; // send the message //
	[emailMessage release];
}

@end
