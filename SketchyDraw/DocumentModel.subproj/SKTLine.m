/*
     File: SKTLine.m
 Abstract: A graphic object to represent a line.
  Version: 1.8
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2012 Apple Inc. All Rights Reserved.
 
*/

#import "SKTLine.h"
#import "SKTFoundationExtras.h" // SatoAkira add. for svg...() //
#import "SKTGraphicView.h" // SatoAkira add. for ISFLIPPED //


// String constants declared in the header. They may not be used by any other class in the project, but it's a good idea to provide and use them, if only to help prevent typos in source code.
NSString *SKTLineBeginPointKey = @"beginPoint";
NSString *SKTLineEndPointKey = @"endPoint";

// SKTGraphic's default selection handle machinery draws more handles than we need, so this class implements its own.
enum {
    SKTLineBeginHandle = 1,
    SKTLineEndHandle = 2
};


@implementation SKTLine


- (id)copyWithZone:(NSZone *)zone {

    // Do the regular Cocoa thing.
    SKTLine *copy = [super copyWithZone:zone];
    copy->_pointsRight = _pointsRight;
    copy->_pointsDown = _pointsDown;
    return copy;

}


#pragma mark *** Private KVC and KVO-Compliance for Public Properties ***


// The only reason we have to have this many methods for simple KVC and KVO compliance for "beginPoint" and "endPoint" is because reusing SKTGraphic's "bounds" property is so complicated (see the instance variable comments in the header). If we just had _beginPoint and _endPoint we wouldn't need any of these methods because KVC's direct instance variable access and KVO's autonotification would just take care of everything for us (though maybe then we'd have to override -setBounds: and -bounds to fulfill the KVC and KVO compliance obligation for "bounds" that this class inherits from its superclass).


+ (NSSet *)keyPathsForValuesAffectingBeginPoint {
    return [NSSet setWithObject:SKTGraphicBoundsKey];
}
- (NSPoint)beginPoint {

    // Convert from our odd storage format to something natural.
    NSPoint beginPoint;
    NSRect bounds = [self bounds];
    beginPoint.x = _pointsRight ? NSMinX(bounds) : NSMaxX(bounds);
    beginPoint.y = _pointsDown ? NSMinY(bounds) : NSMaxY(bounds);
    return beginPoint;

}


+ (NSSet *)keyPathsForValuesAffectingEndPoint {
    return [NSSet setWithObject:SKTGraphicBoundsKey];
}
- (NSPoint)endPoint {
    
    // Convert from our odd storage format to something natural.
    NSPoint endPoint;
    NSRect bounds = [self bounds];
    endPoint.x = _pointsRight ? NSMaxX(bounds) : NSMinX(bounds);
    endPoint.y = _pointsDown ? NSMaxY(bounds) : NSMinY(bounds);
    return endPoint;
    
}


/* + (NSRect)boundsWithBeginPoint:(NSPoint)beginPoint endPoint:(NSPoint)endPoint pointsRight:(BOOL *)outPointsRight down:(BOOL *)outPointsDown {

    // Convert the begin and end points of the line to its bounds and flags specifying the direction in which it points.
    BOOL pointsRight = beginPoint.x<endPoint.x;
    BOOL pointsDown = beginPoint.y<endPoint.y;
    CGFloat xPosition = pointsRight ? beginPoint.x : endPoint.x;
    CGFloat yPosition = pointsDown ? beginPoint.y : endPoint.y;
    CGFloat width = fabs(endPoint.x - beginPoint.x);
    CGFloat height = fabs(endPoint.y - beginPoint.y);
    if (outPointsRight) {
	*outPointsRight = pointsRight;
    }
    if (outPointsDown) {
	*outPointsDown = pointsDown;
    }
    return NSMakeRect(xPosition, yPosition, width, height);
    
} */
+ (NSRect)boundsWithBeginPoint:(NSPoint)beginPoint endPoint:(NSPoint)endPoint pointsRight:(BOOL *)outPointsRight down:(BOOL *)outPointsDown
{
    BOOL pointsRight = beginPoint.x < endPoint.x;
    BOOL pointsDown = beginPoint.y < endPoint.y;
    CGFloat xPosition = pointsRight ? beginPoint.x : endPoint.x;
    CGFloat yPosition = pointsDown ? beginPoint.y : endPoint.y;
    CGFloat width = fabs(endPoint.x - beginPoint.x);
    CGFloat height = fabs(endPoint.y - beginPoint.y);
    if ((BOOL *)NULL != outPointsRight) {
		*outPointsRight = pointsRight;
    }
    if ((BOOL *)NULL != outPointsDown) {
		*outPointsDown = pointsDown;
    }
    return NSMakeRect(xPosition, yPosition, width, height);
}


- (void)setBeginPoint:(NSPoint)beginPoint {
    
    // It's easiest to compute the results of setting these points together.
    [self setBounds:[[self class] boundsWithBeginPoint:beginPoint endPoint:[self endPoint] pointsRight:&_pointsRight down:&_pointsDown]];
    
}


