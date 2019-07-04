//
//  PPMotionManager.h
//  PPRecordVideo
//
//  Created by 盼 on 2019/7/4.
//  Copyright © 2019 pan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

@protocol PPMotionManagerDeviceOrientationDelegate <NSObject>

@optional

- (void)motionManagerDeviceOrientation:(UIDeviceOrientation)deviceOrientation;

@end


@interface PPMotionManager : NSObject

@property (nonatomic, assign) UIDeviceOrientation deviceOrientation;
@property (nonatomic, assign) AVCaptureVideoOrientation videoOrientation;
@property (nonatomic, weak) id<PPMotionManagerDeviceOrientationDelegate> delegate;


/**
 获取PPMotionManager的实例

 @return 返回PPMotionManager的实例
 */
+ (instancetype)sharedManager;



/**
 开始监测方向
 */
- (void)startDeviceMotionUpdates;


/**
 结束方向监测
 */
- (void)stopDeviceMotionUpdates;


/**
 设置设备方向

 @return 返回视频捕捉方向
 */
- (AVCaptureVideoOrientation)currentVideoOrientation;


@end

