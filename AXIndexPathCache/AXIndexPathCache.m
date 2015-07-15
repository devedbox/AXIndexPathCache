//
//  AXTableViewCellCachedHeight.m
//  AXTableViewCellCachedHeight
//
//  Created by ai on 15/7/6.
//  Copyright © 2015年 ai. All rights reserved.
//

#import "AXIndexPathCache.h"

@interface AXCache ()
{
    NSMutableDictionary *_cache;
    NSMutableArray *_sortedKeys;
    dispatch_queue_t _evictsQueue;
}
@end

@interface AXIndexPathCache () <AXCacheDelegate>
{
    NSMutableDictionary *_cachedObjects;
    NSMutableArray *_cachedIndexPaths;
    NSIndexPath *_topIndexPath;
    NSIndexPath *_bottomIndexPath;
    BOOL _invalid;
}

/// Table view
@property (weak, nonatomic, nullable) UITableView *tableView;
/// Cached indexPaths
@property (strong, atomic, nullable) NSMutableArray *cachedIndexPaths;
/// The visibleIndexPaths of table view
@property (strong, nonatomic, nullable) NSArray *visibleIndexPaths;
/// RunLoop observer run in main loop
@property (readonly, nonatomic, nullable) CFRunLoopObserverRef mainRunLoopObserver;
/// Cached objects
@property (strong, atomic, nullable) NSMutableDictionary *cachedObjects;
/// Cache queue
@property (strong, nonatomic, nonnull) dispatch_queue_t cacheQueue;
/// Cache block
@property (copy, nonatomic, nonnull) AXIndexPathCacheBlock cacheBlock;
/// RunLoop run in cache queue
@property (readonly, nonatomic, nullable) CFRunLoopRef cacheRunLoop;
/// RunLoop source of the cache queue runLoop
@property (readonly, nonatomic, nullable) CFRunLoopSourceRef runLoopSource;
/// RunLoop observer run in the cache queue runLoop
@property (readonly, nonatomic, nullable) CFRunLoopObserverRef runLoopObserver;
/// The identifier of caching indexPaths
@property (copy, nonatomic, nonnull) NSString *cachingIdentifier;

@end

@implementation AXIndexPathCache
@synthesize
cacheRunLoop = _cacheRunLoop,
runLoopSource = _runLoopSource,
runLoopObserver = _runLoopObserver,
mainRunLoopObserver = _mainRunLoopObserver;

#pragma mark - LifeCycle
- (instancetype)init {
    if (self = [super init]) {
        
        [self initializer];
    }
    return self;
}

- (nonnull instancetype)initWithTableView:(UITableView * __nullable)tableView {
    if (self = [super init]) {
        
        _tableView = tableView;
        
        [self initializer];
    }
    return self;
}

- (void)initializer {
    _debugLogEnable = NO;
    _invalid = NO;
    _predictedMultiple = 5;
    _tracingEnabled = YES;
    
    _cachedIndexPaths = [NSMutableArray array];
    _cachedObjects = [NSMutableDictionary dictionary];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ax_clearCache) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}

- (void)dealloc {
    
    CFRunLoopRemoveSource(_cacheRunLoop, _runLoopSource, kCFRunLoopDefaultMode);
    CFRunLoopRemoveObserver(_cacheRunLoop, _runLoopObserver, kCFRunLoopDefaultMode);
    
    CFRelease(_runLoopSource);
    CFRelease(_runLoopObserver);
    
    CFRunLoopStop(_cacheRunLoop);
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Override
- (void)observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary *)change context:(nullable void *)context
{
    if ([keyPath isEqualToString:@"visibleIndexPaths"]) {
        [self updateCacheConfiguration];
        
        NSIndexPath *top = (NSIndexPath *)[_visibleIndexPaths firstObject];
        _topIndexPath = [NSIndexPath indexPathForRow:top.row - 1 inSection:top.section];
        NSIndexPath *bottom = (NSIndexPath *)[_visibleIndexPaths lastObject];
        _bottomIndexPath = [NSIndexPath indexPathForRow:bottom.row + 1 inSection:bottom.section];
        
        @autoreleasepool {
            if (_cacheRunLoop) {
                
                if (!CFRunLoopContainsSource(_cacheRunLoop, self.runLoopSource, kCFRunLoopDefaultMode)) {
                    CFRunLoopAddSource(_cacheRunLoop, self.runLoopSource, kCFRunLoopDefaultMode);
                }
                
                if (!CFRunLoopContainsObserver(_cacheRunLoop, self.runLoopObserver, kCFRunLoopDefaultMode)) {
                    CFRunLoopAddObserver(_cacheRunLoop, self.runLoopObserver, kCFRunLoopDefaultMode);
                }
                
                CFRunLoopSourceSignal(_runLoopSource);
                CFRunLoopWakeUp(_cacheRunLoop);
            }
        }
    }
}

