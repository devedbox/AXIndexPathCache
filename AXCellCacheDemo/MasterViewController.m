//
//  MasterViewController.m
//  AXCellCacheDemo
//
//  Created by ai on 15/7/9.
//  Copyright © 2015年 ai. All rights reserved.
//

#import "MasterViewController.h"
#import "DetailViewController.h"
#import "NSDate+Category.h"

#import "UITableView+ax_cache.h"

@interface MasterViewController ()
@property NSMutableArray *objects;
@property (strong, nonatomic) UIBarButtonItem *leftItem;
@property (weak, nonatomic) UISwitch *switchBtn;
@end

@implementation MasterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    if (!self.objects) {
        self.objects = [[NSMutableArray alloc] init];
    }
    for (NSInteger i = 0; i < 100; i ++) {
        [self.objects insertObject:[NSDate date] atIndex:0];
    }
    self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:0.294f green:0.808f blue:0.478f alpha:1.00f];
    self.navigationItem.leftBarButtonItem = self.leftItem;

    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject:)];
    self.navigationItem.rightBarButtonItem = addButton;
    self.detailViewController = (DetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
}

- (void)viewWillAppear:(BOOL)animated {
    self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIBarButtonItem *)leftItem {
    if (_leftItem) return _leftItem;
    UISwitch *switchBtn = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
    [switchBtn addTarget:self
                  action:@selector(switchBtn:)
        forControlEvents:UIControlEventValueChanged];
    switchBtn.on = YES;
    _leftItem = [[UIBarButtonItem alloc] initWithCustomView:switchBtn];
    _switchBtn = switchBtn;
    return _leftItem;
}

- (void)insertNewObject:(id)sender {
    if (!self.objects) {
        self.objects = [[NSMutableArray alloc] init];
    }
    [self.objects insertObject:[NSDate date] atIndex:0];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView ax_insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic forIdentifier:@"AXCell"];
}

- (void)insertNewSection {
    
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSDate *object = self.objects[indexPath.row];
        DetailViewController *controller = (DetailViewController *)[[segue destinationViewController] topViewController];
        [controller setDetailItem:object];
        controller.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
        controller.navigationItem.leftItemsSupplementBackButton = YES;
    }
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.objects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [tableView ax_cellAtIndexPath:indexPath
                           forIdentifier:@"AXCell"
                           configuration:^(AXIndexPathCache * __nonnull cache) {
                               cache.debugLogEnable = YES;
                               [cache ax_cacheInvalid:!_switchBtn.on];
                           } cache:^id __nonnull(UITableView * __nonnull tableView, NSIndexPath * __nonnull indexPath) {
#if TARGET_IPHONE_SIMULATOR
                               for (NSInteger i = 0; i < 1000; i ++) {
                                   NSString *dateStr = @"";
                                   NSDate *date = [NSDate date];
                                   NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                                   formatter.dateFormat = @"YYYYMMDD-hh:mm:ss";
                                   dateStr = [formatter stringFromDate:date];
                               }
#else
                               for (NSInteger i = 0; i < 100; i ++) {
                                   NSString *dateStr = @"";
                                   NSDate *date = [NSDate date];
                                   NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                                   formatter.dateFormat = @"YYYYMMDD-hh:mm:ss";
                                   dateStr = [formatter stringFromDate:date];
                               }
#endif
                               UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AXCell"];
                               NSDate *object = self.objects[indexPath.row];
                               cell.textLabel.text = [NSString stringWithFormat:@"%@+No.%ld",[object timeIntervalDescription], indexPath.row];
                               return cell;
                           }];
}

- (CGFloat)tableView:(nonnull UITableView *)tableView heightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    return [tableView ax_heightAtIndexPath:indexPath
                             forIdentifier:@"AXCell"
                             configuration:^(AXIndexPathCache * __nonnull cache) {
                                 cache.debugLogEnable = YES;
                                 [cache ax_cacheInvalid:!_switchBtn.on];
                             } cache:^id __nonnull(UITableView * __nonnull tableView, NSIndexPath * __nonnull indexPath) {
#if TARGET_IPHONE_SIMULATOR
                                 for (NSInteger i = 0; i < 1000; i ++) {
                                     NSString *dateStr = @"";
                                     NSDate *date = [NSDate date];
                                     NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                                     formatter.dateFormat = @"YYYYMMDD-hh:mm:ss";
                                     dateStr = [formatter stringFromDate:date];
                                 }
#else
                                 for (NSInteger i = 0; i < 100; i ++) {
                                     NSString *dateStr = @"";
                                     NSDate *date = [NSDate date];
                                     NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                                     formatter.dateFormat = @"YYYYMMDD-hh:mm:ss";
                                     dateStr = [formatter stringFromDate:date];
                                 }
#endif
                                 return @(44.f + indexPath.row * 3);
                             }];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.objects removeObjectAtIndex:indexPath.row];
        [tableView ax_deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade forIdentifier:@"AXCell"];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}

#pragma mark - Switch
- (void)switchBtn:(UISwitch *)sender {
}
@end
