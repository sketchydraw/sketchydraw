// SKTFoundationExtras.m
// SketchyDraw
//

#import "SKTFoundationExtras.h"

#ifdef WIN32
#define HUGE 1e999
#endif


NSRect rotateRect(NSRect originalRect,double angle)
// originalRectをangle回転させたときの全体が含まれるRectを返す。微調整はしない。単純に計算するだけである。 //
{
	NSPoint center = NSMakePoint (NSMidX(originalRect),NSMidY(originalRect));
	NSPoint lowerLeft,upperLeft,lowerRight,upperRight;
	double rr = 0.5 * hypot(NSHeight(originalRect), NSWidth(originalRect));
	CGFloat minx = MAXFLOAT; // math.h //
	CGFloat miny = MAXFLOAT;
	CGFloat maxx = -1.0 * MAXFLOAT;
	CGFloat maxy = -1.0 * MAXFLOAT;
	double aa = (0.0 == NSWidth(originalRect)) ? angle + M_PI_2 : angle + atan(NSHeight(originalRect) / NSWidth(originalRect));
	double dx = rr * cos(aa);
	double dy = rr * sin(aa);

	lowerLeft.x = center.x - dx;
	minx = MIN(minx,lowerLeft.x);
	maxx = MAX(maxx,lowerLeft.x);
	lowerLeft.y = center.y - dy;
	miny = MIN(miny,lowerLeft.y);
	maxy = MAX(maxy,lowerLeft.y);
	upperRight.x = center.x + dx;
	minx = MIN(minx, upperRight.x);
	maxx = MAX(maxx, upperRight.x);
	upperRight.y = center.y + dy;
	miny = MIN(miny, upperRight.y);
	maxy = MAX(maxy, upperRight.y);
	aa = (0.0 == NSWidth(originalRect)) ?  angle + M_PI_2 : angle - atan(NSHeight(originalRect) / NSWidth(originalRect));
	dx = rr * cos(aa);
	dy = rr * sin(aa);
	upperLeft.x = center.x - dx;
	minx = MIN(minx, upperLeft.x);
	maxx = MAX(maxx, upperLeft.x);
	upperLeft.y = center.y - dy;
	miny = MIN(miny, upperLeft.y);
	maxy = MAX(maxy, upperLeft.y);
	lowerRight.x = center.x + dx;
	minx = MIN(minx, lowerRight.x);
	maxx = MAX(maxx, lowerRight.x);
	lowerRight.y = center.y + dy;
	miny = MIN(miny, lowerRight.y);
	maxy = MAX(maxy, lowerRight.y);
	return NSMakeRect(minx,miny,maxx - minx,maxy - miny);
}

#ifdef __APPLE__
NSBezierPath *pdfArrow(NSAffineTransform *trans,CGFloat x,CGFloat y, double angle, CGFloat lineWidth, NSLineCapStyle lineCap)
{
	CGFloat offsetX,offsetY;
	NSAffineTransform *localTrans = [NSAffineTransform transform];
	NSBezierPath *path = [NSBezierPath bezierPath];
	NSGraphicsContext *currentContext = [NSGraphicsContext currentContext];
	CGFloat l = (1.0 > lineWidth) ? 8.0 : 8.0 * sqrt(lineWidth);
	CGFloat h = (1.0 > lineWidth) ? 3.0 : 3.0 * sqrt(lineWidth);
	CGFloat t = (1.0 > lineWidth) ? 2.0 : 2.0 * sqrt(lineWidth);

	switch(lineCap) {
	case NSButtLineCapStyle:
		/* offsetX = 0.5 * lineWidth * l / h;
		offsetY = 0.0; */  // この部分は描かれない。従って先端が尖った矢印はできない。 //
		offsetX = 0.0;
		offsetY = 0.5 * lineWidth;
		break;
	case NSSquareLineCapStyle:
		offsetX = offsetY = 0.5 * lineWidth;
		break;
	default: // NSRoundLineCapStyle //
		offsetX = 0.0;
		offsetY = 0.5 * lineWidth;
		break;
	}
	if (nil != trans)
		[localTrans appendTransform:trans];
	[localTrans translateXBy:x yBy:y];
	[localTrans rotateByRadians:angle];
	[localTrans concat];
	[path moveToPoint:NSMakePoint(offsetX,offsetY)];
	[path relativeLineToPoint:NSMakePoint(-1.0 * l,h)];
	[path relativeLineToPoint:NSMakePoint(t,-1.0 * h)];
	[path relativeLineToPoint:NSMakePoint(0.0,-1.0 * lineWidth)];
	[path relativeLineToPoint:NSMakePoint(-1.0 * t,-1.0 * h)];
	[path relativeLineToPoint:NSMakePoint(l,h)];
	[path closePath];
	[currentContext saveGraphicsState];
	[path stroke];
	[currentContext restoreGraphicsState];
	[path fill];
	return path; // [localTrans rotateByRadians:-1.0 * angle];などとしても無意味である。 //
}
#endif
/* defineps PSArrow(float x, y, angle)
/arrow {
% angle x y
    newpath
    moveto
    dup rotate
    -13 6 rlineto
    4 -6 rlineto
    -4 -6 rlineto
    closepath
    gsave
    0 setlinejoin
    stroke
    grestore
    fill
    neg rotate
} def
    angle x y arrow
endps
*/

NSPoint crosspoint(NSPoint a0, NSPoint a1, NSPoint b0, NSPoint b1)
// 平行のときx,y,zともにHUGEを返す。 //
{
	NSPoint crossp;
	double t0,t1;

	t0 = (a1.x == a0.x) ? HUGE : (a1.y - a0.y) / (a1.x - a0.x);
	t1 = (b1.x == b0.x) ? -1.0 * HUGE : (b0.y - b1.y) / (b1.x - b0.x);
	if (0.0 == t0 + t1)
		crossp.x = crossp.y = HUGE;
	else {
		crossp.x = ((b0.y - a0.y) + t1 * (b0.x - a0.x)) / (t0 + t1) + a0.x;
		crossp.y = (t0 * ((b0.y - a0.y) + t1 * (b0.x - a0.x)) / (t0 + t1)) + a0.y;
	}
	return crossp;
}