- (void)setEndPoint:(NSPoint)endPoint {
    
    // It's easiest to compute the results of setting these points together.
    [self setBounds:[[self class] boundsWithBeginPoint:[self beginPoint] endPoint:endPoint pointsRight:&_pointsRight down:&_pointsDown]];
	
}


#pragma mark *** Overrides of SKTGraphic Methods ***


NSString *SKTLineStartsAtLowerLeftKey = @"LineStartsAtLowerLeft"; // SatoAkira add. for sktd. //

- (id)initWithProperties:(NSDictionary *)properties {

    // Let SKTGraphic do its job and then handle the additional properties defined by this subclass.
    self = [super initWithProperties:properties];
    if (self) {

	// This object still doesn't have a bounds (because of what we do in our override of -properties), so set one and record the other information we need to place the begin and end points. The dictionary entries are all instances of the classes that can be written in property lists. Don't trust the type of something you get out of a property list unless you know your process created it or it was read from your application or framework's resources. We don't have to worry about KVO-compliance in initializers like this by the way; no one should be observing an unitialized object.
		NSPoint beginPoint,endPoint; // SatoAkira add. //
	Class stringClass = [NSString class];
	NSString *beginPointString = [properties objectForKey:SKTLineBeginPointKey];
		if (nil != beginPointString) { // SatoAkira add. //
	/* NSPoint beginPoint = [beginPointString isKindOfClass:stringClass] ? NSPointFromString(beginPointString) : NSZeroPoint;
	NSString *endPointString = [properties objectForKey:SKTLineEndPointKey];
	NSPoint endPoint = [endPointString isKindOfClass:stringClass] ? NSPointFromString(endPointString) : NSZeroPoint; */ // SatoAkira delete. //
// ↓SatoAkira add. //
			NSString *endPointString = [properties objectForKey:SKTLineEndPointKey];
			beginPoint = [beginPointString isKindOfClass:stringClass] ? NSPointFromString(beginPointString) : NSZeroPoint;
			endPoint = [endPointString isKindOfClass:stringClass] ? NSPointFromString(endPointString) : NSZeroPoint;
		}
		else { // sktdによるドキュメントに対応するため。 //
			NSString *boundsString = [properties objectForKey:SKTGraphicBoundsKey];
			if (nil != boundsString) {
				NSRect bounds = NSRectFromString(boundsString);
				NSString *startsAtLowerLeftStr = (nil != [properties objectForKey:SKTLineStartsAtLowerLeftKey]) ? [properties objectForKey:SKTLineStartsAtLowerLeftKey] : @"NO";
				BOOL startsAtLowerLeft = (YES == [startsAtLowerLeftStr isEqualToString:@"YES"]) ? YES : NO;
				if (YES == startsAtLowerLeft) {
					beginPoint = NSMakePoint(NSMinX(bounds),NSMaxY(bounds));
					endPoint = NSMakePoint(NSMaxX(bounds),NSMinY(bounds));
				}
				else {
					beginPoint = NSMakePoint(NSMinX(bounds),NSMinY(bounds));
					endPoint = NSMakePoint(NSMaxX(bounds),NSMaxY(bounds));
				}
			}
			else {
				beginPoint = NSZeroPoint;
				endPoint = NSZeroPoint;
			}
		}
// ↑SatoAkira add. //
	[self setBounds:[[self class] boundsWithBeginPoint:beginPoint endPoint:endPoint pointsRight:&_pointsRight down:&_pointsDown]];

    }
    return self;

}

- (NSMutableDictionary *)properties {

    // Let SKTGraphic do its job but throw out the bounds entry in the dictionary it returned and add begin and end point entries insteads. We do this instead of simply recording the currnet value of _pointsRight and _pointsDown because bounds+pointsRight+pointsDown is just too unnatural to immortalize in a file format. The dictionary must contain nothing but values that can be written in old-style property lists.
    NSMutableDictionary *properties = [super properties];
    [properties removeObjectForKey:SKTGraphicBoundsKey];
    [properties setObject:NSStringFromPoint([self beginPoint]) forKey:SKTLineBeginPointKey];
    [properties setObject:NSStringFromPoint([self endPoint]) forKey:SKTLineEndPointKey];
    return properties;

}


// We don't bother overriding +[SKTGraphic keyPathsForValuesAffectingDrawingBounds] because we don't need to take advantage of the KVO dependency mechanism enabled by that method. We fulfill our KVO compliance obligations (inherited from SKTGraphic) for SKTGraphicDrawingBoundsKey by just always invoking -setBounds: in -setBeginPoint: and -setEndPoint:. "bounds" is always in the set returned by +[SKTGraphic keyPathsForValuesAffectingDrawingBounds]. Now, there's nothing in SKTGraphic.h that actually guarantees that, so we're taking advantage of "undefined" behavior. If we didn't have the source to SKTGraphic right next to the source for this class it would probably be prudent to override +keyPathsForValuesAffectingDrawingBounds, and make sure.

