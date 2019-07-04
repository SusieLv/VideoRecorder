//
//  PPProgressView.m
//  PPRecordVideo
//
//  Created by 盼 on 2019/5/17.
//  Copyright © 2019 pan. All rights reserved.
//

#import "PPRecordProgressView.h"

@interface PPRecordProgressView ()

@property (nonatomic, strong) CALayer *centerLayer;
@property (nonatomic, strong) CAShapeLayer *progressLayer;
@property (nonatomic,   copy) TapEventBlock tapEventBlock;
@property (nonatomic,   copy) LongPressEventBlock longPressEventBlock;

@end

@implementation PPRecordProgressView

static CGFloat const SG_LINE_WIDTH = 4;

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setUpUI];
    }
    return self;
}


- (void)setUpUI
{
    self.backgroundColor = [UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:0.4];
    self.layer.cornerRadius = self.bounds.size.height * 0.5;
    self.clipsToBounds = YES;
    
    float centerX = self.bounds.size.width * 0.5;
    float centerY = self.bounds.size.height * 0.5;
    //半径
    float radius = (self.bounds.size.width - SG_LINE_WIDTH) * 0.5;
    //创建贝塞尔路径
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(centerX, centerY) radius:radius startAngle:(-0.5f * M_PI) endAngle:(1.5f * M_PI) clockwise:YES];
    
    //中间的白圆
    CALayer *centerlayer = [CALayer layer];
    centerlayer.backgroundColor = [UIColor whiteColor].CGColor;
    centerlayer.position = self.center;
    centerlayer.bounds = CGRectMake(0, 0, 110/2, 110/2);
    centerlayer.cornerRadius = 110/4;
    centerlayer.masksToBounds = YES;
    [self.layer addSublayer:centerlayer];
    _centerLayer = centerlayer;
    
    //创建进度layer
    _progressLayer = [CAShapeLayer layer];
    _progressLayer.frame = self.bounds;
    _progressLayer.fillColor =  [[UIColor clearColor] CGColor];
    //指定path的渲染颜色
    _progressLayer.strokeColor  = [[UIColor colorWithRed:255/255.0 green:214/255.0 blue:34/255.0 alpha:1] CGColor];
    _progressLayer.lineCap = kCALineCapSquare;//kCALineCapRound;
    _progressLayer.lineWidth = SG_LINE_WIDTH;
    _progressLayer.path = [path CGPath];
    _progressLayer.strokeEnd = 0;
    [self.layer addSublayer:_progressLayer];
}


- (void)setScale{
    [UIView animateWithDuration:0.25 animations:^{
        self.centerLayer.transform = CATransform3DScale(self.centerLayer.transform, 68/110.0, 68/110.0, 1);
        self.transform = CGAffineTransformScale(self.transform, 200.0/148.0, 200.0/148.0);
    }];
}

- (void)resetScale{
    [UIView animateWithDuration:0.25 animations:^{
        self.centerLayer.transform = CATransform3DIdentity;
        self.transform = CGAffineTransformIdentity;
    }];
}

- (void)setProgress:(CGFloat)progress
{
    _progress = progress;
    
    _progressLayer.strokeEnd = progress;
    [_progressLayer removeAllAnimations];
}

/**
 *  配置点击事件
 */
- (void)configureTapCameraButtonEventWithBlock:(TapEventBlock)tapEventBlock
{
    self.tapEventBlock = tapEventBlock;
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapCameraButtonEvent:)];
    
    [self addGestureRecognizer:tapGestureRecognizer];
}

- (void)tapCameraButtonEvent:(UITapGestureRecognizer *)tapGestureRecognizer
{
    if (self.tapEventBlock)
    {
        self.tapEventBlock(tapGestureRecognizer);
    }
}

/**
 *  配置按压事件
 */
- (void)configureLongPressCameraButtonEventWithBlock:(LongPressEventBlock)longPressEventBlock
{
    self.longPressEventBlock = longPressEventBlock;
    
    UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressCameraButtonEvent:)];
    
    [self addGestureRecognizer:longPressGestureRecognizer];
}

- (void)longPressCameraButtonEvent:(UILongPressGestureRecognizer *)longPressGestureRecognizer
{
    if (self.longPressEventBlock)
    {
        self.longPressEventBlock(longPressGestureRecognizer);
    }
}


@end
