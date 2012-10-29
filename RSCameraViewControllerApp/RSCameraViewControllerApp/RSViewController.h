//
//  RSViewController.h
//  RSCameraViewControllerApp
//
//  Created by Sheldon on 10/29/12.
//  Copyright (c) 2012 Resplendent G.P. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "RSVideoViewController.h"

@interface RSViewController : UIViewController

@property(nonatomic, retain) RSVideoViewController* videoViewController;

@property(nonatomic, retain) UIButton* button1;
@property(nonatomic, retain) UIButton* button2;
@property(nonatomic, retain) UIButton* button3;

@end
