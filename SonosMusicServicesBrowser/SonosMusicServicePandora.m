//
//  SonosMusicServicePandora.m
//  SonosMusicServicesBrowser
//
//  Created by Drew Ingebretsen on 11/22/13.
//  Copyright (c) 2013 Drew Ingebretsen. All rights reserved.
//

#import "SonosMusicServicePandora.h"
#import "SonosMusicServiceItemMedia.h"
#import <CommonCrypto/CommonCrypto.h>
#import "blowfish.h"

#define PANDORA_PARTNER_USERNAME @"iphone"
#define PANDORA_PARTNER_PASSWORD @"P2E4FC0EAD3*878N92B2CDp34I0B1@388137C"
#define PANDORA_PARTNER_DEVICEID @"IP01"
#define PANDORA_PARTNER_DECRYPT "20zE1E47BE57$51"
#define PANDORA_PARTNER_ENCRYPT "721^26xE22776"


@interface SonosMusicServicePandora()
@property (nonatomic, strong) NSString *partnerID;
@property (nonatomic, strong) NSString *authToken;
@property (nonatomic, strong) NSString *userID;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, assign) NSInteger syncTime;
@property (nonatomic, assign) NSInteger startTime;
@property (nonatomic, strong) NSString *secureServiceUri;
@property (nonatomic, strong) NSString *password;
@end

@implementation SonosMusicServicePandora

-(BOOL)isAuthenticated{
    return ((self.serviceAuthType == kAuthenticationTypeAnonymous) || self.authToken.length>0);
}

-(id)init{
    self = [super init];
    if (self){
        self.secureServiceUri = @"https://tuner.pandora.com/services/json/";
        self.serviceUri = @"http://tuner.pandora.com/services/json/";
        self.serviceAuthType = kAuthenticationTypeUser;
        self.serviceName = @"Pandora Radio";
        self.serviceContainerType = kContainerTypeMusicService;
    }
    return self;
}

- (void)authenticateWithUsername:(NSString *)username Password:(NSString*)password completion:(void (^)(BOOL success, NSError *error))block{
    if (!self.authToken){
        [self request:@"auth.partnerLogin" params:@{@"username":PANDORA_PARTNER_USERNAME, @"password":PANDORA_PARTNER_PASSWORD, @"deviceModel": PANDORA_PARTNER_DEVICEID, @"version":@"5"} completion:^(NSDictionary *result, NSError *error){
            self.startTime = [self time];
            
            self.authToken = result[@"result"][@"partnerAuthToken"];
            //self.authToken = [self urlEscapeString:self.authToken];
            self.partnerID = result[@"result"][@"partnerId"];
            
            
            NSString *syncTime = (NSString*)result[@"result"][@"syncTime"];
            NSData *sync = [self PandoraDecrypt:(NSString*)syncTime];
            
            const char *bytes = [sync bytes];
            self.syncTime = strtoul(bytes + 4, NULL, 10);
            
            if (self.authToken){
                [self authenticateWithUsername:username Password:password completion:block];
            }
            else{
                block(NO, nil);
            }
        }];
    }
    else{
        [self request:@"auth.userLogin" params:@{@"loginType":@"user", @"username":username, @"password":password, @"partnerAuthToken":self.authToken, @"syncTime":[self syncTimeNum]} encrypt:YES secure:YES completion:^(NSDictionary *response, NSError *error){
            response = response[@"result"];
            self.userID = response[@"userId"];
            self.authToken = response[@"userAuthToken"];
            self.username = username;
            self.password = password;
            //self.authToken = [self urlEscapeString:self.authToken];
            if (self.authToken){
                block(YES,nil);
            }
            else{
                block(NO,nil);
            }
        }];
    }
}

-(NSString*)urlEscapeString:(NSString*)string{
    return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,(CFStringRef)string,NULL,(CFStringRef)@"!*'();:@&=+$,/?%#[]",kCFStringEncodingUTF8 ));
}

- (void)enumerateSearchOptions:(void (^)(NSArray *contents, NSError *error))block{
    if (block){
        block(@[],nil);
    }
}



- (void)enumerateRootDirectory:(void (^)(NSArray *contents, NSInteger totalItems, NSError *error))block{
    [self request:@"user.getStationList" params:@{@"userAuthToken":self.authToken, @"syncTime":[self syncTimeNum]} encrypt:YES secure:NO completion:^(NSDictionary *response, NSError *error){
        if ([response[@"code"] isEqualToNumber:@1001]){
            self.authToken = nil;
            //Auth token invalue, need to reset
            [self authenticateWithUsername:self.username Password:self.password completion:^(BOOL success, NSError *error){
                if (success){
                    [self enumerateRootDirectory:block];
                }
            }];
            return;
        }
        NSArray *stations = response[@"result"][@"stations"];
        NSMutableArray *items = [NSMutableArray new];
        for (NSDictionary *stationDictionary in stations){
            [items addObject:[self sonosMusicServiceItemFromDictionary:stationDictionary]];
        }
        if (block)
            block(items, items.count, error);
    }];
}

