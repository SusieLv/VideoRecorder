//
//  PPRecordViewController.m
//  PPRecordVideo
//
//  Created by 盼 on 2019/5/16.
//  Copyright © 2019 pan. All rights reserved.
//

#import "PPRecordViewController.h"
#import "PPRecordProgressView.h"
#import "PPRecordManager.h"
#import "PPRecordSuccessPreview.h"
#import "PPMotionManager.h"

#define WEAKSELF __weak typeof(self) weakSelf = self;
#define STRONGSELF __strong typeof(weakSelf) strongSelf = weakSelf;

@interface PPRecordViewController ()<PPRecordManagerDelegate,PPMotionManagerDeviceOrientationDelegate>

@property (nonatomic, strong) PPRecordManager *recordManager;
@property (nonatomic, strong) PPRecordProgressView *recordButton;//录制按钮
@property (nonatomic, strong) UIButton *closeButton;//关闭按钮
@property (nonatomic, strong) UIButton *flipButton;//切换摄像头
@property (nonatomic, strong) UIButton *flashButton;//打开或者关闭闪光灯
@property (nonatomic, strong) PPRecordSuccessPreview *preview;
@property (nonatomic, assign) UIDeviceOrientation lastOrientation;
@property (nonatomic, assign) BOOL isEndRecord;

@end

@implementation PPRecordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor blackColor];
    [self setUpUI];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (self.recordManager) {
        [self.recordManager previewLayer].frame = self.view.bounds;
        [self.view.layer insertSublayer:[self.recordManager previewLayer] atIndex:0];
    }
    [self.recordManager startUp];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //监测设备方向
    [[PPMotionManager sharedManager] startDeviceMotionUpdates];
    [PPMotionManager sharedManager].delegate = self;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [[PPMotionManager sharedManager] stopDeviceMotionUpdates];
}


- (void)setUpUI
{
    [self.view addSubview:self.recordButton];
    self.recordButton.center = CGPointMake(kScreenWidth * 0.5, kScreenHeight - 148/2 - 20);

    // 配置拍照方法
    WEAKSELF
    [self.recordButton configureTapCameraButtonEventWithBlock:^(UITapGestureRecognizer *tapGestureRecognizer) {
        [weakSelf takephoto];
    }];
    
    // 配置拍摄方法
    [self.recordButton configureLongPressCameraButtonEventWithBlock:^(UILongPressGestureRecognizer *longPressGestureRecognizer) {
        [weakSelf longPressCameraButtonFunc:longPressGestureRecognizer];
    }];
    
    [self.view addSubview:self.closeButton];
    self.closeButton.center = CGPointMake(kScreenWidth*0.25, self.recordButton.center.y);
    
    [self.view addSubview:self.flipButton];
    self.flipButton.center = CGPointMake(kScreenWidth-80, 40);
    
    [self.view addSubview:self.flashButton];
    self.flashButton.center = CGPointMake(self.flipButton.center.x - 100, 40);

}

#pragma mark -拍照
- (void)takephoto{
    WEAKSELF
    [self.recordManager takePhoto:^(UIImage *image) {
        NSLog(@"拍照结束:%@",image);
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, NULL);
        STRONGSELF
        dispatch_async(dispatch_get_main_queue(), ^{
            [strongSelf.recordManager shutdown];
            [strongSelf.preview setImage:image videoPath:nil captureVideoOrientation:[[PPMotionManager sharedManager] currentVideoOrientation]];
        });
    }];
}

/**
 *  录制视频方法
 */
- (void)longPressCameraButtonFunc:(UILongPressGestureRecognizer *)sender
{
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus == AVAuthorizationStatusRestricted || authStatus ==AVAuthorizationStatusDenied)
    {
        return;
    }
    
    //判断用户是否允许访问麦克风权限
    authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    if (authStatus == AVAuthorizationStatusRestricted || authStatus ==AVAuthorizationStatusDenied)
    {
        return;
    }
    
//    [self hideExitAndSwitchViews];
    
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
        {
            [self.recordButton setScale];
            [self startRecord];
        }
            break;
        case UIGestureRecognizerStateCancelled:
            if (!_isEndRecord) {
                [self stopRecord];
            }
            break;
        case UIGestureRecognizerStateEnded:
            if (!_isEndRecord) {
                [self stopRecord];
            }
            break;
        case UIGestureRecognizerStateFailed:
        {
            if (!_isEndRecord) {
                [self stopRecord];
            }
        }
            break;
        default:
            break;
    }
}

#pragma mark - click event
- (void)exitRecordController
{
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)startRecord
{
    _isEndRecord = NO;
    [self.recordManager startCapture];
    [self.recordButton setProgress:0];
}

- (void)stopRecord
{
    _isEndRecord = YES;
    [self.recordButton setProgress:0];
    [self.recordButton resetScale];
    
    WEAKSELF
    [self.recordManager stopCaptureHandler:^(UIImage * _Nonnull movieImage, NSString * _Nonnull videoPath) {
        NSLog(@"image = %@",movieImage);
        NSLog(@"videoPath = %@",videoPath);
        STRONGSELF
        dispatch_async(dispatch_get_main_queue(), ^{
            [strongSelf.recordManager shutdown];
            [strongSelf.preview setImage:movieImage videoPath:videoPath captureVideoOrientation:[[PPMotionManager sharedManager] currentVideoOrientation]];
        });
        
    }];
}

