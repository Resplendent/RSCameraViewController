//
//
//  RSVideoViewController
//
//  Created by Sheldon Thomas on 6/24/12.
//  Copyright (c) 2012 Resplendent G.P. All rights reserved.
//

#import "RSVideoViewController.h"
#import "UIImage+Extensions.h"

@interface RSVideoViewController ()


@end

@implementation RSVideoViewController

@synthesize delegate = _delegate;

@synthesize isFront;

-(CGRect)video_previewLayerFrame
{
    return _previewLayer.frame;
}


- (UIImage*)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    /*Lock the image buffer*/
    CVPixelBufferLockBaseAddress(imageBuffer,0);
    /*Get information about the image*/
    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    /*We unlock the  image buffer*/
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    /*Create a CGImageRef from the CVImageBufferRef*/
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGImageRef newImage = CGBitmapContextCreateImage(newContext);
    
    /*We release some components*/
    CGContextRelease(newContext);
    CGColorSpaceRelease(colorSpace);
    
    /*We display the result on the custom layer*/
    /*self.customLayer.contents = (id) newImage;*/
    
    /*We display the result on the image view (We need to change the orientation of the image so that the video is displayed correctly)*/
    UIImage *image= [UIImage imageWithCGImage:newImage scale:1.0 orientation:UIImageOrientationRight];

    /*We relase the CGImageRef*/
    CGImageRelease(newImage);
    return image;
}

- (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer
{
    // Get a CMSampleBuffer's Core Video image buffer for the media data
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // Lock the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // Get the number of bytes per row for the pixel buffer
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    // Get the number of bytes per row for the pixel buffer
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // Get the pixel buffer width and height
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // Create a device-dependent RGB color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // Create a bitmap graphics context with the sample buffer data
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
                                                 bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    // Create a Quartz image from the pixel data in the bitmap graphics context
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // Unlock the pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    // Free up the context and color space
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    // Create an image object from the Quartz image
    UIImage *image = [UIImage imageWithCGImage:quartzImage];
    
    // Release the Quartz image
    CGImageRelease(quartzImage);
    
    return (image);
}

-(void)doRecycle
{
    _videoConnection = nil;
    for (AVCaptureConnection *connection in stillOutput.connections) {
        for (AVCaptureInputPort *port in [connection inputPorts]) {
            if ([[port mediaType] isEqual:AVMediaTypeVideo] ) {
                _videoConnection = connection;
                break;
            }
        }
        if (_videoConnection) { break; }
    }
}

-(void)recycleConnection
{
    if ([_videoConnection respondsToSelector:@selector(isActive)])
    {
        if (![_videoConnection isActive])
        {
            [self doRecycle];
        }
    }
}

-(void)captureImageWithCompletionBlock:(void(^)())completion
{
    [self doRecycle];
    
    [stillOutput captureStillImageAsynchronouslyFromConnection:_videoConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error){
        if (error)
            [_delegate cameraCaptureDidFail:self andError:error];
        
        else
        {
            NSData* imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
            
//            UIImage* i = [self imageFromSampleBuffer:imageDataSampleBuffer];
            
            UIImage* i = [UIImage imageWithData:imageData];
            
            [_delegate cameraCaptureDidFinish:self withImage:i];
        }

        if (completion)
            completion();
    }];
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
            [_backCamera lockForConfiguration:nil];
            [_backCamera setFocusMode:AVCaptureFocusModeLocked];
            [_backCamera unlockForConfiguration];
//            NSLog(@"End Focus, Locked.");
        }
    }
    else
        NSLog(@"Odd Keypath %@", keyPath);
}


-(void)switchCameras
{
    if (!_frontCamera)
    {
        _frontCamera = [self get_frontCamera];
        NSError* e = nil;
        _frontCameraInput = [[AVCaptureDeviceInput alloc] initWithDevice:_frontCamera error:&e];
        if (e)
            NSLog(@"Error initalizing the Front Camera Capture Device");
        
    }
    if ([[session inputs] containsObject:_backCameraInput])
        [session removeInput:_backCameraInput];
    
    if ([[session inputs] containsObject:_frontCameraInput])
        [session removeInput:_frontCameraInput];
    
    
    isFront ? [session addInput:_backCameraInput]:[session addInput:_frontCameraInput];
    isFront = !isFront;
}

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        CGSize _screenSize = [[UIScreen mainScreen]bounds].size;
        if (_screenSize.height > 480)
        {
            _barHeight = 96.0f;
        }
        else
        {
            _barHeight = 53.0f;
        }
    }
    return self;
}

