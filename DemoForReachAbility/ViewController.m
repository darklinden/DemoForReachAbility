//
//  ViewController.m
//  DemoForReachAbility
//
//  Created by DarkLinden on 3/11/13.
//  Copyright (c) 2013 darklinden. All rights reserved.
//

#import "ViewController.h"
#import "CusomizeReachability.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [btn setTitle:@"check" forState:UIControlStateNormal];
    btn.frame = CGRectMake((self.view.frame.size.width - 100.f) / 2.f, (self.view.frame.size.height - 35.f) / 2.f, 100.f, 35.f);
    [btn addTarget:self action:@selector(checkReachAbility) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
}

- (void)checkReachAbility
{
    NSLog(@"[CusomizeReachability isReachable] %d", [CusomizeReachability isReachable]);
}

@end