#pragma mark - Getters

- (dispatch_queue_t __nonnull)cacheQueue {
    
    if (_cacheQueue) return _cacheQueue;
    _cacheQueue = dispatch_queue_create("com.ax_tableView.caching", 0);
    return _cacheQueue;
}

- (CFRunLoopSourceRef __nullable)runLoopSource {
    
    if (_runLoopSource) return _runLoopSource;
    
    CFRunLoopSourceContext context =
    
    {
        0,
        (__bridge void *)(self),
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        &ax_runLoopSourceScheduleRoutine,
        &ax_runLoopSourceCancelRoutine,
        &ax_runLoopSourcePerformRoutine
    };
    
    _runLoopSource = CFRunLoopSourceCreate(kCFAllocatorDefault, 0, &context);
    
    return _runLoopSource;
}


- (CFRunLoopObserverRef __nullable)runLoopObserver {
    
    if (_runLoopObserver) return _runLoopObserver;
    
    _runLoopObserver = CFRunLoopObserverCreateWithHandler(
                                                          kCFAllocatorDefault,
                                                          kCFRunLoopBeforeWaiting,
                                                          true,
                                                          0,
                                                          ^(CFRunLoopObserverRef observer, CFRunLoopActivity activity)
    {
        if (_visibleIndexPaths.count == 0 || ![self shouldProccess]) {
            CFRunLoopRemoveObserver(_cacheRunLoop, _runLoopObserver, kCFRunLoopDefaultMode);
        } else {
            if (!CFRunLoopContainsObserver(_cacheRunLoop, self.runLoopObserver, kCFRunLoopDefaultMode)) {
                CFRunLoopContainsObserver(_cacheRunLoop, self.runLoopObserver, kCFRunLoopDefaultMode);
            }
            CFRunLoopSourceSignal(_runLoopSource);
            CFRunLoopWakeUp(_cacheRunLoop);
        }
    });
    
    return _runLoopObserver;
}

- (CFRunLoopObserverRef __nullable)mainRunLoopObserver {
    
    if (_mainRunLoopObserver) return _mainRunLoopObserver;
    
    _mainRunLoopObserver = CFRunLoopObserverCreateWithHandler(
                                                          kCFAllocatorDefault,
                                                          kCFRunLoopBeforeWaiting,
                                                          true,
                                                          0,
                                                          ^(CFRunLoopObserverRef observer, CFRunLoopActivity activity)
    {
        
        if (_tableView) {
            [self performSelectorOnMainThread:@selector(setVisibleIndexPaths:) withObject:_tableView.indexPathsForVisibleRows waitUntilDone:NO modes:@[NSDefaultRunLoopMode]];
        }
        
        CFRunLoopRemoveObserver(CFRunLoopGetMain(), _mainRunLoopObserver, kCFRunLoopDefaultMode);
    });
    
    return _mainRunLoopObserver;
}

#pragma mark - Setters

- (void)setPredictedMultiple:(NSInteger)predictedMultiple {
    
    _predictedMultiple = predictedMultiple;
    
    [self updateCacheConfiguration];
}

- (void)setVisibleIndexPaths:(NSArray * __nullable)visibleIndexPaths {
    
    _visibleIndexPaths = [visibleIndexPaths copy];
    
    [self updateCacheConfiguration];
    
    NSIndexPath *top = (NSIndexPath *)[_visibleIndexPaths firstObject];
    _topIndexPath = [NSIndexPath indexPathForRow:top.row - 1 inSection:top.section];
    NSIndexPath *bottom = (NSIndexPath *)[_visibleIndexPaths lastObject];
    _bottomIndexPath = [NSIndexPath indexPathForRow:bottom.row + 1 inSection:bottom.section];
    
    @autoreleasepool {
        if (_cacheRunLoop) {
            
            if (!CFRunLoopContainsSource(_cacheRunLoop, self.runLoopSource, kCFRunLoopDefaultMode)) {
                CFRunLoopAddSource(_cacheRunLoop, self.runLoopSource, kCFRunLoopDefaultMode);
            }
            
            if (!CFRunLoopContainsObserver(_cacheRunLoop, self.runLoopObserver, kCFRunLoopDefaultMode)) {
                CFRunLoopAddObserver(_cacheRunLoop, self.runLoopObserver, kCFRunLoopDefaultMode);
            }
            
            CFRunLoopSourceSignal(_runLoopSource);
            CFRunLoopWakeUp(_cacheRunLoop);
        }
    }
}

#pragma mark - Public

- (BOOL)isProcessing {
    if (_cacheRunLoop) {
        return !CFRunLoopIsWaiting(_cacheRunLoop);
    } else {
        return NO;
    }
}

