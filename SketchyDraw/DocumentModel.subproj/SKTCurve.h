//
//  SKTCurve.h
//  Sketch
//
//  Created by me on Sat Apr 28 2001.
//  Copyright (c) 2001 SatoAkira. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "SKTLine.h"

@interface SKTCurve : SKTLine {
	@private
	NSPoint move; // [self bounds]の中央を原点としたときの回転前の座標系。curvePoints:によって計算される。 //
	NSPoint to;   // [self bounds]の中央を原点としたときの回転前の座標系。curvePoints:によって計算される。 //
	NSPoint control1; // [self bounds]の中央を原点としたときの回転前の座標系。curvePoints:によって計算される。 //
	NSPoint control2; // [self bounds]の中央を原点としたときの回転前の座標系。curvePoints:によって計算される。 //
}

@end
