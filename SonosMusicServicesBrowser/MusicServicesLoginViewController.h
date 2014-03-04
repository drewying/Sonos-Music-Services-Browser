//
//  MusicServicesLoginViewController.h
//  SonosMusicServicesBrowser
//
//  Created by Drew Ingebretsen on 11/17/13.
//  Copyright (c) 2013 Drew Ingebretsen. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SonosMusicService;

@interface MusicServicesLoginViewController : UIViewController
@property (nonatomic, strong) SonosMusicService *musicService;
@end
