//
//  RunLoopTaskManage.m
//  QHLazyTableImages
//
//  Created by Titania on 2019/10/21.
//  Copyright © 2019 Titania. All rights reserved.
//

#import "RunLoopTaskManage.h"
@interface RunLoopTaskManage ()
@property (nonatomic, strong) NSMutableArray *tasks;

@end

@implementation RunLoopTaskManage
-(NSMutableArray *)tasks{
    return _tasks = _tasks?:[NSMutableArray array];
}

+(instancetype)shareInstaceManager{
    static id singleton;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        singleton = [[RunLoopTaskManage alloc] init];
        [NSTimer scheduledTimerWithTimeInterval:0.1 target:singleton selector:@selector(nullSelector) userInfo:nil repeats:YES];
        [self registRunloopObserver:singleton];
    });
    return singleton;
}

- (void)nullSelector{}

-(void)addTask:(TaskBlock)task{
    [self.tasks addObject:task];
    //超过最大任务数量则移除最后一个，只执行最近的maxTasks个task
    self.tasks.count > self.maxTasks?[self.tasks removeObjectAtIndex:0]:nil;
}

- (void)removeAllTasks {
    [self.tasks removeAllObjects];
}

+ (void)registRunloopObserver:(RunLoopTaskManage *)runLoopWorkDistribution {
    CFRunLoopRef runLoop = CFRunLoopGetCurrent();
    CFRunLoopObserverContext context = {
        0,
        (__bridge void *)runLoopWorkDistribution,
        &CFRetain,
        &CFRelease,
        NULL
    };
    //创建一个runloop observer 监听runloop状态 ，当状态发生变化则调用block
    CFRunLoopObserverRef observer = CFRunLoopObserverCreate(     NULL,
                                                            kCFRunLoopBeforeWaiting,
                                                            YES,
                                                            NSIntegerMax - 999,
                                                            &_defaultModeRunLoopWorkDistributionCallback,
                                                            &context);
    CFRunLoopAddObserver(runLoop, observer, kCFRunLoopDefaultMode);
    CFRelease(observer);
}

static void _defaultModeRunLoopWorkDistributionCallback(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info) {
    RunLoopTaskManage *runloopTaskManage = (__bridge RunLoopTaskManage *)info;
    if (runloopTaskManage.tasks.count == 0) {
        return;
    }
    BOOL result = NO;
    while (result == NO && runloopTaskManage.tasks.count) {
        //任务回调 （调用block执行任务,任务返回yes表示任务已执行）
        TaskBlock taskBlock  = runloopTaskManage.tasks.firstObject;
        result = taskBlock();
        //执行任务后删除任务
        [runloopTaskManage.tasks removeObjectAtIndex:0];
    }
}
@end

