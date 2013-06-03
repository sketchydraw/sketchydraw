//
//  SKTpdf.h
//  Sketch
//
//  Created by me on Tue Aug 07 2001.
//  Copyright (c) 2001 SatoAkira. All rights reserved.
//

#import "SKTImage.h"

@interface SKTpdf : SKTImage {
	@private
	NSPDFImageRep *_PDFImageRep;
}

@end
