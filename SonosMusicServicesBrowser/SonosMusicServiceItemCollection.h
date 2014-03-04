//
//  SonosMusicServiceItemCollection.h
//  SonosMusicServicesBrowser
//
//  Created by Drew Ingebretsen on 11/17/13.
//  Copyright (c) 2013 Drew Ingebretsen. All rights reserved.
//

#import "SonosMusicServiceItem.h"

@interface SonosMusicServiceItemCollection : SonosMusicServiceItem

@property (nonatomic, strong) NSString *artistId;
@property (nonatomic, strong) NSString *artist;
@property (nonatomic, strong) NSString *albumArtURI;
@property (nonatomic, assign) BOOL canPlay;
@property (nonatomic, assign) BOOL canEnumerate;
@property (nonatomic, assign) BOOL canAddToFavorites;
@property (nonatomic, assign) BOOL canScroll;
@property (nonatomic, assign) BOOL canSkip;

@end
