//
//  SonosMusicServiceManager.h
//  SonosMusicServicesBrowser
//
//  Created by Drew Ingebretsen on 11/16/13.
//  Copyright (c) 2013 Drew Ingebretsen. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SonosMusicService;

@interface SonosMusicServiceManager : NSObject

@property (nonatomic, readonly) NSArray *managedServices;

+(SonosMusicServiceManager *)sharedManager;
+(NSArray*)getServiceListFromSonosResponse:(NSDictionary*)dictionary;

-(void)addService:(SonosMusicService*)service;
-(void)removeService:(SonosMusicService*)service;
-(BOOL)save;
-(void)restore;

@end
