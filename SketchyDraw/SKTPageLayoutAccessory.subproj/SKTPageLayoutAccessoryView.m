//
//  SKTPageLayoutView.m
//  Sketch
//
//  Created by 佐藤 昭 on Fri Jun 13 2003.
//  Copyright (c) 2003 SatoAkira. All rights reserved.
//

#import "SKTPageLayoutAccessoryView.h"
#import "SKTPageLayoutAccessory.h"


@implementation SKTPageLayoutAccessoryView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		paperSize = NSZeroSize;
		leftMargin = rightMargin = topMargin = bottomMargin = 0.0;
    }
    return self;
}

- (void)drawRect:(NSRect)rect {
    // Drawing code here.
	if (NO == NSEqualSizes(NSZeroSize,paperSize)) {
		NSRect bounds = [self bounds];
		CGFloat lineWidth = 1.0;
		CGFloat scaleX = (bounds.size.width - lineWidth) / paperSize.width;
		CGFloat scaleY = (bounds.size.height  - lineWidth) / paperSize.height;
		CGFloat scale = (scaleX > scaleY) ? scaleY : scaleX;
		NSPoint center = NSMakePoint(NSMidX(bounds),NSMidY(bounds));
		NSRect paperRect = NSMakeRect(-0.5 * paperSize.width,-0.5 * paperSize.height,paperSize.width,paperSize.height);
		CGFloat grays[] = {1.0,0.5};
		NSRect rects[] = {paperRect,NSMakeRect(-0.5 * paperSize.width + leftMargin,-0.5 * paperSize.height + bottomMargin,paperSize.width - leftMargin - rightMargin,paperSize.height - bottomMargin - topMargin)};
		NSAffineTransform *transform = [NSAffineTransform transform];
		
		[transform translateXBy:center.x yBy:center.y];
		[transform scaleXBy:scale yBy:scale];
		[transform concat];
		NSRectFillListWithGrays(rects,grays,2); // void NSRectFillListWithGrays (const NSRect *rects,const CGFloat *grays,NSInteger num); //
		[[NSColor blackColor] set];
		NSFrameRectWithWidth(NSInsetRect(paperRect,-0.5 * lineWidth,-0.5 * lineWidth),lineWidth / scale);
	}
}

- (void)setPaperSize:(NSSize)aSize {
	paperSize = aSize;
}
- (void)setLeftMargin:(CGFloat)value {
	leftMargin = value;
}
- (void)setRightMargin:(CGFloat)value {
	rightMargin = value;
}
- (void)setTopMargin:(CGFloat)value {
	topMargin = value;
}
- (void)setBottomMargin:(CGFloat)value {
	bottomMargin = value;
}

@end
