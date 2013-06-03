//
//  SBSendEmail.h
//  SketchyDraw
//
//  Created by 佐藤 昭 on 2012/10/04.
//
//

#import <Cocoa/Cocoa.h>

@interface SBSendEmail : NSWindowController
{
	IBOutlet NSForm *headerForm;
	IBOutlet NSTextView *messageContent;
	IBOutlet NSButton *sendBotton;
	IBOutlet NSImageView *attachmentView;
	NSData *pdfData;
}

@property(retain, readwrite) NSTextView *messageContent;

+ (id)sharedSBSendEmail;
- (void)setPdfData:(NSData *)aData;
- (IBAction)sendEmailMessage:(id)sender;
/* - (IBAction)chooseFileAttachment:(id)sender; */

@end
