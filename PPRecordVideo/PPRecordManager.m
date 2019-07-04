//
//  PPRecordManager.m
//  PPRecordVideo
//
//  Created by 盼 on 2019/5/16.
//  Copyright © 2019 pan. All rights reserved.
//

#import "PPRecordManager.h"
#import <AVFoundation/AVFoundation.h>
#import "PPRecordEncoder.h"
#import <Photos/Photos.h>
#import "PPMotionManager.h"

@interface PPRecordManager ()<AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate>
{
    CMTime _timeOffset;//录制的偏移CMTime
    CMTime _lastVideo;//记录上一次视频文件的CMTime
    CMTime _lastAudio;//记录上一次音频文件的CMTime
    
    NSInteger _cx;//视频分辨的宽
    NSInteger _cy;//视频分辨的高
    int _channels;//音频通道
    Float64 _samplerate;//采样率
}

@property (nonatomic, strong) PPRecordEncoder            *recordEncoder;
@property (nonatomic, strong) AVCaptureSession           *recordSession;//捕获视频的会话
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer; //AVCaptureSession预览视频输出
@property (nonatomic, strong) AVCaptureDeviceInput       *audioMicInput;//麦克风的输入
@property (nonatomic, strong) AVCaptureDeviceInput       *backCameraInput;//后置摄像头输入
@property (nonatomic, strong) AVCaptureDeviceInput       *frontCameraInput;//前置摄像头输入
@property (nonatomic, strong) AVCaptureVideoDataOutput   *videoOutput;//视频输出
@property (nonatomic, strong) AVCaptureAudioDataOutput   *audioOutput;//音频输出
@property (nonatomic, strong) AVCaptureStillImageOutput  *imageOutput;//静态图片输出
@property (nonatomic, strong) AVCaptureConnection        *videoConnection;//视频连接
@property (nonatomic, strong) AVCaptureConnection        *audioConnection;//音频连接
@property (nonatomic,   copy) dispatch_queue_t            captureQueue;//录制队列
@property (atomic, assign) BOOL isCapturing;//正在录制
@property (atomic, assign) CMTime startTime;//开始录制时间
@property (atomic, assign) CGFloat currentRecordTime;//当前录制时间

@end

@implementation PPRecordManager


- (instancetype)init
{
    self = [super init];
    if (self) {
        self.maxRecordTime = 15.0;
    }
    return self;
}

- (void)takePhoto:(void (^)(UIImage * _Nonnull))callback
{
    AVCaptureConnection *connection = [self.imageOutput connectionWithMediaType:AVMediaTypeVideo];
    if (connection.isVideoOrientationSupported) {
        connection.videoOrientation = [[PPMotionManager sharedManager] currentVideoOrientation];
        
        NSLog(@"%ld",(long)[[PPMotionManager sharedManager] currentVideoOrientation]);
    }
    
    [self.imageOutput captureStillImageAsynchronouslyFromConnection:connection completionHandler:^(CMSampleBufferRef  _Nullable imageDataSampleBuffer, NSError * _Nullable error) {
        
        if (imageDataSampleBuffer==NULL) {
            return;
        }
        
        NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        UIImage *image = [[UIImage alloc] initWithData:imageData];
        callback(image);
        
    }];
}

//启动录制功能
- (void)startUp
{
    self.startTime = CMTimeMake(0, 0);
    self.isCapturing = NO;
    [self.recordSession startRunning];
}

//关闭录制功能
- (void)shutdown
{
    self.startTime = CMTimeMake(0, 0);
    [self.recordSession stopRunning];
}

//开始录制
- (void)startCapture
{
    @synchronized (self) {
        if (!self.isCapturing) {
            _timeOffset = CMTimeMake(0, 0);
            self.isCapturing = YES;
        }
    }
}


