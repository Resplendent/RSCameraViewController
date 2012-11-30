//
//  RSVideoViewController
//
//  Created by Sheldon Thomas on 6/24/12.
//  Copyright (c) 2012 Resplendent G.P. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RSVideoViewController;

@protocol RSVideoViewControllerDelegate <NSObject>

-(void)cameraCaptureDidFinish:(RSVideoViewController*)cameraViewController withImage:(UIImage*)image;
-(void)cameraCaptureDidFail:(RSVideoViewController*)cameraViewController andError:(NSError*)error;

@end


@interface RSVideoViewController : UIViewController
{
    AVCaptureDevice* backCamera;
    AVCaptureStillImageOutput* stillOutput;
    AVCaptureSession* session;
    
    AVCaptureDevice* frontCamera;
    
    AVCaptureDeviceInput* frontCameraInput;
    AVCaptureDeviceInput* backCameraInput;
    
    AVCaptureConnection *videoConnection;

    BOOL isFront;
    
    float _barHeight;
}

-(void)switchCameras;

-(void)captureImage;

-(void)rearCameraFocusAtPoint:(CGPoint)point;

-(BOOL)setCaptureFlashMode:(AVCaptureFlashMode)mode;

@property(nonatomic, assign)id <RSVideoViewControllerDelegate> delegate;

@end