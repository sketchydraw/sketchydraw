//
//  SKTeps.h
//  Sketch
//
//  Created by 佐藤 昭 on Tue Dec 02 2003.
//  Copyright (c) 2003 SatoAkira. All rights reserved.
//

#import "SKTImage.h"


@interface SKTeps : SKTImage {
	@private
	NSEPSImageRep *_EPSImageRep;
	NSArray *_EPSImageReps;
}

@end