- (void)enumerateItem:(SonosMusicServiceItem*)musicServiceItem startingIndex:(NSInteger)index endingCount:(NSInteger)count completion:(void (^)(NSArray *contents, NSInteger totalItem, NSError *error))block{
    
}

- (void)request:(NSString*)action params:(NSDictionary *)params completion:(void (^)(id, NSError *))block
{
    [self request:action params:params encrypt:NO secure:YES completion:block];
}

- (void)request:(NSString*)action params:(NSDictionary *)params encrypt:(BOOL)encrypted secure:(BOOL)secured completion:(void (^)(id, NSError *))block
{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSData *jsonRequestData = [NSJSONSerialization dataWithJSONObject:params options:nil error:nil];
    if (encrypted){
        jsonRequestData = [self PandoraEncrypt:jsonRequestData];
    }
    [request setHTTPBody:jsonRequestData];
    NSString *urlString;
    if (secured){
        urlString = self.secureServiceUri;
    }
    else{
        urlString = self.serviceUri;
    }
    
    urlString = [urlString stringByAppendingString:[NSString stringWithFormat:@"?method=%@&auth_token=%@&partner_id=%@",action, [self urlEscapeString:self.authToken], self.partnerID]];
   if (self.userID){
       urlString = [urlString stringByAppendingString:[NSString stringWithFormat:@"&user_id=%@",self.userID]];
   }
    
    NSURL *url = [NSURL URLWithString:urlString];
    [request setURL:url];
    [NSURLConnection sendAsynchronousRequest:request queue:[[NSOperationQueue alloc] init] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
        NSLog(@"%@",[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        if (block){
            block([NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error], error);
        }
    }];
}

/*
 @property (nonatomic, strong) NSString *partnerID;
 @property (nonatomic, strong) NSString *authToken;
 @property (nonatomic, strong) NSString *userID;
 @property (nonatomic, strong) NSString *username;
 @property (nonatomic, assign) NSInteger syncTime;
 @property (nonatomic, assign) NSInteger startTime;
 @property (nonatomic, strong) NSString *secureServiceUri;
*/

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self){
        self.partnerID = [aDecoder decodeObjectForKey:@"partnerID"];
        self.authToken = [aDecoder decodeObjectForKey:@"authToken"];
        self.userID = [aDecoder decodeObjectForKey:@"userID"];
        self.syncTime = [aDecoder decodeIntegerForKey:@"syncTime"];
        self.startTime = [aDecoder decodeIntegerForKey:@"startTime"];
        self.secureServiceUri = [aDecoder decodeObjectForKey:@"secureServiceUri"];
        self.password = [aDecoder decodeObjectForKey:@"password"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.partnerID forKey:@"partnerID"];
    [aCoder encodeObject:self.authToken forKey:@"authToken"];
    [aCoder encodeObject:self.userID forKey:@"userID"];
    [aCoder encodeInteger:self.syncTime forKey:@"syncTime"];
    [aCoder encodeInteger:self.startTime forKey:@"startTime"];
    [aCoder encodeObject:self.secureServiceUri forKey:@"secureServiceUri"];
    [aCoder encodeObject:self.password forKey:@"password"];
}

static char i2h[16] = "0123456789abcdef";
static char h2i[256] = {
    ['0'] = 0, ['1'] = 1, ['2'] = 2, ['3'] = 3, ['4'] = 4, ['5'] = 5, ['6'] = 6,
    ['7'] = 7, ['8'] = 8, ['9'] = 9, ['a'] = 10, ['b'] = 11, ['c'] = 12,
    ['d'] = 13, ['e'] = 14, ['f'] = 15
};

static void appendByte(unsigned char byte, void *_data) {
    NSMutableData *data = (__bridge NSMutableData*) _data;
    [data appendBytes:&byte length:1];
}

static void appendHex(unsigned char byte, void *_data) {
    NSMutableData *data = (__bridge NSMutableData*) _data;
    char bytes[2];
    bytes[1] = i2h[byte % 16];
    bytes[0] = i2h[byte / 16];
    [data appendBytes:bytes length:2];
}

