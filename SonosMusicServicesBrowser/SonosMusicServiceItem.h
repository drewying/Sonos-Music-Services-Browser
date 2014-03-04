//
//  SonosMusicServiceBrowseItem.h
//  SonosMusicServicesBrowser
//
//  Created by Drew Ingebretsen on 11/10/13.
//  Copyright (c) 2013 Drew Ingebretsen. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface SonosMusicServiceItem : NSObject
@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *itemType;
@property (nonatomic, strong) NSString *trackMeta;
@property (nonatomic, strong) NSString *playUri;
@end