- (void)ax_fireCache {
    if (!_invalid && !self.isProcessing && _tableView.isDecelerating && _tracingEnabled){
        self.visibleIndexPaths = _tableView.indexPathsForVisibleRows;
    }
}

- (void)ax_cacheInvalid:(BOOL)invalid {
    _invalid = invalid;
    
    if (invalid) {
        
        for (NSString *identifier in self.cachedObjects.allKeys) {
            
            NSMutableDictionary *sections = [self.cachedObjects objectForKey:identifier];
            
            for (NSNumber *number in [sections allKeys]) {
                
                AXCache *cache = [self cacheAtSection:[number integerValue] forIdentifier:identifier];
                
                if (!cache) continue;
                
                [cache removeAllObjects];
                
                [self setCache:cache atSection:[number integerValue] forIdentifier:identifier];
            }
        }
    }
}

- (void)ax_fireCacheIfNeed {
    
    if (!_invalid) {
        [self performSelectorOnMainThread:@selector(ax_fire) withObject:nil waitUntilDone:NO modes:@[NSDefaultRunLoopMode]];
        [self ax_fireCache];
    }
}

- (id __nonnull)ax_objectAtIndexPath:(NSIndexPath * __nonnull)indexPath forIdentifier:(NSString * __nonnull)identifier
{
//    CFRunLoopRemoveObserver(_cacheRunLoop, _runLoopObserver, kCFRunLoopDefaultMode);
    
    AXCache *cache = [self cacheAtSection:indexPath.section forIdentifier:identifier];
    
    if (!cache) {
        
        [self ax_fireCacheIfNeed];
        
        return self.cacheBlock (_tableView, indexPath);
        
    } else {
        
        id obj = [cache objectForKey:@(indexPath.row)];
        
        [cache removeObjectForKey:@(indexPath.row)];
        
        [_cachedIndexPaths removeObject:indexPath];
        
        if (!obj || _invalid) {
            
            obj = self.cacheBlock (_tableView, indexPath);
        }
        
        [self ax_fireCacheIfNeed];
        
        return obj;
    }
}

- (BOOL)ax_cachedObjectAtIndexPath:(NSIndexPath * __nonnull)indexPath forIdentifier:(NSString * __nonnull)identifier {
    
    BOOL flag = NO;
    
    AXCache *cache = [self cacheAtSection:indexPath.section forIdentifier:identifier];
    
    if (!cache) return NO;
    
    if ([cache objectForKey:@(indexPath.row)]) {
        
        flag = YES;
    }
    
    return flag;
}

- (void)ax_asyncCacheWithIdentifier:(NSString * __nonnull)identifier cacheBlock:(AXIndexPathCacheBlock __nonnull)cacheBlock
{
    _cachingIdentifier = identifier;
    
    _cacheBlock = [cacheBlock copy];
    
    dispatch_async(self.cacheQueue, ^{
        @autoreleasepool {
            
            _cacheRunLoop = CFRunLoopGetCurrent ();
            
            if (!CFRunLoopContainsSource(_cacheRunLoop, self.runLoopSource, kCFRunLoopDefaultMode)) {
                CFRunLoopAddSource(_cacheRunLoop, self.runLoopSource, kCFRunLoopDefaultMode);
            }
            
            if (!CFRunLoopContainsObserver(_cacheRunLoop, self.runLoopObserver, kCFRunLoopDefaultMode)) {
                CFRunLoopAddObserver(_cacheRunLoop, self.runLoopObserver, kCFRunLoopDefaultMode);
            }
            
            CFRunLoopRun();
            
            CFRunLoopSourceSignal(_runLoopSource);
            CFRunLoopWakeUp(_cacheRunLoop);
        }
    });
}

#pragma mark - Actions
- (void)ax_deleteRowsAtIndexPaths:(NSArray * __nullable)indexPaths forIdentifier:(NSString * __nonnull)identifier {
    
    for (NSIndexPath *indexPath in indexPaths) {
        
        AXCache *storedCache = [self cacheAtSection:indexPath.section forIdentifier:identifier];
        
        if (!storedCache) continue;
        
        [storedCache removeObjectForKey:@(indexPath.row)];
        
        NSArray *cachedKeys = [storedCache allKeys];
        
        for (NSInteger i = 0; i < cachedKeys.count; i ++) {
            
            NSNumber *cachedRow = cachedKeys[i];
            
            if ([cachedRow integerValue] <= indexPath.row) continue;
            
            id object = [storedCache objectForKey:cachedRow];
            
            [storedCache removeObjectForKey:cachedRow];
            
            if (!object) continue;
            
            [storedCache setObject:object forKey:@([cachedRow integerValue] - 1)];
        }
        
        [self setCache:storedCache atSection:indexPath.section forIdentifier:identifier];
    }
    
}

