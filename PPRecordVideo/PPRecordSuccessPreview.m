//
//  PPRecordSuccessPreview.m
//  短视频录制
//
//  Created by lihaohao on 2017/5/22.
//  Copyright © 2017年 低调的魅力. All rights reserved.
//

#import "PPRecordSuccessPreview.h"
#import "UIButton+Convenience.h"

@interface PPRecordSuccessPreview(){
    float _width;
    float _distance;
}
@property (nonatomic ,strong) UIButton *cancelButton;
@property (nonatomic ,strong) UIButton *sendButton;
@property (nonatomic ,strong) UIImage *image;// 拍摄的图片
@property (nonatomic ,copy) NSString *videoPath; // 拍摄的视频地址
@property (nonatomic ,assign) BOOL isPhoto;// 是否是图片
@property (nonatomic ,strong) AVPlayerViewController *avPlayer;
@property (nonatomic ,assign) AVCaptureVideoOrientation orientation;

@end

@implementation PPRecordSuccessPreview
- (void)setImage:(UIImage *)image videoPath:(NSString *)videoPath captureVideoOrientation:(AVCaptureVideoOrientation)orientation{
    _image = image;
    _videoPath = videoPath;
    _orientation = orientation;
    self.backgroundColor = [UIColor blackColor];
    if (_image && !videoPath) {
        _isPhoto = YES;
    }
    [self setupUI];
}
- (void)setupUI{

    
    if (_isPhoto) {
        //拍照
        UIImageView *imageview = [[UIImageView alloc]initWithImage:_image];
        imageview.frame = self.bounds;
        if (_orientation == AVCaptureVideoOrientationLandscapeRight || _orientation ==AVCaptureVideoOrientationLandscapeLeft) {
            imageview.contentMode = UIViewContentModeScaleAspectFit;
        }
        [self addSubview:imageview];
    } else {
        AVPlayerViewController *avPlayer = [[AVPlayerViewController alloc]init];
        avPlayer.view.backgroundColor = [UIColor clearColor];
        avPlayer.view.frame = self.bounds;
        avPlayer.showsPlaybackControls = NO;
        avPlayer.videoGravity = AVLayerVideoGravityResizeAspect;
        avPlayer.player = [AVPlayer playerWithURL:[NSURL fileURLWithPath:_videoPath]];
        [avPlayer.player play];
        [self addSubview:avPlayer.view];
        _avPlayer = avPlayer;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(replay) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    }
    _width = 148/2;
    _distance = 100/2;
    // 取消
    UIButton *cancelButton = [UIButton image:@"短视频_重拍" target:self action:@selector(cancel)];
    cancelButton.adjustsImageWhenHighlighted = NO;
    cancelButton.bounds = CGRectMake(0, 0, _width, _width);
    cancelButton.center = CGPointMake(self.center.x, self.bounds.size.height -_distance - _width/2);
    [self addSubview:cancelButton];
    _cancelButton = cancelButton;
    
    // 发送
    UIButton *sendButton = [UIButton image:@"短视频_完成" target:self action:@selector(send)];
    sendButton.bounds = CGRectMake(0, 0, _width, _width);
    sendButton.center = CGPointMake(self.center.x, self.bounds.size.height - _distance - _width/2);
    [self addSubview:sendButton];
    _sendButton = sendButton;
}

-(void)layoutSubviews{
    [super layoutSubviews];
    NSLog(@"预览图");
    [UIView animateWithDuration:0.25 animations:^{
        self.cancelButton.bounds = CGRectMake(0, 0, _width, _width);
        self.cancelButton.center = CGPointMake(self.bounds.size.width / 4, self.bounds.size.height -_distance - _width/2);
        self.sendButton.bounds = CGRectMake(0, 0, _width, _width);
        self.sendButton.center = CGPointMake(self.bounds.size.width / 4 * 3, self.bounds.size.height - _distance - _width/2);
    }];
}
#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_8_4
- (void)replay{
    if (_avPlayer) {
        [_avPlayer.player seekToTime:CMTimeMake(0, 1)];
        [_avPlayer.player play];
    }
}
#endif
- (void)cancel{
    if (!_isPhoto) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        [self.avPlayer.player pause];
    }
    
    if (self.cancelBlcok) {
        self.cancelBlcok();
    }
}
- (void)send{
    if (self.sendBlock) {
        self.sendBlock(_image, _videoPath);
    }
}
- (void)dealloc{
   
    NSLog(@"%s",__func__);
}
@end