// We don't bother overriding +[SKTGraphic keyPathsForValuesAffectingDrawingContents] because this class doesn't define any properties that affect drawing without affecting the bounds.


- (BOOL)isDrawingFill {

    // You can't fill a line.
    return NO;

}


- (BOOL)isDrawingStroke {

    // You can't not stroke a line.
    return YES;

}


/* - (NSBezierPath *)bezierPathForDrawing {

    // Simple.
    NSBezierPath *path = [NSBezierPath bezierPath];
    [path moveToPoint:[self beginPoint]];
    [path lineToPoint:[self endPoint]];
    [path setLineWidth:[self strokeWidth]];
    return path;

} */ // SatoAkira delete. //
- (NSBezierPath *)bezierPathForDrawing
// SatoAkira add. //
{
	NSPoint beginPoint = [self beginPoint];
	NSPoint endPoint = [self endPoint];
	NSPoint midPoint = NSMakePoint(0.5 * (beginPoint.x + endPoint.x),0.5 * (beginPoint.y + endPoint.y));
		NSAffineTransform *transform = [NSAffineTransform transform];
		NSBezierPath *path = [NSBezierPath bezierPath];

		[transform translateXBy:midPoint.x yBy:midPoint.y];
		[transform rotateByRadians:[self rotateAngle]];
		[transform concat];
		[path moveToPoint:NSMakePoint(beginPoint.x - midPoint.x,beginPoint.y - midPoint.y)];
		[path lineToPoint:NSMakePoint(endPoint.x - midPoint.x,endPoint.y - midPoint.y)];
		return path;
}

- (double)arrowRadian:(NSInteger)corner
{
	NSRect bounds = [self bounds];
	double radian = atan2(NSHeight(bounds), NSWidth(bounds));
#ifdef ISFLIPPED
	switch (corner) {
	case SKTGraphicUpperLeftHandle:
		radian += M_PI;
		break;
	case SKTGraphicLowerLeftHandle:
		radian = M_PI - radian;
		break;
	case SKTGraphicUpperRightHandle:
		radian = 2.0 * M_PI - radian;
		break;
	default: // SKTGraphicLowerRightHandle //
		break;
	}
#else
	switch (corner) {
	case SKTGraphicLowerLeftHandle:
		radian += M_PI;
		break;
	case SKTGraphicUpperLeftHandle:
		radian = M_PI - radian;
		break;
	case SKTGraphicLowerRightHandle:
		radian = 2.0 * M_PI - radian;
		break;
	default: // SKTGraphicUpperRightHandle //
		break;
	}
#endif
    return radian;	
}
- (float)arrowAngle:(NSInteger)corner
// SatoAkira add. //
// Returns the angle which the arrow should be drawn at. //
{
	NSRect bounds = [self bounds];
	float angle = 180.0 * atan2(NSHeight(bounds), NSWidth(bounds)) * M_1_PI;
#ifdef ISFLIPPED
	switch (corner) {
	case SKTGraphicUpperLeftHandle:
		angle += 180.0;
		break;
	case SKTGraphicLowerLeftHandle:
		angle = 180.0 - angle;
		break;
	case SKTGraphicUpperRightHandle:
		angle = 360.0 - angle;
		break;
	default: // SKTGraphicLowerRightHandle //
		break;
	}
#else
	switch (corner) {
	case SKTGraphicLowerLeftHandle:
		angle += 180.0;
		break;
	case SKTGraphicUpperLeftHandle:
		angle = 180.0 - angle;
		break;
	case SKTGraphicLowerRightHandle:
		angle = 360.0 - angle;
		break;
	default: // SKTGraphicUpperRightHandle //
		break;
	}
#endif
    return angle;
}
- (NSBezierPath *)arrowBezierPath:(BOOL)isAtStart
// SatoAkira add. shadowの状態は継承される。 //
{
    NSBezierPath *path = [NSBezierPath bezierPath];
    NSRect bounds = [self bounds];
    
	if (((NSWidth(bounds) >= 1.0) || (NSHeight(bounds) >= 1.0)) && (SKTArrowNone != [self arrowState])) {
		NSInteger corner;
		NSPoint beginPoint = [self beginPoint];
		NSPoint endPoint = [self endPoint];
		NSPoint midPoint = NSMakePoint(0.5 * (beginPoint.x + endPoint.x),0.5 * (beginPoint.y + endPoint.y));
		[self strokeColorSet];
		[[self convertColorSpace:[self strokeColor]] setFill];
		[path setLineWidth:1.0];
		[path setLineJoinStyle:NSMiterLineJoinStyle];
		[path setLineDash:(CGFloat *)NULL count:0 phase:0.0];
		if (YES == isAtStart) {
			if ((YES == _pointsRight) && (YES == _pointsDown))
				corner = SKTGraphicUpperLeftHandle;
			else {
				if ((YES == _pointsRight) && (NO == _pointsDown))
					corner = SKTGraphicLowerLeftHandle;
				else {
					if ((NO == _pointsRight) && (YES == _pointsDown))
						corner = SKTGraphicUpperRightHandle;
					else
						corner = SKTGraphicLowerRightHandle;
				}
			}
			pdfArrow(nil,beginPoint.x - midPoint.x, beginPoint.y - midPoint.y,[self arrowRadian:corner],[self strokeWidth],[self lineCap]);
		}
		else {
			if ((YES == _pointsRight) && (YES == _pointsDown))
				corner = SKTGraphicLowerRightHandle;
			else {
				if ((YES == _pointsRight) && (NO == _pointsDown))
					corner = SKTGraphicUpperRightHandle;
				else {
					if ((NO == _pointsRight) && (YES == _pointsDown))
						corner = SKTGraphicLowerLeftHandle;
					else
						corner = SKTGraphicUpperLeftHandle;
				}
			}
			pdfArrow(nil,endPoint.x - midPoint.x, endPoint.y - midPoint.y,[self arrowRadian:corner],[self strokeWidth],[self lineCap]);
		}
	}
	return path;
}

