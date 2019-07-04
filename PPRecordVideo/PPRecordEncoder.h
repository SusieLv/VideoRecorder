//
//  PPRecordEncoder.h
//  PPRecordVideo
//
//  Created by 盼 on 2019/5/17.
//  Copyright © 2019 pan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PPRecordEncoder : NSObject

@property (nonatomic, readonly) NSString *path;

/**
 PPRecordEncoder遍历构造器

 @param path 媒体存放路径
 @param cy 视频分辨率的高
 @param cx 视频分辨率的宽
 @param ch 音频通道
 @param rate 音频采样率
 @return PPRecordEncoder的实体
 */
+ (PPRecordEncoder *)encoderForPath:(NSString *)path
                             height:(NSInteger)cy
                              width:(NSInteger)cx
                           channels:(int)ch
                         samplerate:(Float64)rate;

/**
 初始化方法

 @param path 媒体存放路径
 @param cy   视频分辨率的高
 @param cx   视频分辨率的宽
 @param ch   音频通道
 @param rate 音频采样率
 @return PPRecordEncoder的实体
 */
- (instancetype)initPath:(NSString *)path
                  height:(NSInteger)cy
                   width:(NSInteger)cx
                channels:(int)ch
              samplerare:(Float64)rate;



/**
 视频录制完成时的回调

 @param handler 完成的回调block
 */
- (void)finishWithCompletionHandler:(void(^)(void))handler;


/**
 通过这个方法写入数据

 @param sampleBuffer 写入的数据
 @param isVideo      写入的是否是视频
 
 @return   写入是否成功
 */
- (BOOL)encodeFrame:(CMSampleBufferRef)sampleBuffer isVideo:(BOOL)isVideo;

@end

NS_ASSUME_NONNULL_END
