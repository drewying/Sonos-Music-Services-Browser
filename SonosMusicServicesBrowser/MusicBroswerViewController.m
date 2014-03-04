//
//  MusicBroswerViewController.m
//  SonosMusicServicesBrowser
//
//  Created by Drew Ingebretsen on 11/10/13.
//  Copyright (c) 2013 Drew Ingebretsen. All rights reserved.
//

#import "MusicBroswerViewController.h"
#import "SonosMusicServiceItem.h"
#import "SonosMusicService.h"
#import "SonosController.h"
#import "SonosInputStore.h"
#import "SonosMusicServiceItemMedia.h"
#import "SonosMusicServiceItemCollection.h"

@interface MusicBroswerViewController () <UITableViewDataSource, UITableViewDelegate>

@end

@implementation MusicBroswerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.musicItems.count;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    SonosMusicServiceItem *item = [self.musicItems objectAtIndex:indexPath.row];
    cell.textLabel.text = item.title;
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    SonosMusicServiceItem *item = [self.musicItems objectAtIndex:indexPath.row];
    if ([item isKindOfClass:[SonosMusicServiceItemMedia class]]){
        [[SonosController sharedController] play:[[SonosInputStore sharedStore] master] musicServiceItem:item completion:nil];
    }
    else{
        SonosMusicServiceItemCollection *sItem = (SonosMusicServiceItemCollection*)item;
        if (!sItem.canEnumerate){
            [[SonosController sharedController] play:[[SonosInputStore sharedStore] master] musicServiceItem:item completion:nil];
        }
        else{
            [self.service enumerateItem:sItem startingIndex:0 endingCount:100 completion:^(NSArray *contents, NSInteger totalItems, NSError *error){
                MusicBroswerViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"browser"];
                vc.musicItems = contents;
                vc.service = self.service;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.navigationController pushViewController:vc animated:YES];
                });
            }];
        }
        
    }
}

@end
