//
//  MusicBroswerViewController.h
//  SonosMusicServicesBrowser
//
//  Created by Drew Ingebretsen on 11/10/13.
//  Copyright (c) 2013 Drew Ingebretsen. All rights reserved.
//

#import <UIKit/UIKit.h>
@class SonosMusicService;

@interface MusicBroswerViewController : UIViewController
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSArray *musicItems;
@property (nonatomic,strong) SonosMusicService *service;
@end
