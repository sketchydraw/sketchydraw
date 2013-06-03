//
//  SKTPageLayoutAccessoeyView.h
//  Sketch
//
//  Created by 佐藤 昭 on Fri Jun 13 2003.
//  Copyright (c) 2003 SatoAkira. All rights reserved.
//

#import <AppKit/AppKit.h>


@interface SKTPageLayoutAccessoryView : NSView {
	@private
	NSSize paperSize;
	CGFloat leftMargin;
	CGFloat rightMargin;
	CGFloat topMargin;
	CGFloat bottomMargin;
}

- (void)setPaperSize:(NSSize)aSize;
- (void)setLeftMargin:(CGFloat)value;
- (void)setRightMargin:(CGFloat)value;
- (void)setTopMargin:(CGFloat)value;
- (void)setBottomMargin:(CGFloat)value;

@end
