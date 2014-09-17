//
//  AppDelegate.h
//  GreatExchange
//
//  Created by Christine Abernathy on 6/27/13.
//  Copyright (c) 2013 Elidora LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import "Card.h"

extern NSString *const DataReceivedNotification;
extern NSString *const kServiceType;

extern NSString *const PeerConnectionAcceptedNotification;

extern BOOL const kProgrammaticDiscovery;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) NSMutableArray *cards;
@property (strong, nonatomic) Card *myCard;
@property (strong, nonatomic) NSMutableArray *otherCards;

@property (strong, nonatomic) MCSession *session;
@property (strong, nonatomic) MCPeerID *peerId;

- (void) addToOtherCardsList:(Card *)card;
- (void) removeCardFromExchangeList:(Card *)card;
- (UIColor *) mainColor;

- (void)sendCardToPeer;

@end
