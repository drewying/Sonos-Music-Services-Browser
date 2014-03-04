//
//  SonosMusicServiceItemMedia.h
//  SonosMusicServicesBrowser
//
//  Created by Drew Ingebretsen on 11/17/13.
//  Copyright (c) 2013 Drew Ingebretsen. All rights reserved.
//

#import "SonosMusicServiceItem.h"

@interface SonosMusicServiceItemMedia : SonosMusicServiceItem

@property (nonatomic, strong) NSString *mimeType;
@property (nonatomic, strong) NSDictionary *streamMetadata;

@end