- (void)ax_insertRowsAtIndexPaths:(NSArray * __nullable)indexPaths forIdentifier:(NSString * __nonnull)identifier {
    
    for (NSIndexPath *indexPath in indexPaths) {
        
        AXCache *storedCache = [self cacheAtSection:indexPath.section forIdentifier:identifier];
        
        if (!storedCache) continue;
        
        NSArray *cachedKeys = [storedCache allKeys];
        
        for (NSInteger i = cachedKeys.count - 1; i >= 0; i --) {
            
            NSNumber *cachedRow = cachedKeys[i];
            
            if ([cachedRow integerValue] <= indexPath.row) continue;
            
            id object = [storedCache objectForKey:cachedRow];
            
            [storedCache removeObjectForKey:cachedRow];
            
            if (!object) continue;
            
            [storedCache setObject:object forKey:@([cachedRow integerValue] + 1)];
        }
        
        if ([self shouldCacheIndexPath:indexPath]) {
            
            id object = self.cacheBlock (_tableView, indexPath);
            
            [storedCache setObject:object forKey:@(indexPath.row)];
        }
        
        [self setCache:storedCache atSection:indexPath.section forIdentifier:identifier];
    }
}

- (void)ax_recacheRowsAtIndexPaths:(NSArray * __nullable)indexPaths forIdentifier:(NSString * __nonnull)identifier {
    
    for (NSIndexPath *indexPath in indexPaths) {
        
        AXCache *cache = [self cacheAtSection:indexPath.section forIdentifier:identifier];
        
        if (!cache || ![cache objectForKey:@(indexPath.row)] || ![self shouldCacheIndexPath:indexPath]) continue;
        
        id object = self.cacheBlock (_tableView, indexPath);
        
        [cache setObject:object forKey:@(indexPath.row)];
        
        [self setCache:cache atSection:indexPath.section forIdentifier:identifier];
    }
}

- (void)ax_moveRowAtIndexPath:(NSIndexPath * __nonnull)indexPath toIndexPath:(NSIndexPath * __nonnull)newIndexPath forIdentifier:(NSString * __nonnull)identifier
{
    
    AXCache *storedCache1 = [self cacheAtSection:indexPath.section forIdentifier:identifier];
    
    id object = [storedCache1 objectForKey:@(indexPath.row)];
    
    if (object) {
        
        [storedCache1 removeObjectForKey:@(indexPath.row)];
    }
    
    NSArray *cachedRows1 = storedCache1.allKeys;
    
    for (NSInteger i = 0; i < cachedRows1.count; i ++) {
        
        NSNumber *cachedRow = cachedRows1[i];
        
        if ([cachedRow integerValue] <= indexPath.row) continue;
        
        id object = [storedCache1 objectForKey:cachedRow];
        
        [storedCache1 removeObjectForKey:cachedRow];
        
        if (!object) continue;
        
        [storedCache1 setObject:object forKey:@([cachedRow integerValue] - 1)];
    }
    
    [self setCache:storedCache1 atSection:indexPath.section forIdentifier:identifier];
    
    AXCache *storedCache2 = [self cacheAtSection:newIndexPath.section forIdentifier:identifier];
    
    NSArray *cachedRows2 = storedCache2.allKeys;
    
    for (NSInteger i = cachedRows2.count - 1; i >= 0; i --) {
        
        NSNumber *cachedRow = cachedRows2[i];
        
        if ([cachedRow integerValue] <= indexPath.row) continue;
        
        id obj = [storedCache2 objectForKey:cachedRow];
        
        [storedCache2 removeObjectForKey:cachedRow];
        
        if (!obj) continue;
        
        [storedCache2 setObject:obj forKey:@([cachedRow integerValue] + 1)];
    }
    
    if ([storedCache2 objectForKey:@(newIndexPath.row)]) {
        
        if (!object && [self shouldCacheIndexPath:newIndexPath]) {
            
            object = self.cacheBlock (_tableView, newIndexPath);
        }
        
        [storedCache2 setObject:object forKey:@(indexPath.row)];
        
        [self setCache:storedCache2 atSection:indexPath.section forIdentifier:identifier];
    }
}

- (void)ax_deleteSections:(NSIndexSet * __nullable)sections forIdentifier:(NSString * __nonnull)identifier {
    
    NSUInteger currentIndex = [sections firstIndex];
    
    while (currentIndex != NSNotFound) {
        
        NSMutableDictionary *object = [self.cachedObjects objectForKey:identifier];
        
        if (![object objectForKey:@(currentIndex)]) continue;
        
        [object removeObjectForKey:@(currentIndex)];
        
        for (NSInteger i = currentIndex + 1; i < _tableView.numberOfSections; i ++) {
            
            AXCache *cache = [self cacheAtSection:i forIdentifier:identifier];
            
            if (!cache) continue;
            
            [object removeObjectForKey:@(i)];
            
            [object setObject:cache forKey:@(i - 1)];
        }
        
        [self.cachedObjects setObject:object forKey:identifier];
        
        currentIndex = [sections indexGreaterThanIndex:currentIndex];
    }
}

