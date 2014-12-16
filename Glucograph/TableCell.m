//
//  TableCell.m
//  Glucograph
//
//  Created by Sergey Seitov on 17.03.13.
//  Copyright (c) 2013 Sergey Seitov. All rights reserved.
//

#import "TableCell.h"
#import "StorageManager.h"

@implementation TableCell

- (IBAction)showComment
{
    [self.delegate showCommentFor:_cellDate];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	
    [[StorageManager sharedStorageManager] setComment:textField.text forDate:_cellDate];
}

@end
