//
//  SKTBezierCurve.h
//  Sketch
//
//  Created by 佐藤 昭 on Sun Oct 06 2002.
//  Copyright (c) 2002 SatoAkira. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "SKTGraphic.h"


@interface SKTBezierCurve : SKTGraphic {
	@private
	NSRect _createdBounds;
	NSMutableArray *_points;
	NSMutableArray *_createdPoints;
	NSPoint _lastControlPoint;
	BOOL _isPathClosed;
	BOOL _isFlippedHorizontally;
	BOOL _isFlippedVertically;
	NSUInteger _selectedPointIndex;
	BOOL _isEditing;
	BOOL _isCreating;
	// 回転移動に対応する為、hitTest:isSelected:に_cachedBezierPathを使えない。何故だか分からないがエラーメッセージは出されない。 //
}

@end
