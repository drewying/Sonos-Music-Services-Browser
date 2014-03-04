//
//  SonosMusicService.m
//  SonosMusicServicesBrowser
//
//  Created by Drew Ingebretsen on 11/10/13.
//  Copyright (c) 2013 Drew Ingebretsen. All rights reserved.
//

#import "SonosMusicService.h"
#import "XMLReader.h"
#import "SonosMusicServiceItem.h"
#import "SonosMusicServiceItemCollection.h"
#import "SonosMusicServiceItemMedia.h"

@interface SonosMusicService () 
@property (nonatomic, strong) NSString *sessionId;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *oAuthKey;
@property (nonatomic, strong) NSString *householdId;
@end

@implementation SonosMusicService

-(BOOL)isAuthenticated{
    return ((self.serviceAuthType == kAuthenticationTypeAnonymous) || self.sessionId.length>0);
}

- (void)authenticateWithUsername:(NSString *)username Password:(NSString*)password completion:(void (^)(BOOL success, NSError *error))block{
    [self request:@"getSessionId" params:@{@"username":username, @"password":password} completion:^(NSDictionary *response, NSError *error){
        NSString *string = [self getValueForSuffix:@"getSessionIdResult" fromDictionary:response][@"text"];
        if (string.length>0){
            self.sessionId = string;
            self.username = username;
            block(YES, nil);
        }
        else{
            block(NO, error);
        }
    }];
}

- (void)authenticateWithDeviceLinkCode:(NSString *)linkCode completion:(void (^)(BOOL success, NSError *error))block{
    [self request:@"getDeviceAuthToken" params:@{@"householdId":self.householdId, @"linkCode":linkCode} completion:^(NSDictionary *response, NSError *error){
        if (error){
            if (block){
                block(NO, error);
            }
            return;
        }
        
        NSString *token = [self getValueForSuffix:@"authToken" fromDictionary:response][@"text"];
        if (token.length == 0){
            if (block){
                block(NO, error);
            }
            return;
        }
        
        
        self.sessionId = token;
        self.oAuthKey = [self getValueForSuffix:@"privateKey" fromDictionary:response][@"text"];
        
       if (block){
            block(YES, nil);
        }
    }];
}

- (void)getDeviceLinkCode:(void (^)(NSString *linkCode, NSString *authURL, NSError *error))block{
    CFUUIDRef newUniqueId = CFUUIDCreate(kCFAllocatorDefault);
    NSString * uuidString = (__bridge_transfer NSString*)CFUUIDCreateString(kCFAllocatorDefault, newUniqueId);
    CFRelease(newUniqueId);
    uuidString = [uuidString stringByReplacingOccurrencesOfString:@"-" withString:@""];
    
    self.householdId = uuidString;
    [self request:@"getDeviceLinkCode" params:@{@"householdId":self.householdId} completion:^(NSDictionary *response, NSError *error){
        NSString *linkcode = [self getValueForSuffix:@"linkCode" fromDictionary:response][@"text"];
        NSString *url = [self getValueForSuffix:@"regUrl" fromDictionary:response][@"text"];
        if (block){
            block(linkcode, url, error);
        }
    }];
}

- (void)enumerateRootDirectory:(void (^)(NSArray *contents, NSInteger totalItems, NSError *error))block{
    SonosMusicServiceItem *item = [[SonosMusicServiceItem alloc] init];
    item.identifier = @"root";
    [self enumerateItem:item startingIndex:0 endingCount:99 completion:block];
}

- (void)enumerateItem:(SonosMusicServiceItem*)musicServiceItem startingIndex:(NSInteger)index endingCount:(NSInteger)count completion:(void (^)(NSArray *contents, NSInteger totalItems, NSError *error))block{
    if (count>index+99){
        count = index+99;
    }
    [self request:@"getMetadata" params:@{@"index":[NSNumber numberWithInteger:index], @"id":musicServiceItem.identifier, @"count":[NSNumber numberWithInteger:count]} completion:^(NSDictionary *response, NSError *error){
        NSMutableArray *contents = [NSMutableArray array];
        id object = [self getValueForSuffix:@"mediaCollection" fromDictionary:response];
        if (object){
            NSArray *array;
            if ([object isKindOfClass:[NSDictionary class]]){
                array = @[object];
            }
            else{
                array = object;
            }
            
            for (NSDictionary *dictionary in array){
                [contents addObject:[self createCollectionItemFromDictionary:dictionary]];
            }
        }
        object = [self getValueForSuffix:@"mediaMetadata" fromDictionary:response];
        if (object){
            NSArray *array;
            if ([object isKindOfClass:[NSDictionary class]]){
                array = @[object];
            }
            else{
                array = object;
            }
            for (NSDictionary *dictionary in array){
                [contents addObject:[self createMediaItemFromDictionary:dictionary]];
            }
        }
        NSInteger totalCount = [[self getValueForSuffix:@"total" fromDictionary:response][@"text"] integerValue];
        block(contents, totalCount, nil);
        
    }];
}