- (void)ax_insertSections:(NSIndexSet * __nullable)sections forIdentifier:(NSString * __nonnull)identifier {
    
    NSUInteger currentIndex = [sections firstIndex];
    
    while (currentIndex != NSNotFound) {
        
        NSMutableDictionary *object = [self.cachedObjects objectForKey:identifier];
        
        for (NSInteger i = _tableView.numberOfSections - 1; i >= currentIndex ; i --) {
            
            AXCache *cache = [self cacheAtSection:i forIdentifier:identifier];
            
            if (!cache) continue;
            
            [object removeObjectForKey:@(i)];
            
            [object setObject:cache forKey:@(i + 1)];
        }
        
        [self.cachedObjects setObject:object forKey:identifier];
        
        for (NSInteger i = 0; i < [_tableView numberOfRowsInSection:currentIndex]; i ++) {
            
            NSIndexPath *indexPathToInsert = [NSIndexPath indexPathForRow:i inSection:currentIndex];
            
            if ([self shouldCacheIndexPath:indexPathToInsert]) {
                
                id object = self.cacheBlock (_tableView, indexPathToInsert);
                
                AXCache *cache = [self cacheAtSection:currentIndex forIdentifier:identifier];
                
                if (!cache) cache = [self ax_cache];
                
                [cache setObject:object forKey:@(i)];
                
                [self setCache:cache atSection:currentIndex forIdentifier:identifier];
            }
        }
        
        currentIndex = [sections indexGreaterThanIndex:currentIndex];
    }
}

- (void)ax_recacheSections:(NSIndexSet * __nullable)sections forIdentifier:(NSString * __nonnull)identifier {
    
    NSUInteger currentIndex = [sections firstIndex];
    
    while (currentIndex != NSNotFound) {
        
        if (![self cacheAtSection:currentIndex forIdentifier:identifier]) continue;
        
        for (NSInteger i = 0; i < [_tableView numberOfRowsInSection:currentIndex]; i ++) {
            
            NSIndexPath *indexPathToInsert = [NSIndexPath indexPathForRow:i inSection:currentIndex];
            
            if ([self shouldCacheIndexPath:indexPathToInsert]) {
                
                id object = self.cacheBlock (_tableView, indexPathToInsert);
                
                AXCache *cache = [self cacheAtSection:currentIndex forIdentifier:identifier];
                
                if (!cache) cache = [self ax_cache];
                
                [cache setObject:object forKey:@(i)];
                
                [self setCache:cache atSection:currentIndex forIdentifier:identifier];
            }
        }
        
        currentIndex = [sections indexGreaterThanIndex:currentIndex];
    }
}

- (void)ax_moveSection:(NSInteger)section toSection:(NSInteger)newSection forIdentifier:(NSString * __nonnull)identifier {
    
    NSMutableDictionary *object = [self.cachedObjects objectForKey:identifier];
    
    if ([object objectForKey:@(section)]) {
        
        [object removeObjectForKey:@(section)];
    }
    
    for (NSInteger i = section + 1; i < _tableView.numberOfSections; i ++) {
        
        AXCache *cache = [self cacheAtSection:i forIdentifier:identifier];
        
        if (!cache) continue;
        
        [object removeObjectForKey:@(i)];
        
        [object setObject:cache forKey:@(i - 1)];
    }
    
    [self.cachedObjects setObject:object forKey:identifier];
    
    for (NSInteger i = _tableView.numberOfSections - 1; i > newSection ; i --) {
        
        AXCache *cache = [self cacheAtSection:i forIdentifier:identifier];
        
        if (!cache) continue;
        
        [object removeObjectForKey:@(i)];
        
        [object setObject:cache forKey:@(i + 1)];
    }
    
    [self.cachedObjects setObject:object forKey:identifier];
    
    if ([object objectForKey:@(newSection)]) {
        
        for (NSInteger i = 0; i < [_tableView numberOfRowsInSection:newSection]; i ++) {
            
            NSIndexPath *indexPathToInsert = [NSIndexPath indexPathForRow:i inSection:newSection];
            
            if ([self shouldCacheIndexPath:indexPathToInsert]) {
                
                id object = self.cacheBlock (_tableView, indexPathToInsert);
                
                AXCache *cache = [self cacheAtSection:newSection forIdentifier:identifier];
                
                if (!cache) cache = [self ax_cache];
                
                [cache setObject:object forKey:@(i)];
                
                [self setCache:cache atSection:newSection forIdentifier:identifier];
            }
        }
    }
}

