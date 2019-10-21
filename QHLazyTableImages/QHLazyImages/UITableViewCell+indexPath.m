//
//  UITableViewCell+indexPath.m
//  QHLazyTableImages
//
//  Created by Titania on 2019/10/21.
//  Copyright © 2019 Titania. All rights reserved.
//

#import "UITableViewCell+indexPath.h"
#import <objc/runtime.h>

@implementation UITableViewCell (indexPath)
@dynamic indexPath;
@dynamic image;

- (NSIndexPath *)indexPath {
    NSIndexPath *indexP = objc_getAssociatedObject(self, @selector(indexPath));
    return indexP;
}

- (void)setIndexPath:(NSIndexPath *)indexPath {
    objc_setAssociatedObject(self, @selector(indexPath), indexPath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIImage *)image {
    UIImage *img = objc_getAssociatedObject(self, @selector(image));
    return img;
}

- (void)setImage:(UIImage *)image {
    objc_setAssociatedObject(self, @selector(image), image, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
