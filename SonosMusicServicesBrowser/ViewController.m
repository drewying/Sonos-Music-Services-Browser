//
//  ViewController.m
//  SonosMusicServicesBrowser
//
//  Created by Drew Ingebretsen on 11/10/13.
//  Copyright (c) 2013 Drew Ingebretsen. All rights reserved.
//

#import "ViewController.h"
#import "SonosInputStore.h"
#import "SonosInput.h"
#import "SonosController.h"
#import "SonosMusicService.h"
#import "XMLReader.h"
#import "MusicBroswerViewController.h"
#import "SonosMusicServiceManager.h"

@interface ViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, readonly) SonosController *controller;
@property (nonatomic, strong) NSArray *selectedServices;
@property (nonatomic, strong) SonosMusicService *selectedServic;
@property (nonatomic, weak) IBOutlet UITableView *tablView;
@property (nonatomic, readonly) SonosMusicServiceManager *musicManager;
@end

@implementation ViewController

-(SonosMusicServiceManager*)musicManager{
    return [SonosMusicServiceManager sharedManager];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.musicManager restore];
    [self.tablView reloadData];
    [SonosController discover:^(NSArray *inputs, NSError *error){
        SonosInputStore *first = [inputs objectAtIndex:0];
        [[SonosInputStore sharedStore] setMaster:first.master];
        [[SonosInputStore sharedStore] setInputs:first.allInputs];
        NSLog(@"FoundSonos");
    }];
}

-(void)viewDidAppear:(BOOL)animated{
    [self.tablView reloadData];
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
    return self.musicManager.managedServices.count;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    cell.textLabel.text = [[self.musicManager.managedServices objectAtIndex:indexPath.row] serviceName];
    return cell;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"brosweMusic"]){
        MusicBroswerViewController *vc = segue.destinationViewController;
        vc.musicItems = self.selectedServices;
        vc.service = self.selectedServic;
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    SonosMusicService *service = [self.musicManager.managedServices objectAtIndex:indexPath.row];
    
    [service enumerateRootDirectory:^(NSArray *contents, NSInteger totalItems, NSError *error){
        self.selectedServices = contents;
        self.selectedServic = service;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self performSegueWithIdentifier:@"brosweMusic" sender:nil];
        });
    }];
}

@end