-(SonosMusicServiceItemCollection*)createCollectionItemFromDictionary:(NSDictionary*)dictionary{
    SonosMusicServiceItemCollection *item = [[SonosMusicServiceItemCollection alloc] init];
    if ([[self getValueForSuffix:@"canEnumerate" fromDictionary:dictionary][@"text"] isEqualToString:@"false"]){
        item.canEnumerate = NO;
    }
    else{
        item.canEnumerate = YES;
    }
    item.canPlay = [[self getValueForSuffix:@"canPlay" fromDictionary:dictionary][@"text"] isEqualToString:@"true"];
    item.title = [self getValueForSuffix:@"title" fromDictionary:dictionary][@"text"];
    item.identifier = [self getValueForSuffix:@"id" fromDictionary:dictionary][@"text"];
    item.itemType = [self getValueForSuffix:@"itemType" fromDictionary:dictionary][@"text"];
    item.albumArtURI = [self getValueForSuffix:@"albumArtURI" fromDictionary:dictionary][@"text"];
    item.trackMeta = @"";
    return item;
}

-(SonosMusicServiceItemMedia*)createMediaItemFromDictionary:(NSDictionary*)dictionary{
    SonosMusicServiceItemMedia *item = [[SonosMusicServiceItemMedia alloc] init];
    item.title = [self getValueForSuffix:@"title" fromDictionary:dictionary][@"text"];
    item.identifier = [self getValueForSuffix:@"id" fromDictionary:dictionary][@"text"];
    item.itemType = [self getValueForSuffix:@"itemType" fromDictionary:dictionary][@"text"];
    
    NSString *service = self.serviceType;
    if (self.serviceAuthType == kAuthenticationTypeDeviceLink){
        service = [NSString stringWithFormat:@"%@_X_#Svc%@-0-Token", service, service];
    }
    else if(self.serviceAuthType == kAuthenticationTypeUser){
        service = [NSString stringWithFormat:@"%@_%@", service, self.username];
    }
    else{
        service = [NSString stringWithFormat:@"%@_", service];
    }
    
    NSString *metaIdentifier = item.identifier;
    if ([self.serviceId isEqualToString:@"4356"]){
        metaIdentifier = [NSString stringWithFormat:@"000c0068%@", item.identifier];
    }
    else if ([self.serviceId isEqualToString:@"2823"]){
        metaIdentifier = metaIdentifier;
    }
    else{
        metaIdentifier = [NSString stringWithFormat:@"00030020%@", metaIdentifier];
    }
    
    NSString *encodedString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,(CFStringRef)metaIdentifier, NULL,(CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8 ));
    
    NSString *trackMetaData = [NSString stringWithFormat:@"&lt;DIDL-Lite xmlns:dc=&quot;http://purl.org/dc/elements/1.1/&quot; xmlns:upnp=&quot;urn:schemas-upnp-org:metadata-1-0/upnp/&quot; xmlns:r=&quot;urn:schemas-rinconnetworks-com:metadata-1-0/&quot; xmlns=&quot;urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/&quot;&gt;&lt;item id=&quot;%@&quot; parentID=&quot;%@&quot; restricted=&quot;true&quot;&gt;&lt;dc:title&gt;%@&lt;/dc:title&gt;&lt;desc&gt;SA_RINCON%@&lt;/desc&gt;&lt;/item&gt;&lt;/DIDL-Lite&gt;", encodedString, @"-1", item.title, service];
    
    item.trackMeta = trackMetaData;
    
    //program: x-sonosapi-radio:...
    //track: x-sonos-http:...mp3
    //stream: x-sonosapi-stream
    
    NSString *uri = item.identifier;
    
    //Escape the url
    uri = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,(CFStringRef)uri,NULL,(CFStringRef)@"!*'();:@&=+$,/?%#[]",kCFStringEncodingUTF8 ));
    
    if ([item.itemType isEqualToString:@"program"]){
        uri = [NSString stringWithFormat:@"x-sonosapi-radio:%@", uri];
    }
    else if ([item.itemType isEqualToString:@"stream"]){
        uri = [NSString stringWithFormat:@"x-sonosapi-stream:%@", uri];
    }
    else{
        uri = [NSString stringWithFormat:@"x-sonos-http:%@.mp3", uri];
    }
    
    //Append the service identifier
    item.playUri = [NSString stringWithFormat:@"%@?sid=%@",uri, self.serviceId];
    
    //Slacker Radio Type: 4359
    //Rdio Service Type: 2823
    //Sticher Service Type: 3335
    //Amazon Service Type: 6663
    //TuneIn Service Type: 65031
    //Spotify Service Type: 3079
    
    return item;

}