#pragma mark - Pravite

/// Called when the runLoop source has been removed from the runLoop.
void ax_runLoopSourceCancelRoutine (void *info, CFRunLoopRef rl, CFStringRef mode)
{
    CFRunLoopStop(rl);
}

/// Called when the runLoop is waked up and do someting with the source
void ax_runLoopSourcePerformRoutine (void *info)
{
    AXIndexPathCache * __weak rlSelf = (__bridge AXIndexPathCache *)info;
    
    [rlSelf cacheObject];
}

/// Called when the source has been added to the runLoop
void ax_runLoopSourceScheduleRoutine (void *info, CFRunLoopRef rl, CFStringRef mode)
{
    AXIndexPathCache * __weak rlSelf = (__bridge AXIndexPathCache *)info;
    
    CFRunLoopSourceSignal(rlSelf.runLoopSource);
    CFRunLoopWakeUp(rl);
}

/// Clear cache
- (void)ax_clearCache {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
       
        [self ax_cacheInvalid:YES];
        
        [self ax_cacheInvalid:NO];
    });
}

/// Fire
- (void)ax_fire {
    
    if (!CFRunLoopContainsObserver(CFRunLoopGetMain(), self.mainRunLoopObserver, kCFRunLoopDefaultMode)) {
        
        CFRunLoopAddObserver(CFRunLoopGetMain (), self.mainRunLoopObserver, kCFRunLoopDefaultMode);
    }
}

/// Get the cache object with the common configuration
- (AXCache * __nonnull)ax_cache {
    
    AXCache *cache = [[AXCache alloc] init];
    
    cache.countLimit = _visibleIndexPaths.count * _predictedMultiple * 2;
    
    cache.delegate = self;
    
    return cache;
}

/// Cache the object
- (void)cacheObject {
    
    if (self.cacheBlock) {
        
        if ([self shouldCacheIndexPath:_topIndexPath]) {
            
            id object = self.cacheBlock (_tableView, _topIndexPath);
            
            AXCache *cache = [self cacheAtSection:_topIndexPath.section forIdentifier:_cachingIdentifier];
            
            if (!cache) {
                cache = [self ax_cache];
            }
            
            [cache setObject:object forKey:@(_topIndexPath.row)];
            
            [self setCache:cache atSection:_topIndexPath.section forIdentifier:_cachingIdentifier];
            
#if DEBUG
            if (_debugLogEnable) {
                NSLog(@"\n----------------------\nCached [%ld-%ld] object:%@\n----------------------\n", _topIndexPath.row, _topIndexPath.section, object);
            }
#endif
            
            _topIndexPath = [self forwardWithIndexPath:_topIndexPath];
        }
        
        if ([self shouldCacheIndexPath:_bottomIndexPath]) {
            
            id object = self.cacheBlock (_tableView, _bottomIndexPath);
            
            AXCache *cache = [self cacheAtSection:_bottomIndexPath.section forIdentifier:_cachingIdentifier];
            
            if (!cache) {
                cache = [self ax_cache];
            }
            
            [cache setObject:object forKey:@(_bottomIndexPath.row)];
            
            [self setCache:cache atSection:_bottomIndexPath.section forIdentifier:_cachingIdentifier];
            
#if DEBUG
            if (_debugLogEnable) {
                NSLog(@"\n----------------------\nCached [%ld-%ld] object:%@\n----------------------\n", _bottomIndexPath.row, _bottomIndexPath.section,object);
            }
#endif
            
            _bottomIndexPath = [self backwardsWithIndexPath:_bottomIndexPath];
        }
        
    }
}

/// Should cache proccess
- (BOOL)shouldProccess {
    
    if (![self shouldCacheIndexPath:_topIndexPath]) {
        
        if (![self shouldCacheIndexPath:_bottomIndexPath]) {
            
            return NO;
        } else {
            
            return YES;
        }
    } else {
        
        return YES;
    }
}

/// IndexPath forward
- (NSIndexPath * __nonnull)forwardWithIndexPath:(NSIndexPath * __nonnull)indexPath {
    
    NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:indexPath.row - 1 inSection:indexPath.section];
    
    if (newIndexPath.row < 0) {
        
        if (newIndexPath.section >= 1) {
            
            NSInteger newSection = newIndexPath.section - 1;
            
            newIndexPath = [NSIndexPath indexPathForRow:[_tableView numberOfRowsInSection:newSection] - 1 inSection:newSection];
        } else {
            
            return nil;
        }
    }
    
    return newIndexPath;
}