double atan3(double y,double x)
// y/x のアークタンジェントを計算する。０から２ＰＩまでのラジアンを返す。//
{
	double rad;
	if( x == 0.0 )
	{
		if( y < 0.0 ) return( M_PI + M_PI_2 );
		if( y > 0.0 ) return( M_PI_2 );
		else return(0.0);
	}
	if( y == 0.0 && x < 0.0 ) return(M_PI);
	rad = atan(y/x);
	if( x < 0.0 )   rad += M_PI;
	if( rad < 0.0 ) rad += 2.0 * M_PI;
	return(rad);
}
NSInteger mat_inv(double *a,NSInteger l,NSInteger m,double **im)
{
	double w,*y,temp;
	/* double det; */
	NSInteger i,j,k,endm,enda,idouble,iw,*work,row,baserow;
	
	if( l < m )
		return -1;
	if( l == m )
		memcpy(*im,a,m * l * sizeof(double));
	else {
		for( i = 0; i < m; i++ ) {
			for( j = 0; j < m; j++, (*im)++ )
				**im = *(a + (i * l + j));
		}
		*im -= m * m;
	}
	endm = m * m - 1;
	enda = m - 1;
	idouble = 1;
	/* det = (double)idouble; */
	if( (work = (NSInteger *)malloc(m * sizeof(NSInteger))) == (NSInteger *)NULL )
		return -1;
	for( i = 0; i < m; i++, work++ )
		*work = i;
	work -= m;
	for( w = fabs(**im), iw = 0, i = 1; i < m; i++ ) {
		if( w < fabs(*(*im + (i * m))) ) {
			iw = *(work + i);
			*(work + i) = *work;
			*work = iw;
			iw = i;
			w = fabs(*(*im + (i * m)));
		}
	}
	/* if( w == 0.0 )
		det = 0.0; */
	if( iw ) {
		for( row = iw * m, j = 0; j < m; j++ ) {
			temp = *(*im + j);
			*(*im + j) = *(*im + (row + j));
			*(*im + (row + j)) = temp;
		}
		idouble *= -1;
	}
	for( j = 1; j < m; j++ )
		*(*im + j) /= **im;
	for( k = 1; k < enda; k++ ) {
		baserow = k * m;
		for( i = k; i < m; i++ ) {
			row = i * m;
			w = *(*im + (row + k));
			for( j = 0; j < k; j++ )
				w -= *(*im + (row + j)) * *(*im + (j * m + k));
			*(*im + (row + k)) = w;
		}
		w = fabs(*(*im + (baserow + k)));
		iw = k;
		for( i = k + 1; i < m; i++ ) {
			if( w < fabs(*(*im + (i * m + k))) ) {
				iw = *(work + i);
				*(work + i) = *(work + k);
				*(work + k) = iw;
				iw = i;
				w = fabs(*(*im + (i * m + k)));
			}
		}
		/* if( w == 0.0 )
			det = 0.0; */
		if( iw != k ) {
			for( row = iw * m, j = 0; j < m; j++ ) {
				temp = *(*im + (baserow + j));
				*(*im + (baserow + j)) = *(*im + (row + j));
				*(*im + (row + j)) = temp;
			}
			idouble *= -1;
		}
		for( j = k + 1; j < m; j++ ) {
			w = *(*im + (baserow + j));
			for( i = 0; i < k; i++ )
				w -= *(*im + (baserow + i)) * *(*im + (i * m + j));
			*(*im + (baserow + j)) = w / *(*im + (baserow + k));
		}
	}
	for( w = *(*im + endm), j = 0; j < enda; j++ )
		w -= *(*im + (enda * m + j)) * *(*im + (j * m + enda));
	*(*im + endm) = w;
	/*  printf("LU triangler matrix\n");
	 for( i = 0; i < m; i++ ) {
	 for( j = 0; j < m; j++ ) printf("%14.4e ",*(*im + (i * m + j)));
	 printf("\n");
	 }
	 printf("\n"); */
	/* 行列式の値 */
	/*  if( det != 0.0 ) {
	 for( det = (double)idouble, i = 0; i < m; i++ )
	 det *= *(*im + (i * m + i));
	 } */
	if( (y = (double *)malloc(m * sizeof(double))) == (double *)NULL ) {
		free(work);
		return -1;
	}
	for( j = 0; j < enda; j++ ) {
		*(y + j) = 1.0 / *(*im + (j * m + j));
		for( i = j + 1; i < m; i++ ) {
			row = i * m;
			w = 0.0;
			for( k = j; k < i; k++ )
				w += *(*im + (row + k)) * *(y + k);
			*(y + i) = -w / *(*im + (row + i));
		}
		for( i = j; i < m; i++ )
			*(*im + (i * m + j)) = *(y + i);
	}
	*(*im + endm) = 1.0 / *(*im + endm);
	for( i = enda - 1; i >= 0; i-- ) {
		row = i * m;
		for( j = 0; j < m; j++ ) {
			w = 0.0;
			for( k = i + 1; k < m; k++ )
				w += *(*im + (row + k)) * *(*im + (k * m + j));
			*(y + j) = -w;
		}
		for( j = 0; j <= i; j++ )
			*(*im + (row + j)) += *(y + j);
		for( j = i + 1; j < m; j++ )
			*(*im + (row + j)) = *(y + j);
	}
	for( i = 0; i < m; i++ ) {
		while(1) {
			if( (k = *(work + i)) == i )
				break;
			iw = *(work + k);
			*(work + k) = *(work + i);
			*(work + i) = iw;
			for( j = 0; j < m; j++ ) {
				row = j * m;
				temp = *(*im + (row + i));
				*(*im + (row + i)) = *(*im + (row + k));
				*(*im + (row + k)) = temp;
			}
		}
	}
	free(y);
	free(work);
	return 0;
}
NSInteger mat_mult(double *a,double *b,NSInteger m,NSInteger n,NSInteger o,double **c)
{
	NSInteger i,j,k;
	
	for (i = 0; i < m; i++) {
		for (j = 0; j < n; j++, (*c)++) {
			**c = 0.0;
			for (k = 0; k < o; k++) {
				**c += *(a + (i * o + k)) * *(b + (k * n + j));
				if (isinf(**c)) {
					*c -= i * m + j;
					return -1;
				}
				if (isnan(**c)) {
					*c -= i * m + j;
					return -2;
				}
				if (MAXFLOAT - 1.0 < **c) {
					*c -= i * m + j;
					return -3;
				}
			}
		}
	}
	*c -= m * n;
	return 0;
}
NSInteger mat_trn(double *a,NSInteger m,NSInteger n,double **b)
{
	NSInteger i,j;
	
	for( i = 0; i < n; i++ ) {
		for( j = 0; j < m; j++, (*b)++ )
			**b = *(a + (j * n + i));           
	}
	*b -= n * m;
	return 0;
}
NSInteger leastsqr(double *a,double *b,NSInteger l,NSInteger m,double **x)
{
	double *tm,*mm,*im,*itm;
	
	if( (tm = (double *)malloc(l * m * sizeof(double))) == (double *)NULL )
		return -1;
	if( (mm = (double *)malloc(l * l * sizeof(double))) == (double *)NULL ) {
		free(tm);
		return -1;
	}
	if( (im = (double *)malloc(l * l * sizeof(double))) == (double *)NULL ) {
		free(tm);
		free(mm);
		return -1;
	}
	if( (itm = (double *)malloc(l * m * sizeof(double))) == (double *)NULL ) {
		free(tm);
		free(mm);
		free(im);
		return -1;
	}
	/* tm = aの転置行列 */
	mat_trn(a,m,l,&tm);
	/* mm = tm * a */
	mat_mult(tm,a,l,l,m,&mm);
	/* im = mmの逆行列 */
	if( mat_inv(mm,l,l,&im) == -1 ) {
		free(tm);
		free(mm);
		free(im);
		free(itm);
		return -1;
	}
	/* itm = im * tm */
	mat_mult(im,tm,l,m,l,&itm);
	/* x = itm * b */
	mat_mult(itm,b,l,1,m,&(*x));
	free(tm);
	free(mm);
	free(im);
	free(itm);
	return 0;
}
double mltnreg1d(double *a,double *b,double *x,NSInteger l,NSInteger m)
{
	NSInteger i,j;
	double w,d,returnValue;
	
	if (l == m)
		return 0.0;
	if (l > m)
		return -1.0;
	for (d = 0.0, i = 0; i < m; i++, b++) {
		for (w = 0.0, j = 0; j < l; j++)
			w += *(a + (i * l + j)) * *x++;
		x -= l;
		if (isinf(w)) {
			d = -2.0;
			break;
		}
		else {
			if (isnan(w)) {
				d = -1.0;
				break;
			}
			else
				d += (*b - w) * (*b - w);
		}
	}
	if (0.0 > d) {
		fprintf(stderr,"mltnreg1d in slib:d < 0.0 error!\n");
		return d;
	}
	else {
		d /= (double)(m - l);
		returnValue = sqrt(d); // 残差の平方和の二乗根 //
	}
	if (returnValue >= HUGE_VAL) {
		fprintf(stderr,"mltnreg1d in slib:d >= HUGE_VAL error!\n");
		return -3.0;
	}
	if (ERANGE == errno) {
		errno = 0;
		fprintf(stderr,"mltnreg1d in slib:errno = ERANGE!\n");
		return -4.0;
	}
	else
		return returnValue;
}
double regiter1d(double *a,double *b,NSInteger l,NSInteger m,double **x)
{
	NSInteger i,j,rep; // rep : 反復回数。大概repが1で収束する。すなわち2回ループを回る。 //
	double d,bw,dw,*alm,*bm,*xl;
	
	if ((alm = (double *)malloc(l * m * sizeof(double))) == (double *)NULL)
		return -6.0;
	if ((bm = (double *)malloc(m * sizeof(double))) == (double *)NULL) {
		free(alm);
		return -6.0;
	}
	// xlは初期化が必要であるのでcalloc() //
	if ((xl = (double *)calloc(l,sizeof(double))) == (double *)NULL) {
		free(alm);
		free(bm);
		return -6.0;
	}
	memcpy(alm,a,l * m * sizeof(double));
	memcpy(bm,b,m * sizeof(double));
	for (i = 0; i < l; i++, (*x)++)
		**x = 1.0;
	*x -= l;
	dw = 10000000.0;
	for (rep = 0; rep < 1000; rep++) { // 繰り返し回数の上限1000には特別な意味は無い。無限ループになってしまうことを防ぐためだけである。 //
		if ((d = mltnreg1d(alm,bm,*x,l,m)) < 0.0) {
			free(alm);
			free(bm);
			free(xl);
			return d;
		}
		if (leastsqr(alm,bm,l,m,&(*x)) == -1) {
			free(alm);
			free(bm);
			free(xl);
			return -5.0;
		}
		if ((d = mltnreg1d(alm,bm,*x,l,m)) < 0.0) {
			free(alm);
			free(bm);
			free(xl);
			return d;
		}
		if (dw <= d)
			break;
		dw = d;
		for (i = 0; i < l; i++, (*x)++)
			**x += *xl++;
		*x -= l;
		xl -= l;
		memcpy(xl,*x,l * sizeof(double));
		for (i = 0; i < m; i++) {
			for (bw = 0.0, j = 0; j < l; j++, (*x)++)
				bw += **x * *alm++;
			*x -= l;
			*bm++ = *b++ - bw;
		}
		bm -= m;
		b -= m;
		alm -= l * m;
	}
	memcpy(*x,xl,l * sizeof(double));
	d = mltnreg1d(alm,b,*x,l,m);
	free(xl);
	free(bm);
	free(alm);
	return d;
}

NSColor *colorFromPropertyList(id plist, NSZone *zone)
{
    if ([plist isKindOfClass:[NSDictionary class]]) {
        NSString *colorSpaceName = [plist objectForKey:@"ColorSpace"];
        if ([colorSpaceName isEqualToString:@"NSCalibratedWhiteColorSpace"]) {
            return [[NSColor colorWithCalibratedWhite:[[plist objectForKey:@"White"] floatValue] alpha:[[plist objectForKey:@"Alpha"] floatValue]] retain];
        } else if ([colorSpaceName isEqualToString:@"NSCalibratedRGBColorSpace"]) {
            return [[NSColor colorWithCalibratedRed:[[plist objectForKey:@"Red"] floatValue] green:[[plist objectForKey:@"Green"] floatValue] blue:[[plist objectForKey:@"Blue"] floatValue] alpha:[[plist objectForKey:@"Alpha"] floatValue]] retain];
        } else if ([colorSpaceName isEqualToString:@"NSDeviceWhiteColorSpace"]) {
            return [[NSColor colorWithDeviceWhite:[[plist objectForKey:@"White"] floatValue] alpha:[[plist objectForKey:@"Alpha"] floatValue]] retain];
        } else if ([colorSpaceName isEqualToString:@"NSDeviceRGBColorSpace"]) {
            return [[NSColor colorWithDeviceRed:[[plist objectForKey:@"Red"] floatValue] green:[[plist objectForKey:@"Green"] floatValue] blue:[[plist objectForKey:@"Blue"] floatValue] alpha:[[plist objectForKey:@"Alpha"] floatValue]] retain];
        } else if ([colorSpaceName isEqualToString:@"NSDeviceCMYKColorSpace"]) {
            return [[NSColor colorWithDeviceCyan:[[plist objectForKey:@"Cyan"] floatValue] magenta:[[plist objectForKey:@"Magenta"] floatValue] yellow:[[plist objectForKey:@"Yellow"] floatValue] black:[[plist objectForKey:@"Black"] floatValue] alpha:[[plist objectForKey:@"Alpha"] floatValue]] retain];
        } else if ([colorSpaceName isEqualToString:@"NSNamedColorSpace"]) {
            return [[NSColor colorWithCatalogName:[plist objectForKey:@"CId"] colorName:[plist objectForKey:@"NId"]] retain];
        } else if ([colorSpaceName isEqualToString:@"Unknown"]) {
            return [[NSUnarchiver unarchiveObjectWithData:[plist objectForKey:@"Data"]] retain];
        } else { // should never happen, maybe raise?
            return nil;
        }
    } else if ([plist isKindOfClass:[NSData class]]) {
        return plist ? [[NSUnarchiver unarchiveObjectWithData:plist] retain] : nil;
    } else { // should never happen, maybe raise?
        return nil;
    }
}