/* - (void)drawHandlesInView:(NSView *)view {
    
    // A line only has two handles.
    [self drawHandleInView:view atPoint:[self beginPoint]];
    [self drawHandleInView:view atPoint:[self endPoint]];

} */ // SatoAkira delete. //
- (void)drawHandlesInView:(NSView *)view
// SatoAkira add. //
{
	NSPoint beginPoint = [self beginPoint];
	NSPoint endPoint = [self endPoint];

	[self drawHandleInView:view atPoint:NSMakePoint(0.5 * (beginPoint.x - endPoint.x), 0.5 * (beginPoint.y - endPoint.y))];
	[self drawHandleInView:view atPoint:NSMakePoint(0.5 * (endPoint.x - beginPoint.x), 0.5 * (endPoint.y - beginPoint.y))];
}


+ (NSInteger)creationSizingHandle {

    // When the user creates a line and is dragging around a handle to size it they're dragging the end of the line.
    return SKTLineEndHandle;

}


- (BOOL)canSetDrawingFill {

    // Don't let the user think we can fill a line.
    return NO;

}


- (BOOL)canSetDrawingStroke {

    // Don't let the user think can ever not stroke a line.
    return NO;

}


- (BOOL)canMakeNaturalSize {

    // What would the "natural size" of a line be?
    return NO;

}