//停止录制
- (void)stopCaptureHandler:(void (^)(UIImage *movieImage, NSString *videoPath))handler
{
    @synchronized (self) {
        if (self.isCapturing) {
            
            NSString *path = self.recordEncoder.path;
            NSURL *url = [NSURL fileURLWithPath:path];
            self.isCapturing = NO;
            dispatch_async(self.captureQueue, ^{
               //执行录制完成的操作
                [self.recordEncoder finishWithCompletionHandler:^{
                    self.isCapturing = NO;
                    self.recordEncoder = nil;
                    self.startTime = CMTimeMake(0, 0);
                    self.currentRecordTime = 0;
                    if ([self.delegate respondsToSelector:@selector(recordProgress:)]) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.delegate recordProgress:self.currentRecordTime/self.maxRecordTime];
                        });
                    }
                    
                    //把视频保存到本地相册,异步执行的block
                    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                       //创建一个请求去添加新的视频资源到图片相册
                        [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:url];
                    } completionHandler:^(BOOL success, NSError * _Nullable error) {
                        NSLog(@"保存成功");
                    }];
                    
                    //获取视频第一帧图片
                    [self movieToImageHandler:handler];
                }];
            });
        }
    }
}

//获取视频的第一帧图片
- (void)movieToImageHandler:(void(^)(UIImage *movieImage, NSString *videoPath))handler
{
    NSURL *url = [NSURL fileURLWithPath:self.videoPath];
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:url options:nil];
    //初始化一个资源缩略图或者预览图像的对象
    AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    //从资源中提取图片的时候是否应用矩阵
    generator.appliesPreferredTrackTransform = TRUE;
    CMTime thumbTime = CMTimeMake(0, 60);
    generator.apertureMode = AVAssetImageGeneratorApertureModeEncodedPixels;
    AVAssetImageGeneratorCompletionHandler generatorHandler = ^(CMTime requestedTime, CGImageRef image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error)
    {
        if (result == AVAssetImageGeneratorSucceeded) {
            UIImage *thumbImg = [UIImage imageWithCGImage:image];
            if (handler) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    handler(thumbImg,self.videoPath);
                });
            }
        }
    };
    
    //从一个资源指定或者接近的时间生成一系列的CGImage对象
    /* 这个方法使用高效的批量模式按照时间顺序获取图片 */
    [generator generateCGImagesAsynchronouslyForTimes:[NSArray arrayWithObject:[NSValue valueWithCMTime:thumbTime]] completionHandler:generatorHandler];
}

//开启闪光灯
- (void)openFlashLight
{
    AVCaptureDevice *backCamera = [self backCamera];
    if (backCamera.torchMode == AVCaptureTorchModeOff) {
        [backCamera lockForConfiguration:nil];
        backCamera.torchMode = AVCaptureTorchModeOn;
        backCamera.flashMode = AVCaptureFlashModeOn;
        [backCamera unlockForConfiguration];
    }
}

//关闭闪光灯
- (void)closeFlashLight
{
    AVCaptureDevice *backCamera = [self backCamera];
    if (backCamera.torchMode == AVCaptureTorchModeOn) {
        [backCamera lockForConfiguration:nil];
        backCamera.torchMode = AVCaptureTorchModeOff;
        backCamera.flashMode = AVCaptureFlashModeOff;
        [backCamera unlockForConfiguration];
    }
}

- (void)changeCameraInputDeviceisFront:(BOOL)isFront
{
    //把配置类释放
    [self.recordSession beginConfiguration];
    
    if (isFront) {
        [self.recordSession removeInput:self.backCameraInput];
        
        if ([self.recordSession canAddInput:self.frontCameraInput]) {
            [self.recordSession addInput:self.frontCameraInput];
        }
    }else
    {
        [self.recordSession removeInput:self.frontCameraInput];
        if ([self.recordSession canAddInput:self.backCameraInput]) {
            [self.recordSession addInput:self.backCameraInput];
        }
    }
    if (self.videoConnection.isVideoMirroringSupported) {
        self.videoConnection.videoMirrored = isFront;
    }
    self.videoConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
    [self.recordSession commitConfiguration];
}


#pragma mark - getter setter

- (AVCaptureSession *)recordSession
{
    if (!_recordSession) {
        
        _recordSession = [[AVCaptureSession alloc] init];
        
        //设置输出的质量等级
        _recordSession.sessionPreset = AVCaptureSessionPresetHigh;
        
        //添加视频输入
        if ([_recordSession canAddInput:self.backCameraInput]) {
            [_recordSession addInput:self.backCameraInput];
        }
        
        //添加音频输入
        if ([_recordSession canAddInput:self.audioMicInput]) {
            [_recordSession addInput:self.audioMicInput];
        }
        
        //添加视频输出
        if ([_recordSession canAddOutput:self.videoOutput]) {
            [_recordSession addOutput:self.videoOutput];
            //设置视频的分辨率
            _cx = kScreenWidth;
            _cy = kScreenHeight;
        }
        
        //添加音频输出
        if ([_recordSession canAddOutput:self.audioOutput]) {
            [_recordSession addOutput:self.audioOutput];
        }
        
        //添加图片输出
        if ([_recordSession canAddOutput:self.imageOutput]) {
            [_recordSession addOutput:self.imageOutput];
        }
    }
    return _recordSession;
}

