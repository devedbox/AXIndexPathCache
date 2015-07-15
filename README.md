# AXIndexPathCache
基于NSIndexPath的UITableViewCell异步缓存组件，一行代码集成。
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
