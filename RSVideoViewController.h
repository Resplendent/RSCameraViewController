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

typedef enum{
    RSVideoViewControllerCameraStateNone = 0,
    RSVideoViewControllerCameraStateBackCamera = 100,
    RSVideoViewControllerCameraStateFrontCamera,
}RSVideoViewControllerCameraState;

@interface RSVideoViewController : UIViewController
{
//    AVCaptureStillImageOutput* _stillOutput;
//    AVCaptureSession* _session;
    
//    float _barHeight;
}

-(void)switchCameras;

//-(void)captureImage;

//-(void)cameraFocusAtPoint:(CGPoint)point;

//-(BOOL)setCaptureFlashMode:(AVCaptureFlashMode)mode;

//@property(nonatomic) BOOL isFront;

@property (nonatomic, assign) BOOL enableCameraCapture;

//@property (nonatomic, assign) CGFloat topPadding;

@property(nonatomic, assign)id <RSVideoViewControllerDelegate> delegate;
@property(nonatomic, readonly) RSVideoViewControllerCameraState cameraState;

@property(readonly) AVCaptureVideoPreviewLayer* previewLayer;

@property(nonatomic, readonly) AVCaptureDevice* frontCamera;

@property(nonatomic, readonly) AVCaptureDeviceInput* frontCameraInput;

//@property(nonatomic, readonly) AVCaptureDeviceInput* backCameraInput;

@property(nonatomic, readonly) AVCaptureConnection* videoConnection;

@end