//
//  ViewController.m
//  PPRecordVideo
//
//  Created by 盼 on 2019/5/16.
//  Copyright © 2019 pan. All rights reserved.
//

#import "ViewController.h"
#import "PPRecordViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    UIButton *recordButton = [UIButton buttonWithType:UIButtonTypeCustom];
    recordButton.frame = CGRectMake(100, 100, 100, 40);
    [recordButton setTitle:@"录制视频" forState:UIControlStateNormal];
    [recordButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [recordButton addTarget:self action:@selector(recordBtnDidClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:recordButton];
}

- (void)recordBtnDidClick
{
    PPRecordViewController *recordVC = [[PPRecordViewController alloc] init];
    [self presentViewController:recordVC animated:YES completion:^{
        
    }];
}


@end
