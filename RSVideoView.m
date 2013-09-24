//
//  RSVideoView.m
//  Albumatic
//
//  Created by Benjamin Maer on 9/23/13.
//  Copyright (c) 2013 Albumatic Inc. All rights reserved.
//

#import "RSVideoView.h"

#import "RUConstants.h"

@interface RSVideoView ()

@property(nonatomic, strong) AVCaptureStillImageOutput* stillOutput;;
@property(nonatomic, strong) AVCaptureSession* session;

@property(nonatomic, strong) AVCaptureDevice* backCamera;
@property(nonatomic, strong) AVCaptureDevice* frontCamera;

@property(nonatomic, readonly) CGRect previewLayerFrame;

-(AVCaptureDeviceInput*)captureDeviceInputForCameraState:(RSVideoViewCameraState)cameraState;
-(AVCaptureDevice*)captureDeviceForCameraState:(RSVideoViewCameraState)cameraState;

-(void)setCameraStateToBack;
-(void)setCameraStateToFront;

@end

@implementation RSVideoView

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        // Initialization code
        _previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
//        [_previewLayer setBackgroundColor:[UIColor redColor].CGColor];
//        [_previewLayer setFrame:previewFrame];
        _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
//        _previewLayer.bounds = bounds;
//        _previewLayer.position=CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
        [self.layer addSublayer:_previewLayer];

        [self recycleVideoConnection];
    }

    return self;
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    [_previewLayer setFrame:self.previewLayerFrame];
//    [_previewLayer setBounds:self.bounds];
//    [_previewLayer setPosition:(CGPoint){CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds)}];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"adjustingExposure"])
    {
        if ([[change objectForKey:@"new"] intValue])
        {
            //            NSLog(@"Started Exposure");
        }
        else
        {
            //            NSLog(@"Ending Exposure");
        }
    }
    else if ([keyPath isEqualToString:@"adjustingFocus"])
    {
        if ([[change objectForKey:@"new"] intValue])
        {
            //            NSLog(@"Started Focus");
        }
        else
        {
            NSError* lockError = nil;
            [self.backCamera lockForConfiguration:&lockError];
            if (lockError)
            {
                RUDLog(@"lockError: %@",lockError);
            }
            else
            {
                [self.backCamera setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
                [self.backCamera unlockForConfiguration];
            }
            //            NSLog(@"End Focus, Locked.");
        }
    }
    else
    {
        RUDLog(@"Odd Keypath %@", keyPath);
    }
}


#pragma mark - Frames
-(CGRect)previewLayerFrame
{
    return self.bounds;
}

#pragma mark - Load on demand
-(AVCaptureStillImageOutput *)stillOutput
{
    if (!_stillOutput)
    {
        _stillOutput = [AVCaptureStillImageOutput new];
        NSDictionary* newOutput = @{[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA] : (id)kCVPixelBufferPixelFormatTypeKey, AVVideoCodecJPEG : AVVideoCodecKey};
        [_stillOutput setOutputSettings:newOutput];
        
        if ([self.session canAddOutput:_stillOutput])
        {
            [self.session addOutput:_stillOutput];
        }
        else
        {
            RUDLog(@"couldn't add output %@ to session %@",_stillOutput,self.session);
        }
    }
    
    return _stillOutput;
}

-(AVCaptureSession *)session
{
    if (!_session)
    {
        _session = [AVCaptureSession new];
        if ([_session canSetSessionPreset:AVCaptureSessionPresetPhoto])
            [_session setSessionPreset:AVCaptureSessionPresetPhoto];
    }
    
    return _session;
}

#pragma mark - Camera Setters
-(void)setFrontCamera:(AVCaptureDevice *)frontCamera
{
    if (self.frontCamera == frontCamera)
        return;

    _frontCamera = frontCamera;

    if (_frontCamera)
    {
        NSError* error = nil;
        _frontCameraInput = [AVCaptureDeviceInput deviceInputWithDevice:_frontCamera error:&error];
    }
}

