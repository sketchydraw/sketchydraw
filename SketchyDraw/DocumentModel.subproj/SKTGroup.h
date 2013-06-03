//
//  SKTGroup.h
//  Sketch
//
//  Created by me on Wed May 16 2001.
//  Copyright (c) 2001 SatoAkira. All rights reserved.
//

#import "SKTGraphic.h"


@interface SKTGroup : SKTGraphic {
	@private
    NSMutableArray *_components;	// the Graphics in the group //
    NSRect _lastRect;	// the last rectangle the group was drawn in //
	double _lastAngle;
}

NSRect groupRotateRect(NSRect bounds,NSRect lastrect,double lastangle,SKTGraphic *component,CGFloat sx,CGFloat sy,double angle);
- (id)initList:(NSArray *)list;
- (id)copyWithZone:(NSZone *)zone;
- (void)setComponents:(NSArray *)newArray;
- (void)setLastRect:(NSRect)newRect;
- (void)setLastAngle:(double)newAngle;
- (NSArray *)components;

@end
