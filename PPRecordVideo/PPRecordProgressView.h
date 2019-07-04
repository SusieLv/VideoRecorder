//
//  PPProgressView.h
//  PPRecordVideo
//
//  Created by 盼 on 2019/5/17.
//  Copyright © 2019 pan. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^TapEventBlock)(UITapGestureRecognizer *tapGestureRecognizer);
typedef void(^LongPressEventBlock)(UILongPressGestureRecognizer *longPressGestureRecognizer);

@interface PPRecordProgressView : UIView

/**
 * 视频录制进度
 */
@property (nonatomic ,assign) CGFloat progress;

/**
 *  配置点击事件
 */
- (void)configureTapCameraButtonEventWithBlock:(TapEventBlock)tapEventBlock;

/**
 *  配置按压事件
 */
- (void)configureLongPressCameraButtonEventWithBlock:(LongPressEventBlock)longPressEventBlock;


/**
 * 恢复录制按钮状态的动画
 */
- (void)resetScale;


/**
 * 录制按钮开始录制的动画
 */
- (void)setScale;

@end

