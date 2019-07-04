//
//  PPMotionManager.m
//  PPRecordVideo
//
//  Created by 盼 on 2019/7/4.
//  Copyright © 2019 pan. All rights reserved.
//

#import "PPMotionManager.h"
#import <CoreMotion/CoreMotion.h>

//#define MOTION_UPDATE_INTERVAL 1/15.0

static CGFloat const MOTION_UPDATE_INTERVAL = 1/15.0;

@interface PPMotionManager ()

@property (nonatomic, strong) CMMotionManager *motionManager;

@end

@implementation PPMotionManager

+ (instancetype)sharedManager
{
    static PPMotionManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[PPMotionManager alloc] init];
    });
    
    return manager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        if (!_motionManager) {
            _motionManager = [[CMMotionManager alloc] init];
            _motionManager.deviceMotionUpdateInterval = MOTION_UPDATE_INTERVAL;
        }
    }
    
    return self;
}


- (void)startDeviceMotionUpdates
{
    if (_motionManager.accelerometerAvailable) {
        [_motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMDeviceMotion * _Nullable motion, NSError * _Nullable error) {
            
            [self performSelectorOnMainThread:@selector(handleDeviceMotion:) withObject:motion waitUntilDone:YES];
        }];
    }
}

- (void)stopDeviceMotionUpdates
{
    [_motionManager stopDeviceMotionUpdates];
}


- (void)handleDeviceMotion:(CMDeviceMotion *)deviceMotion
{
    double x = deviceMotion.gravity.x;
    double y = deviceMotion.gravity.y;
    
    if (fabs(y) >= fabs(x)) {
        
        if (y>=0)
        {
            //竖屏 home键在上
            _deviceOrientation = UIDeviceOrientationPortraitUpsideDown;
            _videoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
        }else
        {
            //竖屏 home键在下
            _deviceOrientation = UIDeviceOrientationPortrait;
            _videoOrientation = AVCaptureVideoOrientationPortrait;
        }
        
    }else
    {
        //横屏 home键在左
        if (x>=0)
        {
            _deviceOrientation = UIDeviceOrientationLandscapeRight;
            _videoOrientation = AVCaptureVideoOrientationLandscapeRight;
        }else
        {
            _deviceOrientation = UIDeviceOrientationLandscapeLeft;
            _videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
        }
    }
    
    if (self.delegate&&[self.delegate respondsToSelector:@selector(motionManagerDeviceOrientation:)]) {
        [self.delegate motionManagerDeviceOrientation:_deviceOrientation];
    }
}


- (AVCaptureVideoOrientation)currentVideoOrientation
{
    AVCaptureVideoOrientation videoOrientation;
    NSLog(@"%ld %s",(long)[PPMotionManager sharedManager].deviceOrientation, __func__);
    
    switch ([PPMotionManager sharedManager].deviceOrientation) {
        case UIDeviceOrientationPortrait:
            videoOrientation = AVCaptureVideoOrientationPortrait;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            videoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
            break;
        case UIDeviceOrientationLandscapeRight:
            videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
            break;
        default:
            videoOrientation = AVCaptureVideoOrientationLandscapeRight;
            break;
    }
    return videoOrientation;
}


@end