//捕获视频预览的layer
- (AVCaptureVideoPreviewLayer *)previewLayer
{
    if (!_previewLayer) {
        _previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.recordSession];
        //设置比例为铺满全屏
        _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    }
    return _previewLayer;
}


//后置摄像头输入
- (AVCaptureDeviceInput *)backCameraInput
{
    if (!_backCameraInput) {
        NSError *error;
        _backCameraInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self backCamera] error:&error];
    }
    return _backCameraInput;
}

//前置摄像头输入
- (AVCaptureDeviceInput *)frontCameraInput
{
    if (!_frontCameraInput) {
        NSError *error;
        _frontCameraInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self frontCamera] error:&error];
    }
    return _frontCameraInput;
}

//麦克风输入
- (AVCaptureDeviceInput *)audioMicInput
{
    if (!_audioMicInput) {
        AVCaptureDevice *mic = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
        NSError *error;
        _audioMicInput = [AVCaptureDeviceInput deviceInputWithDevice:mic error:&error];
    }
    return _audioMicInput;
}

//视频输出
- (AVCaptureVideoDataOutput *)videoOutput
{
    if (!_videoOutput) {
        _videoOutput = [[AVCaptureVideoDataOutput alloc] init];
        //设置处理接收视频数据的delegate和队列
        [_videoOutput setSampleBufferDelegate:self queue:self.captureQueue];
        //指定像素输出格式
        NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                       [NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange],kCVPixelBufferPixelFormatTypeKey,
                                       nil];
        _videoOutput.videoSettings = videoSettings;
    }
    return _videoOutput;
}

//音频输出
- (AVCaptureAudioDataOutput *)audioOutput
{
    if (!_audioOutput) {
        _audioOutput = [[AVCaptureAudioDataOutput alloc] init];
        [_audioOutput setSampleBufferDelegate:self queue:self.captureQueue];
    }
    return _audioOutput;
}

- (AVCaptureStillImageOutput *)imageOutput
{
    if (!_imageOutput) {
        _imageOutput = [[AVCaptureStillImageOutput alloc] init];
        _imageOutput.outputSettings = @{
                                        AVVideoCodecKey:AVVideoCodecJPEG
                                        };
    }
    return _imageOutput;
}

//视频连接
- (AVCaptureConnection *)videoConnection
{
    if (!_videoConnection) {
        _videoConnection = [self.videoOutput connectionWithMediaType:AVMediaTypeVideo];
    }
    return _videoConnection;
}

//音频连接
- (AVCaptureConnection *)audioConnection
{
    if (!_audioConnection) {
        _audioConnection = [self.audioOutput connectionWithMediaType:AVMediaTypeAudio];
    }
    return _audioConnection;
}

//录制队列
- (dispatch_queue_t)captureQueue
{
    if (!_captureQueue) {
        _captureQueue = dispatch_queue_create("cn.com.susie.videoRecord",DISPATCH_QUEUE_SERIAL);
    }
    return _captureQueue;
}


#pragma mark - 视频相关

//返回后置摄像头
- (AVCaptureDevice *)backCamera
{
    return [self cameraWithPosition:AVCaptureDevicePositionBack];
}

//返回前置摄像头
- (AVCaptureDevice *)frontCamera
{
    return [self cameraWithPosition:AVCaptureDevicePositionFront];
}

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position
{
    //返回和视频录制相关的所有设备
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    //遍历设备返回和position相同的设备
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            return device;
        }
    }
    return nil;
}