- (void)switchCamera:(UIButton *)sender
{
    sender.selected = !sender.selected;
    [self.recordManager changeCameraInputDeviceisFront:sender.selected];
}

- (void)flashLight:(UIButton *)sender
{
    sender.selected = !sender.selected;
    if (sender.selected) {
        //打开闪光灯
        [self.flashButton setImage:[UIImage imageNamed:@"icon_btn_camera_flash_on"] forState:UIControlStateNormal];
        [self.recordManager openFlashLight];
    }else
    {
        //关闭闪光灯
        [self.flashButton setImage:[UIImage imageNamed:@"icon_btn_camera_flash_off"] forState:UIControlStateNormal];
        [self.recordManager closeFlashLight];
    }
}


#pragma mark -
- (void)sendWithImage:(UIImage *)image videoPath:(NSString *)videoPath
{
    NSLog(@"%@----%@",image,videoPath);
}

- (void)cancel
{
    if (_preview) {
        [_preview removeFromSuperview];
        _preview = nil;
    }
    [self.recordButton resetScale];
//    [self showAllOperationViews];
    [self.recordManager startUp];
}

#pragma mark - PPRecordManagerDelegate
- (void)recordProgress:(CGFloat)progress
{
    NSLog(@"progress = %.2f",progress);
    if (progress >= 0) {
        [self.recordButton setProgress:progress];
    }
    
    if ((int)progress == 1) {
        [self stopRecord];
    }
}

#pragma mark - PPMotionManagerDeviceOrientationDelegate
- (void)motionManagerDeviceOrientation:(UIDeviceOrientation)deviceOrientation
{
    if (self.lastOrientation == deviceOrientation)
    {
        return;
    }
    
    CGFloat angle = 0;
    switch (deviceOrientation) {
        case UIDeviceOrientationPortrait:
            angle = 0;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            angle = M_PI;
            break;
        case UIDeviceOrientationLandscapeLeft:
            angle = M_PI_2;
            break;
        case UIDeviceOrientationLandscapeRight:
            angle = -M_PI_2;
        default:
            break;
    }
    
    [UIView animateWithDuration:0.25 animations:^{
        self.flashButton.transform = CGAffineTransformRotate(CGAffineTransformIdentity, angle);
        self.flipButton.transform = CGAffineTransformRotate(CGAffineTransformIdentity, angle);
    }];
    
    _lastOrientation = deviceOrientation;
}

#pragma mark - getter,setter

- (PPRecordManager *)recordManager
{
    if (!_recordManager) {
        _recordManager = [[PPRecordManager alloc] init];
        _recordManager.delegate = self;
    }
    
    return _recordManager;
}

//录制按钮
- (PPRecordProgressView *)recordButton
{
    if (!_recordButton) {
        _recordButton = [[PPRecordProgressView alloc] initWithFrame:CGRectMake(0, 0, 148/2, 148/2)];
    }
    return _recordButton;
}

//退出按钮
- (UIButton *)closeButton
{
    if (!_closeButton) {
        _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_closeButton setImage:[UIImage imageNamed:@"短视频_关闭"] forState:UIControlStateNormal];
        _closeButton.frame = CGRectMake(0, 0, 44, 44);
        [_closeButton addTarget:self action:@selector(exitRecordController) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeButton;
}

//摄像头切换
- (UIButton *)flipButton
{
    if (!_flipButton) {
        _flipButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_flipButton setImage:[UIImage imageNamed:@"短视频_翻转"] forState:UIControlStateNormal];
        [_flipButton addTarget:self action:@selector(switchCamera:) forControlEvents:UIControlEventTouchUpInside];
        _flipButton.frame = CGRectMake(0, 0, 44, 44);
    }
    return _flipButton;
}

//闪光灯打开或关闭
- (UIButton *)flashButton
{
    if (!_flashButton) {
        _flashButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_flashButton setImage:[UIImage imageNamed:@"icon_btn_camera_flash_off"] forState:UIControlStateNormal];
        [_flashButton addTarget:self action:@selector(flashLight:) forControlEvents:UIControlEventTouchUpInside];
        _flashButton.frame = CGRectMake(0, 0, 44, 44);
    }
    return _flashButton;
}

- (PPRecordSuccessPreview *)preview{
    if (!_preview) {
        _preview = [[PPRecordSuccessPreview alloc]initWithFrame:self.view.bounds];
        WEAKSELF
        [_preview setSendBlock:^(UIImage *image,NSString *videoPath){
            STRONGSELF
            [strongSelf sendWithImage:image videoPath:videoPath];
        }];
        [_preview setCancelBlcok:^{
            STRONGSELF
            [strongSelf cancel];
        }];
        [self.view addSubview:_preview];
    }
    return _preview;
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
