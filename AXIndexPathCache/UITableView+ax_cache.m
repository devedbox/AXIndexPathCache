//
//  UITableView+ax_cache.m
//  AXCellCacheDemo
//
//  Created by ai on 15/7/15.
//  Copyright © 2015年 ai. All rights reserved.
//

#import "UITableView+ax_cache.h"
#import <objc/runtime.h>

@interface UITableView ()
@property (readonly, nonatomic) AXIndexPathCache *heightCache;
@property (readonly, nonatomic) AXIndexPathCache *cellCache;
@end

@implementation UITableView (ax_cache)

- (double)ax_heightAtIndexPath:(NSIndexPath * __nonnull)indexPath
                 forIdentifier:(NSString * __nonnull)identifier
                 configuration:(AXIndexPathCacheConfiguration __nonnull)configuration
                         cache:(AXIndexPathCacheBlock __nonnull)cache
{
    if (configuration) {
        
        configuration (self.heightCache);
    }
    
    static dispatch_once_t heightOnceToken;
    dispatch_once(&heightOnceToken, ^{
        [self.heightCache ax_asyncCacheWithIdentifier:identifier
                                         cacheBlock:cache];
    });
    
    NSNumber *height = [self.heightCache ax_objectAtIndexPath:indexPath
                                                forIdentifier:identifier];
    return [height doubleValue];
}

- (UITableViewCell * __nonnull)ax_cellAtIndexPath:(NSIndexPath * __nonnull)indexPath
                                    forIdentifier:(NSString * __nonnull)identifier
                                    configuration:(AXIndexPathCacheConfiguration __nonnull)configuration
                                            cache:(AXIndexPathCacheBlock __nonnull)cache
{
    if (configuration) {
        
        configuration (self.cellCache);
    }
    
    static dispatch_once_t cellOnceToken;
    dispatch_once(&cellOnceToken, ^{
        [self.cellCache ax_asyncCacheWithIdentifier:identifier
                                         cacheBlock:cache];
    });
    
    UITableViewCell *cell = [self.cellCache ax_objectAtIndexPath:indexPath
                                                   forIdentifier:identifier];
    return cell;
}
#pragma mark - Actions
- (void)ax_deleteRowsAtIndexPaths:(NSArray * __nonnull)indexPaths withRowAnimation:(UITableViewRowAnimation)animation forIdentifier:(NSString * __nonnull)identifier
{
    [self.heightCache ax_deleteRowsAtIndexPaths:[indexPaths copy] forIdentifier:identifier];
    
    [self.cellCache ax_deleteRowsAtIndexPaths:[indexPaths copy] forIdentifier:identifier];
    
    [self deleteRowsAtIndexPaths:indexPaths withRowAnimation:animation];
}

- (void)ax_insertRowsAtIndexPaths:(NSArray * __nullable)indexPaths withRowAnimation:(UITableViewRowAnimation)animation forIdentifier:(NSString * __nonnull)identifier
{
    [self.heightCache ax_insertRowsAtIndexPaths:[indexPaths copy] forIdentifier:identifier];
    
    [self.cellCache ax_insertRowsAtIndexPaths:[indexPaths copy] forIdentifier:identifier];
    
    [self deleteRowsAtIndexPaths:indexPaths withRowAnimation:animation];
}

- (void)ax_reloadRowsAtIndexPaths:(NSArray * __nullable)indexPaths withRowAnimation:(UITableViewRowAnimation)animation forIdentifier:(NSString * __nonnull)identifier
{
    [self.heightCache ax_recacheRowsAtIndexPaths:[indexPaths copy] forIdentifier:identifier];
    
    [self.cellCache ax_recacheRowsAtIndexPaths:[indexPaths copy] forIdentifier:identifier];
    
    [self reloadRowsAtIndexPaths:indexPaths withRowAnimation:animation];
}

- (void)ax_moveRowAtIndexPath:(NSIndexPath * __nonnull)indexPath withRowAnimation:(UITableViewRowAnimation)animation toIndexPath:(NSIndexPath * __nonnull)newIndexPath forIdentifier:(NSString * __nonnull)identifier
{
    [self.heightCache ax_moveRowAtIndexPath:indexPath toIndexPath:newIndexPath forIdentifier:identifier];
    
    [self.cellCache ax_moveRowAtIndexPath:indexPath toIndexPath:newIndexPath forIdentifier:identifier];
    
    [self moveRowAtIndexPath:indexPath toIndexPath:newIndexPath];
}


- (void)ax_deleteSections:(NSIndexSet * __nullable)sections withRowAnimation:(UITableViewRowAnimation)animation forIdentifier:(NSString * __nonnull)identifier
{
    [self.heightCache ax_deleteSections:[sections copy] forIdentifier:identifier];
    
    [self.cellCache ax_deleteSections:[sections copy] forIdentifier:identifier];
    
    [self deleteSections:sections withRowAnimation:animation];
}

- (void)ax_insertSections:(NSIndexSet * __nullable)sections withRowAnimation:(UITableViewRowAnimation)animation forIdentifier:(NSString * __nonnull)identifier
{
    [self.heightCache ax_insertSections:[sections copy] forIdentifier:identifier];
    
    [self.cellCache ax_insertSections:[sections copy] forIdentifier:identifier];
    
    [self insertSections:sections withRowAnimation:animation];
}

- (void)ax_reloadSections:(NSIndexSet * __nullable)sections withRowAnimation:(UITableViewRowAnimation)animation forIdentifier:(NSString * __nonnull)identifier
{
    [self.heightCache ax_recacheSections:[sections copy] forIdentifier:identifier];
    
    [self.cellCache ax_recacheSections:[sections copy] forIdentifier:identifier];
    
    [self reloadSections:sections withRowAnimation:animation];
}

- (void)ax_moveSection:(NSInteger)section toSection:(NSInteger)newSection withRowAnimation:(UITableViewRowAnimation)animation forIdentifier:(NSString * __nonnull)identifier
{
    [self.heightCache ax_moveSection:section toSection:newSection forIdentifier:identifier];
    
    [self.cellCache ax_moveSection:section toSection:newSection forIdentifier:identifier];
    
    [self moveSection:section toSection:newSection];
}

#pragma mark - Getters
- (AXIndexPathCache *)heightCache {
    id object = objc_getAssociatedObject(self, _cmd);
    
    if (object) {
        
        return object;
    } else {
        
        AXIndexPathCache *cache = [[AXIndexPathCache alloc] initWithTableView:self];
        
        objc_setAssociatedObject(self, _cmd, cache, OBJC_ASSOCIATION_RETAIN);
        
        return cache;
    }
}

- (AXIndexPathCache *)cellCache {
    id object = objc_getAssociatedObject(self, _cmd);
    
    if (object) {
        
        return object;
    } else {
        
        AXIndexPathCache *cache = [[AXIndexPathCache alloc] initWithTableView:self];
        
        objc_setAssociatedObject(self, _cmd, cache, OBJC_ASSOCIATION_RETAIN);
        
        return cache;
    }
}
@end