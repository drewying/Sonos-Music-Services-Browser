//
//  SonosMusicService.h
//  SonosMusicServicesBrowser
//
//  Created by Drew Ingebretsen on 11/10/13.
//  Copyright (c) 2013 Drew Ingebretsen. All rights reserved.
//

typedef enum {kAuthenticationTypeUser, kAuthenticationTypeAnonymous, kAuthenticationTypeDeviceLink} AuthenticationType;
typedef enum {kContainerTypeSoundLab, kContainerTypeMusicService} ServiceContainerType;

#import <Foundation/Foundation.h>
@class SonosMusicServiceItem;

@interface SonosMusicService : NSObject <NSCoding>
@property (nonatomic, strong) NSString *serviceId;
@property (nonatomic, strong) NSString *serviceName;
@property (nonatomic, strong) NSString *serviceUri;
@property (nonatomic, strong) NSString *serviceType;
@property (nonatomic, assign) AuthenticationType serviceAuthType;
@property (nonatomic, readonly) NSString *username;
@property (nonatomic, strong) NSString *serviceCapabilities;
@property (nonatomic, assign) ServiceContainerType serviceContainerType;

//Authentication
- (BOOL)isAuthenticated;
- (void)authenticateWithUsername:(NSString *)username Password:(NSString*)password completion:(void (^)(BOOL success, NSError *error))block;
- (void)getDeviceLinkCode:(void (^)(NSString *linkCode, NSString *authURL, NSError *error))block;
- (void)authenticateWithDeviceLinkCode:(NSString *)linkCode completion:(void (^)(BOOL success, NSError *error))block;

- (void)enumerateRootDirectory:(void (^)(NSArray *contents, NSInteger totalItems, NSError *error))block;
- (void)enumerateSearchOptions:(void (^)(NSArray *contents, NSError *error))block;
- (void)enumerateItem:(SonosMusicServiceItem*)musicServiceItem startingIndex:(NSInteger)index endingCount:(NSInteger)count completion:(void (^)(NSArray *contents, NSInteger totalItem, NSError *error))block;
- (void)searchItem:(SonosMusicServiceItem*)musicServiceItem searchTerm:(NSString*)searchTerm completion:(void (^)(NSArray *contents,NSError *error))block;
- (void)request:(NSString*)action params:(NSDictionary *)params completion:(void (^)(id, NSError *error))block;

@end
