//
//  MyBrowserViewController.m
//  GreatExchange
//
//  Created by Christine Abernathy on 7/1/13.
//  Copyright (c) 2013 Elidora LLC. All rights reserved.
//

#import "MyBrowserViewController.h"
#import "AppDelegate.h"
#import "MyBrowserTableViewCell.h"

@interface MyBrowserViewController ()
<UIToolbarDelegate, MCNearbyServiceBrowserDelegate>

@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *doneButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSMutableArray *nearbyPeers;
@property (strong, nonatomic) NSMutableArray *acceptedPeers;
@property (strong, nonatomic) NSMutableArray *declinedPeers;

@property (strong, nonatomic) MCNearbyServiceBrowser *browser;
@property (strong, nonatomic) NSString *serviceType;
@property (strong, nonatomic) MCPeerID *peerId;
@property (strong, nonatomic) MCSession *session;

@end

@implementation MyBrowserViewController

#pragma mark Initialization methods
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)initWithCoder:(NSCoder*)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        // Default maximum and minimum number of
        // peers allowed in a session
        self.maximumNumberOfPeers = 8;
        self.minimumNumberOfPeers = 2;
    }
    return self;
}

- (void)setupWithServiceType:(NSString *)serviceType session:(MCSession *)session peer:(MCPeerID *)peerId
{
    self.serviceType = serviceType;
    self.session = session;
    self.peerId = peerId;
}

#pragma mark - View lifecycle methods
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(peerConnected:) name:PeerConnectionAcceptedNotification object:nil];
    
    // Set the toolbar delegate to be able
    // to position it to the top of the view.
    self.toolbar.delegate = self;
    
    self.nearbyPeers = [@[] mutableCopy];
    self.acceptedPeers = [@[] mutableCopy];
    self.declinedPeers = [@[] mutableCopy];
    
    [self showDoneButton:NO];
    
    self.browser = [[MCNearbyServiceBrowser alloc] initWithPeer:self.peerId serviceType:self.serviceType];
    self.browser.delegate = self;
    [self.browser startBrowsingForPeers];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    // Release any retained subviews of the main view.
    
}

- (void)peerConnected:(NSNotification *)notification
{
    MCPeerID *peer = (MCPeerID *)[notification userInfo][@"peer"];
    
    BOOL nearbyDeviceDecision = [[notification userInfo][@"accept"] boolValue];
    if (nearbyDeviceDecision) {
        [self.acceptedPeers addObject:peer];
    } else {
        [self.declinedPeers addObject:peer];
    }
    if ([self.acceptedPeers count] >= (self.maximumNumberOfPeers - 1)) {
        [self doneButtonPressed:nil];
    } else {
        if ([self.acceptedPeers count] < (self.minimumNumberOfPeers - 1)) {
            [self showDoneButton:NO];
        } else {
            [self showDoneButton:YES];
        }
        [self.tableView reloadData];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIStatusBarStyle) preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#pragma mark - UIToolbarDelegate methods
- (UIBarPosition)positionForBar:(id <UIBarPositioning>)bar
{
    return UIBarPositionTopAttached;
    
}

#pragma mark - Helper methods
- (void)showDoneButton:(BOOL)display
{
    NSMutableArray *toolbarButtons = [[self.toolbar items] mutableCopy];
    if (display) {
        // Show the done button
        if (![toolbarButtons containsObject:self.doneButton]) {
            [toolbarButtons addObject:self.doneButton];
            [self.toolbar setItems:toolbarButtons animated:NO];
        }
    } else {
        // Hide the done button
        [toolbarButtons removeObject:self.doneButton];
        [self.toolbar setItems:toolbarButtons animated:NO];
    }
}

#pragma mark - Action methods

- (IBAction)cancelButtonPressed:(id)sender {
    [self.browser stopBrowsingForPeers];
    self.browser.delegate = nil;
    // Send the delegate a message that the controller was canceled.
    if ([self.delegate respondsToSelector:@selector(myBrowserViewControllerWasCancelled:)]) {
        [self.delegate myBrowserViewControllerWasCancelled:self];
    }
}

- (IBAction)doneButtonPressed:(id)sender {
    [self.browser stopBrowsingForPeers];
    self.browser.delegate = nil;
    // Send the delegate a message that the controller was done browsing.
    if ([self.delegate respondsToSelector:@selector(myBrowserViewControllerDidFinish:)]) {
        [self.delegate myBrowserViewControllerDidFinish:self];
    }
}

#pragma mark - Browser delegate methods
- (void)browser:(MCNearbyServiceBrowser *)browser didNotStartBrowsingForPeers:(NSError *)error
{
    NSLog(@"Error browsing: %@",error.localizedDescription);
}

- (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info
{
    [self.nearbyPeers addObject:peerID];
    [self.tableView reloadData];
}

- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID
{
    [self.nearbyPeers removeObject:peerID];
    [self.acceptedPeers removeObject:peerID];
    [self.declinedPeers removeObject:peerID];
    
    if (self.acceptedPeers.count < (self.minimumNumberOfPeers -1)) {
        [self showDoneButton:NO];
    }
    [self.tableView reloadData];
}

#pragma mark - Table view data source and delegate methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.nearbyPeers count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"NearbyDevicesCell";
    MyBrowserTableViewCell *cell = (MyBrowserTableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[MyBrowserTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.accessoryView = nil;
    }
    // 1
    MCPeerID *cellPeerId = (MCPeerID *)self.nearbyPeers[indexPath.row];
    
    // 2
    if ([self.acceptedPeers containsObject:cellPeerId]) {
        if ([cell.accessoryView isKindOfClass:[UIActivityIndicatorView class]]) {
            UIActivityIndicatorView *activityIndicatorView = (UIActivityIndicatorView *)cell.accessoryView;
            [activityIndicatorView stopAnimating];
        }
        UILabel *checkmarkLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
        checkmarkLabel.text = @" √ ";
        cell.accessoryView = checkmarkLabel;
    }
    
    // 3
    else if ([self.declinedPeers containsObject:cellPeerId]) {
        if ([cell.accessoryView isKindOfClass:[UIActivityIndicatorView class]]) {
            UIActivityIndicatorView *activityIndicatorView = (UIActivityIndicatorView *)cell.accessoryView;
            [activityIndicatorView stopAnimating];
        }
        UILabel *unCheckmarkLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
        unCheckmarkLabel.text = @" X ";
        cell.accessoryView = unCheckmarkLabel;
    }
    
    // 4
    else {
        // 5
        UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        activityIndicatorView.hidesWhenStopped = YES;
        [activityIndicatorView setColor:[(AppDelegate *)[[UIApplication sharedApplication] delegate] mainColor]];
        [activityIndicatorView startAnimating];
        cell.accessoryView = activityIndicatorView;
        
        // 6
        [self.browser invitePeer:cellPeerId toSession:self.session withContext:[@"Making contact" dataUsingEncoding:NSUTF8StringEncoding] timeout:10];
    }
    // 7
    cell.textLabel.text = cellPeerId.displayName;
    return cell;
}

@end
