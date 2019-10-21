//
//  QHLazyImagesViewController.m
//  QHLazyTableImages
//
//  Created by Titania on 2019/10/21.
//  Copyright © 2019 Titania. All rights reserved.
//

#import "QHLazyImagesViewController.h"
#import <SDWebImage.h>
#import "UITableViewCell+indexPath.h"
#import "AppRecord.h"

static NSString *CellIdentifier = @"LazyTableCell";
static NSString *PlaceholderCellIdentifier = @"PlaceholderCell";


#pragma mark -
typedef void(^runloopTask)(void);
@interface QHLazyImagesViewController () <UIScrollViewDelegate, UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tableView;

//任务执行的代码块
@property (copy, nonatomic) runloopTask task;
//存放任务的数组
@property (nonatomic, strong) NSMutableArray *TaskMarr;
//最大任务数     任务数据只保留最后停留在页面的任务
@property (nonatomic, assign) NSInteger maxTasksNumber;
@end


#pragma mark -

@implementation QHLazyImagesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:CellIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:PlaceholderCellIdentifier];
    //给当前runloop注册观察者
    [self addRunloopObserver];
    //给runloop一个事件源，让Runloop不断的运行执行代码块任务。
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(runloopalive) userInfo:nil repeats:YES];
}
//如果方法里什么都不干，APP性能影响并不大。但cpu增加负担，
-(void)runloopalive{
    //什么都不干
}
-(NSMutableArray *)TaskMarr{
    if (!_TaskMarr) {
        _TaskMarr = [NSMutableArray array];
    }
    self.maxTasksNumber  =  30;
    return _TaskMarr;
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
    __weak  QHLazyImagesViewController *weakSelf  = self;
    UITableViewCell *cell = nil;
    NSUInteger nodeCount = self.entries.count;
    if (nodeCount == 0 && indexPath.row == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:PlaceholderCellIdentifier forIndexPath:indexPath];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        // Leave cells empty if there's no data yet
        if (nodeCount > 0) {
            // Set up the cell representing the app
            AppRecord *appRecord = (self.entries)[indexPath.row];
            cell.textLabel.text = appRecord.appName;
            cell.detailTextLabel.text = appRecord.artist;
            cell.indexPath = indexPath;
            // 这个cell只有一个image 如有多个 则 再次addTasks:image即可
            cell.imageView.image = [UIImage imageNamed:@"小图占位"];
            [self addTasks:^{
                [weakSelf setImageWithCell:cell IndexPath:indexPath UrlString:appRecord.imageURLString toImageV:cell.imageView];
            }];
        }
    }
    return cell;
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




//添加任务进数组保存
-(void)addTasks:(runloopTask)taskBlock{
    [self.TaskMarr addObject:taskBlock];
    //超过每次最多执行的任务数就移出当前数组
    if (self.TaskMarr.count > self.maxTasksNumber) {
        [self.TaskMarr removeObjectAtIndex:0];
    }
}

#pragma mark  设置runloop监听
//这里面都是C语言 -- 添加一个监听者
-(void)addRunloopObserver{
    //获取当前runloop
    CFRunLoopRef  currentRunloop =  CFRunLoopGetCurrent();
    //runloop观察者上下文， 为下面创建观察者准备，只有创建上下文才能在回调了拿到self对象，才能进行我们的逻辑操作. 这是一个结构体。
    /**
     typedef struct {
     CFIndex    version;
     void *    info;
     const void *(*retain)(const void *info);
     void    (*release)(const void *info);
     CFStringRef    (*copyDescription)(const void *info);
     } CFRunLoopObserverContext;
     **/
    CFRunLoopObserverContext  context = {
        0,
        (__bridge void *)(self),
        &CFRetain,
        &CFRelease,
        NULL
    };
    //创建Runloop观察者  kCFRunLoopBeforeWaiting  观察在等待状态之前  runloop有下面几种状态 看英文应该知道了。
    /*
     kCFRunLoopEntry = (1UL << 0),
     kCFRunLoopBeforeTimers = (1UL << 1),
     kCFRunLoopBeforeSources = (1UL << 2),
     kCFRunLoopBeforeWaiting = (1UL << 5),
     kCFRunLoopAfterWaiting = (1UL << 6),
     kCFRunLoopExit = (1UL << 7),
     kCFRunLoopAllActivities = 0x0FFFFFFFU
     */
    static CFRunLoopObserverRef  obserberRef;
    obserberRef =CFRunLoopObserverCreate(NULL, kCFRunLoopBeforeWaiting, YES, 0,&callback, &context);
    //给当前runloop添加观察者
    CFRunLoopAddObserver(currentRunloop, obserberRef, kCFRunLoopDefaultMode);
    //释放观察者
    CFRelease(obserberRef);
}

//观察回调
static void callback(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info){
    QHLazyImagesViewController * vcSelf = (__bridge QHLazyImagesViewController *)(info);
    if (vcSelf.TaskMarr.count > 0) {
        //获取一次数组里面的任务并执行
        runloopTask  task  =  vcSelf.TaskMarr.firstObject;
        task();
        [vcSelf.TaskMarr removeObjectAtIndex:0];
    }else{
        return;
    }
}

@end
