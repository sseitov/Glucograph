//
//  GraphView.m
//  Glucograph
//
//  Created by Sergey Seitov on 17.03.13.
//  Copyright (c) 2013 Sergey Seitov. All rights reserved.
//

#import "GraphView.h"
#import "StorageManager.h"

static NSString* textFromDate(NSDate *date) {
	
	NSString *result =  [NSDateFormatter localizedStringFromDate:date
										  dateStyle:NSDateFormatterShortStyle
										  timeStyle:NSDateFormatterNoStyle];
	NSCharacterSet *charSet = [NSCharacterSet characterSetWithCharactersInString:@"./"];
	NSArray *comps = [result componentsSeparatedByCharactersInSet:charSet];
	if (comps.count > 1) {
		return [NSString stringWithFormat:@"%@/%@", [comps objectAtIndex:0], [comps objectAtIndex:1]];
	} else {
		return @"";
	}
}

@implementation GraphView

- (void)setup {
	
	rgb = CGColorSpaceCreateDeviceRGB();
	CGFloat colors[] =
	{
		128.0 / 255.0, 128.0 / 255.0, 128.0 / 255.0, 1.00,
		164.0 / 255.0, 164.0 / 255.0, 164.0 / 255.0, 1.00,
		206.0 / 255.0, 206.0 / 255.0, 206.0 / 255.0, 1.00,
	};
	gradient = CGGradientCreateWithColorComponents(rgb, colors, NULL, sizeof(colors)/(sizeof(colors[0])*4));
	dates = [[NSMutableArray alloc] init];
	morningVals = [[NSMutableArray alloc] init];
	eveningVals = [[NSMutableArray alloc] init];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:155.0/255.0 green:169.0/255.0 blue:186.0/255.0 alpha:1.0];
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		[self setup];
    }
    return self;
}

- (void)awakeFromNib {
	
	[self setup];
}

- (void)dealloc {
	
	CGGradientRelease(gradient);
	CGColorSpaceRelease(rgb);
}

void getMinMax(NSNumber *num, float *min, float *max) {
	
	float val = [num floatValue];
	if (val < 0) {
		return;
	}
	if (val < *min) {
		*min = val;
	}
	if (val > *max) {
		*max = val;
	}
}