- (void)viewDidLoad
{
    [self.view setBackgroundColor:[UIColor clearColor]];
    session = [AVCaptureSession new];
    if ([session canSetSessionPreset:AVCaptureSessionPresetPhoto])
        [session setSessionPreset:AVCaptureSessionPresetPhoto];
    _backCamera = [self get_backCamera];
    if ([_backCamera respondsToSelector:@selector(isLowLightBoostSupported)])
    {
        if ([_backCamera isLowLightBoostSupported])
        {
            NSError* e = nil;
            [_backCamera lockForConfiguration:&e];
            if (e) @throw e;
            [_backCamera setAutomaticallyEnablesLowLightBoostWhenAvailable:YES];
            [_backCamera unlockForConfiguration];
        }
    }
    NSError* e;
    if (_backCamera)
    {
        _backCameraInput = [AVCaptureDeviceInput deviceInputWithDevice:_backCamera error:&e];
        if (e) @throw e;
        if ([session canAddInput:_backCameraInput])
            [session addInput:_backCameraInput];
    }
    
    stillOutput = [AVCaptureStillImageOutput new];
    
//    NSDictionary *outputSettings = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA], (id)kCVPixelBufferPixelFormatTypeKey, nil];
    
    NSDictionary* newOutput = @{[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA] : (id)kCVPixelBufferPixelFormatTypeKey, AVVideoCodecJPEG : AVVideoCodecKey};
    
    [stillOutput setOutputSettings:newOutput];
    
    if ([session canAddOutput:stillOutput])
        [session addOutput:stillOutput];
    

    CGRect previewFrame = self.view.frame;
    /*
     Adjust the position of the preview frame
     */
    
    CGRect bounds = CGRectMake(0, 0, 320, self.view.frame.size.height - _barHeight);
    
//    CGRect bounds = self.view.bounds;
    
    _previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:session];
    [_previewLayer setFrame:previewFrame];
    _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    _previewLayer.bounds = bounds;
    _previewLayer.position=CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
    
    [self.view.layer addSublayer:_previewLayer];
    
    [self doRecycle];
    
    isFront = NO;
    
    [super viewDidLoad];
}

-(void)viewDidAppear:(BOOL)animated
{
    [self setEnableCameraCapture:YES];
    [super viewDidAppear:animated];
}

-(BOOL)setCaptureFlashMode:(AVCaptureFlashMode)mode
{
    if ([_backCamera isFlashModeSupported:mode])
    {
        NSError* e = nil;
        [_backCamera lockForConfiguration:&e];
        
        if (e)
            return NO;
        else
        {
            [_backCamera setFlashMode:mode];
            return YES;
        }
    }
    else
        return NO;
}

-(AVCaptureDevice*)get_backCamera
{
    NSArray* devices = [AVCaptureDevice devices];
    for (AVCaptureDevice* device in devices) {
        if ([device position] == AVCaptureDevicePositionBack)
        {
            if ([device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance])
            {
                [device lockForConfiguration:nil];
                [device setWhiteBalanceMode:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance];
                [device unlockForConfiguration];
            }
            
//            if ([device isExposureModeSupported:AVCaptureExposureModeLocked])
//                NSLog(@"AVCaptureExposureModeLocked");
//            if ([device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure])
//                NSLog(@"AVCaptureExposureModeContinuousAutoExposure");
//            if ([device isExposureModeSupported:AVCaptureExposureModeAutoExpose])
//                NSLog(@"AVCaptureExposureModeAutoExpose");
            
            [device addObserver:self forKeyPath:@"adjustingExposure" options:NSKeyValueObservingOptionNew context:nil];
            [device addObserver:self forKeyPath:@"adjustingFocus" options:NSKeyValueObservingOptionNew context:nil];
            return device;
        }
    }
    return nil;
}

-(AVCaptureDevice*)get_frontCamera
{
    NSArray* devices = [AVCaptureDevice devices];
    for (AVCaptureDevice* device in devices) {
        if ([device position] == AVCaptureDevicePositionFront)
            return device;
    }
    return nil;
}


-(void)cameraFocusAtPoint:(CGPoint)point
{
    AVCaptureDevice* captureDevice;
    if ([[session inputs] containsObject:_frontCameraInput])
        captureDevice = _frontCamera;
    else
        captureDevice = _backCamera;
    if ([captureDevice isFocusPointOfInterestSupported] && [captureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus] && [captureDevice isExposurePointOfInterestSupported])
    {
        NSError* e = nil;
        if ([captureDevice lockForConfiguration:&e])
        {
            if (e)
            {NSLog(@"ERROR %@", e);return;}
            
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

- (void)viewDidUnload
{
    [self setEnableCameraCapture:NO];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark - Setter/Getter methods
-(BOOL)enableCameraCapture
{
    return session.isRunning;
}

-(void)setEnableCameraCapture:(BOOL)enableCameraCapture
{
    if (self.enableCameraCapture == enableCameraCapture)
        return;

    if (enableCameraCapture)
    {
        [session startRunning];
    }
    else
    {
        [session stopRunning];
    }
}

-(void)dealloc
{
    [_backCamera removeObserver:self forKeyPath:@"adjustingExposure"];
    [_backCamera removeObserver:self forKeyPath:@"adjustingFocus"];
}

@end
