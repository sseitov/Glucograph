//
//  BloodViewController.h
//  Glucograph
//
//  Created by Sergey Seitov on 07.04.14.
//  Copyright (c) 2014 Sergey Seitov. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BloodViewController;

@protocol BloodControllerDelegate <NSObject>

- (void)bloodControllerChangeData:(BloodViewController*)controller;
- (void)bloodControllerDidFinish:(BloodViewController*)controller;

@end

@interface BloodViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate, UITextViewDelegate> {
    
	IBOutlet UIPickerView *valuePicker;
    IBOutlet UILabel* morning;
    IBOutlet UILabel* evening;
	IBOutlet UITextView *comment;
    IBOutlet UISegmentedControl* command;
    IBOutlet UIToolbar* toolbar;
}

@property (strong, nonatomic) NSDate* setupDate;
@property (weak, nonatomic) id<BloodControllerDelegate> delegate;

- (IBAction)dataChanged:(UISegmentedControl*)sender;

@end
