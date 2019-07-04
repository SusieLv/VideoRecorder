//
//  UIButton+Convenience.h
//  PPRecordVideo
//
//  Created by 盼 on 2019/7/4.
//  Copyright © 2019 pan. All rights reserved.
//

#import <UIKit/UIKit.h>



@interface UIButton (Convenience)

/**
 便利构造函数
 
 @param imageName     图片名称
 @param target    代理
 @param action    响应事件
 @return UIButton 实例
 */
+ (UIButton *)image:(NSString *)imageName target:(id)target action:(SEL)action;

/**
 便利构造函数
 
 @param title     提示问题
 @param target    代理
 @param action    响应事件
 @return UIButton 实例
 */
+ (UIButton *)title:(NSString *)title target:(id)target action:(SEL)action;


@end