NSString *svgUnit = @"px";// SatoAkira add. //

NSXMLNode *svgTransformNode(CGFloat x,CGFloat y,double r,CGFloat sx,CGFloat sy) {
	if ((1.0 != sx) || (1.0 != sy)) {
		if (0.0 != r)
			return [NSXMLNode attributeWithName:@"transform" stringValue:[NSString stringWithFormat:@"translate(%g %g) rotate(%g) scale(%g %g)",x,y,180.0 * r * M_1_PI,sx,sy]];
		else
			return [NSXMLNode attributeWithName:@"transform" stringValue:[NSString stringWithFormat:@"translate(%g %g) scale(%g %g)",x,y,sx,sy]];
	}
	else {
		if (0.0 != r)
			return [NSXMLNode attributeWithName:@"transform" stringValue:[NSString stringWithFormat:@"translate(%g %g) rotate(%g)",x,y,180.0 * r * M_1_PI]];
		else
			return [NSXMLNode attributeWithName:@"transform" stringValue:[NSString stringWithFormat:@"translate(%g %g)",x,y]];
	}
}
NSString *svgTransformFrom(CGFloat x,CGFloat y,double r,CGFloat sx,CGFloat sy) {
	if ((1.0 != sx) || (1.0 != sy))
		return [NSString stringWithFormat:@"transform=\"translate(%g %g) rotate(%g) scale(%g %g)\"",x,y,180.0 * r * M_1_PI,sx,sy];
	else
		return [NSString stringWithFormat:@"transform=\"translate(%g %g) rotate(%g)\"",x,y,180.0 * r * M_1_PI];
}
NSString *svgEndElement(void) {
	return @"/>\n";
}
NSXMLNode *svgPatternNode(NSString *unique_ID, NSString *prefix, NSImage *image, NSPoint minPoint)
{
	NSString *idValue = [NSString stringWithFormat:@"%@_%@",prefix,unique_ID];
	NSXMLElement *child = [NSXMLNode elementWithName:@"pattern" children:nil attributes:[NSArray arrayWithObjects:[NSXMLNode attributeWithName:@"id" stringValue:idValue],[NSXMLNode attributeWithName:@"patternUnits" stringValue:@"userSpaceOnUse"],[NSXMLNode attributeWithName:@"width" stringValue:[NSString stringWithFormat:@"%g%@",[image size].width,svgUnit]],[NSXMLNode attributeWithName:@"height" stringValue:[NSString stringWithFormat:@"%g%@",[image size].height,svgUnit]],[NSXMLNode attributeWithName:@"x" stringValue:[NSString stringWithFormat:@"%g%@",minPoint.x,svgUnit]],[NSXMLNode attributeWithName:@"y" stringValue:[NSString stringWithFormat:@"%g%@",minPoint.y,svgUnit]],nil]];
	NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:[image TIFFRepresentation]];
	NSString *base64Str = (nil != imageRep) ? imageRepToBase64(imageRep) : nil;
	if (nil != base64Str) {
		NSXMLElement *grandChild = [NSXMLNode elementWithName:@"image" children:nil attributes:[NSArray arrayWithObjects:[NSXMLNode attributeWithName:@"width" stringValue:[NSString stringWithFormat:@"%g%@",[image size].width,svgUnit]],[NSXMLNode attributeWithName:@"height" stringValue:[NSString stringWithFormat:@"%g%@",[image size].height,svgUnit]],[NSXMLNode attributeWithName:@"preserveAspectRatio" stringValue:@"none"],[NSXMLNode attributeWithName:@"xlink:href" stringValue:[NSString stringWithFormat:@"data:%@",base64Str]],nil]];
		[child addChild:grandChild];
	}
	return child;
}
NSXMLNode *svgGradientNode(NSString *unique_ID, NSString *prefix, NSString *name, NSArray *values, NSArray *colors, NSArray *colorPosition)
// prefixはsvgColorNodesで常数として使用するために@"gradient"でなければならない。valuesはx1,y1,x2,y2またはcx,cy,rの[NSNumber numberWithDouble:]の順。colorsの各要素はNSColor。colorPositionの各要素は0.0から1.0までの[NSNumber numberWithFloat:]。colorsとcolorPositionは1対1。 //
{
	NSUInteger i;
	NSString *idValue = [NSString stringWithFormat:@"%@_%@",prefix,unique_ID];
	NSXMLElement *child;
	NSXMLElement *grandChild;
	NSString *colorSpace;
	NSColor *rgbColor;
	CGFloat r,g,b,a;
	CGFloat ff = 255.0;
	NSMutableArray *grandChildren = [NSMutableArray array];
	
	if (YES == [name isEqualToString:@"radialGradient"])
		child = [NSXMLNode elementWithName:@"radialGradient" children:nil attributes:[NSArray arrayWithObjects:[NSXMLNode attributeWithName:@"id" stringValue:idValue],[NSXMLNode attributeWithName:@"gradientUnits" stringValue:@"userSpaceOnUse"],[NSXMLNode attributeWithName:@"cx" stringValue:[NSString stringWithFormat:@"%g%@",[[values objectAtIndex:0] doubleValue],svgUnit]],[NSXMLNode attributeWithName:@"cy" stringValue:[NSString stringWithFormat:@"%g%@",[[values objectAtIndex:1] doubleValue],svgUnit]],[NSXMLNode attributeWithName:@"r" stringValue:[NSString stringWithFormat:@"%g%@",[[values objectAtIndex:2] doubleValue],svgUnit]],[NSXMLNode attributeWithName:@"fx" stringValue:[NSString stringWithFormat:@"%g%@",[[values objectAtIndex:0] doubleValue],svgUnit]],[NSXMLNode attributeWithName:@"fy" stringValue:[NSString stringWithFormat:@"%g%@",[[values objectAtIndex:1] doubleValue],svgUnit]],[NSXMLNode attributeWithName:@"spreadMethod" stringValue:@"pad"],nil]]; // fx,fyはcx,cyと異なる値を指定しなければならないので、とりあえず指定しないものとする。 //
	else
		child = [NSXMLNode elementWithName:@"linearGradient" children:nil attributes:[NSArray arrayWithObjects:[NSXMLNode attributeWithName:@"id" stringValue:idValue],[NSXMLNode attributeWithName:@"gradientUnits" stringValue:@"userSpaceOnUse"],[NSXMLNode attributeWithName:@"x1" stringValue:[NSString stringWithFormat:@"%g%@",[[values objectAtIndex:0] doubleValue],svgUnit]],[NSXMLNode attributeWithName:@"y1" stringValue:[NSString stringWithFormat:@"%g%@",[[values objectAtIndex:1] doubleValue],svgUnit]],[NSXMLNode attributeWithName:@"x2" stringValue:[NSString stringWithFormat:@"%g%@",[[values objectAtIndex:2] doubleValue],svgUnit]],[NSXMLNode attributeWithName:@"y2" stringValue:[NSString stringWithFormat:@"%g%@",[[values objectAtIndex:3] doubleValue],svgUnit]],[NSXMLNode attributeWithName:@"spreadMethod" stringValue:@"pad"],nil]];

	for (i = 0; i < [colors count]; i++) {
		colorSpace = [[colors objectAtIndex:i] colorSpaceName];
		if ((YES == [colorSpace isEqualToString:NSCalibratedRGBColorSpace]) || (YES == [colorSpace isEqualToString:NSDeviceRGBColorSpace]))
			rgbColor = [colors objectAtIndex:i];
		else
			rgbColor = [[colors objectAtIndex:i] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
		[rgbColor getRed:&r green:&g blue:&b alpha:&a];
		grandChild = [NSXMLNode elementWithName:@"stop" children:nil attributes:[NSArray arrayWithObjects:[NSXMLNode attributeWithName:@"offset" stringValue:[NSString stringWithFormat:@"%g",[[colorPosition objectAtIndex:i] floatValue]]],[NSXMLNode attributeWithName:@"stop-color" stringValue:[NSString stringWithFormat:@"#%02lX%02lX%02lX",(NSInteger)(r * ff + 0.5),(NSInteger)(g * ff + 0.5),(NSInteger)(b * ff + 0.5)]],[NSXMLNode attributeWithName:@"stop-opacity" stringValue:[NSString stringWithFormat:@"%g",a]],nil]];
		[grandChildren addObject:grandChild];
	}
	[child setChildren:grandChildren];
	return child;
}
NSArray *svgColorNodes(NSString *unique_ID,NSString *attributeName,NSString *prefix,NSColor *aColor)
// RGBの文字列にして返す。fillとstrokeとgradient専用。gradientのときはaColorをnilにすること。fill-opacity="0.5" stroke-opacity="0.5" //
{
	if (nil != aColor) {
		NSColor *rgbColor;
		CGFloat r,g,b,a;
		CGFloat ff = 255.0;
		NSString *colorSpace = [aColor colorSpaceName];

		if (YES == [colorSpace isEqualToString:NSPatternColorSpace]) {
			return [NSArray arrayWithObjects:[NSXMLNode attributeWithName:attributeName stringValue:[NSString stringWithFormat:@"url(#%@_%@)",prefix,unique_ID]],nil];
		}
		else {
			if ((YES == [colorSpace isEqualToString:NSCalibratedRGBColorSpace]) || (YES == [colorSpace isEqualToString:NSDeviceRGBColorSpace]))
				rgbColor = aColor;
			else
				rgbColor = [aColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
			[rgbColor getRed:&r green:&g blue:&b alpha:&a];
			if (1.0 == a)
				return [NSArray arrayWithObject:[NSXMLNode attributeWithName:attributeName stringValue:[NSString stringWithFormat:@"#%02lX%02lX%02lX",(NSInteger)(r * ff),(NSInteger)(g * ff),(NSInteger)(b * ff)]]];
			else
				return [NSArray arrayWithObjects:[NSXMLNode attributeWithName:attributeName stringValue:[NSString stringWithFormat:@"#%02lX%02lX%02lX",(NSInteger)(r * ff),(NSInteger)(g * ff),(NSInteger)(b * ff)]],[NSXMLNode attributeWithName:[NSString stringWithFormat:@"%@-opacity",prefix] stringValue:[NSString stringWithFormat:@"%g",a]],nil];
		}
	}
	else {
		if (YES == [prefix isEqualToString:@"gradient"])
			return [NSArray arrayWithObjects:[NSXMLNode attributeWithName:@"fill" stringValue:[NSString stringWithFormat:@"url(#%@_%@)",prefix,unique_ID]],nil];
		else
			return [NSArray arrayWithObject:[NSXMLNode attributeWithName:attributeName stringValue:@"none"]];
	}
}
NSString *svgColorFrom(NSString *prefix,NSColor *aColor)
// RGBの文字列にして返す。fillとstroke専用。fill-opacity="0.5" stroke-opacity="0.5" //
{
	if (nil != aColor) {
		NSColor *rgbColor;
		CGFloat r,g,b,a;
		CGFloat ff = 255.0;
		NSString *colorSpace = [aColor colorSpaceName];

		if ((YES == [colorSpace isEqualToString:NSCalibratedRGBColorSpace]) || (YES == [colorSpace isEqualToString:NSDeviceRGBColorSpace]))
			rgbColor = aColor;
		else
			rgbColor = [aColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
		[rgbColor getRed:&r green:&g blue:&b alpha:&a];
		if (1.0 == a)
			return [NSString stringWithFormat:@"%@=\"#%02lX%02lX%02lX\" ",prefix,(NSInteger)(r * ff + 0.5),(NSInteger)(g * ff + 0.5),(NSInteger)(b * ff + 0.5)];
		else
			return [NSString stringWithFormat:@"%@=\"#%02lX%02lX%02lX\" %@-opacity=\"%g\" ",prefix,(NSInteger)(r * ff + 0.5),(NSInteger)(g * ff + 0.5),(NSInteger)(b * ff + 0.5),prefix,a];
	}
	else
		return [NSString stringWithFormat:@"%@=\"none\" ",prefix];
}
NSXMLNode *svgFillRuleNode(NSWindingRule aValue) {
	return [NSXMLNode attributeWithName:@"fill-rule" stringValue:(NSEvenOddWindingRule == aValue) ? @"evenodd" : @"nonzero"];
}
NSString *svgFillRuleFrom(NSWindingRule aValue) {
	return (NSEvenOddWindingRule == aValue) ? @"fill-rule=\"evenodd\" " : @"fill-rule=\"nonzero\" ";
}
NSXMLNode *svgStrokeWidthNode(CGFloat aValue) {
	return (0.0 < aValue) ? [NSXMLNode attributeWithName:@"stroke-width" stringValue:[NSString stringWithFormat:@"%g%@",aValue,svgUnit]] : [NSXMLNode attributeWithName:@"stroke-width" stringValue:@"0"];
}
NSString *svgStrokeWidthFrom(CGFloat aValue) {
	return (0.0 < aValue) ? [NSString stringWithFormat:@"stroke-width=\"%g%@\" ",aValue,svgUnit] : @"";
}
NSArray *svgDashArrayNodes(NSArray *anArray,CGFloat phase)
{
	if ((nil != anArray) && (0 < [anArray count])) {
		NSMutableString *arrayStr = [NSMutableString string];

		for (NSNumber *pattern in anArray) {
			if (0 < [arrayStr length])
				[arrayStr appendFormat:@" %g%@",[pattern floatValue],svgUnit];
			else
				[arrayStr appendFormat:@"%g%@",[pattern floatValue],svgUnit];
		}
		return [NSArray arrayWithObjects:[NSXMLNode attributeWithName:@"stroke-dasharray" stringValue:arrayStr],[NSXMLNode attributeWithName:@"stroke-dashoffset" stringValue:[NSString stringWithFormat:@"%g%@",phase,svgUnit]],nil];
	}
	else
		return [NSArray arrayWithObject:[NSXMLNode attributeWithName:@"stroke-dasharray" stringValue:@"none"]];
}
NSString *svgDashArrayFrom(NSArray *anArray,CGFloat phase)
{
	if ((nil != anArray) && (0 < [anArray count])) {
		NSMutableString *arrayStr = [NSMutableString string];

		for (NSNumber *pattern in anArray) {
			if (0 < [arrayStr length])
				[arrayStr appendFormat:@" %g%@",[pattern floatValue],svgUnit];
			else
				[arrayStr appendFormat:@"%g%@",[pattern floatValue],svgUnit];
		}
		return [NSString stringWithFormat:@"stroke-dasharray=\"%@\" stroke-dashoffset=\"%g%@\" ",arrayStr,phase,svgUnit];
	}
	else
		return @"stroke-dasharray=\"none\" ";
}
NSXMLNode *svgLineCapNode(NSLineCapStyle aValue)
{
	NSString *obj;
	switch (aValue) {
	case NSSquareLineCapStyle:
		obj = @"square";
		break;
	case NSRoundLineCapStyle:
		obj = @"round";
		break;
	default:
		obj = @"butt";
		break;
	}
	return [NSXMLNode attributeWithName:@"stroke-linecap" stringValue:obj];
}
NSString *svgLineCapFrom(NSLineCapStyle aValue)
{
	NSMutableString *rStr = [NSMutableString stringWithString:@"stroke-linecap=\""];

	switch (aValue) {
	case NSSquareLineCapStyle:
		[rStr appendString:@"square\" "];
		break;
	case NSRoundLineCapStyle:
		[rStr appendString:@"round\" "];
		break;
	default:
		[rStr appendString:@"butt\" "];
		break;
	}
	return rStr;
}
NSXMLNode *svgLineJoinNode(NSLineJoinStyle aValue)
{
	NSString *obj;
	switch (aValue) {
	case NSMiterLineJoinStyle:
		obj = @"miter";
		break;
	case NSRoundLineJoinStyle:
		obj = @"round";
		break;
	default: // NSBevelLineJoinStyle //
		obj = @"bevel";
		break;
	}
	return [NSXMLNode attributeWithName:@"stroke-linejoin" stringValue:obj];
}
NSString *svgLineJoinFrom(NSLineJoinStyle aValue)
{
	NSMutableString *rStr = [NSMutableString stringWithString:@"stroke-linejoin=\""];

	switch (aValue) {
	case NSMiterLineJoinStyle:
		[rStr appendString:@"miter\" "];
		break;
	case NSRoundLineJoinStyle:
		[rStr appendString:@"round\" "];
		break;
	default: // NSBevelLineJoinStyle //
		[rStr appendString:@"bevel\" "];
		break;
	}
	return rStr;
}
NSXMLElement *svgArrowElement(NSColor *strokeColor,CGFloat x,CGFloat y,CGFloat angle,CGFloat lineWidth,NSLineCapStyle lineCap)
// pdfArrow()とアルゴリズムは同じ。 //
{
	CGFloat offsetX,offsetY,xx,yy;
	CGFloat l = (1.0 > lineWidth) ? 8.0 : 8.0 * sqrt(lineWidth);
	CGFloat h = (1.0 > lineWidth) ? 3.0 : 3.0 * sqrt(lineWidth);
	CGFloat t = (1.0 > lineWidth) ? 2.0 : 2.0 * sqrt(lineWidth);
	NSXMLElement *arrowElement = [[NSXMLElement  alloc] initWithName:@"polygon"];
	NSMutableString *aStr = [NSMutableString string];

	switch (lineCap) {
	case NSButtLineCapStyle:
		offsetX = 0.0;
		offsetY = 0.5 * lineWidth;
		break;
	case NSSquareLineCapStyle:
		offsetX = offsetY = 0.5 * lineWidth;
		break;
	default: // NSRoundLineCapStyle //
		offsetX = 0.0;
		offsetY = 0.5 * lineWidth;
		break;
	}
	[arrowElement addAttribute:svgTransformNode(x,y,angle,1.0,1.0)];
	[aStr appendFormat:@"%g %g ",offsetX,offsetY];
	xx = offsetX - l;
	yy = offsetY + h;
	[aStr appendFormat:@"%g %g ",xx,yy];
	xx += t;
	yy -= h;
	[aStr appendFormat:@"%g %g ",xx,yy];
	yy -= lineWidth;
	[aStr appendFormat:@"%g %g ",xx,yy];
	xx -= t;
	yy -= h;
	[aStr appendFormat:@"%g %g ",xx,yy];
	xx += l;
	yy += h;
	[aStr appendFormat:@"%g %g",xx,yy];
	[arrowElement addAttribute:[NSXMLNode attributeWithName:@"points" stringValue:aStr]];
	return [arrowElement autorelease];
}
NSString *svgArrowFrom(NSColor *strokeColor,CGFloat x,CGFloat y,CGFloat angle,CGFloat lineWidth,NSLineCapStyle lineCap)
// pdfArrow()とアルゴリズムは同じ。 //
{
	CGFloat offsetX,offsetY,xx,yy;
	CGFloat l = (1.0 > lineWidth) ? 8.0 : 8.0 * sqrt(lineWidth);
	CGFloat h = (1.0 > lineWidth) ? 3.0 : 3.0 * sqrt(lineWidth);
	CGFloat t = (1.0 > lineWidth) ? 2.0 : 2.0 * sqrt(lineWidth);
	NSMutableString *rStr = [NSMutableString stringWithString:@"\t\t<polygon "];
	
	switch (lineCap) {
	case NSButtLineCapStyle:
		offsetX = 0.0;
		offsetY = 0.5 * lineWidth;
		break;
	case NSSquareLineCapStyle:
		offsetX = offsetY = 0.5 * lineWidth;
		break;
	default: // NSRoundLineCapStyle //
		offsetX = 0.0;
		offsetY = 0.5 * lineWidth;
		break;
	}
	[rStr appendString:svgTransformFrom(x,y,angle,1.0,1.0)];
	[rStr appendFormat:@" points=\"%g %g ",offsetX,offsetY];
	xx = offsetX - l;
	yy = offsetY + h;
	[rStr appendFormat:@"%g %g ",xx,yy];
	xx += t;
	yy -= h;
	[rStr appendFormat:@"%g %g ",xx,yy];
	yy -= lineWidth;
	[rStr appendFormat:@"%g %g ",xx,yy];
	xx -= t;
	yy -= h;
	[rStr appendFormat:@"%g %g ",xx,yy];
	xx += l;
	yy += h;
	[rStr appendFormat:@"%g %g\" ",xx,yy];
	[rStr appendString:svgEndElement()];
	return rStr;
}
NSString *svgFontFrom(NSFont *font)
// Windows,UNIX用のフォント名を加えて返す。他のシステムとの互換性を取るためなので稼働中のシステムとは無関係。Arial,Comic Sans MS,Courier New,Times New Roman,Trebuchet MS,Verdana,Symbol,Webdings,Impact,GeorgiaはWindows互換。Lucida Console,Lucida Sans Unicode,Palatino LinotypeはWindowsにあるが，Mac OSXではLucida Grande,Palatinoとなっている。 //
// フォントファミリー名(例えばMS PGothic)ならば良い。漢字は駄目。NSFontNameAttributeからポストスクリプト名が得られる。 //
// Adobe SVGViewerは一致するものがあれば表示できなくてもそこでやってしまう。OpenTypeは殆ど全滅。Y.OzFontOは大丈夫。全くでたらめのフォント名ならば","以後を検索する。一致は完全一致ではなくて，prefixで一致するかどうかを見ている。 //
// HGについては不明 //
{
	NSArray *fonts;
	NSUInteger i;
	NSString *fontName = [font fontName]; // descからは取得できない。NSFontFaceAttributeにも情報が無い。 //
	NSString *familyName = [font familyName]; // NSFontDescriptorにはNSFontFamilyAttributeの情報が無い。 //
	NSFontDescriptor *desc = [font fontDescriptor];
	NSFontSymbolicTraits typeFace = [desc symbolicTraits];
	NSString *weight = (typeFace & NSFontBoldTrait) ? @"bold" : @"normal";
	// SVGではnormal:400 bold:700 bolder:900 lighter:100 となっている。 100から900までの100ピッチで数値指定ができる。 //
	NSString *style = (typeFace & NSFontItalicTrait) ? @"italic" : @"normal";
	NSMutableString *rStr = [NSMutableString stringWithFormat:@"font-family:\'%@\'",familyName]; // InDesignではfont-familyの値にpostscript名を使っている。例えば「アニト」系のフォントの場合familyNameは"Anito"となってしまい、区別がつかなくなる。postscript名からならば判断できるがfont-styleやfont-weightを指定する方法が無い。 //
	NSUInteger limit = 5; // limit個までのフォント名を設定する。limit個以下は参照するだけである。以下のNSArrayのlastObjectはlimit個目の次へaddされる。 //

	// generic-family sans-serif…………ゴシック系 serif…………明朝系 cursive…………筆記体・草書体系 fantasy…………装飾的 monospace………等幅 //
	// ファミリー名はfamilyNameメソッドで返される値を設定しなければならないが、総てを試してはいない。とてもやりきれない。 //
	NSArray *serif = [NSArray arrayWithObjects:@"Hiragino Mincho ProN",@"MS PMincho",@"IPAPMincho",@"HeiseiMincho",@"Sazanami Mincho",@"Kozuka Mincho Pr6N",@"serif",nil];
	NSArray *sans_serif = [NSArray arrayWithObjects:@"Hiragino Kaku Gothic ProN",@"Meiryo",@"MS PGothic",@"IPAPGothic",@"HeiseiKakuGothic",@"Sazanami Gothic",@"Kozuka Gothic Pr6N",@"Osaka",@"sans-serif",nil]; // Meiryo は メイリオ の方が良さそうだがカタカナにするのが面倒なのでやめた。 //
	NSArray *maru = [NSArray arrayWithObjects:@"HiraGino Maru Gothic ProN",@"DFPMaruGothic-SB",@"Monaco",@"id-kaifu3-OT",@"HGMaruGothicM",@"sans-serif",nil];
	NSArray *fixed_serif = [NSArray arrayWithObjects:@"MS Mincho",@"IPAMincho",@"Sazanami Mincho",@"SimSun",@"SimHei",@"AppleMyungjo",@"Apple LiSung",@"monospace",nil];
	NSArray *fixed_sans_serif = [NSArray arrayWithObjects:@"Osaka-Mono",@"MS Gothic",@"IPAGothic",@"Sazanami Gothic",@"Apple LiGothic",@"monospace",nil];
	NSArray *kaisyo = [NSArray arrayWithObjects:@"Adobe Kaiti Std",@"Adobe Fangsong Std",@"DFPKaisho-Md",@"HGSeikaishotaiPRO",@"Y.OzFontMO97",@"Y.OzFontO04",@"Comic Sans MS",@"Brush Script MT",@"Edwardian Script ITC",@"Lucida Calligraphy",@"Lucida Handwriting",@"DFPGyosho-Lt",@"DFPSNGyoSho-W5",@"DFPKyoKaSho-W3",@"Apple Chancery",@"cursive",nil];
	NSArray *fantasy = [NSArray arrayWithObjects:@"Papyrus",@"Impact",@"Curlz MT",@"Cooper Black",@"Copperplate Gothic Bold",@"Matura MT Script Capitals",@"Perpetua Titling MT",@"Marker Felt",@"Zapfino",@"Herculanum",@"fantasy",nil];
	CGFloat fontSize = [font pointSize]; // [[font fontDescriptor] pointSize]は結果不定。 //

	/* if (typeFace & NSFontBoldTrait) NSLog(@"boldFont=%@",[font fontName]);
	if (typeFace & NSFontExpandedTrait) NSLog(@"expandedFont=%@",[font fontName]);
	if (typeFace & NSFontCondensedTrait) NSLog(@"condensedFont=%@",[font fontName]);
	if (typeFace & NSFontMonoSpaceTrait) NSLog(@"monospaceFont=%@",[font fontName]);
	if (typeFace & NSFontVerticalTrait) NSLog(@"verticalFont=%@",[font fontName]);
	if (typeFace & NSFontUIOptimizedTrait) NSLog(@"optimizedFont=%@",[font fontName]); */
	if (0.0 == fontSize) {
		NSLog(@"descSize=%f pointSize=%f attrSize=%f",[[font fontDescriptor] pointSize],[font pointSize],[[[[font fontDescriptor] fontAttributes] objectForKey:NSFontSizeAttribute] floatValue]);
	}
	if (YES == [fontName hasSuffix:@"Oblique"])
		style = @"oblique"; // 確実にあたるとは限らない。 //
	if (YES == [familyName hasPrefix:@"Kozuka"]) { // "Kozuka Gothic Pr6N" //
		if (YES == [familyName hasSuffix:@"Std"]) {
			if (YES == [fontName hasSuffix:@"ExtraLight"])
				weight = @"200";
			else {
				if (YES == [fontName hasSuffix:@"Light"])
					weight = @"400";
				else {
					if (YES == [fontName hasSuffix:@"Regular"])
						weight = @"600";
					else {
						if (YES == [fontName hasSuffix:@"Medium"])
							weight = @"700";
						else {
							if (YES == [fontName hasSuffix:@"Bold"])
								weight = @"800";
							else {
								if (YES == [fontName hasSuffix:@"Heavy"])
									weight = @"900";
							}
						}
					}
				}
			}
		}
		else { // 小塚フォントはstdという名称がつかなくなったので、殆どこっちになる。ポストスクリプト名(KozGoPr6N-Regular)のsuffixにweight名が付く。 //
			if (YES == [fontName hasSuffix:@"ExtraLight"])
				weight = @"100";
			else {
				if (YES == [fontName hasSuffix:@"Light"])
					weight = @"200";
				else {
					if (YES == [fontName hasSuffix:@"Regular"])
						weight = @"400";
					else {
						if (YES == [fontName hasSuffix:@"Medium"])
							weight = @"600";
						else {
							if (YES == [fontName hasSuffix:@"Bold"])
								weight = @"800";
							else {
								if (YES == [fontName hasSuffix:@"Heavy"])
									weight = @"900";
							}
						}
					}
				}
			}
		}
	}
	else {
		if ((YES == [familyName hasPrefix:@"Hiragino"]) || (YES == [familyName hasPrefix:@"Heisei"])) { // 「DFP」,「えれがんと」など-W?を含むが中間にあるので取り出しにくい。 //
			weight = [NSString stringWithFormat:@"%ld",100 * [[fontName substringFromIndex:[fontName length] - 1] integerValue]];
		}
		else {
			if (YES == [fontName hasSuffix:@"Lighter"])
				weight = @"100";
			else {
				if ((YES == [fontName hasSuffix:@"Regular"]) || (YES == [fontName hasSuffix:@"Normal"]))
					weight = @"400";
				else {
					if (YES == [fontName hasSuffix:@"Semibold"])
						weight = @"600";
					else {
						if (YES == [fontName hasSuffix:@"Bold"])
							weight = @"700";
						else {
							if (YES == [fontName hasSuffix:@"Bolder"])
								weight = @"900";
						}
					}
				}
			}
		}
	}
	if (YES == [serif containsObject:familyName])
		fonts = serif;
	else {
		if (YES == [sans_serif containsObject:familyName])
			fonts = sans_serif;
		else {
			if (YES == [maru containsObject:familyName])
				fonts = maru;
			else {
				if (YES == [fixed_serif containsObject:familyName])
					fonts = fixed_serif;
				else {
					if (YES == [fixed_sans_serif containsObject:familyName])
						fonts = fixed_sans_serif;
					else {
						if (YES == [kaisyo containsObject:familyName])
							fonts = kaisyo;
						else {
							if (YES == [fantasy containsObject:familyName])
								fonts = fantasy;
							else
								fonts = sans_serif;
						}
					}
				}
			}
		}
	}
	for (i = 0; i < limit; i++) {
		if (NO == [familyName isEqualToString:[fonts objectAtIndex:i]])
			[rStr appendFormat:@",\'%@\'",[fonts objectAtIndex:i]];
	}
	[rStr appendFormat:@",\'%@\';font-style:%@;font-weight:%@;font-size:%g%@",[fonts lastObject],style,weight,fontSize,svgUnit];
	return rStr;
}
NSString *svgUnderlineFrom(NSNumber *under,NSNumber *through)
{
	NSMutableString *rStr = [NSMutableString string];

	if ((nil != under) || (nil != through)) {
		BOOL prefixFlag = NO;

		if ((nil != under) && (NSUnderlineStyleNone != [under intValue])) {
			[rStr appendString:@"text-decoration:underline"];
			prefixFlag = YES;
		}
		if ((nil != through) && (NSUnderlineStyleNone != [through intValue])) {
			if (NO == prefixFlag)
				[rStr appendString:@"text-decoration:line-through"];
			else
				[rStr appendString:@" line-through"];
		}
	}
	return rStr;
}

NSString *svgKerningFrom(NSNumber *aValue) {
	if (nil == aValue)
		return @"kerning:auto";
	else
		return [NSString stringWithFormat:@"kerning:%g%@",[aValue floatValue],svgUnit];
}
NSString *svgLetterSpacingFrom(CGFloat aValue) {
	return [NSString stringWithFormat:@"letter-spacing:%g%@",aValue,svgUnit];
}
NSString *svgBaselineOffsetFrom(NSInteger superScript,CGFloat offset)
{
	if (0 != superScript) {
		if (1 == superScript)
			return @"baseline-shift:super";
		else {
			if (-1 == superScript)
				return @"baseline-shift:sub";
			else
				return @"baseline-shift:baseline";
		}
	}
	else
		return [NSString stringWithFormat:@"baseline-shift:%g%@",offset,svgUnit];
}
void enclode_char(unsigned long bb, NSInteger srclen, unsigned char *dest, NSInteger j)
// http://www.sea-bird.org/doc/Cygwin/BASE64encode.c //
{
	NSInteger x, i, base;
	unsigned char *base64 = (unsigned char *)"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

	// 最終位置の計算 //
	for (i = srclen; i < 2; i++) 
		bb <<= 8;
	// BASE64変換 //
	for (base = 18, x = 0; x < srclen + 2; x++, base -= 6)
		dest[j++] = base64[(unsigned long)((bb>>base) & 0x3F)];
	// 端数の判断 //
	for (i = x; i < 4; i++)
		dest[j++] = (unsigned char)'=';		// 端数 //
	dest[j] = '\0';
}

NSString *enclode(NSData *src)
// http://www.sea-bird.org/doc/Cygwin/BASE64encode.c をアレンジした。 //
{
	unsigned char *p = (unsigned char *)[src bytes];
	unsigned long bb = (unsigned long)0;
	int i = 0, j = 0;
	NSInteger mallocSize = (4 * (([src length] + 2) / 3) + 1) * sizeof(unsigned char); // 最後の\0のために1バイト多め。 //
	unsigned char *dest = (unsigned char *)malloc(mallocSize);
	NSInteger k = [src length];

	while (k--) {
		bb <<= 8;
		bb |= (unsigned long)*p;
		// 24bit単位に編集 //
		if (i == 2) {
			enclode_char(bb, i, dest, j);
			j = j + 4;
			i = bb = 0;
		}
		else
			i++;
		p++;
	}
	// 24bitに満たない場合 //
	if (i)
		enclode_char(bb, i - 1, dest, j);
	NSData *data = [NSData dataWithBytes:dest length:mallocSize - sizeof(unsigned char)]; // 必要な所はmallocSize - 1バイト。 //
	free(dest);
	return [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
}

// imageRepToPNG()は不要。libpngの使い方が分かるので保存しているだけである。これを動作させるには，libpng.dylibをプロジェクトに加える必要がある。 //
/* #import "png.h"
NSData *imageRepToPNG(NSBitmapImageRep *imageRep)
// tiffはPlanarとnoPlanar。gif,pngはnoPlanar。jpegはnoPlanarだが崩れる。 //
{
	int pngColorType;
	png_uint_32 samples = [imageRep samplesPerPixel];
	png_uint_32 depth = [imageRep bitsPerSample];
	BOOL isPlanar = [imageRep isPlanar];
	int typeError = -1; // 負の数が使われていないことを利用する。 //

	switch (samples) { // PNG_COLOR_TYPE_GRAY,PNG_COLOR_TYPE_PALETTE,PNG_COLOR_TYPE_RGB,PNG_COLOR_TYPE_RGB_ALPHA,PNG_COLOR_TYPE_GRAY_ALPHA. CMYKをサポートしているかどうかは不明。 //
	case 1:
		if (NO == [imageRep hasAlpha])
			pngColorType = PNG_COLOR_TYPE_GRAY;
		else
			pngColorType = typeError;
		break;		
	case 2:
		if (YES == [imageRep hasAlpha])
			pngColorType = PNG_COLOR_TYPE_GRAY_ALPHA;
		else
			pngColorType = typeError;
		break;
	case 3:
		if (NO == [imageRep hasAlpha])
			pngColorType = PNG_COLOR_TYPE_RGB;
		else
			pngColorType = typeError;
		break;
	case 4:
		if (YES == [imageRep hasAlpha])
			pngColorType = PNG_COLOR_TYPE_RGB_ALPHA;
		else
			pngColorType = PNG_COLOR_TYPE_PALETTE; // CMYK //
		break;
	case 5:
		if (YES == [imageRep hasAlpha])
			pngColorType = PNG_COLOR_TYPE_PALETTE | PNG_COLOR_MASK_ALPHA; // CMYK,Alpha //
		else
			pngColorType = typeError;
		break;
	default: // error //
		pngColorType = typeError;
		break;
	}
	if ((8 != depth) || (typeError == pngColorType)) {
		if (NO == [imageRep hasAlpha])
			NSLog(@"noAlpha depth=%d samples=%d type=%d",depth,samples,pngColorType);
		else
			NSLog(@"Alpha depth=%d samples=%d type=%d",depth,samples,pngColorType);
		return nil;
	}
	else {
		unsigned char *bitmapData[5]; // NSBitmapImageRepのgetBitmapDataPlanes:メソッドの仕様により5個と決められている。 //
		png_uint_32 i,j,k;
		png_structp png_ptr;
		png_infop info_ptr;
		png_uint_32 width = [imageRep pixelsWide];
		png_uint_32 height = [imageRep pixelsHigh];
		png_bytepp image = (typeof (image))malloc(height * sizeof(png_bytep)); // png_write_image を使用する際は単純なビットマップイメージ配列は使用出来ず、1 ラインごとの各ラスターへのポインタ配列を渡す必要がある。 //

		[imageRep getBitmapDataPlanes:bitmapData]; // 表示されているページのデータ。 //
		for (i = 0; i < height; i++) {
			*(image + i) = (typeof (*image))calloc(sizeof(png_byte), width * samples);
			for (j = 0; j < width; j++) {
				for (k = 0; k < samples; k++) {
					if (NO == isPlanar)
						*(*(image + i) + j * samples + k) = *bitmapData[0]++;
					else
						*(*(image + i) + j * samples + k) = *bitmapData[k]++;
				}
			}
		}
		if (YES == isPlanar) {
			for (i = 0; i < samples; i++)
				bitmapData[i] -= height * width;
		}
		else
			bitmapData[0] -= height * width * samples;
		png_ptr = png_create_write_struct( PNG_LIBPNG_VER_STRING, NULL, NULL, NULL ); // その画像を識別するための構造体を初期化する。 //
		info_ptr = png_create_info_struct( png_ptr ); // その画像固有の情報(サイズや色、コメントなど)を保持している構造体。 //
		if (setjmp(png_jmpbuf(png_ptr))) { // libpng ライブラリ内でエラーが発生して処理を中止する際の処理。その際 longjmp で戻ってくるので必ず setjmp しておくこと。 //
			png_destroy_write_struct( &png_ptr, &info_ptr );
			free(image);
			NSLog(@"libpng error.");
			return nil;
		}
		else {
			NSData *tempData;
			unsigned int pngLength;
			unsigned char *fileData,*base64data;
			NSString *rStr;
			FILE *fp = fopen( "/tmp/SketchyDrawTemp.png", "wb" ); // png_init_io()を使わずに，メモリーへ書き出す方法が分からない。 //

			png_init_io( png_ptr, fp );
			png_set_IHDR( png_ptr, info_ptr, width, height,
				depth,                        // 各色に必要なビット数 //
				pngColorType,           // RGB 表現を選択 //
				PNG_INTERLACE_NONE,           // ノンインターレースモード //
				PNG_COMPRESSION_TYPE_DEFAULT, // 今の所 DEFAULT のみ //
				PNG_FILTER_TYPE_DEFAULT       // mng ではフレーム差分等を指定できる //
			); // IHDR(イメージヘッダ)の設定。必ず設定しなければならないパラメータを指定する。 //
			png_write_info( png_ptr, info_ptr );
			png_write_image( png_ptr, image ); // イメージを実際に書き出す。これは png_write_rows を連続して呼び出してくれる関数 //
			png_write_end( png_ptr, info_ptr );
			png_destroy_write_struct( &png_ptr, &info_ptr ); // 使い終わった png_ptr と info_ptr を破棄する //
			fclose( fp );
			tempData = [NSData dataWithContentsOfFile:@"/tmp/SketchyDrawTemp.png"];
			return tempData;
			// pngLength = [tempData length];
			fileData = (unsigned char *)malloc(pngLength * sizeof(unsigned char));
			[tempData getBytes:fileData];
			base64data = (unsigned char *)malloc((4 * ((pngLength + 2) / 3) + 1) * sizeof(unsigned char));
			enclode(fileData,pngLength,base64data);
			rStr = [NSString stringWithCString:base64data];
			free(base64data);
			free(fileData);
			free(image);
			unlink("/tmp/SketchyDrawTemp.png");
			return rStr; //
		}
	}
} */

NSString *imageRepToBase64(NSBitmapImageRep *imageRep)
// SVGはimage/svg+xml;であるが適用外。SVGのimageエレメントへ書き込む為の関数。pngを優先する。 //
{
	NSString *prefix = @"image/png;base64,";
	NSData *representation;
	CGFloat factor;

	NS_DURING
	representation = [imageRep representationUsingType:NSPNGFileType properties:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:NSImageInterlaced]]; // どこかのlibpngを読んでいるがどこだか分からない。libpngのバージョンによりCGImageDestinationFinalize failed for output type 'public.png'という警告メッセージが出されることがある。昔のtiffデータなどで発生する。NSImageInterlacedのほかにNSImageGamma:NSNumber(float)も使える。 //
	NS_HANDLER
	representation = nil; /* representation = imageRepToPNG(imageRep);とすれば，絵になるときもあるが大体駄目である。BMP,PCXなどで駄目になる。 */
	NS_ENDHANDLER
	if (nil == representation) {
		factor = 0.5; // 数値が大きいほど高画質，大容量 //
		prefix = @"image/jpeg;base64,";
		NS_DURING
		representation = [imageRep representationUsingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:factor] forKey:NSImageCompressionFactor]];
		NS_HANDLER
		representation = nil;
		NS_ENDHANDLER
	}
	if (nil == representation) {
		factor = 0.8;
		prefix = @"image/tiff;base64,";
		NS_DURING
		representation = [imageRep TIFFRepresentationUsingCompression:NSTIFFCompressionLZW factor:factor]; // SVGの仕様外。大概の場合，例外発生しないがAdobe SVGViewerでは表示されない。 //
		NS_HANDLER
		representation = nil;
		NS_ENDHANDLER
	}
	if (nil == representation) {
		prefix = @"image/gif;base64,";
		NS_DURING
		representation = [imageRep representationUsingType:NSGIFFileType properties:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:[imageRep hasAlpha]],NSImageDitherTransparency,nil,nil,[imageRep valueForProperty:NSImageRGBColorTable],NSImageRGBColorTable,nil]]; // SVGの仕様外。大概の場合，例外発生しないが非常に汚い。Adobe SVGViewerで表示可能。 //
		NS_HANDLER
		representation = nil;
		NS_ENDHANDLER
	}
	if (nil != representation) {
		NSMutableString *rStr = [NSMutableString stringWithString:prefix];
		NSString *base64Encode = enclode(representation);

		if (nil != base64Encode)
			[rStr appendString:base64Encode];
		return rStr;
	}
	else
		return nil;
}

