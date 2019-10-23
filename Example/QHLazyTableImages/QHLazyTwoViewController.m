//
//  QHLazyTwoViewController.m
//  QHLazyTableImages
//
//  Created by Titania on 2019/10/21.
//  Copyright © 2019 Titania. All rights reserved.
//

#import "QHLazyTwoViewController.h"
#import <SDWebImage.h>
#import "UITableViewCell+indexPath.h"
#import "AppRecord.h"
#import "RunLoopTaskManage.h"

static NSString *CellIdentifier = @"LazyTableCell";
static NSString *PlaceholderCellIdentifier = @"PlaceholderCell";


#pragma mark -
typedef void(^runloopTask)(void);
@interface QHLazyTwoViewController () <UIScrollViewDelegate, UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tableView;

//任务执行的代码块
@property (copy, nonatomic) runloopTask task;
//存放任务的数组
@property (nonatomic, strong) NSMutableArray *TaskMarr;
//最大任务数     任务数据只保留最后停留在页面的任务
@property (nonatomic, assign) NSInteger maxTasksNumber;
@end


#pragma mark -

@implementation QHLazyTwoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:CellIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:PlaceholderCellIdentifier];
    [RunLoopTaskManage shareInstaceManager].maxTasks = 30;
}

- (void)setEntries:(NSArray *)entries {
    _entries = entries;
    [self.tableView reloadData];
}

- (void)dealloc {
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.entries.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
//    __weak  QHLazyTwoViewController *weakSelf  = self;
    UITableViewCell *cell = nil;
    NSUInteger nodeCount = self.entries.count;
    if (nodeCount == 0 && indexPath.row == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:PlaceholderCellIdentifier forIndexPath:indexPath];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        // Leave cells empty if there's no data yet
        if (nodeCount > 0) {
            cell.indexPath = indexPath;
            cell.imageView.image = [UIImage imageNamed:@"小图占位"];
            AppRecord *appRecord = self.entries[indexPath.row];
            cell.textLabel.text = appRecord.appName;
            cell.detailTextLabel.text = appRecord.artist;
            [self runloopCell:cell indexPath:indexPath];
        }
    }
    return cell;
}

// 该方法可以封装到自定义Cell中处理图片下载
- (void)runloopCell:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath {
    NSLog(@"cell=%ld===%ld", cell.indexPath.row, indexPath.row);
    [[RunLoopTaskManage shareInstaceManager] addTask:^BOOL{
        if (![cell.indexPath isEqual:indexPath])
            return NO;
        AppRecord *appRecord = self.entries[indexPath.row];
        [cell.imageView sd_setImageWithURL:[NSURL URLWithString:appRecord.imageURLString]];
//        [self setImageWithCell:cell IndexPath:indexPath UrlString:appRecord.imageURLString toImageV:cell.imageView];
        return YES;
    }];
}

- (void)setImageWithCell:(UITableViewCell *)weakCell IndexPath:(NSIndexPath *)indexPath UrlString:(NSString *)urlString toImageV:(UIImageView *)imageView {
    [[SDImageCache sharedImageCache] containsImageForKey:urlString cacheType:(SDImageCacheTypeAll) completion:^(SDImageCacheType containsCacheType) {
        if (containsCacheType == SDImageCacheTypeNone) {
            [[SDWebImageManager sharedManager] loadImageWithURL:[NSURL URLWithString:urlString]
                                                        options:0
                                                       progress:nil
                                                      completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
                                                          if ([weakCell.indexPath isEqual:indexPath]) {
                                                              if (weakCell.image) {
                                                                  imageView.image = image;
                                                                  imageView.hidden = NO;
                                                              } else if (image) {
                                                                  weakCell.image = image;
                                                                  imageView.image = image;
                                                                  imageView.hidden = NO;
                                                              } else {
                                                                  imageView.image = [UIImage imageNamed:@"小图占位"]; // 除非下载不了
                                                                  imageView.hidden = NO;
                                                              }
                                                          } else {
                                                              NSLog(@"当前===%ld===%ld", weakCell.indexPath.row, indexPath.row);
                                                          }
                                                      }];
        } else {
            if ([weakCell.indexPath isEqual:indexPath]) {
                [imageView sd_setImageWithURL:[NSURL URLWithString:urlString] placeholderImage:[UIImage imageNamed:@"小图占位"]completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                    if (image) {
                        weakCell.image = image;
                        imageView.image = image;
                        imageView.hidden = NO;
                    }
                }];
            } else {
                NSLog(@"当前存在===%ld===%ld", weakCell.indexPath.row, indexPath.row);
            }
        }
    }];
}

@end
