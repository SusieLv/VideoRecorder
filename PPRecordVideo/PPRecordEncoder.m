//
//  PPRecordEncoder.m
//  PPRecordVideo
//
//  Created by 盼 on 2019/5/17.
//  Copyright © 2019 pan. All rights reserved.
//

#import "PPRecordEncoder.h"

@interface PPRecordEncoder ()

@property (nonatomic, strong) AVAssetWriter *writer;//媒体写入对象,把媒体数据写入到文件中
@property (nonatomic, strong) AVAssetWriterInput *videoInput;//视频写入
@property (nonatomic, strong) AVAssetWriterInput *audioInput;//音频写入
@property (nonatomic, copy) NSString *path;//媒体写入路径

@end

@implementation PPRecordEncoder

- (void)dealloc
{
    _writer = nil;
    _videoInput = nil;
    _audioInput = nil;
    _path = nil;
}

+ (PPRecordEncoder *)encoderForPath:(NSString *)path height:(NSInteger)cy width:(NSInteger)cx channels:(int)ch samplerate:(Float64)rate
{
    PPRecordEncoder *encoder = [PPRecordEncoder alloc];
    return [encoder initPath:path height:cy width:cx channels:ch samplerare:rate];
}

- (instancetype)initPath:(NSString *)path height:(NSInteger)cy width:(NSInteger)cx channels:(int)ch samplerare:(Float64)rate
{
    self = [super init];
    if (self) {
        
        self.path = path;
        //先把路径下的文件删除，保证录制的文件是最新的
        [[NSFileManager defaultManager] removeItemAtPath:self.path error:nil];
        NSURL *url = [NSURL fileURLWithPath:self.path];
        //初始化写入媒体类型为MP4类型
        _writer = [[AVAssetWriter alloc] initWithURL:url fileType:AVFileTypeMPEG4 error:nil];
        //更适合网络播放
        _writer.shouldOptimizeForNetworkUse = YES;
        
        //初始化视频输入类
        [self initVideoInputHeight:cy width:cx];
        
        if (ch != 0 && rate != 0) {
            //初始化音频输入
            [self initAudioInputChannels:ch samplerate:rate];
        }
        
        
    }
    return self;
}

//初始化视频输入
- (void)initVideoInputHeight:(NSInteger)cy width:(NSInteger)cx
{
    //录制视频的一些配置，分辨率，编码方式等
    NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:
                              AVVideoCodecH264,AVVideoCodecKey,
                              [NSNumber numberWithInteger:cx],AVVideoWidthKey,
                              [NSNumber numberWithInteger:cy],AVVideoHeightKey
                              , nil];
    
    //初始化视频写入类
    _videoInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:settings];
    _videoInput.expectsMediaDataInRealTime = YES;
    //把视频输入源加入
    [_writer addInput:_videoInput];
}


//初始化音频输入
- (void)initAudioInputChannels:(int)ch samplerate:(Float64)rate
{
    //音频配置，AAC，音频通道，采样率和音频的比特率
    NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:kAudioFormatMPEG4AAC],AVFormatIDKey,
                              [NSNumber numberWithInt:ch],AVNumberOfChannelsKey,
                              [NSNumber numberWithFloat:rate],AVSampleRateKey,
                              [NSNumber numberWithInt:128000],AVEncoderBitRateKey
                              , nil];
    
    //初始化音频写入类
    _audioInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio outputSettings:settings];
    _audioInput.expectsMediaDataInRealTime = YES;
    //把音频输入源加入
    [_writer addInput:_audioInput];
}

//视频录制完成的回调
- (void)finishWithCompletionHandler:(void (^)(void))handler
{
    [_writer finishWritingWithCompletionHandler:handler];
}


- (BOOL)encodeFrame:(CMSampleBufferRef)sampleBuffer isVideo:(BOOL)isVideo
{
    //数据是否准备写入
    if (CMSampleBufferDataIsReady(sampleBuffer)) {
        //写入状态未知，保证视频先写入
        if (_writer.status == AVAssetWriterStatusUnknown && isVideo) {
            
            //获取开始写入的CMTime
            CMTime startTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
            //开始写入
            [_writer startWriting];
            [_writer startSessionAtSourceTime:startTime];
        }
        
        //写入失败
        if (_writer.status == AVAssetWriterStatusFailed ) {
            NSLog(@"writer error %@",_writer.error);
            return NO;
        }
        
        //判断是否是视频
        if (isVideo) {
            //视频是否接受更多的媒体数据
            if ([_videoInput isReadyForMoreMediaData]) {
                [_videoInput appendSampleBuffer:sampleBuffer];
            }
            return YES;
        }else
        {
            //音频输入是否准备接受更多数据
            if ([_audioInput isReadyForMoreMediaData]) {
                [_audioInput appendSampleBuffer:sampleBuffer];
            }
            return YES;
        }
        
    }
    
    return NO;
}



@end