//获取视频存放地址
- (NSString *)getVideoCachePath
{
    NSString *videoCache = [NSTemporaryDirectory() stringByAppendingPathComponent:@"videos"];
    BOOL isDir = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL existed = [fileManager fileExistsAtPath:videoCache isDirectory:&isDir];
    if (!(isDir&&existed)) {
        //创建目录
        [fileManager createDirectoryAtPath:videoCache withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return videoCache;
}

//创建文件名
- (NSString *)getUploadFile_type:(NSString *)type fileType:(NSString *)fileType
{
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HHmmss"];
    NSDate *nowDate = [NSDate dateWithTimeIntervalSince1970:now];
    NSString *timeStr = [formatter stringFromDate:nowDate];
    NSString *fileName = [NSString stringWithFormat:@"%@_%@.%@",type,timeStr,fileType];
    
    return fileName;
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    BOOL isVideo = YES;
    
    @synchronized (self) {
        if (!self.isCapturing||self.isPaused) {
            return;
        }
        
        if (self.videoOutput != output) {
            isVideo = NO;
        }
        
        //初始化编码器，当有音频和视频参数时创建编码器
        if ((self.recordEncoder==nil) && !isVideo) {
            CMFormatDescriptionRef fmt = CMSampleBufferGetFormatDescription(sampleBuffer);
            [self setAudioFormat:fmt];
            
            NSString *videoName = [self getUploadFile_type:@"video" fileType:@"mp4"];
            self.videoPath = [[self getVideoCachePath] stringByAppendingPathComponent:videoName];
            
            self.recordEncoder = [PPRecordEncoder encoderForPath:self.videoPath height:kScreenHeight width:kScreenWidth channels:_channels samplerate:_samplerate];
        }

        
        //增加sampleBuffer的引用计时，这样我们可以释放这个或修改这个数据，防止在修改时被释放
        CFRetain(sampleBuffer);
        if (_timeOffset.value > 0) {
            CFRelease(sampleBuffer);
            
            //根据得到的sampleBuffer调整
            sampleBuffer = [self adjustTime:sampleBuffer by:_timeOffset];
        }
        
        //记录暂停上一次录制的时间
        CMTime pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
        CMTime dur = CMSampleBufferGetDuration(sampleBuffer);
        if (dur.value > 0) {
            pts = CMTimeAdd(pts, dur);
        }
        if (isVideo)
        {
            _lastVideo = pts;
        }else
        {
            _lastAudio = pts;
        }
    }
    
    CMTime dur = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    if (self.startTime.value == 0) {
        self.startTime = dur;
    }
    CMTime sub = CMTimeSubtract(dur, self.startTime);
    self.currentRecordTime = CMTimeGetSeconds(sub);
    
    if (self.currentRecordTime > self.maxRecordTime) {
        if (self.maxRecordTime - self.currentRecordTime < 0.1) {
            if (self.delegate&&[self.delegate respondsToSelector:@selector(recordProgress:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate recordProgress:self.currentRecordTime/self.maxRecordTime];
                });
            }
        }
    }
    
    if (self.delegate&&[self.delegate respondsToSelector:@selector(recordProgress:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate recordProgress:self.currentRecordTime/self.maxRecordTime];
        });
    }
    
    //进行数据编码
    [self.recordEncoder encodeFrame:sampleBuffer isVideo:isVideo];
    CFRelease(sampleBuffer);
    
}


//设置音频格式
- (void)setAudioFormat:(CMFormatDescriptionRef)fmt
{
    const AudioStreamBasicDescription *asbd = CMAudioFormatDescriptionGetStreamBasicDescription(fmt);
    _samplerate = asbd->mSampleRate;
    _channels = asbd->mChannelsPerFrame;
}

//调整媒体数据的时间
- (CMSampleBufferRef)adjustTime:(CMSampleBufferRef)sample by:(CMTime)offset
{
    CMItemCount count;
    CMSampleBufferGetSampleTimingInfoArray(sample, 0, nil, &count);
    
    CMSampleTimingInfo *pInfo = malloc(sizeof(CMSampleTimingInfo) * count);
    CMSampleBufferGetSampleTimingInfoArray(sample, count, pInfo, &count);
    for (CMItemCount i = 0; i < count; i++) {
        pInfo[i].decodeTimeStamp = CMTimeSubtract(pInfo[i].decodeTimeStamp, offset);
        pInfo[i].presentationTimeStamp = CMTimeSubtract(pInfo[i].presentationTimeStamp, offset);
    }
    
    CMSampleBufferRef sout;
    CMSampleBufferCreateCopyWithNewTiming(nil, sample, count, pInfo, &sout);
    free(pInfo);
    return sout;
}

@end
