//
//  RSVideoView.h
//  Albumatic
//
//  Created by Benjamin Maer on 9/23/13.
//  Copyright (c) 2013 Albumatic Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RSVideoViewProtocols.h"

typedef enum{
    RSVideoViewCameraStateNone = 0,
    RSVideoViewCameraStateBackCamera = 100,
    RSVideoViewCameraStateFrontCamera,
}RSVideoViewCameraState;

@interface RSVideoView : UIView
{
    AVCaptureVideoPreviewLayer* _previewLayer;
    AVCaptureConnection* _videoConnection;

    AVCaptureDeviceInput* _backCameraInput;
    AVCaptureDeviceInput* _frontCameraInput;
}

@property (nonatomic, assign) BOOL enableCameraCapture;

@property (nonatomic, assign) id<RSVideoViewImageTakingDelegate> imageTakingDelegate;
@property (nonatomic, assign) RSVideoViewCameraState cameraState;

@property (nonatomic, readonly) BOOL isVideoConnectionMirrored;
@property (nonatomic, readonly) NSString* previewLayerVideoGravity;

@property (nonatomic, readonly) AVCaptureDevice* captureDeviceForCurrentCameraState;
@property (nonatomic, readonly) AVCaptureDeviceInput* captureDeviceInputForCurrentCameraState;

-(void)captureCurrentImage;

-(void)focusCameraAtPoint:(CGPoint)point;

-(BOOL)setCaptureFlashMode:(AVCaptureFlashMode)mode;

@end
