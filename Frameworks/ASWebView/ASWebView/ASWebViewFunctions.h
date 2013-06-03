//
//  ASWebViewFunctions.h
//  ASWebView
//
//  Created by 佐藤 昭 on 10/12/02.
//  Copyright 2010 SatoAkira. All rights reserved.
//

#import <Foundation/Foundation.h>


NSString *guessEncoding(NSData *data, NSStringEncoding *enc);
NSDictionary *characterSets(void);
double unitToPix(NSString *aString,NSFont *font,CGFloat baseValue);
NSArray *values();
NSDictionary *getSVGRect(NSXMLDocument *xmlDoc);
