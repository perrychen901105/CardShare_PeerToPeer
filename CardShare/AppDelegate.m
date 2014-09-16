//
//  AppDelegate.m
//  GreatExchange
//
//  Created by Christine Abernathy on 6/27/13.
//  Copyright (c) 2013 Elidora LLC. All rights reserved.
//

#import "AppDelegate.h"

NSString *const kServiceType = @"rw-cardshare";
NSString *const DataReceivedNotification = @"com.razeware.apps.CardShare:DataReceivedNotification";
BOOL const kProgrammaticDiscovery = YES;

typedef void(^InvitationHandler) (BOOL accept, MCSession *session);

@interface AppDelegate () <MCSessionDelegate, MCNearbyServiceAdvertiserDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) MCAdvertiserAssistant *advertiserAssistant;

@property (strong, nonatomic) MCNearbyServiceAdvertiser *advertiser;
@property (copy, nonatomic) InvitationHandler handler;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    // Set appearance info
    [[UITabBar appearance] setBarTintColor:[self mainColor]];
    
    [[UINavigationBar appearance] setBarStyle:UIBarStyleBlackOpaque];
    [[UINavigationBar appearance] setBarTintColor:[self mainColor]];
    
    [[UIToolbar appearance] setBarStyle:UIBarStyleBlackOpaque];
    [[UIToolbar appearance] setBarTintColor:[self mainColor]];
    
    // Initialize properties
    self.cards = [@[] mutableCopy];
    
    // Initialize any stored data
    self.myCard = nil;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"myCard"]) {
        NSData *myCardData = [defaults objectForKey:@"myCard"];
        self.myCard = (Card *)[NSKeyedUnarchiver unarchiveObjectWithData:myCardData];
    }
    self.otherCards = [@[] mutableCopy];
    if ([defaults objectForKey:@"otherCards"]) {
        NSData *otherCardsData = [defaults objectForKey:@"otherCards"];
        self.otherCards = (NSMutableArray *)[NSKeyedUnarchiver unarchiveObjectWithData:otherCardsData];
    }
    
    // 1
    /**
     *  First, initialize an MCPeerID object with a peer display name, which is either the first name on the user's business card if available, or alternatively the device name itself. It's best to keep the display name as short as possible.
     */
    NSString *peerName = self.myCard.firstName ? self.myCard.firstName : [[UIDevice currentDevice] name];
    self.peerId = [[MCPeerID alloc] initWithDisplayName:peerName];
    
    // 2
    /**
     *  init the session
     */
    self.session = [[MCSession alloc] initWithPeer:self.peerId
                                  securityIdentity:nil encryptionPreference:MCEncryptionNone];
    self.session.delegate = self;
    
    
    if (kProgrammaticDiscovery) {
        // 1
        /**
         *  initializes the advertiser with a peer, a nil for the discoveryInfo parameter and the serviceType identifier for the service being provided.Remember only browsers searching for a service with the same identifer will see this advisier.
         */
        self.advertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:self.peerId discoveryInfo:nil serviceType:kServiceType];
        // 2
        /**
         *  sets the advertiser's delegate to the app delegate.
         */
        self.advertiser.delegate = self;
        // 3
        /**
         *  calls startAdvertisingPeer to commence the process of adverising this service.
         */
        [self.advertiser startAdvertisingPeer];
    } else {
        // 3
        /**
         *  initialize the MCAdvertiserAssistant object
         */
        self.advertiserAssistant = [[MCAdvertiserAssistant alloc] initWithServiceType:kServiceType
                                                                        discoveryInfo:nil session:self.session];
        
        // 4
        [self.advertiserAssistant start];
    }
    return YES;
}

- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
    Card *card = (Card *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
    [self.cards addObject:card];
    [[NSNotificationCenter defaultCenter] postNotificationName:DataReceivedNotification object:nil];
}

- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID
{
    
}

- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error
{
    
}

- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress
{
    
}

- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    
}

#pragma mark - Programmer
- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void (^)(BOOL, MCSession *))invitationHandler
{
    self.handler = invitationHandler;
    [[[UIAlertView alloc] initWithTitle:@"Invitation"
                                message:[NSString stringWithFormat:@"%@ wants to connect", peerID.displayName] delegate:self cancelButtonTitle:@"Nope" otherButtonTitles:@"Sure", nil] show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    BOOL accept = (buttonIndex == alertView.cancelButtonIndex) ? NO : YES;
    self.handler(accept, self.session);
}


#pragma mark - Helper methods
- (void)sendCardToPeer
{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.myCard];
    NSError *error;
    [self.session sendData:data toPeers:[self.session connectedPeers] withMode:MCSessionSendDataReliable error:&error];
}

- (UIColor *)mainColor
{
    return [UIColor colorWithRed:28/255.0f green:171/255.0f blue:116/255.0f alpha:1.0f];
}

/*
 * Implement the setter for the user's card
 * so as to set the value in storage as well.
 */
- (void)setMyCard:(Card *)aCard
{
    if (aCard != _myCard) {
        _myCard = aCard;
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        // Create an NSData representation
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:aCard];
        [defaults setObject:data forKey:@"myCard"];
        [defaults synchronize];
    }
}

- (void)addToOtherCardsList:(Card *)card
{
    [self.otherCards addObject:card];
    // Update stored value
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.otherCards];
    [defaults setObject:data forKey:@"otherCards"];
    [defaults synchronize];
}

- (void) removeCardFromExchangeList:(Card *)card
{
    NSMutableSet *cardsSet = [NSMutableSet setWithArray:self.cards];
    [cardsSet removeObject:card];
    self.cards = [[cardsSet allObjects] mutableCopy];
}

@end