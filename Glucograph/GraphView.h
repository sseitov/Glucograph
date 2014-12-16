//
//  GraphView.h
//  Glucograph
//
//  Created by Sergey Seitov on 17.03.13.
//  Copyright (c) 2013 Sergey Seitov. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GraphView : UIView {
	
	CGColorSpaceRef rgb;
	CGGradientRef	gradient;
	
	NSMutableArray *dates;
	NSMutableArray *morningVals;
	NSMutableArray *eveningVals;
	int morningCount;
	int eveningCount;
	
	float minValue;
	float maxValue;
}

- (void)setDateInterval:(NSArray*)interval;

@end
