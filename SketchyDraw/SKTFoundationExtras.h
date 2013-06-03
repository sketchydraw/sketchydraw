// SKTFoundationExtras.h
// SketchyDraw
//

#import <AppKit/AppKit.h>

NSRect rotateRect(NSRect originalRect,double angle);
NSBezierPath *pdfArrow(NSAffineTransform *trans,CGFloat x,CGFloat y, double angle, CGFloat lineWidth, NSLineCapStyle lineCap);
double atan3(double y,double x);
NSPoint crosspoint(NSPoint a0, NSPoint a1, NSPoint b0, NSPoint b1);
NSColor *colorFromPropertyList(id plist, NSZone *zone);
NSXMLNode *svgTransformNode(CGFloat x,CGFloat y,double r,CGFloat sx,CGFloat sy);
NSString *svgTransformFrom(CGFloat x,CGFloat y,double r,CGFloat sx,CGFloat sy);
NSString *svgEndElement(void);
NSXMLNode *svgPatternNode(NSString *unique_ID, NSString *prefix, NSImage *image, NSPoint minPoint);
NSXMLNode *svgGradientNode(NSString *unique_ID, NSString *prefix, NSString *name, NSArray *values, NSArray *colors, NSArray *colorPosition);
NSArray *svgColorNodes(NSString *unique_ID,NSString *attributeName,NSString *prefix,NSColor *aColor);
NSString *svgColorFrom(NSString *prefix,NSColor *aColor);
NSXMLNode *svgFillRuleNode(NSWindingRule aValue);
NSString *svgFillRuleFrom(NSWindingRule aValue);
NSXMLNode *svgStrokeWidthNode(CGFloat aValue);
NSString *svgStrokeWidthFrom(CGFloat aValue);
NSArray *svgDashArrayNodes(NSArray *anArray,CGFloat phase);
NSString *svgDashArrayFrom(NSArray *anArray,CGFloat phase);
NSXMLNode *svgLineCapNode(NSLineCapStyle aValue);
NSString *svgLineCapFrom(NSLineCapStyle aValue);
NSXMLNode *svgLineJoinNode(NSLineJoinStyle aValue);
NSString *svgLineJoinFrom(NSLineJoinStyle aValue);
NSXMLElement *svgArrowElement(NSColor *strokeColor,CGFloat x,CGFloat y,CGFloat angle,CGFloat lineWidth,NSLineCapStyle lineCap);
NSString *svgArrowFrom(NSColor *strokeColor,CGFloat x,CGFloat y,CGFloat angle,CGFloat lineWidth,NSLineCapStyle lineCap);
NSString *svgFontFrom(NSFont *font);
NSString *svgUnderlineFrom(NSNumber *under,NSNumber *through);
NSString *svgKerningFrom(NSNumber *aValue);
NSString *svgLetterSpacingFrom(CGFloat aValue);
NSString *svgBaselineOffsetFrom(NSInteger superScript,CGFloat offset);
NSString *imageRepToBase64(NSBitmapImageRep *imageRep);
/* CGImageRef convertBitmapImageRep(NSBitmapImageRep *theRep, NSColorSpace *colorspace); */
NSImage *imageFromCGImageRef(CGImageRef image);
NSBitmapImageRep *rgbToCMYKImageRep(NSBitmapImageRep *theRep, NSColorSpace *colorSpace);
NSBitmapImageRep *colorToGrayImageRep(NSBitmapImageRep *theRep);
NSBitmapImageRep *colorToMonoImageRep(NSBitmapImageRep *theRep, NSTIFFCompression compress);

extern NSString *svgUnit;
