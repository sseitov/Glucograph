//
//  ViewController.m
//  Glucograph
//
//  Created by Sergey Seitov on 07.04.14.
//  Copyright (c) 2014 Sergey Seitov. All rights reserved.
//

#import "ViewController.h"
#import "GraphView.h"
#import "StorageManager.h"
#import "AppDelegate.h"
#import "RowTextField.h"

NSString* LOCALIZE(NSString *key) {
	
	return [[NSBundle mainBundle] localizedStringForKey:key value:@"" table:nil];
}

@interface ViewController ()

@property (nonatomic, strong) UISegmentedControl *segmentedControl;
@property (nonatomic, strong) UIPopoverController *popover;

@property (strong, nonatomic) NSMutableArray *dateInterval;
@property (strong, nonatomic) GraphView *graphView;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _dateInterval = [[NSMutableArray alloc] init];
    _graphView = [[GraphView alloc] initWithFrame:CGRectZero];
    
	NSArray *items = [NSArray arrayWithObjects:
					  [NSString stringWithFormat:@"1 %@", LOCALIZE(@"week")],
					  [NSString stringWithFormat:@"4 %@", LOCALIZE(@"weeks ")],
					  [NSString stringWithFormat:@"8 %@", LOCALIZE(@"weeks")],
					  [NSString stringWithFormat:@"16 %@", LOCALIZE(@"weeks")], nil];
	
	_segmentedControl = [[UISegmentedControl alloc] initWithItems:items];
	_segmentedControl.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	_segmentedControl.selectedSegmentIndex = 0;
	_segmentedControl.momentary = NO;
	_segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) {
        _segmentedControl.tintColor = [UIColor whiteColor];
    }
	[_segmentedControl addTarget:self action:@selector(updateDateInterval) forControlEvents:UIControlEventValueChanged];
	self.navigationItem.titleView = _segmentedControl;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(doSynchro)];
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) {
        self.navigationItem.rightBarButtonItem.tintColor = [UIColor whiteColor];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	[self updateDateInterval];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	if (_popover) {
		[_popover dismissPopoverAnimated:NO];
		_popover = nil;
	}
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	if (_graphView) {
		[_graphView setNeedsDisplay];
	}
}

- (void)updateDateInterval {
	
	NSCalendar *calendar = [NSCalendar currentCalendar];
	NSDateComponents *components = [calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit)
											   fromDate:[NSDate date]];
	NSDate *currentDate = [calendar dateFromComponents:components];
	int numDays = 0;
	switch (_segmentedControl.selectedSegmentIndex) {
		case 0:
			numDays = 7;
			break;
		case 1:
			numDays = 28;
			break;
		case 2:
			numDays = 56;
			break;
		case 3:
			numDays = 112;
			break;
		default:
			break;
	}
	NSDateComponents *day = [[NSDateComponents alloc] init];
	[_dateInterval removeAllObjects];
	for (int days = 0; days < numDays; days++) {
		[day setDay:-days];
		NSDate *nextDate = [calendar dateByAddingComponents:day toDate:currentDate options:0];
		[_dateInterval addObject:nextDate];
	}
	[self.tableView reloadData];
	if (_graphView) {
		[_graphView setDateInterval:_dateInterval];
	}
}

- (BOOL)isLandscape {
    
	return UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]);
}

