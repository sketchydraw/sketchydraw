//
//  SKTsvg.h
//  Sketch
//
//  Created by me on Sat Aug 04 2001.
//  Copyright (c) 2001 SatoAkira. All rights reserved.
//

#import "SKTImage.h"
#import <ASWebView/ASWebImageRep.h>

@interface SKTsvg : SKTImage {
	@private
	ASWebImageRep *_SVGImageRep;
	NSString *frameName;
}

@end
