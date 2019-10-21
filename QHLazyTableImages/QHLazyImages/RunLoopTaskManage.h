//
//  RunLoopTaskManage.h
//  QHLazyTableImages
//
//  Created by Titania on 2019/10/21.
//  Copyright © 2019 Titania. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
typedef BOOL(^TaskBlock)(void);

@interface RunLoopTaskManage : NSObject
@property (nonatomic,assign)NSInteger maxTasks;

+(instancetype)shareInstaceManager;

- (void)addTask:(TaskBlock)task;

- (void)removeAllTasks;

@end

NS_ASSUME_NONNULL_END
