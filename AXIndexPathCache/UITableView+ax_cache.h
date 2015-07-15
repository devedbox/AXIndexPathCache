//
//  UITableView+ax_cache.h
//  AXCellCacheDemo
//
//  Created by ai on 15/7/15.
//  Copyright © 2015年 ai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AXIndexPathCache.h"

typedef void(^AXIndexPathCacheConfiguration)(AXIndexPathCache * __nonnull cache);

@interface UITableView (ax_cache)

- (double)ax_heightAtIndexPath:(NSIndexPath * __nonnull)indexPath
                 forIdentifier:(NSString * __nonnull)identifier
                 configuration:(AXIndexPathCacheConfiguration __nonnull)configuration
                         cache:(AXIndexPathCacheBlock __nonnull)cache;

- (UITableViewCell * __nonnull)ax_cellAtIndexPath:(NSIndexPath * __nonnull)indexPath
                                    forIdentifier:(NSString * __nonnull)identifier
                                    configuration:(AXIndexPathCacheConfiguration __nonnull)configuration
                                            cache:(AXIndexPathCacheBlock __nonnull)cache;

- (void)ax_deleteRowsAtIndexPaths:(NSArray * __nonnull)indexPaths withRowAnimation:(UITableViewRowAnimation)animation forIdentifier:(NSString * __nonnull)identifier;

- (void)ax_insertRowsAtIndexPaths:(NSArray * __nullable)indexPaths withRowAnimation:(UITableViewRowAnimation)animation forIdentifier:(NSString * __nonnull)identifier;

- (void)ax_reloadRowsAtIndexPaths:(NSArray * __nullable)indexPaths withRowAnimation:(UITableViewRowAnimation)animation forIdentifier:(NSString * __nonnull)identifier;

- (void)ax_moveRowAtIndexPath:(NSIndexPath * __nonnull)indexPath withRowAnimation:(UITableViewRowAnimation)animation toIndexPath:(NSIndexPath * __nonnull)newIndexPath forIdentifier:(NSString * __nonnull)identifier;


- (void)ax_deleteSections:(NSIndexSet * __nullable)sections withRowAnimation:(UITableViewRowAnimation)animation forIdentifier:(NSString * __nonnull)identifier;

- (void)ax_insertSections:(NSIndexSet * __nullable)sections withRowAnimation:(UITableViewRowAnimation)animation forIdentifier:(NSString * __nonnull)identifier;

- (void)ax_reloadSections:(NSIndexSet * __nullable)sections withRowAnimation:(UITableViewRowAnimation)animation forIdentifier:(NSString * __nonnull)identifier;

- (void)ax_moveSection:(NSInteger)section toSection:(NSInteger)newSection withRowAnimation:(UITableViewRowAnimation)animation forIdentifier:(NSString * __nonnull)identifier;
@end
