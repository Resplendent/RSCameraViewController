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

@synthesize button1 = _button1;
@synthesize button2 = _button2;
@synthesize button3 = _button3;

-(void)cameraCaptureDidFinish:(RSVideoViewController *)cameraViewController andUIImageData:(NSData *)imageData
{
    NSLog(@"Recieved ImageData size %ul", imageData.length);
    /*
     
     Implement custom logic to manipulate the image here.
     
     CGFilters, shapes, etc.
     
     Save or do a multipart upload with it
     
     */
}

-(void)cameraCaptureDidFail:(RSVideoViewController *)cameraViewController andError:(NSError *)error
{
    NSLog(@"Error Taking Photo %@", error.localizedDescription);
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _videoViewController = [[RSVideoViewController alloc]initWithNibName:nil bundle:nil];
    
    [_videoViewController setDelegate:self];
    
    [_videoViewController.view setFrame:CGRectMake(0, 0, 320, 300)];
    
    isCameraBackfacing = YES;
    [self addChildViewController:_videoViewController];
    [self.view addSubview:_videoViewController.view];
    
    [self setButton1:[UIButton buttonWithType:UIButtonTypeRoundedRect]];
    
    [_button1 setTitle:@"Take Photo" forState:UIControlStateNormal];
    
    [_button1 setFrame:CGRectMake((self.view.frame.size.width / 2) - 100, 10, 200, 50)];
    
    [_button1 addTarget:_videoViewController action:@selector(captureImage) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:_button1];
    
    [self setButton2:[UIButton buttonWithType:UIButtonTypeRoundedRect]];
    
    [_button2 setTitle:@"Swap" forState:UIControlStateNormal];
    
    [_button2 setFrame:CGRectMake((self.view.frame.size.width / 2) - 70, self.view.frame.size.height - 80, 140, 60)];
    
    [_button2 addTarget:_videoViewController action:@selector(switchCameras) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:_button2];
    
    /*
     
     Build custom UI Components
     
     Buttons, switches, statuses, and add them to self subview
     
     */
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
