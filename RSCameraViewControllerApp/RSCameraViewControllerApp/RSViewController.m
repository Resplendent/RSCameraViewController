//
//  RSViewController.m
//  RSCameraViewControllerApp
//
//  Created by Sheldon on 10/29/12.
//  Copyright (c) 2012 Resplendent G.P. All rights reserved.
//

#import "RSViewController.h"



@interface RSViewController ()
{
    BOOL isCameraBackfacing;
}
@end

@implementation RSViewController

@synthesize videoViewController = _videoViewController;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.

    _videoViewController = [[RSVideoViewController alloc]initWithNibName:nil bundle:nil];
    
    [_videoViewController.view setFrame:CGRectMake(0, 0, 320, 300)];
    
    isCameraBackfacing = YES;
    [self addChildViewController:_videoViewController];
    [self.view addSubview:_videoViewController.view];
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