/// Return a BOOL value to decide the indexPath should be cached or not
- (BOOL)shouldCacheIndexPath:(NSIndexPath * __nonnull)indexPath {
    
    if (!indexPath || indexPath.row < 0 || indexPath.row >= [_tableView numberOfRowsInSection:indexPath.section] || ![indexPath isKindOfClass:[NSIndexPath class]]) {
        
        return NO;
    }

    AXCache *cache = [self cacheAtSection:indexPath.section forIdentifier:_cachingIdentifier];
    
    id cachedObject = [cache objectForKey:@(indexPath.row)];
    
    if (cachedObject) {
        
        return NO;
    }
    
    BOOL __block indexFlag = NO;
    
    [_visibleIndexPaths enumerateObjectsUsingBlock:^(id  __nonnull obj, NSUInteger idx, BOOL * __nonnull stop) {
        
        NSIndexPath *visibleIndexPath = (NSIndexPath *)obj;
        
        if (visibleIndexPath.row == indexPath.row && visibleIndexPath.section == indexPath.section) {
            
            *stop = YES;
            
            indexFlag = YES;
        }
    }];
    
    if (indexFlag) {
        
        return NO;
    }
    
    NSIndexPath *first = (NSIndexPath *)[_visibleIndexPaths firstObject];
    NSIndexPath *last = (NSIndexPath *)[_visibleIndexPaths lastObject];
    
    NSUInteger change = _visibleIndexPaths.count * _predictedMultiple;
    
    NSInteger topFlag = first.row - change;
    NSInteger bottomFlag = last.row + change;
    
    if (indexPath.section == first.section - 1) {
        if (topFlag < 0) {
            if (indexPath.row >= [_tableView numberOfRowsInSection:indexPath.section] + topFlag) {
                return YES;
            } else {
                return NO;
            }
        } else {
            return NO;
        }
    } else if (indexPath.section == first.section && first.section <= last.section - 1) {
        if (indexPath.row < first.row) {
            if (topFlag < 0) {
                return YES;
            } else {
                if (indexPath.row >= topFlag) {
                    return YES;
                } else {
                    return NO;
                }
            }
        } else {
            return NO;
        }
    } else if (indexPath.section == first.section && first.section == last.section) {
        if (indexPath.row < first.row) {
            if (topFlag < 0) {
                return YES;
            } else {
                if (indexPath.row >= topFlag) {
                    return YES;
                } else {
                    return NO;
                }
            }
        } else if (indexPath.row > last.row) {
            if (bottomFlag >= [_tableView numberOfRowsInSection:indexPath.section]) {
                return YES;
            } else {
                if (indexPath.row <= bottomFlag) {
                    return YES;
                } else {
                    return NO;
                }
            }
        }
    } else if (indexPath.section == last.section && last.section >= first.section + 1) {
        if (indexPath.row > last.row) {
            if (bottomFlag >= [_tableView numberOfRowsInSection:indexPath.section]) {
                return YES;
            } else {
                if (indexPath.row <= bottomFlag) {
                    return YES;
                } else {
                    return NO;
                }
            }
        } else {
            return NO;
        }
    } else if (indexPath.section == last.section + 1) {
        if (bottomFlag >= [_tableView numberOfRowsInSection:indexPath.section]) {
            if (indexPath.row <= bottomFlag - [_tableView numberOfRowsInSection:last.section]) {
                return YES;
            } else {
                return NO;
            }
        } else {
            return NO;
        }
    }
    
    return NO;
}

/// set up the indexPaths should be cached, it's a circle that maybe affect the performance of system
- (void)setupCachedIndexPaths {
    
    if (_cachedIndexPaths.count) return;
    
    [_cachedIndexPaths sortedArrayUsingComparator:^NSComparisonResult(id  __nonnull obj1, id  __nonnull obj2) {
        
        NSIndexPath *indexPath1 = (NSIndexPath *)obj1;
        NSIndexPath *indexPath2 = (NSIndexPath *)obj2;
        
        if (indexPath1.section < indexPath2.section) {
            
            return NSOrderedDescending;
        } else if (indexPath1.section == indexPath2.section) {
            
            if (indexPath1.row < indexPath2.row) {
                
                return NSOrderedDescending;
            } else if (indexPath1.row == indexPath2.row) {
                
                return NSOrderedSame;
            } else {
                
                return NSOrderedAscending;
            }
        } else {
            
            return NSOrderedAscending;
        }
    }];
}

/// IndexPath backwards
- (NSIndexPath * __nonnull)backwardsWithIndexPath:(NSIndexPath * __nonnull)indexPath {
    
    NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section];
    
    if (newIndexPath.row >= [_tableView numberOfRowsInSection:newIndexPath.section]) {
        
        if (newIndexPath.section <= [_tableView numberOfSections] - 2) {
            
            NSInteger newSection = newIndexPath.section + 1;
            
            newIndexPath = [NSIndexPath indexPathForRow:0 inSection:newSection];
        } else {
            return nil;
        }
    }
    
    return newIndexPath;
}

