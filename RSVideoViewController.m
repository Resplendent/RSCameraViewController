//
//
//  RSVideoViewController
//
//  Created by Sheldon Thomas on 6/24/12.
//  Copyright (c) 2012 Resplendent G.P. All rights reserved.
//

#import "RSVideoViewController.h"

@interface RSVideoViewController ()


@end

@implementation RSVideoViewController

@synthesize delegate = _delegate;

UIImage *imageFromSampleBuffer(CMSampleBufferRef sampleBuffer) {
    
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // Lock the base address of the pixel buffer.
    CVPixelBufferLockBaseAddress(imageBuffer,0);
    
    // Get the number of bytes per row for the pixel buffer.
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // Get the pixel buffer width and height.
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // Create a device-dependent RGB color space.
    static CGColorSpaceRef colorSpace = NULL;
    if (colorSpace == NULL) {
        colorSpace = CGColorSpaceCreateDeviceRGB();
        if (colorSpace == NULL) {
            // Handle the error appropriately.
            return nil;
        }
    }
    
    // Get the base address of the pixel buffer.
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    // Get the data size for contiguous planes of the pixel buffer.
    size_t bufferSize = CVPixelBufferGetDataSize(imageBuffer);
    
    // Create a Quartz direct-access data provider that uses data we supply.
    CGDataProviderRef dataProvider =
    CGDataProviderCreateWithData(NULL, baseAddress, bufferSize, NULL);
    // Create a bitmap image from data supplied by the data provider.
    CGImageRef cgImage =
    CGImageCreate(width, height, 8, 32, bytesPerRow,
                  colorSpace, kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Little,
                  dataProvider, NULL, true, kCGRenderingIntentDefault);
    CGDataProviderRelease(dataProvider);
    
    // Create and return an image object to represent the Quartz image.
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    
    return image;
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
            NSData* imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
            [_delegate cameraCaptureDidFinish:self andUIImageData:imageData];
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

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSLog(@"Camera Bool State Changed To %@ from %@", [change objectForKey:@"new"], [change objectForKey:@"old"]);
}

- (void)viewDidLoad
{
    session = [[AVCaptureSession alloc]init];
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
    
    [stillOutput addObserver:self forKeyPath:@"capturingStillImage" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    
    if ([session canAddOutput:stillOutput])
        [session addOutput:stillOutput];
    
    
    CGRect previewFrame = CGRectMake(0, 0, 320, 390);
    
    CGRect bounds = CGRectMake(0, 70, 320, 390);
    
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

- (void)viewDidUnload
{
    [stillOutput removeObserver:self forKeyPath:@"capturingStillImage"];
    [session stopRunning];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end