CGImageAlphaInfo GetAlphaInfoFromBitmapImageRep(NSBitmapImageRep *theRep)
{
	if (YES == [theRep hasAlpha]) {
		NSBitmapFormat format = [theRep bitmapFormat];
		if (format & NSAlphaFirstBitmapFormat) {
			if (format & NSAlphaNonpremultipliedBitmapFormat)
				return kCGImageAlphaFirst;
			else
				return kCGImageAlphaPremultipliedFirst;
		}
		else {
			if (format & NSAlphaNonpremultipliedBitmapFormat)
				return kCGImageAlphaLast;
			else
				return kCGImageAlphaPremultipliedLast;
		}
	}
	else
		return kCGImageAlphaNone;
}
/* CGContextRef CreateCGBitmapContextWithColorProfile(size_t width,size_t height,CMProfileRef profile,CGImageAlphaInfo alphaInfo)
// CocoaDrawingGuideに掲載されている例を基にした。 //
{
    size_t bytesPerRow = 0;
    size_t alphaComponent = 0;
    // Get the type of the color space.
    CMAppleProfileHeader header;
    if (noErr != CMGetProfileHeader(profile, &header))
        return NULL;
    // Add 1 channel if there is an alpha component.
    if (alphaInfo != kCGImageAlphaNone)
        alphaComponent = 1;
    // Check the major color spaces.
    OSType space = header.cm2.dataColorSpace;
    switch (space)
    {
        case cmGrayData:
            bytesPerRow = width;
            // Quartz doesn’t support alpha for grayscale bitmaps.
            alphaInfo = kCGImageAlphaNone;
            break;
        case cmRGBData:
            bytesPerRow = width * (3 + alphaComponent);
            break;
        case cmCMYKData:
            bytesPerRow = width * 4;
            // Quartz doesn’t support alpha for CMYK bitmaps.
            alphaInfo = kCGImageAlphaNone;
            break;
        default:
            break;
    }
    // Allocate the memory for the bitmap.
	if (0 < bytesPerRow) {
		// Get the color space info from the profile.
		CGColorSpaceRef csRef = CGColorSpaceCreateWithPlatformColorSpace(profile);
		if (csRef == NULL)
			return NULL;
		else {
			void *bitmapData = malloc(bytesPerRow * height);
			CGContextRef theRef = CGBitmapContextCreate(bitmapData,width,height,8,bytesPerRow,csRef,alphaInfo);
			// Cleanup if an error occurs; otherwise, the caller is responsible
			// for releasing the bitmap data.
			if ((!theRef) && bitmapData)
				free(bitmapData);
			CGColorSpaceRelease(csRef);
			return theRef;
		}
	}
	else
		return NULL;
} */
/* CGImageRef convertBitmapImageRep(NSBitmapImageRep *theRep, NSColorSpace *colorspace)
{
	if (nil == theRep)
		return nil;
	CGImageAlphaInfo alphaInfo = GetAlphaInfoFromBitmapImageRep(theRep); // CocoaのbitmapFormatが返した値をQuartzにマップする。 //
	NSSize imageSize = [theRep size]; // イメージの情報を得る。 //
	size_t width = imageSize.width;
	size_t height = imageSize.height;
	CMProfileRef profile = (CMProfileRef)[colorspace colorSyncProfile];
	CGContextRef cgContext = CreateCGBitmapContextWithColorProfile(width,height, profile, alphaInfo); // イメージの情報に基づく8ビットのビットマップを作る。Create a new 8-bit bitmap context based on the image info.
	if (NULL == cgContext)
		return nil;
	NSGraphicsContext *graphicsContext = [NSGraphicsContext graphicsContextWithGraphicsPort:cgContext flipped:NO]; // NSGraphicsContextを作る。 //
	[NSGraphicsContext saveGraphicsState];
	[NSGraphicsContext setCurrentContext:graphicsContext]; // NSGraphicsContextをcurrentにする。 //
	NSImage *theImage = [[[NSImage alloc] initWithSize:imageSize] autorelease];
	[theImage addRepresentation:theRep];
	NSRect imageRect = NSMakeRect(0.0,0.0,imageSize.width,imageSize.height);
	[theImage drawAtPoint:NSMakePoint(0.0,0.0) fromRect:imageRect operation:NSCompositeSourceOver fraction:1.0];
	[NSGraphicsContext restoreGraphicsState];
	CGImageRef cgImage = CGBitmapContextCreateImage(cgContext); // CGContextの内容からCGImgeを作成。 //
	CGContextRelease(cgContext); // コンテキストを解放。ビットマップデータを解放しないこと。 //
	return cgImage;
} */
NSImage *imageFromCGImageRef(CGImageRef image)
{
    NSRect imageRect = NSMakeRect(0.0, 0.0, 0.0, 0.0);
    CGContextRef imageContext = nil;
    NSImage* newImage = nil;
 
    // Get the image dimensions.
    imageRect.size.height = CGImageGetHeight(image);
    imageRect.size.width = CGImageGetWidth(image);
 
    // Create a new image to receive the Quartz image data.
    newImage = [[NSImage alloc] initWithSize:imageRect.size];
    [newImage lockFocus];
 
    // Get the Quartz context and draw.
    imageContext = (CGContextRef)[[NSGraphicsContext currentContext]
                                         graphicsPort];
    CGContextDrawImage(imageContext, *(CGRect*)&imageRect, image);
    [newImage unlockFocus];
 
    return newImage;
}
NSBitmapImageRep *rgbToCMYKImageRep(NSBitmapImageRep *theRep, NSColorSpace *colorSpace)
{
	if (nil == theRep)
		return nil;
	else {
		unsigned char **bitmapData = (unsigned char **)NULL;
		NSInteger newSamplesPerPixel = 5;
		NSBitmapImageRep *cmykImageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:bitmapData pixelsWide:[theRep pixelsWide] pixelsHigh:[theRep pixelsHigh] bitsPerSample:8 samplesPerPixel:newSamplesPerPixel hasAlpha:YES isPlanar:NO colorSpaceName:NSDeviceCMYKColorSpace bitmapFormat:0 bytesPerRow:0 bitsPerPixel:8 * newSamplesPerPixel];
		NSInteger x,y;
		NSUInteger a;
		NSUInteger pix[4],newPix[newSamplesPerPixel];
		CGFloat kr,kg,kb,k;
		CGFloat ff = 0xff;
		NSInteger pixelsWide = [theRep pixelsWide];
		NSInteger pixelsHigh = [theRep pixelsHigh];
		/* BOOL hasAlpha = [theRep hasAlpha]; */ // alphaありと決め打ち //
		NSInteger spp = [theRep samplesPerPixel]; // 4と決め打ち //
		NSBitmapFormat bitmapFormat = [theRep bitmapFormat];
		BOOL alphaFirst = (bitmapFormat & NSAlphaFirstBitmapFormat) ? YES : NO;
		/* BOOL alphaNonpremultiplied = (bitmapFormat & NSAlphaNonpremultipliedBitmapFormat) ? YES : NO;
		BOOL floatingPointSamples = (bitmapFormat & NSFloatingPointSamplesBitmapFormat) ? YES : NO; */

		for (y = 0; y < pixelsHigh; y++) {
			for (x = 0; x < pixelsWide; x++) {
				[theRep getPixel:pix atX:x y:y];
				if (NO == alphaFirst) {
					a = pix[spp -1];
					k = kr = 0xff - pix[0];
					kg = 0xff - pix[1];
					kb = 0xff - pix[2];
				}
				else {
					a = pix[0];
					k = kr = 0xff - pix[1];
					kg = 0xff - pix[2];
					kb = 0xff - pix[3];
				}
				if (k > kg)
					k = kg;
				if (k > kb)
					k = kb;
				if (0xff == k) {
					newPix[0] = newPix[1] = newPix[2] = 0xff;
				}
				else {
					newPix[0] = ff * (kr - k) / (ff - k);
					newPix[1] = ff * (kg - k) / (ff - k);
					newPix[2] = ff * (kb - k) / (ff - k);
				}
				newPix[3] = k;
				newPix[4] = a;
				[cmykImageRep setPixel:newPix atX:x y:y];
			}
		}
		[cmykImageRep setProperty:NSImageColorSyncProfileData withValue:[colorSpace ICCProfileData]];
		/* for (y = 0; y < pixelsHigh; y++) {
			for (x = 0; x < pixelsWide; x++) {
				theColor = [[theRep colorAtX:x y:y] colorWithAlphaComponent:1.0];
				newColor = [theColor colorUsingColorSpaceName:NSDeviceCMYKColorSpace];
				[cmykImageRep setColor:newColor atX:x y:y];
			}
		} */
		return [cmykImageRep autorelease];
	}
}
NSBitmapImageRep *colorToGrayImageRep(NSBitmapImageRep *theRep)
// 色合いの調整はcolorizeByMappingGrayに任せてある。ここでやっていることはSamplesPerPixelを減らすだけ。 //
{
	if (nil == theRep)
		return nil;
	else {
			[theRep colorizeByMappingGray:0.5 toColor:[NSColor grayColor] blackMapping:[NSColor blackColor] whiteMapping:[NSColor whiteColor]]; // It works on images with 8-bit SPP, and thus supports either 8-bit gray or 24-bit color (with optional alpha).  alpha付きのRGBだとRGB kCGImageAlphaOnlyとなる。 //
			BOOL hasAlpha = [theRep hasAlpha];
			unsigned char **bitmapData = (unsigned char **)NULL;
			NSInteger newSamplesPerPixel = [theRep samplesPerPixel] - 2;
			NSBitmapImageRep *monoImageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:bitmapData pixelsWide:[theRep pixelsWide] pixelsHigh:[theRep pixelsHigh] bitsPerSample:8 samplesPerPixel:newSamplesPerPixel hasAlpha:(0 == newSamplesPerPixel % 2) ? YES : NO isPlanar:NO colorSpaceName:NSCalibratedWhiteColorSpace bitmapFormat:0 bytesPerRow:0 bitsPerPixel:8 * newSamplesPerPixel];
			NSInteger x,y;
			NSUInteger a;
			NSUInteger pix[4],newPix[newSamplesPerPixel];
			NSBitmapFormat bitmapFormat = [theRep bitmapFormat];
			NSInteger spp = [theRep samplesPerPixel];
			NSInteger pixelsWide = [theRep pixelsWide];
			NSInteger pixelsHigh = [theRep pixelsHigh];
			BOOL alphaFirst = (bitmapFormat & NSAlphaFirstBitmapFormat) ? YES : NO;
			/* BOOL alphaNonpremultiplied = (bitmapFormat & NSAlphaNonpremultipliedBitmapFormat) ? YES : NO;
			BOOL floatingPointSamples = (bitmapFormat & NSFloatingPointSamplesBitmapFormat) ? YES : NO; */

			for (y = 0; y < pixelsHigh; y++) {
				for (x = 0; x < pixelsWide; x++) {
					[theRep getPixel:pix atX:x y:y];
					if (YES == hasAlpha) {
						a = (NO == alphaFirst) ? pix[spp -1] : pix[0];
						newPix[0] = pix[1];
						newPix[1] = a;
					}
					else
						newPix[0] = pix[1];
					[monoImageRep setPixel:newPix atX:x y:y]; // これが長時間を要する。 //
				}
			}
			return [monoImageRep autorelease];
	}
}
NSBitmapImageRep *colorToMonoImageRep(NSBitmapImageRep *theRep, NSTIFFCompression compress)
// 色合いの調整はcolorizeByMappingGrayに任せてある。グレー値の0x7fを閾値として白と黒とに変換し1-bitの2値データにする。 //
{
	if (nil == theRep)
		return nil;
	else { // bitmapDataを使っての演算はOS10.4からは不可能である。 //
			[theRep colorizeByMappingGray:0.5 toColor:[NSColor grayColor] blackMapping:[NSColor blackColor] whiteMapping:[NSColor whiteColor]]; // It works on images with 8-bit SPP, and thus supports either 8-bit gray or 24-bit color (with optional alpha).  alpha付きのRGBだとRGB kCGImageAlphaOnlyとなる。 //
			NSString *colorName;
			NSUInteger black,white;
			if ((NSTIFFCompressionCCITTFAX3 == compress) || (NSTIFFCompressionCCITTFAX4 == compress)) {
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6
				colorName = NSCalibratedWhiteColorSpace;
#else
				colorName = NSCalibratedBlackColorSpace; // AVAILABLE_MAC_OS_X_VERSION_10_0_AND_LATER_BUT_DEPRECATED_IN_MAC_OS_X_VERSION_10_6 //
#endif
				black = 1;
				white = 0;
			}
			else {
				colorName = NSCalibratedWhiteColorSpace;
				black = 0;
				white = 1;
			}
			BOOL hasAlpha = [theRep hasAlpha];
			unsigned char **bitmapData = (unsigned char **)NULL;
			NSInteger newSamplesPerPixel = 1;
			NSBitmapImageRep *monoImageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:bitmapData pixelsWide:[theRep pixelsWide] pixelsHigh:[theRep pixelsHigh] bitsPerSample:1 samplesPerPixel:newSamplesPerPixel hasAlpha:NO isPlanar:NO colorSpaceName:colorName bitmapFormat:0 bytesPerRow:0 bitsPerPixel:1 * newSamplesPerPixel];
			NSInteger x,y;
			NSUInteger a;
			NSUInteger pix[4],newPix[newSamplesPerPixel];
			NSBitmapFormat bitmapFormat = [theRep bitmapFormat];
			NSInteger spp = [theRep samplesPerPixel];
			NSInteger pixelsWide = [theRep pixelsWide];
			NSInteger pixelsHigh = [theRep pixelsHigh];
			BOOL alphaFirst = (bitmapFormat & NSAlphaFirstBitmapFormat) ? YES : NO;
			/* BOOL alphaNonpremultiplied = (bitmapFormat & NSAlphaNonpremultipliedBitmapFormat) ? YES : NO;
			BOOL floatingPointSamples = (bitmapFormat & NSFloatingPointSamplesBitmapFormat) ? YES : NO; */

			for (y = 0; y < pixelsHigh; y++) {
				for (x = 0; x < pixelsWide; x++) {
					[theRep getPixel:pix atX:x y:y];
					if (YES == hasAlpha) {
						a = (NO == alphaFirst) ? pix[spp -1] : pix[0];
						if ((0x7f > a) || (0x7f < pix[1]))
							newPix[0] = white;
						else
							newPix[0] = black;
					}
					else
						newPix[0] = (0x7f < pix[1]) ? white : black;
					[monoImageRep setPixel:newPix atX:x y:y];
				}
			}
			return [monoImageRep autorelease];
	}
}