-(void)setBackCamera:(AVCaptureDevice *)backCamera
{
    if (self.backCamera == backCamera)
        return;
    
    if (self.backCamera)
    {
        [self.backCamera removeObserver:self forKeyPath:@"adjustingExposure"];
        [self.backCamera removeObserver:self forKeyPath:@"adjustingFocus"];
    }
    
    _backCamera = backCamera;
    
    if (self.backCamera)
    {
        NSError* error = nil;
        [self.backCamera lockForConfiguration:&error];
        
        if (error)
        {
            RUDLog(@"error: %@",error);
        }
        else
        {
            //White balance
            if ([self.backCamera isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance])
            {
                [self.backCamera lockForConfiguration:nil];
                
                [self.backCamera setWhiteBalanceMode:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance];
                if ([self.backCamera isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus])
                {
                    [self.backCamera setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
                }
                
                [self.backCamera unlockForConfiguration];
            }
            
            //Low light boost
            if ([self.backCamera respondsToSelector:@selector(isLowLightBoostSupported)])
            {
                if ([self.backCamera isLowLightBoostSupported])
                {
                    NSError* error = nil;
                    [self.backCamera lockForConfiguration:&error];
                    
                    if (error)
                    {
                        RUDLog(@"error: %@",error);
                    }
                    else
                    {
                        [self.backCamera setAutomaticallyEnablesLowLightBoostWhenAvailable:YES];
                    }
                    
                    [self.backCamera unlockForConfiguration];
                }
            }
            
            [self.backCamera unlockForConfiguration];
        }
        
        NSError* backCameraInputError = nil;
        _backCameraInput = [AVCaptureDeviceInput deviceInputWithDevice:self.backCamera error:&backCameraInputError];
        if (backCameraInputError)
        {
            RUDLog(@"backCameraInputError: %@",backCameraInputError);
        }

        [self.backCamera addObserver:self forKeyPath:@"adjustingExposure" options:NSKeyValueObservingOptionNew context:nil];
        [self.backCamera addObserver:self forKeyPath:@"adjustingFocus" options:NSKeyValueObservingOptionNew context:nil];
    }
}

#pragma mark - Recycle Video Connection
-(void)recycleVideoConnection
{
    _videoConnection = nil;
    [self.stillOutput.connections enumerateObjectsUsingBlock:^(AVCaptureConnection *connection, NSUInteger connectionIndex, BOOL *stillOutputConnectionsStop) {
        [[connection inputPorts] enumerateObjectsUsingBlock:^(AVCaptureInputPort *port, NSUInteger portIndex, BOOL *portStop) {
            if ([[port mediaType] isEqual:AVMediaTypeVideo] )
            {
                _videoConnection = connection;
                *portStop = YES;
                *stillOutputConnectionsStop = YES;
            }
        }];
    }];
}

-(void)dealloc
{
    [self setImageTakingDelegate:nil];
    [self setBackCamera:nil];
    [self setEnableCameraCapture:NO];
}

#pragma mark - Capture Current Image
-(void)captureCurrentImage
{
    [self recycleVideoConnection];
    
    if (_videoConnection)
    {
        [self.stillOutput captureStillImageAsynchronouslyFromConnection:_videoConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error){
            if (self.imageTakingDelegate)
            {
                if (error)
                {
                    [self.imageTakingDelegate videoView:self didFinishImageCaptureWithError:error];
                }
                else
                {
                    NSData* imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                    UIImage* captureImage = [UIImage imageWithData:imageData];
                    
                    [self.imageTakingDelegate videoView:self didFinishImageCaptureWithImage:captureImage];
                }
            }
        }];
    }
    else
    {
        [self.imageTakingDelegate videoViewFailedImageCaptureDueToNoVideoConnection:self];
    }
}

#pragma mark - Capure Device Getter
-(AVCaptureDevice *)captureDeviceForCurrentCameraState
{
    return [self captureDeviceForCameraState:self.cameraState];
}

-(AVCaptureDevice*)captureDeviceForCameraState:(RSVideoViewCameraState)cameraState
{
    switch (cameraState)
    {
        case RSVideoViewCameraStateNone:
            return nil;
        case RSVideoViewCameraStateBackCamera:
            return self.backCamera;
        case RSVideoViewCameraStateFrontCamera:
            return self.frontCamera;
    }
}

#pragma mark - Capure Device Input Getter
-(AVCaptureDeviceInput *)captureDeviceInputForCurrentCameraState
{
    return [self captureDeviceInputForCameraState:self.cameraState];
}

-(AVCaptureDeviceInput*)captureDeviceInputForCameraState:(RSVideoViewCameraState)cameraState
{
    switch (cameraState)
    {
        case RSVideoViewCameraStateNone:
            return nil;
        case RSVideoViewCameraStateBackCamera:
            return _backCameraInput;
        case RSVideoViewCameraStateFrontCamera:
            return _frontCameraInput;
    }
}

