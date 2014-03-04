//
//  MusicServicesViewController.m
//  SonosMusicServicesBrowser
//
//  Created by Drew Ingebretsen on 11/17/13.
//  Copyright (c) 2013 Drew Ingebretsen. All rights reserved.
//

#import "MusicServicesViewController.h"
#import "SonosController.h"
#import "SonosInputStore.h"
#import "SonosMusicServiceManager.h"
#import "SonosMusicService.h"
#import "MusicServicesLoginViewController.h"
#import "MusicServicesOauthLoginViewController.h"

@interface MusicServicesViewController () <UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSArray *musicServices;
@property (nonatomic, readonly) SonosController *controller;

@property (nonatomic, strong) NSString *oauthUrl;
@property (nonatomic, strong) NSString *oauthLinkCode;

@end

@implementation MusicServicesViewController



-(SonosController*)controller{
    return [SonosController sharedController];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    SonosInput*master = [[SonosInputStore sharedStore] master];
    
    [self.controller musicServices:master completion:^(NSDictionary *response, NSError *error){
        self.musicServices = [SonosMusicServiceManager getServiceListFromSonosResponse:response];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    }];
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
    return self.musicServices.count;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    SonosMusicService *service = [self.musicServices objectAtIndex:indexPath.row];
    cell.textLabel.text = service.serviceName;
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    SonosMusicService *service = [self.musicServices objectAtIndex:indexPath.row];
    if (service.serviceAuthType == kAuthenticationTypeUser){
        [self performSegueWithIdentifier:@"Login" sender:[tableView cellForRowAtIndexPath:indexPath]];
    }
    else if (service.serviceAuthType == kAuthenticationTypeDeviceLink){
        [service getDeviceLinkCode:^(NSString *linkCode, NSString *authUrl, NSError *error){
            self.oauthLinkCode = linkCode;
            self.oauthUrl = authUrl;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self performSegueWithIdentifier:@"OAuth" sender:[tableView cellForRowAtIndexPath:indexPath]];
            });
        }];
    }
    else if (service.serviceAuthType == kAuthenticationTypeAnonymous){
        [[SonosMusicServiceManager sharedManager] addService:service];
        [[SonosMusicServiceManager sharedManager] save];
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"Login"]){
        NSIndexPath *path = [self.tableView indexPathForCell:sender];
        MusicServicesLoginViewController *vc = segue.destinationViewController;
        vc.musicService = [self.musicServices objectAtIndex:path.row];
    }
    else if ([segue.identifier isEqualToString:@"OAuth"]){
        NSIndexPath *path = [self.tableView indexPathForCell:sender];
        MusicServicesOauthLoginViewController *vc = segue.destinationViewController;
        vc.musicService = [self.musicServices objectAtIndex:path.row];
        vc.deviceLinkUrl = self.oauthUrl;
        vc.deviceLinkCode = self.oauthLinkCode;
    }
}

@end