#pragma mark - UITableView delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return _dateInterval.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
		if ([self isLandscape]) {
            if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) {
                return self.view.frame.size.height - 65.0;
            } else {
                return self.view.frame.size.height;
            }
		} else {
			return 200.0;
		}
	} else {
		if ([self isLandscape]) {
            return 400;
        } else {
            return 650;
        }
	}
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    return _graphView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	
	static NSString *cellIdentifier = @"TableCell";
	TableCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (!cell) {
        NSLog(@"ERROR LOAD TABLE CELL");
        return nil;
	}
	NSDate *date = [_dateInterval objectAtIndex:indexPath.row];
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		cell.date.text = [NSDateFormatter localizedStringFromDate:date
														dateStyle:NSDateFormatterLongStyle
														timeStyle:NSDateFormatterNoStyle];
	} else {
        cell.accessoryType = UITableViewCellAccessoryNone;
		cell.date.text = [NSDateFormatter localizedStringFromDate:date
														dateStyle:NSDateFormatterFullStyle
														timeStyle:NSDateFormatterNoStyle];
	}
	Blood *blood = [[StorageManager sharedStorageManager] getBloodForDate:date];
    if (blood.morning > 0) {
        cell.morning.text = [NSString stringWithFormat:@"%.1f", blood.morning];
    } else {
        cell.morning.text = @"";
    }
    if (blood.evening > 0) {
        cell.evening.text = [NSString stringWithFormat:@"%.1f", blood.evening];
    } else {
        cell.evening.text = @"";
    }
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        cell.delegate = self;
        if (blood.comment.length > 0) {
            cell.commentButton.hidden = NO;
        } else {
            cell.commentButton.hidden = YES;
        }
    } else {
        cell.comment.indexPath = indexPath;
        cell.comment.delegate = self;
        cell.comment.text = blood.comment;
        cell.comment.placeholder = LOCALIZE(@"Type comments");
    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.backgroundColor = [UIColor colorWithRed:155.0/255.0 green:169.0/255.0 blue:186.0/255.0 alpha:1.0];
	cell.cellDate = date;
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        return;
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main_iPad" bundle:nil];
    BloodViewController *next = [storyboard instantiateViewControllerWithIdentifier:@"BloodViewController"];
	next.setupDate = [_dateInterval objectAtIndex:indexPath.row];
	next.delegate = self;
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
		[self.navigationController pushViewController:next animated:YES];
	} else {
		UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
		CGRect rc = cell.bounds;
		rc.origin.x = rc.size.width - 130;
		rc.size.width = 20;
		UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:next];
		_popover = [[UIPopoverController alloc] initWithContentViewController:navController];
		_popover.delegate = self;
		_popover.popoverContentSize = CGSizeMake(320, 294);
		[_popover presentPopoverFromRect:rc inView:cell permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
	}
}

- (void)showCommentFor:(NSDate*)date
{
    Blood * blood = [[StorageManager sharedStorageManager] getBloodForDate:date];
	if (blood && blood.comment && blood.comment.length > 0) {
		NSString *when = [NSDateFormatter localizedStringFromDate:date
														dateStyle:NSDateFormatterLongStyle
														timeStyle:NSDateFormatterNoStyle];
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:when
														message:blood.comment
													   delegate:nil
											  cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
		[alert show];
	}
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    TableCell* cell = (TableCell*)sender;
    BloodViewController* controller = (BloodViewController*)segue.destinationViewController;
    controller.setupDate = cell.cellDate;
    controller.delegate = self;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    _graphView.hidden = YES;
    RowTextField* row = (RowTextField*)textField;
    [self.tableView selectRowAtIndexPath:row.indexPath animated:YES scrollPosition:UITableViewScrollPositionTop];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    _graphView.hidden = NO;
    RowTextField* row = (RowTextField*)textField;
    TableCell* cell = (TableCell*)[self.tableView cellForRowAtIndexPath:row.indexPath];
    [[StorageManager sharedStorageManager] setComment:textField.text forDate:cell.cellDate];
    if (row.indexPath) {
        [self.tableView deselectRowAtIndexPath:row.indexPath animated:YES];
    }
}

- (void)bloodControllerChangeData:(BloodViewController*)controller
{
	[self.tableView reloadData];
    [_graphView setDateInterval:_dateInterval];
}

- (void)bloodControllerDidFinish:(BloodViewController*)controller
{
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
		[self.navigationController popViewControllerAnimated:YES];
	} else {
		[_popover dismissPopoverAnimated:YES];
		_popover = nil;
	}
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
	_popover = nil;
}

- (void)doSynchro
{
    AppDelegate* app = (AppDelegate*)[UIApplication sharedApplication].delegate;
    if ([app iCloudSynchro]) {
        [self.tableView reloadData];
        [_graphView setDateInterval:_dateInterval];
    }
}

@end