/// Update the common cache configuration
- (void)updateCacheConfiguration {
    
    for (NSString *identifier in self.cachedObjects.allKeys) {
        
        for (NSInteger i = 0; i < _tableView.numberOfSections; i ++) {
            
            AXCache *cache = [self cacheAtSection:i forIdentifier:identifier];
            
            if (!cache) continue;
            
            cache.countLimit = _visibleIndexPaths.count * _predictedMultiple * 2;
            
            [self setCache:cache atSection:i forIdentifier:identifier];
        }
    }
}

/// Should set a new value to the visible indexPaths
- (BOOL)shouldSetVisibleIndexPaths:(NSArray * __nonnull)newIndexPaths {
    
    if (!newIndexPaths.count) return NO;
    
    for (NSIndexPath *indexPath in _visibleIndexPaths) {
        
        if ([newIndexPaths containsObject:indexPath]) {
            
            return NO;
        } else {
            
            return YES;
        }
    }
    
    return YES;
}

/// Get the cache object with a given identifier
- (AXCache * __nullable)cacheAtSection:(NSInteger)section forIdentifier:(NSString * __nonnull)identifier {
    
    AXCache *cache = nil;
    
    NSMutableDictionary *cachedSections = [self.cachedObjects objectForKey:identifier];
    
    cache = [cachedSections objectForKey:@(section)];
    
    return cache;
}

/// Set the cache object for a given identifier
- (void)setCache:(AXCache * __nonnull)cache atSection:(NSInteger)section forIdentifier:(NSString * __nonnull)identifier {
    
    NSMutableDictionary *cachedSections = [self.cachedObjects objectForKey:identifier];
    
    if (!cachedSections) {
        cachedSections = [NSMutableDictionary dictionary];
    }
    
    [cachedSections setObject:cache forKey:@(section)];
    
    [self.cachedObjects setObject:cachedSections
                           forKey:identifier];
}

#pragma mark - AXCacheDelegate
- (void)cache:(AXCache * __nonnull)cache willEvictObject:(id __nonnull)obj forKey:(id<NSCopying> __nonnull)key {
    
    /// do someting when the object will be evicted
}
@end

@implementation AXCache
#pragma mark - LifeCycle
- (instancetype)init {
    if (self = [super init]) {
        [self initializer];
    }
    return self;
}

- (void)initializer {
    _cache = [[NSMutableDictionary alloc] init];
    _sortedKeys = [[NSMutableArray alloc] init];
    _evictsQueue = dispatch_queue_create("com.ax_cache.evict", NULL);
    _countLimit = 0;
    _evictsObjectsWithDiscardedContent = YES;
}

#pragma mark - Getters
- (NSArray * __nullable)allKeys {
    
    NSMutableArray *allKeys = [_sortedKeys mutableCopy];
    
    [allKeys sortUsingComparator:^NSComparisonResult(id  __nonnull obj1, id  __nonnull obj2) {
        
        NSNumber *indexPath1 = (NSNumber *)obj1;
        NSNumber *indexPath2 = (NSNumber *)obj2;
        
        if ([indexPath1 integerValue] < [indexPath2 integerValue]) {
            
            return NSOrderedAscending;
        } else if ([indexPath1 integerValue] == [indexPath2 integerValue]) {
            
            return NSOrderedSame;
        } else {
            
            return NSOrderedDescending;
        }
    }];
    return allKeys;
}

#pragma mark - Public
- (nullable id)objectForKey:(id<NSCopying> __nonnull)key {
    
    return [_cache objectForKey:key];
}

- (void)setObject:(id __nonnull)obj forKey:(id<NSCopying> __nonnull)key {
    
    [_cache setObject:obj forKey:key];
    
    [_sortedKeys insertObject:key atIndex:0];
    
    [self check];
}

- (void)removeObjectForKey:(id<NSCopying> __nonnull)key {
    
    [_cache removeObjectForKey:key];
    
    [_sortedKeys removeObject:key];
}

- (void)removeAllObjects {
    
    [_cache removeAllObjects];
    
    [_sortedKeys removeAllObjects];
}

#pragma mark - Private
- (void)check {
    if (!_evictsObjectsWithDiscardedContent || _countLimit == 0) return;
    
    if (_sortedKeys.count > _countLimit) {
        
        [self evictsObjects];
    }
}

- (void)evictsObjects {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        dispatch_async(_evictsQueue, ^{
            
            id key = [_sortedKeys lastObject];
            
            if (_delegate && [_delegate respondsToSelector:@selector(cache:willEvictObject:forKey:)]) {
                
                id object = [_cache objectForKey:key];
                
                [_delegate cache:self willEvictObject:object forKey:key];
            }
            
            [_cache removeObjectForKey:key];
            
            [_sortedKeys removeLastObject];
        });
    });
}
@end