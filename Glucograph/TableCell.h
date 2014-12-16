//
//  TableCell.h
//  Glucograph
//
//  Created by Sergey Seitov on 17.03.13.
//  Copyright (c) 2013 Sergey Seitov. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RowTextField.h"

@protocol TableCellDelegate <NSObject>

- (void)showCommentFor:(NSDate*)date;

@end

@interface TableCell : UITableViewCell <UITextFieldDelegate>

@property (weak, nonatomic) id<TableCellDelegate> delegate;

@property (strong, nonatomic) NSDate *cellDate;

@property (strong, nonatomic) IBOutlet UILabel* date;
@property (strong, nonatomic) IBOutlet UILabel* morning;
@property (strong, nonatomic) IBOutlet UILabel* evening;
@property (strong, nonatomic) IBOutlet UIButton* commentButton;
@property (strong, nonatomic) IBOutlet RowTextField* comment;

- (IBAction)showComment;

@end