- (void)enumerateSearchOptions:(void (^)(NSArray *contents, NSError *error))block{
    SonosMusicServiceItem *item = [[SonosMusicServiceItem alloc] init];
    item.identifier = @"search";
    [self enumerateItem:item startingIndex:0 endingCount:99 completion:^(NSArray *contents, NSInteger totalItems, NSError *error){
        if (block){
            block(contents, error);
        }
    }];
}

- (void)searchItem:(SonosMusicServiceItem*)musicServiceItem searchTerm:(NSString*)searchTerm completion:(void (^)(NSArray *contents,NSError *error))block{
    [self request:@"search" params:@{@"id":musicServiceItem.identifier, @"term":searchTerm, @"index":@0, @"count":@99} completion:^(NSDictionary *response, NSError *error){
        NSMutableArray *contents = [NSMutableArray array];
        id object = [self getValueForSuffix:@"mediaCollection" fromDictionary:response];
        if (object){
            NSArray *array;
            if ([object isKindOfClass:[NSDictionary class]]){
                array = @[object];
            }
            else{
                array = object;
            }
            
            for (NSDictionary *dictionary in array){
                [contents addObject:[self createCollectionItemFromDictionary:dictionary]];
            }
        }
        object = [self getValueForSuffix:@"mediaMetadata" fromDictionary:response];
        if (object){
            NSArray *array;
            if ([object isKindOfClass:[NSDictionary class]]){
                array = @[object];
            }
            else{
                array = object;
            }
            for (NSDictionary *dictionary in array){
                [contents addObject:[self createMediaItemFromDictionary:dictionary]];
            }
        }
        if (block){
            block(contents, nil);
        }
    }];
}

-(id)getValueForSuffix:(NSString*)suffix fromDictionary:(NSDictionary *)dictionary{
    NSArray *keys = [dictionary allKeys];
    id returnObject;
    for (NSString *key in keys){
        id object = [dictionary objectForKey:key];
        if ([key hasSuffix:suffix]){
            return dictionary[key];
        }
        else if ([object isKindOfClass:[NSDictionary class]]){
            NSDictionary *dict = (NSDictionary*)object;
            returnObject = [self getValueForSuffix:suffix fromDictionary:dict];
        }
        else if ([object isKindOfClass:[NSArray class]]){
            NSArray *array = (NSArray*)object;
            for (NSDictionary *dic in array){
               returnObject = [self getValueForSuffix:suffix fromDictionary:dic];
            }
        }
        if (returnObject){
            return returnObject;
        }
    }
    return nil;
}

