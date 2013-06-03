//
//  SKTScribble.h
//  Sketch
//
//  Created by me on Sat Apr 28 2001.
//  Copyright (c) 2001 SatoAkira. All rights reserved.
//

#import "SKTGraphic.h"

@interface SKTScribble : SKTGraphic {
    NSMutableArray *_points;	// the points in the scribble //
    NSMutableArray *_createdPoints;	// the points in the scribble //
	NSRect _createdBounds;
    BOOL _isFlippedHorizontally;
    BOOL _isFlippedVertically;
	NSBezierPath *_cachedBezierPath;  // hitTest:isSelected:に使うため //
	BOOL _isCreating;
	BOOL _isEditing;
	BOOL _isPathClosed;
	NSUInteger _selectedPointIndex;
	CGFloat _testUndo;
}

@end

extern NSString *SKTIsPathClosedKey;