-(NSData*)PandoraDecrypt:(NSString*)string {
    struct blf_ecb_ctx ctx;
    NSMutableData *mut = [[NSMutableData alloc] init];
    
    Blowfish_ecb_start(&ctx, FALSE, (unsigned char*) PANDORA_PARTNER_DECRYPT,
                       sizeof(PANDORA_PARTNER_DECRYPT) - 1, appendByte,
                       (__bridge void*) mut);
    
    const char *bytes = [string cStringUsingEncoding:NSASCIIStringEncoding];
    int len = [string lengthOfBytesUsingEncoding:NSASCIIStringEncoding];
    int i;
    for (i = 0; i < len; i += 2) {
        Blowfish_ecb_feed(&ctx, h2i[(int) bytes[i]] * 16 + h2i[(int) bytes[i + 1]]);
    }
    Blowfish_ecb_stop(&ctx);
    
    return mut;
}

-(NSData*)PandoraEncrypt:(NSData*)data {
    struct blf_ecb_ctx ctx;
    NSMutableData *mut = [[NSMutableData alloc] init];
    
    Blowfish_ecb_start(&ctx, TRUE, (unsigned char*) PANDORA_PARTNER_ENCRYPT,
                       sizeof(PANDORA_PARTNER_ENCRYPT) - 1, appendHex,
                       (__bridge void*) mut);
    
    const char *bytes = [data bytes];
    int len = [data length];
    int i;
    for (i = 0; i < len; i++) {
        Blowfish_ecb_feed(&ctx, bytes[i]);
    }
    Blowfish_ecb_stop(&ctx);
    
    return mut;
}

- (NSNumber*)syncTimeNum {
    return [NSNumber numberWithLongLong: self.syncTime + ([self time] - self.startTime)];
}

-(NSInteger)time{
    return [NSDate timeIntervalSinceReferenceDate];
}

-(SonosMusicServiceItemMedia*)sonosMusicServiceItemFromDictionary:(NSDictionary*)dictionary{
    //PandoraStream URI: pndrradio:1731263328098120224
    
    /*
     {
     allowAddMusic = 0;
     allowDelete = 1;
     allowRename = 1;
     dateCreated =                 {
     date = 3;
     day = 2;
     hours = 9;
     minutes = 56;
     month = 11;
     nanos = 245000000;
     seconds = 52;
     time = 1386093412245;
     timezoneOffset = 480;
     year = 113;
     };
     genre =                 (
     Jazz,
     Holiday
     );
     isQuickMix = 0;
     isShared = 0;
     requiresCleanAds = 1;
     stationDetailUrl = "https://www.pandora.com/login?target=%2Fstations%2F7895ba60f823913349213a14d138425ad0e9c61ee1b900a5";
     stationId = 1731263328098120224;
     stationName = "Christmas Radio";
     stationSharingUrl = "https://www.pandora.com/login?target=%2Fshare%2Fstation%2F7895ba60f823913349213a14d138425ad0e9c61ee1b900a5";
     stationToken = 1731263328098120224;
     suppressVideoAds = 1;*/
    
    //Meta: <DIDL-Lite xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:upnp="urn:schemas-upnp-org:metadata-1-0/upnp/" xmlns:r="urn:schemas-rinconnetworks-com:metadata-1-0/" xmlns="urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/"><item id="OXOX1731263328098120224" parentID="0" restricted="true"><dc:title>Christmas Radio</dc:title><upnp:class>object.item.audioItem.audioBroadcast</upnp:class><desc id="cdudn" nameSpace="urn:schemas-rinconnetworks-com:metadata-1-0/">SA_RINCON3_drewying@gmail.com</desc></item></DIDL-Lite>
    
    SonosMusicServiceItemMedia *item = [SonosMusicServiceItemMedia new];
    item.identifier = dictionary[@"stationToken"];
    item.title = dictionary[@"stationName"];
    item.playUri = [NSString stringWithFormat:@"pndrradio:%@",item.identifier];
    item.itemType = @"stream";
    NSString *encodedString = [NSString stringWithFormat:@"OXOX%@",item.identifier];
    NSString *service = [NSString stringWithFormat:@"3_%@", self.username];
    item.trackMeta = [NSString stringWithFormat:@"&lt;DIDL-Lite xmlns:dc=&quot;http://purl.org/dc/elements/1.1/&quot; xmlns:upnp=&quot;urn:schemas-upnp-org:metadata-1-0/upnp/&quot; xmlns:r=&quot;urn:schemas-rinconnetworks-com:metadata-1-0/&quot; xmlns=&quot;urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/&quot;&gt;&lt;item id=&quot;%@&quot; parentID=&quot;%@&quot; restricted=&quot;true&quot;&gt;&lt;dc:title&gt;%@&lt;/dc:title&gt;&lt;desc&gt;SA_RINCON%@&lt;/desc&gt;&lt;/item&gt;&lt;/DIDL-Lite&gt;", encodedString, @"0", item.title, service];
    return item;
}


@end