#pragma mark - Set Camera State
-(void)setCameraState:(RSVideoViewCameraState)cameraState
{
    if (self.cameraState == cameraState)
        return;
    
    AVCaptureDeviceInput* oldCurrentCaptureDeviceInput = [self captureDeviceInputForCameraState:self.cameraState];
    if (oldCurrentCaptureDeviceInput)
    {
        if ([self.session.inputs containsObject:oldCurrentCaptureDeviceInput])
        {
            [self.session removeInput:oldCurrentCaptureDeviceInput];
        }
        else
        {
            RUDLog(@"currentCaptureDeviceInput %@ not in current session inputs %@",oldCurrentCaptureDeviceInput,self.session.inputs);
        }
    }
    
    _cameraState = cameraState;
    
    switch (self.cameraState)
    {
        case RSVideoViewCameraStateBackCamera:
            [self setCameraStateToBack];
            break;

        case RSVideoViewCameraStateFrontCamera:
            [self setCameraStateToFront];
            break;

        default:
            RUDLog(@"No action for state %i",self.cameraState);
            break;
    }

    AVCaptureDeviceInput* newCurrentCaptureDeviceInput = [self captureDeviceInputForCameraState:self.cameraState];
    if (newCurrentCaptureDeviceInput)
    {
        if ([self.session.inputs containsObject:newCurrentCaptureDeviceInput])
        {
            RUDLog(@"currentCaptureDeviceInput %@ already in session inputs %@",newCurrentCaptureDeviceInput,self.session.inputs);
        }
        else
        {
            [self.session addInput:newCurrentCaptureDeviceInput];
        }
    }
}

-(void)setCameraStateToBack
{
    if (!self.backCamera)
    {
        [[AVCaptureDevice devices] enumerateObjectsUsingBlock:^(AVCaptureDevice* device, NSUInteger idx, BOOL *stop) {
            if ([device position] == AVCaptureDevicePositionBack)
            {
                [self setBackCamera:device];
                *stop = YES;
            }
        }];
    }
}

-(void)setCameraStateToFront
{
    if (!self.frontCamera)
    {
        [[AVCaptureDevice devices] enumerateObjectsUsingBlock:^(AVCaptureDevice* device, NSUInteger idx, BOOL *stop) {
            if ([device position] == AVCaptureDevicePositionFront)
            {
                [self setFrontCamera:device];
                *stop = YES;
            }
        }];
    }
}

#pragma mark - Camera Focus
-(void)focusCameraAtPoint:(CGPoint)point
{
    AVCaptureDevice* captureDevice = [self captureDeviceForCameraState:self.cameraState];
    if (captureDevice)
    {
        if ([self.session.inputs containsObject:captureDevice])
        {
            if ([captureDevice isFocusPointOfInterestSupported] && [captureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus] && [captureDevice isExposurePointOfInterestSupported])
            {
                NSError* error = nil;
                [captureDevice lockForConfiguration:&error];

                if (error)
                {
                    RUDLog(@"error: %@",error);
                }
                else
                {
                    if ([captureDevice isExposurePointOfInterestSupported] && [captureDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure])
                    {
                        [captureDevice setExposurePointOfInterest:point];
                        [captureDevice setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
                    }
                    if ([captureDevice isFocusPointOfInterestSupported])
                    {
                        [captureDevice setFocusPointOfInterest:point];
                        [captureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
                    }
                    [captureDevice unlockForConfiguration];
                }
            }
        }
        else
        {
            RUDLog(@"current capture device %@ during state %i is not contained in session's %@ inputs %@",captureDevice,self.cameraState,self.session,self.session.inputs);
        }
    }
}

#pragma mark - Capture Flash Mode
-(BOOL)setCaptureFlashMode:(AVCaptureFlashMode)mode
{
    if ([_backCamera isFlashModeSupported:mode])
    {
        NSError* error = nil;
        [_backCamera lockForConfiguration:&error];
        
        if (error)
        {
            RUDLog(@"error: %@",error);
        }
        else
        {
            [_backCamera setFlashMode:mode];
            [_backCamera unlockForConfiguration];
            return YES;
        }
    }

    return NO;
}

#pragma mark - Getters
-(NSString *)previewLayerVideoGravity
{
    return _previewLayer.videoGravity;
}

-(BOOL)isVideoConnectionMirrored
{
    return _videoConnection.isVideoMirrored;
}

#pragma mark - enableCameraCapture
-(BOOL)enableCameraCapture
{
    return self.session.isRunning;
}

-(void)setEnableCameraCapture:(BOOL)enableCameraCapture
{
    if (self.enableCameraCapture == enableCameraCapture)
        return;
    
    if (enableCameraCapture)
    {
        [self.session startRunning];
    }
    else
    {
        [self.session stopRunning];
    }
}

@end