- (void)request:(NSString*)action params:(NSDictionary *)params completion:(void (^)(id, NSError *))block
{
    NSString *xmlns;
    xmlns = @"http://www.sonos.com/Services/1.1";

    // Enumerate
    NSMutableString *requestParams = [[NSMutableString alloc] init];
    NSEnumerator *enumerator = [params  keyEnumerator];
    NSString *key;
    while (key = [enumerator nextObject]) {
        requestParams = [NSMutableString stringWithFormat:@"<ns:%@>%@</ns:%@>%@", key, [params objectForKey:key], key, requestParams];
    }
    
  
    NSString *headerParams;
    if (self.sessionId.length){
        if (self.serviceAuthType == kAuthenticationTypeUser) {
            headerParams = [NSString stringWithFormat:@"<soapenv:Header><ns:credentials xmlns:ns=\"http://www.sonos.com/Services/1.1\"><ns:sessionId>%@</ns:sessionId></ns:credentials></soapenv:Header>", self.sessionId];
        }
        else if (self.serviceAuthType == kAuthenticationTypeDeviceLink){
            headerParams = [NSString stringWithFormat:@"<soapenv:Header><ns:credentials xmlns:ns=\"http://www.sonos.com/Services/1.1\"><ns:loginToken><ns:token>%@</ns:token><ns:key>%@</ns:key><ns:householdId>%@</ns:householdId></ns:loginToken></ns:credentials></soapenv:Header>", self.sessionId, self.oAuthKey, self.householdId];
        }
    }
    else if (self.serviceAuthType == kAuthenticationTypeDeviceLink){
        headerParams = @""
                        "<soapenv:Header>"
                        "<ns:credentials xmlns:ns=\"http://www.sonos.com/Services/1.1\">"
                        "<ns:deviceId>12345</ns:deviceId>"
                        "<ns:deviceProvider>Sonos</ns:deviceProvider>"
                        "</ns:credentials>"
                        "</soapenv:Header>";
    }
    else{
        headerParams = @"";
    }
    
    
    NSString *requestBody = [NSString stringWithFormat:@""
                             "<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:ns=\"http://www.sonos.com/Services/1.1\">"
                             @"%@"
                             "<soapenv:Body>"
                             "<ns:%@ xmlns:ns=\"%@\">"
                             "%@"
                             "</ns:%@>"
                             "</soapenv:Body>"
                             "</soapenv:Envelope>", headerParams, action, xmlns, requestParams, action];

    //requestBody = @"<soap:Envelope xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\"><soap:Body><getSessionId xmlns=\"http://www.sonos.com/Services/1.1\"><username>drewying@gmail.com</username><password>lanfear1</password></getSessionId></soap:Body></soap:Envelope>";
    
    NSString *requestLength = [NSString stringWithFormat:@"%d", [requestBody length]];
    //NSLog(@"Request:%@", requestBody);
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.serviceUri]];
    [request setHTTPMethod:@"POST"];
    [request addValue:@"text/xml" forHTTPHeaderField:@"Content-Type"];
    [request addValue:[NSString stringWithFormat:@"\"%@#%@\"", xmlns, action] forHTTPHeaderField:@"SOAPAction"];
    [request addValue:requestLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:[requestBody dataUsingEncoding:NSUTF8StringEncoding]];
    [NSURLConnection sendAsynchronousRequest:request queue:[[NSOperationQueue alloc] init] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
        //NSLog(@"Response: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        NSDictionary *responseDictionary = [XMLReader dictionaryForXMLData:data error:&error];
        if (block){
            block(responseDictionary, error);
        }
    }];
}

-(NSString*)description{
    return self.serviceName;
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        [self setSessionId:[aDecoder decodeObjectForKey:@"sessionId"]];
        [self setUsername:[aDecoder decodeObjectForKey:@"username"]];
        [self setServiceName:[aDecoder decodeObjectForKey:@"serviceName"]];
        [self setServiceId:[aDecoder decodeObjectForKey:@"serviceId"]];
        [self setServiceUri:[aDecoder decodeObjectForKey:@"serviceUri"]];
        [self setServiceType:[aDecoder decodeObjectForKey:@"serviceType"]];
        [self setServiceAuthType:[aDecoder decodeIntegerForKey:@"serviceAuthType"]];
        [self setHouseholdId:[aDecoder decodeObjectForKey:@"householdId"]];
        [self setOAuthKey:[aDecoder decodeObjectForKey:@"oAuthKey"]];
        [self setServiceContainerType:[aDecoder decodeIntegerForKey:@"containerType"]];
        [self setServiceCapabilities:[aDecoder decodeObjectForKey:@"serviceCapabilities"]];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.sessionId forKey:@"sessionId"];
    [aCoder encodeObject:self.username forKey:@"username"];
    [aCoder encodeObject:self.serviceName forKey:@"serviceName"];
    [aCoder encodeObject:self.serviceId forKey:@"serviceId"];
    [aCoder encodeObject:self.serviceUri forKey:@"serviceUri"];
    [aCoder encodeObject:self.serviceType forKey:@"serviceType"];
    [aCoder encodeInteger:self.serviceAuthType forKey:@"serviceAuthType"];
    [aCoder encodeObject:self.householdId forKey:@"householdId"];
    [aCoder encodeObject:self.oAuthKey forKey:@"oAuthKey"];
    [aCoder encodeObject:self.serviceCapabilities forKey:@"serviceCapabilities"];
    [aCoder encodeInteger:self.serviceAuthType forKey:@"containerType"];
}

@end
