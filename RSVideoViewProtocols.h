//
//  RSVideoViewProtocols.h
//  Albumatic
//
//  Created by Benjamin Maer on 9/23/13.
//  Copyright (c) 2013 Albumatic Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RSVideoView;

@protocol RSVideoViewImageTakingDelegate <NSObject>

-(void)videoView:(RSVideoView*)videoView didFinishImageCaptureWithImage:(UIImage*)image;
-(void)videoView:(RSVideoView*)videoView didFinishImageCaptureWithError:(NSError*)error;
-(void)videoViewFailedImageCaptureDueToNoVideoConnection:(RSVideoView*)videoView;

@end
