//
//  MusicServicesOauthLoginViewController.h
//  SonosMusicServicesBrowser
//
//  Created by Drew Ingebretsen on 11/20/13.
//  Copyright (c) 2013 Drew Ingebretsen. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SonosMusicService;

@interface MusicServicesOauthLoginViewController : UIViewController
@property (nonatomic, strong) NSString* deviceLinkCode;
@property (nonatomic, strong) NSString *deviceLinkUrl;
@property (nonatomic, strong) SonosMusicService *musicService;
@end
