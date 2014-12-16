//
//  ViewController.h
//  Glucograph
//
//  Created by Sergey Seitov on 07.04.14.
//  Copyright (c) 2014 Sergey Seitov. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TableCell.h"
#import "BloodViewController.h"

NSString* LOCALIZE(NSString *key);

@interface ViewController : UITableViewController
<UITextFieldDelegate, UIPopoverControllerDelegate, TableCellDelegate, BloodControllerDelegate>

- (void)updateDateInterval;

@end