/* - (BOOL)isContentsUnderPoint:(NSPoint)point {

    // Do a gross check against the bounds.
    BOOL isContentsUnderPoint = NO;
    if (NSPointInRect(point, [self bounds])) {

	// Let the user click within the stroke width plus some slop.
	CGFloat acceptableDistance = ([self strokeWidth] / 2.0f) + 2.0f;

	// Before doing anything avoid a divide by zero error.
	NSPoint beginPoint = [self beginPoint];
	NSPoint endPoint = [self endPoint];
	CGFloat xDelta = endPoint.x - beginPoint.x;
	if (xDelta==0.0f && fabs(point.x - beginPoint.x)<=acceptableDistance) {
	    isContentsUnderPoint = YES;
	} else {

	    // Do a weak approximation of distance to the line segment.
	    CGFloat slope = (endPoint.y - beginPoint.y) / xDelta;
	    if (fabs(((point.x - beginPoint.x) * slope) - (point.y - beginPoint.y))<=acceptableDistance) {
		isContentsUnderPoint = YES;
	    }

	}

    }
    return isContentsUnderPoint;

} */ // SatoAkira delete. //
#define HIT_TOLERANCE 6.0 // SatoAkira add. //
- (BOOL)isContentsUnderPoint:(NSPoint)point
// SatoAkira add. //
{
    if (NO == [self locked]) {
		NSRect bounds = [self bounds];
		double rotateAngle = [self rotateAngle];
		CGFloat linewidth = [self strokeWidth];
		CGFloat tolerance = HIT_TOLERANCE + linewidth;
		NSRect r = NSMakeRect(-0.5 * NSWidth(bounds),-0.5 * NSHeight(bounds),NSWidth(bounds),NSHeight(bounds));
		NSPoint center = NSMakePoint(NSMidX(bounds),NSMidY(bounds));
		CGFloat x = (point.x - center.x) * cos(rotateAngle) + (point.y - center.y) * sin(rotateAngle);
		CGFloat y = -1.0 * (point.x - center.x) * sin(rotateAngle) + (point.y - center.y) * cos(rotateAngle);
		if (r.size.width < tolerance) {
			r.size.width += tolerance * 2.0;
			r.origin.x -= tolerance;
		}
		if (r.size.height < tolerance) {
			r.size.height += tolerance * 2.0;
			r.origin.y -= tolerance;
		}
#ifdef ISFLIPPED
		if (YES == NSPointInRect(NSMakePoint(x,y), r)) { // isFlipped //
#else
		if (YES == NSMouseInRect(NSMakePoint(x,y),r,NO)) { // NO == isFlipped //
#endif
			NSPoint lowerLeft = NSMakePoint(-0.5 * NSWidth(bounds),0.5 * NSHeight(bounds));
			NSPoint p = NSMakePoint((point.x - center.x) * cos(rotateAngle) + (point.y - center.y) * sin(rotateAngle),-1.0 * (point.x - center.x) * sin(rotateAngle) + (point.y - center.y) * cos(rotateAngle));
			CGFloat dx = p.x - lowerLeft.x;
#ifdef ISFLIPPED
			CGFloat dy = (_pointsDown == _pointsRight) ? lowerLeft.y + p.y : lowerLeft.y - p.y; // isFlipped //
#else
			CGFloat dy = (_pointsDown == _pointsRight) ? lowerLeft.y - p.y : lowerLeft.y + p.y;
#endif
			CGFloat distance = ((0.0 != dx) && (0.0 != NSWidth(bounds))) ? hypot(dx,dy) * sin(fabs(atan(NSHeight(bounds) / NSWidth(bounds)) - atan(dy / dx))) : fabs(p.x - lowerLeft.x);

			return ((distance - tolerance) <= linewidth) ? YES : NO;
		}
		else
			return NO;
	}
	else
		return NO;
}

/* - (NSInteger)handleUnderPoint:(NSPoint)point {

    // A line just has handles at its ends.
    NSInteger handle = SKTGraphicNoHandle;
    if ([self isHandleAtPoint:[self beginPoint] underPoint:point]) {
	handle = SKTLineBeginHandle;
    } else if ([self isHandleAtPoint:[self endPoint] underPoint:point]) {
	handle = SKTLineEndHandle;
    }
    return handle;

} */ // SatoAkira delete. //
- (NSInteger)handleUnderPoint:(NSPoint)point
// SatoAkira add. //
{
	NSPoint beginPoint = [self beginPoint];
	NSPoint endPoint = [self endPoint];
	NSPoint center = NSMakePoint(0.5 * (beginPoint.x + endPoint.x),0.5 * (beginPoint.y + endPoint.y));
	double rotateAngle = [self rotateAngle];
	CGFloat x = (point.x - center.x) * cos(rotateAngle) + (point.y - center.y) * sin(rotateAngle) + center.x;
	CGFloat y = -1.0 * (point.x - center.x) * sin(rotateAngle) + (point.y - center.y) * cos(rotateAngle) + center.y;
	NSInteger handle = SKTGraphicNoHandle;
	if (YES == [self isHandleAtPoint:[self beginPoint] underPoint:NSMakePoint(x,y)])
		handle = SKTLineBeginHandle;
	else {
		if (YES == [self isHandleAtPoint:[self endPoint] underPoint:NSMakePoint(x,y)])
			handle = SKTLineEndHandle;
	}
	return handle;	
}


/* - (NSInteger)resizeByMovingHandle:(NSInteger)handle toPoint:(NSPoint)point {

    // A line just has handles at its ends.
    if (handle==SKTLineBeginHandle) {
	[self setBeginPoint:point];
    } else if (handle==SKTLineEndHandle) {
	[self setEndPoint:point];
    } // else a cataclysm occurred.

    // We don't have to do the kind of handle flipping that SKTGraphic does.
    return handle;

} */ // SatoAkira delete. //
- (NSRect)resizedBoundsWithRotate:(double)angle oldBounds:(NSRect)oldBounds movingHandle:(NSInteger *)handle toPoint:(NSPoint)point
// SatoAkira add. SKTGraphic.m の- (NSInteger)resizeByMovingHandle:(NSInteger)handle toPoint:(NSPoint)point と同じアルゴリズム。[self flipHorizontally],[self flipVertically],[self setBounds:]が無いだけ。 //
{
	CGFloat dw;
	NSRect bounds = oldBounds;
	NSPoint center = NSMakePoint(NSMidX(bounds),NSMidY(bounds));
	NSPoint p = NSMakePoint((point.x - center.x) * cos(angle) + (point.y - center.y) * sin(angle),-1.0 * (point.x - center.x) * sin(angle) + (point.y - center.y) * cos(angle));

	if ((SKTGraphicUpperRightHandle == *handle) || (SKTGraphicMiddleRightHandle == *handle) || (SKTGraphicLowerRightHandle == *handle)) { // Change the left edge of the graphic. //
		dw = p.x - 0.5 * NSWidth(bounds);
		bounds.size.width += dw;
		bounds.origin.x += 0.5 * dw * (cos(angle) - 1.0);
		bounds.origin.y += 0.5 * dw * sin(angle);
	}
	else {
		if ((SKTGraphicUpperLeftHandle == *handle) || (SKTGraphicMiddleLeftHandle == *handle) || (SKTGraphicLowerLeftHandle == *handle)) { // Change the right edge of the graphic. //
			dw = -0.5 * NSWidth(bounds) - p.x;
			bounds.size.width += dw;
			bounds.origin.x -= 0.5 * dw * (cos(angle) + 1.0);
			bounds.origin.y -= 0.5 * dw * sin(angle);
		}
	}
	if (NSWidth(bounds) < 0.0) {
		static NSInteger flippings[9];
		static BOOL flippingsInitialized = NO;
		if (NO == flippingsInitialized) {
			flippings[SKTGraphicUpperLeftHandle] = SKTGraphicUpperRightHandle;
			flippings[SKTGraphicUpperMiddleHandle] = SKTGraphicUpperMiddleHandle;
			flippings[SKTGraphicUpperRightHandle] = SKTGraphicUpperLeftHandle;
			flippings[SKTGraphicMiddleLeftHandle] = SKTGraphicMiddleRightHandle;
			flippings[SKTGraphicMiddleRightHandle] = SKTGraphicMiddleLeftHandle;
			flippings[SKTGraphicLowerLeftHandle] = SKTGraphicLowerRightHandle;
			flippings[SKTGraphicLowerMiddleHandle] = SKTGraphicLowerMiddleHandle;
			flippings[SKTGraphicLowerRightHandle] = SKTGraphicLowerLeftHandle;
			flippingsInitialized = YES;
		}
		*handle = flippings[*handle];
		bounds.origin.x += NSWidth(bounds);
		bounds.size.width *= -1.0;
	}

	if ((SKTGraphicLowerLeftHandle == *handle) || (SKTGraphicLowerMiddleHandle == *handle) || (SKTGraphicLowerRightHandle == *handle)) { // Change the top edge of the graphic. //
		dw = p.y - 0.5 * NSHeight(bounds);
		bounds.size.height += dw;
		bounds.origin.x -= 0.5 * dw * sin(angle);
		bounds.origin.y += 0.5 * dw * (cos(angle) - 1.0);
	}
	else {
		if ((SKTGraphicUpperLeftHandle == *handle) || (SKTGraphicUpperMiddleHandle == *handle) || (SKTGraphicUpperRightHandle == *handle)) { // Change the bottom edge of the graphic. //
			dw = -0.5 * NSHeight(bounds) - p.y;
			bounds.size.height += dw;
			bounds.origin.x += 0.5 * dw * sin(angle);
			bounds.origin.y -= 0.5 * dw * (cos(angle) + 1.0);
		}
	}
	if (NSHeight(bounds) < 0.0) {
		static NSInteger flippings[9];
		static BOOL flippingsInitialized = NO;
		if (NO == flippingsInitialized) {
			flippings[SKTGraphicUpperLeftHandle] = SKTGraphicLowerLeftHandle;
			flippings[SKTGraphicUpperMiddleHandle] = SKTGraphicLowerMiddleHandle;
			flippings[SKTGraphicUpperRightHandle] = SKTGraphicLowerRightHandle;
			flippings[SKTGraphicMiddleLeftHandle] = SKTGraphicMiddleLeftHandle;
			flippings[SKTGraphicMiddleRightHandle] = SKTGraphicMiddleRightHandle;
			flippings[SKTGraphicLowerLeftHandle] = SKTGraphicUpperLeftHandle;
			flippings[SKTGraphicLowerMiddleHandle] = SKTGraphicUpperMiddleHandle;
			flippings[SKTGraphicLowerRightHandle] = SKTGraphicUpperRightHandle;
			flippingsInitialized = YES;
		}
		*handle = flippings[*handle];
		bounds.origin.y += NSHeight(bounds);
		bounds.size.height *= -1.0;
	}
	return bounds;
}
- (NSInteger)resizeByMovingHandle:(NSInteger)handle toPoint:(NSPoint)point
// SatoAkira add. //
{
	NSRect newBounds;
	NSInteger handleForBounds;
	NSPoint newBeginPoint,newEndPoint;
	double angle = [self rotateAngle];
	

	if (SKTLineBeginHandle == handle) {
		if (YES == _pointsDown)
			handleForBounds = (YES == _pointsRight) ? SKTGraphicUpperLeftHandle :SKTGraphicUpperRightHandle;
		else
			handleForBounds = (YES == _pointsRight) ? SKTGraphicLowerLeftHandle : SKTGraphicLowerRightHandle;
	}
	else {
		if (YES == _pointsDown)
			handleForBounds = (YES == _pointsRight) ? SKTGraphicLowerRightHandle :SKTGraphicLowerLeftHandle;
		else
			handleForBounds = (YES == _pointsRight) ? SKTGraphicUpperRightHandle :SKTGraphicUpperLeftHandle;
	}

	newBounds = [self resizedBoundsWithRotate:angle oldBounds:[self bounds] movingHandle:&handleForBounds toPoint:point];
	if (SKTGraphicUpperLeftHandle == handleForBounds) {
		newBeginPoint = NSMakePoint(NSMinX(newBounds), NSMinY(newBounds));
		newEndPoint = NSMakePoint(NSMaxX(newBounds), NSMaxY(newBounds));
	}
	else {
	if (SKTGraphicLowerLeftHandle == handleForBounds) {
		newBeginPoint = NSMakePoint(NSMinX(newBounds), NSMaxY(newBounds));
		newEndPoint = NSMakePoint(NSMaxX(newBounds), NSMinY(newBounds));
	}
	else {
	if (SKTGraphicUpperRightHandle == handleForBounds) {
		newBeginPoint = NSMakePoint(NSMaxX(newBounds), NSMinY(newBounds));
		newEndPoint = NSMakePoint(NSMinX(newBounds), NSMaxY(newBounds));
	}
	else {
		newBeginPoint = NSMakePoint(NSMaxX(newBounds), NSMaxY(newBounds));
		newEndPoint = NSMakePoint(NSMinX(newBounds), NSMinY(newBounds));
	}
	}
	}
	// この後、[self beginPoint], [self endPoint], _bounds, _pointsDown, _pointsRightを設定させるためにsetBeginPoint:とsetEndPoint:とを呼び出す。 //
	if (SKTLineBeginHandle == handle) {
		[self setBeginPoint:newBeginPoint];
		[self setEndPoint:newEndPoint];
	}
	else {
		[self setBeginPoint:newEndPoint];
		[self setEndPoint:newBeginPoint];
	}
	return handle;
}


- (void)setColor:(NSColor *)color {

    // Because lines aren't filled we'll consider the stroke's color to be the one.
    [self setValue:color forKey:SKTGraphicStrokeColorKey];

}


- (NSSet *)keysForValuesToObserveForUndo {
    
    // When the user drags one of the handles of a line we don't want to just have changes to "bounds" registered in the undo group. That would be:
    // 1) Insufficient. We would also have to register changes of "pointsRight" and "pointsDown," but we already decided to keep those properties private (see the comments in the header).
    // 2) Not very user-friendly. We don't want the user to see an "Undo Change of Bounds" item in the Edit menu. We want them to see "Undo Change of Endpoint."
    // So, tell the observer of undoable properties (SKTDocument, in Sketch) to observe "beginPoint" and "endPoint" instead of "bounds."
    NSMutableSet *keys = [[super keysForValuesToObserveForUndo] mutableCopy];
    [keys removeObject:SKTGraphicBoundsKey];
    [keys addObject:SKTLineBeginPointKey];
    [keys addObject:SKTLineEndPointKey];
    return [keys autorelease];
    
}


+ (NSString *)presentablePropertyNameForKey:(NSString *)key {
    
    // Pretty simple. As is usually the case when a key is passed into a method like this, we have to invoke super if we don't recognize the key. As far as the user is concerned both points that define a line are "endpoints."
    static NSDictionary *presentablePropertyNamesByKey = nil;
    if (!presentablePropertyNamesByKey) {
	presentablePropertyNamesByKey = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
	    NSLocalizedStringFromTable(@"Beginpoint", @"UndoStrings", @"Action name part for SKTLineBeginPointKey."), SKTLineBeginPointKey,
	    NSLocalizedStringFromTable(@"Endpoint", @"UndoStrings",@"Action name part for SKTLineEndPointKey."), SKTLineEndPointKey,
	    nil];
    }
    NSString *presentablePropertyName = [presentablePropertyNamesByKey objectForKey:key];
    if (!presentablePropertyName) {
	presentablePropertyName = [super presentablePropertyNameForKey:key];
    }
    return presentablePropertyName;

}

