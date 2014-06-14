//
//  BCOViewController.m
//  Draggable
//
//  Created by 阿部耕平 on 2014/06/09.
//  Copyright (c) 2014年 Kohei Abe. All rights reserved.
//

#import "BCOViewController.h"
#import "UIView+BCODraggable.h"
#import "BCOCustomView.h"

@interface BCOViewController ()
- (IBAction)didTouchButton:(id)sender;
@end

@implementation BCOViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    BCOCustomView *view = [[BCOCustomView alloc] initWithFrame:CGRectMake(100, 100, 100, 100)];
    view.backgroundColor = [UIColor redColor];
    [self.view addSubview:view];
    view.draggable = YES;
    
    UIView *view2 = [[UIView alloc] initWithFrame:CGRectMake(200, 200, 50, 50)];
    view2.backgroundColor = [UIColor blueColor];
    [self.view addSubview:view2];
    view2.draggable = YES;
    
    UIControl *control = [[UIControl alloc] initWithFrame:CGRectMake(50, 50, 10, 10)];
    control.backgroundColor = [UIColor greenColor];
    [self.view addSubview:control];
    control.draggable = YES;
    
    UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectMake(50, 300, 100, 100)];
    [self.view addSubview:switchView];
    switchView.draggable = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)didTouchButton:(id)sender
{
    for (UIView *view in self.view.subviews) {
        view.draggable = !view.draggable;
    }
}
@end
