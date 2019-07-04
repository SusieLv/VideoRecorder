//
//  PPRecordManager.h
//  PPRecordVideo
//
//  Created by 盼 on 2019/5/16.
//  Copyright © 2019 pan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVCaptureVideoPreviewLayer.h>
#import <UIKit/UIKit.h>

@protocol PPRecordManagerDelegate <NSObject>

- (void)recordProgress:(CGFloat)progress;

@end

NS_ASSUME_NONNULL_BEGIN

@interface PPRecordManager : NSObject

@property (atomic, assign, readonly) BOOL isCapturing;//正在录制
@property (atomic, assign, readonly) BOOL isPaused; //是否暂停
@property (atomic, assign, readonly) BOOL discont;//是否中断
@property (nonatomic, assign) CGFloat maxRecordTime;//录制最长时间
@property (nonatomic, copy) NSString *videoPath;//视频路径
@property (nonatomic, weak) id<PPRecordManagerDelegate> delegate;

/**
 展示捕获视频的previewLayer
 
 @return previewLayer
 */
- (AVCaptureVideoPreviewLayer *)previewLayer;

/**
 启动录制功能
 */
- (void)startUp;


/**
 关闭录制功能
 */
- (void)shutdown;


/**
 开始录制
 */
- (void)startCapture;


/**
 停止录制

 @param handler 停止录制的回调
 */
- (void)stopCaptureHandler:(void(^)(UIImage *movieImage,NSString *videoPath))handler;

/**
 拍照
 
 @param callback 返回图片
 */
- (void)takePhoto:(void(^)(UIImage *image))callback;

/**
 开启闪光灯
 */
- (void)openFlashLight;


/**
 关闭闪光灯
 */
- (void)closeFlashLight;


/**
 切换前后置摄像头

 @param isFront YES:前置  NO:后置
 */
- (void)changeCameraInputDeviceisFront:(BOOL)isFront;


@end

NS_ASSUME_NONNULL_END