- (void)setDateInterval:(NSArray*)interval {
	
	[dates removeAllObjects];
	[dates addObjectsFromArray:interval];
	[morningVals removeAllObjects];
	[eveningVals removeAllObjects];
	morningCount = 0;
	eveningCount = 0;
	for (NSDate *date in dates) {
		Blood *blood = [[StorageManager sharedStorageManager] getBloodForDate:date];
		if (blood) {
			if (blood.morning > 0) {
				[morningVals addObject:[NSNumber numberWithFloat:blood.morning]];
				morningCount++;
			} else {
				[morningVals addObject:[NSNumber numberWithFloat:-1]];
			}
			if (blood.evening > 0) {
				[eveningVals addObject:[NSNumber numberWithFloat:blood.evening]];
				eveningCount++;
			} else {
				[eveningVals addObject:[NSNumber numberWithFloat:-1]];
			}
		} else {
			[morningVals addObject:[NSNumber numberWithFloat:-1]];
			[eveningVals addObject:[NSNumber numberWithFloat:-1]];
		}
	}
	minValue = 10000;
	maxValue = 0;
	if (morningCount > 0) {
		for (NSNumber *val in morningVals) {
			getMinMax(val, &minValue, &maxValue);
		}
	}
	if (eveningCount > 0) {
		for (NSNumber *val in eveningVals) {
			getMinMax(val, &minValue, &maxValue);
		}
	}
//	NSLog(@"MIN %f MAx %f", minValue, maxValue);
	[self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
	rect.origin.x = 40;
	rect.size.width -= 50;
	rect.size.height -= 20;
	
    CGContextRef context = UIGraphicsGetCurrentContext();
	
	// create bubble clip path
	CGFloat radius = 10.0;
	CGFloat minx = CGRectGetMinX(rect), midx = CGRectGetMidX(rect), maxx = CGRectGetMaxX(rect);
	CGFloat miny = CGRectGetMinY(rect), midy = CGRectGetMidY(rect), maxy = CGRectGetMaxY(rect);
	CGContextMoveToPoint(context, minx, midy);
	CGContextAddArcToPoint(context, minx, miny, midx, miny, radius);
	CGContextAddArcToPoint(context, maxx, miny, maxx, midy, radius);
	CGContextAddArcToPoint(context, maxx, maxy, midx, maxy, radius);
	CGContextAddArcToPoint(context, minx, maxy, minx, midy, radius);
	CGContextClosePath(context);
	
	// draw bubble with gradient
	CGContextSaveGState(context);
	CGContextClip(context);
	CGContextDrawLinearGradient(context, gradient, CGPointMake(0, 0), CGPointMake(0, rect.size.height), 0);
	CGContextRestoreGState(context);
	
	if (!dates.count) {
		return;
	}
	
// draw grid
	
	CGPoint originPt = CGPointMake(50, rect.size.height-10);
	const CGPoint maxyPt = CGPointMake(50, 10);
	const CGPoint maxxPt = CGPointMake(rect.size.width + 30, rect.size.height-10);
	
	UIBezierPath *line = [UIBezierPath bezierPath];
	[line setLineWidth:1];
	[[UIColor whiteColor] setStroke];
	[[UIColor darkGrayColor] set];
	UIFont *axisFont = [UIFont fontWithName:@"Helvetica-Bold" size:12];
	
	[line moveToPoint:CGPointMake(originPt.x-5, originPt.y)];
	[line addLineToPoint:CGPointMake(maxxPt.x+5, maxxPt.y)];
	[line moveToPoint:CGPointMake(originPt.x, originPt.y+5)];
	[line addLineToPoint:CGPointMake(originPt.x, maxyPt.y-5)];
	
	float valStepX = (maxxPt.x - originPt.x)/(dates.count-1);
	int skipIndex = (int)dates.count/7;
	
	float lastX = 0.0;
	for (int i=0; i<7; i++) {
		[line moveToPoint:CGPointMake(maxxPt.x-valStepX*skipIndex*i, originPt.y+5)];
		[line addLineToPoint:CGPointMake(maxxPt.x-valStepX*skipIndex*i, maxyPt.y-5)];
		NSString *str = textFromDate([dates objectAtIndex:i*skipIndex]);
		lastX = maxxPt.x-valStepX*skipIndex*i;
		[str drawAtPoint:CGPointMake(lastX-15, originPt.y+10) withFont:axisFont];
	}
	if (dates.count > 7 && (lastX - originPt.x) > 30) {
		NSString *str = textFromDate([dates lastObject]);
		[str drawAtPoint:CGPointMake(originPt.x-15, originPt.y+10) withFont:axisFont];
	}
	[line stroke];

	if (morningCount == 0 && eveningCount == 0) {
		return;
	}
	
	UIBezierPath *dashLine = [UIBezierPath bezierPath];
	CGFloat dash[2] = {4, 4};
	[dashLine setLineDash:dash count:2 phase:0];
	float gridStepY = (maxyPt.y - originPt.y)/11.0;
	float gridDelta = (maxValue - minValue)/10.0;
	
	[@"0" drawAtPoint:CGPointMake(originPt.x-20, originPt.y - 7) withFont:[UIFont fontWithName:@"Helvetica-Bold" size:14]];
	
	if (maxValue == minValue) {
		[dashLine moveToPoint:CGPointMake(originPt.x-5, originPt.y+gridStepY*11)];
		[dashLine addLineToPoint:CGPointMake(maxxPt.x+5, originPt.y+gridStepY*11)];
		NSString *str = [NSString stringWithFormat:@"%.2f", minValue + gridDelta*11];
		[str drawAtPoint:CGPointMake(originPt.x-40, originPt.y+gridStepY*11 - 5) withFont:axisFont];
	} else {
		for (int i=1; i<=11; i++) {
			[dashLine moveToPoint:CGPointMake(originPt.x-5, originPt.y+gridStepY*i)];
			[dashLine addLineToPoint:CGPointMake(maxxPt.x+5, originPt.y+gridStepY*i)];
			NSString *str = [NSString stringWithFormat:@"%.2f", minValue + gridDelta*(i-1)];
			[str drawAtPoint:CGPointMake(originPt.x-40, originPt.y+gridStepY*i - 5) withFont:axisFont];
		}
		originPt.y += gridStepY;
	}
	[dashLine stroke];
	
	float valZoom = (maxValue == minValue) ? 0 : (originPt.y - maxyPt.y)/(maxValue - minValue);
		
	if (morningCount > 0) {
		UIBezierPath *morningLine = [UIBezierPath bezierPath];
		morningLine.lineWidth = 4;
		[[UIColor blueColor] setStroke];
		
		BOOL start = NO;
		for (int i = 0; i < morningVals.count; i++) {
			float val = [[morningVals objectAtIndex:i] floatValue];
			CGPoint pt = CGPointMake(maxxPt.x-valStepX*i, maxyPt.y+valZoom*(maxValue - val));
			if (!start) {
				if (val > 0) {
					[morningLine moveToPoint:pt];
					start = YES;
				}
				continue;
			}
			if (val > 0) {
				[morningLine addLineToPoint:pt];
			}
		}
		[morningLine stroke];
	}
	
	if (eveningCount > 0) {
		UIBezierPath *eveningLine = [UIBezierPath bezierPath];
		eveningLine.lineWidth = 4;
		[[UIColor purpleColor] setStroke];
		
		BOOL start = NO;
		for (int i = 0; i < eveningVals.count; i++) {
			float val = [[eveningVals objectAtIndex:i] floatValue];
			CGPoint pt = CGPointMake(maxxPt.x-valStepX*i, maxyPt.y+valZoom*(maxValue - val));
			if (!start) {
				if (val > 0) {
					[eveningLine moveToPoint:pt];
					start = YES;
				}
				continue;
			}
			if (val > 0) {
				[eveningLine addLineToPoint:pt];
			}
		}
		[eveningLine stroke];
	}
}

@end
