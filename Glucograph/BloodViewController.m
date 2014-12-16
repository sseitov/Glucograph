//
//  BloodViewController.m
//  Glucograph
//
//  Created by Sergey Seitov on 07.04.14.
//  Copyright (c) 2014 Sergey Seitov. All rights reserved.
//

#import "BloodViewController.h"
#import "StorageManager.h"

@interface BloodViewController ()

@end

@implementation BloodViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	self.title = [NSDateFormatter localizedStringFromDate:self.setupDate
												dateStyle:NSDateFormatterLongStyle
												timeStyle:NSDateFormatterNoStyle];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
		self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
																							  target:self
																							  action:@selector(done)];
        if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) {
            self.navigationItem.leftBarButtonItem.tintColor = [UIColor whiteColor];
        }
    }
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
                                                                                           target:self
                                                                                           action:@selector(clear)];
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1)
    {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            command.tintColor = [UIColor whiteColor];
            self.navigationItem.rightBarButtonItem.tintColor = [UIColor whiteColor];
        } else {
            morning.textColor = [UIColor blueColor];
            evening.textColor = [UIColor magentaColor];
        }
    } else {
        if ([[UIDevice currentDevice] userInterfaceIdiom] != UIUserInterfaceIdiomPhone) {
            toolbar.barStyle = UIBarStyleBlackOpaque;
        }
    }
    
    Blood *blood = [[StorageManager sharedStorageManager] getBloodForDate:self.setupDate];
	if (blood && blood.morning > 0) {
		[self selectRowForPicker:valuePicker forValue:blood.morning animated:NO];
	} else {
		[valuePicker selectRow:32 inComponent:0 animated:NO];
		[valuePicker selectRow:9 inComponent:1 animated:NO];
	}
	if (blood) {
		morning.text = [NSString stringWithFormat:@"%.1f", blood.morning];
		evening.text = [NSString stringWithFormat:@"%.1f", blood.evening];
		if (blood.comment) {
			comment.text = blood.comment;
		}
	} else {
		morning.text = @"0.0";
		evening.text = @"0.0";
	}

}

- (float)getValueFromPicker:(UIPickerView*)picker
{
	UILabel *l1 = (UILabel*)[picker viewForRow:[picker selectedRowInComponent:0] forComponent:0];
	UILabel *l2 = (UILabel*)[picker viewForRow:[picker selectedRowInComponent:1] forComponent:1];
	NSString *strVal = [l1.text stringByAppendingString:l2.text];
	return [strVal floatValue];
}

- (void)selectRowForPicker:(UIPickerView*)picker forValue:(float)value animated:(BOOL)animated
{
    int integer = value;
    int fract = round((value - integer)*10);
    [picker selectRow:(33 - integer) inComponent:0 animated:animated];
    [picker selectRow:(10 - fract - 1) inComponent:1 animated:animated];
}

- (void)done
{
	[self.delegate bloodControllerDidFinish:self];
}

- (void)clear
{
	morning.text = @"0.0";
	evening.text = @"0.0";
    comment.text = @"";
	[[StorageManager sharedStorageManager] removeBloodForDate:_setupDate];
	[self.delegate bloodControllerChangeData:self];
}

- (IBAction)dataChanged:(UISegmentedControl*)sender
{
    float val = [self getValueFromPicker:valuePicker];
    if (sender.selectedSegmentIndex) {
        evening.text = [NSString stringWithFormat:@"%.1f", val];
        [[StorageManager sharedStorageManager] setEveningBlood:val forDate:self.setupDate];
    } else {
        morning.text = [NSString stringWithFormat:@"%.1f", val];
        [[StorageManager sharedStorageManager] setMorningBlood:val forDate:self.setupDate];
    }
	[self.delegate bloodControllerChangeData:self];
}

#pragma mark - UIPickerView delegate

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    
	return 2;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    
	if (component == 0) {
		return 33;
	} else {
		return 10;
	}
}

- (UIView *)pickerView:(UIPickerView *)pickerView
			viewForRow:(NSInteger)row
		  forComponent:(NSInteger)component
		   reusingView:(UIView *)view
{
	UILabel *label = (UILabel*)view;
	if (!label) {
		label = [[UILabel alloc] initWithFrame:CGRectZero];
		label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		label.backgroundColor = [UIColor clearColor];
		label.font = [UIFont fontWithName:@"Helvetica-Bold" size:24];
	}
	
	if (component == 0) {
		label.textAlignment = NSTextAlignmentCenter;
		label.text = [NSString stringWithFormat:@"%d", (int)(33 - row)];
	} else {
		label.textAlignment = NSTextAlignmentCenter;
		label.text = [NSString stringWithFormat:@".%d", (int)(10 - (row+1))];
	}
	
	return label;
}

#pragma mark - UITextView delegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
	
    if([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }
    return YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    [[StorageManager sharedStorageManager] setComment:comment.text forDate:self.setupDate];
	[self.delegate bloodControllerChangeData:self];
}

@end
