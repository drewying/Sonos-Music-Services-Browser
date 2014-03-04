//
//  SonosMusicServiceManager.m
//  SonosMusicServicesBrowser
//
//  Created by Drew Ingebretsen on 11/16/13.
//  Copyright (c) 2013 Drew Ingebretsen. All rights reserved.
//

#import "SonosMusicServiceManager.h"
#import "SonosMusicService.h"
#import "XMLReader.h"
#import "SonosMusicServicePandora.h"

@interface SonosMusicServiceManager ()
@property (nonatomic, strong) NSArray *managedServices;
@end

@implementation SonosMusicServiceManager

+ (SonosMusicServiceManager *)sharedManager
{
    static SonosMusicServiceManager *manager;
    if (!manager) {
        manager = [[SonosMusicServiceManager alloc] init];
    }
    return manager;
}

-(NSArray*)managedServices{
    if (!_managedServices){
        _managedServices = [[NSArray alloc] init];
    }
    return _managedServices;
}

+(NSArray*)getServiceListFromSonosResponse:(NSDictionary*)responseDictionary{
    
    NSString *serviceTypeList = responseDictionary[@"u:ListAvailableServicesResponse"][@"AvailableServiceTypeList"][@"text"];
    NSArray *serviceTypes = [serviceTypeList componentsSeparatedByString:@","];
    NSDictionary *services = [XMLReader dictionaryForXMLString:responseDictionary[@"u:ListAvailableServicesResponse"][@"AvailableServiceDescriptorList"][@"text"] error:nil];
    NSArray *responseServices = services[@"Services"][@"Service"];
    
    NSMutableArray *musicServices = [NSMutableArray array];
    //NSInteger counter = -1;
    for (NSDictionary *dictionary in responseServices){
        SonosMusicService *service = [[SonosMusicService alloc] init];
        service.serviceUri = dictionary[@"SecureUri"];
        service.serviceId = dictionary[@"Id"];
        service.serviceName = dictionary[@"Name"];
        service.serviceCapabilities = dictionary[@"Capabilities"];
        
        if ([dictionary[@"Policy"][@"Auth"] isEqualToString:@"Userid"]){
            service.serviceAuthType = kAuthenticationTypeUser;
        }
        if ([dictionary[@"Policy"][@"Auth"] isEqualToString:@"Anonymous"]){
            service.serviceAuthType = kAuthenticationTypeAnonymous;
        }
        if ([dictionary[@"Policy"][@"Auth"] isEqualToString:@"DeviceLink"]){
            service.serviceAuthType = kAuthenticationTypeDeviceLink;
        }
        
        if ([dictionary[@"ContainerType"] isEqualToString:@"SoundLab"]){
            service.serviceContainerType = kContainerTypeSoundLab;
        }
        
        if ([dictionary[@"ContainerType"] isEqualToString:@"MService"]){
            service.serviceContainerType = kContainerTypeMusicService;
        }
        /*if (counter<0){
            service.serviceType = [serviceTypes objectAtIndex:0];
        }
        else{
            service.serviceType = [serviceTypes objectAtIndex:counter];
        }*/
        
        //counter++;
        //Rdio 2823
        //Amazon 6663
        
        [musicServices addObject:service];
    }
    
    [musicServices sortUsingComparator:^NSComparisonResult(SonosMusicService *obj1, SonosMusicService *obj2){
        NSNumber *first = [NSNumber numberWithInteger:[obj1.serviceId integerValue]];
        NSNumber *second = [NSNumber numberWithInteger:[obj2.serviceId integerValue]];
        return [first compare:second];
    }];
    
    serviceTypes = [serviceTypes sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2){
        NSNumber *first = [NSNumber numberWithInteger:[obj1 integerValue]];
        NSNumber *second = [NSNumber numberWithInteger:[obj2 integerValue]];
        return [first compare:second];
    }];
    
    for (NSInteger i=0; i<musicServices.count-1; i++){
        SonosMusicService *service = [musicServices objectAtIndex:i];
        service.serviceType = [serviceTypes objectAtIndex:i+3];
    }
    
    //This block of code prints out the list oredered by capability.
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    NSArray *array = [musicServices valueForKey:@"serviceCapabilities"];
    NSSet *set = [NSSet setWithArray:array];
    array = [set allObjects];
    for (NSString *string in array){
        [dictionary setObject: [musicServices filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"serviceCapabilities=%@",string]] forKey:string];
    }
    //NSLog(@"%@",dictionary);
    
    //These process the custom Music Service, such as Pandora and TuneIn Radio
    SonosMusicService *radio = [musicServices lastObject];
    radio.serviceName = @"Radio";
    radio.serviceType = @"65031";
    
    SonosMusicServicePandora *pandora = [[SonosMusicServicePandora alloc] init];
    [musicServices addObject:pandora];
    
    //Sort the list alphabetically
    [musicServices sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"serviceName" ascending:YES]]];
    
    return [musicServices copy];
}

-(void)addService:(SonosMusicService*)service;
{
    if ([service isAuthenticated]){
        self.managedServices = [self.managedServices arrayByAddingObject:service];
    }
}

-(void)removeService:(SonosMusicService*)service
{
    NSMutableArray *services = [self.managedServices mutableCopy];
    [services removeObject:service];
    self.managedServices = [services copy];
}

-(BOOL)save{
    NSString *path = [self inputArchivePath];
    return [NSKeyedArchiver archiveRootObject:_managedServices toFile:path];
}

-(void)restore{
    NSString *path = [self inputArchivePath];
    _managedServices = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
}

- (NSString *)inputArchivePath
{
    NSArray *documentDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = [documentDirectories objectAtIndex:0];
    return [documentDirectory stringByAppendingPathComponent:@"services.archive"];
}



@end
