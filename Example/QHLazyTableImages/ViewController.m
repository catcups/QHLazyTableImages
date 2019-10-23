//
//  ViewController.m
//  QHLazyTableImages
//
//  Created by Titania on 2019/10/21.
//  Copyright © 2019 Titania. All rights reserved.
//

#import "ViewController.h"
#import "RootViewController.h"
#import "QHLazyImagesViewController.h"
#import "QHLazyTwoViewController.h"

#import <SDWebImage.h>

@interface ViewController ()<UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"UITableViewCell"];
    self.tableView .tableFooterView = [UIView new];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell" forIndexPath:indexPath];
    cell.textLabel.text = @[@"1",@"QHLazyImagesViewController", @"QHLazyTwoViewController"][indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (self.entries.count > 0) {
        switch (indexPath.row) {
            case 0:
            {
                RootViewController *one = [RootViewController new];
                one.entries = self.entries;
                [self.navigationController pushViewController:one animated:YES];
            }
                break;
            case 1:
            {
                QHLazyImagesViewController *vc = [QHLazyImagesViewController new];
                vc.entries = self.entries;
                [self.navigationController pushViewController:vc animated:YES];
            }
                break;
            case 2:
            {
                QHLazyTwoViewController *vc = [QHLazyTwoViewController new];
                vc.entries = self.entries;
                [self.navigationController pushViewController:vc animated:YES];
            }
                break;
            default:
                break;
        }
    }
}

- (IBAction)cleanAction:(id)sender {
    float tmpSize = [[SDImageCache sharedImageCache] totalDiskSize];
    float tmpSizeM = tmpSize/1024/1024;
    NSString *clearCacheName = tmpSizeM >= 1 ? [NSString stringWithFormat:@"清理了%.2fM缓存",tmpSizeM] : [NSString stringWithFormat:@"清理了%.2fK缓存",tmpSizeM * 1024];
    NSLog(@"%@", clearCacheName);
    [[SDImageCache sharedImageCache] clearDiskOnCompletion:nil];
}


@end
