RSCameraViewController
======================

Customizable View Controller which opens a channel to both cameras where hardware is available.

### RSVideoViewController

This is a class which opens a connection to both the front and back cameras on a layer within itself.

The preview layer's size and relative position can be adjusted by changing

	CGRect previewFrame = CGRectMake(0, 0, 320, 390);
	CGRect bounds = CGRectMake(0, 70, 320, 390);
    
It has API's for switching cameras and grabbing a photo, which is informed with the delegate pattern.

	-(void)switchCameras;
	-(void)captureImage;
	
	
## RACameraViewControllerApp

Has a single view controller which shows the correct implementation of the the RSVideoViewController