//
//  UIButton+Convenience.m
//  PPRecordVideo
//
//  Created by 盼 on 2019/7/4.
//  Copyright © 2019 pan. All rights reserved.
//

#import "UIButton+Convenience.h"

@implementation UIButton (Convenience)

+ (UIButton *)image:(NSString *)imageName target:(id)target action:(SEL)action{
    UIButton *button = [self buttonWithType:UIButtonTypeCustom];
    [button setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
    [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

+ (UIButton *)title:(NSString *)title target:(id)target action:(SEL)action{
    UIButton *button = [self buttonWithType:UIButtonTypeCustom];
    [button setTitle:title forState:UIControlStateNormal];
    [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

@end
