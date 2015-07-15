//
//  AXTableViewCellCachedHeight.h
//  AXTableViewCellCachedHeight
//
//  Created by ai on 15/7/6.
//  Copyright © 2015年 ai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol AXCacheDelegate;

@interface AXCache : NSObject

@property (assign, nonatomic, nullable) id<AXCacheDelegate>delegate;

@property NSUInteger countLimit;

@property BOOL evictsObjectsWithDiscardedContent;

@property (readonly, nonatomic, nullable) NSArray *allKeys;

- (nullable id)objectForKey:(id <NSCopying> __nonnull)key;

- (void)setObject:(id __nonnull)obj forKey:(id <NSCopying> __nonnull)key; // 0 cost

- (void)removeObjectForKey:(id <NSCopying> __nonnull)key;

- (void)removeAllObjects;

@end

@protocol AXCacheDelegate <NSObject>

@optional
- (void)cache:(AXCache * __nonnull)cache willEvictObject:(id __nonnull)obj forKey:(id <NSCopying> __nonnull)key;
@end

typedef id __nonnull (^AXIndexPathCacheBlock)(UITableView * __nonnull tableView, NSIndexPath * __nonnull indexPath);

NS_CLASS_AVAILABLE_IOS(7_0)
@interface AXIndexPathCache : NSObject
{
    @private
    NSInteger _predictedMultiple;
}
#pragma mark - Properties

@property (assign, nonatomic) NSInteger predictedMultiple;//default : 5

@property (assign, nonatomic, getter=isDebugLogEnabled) BOOL debugLogEnable;//default : NO

@property (readonly, nonatomic, getter=isProcessing) BOOL processing;

@property (assign, nonatomic, getter=isTracingEnabled) BOOL tracingEnabled;//default : YES

#pragma mark - Public
/**
 * @brief Get a instance type of the indexPath cache
 *
 * @param tableView a table view to attach
 *
 * @return a instance object of AXIndexPathCache
 */
- (nonnull instancetype)initWithTableView:(UITableView * __nullable)tableView;
/**
 * @brief Ensure the object at index path with a given identifier cached or not
 *
 * @param indexPath a indexPath the object should be
 * @param identifier a identifier view the object should identity
 *
 * @return YES if the object has been cached, otherwise NO
 */
- (BOOL)ax_cachedObjectAtIndexPath:(NSIndexPath * __nonnull)indexPath forIdentifier:(NSString * __nonnull)identifier;
/**
 * @brief Async cache the object. The identifier and the cacheBlock should not be nil.
 *
 * @param identifier a identifier view the object should identity
 * @param cacheBlock a cacheBlock to cache the object and must return a value
 *
 * @return None
 */
- (void)ax_asyncCacheWithIdentifier:(NSString * __nonnull)identifier cacheBlock:(AXIndexPathCacheBlock __nonnull)cacheBlock;
/**
 * @brief Get the cached object, if there is a cached object then return the one, or will retun a new one using cacheBlock
 *
 * @param indexPath a indexPath the object should be
 * @param identifier a identifier view the object should identity
 *
 * @return a cached object
 */
- (id __nonnull)ax_objectAtIndexPath:(NSIndexPath * __nonnull)indexPath forIdentifier:(NSString * __nonnull)identifier;
/**
 * @brief To fire the cache, this will update the visible indexPaths, and cache the objects if need
 *
 */
- (void)ax_fireCache;
/**
 * @brief To fire the cache if need, run on the main thread when the run loop is going to sleep
 *
 */
- (void)ax_fireCacheIfNeed;
/**
 * @brief Invalid the cache and clear the cache
 *
 */
- (void)ax_cacheInvalid:(BOOL)invalid;

#pragma mark - Actions
- (void)ax_deleteRowsAtIndexPaths:(NSArray * __nullable)indexPaths forIdentifier:(NSString * __nonnull)identifier;

- (void)ax_insertRowsAtIndexPaths:(NSArray * __nullable)indexPaths forIdentifier:(NSString * __nonnull)identifier;

- (void)ax_recacheRowsAtIndexPaths:(NSArray * __nullable)indexPaths forIdentifier:(NSString * __nonnull)identifier;

- (void)ax_moveRowAtIndexPath:(NSIndexPath * __nonnull)indexPath toIndexPath:(NSIndexPath * __nonnull)newIndexPath forIdentifier:(NSString * __nonnull)identifier;


- (void)ax_deleteSections:(NSIndexSet * __nullable)sections forIdentifier:(NSString * __nonnull)identifier;

- (void)ax_insertSections:(NSIndexSet * __nullable)sections forIdentifier:(NSString * __nonnull)identifier;

- (void)ax_recacheSections:(NSIndexSet * __nullable)sections forIdentifier:(NSString * __nonnull)identifier;

- (void)ax_moveSection:(NSInteger)section toSection:(NSInteger)newSection forIdentifier:(NSString * __nonnull)identifier;
@end
