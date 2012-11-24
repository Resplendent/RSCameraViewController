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

/*
 - (CGImageRef) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer // Create a CGImageRef from sample buffer data
 {
 CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
 CVPixelBufferLockBaseAddress(imageBuffer,0);        // Lock the image buffer
 
 uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);   // Get information of the image
 size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
 size_t width = CVPixelBufferGetWidth(imageBuffer);
 size_t height = CVPixelBufferGetHeight(imageBuffer);
 CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
 
 CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
 CGImageRef newImage = CGBitmapContextCreateImage(newContext);
 CGContextRelease(newContext);
 
 CGColorSpaceRelease(colorSpace);
 CVPixelBufferUnlockBaseAddress(imageBuffer,0);

return newImage;
}
 */

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
    videoConnection = nil;
    for (AVCaptureConnection *connection in stillOutput.connections) {
        for (AVCaptureInputPort *port in [connection inputPorts]) {
            if ([[port mediaType] isEqual:AVMediaTypeVideo] ) {
                videoConnection = connection;
                break;
            }
        }
        if (videoConnection) { break; }
    }
}

-(void)recycleConnection
{
    if ([videoConnection respondsToSelector:@selector(isActive)])
    {
        if (![videoConnection isActive])
        {
            [self doRecycle];
        }
    }
}

-(void)captureImage
{
    [self recycleConnection];
    
    [stillOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error){
        if (error)
            [_delegate cameraCaptureDidFail:self andError:error];
        
        else
        {
//            NSData* imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
            
            UIImage* i = [self imageFromSampleBuffer:imageDataSampleBuffer];
            
//            UIImage* i = [UIImage imageWithData:imageData];
            
            [_delegate cameraCaptureDidFinish:self withImage:i];
        }
    }];
}


-(AVCaptureDevice*)getBackCamera
{
    NSArray* devices = [AVCaptureDevice devices];
    for (AVCaptureDevice* device in devices) {
        if ([device position] == AVCaptureDevicePositionBack)
            return device;
    }
    return nil;
}

-(AVCaptureDevice*)getFrontCamera
{
    NSArray* devices = [AVCaptureDevice devices];
    for (AVCaptureDevice* device in devices) {
        if ([device position] == AVCaptureDevicePositionFront)
            return device;
    }
    return nil;
}

-(void)switchCameras
{
    if (!frontCamera)
    {
        frontCamera = [self getFrontCamera];
        NSError* e = nil;
        frontCameraInput = [[AVCaptureDeviceInput alloc] initWithDevice:frontCamera error:&e];
        if (e)
            NSLog(@"Error initalizing the Front Camera Capture Device");
        
    }
    if ([[session inputs] containsObject:backCameraInput])
        [session removeInput:backCameraInput];
    
    if ([[session inputs] containsObject:frontCameraInput])
        [session removeInput:frontCameraInput];
    
    
    isFront ? [session addInput:frontCameraInput]:[session addInput:backCameraInput];
    
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
    session = [[AVCaptureSession alloc]init];
    if ([session canSetSessionPreset:AVCaptureSessionPresetPhoto])
        [session setSessionPreset:AVCaptureSessionPresetPhoto];
    backCamera = [self getBackCamera];
    
    NSError* e = nil;
    
    if (backCamera)
    {
        backCameraInput = [[AVCaptureDeviceInput alloc]initWithDevice:backCamera error:&e];
        if (e)
            NSLog(@"Error setting BackCameraInput %@", e.localizedDescription);
        if ([session canAddInput:backCameraInput])
        {
            [session addInput:backCameraInput];
        }
    }
    
    stillOutput = [[AVCaptureStillImageOutput alloc]init];

    
    NSDictionary *outputSettings = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA], (id)kCVPixelBufferPixelFormatTypeKey, nil];
    
    [stillOutput setOutputSettings:outputSettings];

    if ([session canAddOutput:stillOutput])
        [session addOutput:stillOutput];
    
    /*
     Adjust this to change the size of the preview frame
     */

    CGRect previewFrame = self.view.frame;
    /*
     Adjust the position of the preview frame
     */
    
    CGRect bounds = CGRectMake(0, 0, 320, self.view.frame.size.height - _barHeight);
    
//    CGRect bounds = self.view.bounds;
    
    AVCaptureVideoPreviewLayer* previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:session];
    [previewLayer setFrame:previewFrame];
    previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    previewLayer.bounds = bounds;
    previewLayer.position=CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
    
    [self.view.layer addSublayer:previewLayer];
    
    [self doRecycle];
    
    isFront = YES;
    
    [super viewDidLoad];
}

-(void)viewDidAppear:(BOOL)animated
{
    [session startRunning];
    [super viewDidAppear:animated];
}

/*-(void)dealloc
{
    [stillOutput removeObserver:self forKeyPath:@"capturingStillImage"];
}

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        [stillOutput addObserver:self forKeyPath:@"capturingStillImage" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    }
    return self;
}
 */

- (void)viewDidUnload
{
    [session stopRunning];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end