- (NSArray *)svgXMLElements:(NSRect)aRect name:(NSString *)unique_ID
// SatoAkira add. //
{
	NSRect bounds = [self bounds];
	NSMutableArray *elements = [NSMutableArray arrayWithObject:[NSXMLNode commentWithStringValue:NSStringFromClass([self class])]];

	if ((NSWidth(bounds) >= 1.0) || (NSHeight(bounds) >= 1.0)) {
		BOOL shadowFlag = (0.1 > [self shadowBlurRadiusValue]) ? NO : YES;
		NSArray *defsAndRect = [self svgDefsAndRect:unique_ID allGraphics:NSZeroRect bounds:bounds transform:nil];
		if (0 < [defsAndRect count])
			[elements addObjectsFromArray:defsAndRect];
		CGFloat translateX = NSMidX(bounds) - NSMinX(aRect);
		CGFloat translateY = NSMidY(bounds) - NSMinY(aRect);
		NSXMLElement *element = [NSXMLElement elementWithName:@"line"];
		NSMutableArray *attributes = [NSMutableArray arrayWithObjects:svgTransformNode(translateX,translateY,[self rotateAngle],1.0,1.0),nil];
		NSArray *fillAndStrokeAttributes = [self svgFillAndStrokeAttributes:unique_ID];

		[attributes addObjectsFromArray:fillAndStrokeAttributes];
		if (YES == [self isDrawingStroke])
			[attributes addObject:svgStrokeWidthNode([self strokeWidth])];
		if (_pointsDown != _pointsRight) { // (YES == [self startsAtLowerLeft]) 古くは(NO == gFlags.downhill) //
			[attributes addObjectsFromArray:[NSArray arrayWithObjects:[NSXMLNode attributeWithName:@"x1" stringValue:[NSString stringWithFormat:@"%g%@",-0.5 * NSWidth(bounds),svgUnit]],[NSXMLNode attributeWithName:@"y1" stringValue:[NSString stringWithFormat:@"%g%@",0.5 * NSHeight(bounds),svgUnit]],[NSXMLNode attributeWithName:@"x2" stringValue:[NSString stringWithFormat:@"%g%@",0.5 * NSWidth(bounds),svgUnit]],[NSXMLNode attributeWithName:@"y2" stringValue:[NSString stringWithFormat:@"%g%@",-0.5 * NSHeight(bounds),svgUnit]],nil]];
		}
		else {
			[attributes addObjectsFromArray:[NSArray arrayWithObjects:[NSXMLNode attributeWithName:@"x1" stringValue:[NSString stringWithFormat:@"%g%@",-0.5 * NSWidth(bounds),svgUnit]],[NSXMLNode attributeWithName:@"y1" stringValue:[NSString stringWithFormat:@"%g%@",-0.5 * NSHeight(bounds),svgUnit]],[NSXMLNode attributeWithName:@"x2" stringValue:[NSString stringWithFormat:@"%g%@",0.5 * NSWidth(bounds),svgUnit]],[NSXMLNode attributeWithName:@"y2" stringValue:[NSString stringWithFormat:@"%g%@",0.5 * NSHeight(bounds),svgUnit]],nil]];
		}
		[attributes addObject:svgLineCapNode([self lineCap])];
		[attributes addObjectsFromArray:(0 < [[self lineDashPattern] count]) ? svgDashArrayNodes([self lineDashPattern],[self lineDashPhase]) : svgDashArrayNodes(nil,0.0)];
		if (YES == shadowFlag)
			[attributes addObject:[NSXMLNode attributeWithName:@"filter" stringValue:[NSString stringWithFormat:@"url(#shadow_%@)",unique_ID]]];
		[element setAttributes:attributes];
		[elements addObject:element];
		if (SKTArrowNone != [self arrowState]) {
			NSInteger corner;
			NSPoint beginPoint = [self beginPoint];
			NSPoint endPoint = [self endPoint];
			NSPoint midPoint = NSMakePoint(0.5 * (beginPoint.x + endPoint.x),0.5 * (beginPoint.y + endPoint.y));
			element = [NSXMLElement elementWithName:@"g"];
			attributes = [NSMutableArray arrayWithObjects:svgTransformNode(translateX,translateY,[self rotateAngle],1.0,1.0),nil];
			[attributes addObjectsFromArray:svgColorNodes(unique_ID,@"fill",@"stroke",[self strokeColor])];
			[attributes addObject:svgFillRuleNode(NSNonZeroWindingRule)];
			[attributes addObjectsFromArray:svgColorNodes(unique_ID,@"stroke",@"stroke",nil)];
			if (YES == shadowFlag)
				[attributes addObject:[NSXMLNode attributeWithName:@"filter" stringValue:[NSString stringWithFormat:@"url(#shadow_%@)",unique_ID]]];
			if (YES == [[[self strokeColor] colorSpaceName] isEqualToString:NSPatternColorSpace])
				[attributes addObject:[NSXMLNode attributeWithName:@"stroke" stringValue:[NSString stringWithFormat:@"url(#stroke_%@)",unique_ID]]];
			[element setAttributes:attributes];
			[element addChild:[NSXMLNode commentWithStringValue:[NSString stringWithFormat:@"%@/arrow",NSStringFromClass([self class])]]];
			if ([self arrowState] & SKTArrowOnStart) {
				if ((YES == _pointsRight) && (YES == _pointsDown))
					corner = SKTGraphicUpperLeftHandle;
				else {
					if ((YES == _pointsRight) && (NO == _pointsDown))
						corner = SKTGraphicLowerLeftHandle;
					else {
						if ((NO == _pointsRight) && (YES == _pointsDown))
							corner = SKTGraphicUpperRightHandle;
						else
							corner = SKTGraphicLowerRightHandle;
					}
				}
				[element addChild:svgArrowElement([self strokeColor], beginPoint.x - midPoint.x, beginPoint.y - midPoint.y, [self arrowRadian:corner],[self strokeWidth],[self lineCap])];
			}
			if ([self arrowState] & SKTArrowOnEnd) {
				if ((YES == _pointsRight) && (YES == _pointsDown))
					corner = SKTGraphicLowerRightHandle;
				else {
					if ((YES == _pointsRight) && (NO == _pointsDown))
						corner = SKTGraphicUpperRightHandle;
					else {
						if ((NO == _pointsRight) && (YES == _pointsDown))
							corner = SKTGraphicLowerLeftHandle;
						else
							corner = SKTGraphicUpperLeftHandle;
					}
				}
				[element addChild:svgArrowElement([self strokeColor], endPoint.x - midPoint.x, endPoint.y - midPoint.y, [self arrowRadian:corner],[self strokeWidth],[self lineCap])];
			}
			[elements addObject:element];
		}
		return elements;
	}
	else
		return nil;
}

@end
