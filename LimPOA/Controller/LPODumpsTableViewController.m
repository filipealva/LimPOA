//
//  LPODumpsTableViewController.m
//  LimPOA
//
//  Created by Filipe Alvarenga on 5/13/14.
//  Copyright (c) 2014 Filipe Alvarenga. All rights reserved.
//

#import "LPODumpsTableViewController.h"
#import "LPODumpMapViewController.h"
#import "LPODumpDetailTableViewController.h"
#import "LPOInfoViewController.h"

@interface LPODumpsTableViewController ()

@property (nonatomic, strong) NSMutableArray *dumps;
@property (nonatomic, assign) CLLocationCoordinate2D currentLocation;
@property (nonatomic, strong) LPOLocationManager *locationManager;
- (IBAction)infoButtonTapped:(UIBarButtonItem *)sender;

@end

@implementation LPODumpsTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"dump_list_title", nil);
    
    [self startLocationManager];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

#pragma mark - Lazy Instantiation

- (NSMutableArray *)dumps
{
    if (!_dumps) {
        _dumps = [[NSMutableArray alloc] initWithArray:[[LPODumpManager new] selectAllDumpsOrderedByDistanceFromLocation:self.currentLocation]];
    }
    
    return _dumps;
}

- (CLLocationCoordinate2D) currentLocation
{
    if (_currentLocation.latitude == 0 && _currentLocation.longitude == 0) {
        _currentLocation = [[self.locationManager lastLocation] coordinate];
    }
    
    return _currentLocation;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dumps.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DumpCell" forIndexPath:indexPath];
    
    Dump *dump = (Dump *)[self.dumps objectAtIndex:indexPath.row];

    UILabel *dumpAddress = (UILabel *)[cell viewWithTag:100];
    UILabel *distanceToDump = (UILabel *)[cell viewWithTag:200];
    
    dumpAddress.text = dump.address;
    distanceToDump.text = [NSString stringWithFormat:@"%.2fkm", [dump.distance floatValue]];
    
    return cell;
}

#pragma mark - Actions

- (void)startLocationManager
{
	if (!self.locationManager) {
		[self setLocationManager:[LPOLocationManager sharedManager]];
		[self.locationManager addDelegate:self];
	}
}

- (IBAction)infoButtonTapped:(UIBarButtonItem *)sender
{
    UINavigationController *navigation = [self.storyboard instantiateViewControllerWithIdentifier:@"Info"];
    LPOInfoViewController *info = (LPOInfoViewController *)[navigation.viewControllers objectAtIndex:0];
    info.type = @"Dump";
    [self.navigationController presentViewController:navigation animated:YES completion:nil];
}

#pragma mark - LPOLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocation:(CLLocation *)location
{
    CLLocation *current = [[CLLocation alloc] initWithLatitude:self.currentLocation.latitude longitude:self.currentLocation.longitude];
    
    if ([current distanceFromLocation:location] > 100) {
        self.currentLocation = location.coordinate;
    }
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"showDumpsMap"]) {
		LPODumpMapViewController *mapViewController = segue.destinationViewController;
        mapViewController.dumps = [NSMutableArray arrayWithArray:[self.dumps subarrayWithRange:NSMakeRange(0, 10)]];
	}
    
    if ([segue.identifier isEqualToString:@"showDetails"]) {
		LPODumpDetailTableViewController *mapViewController = segue.destinationViewController;
        
        Dump *dump = [self.dumps objectAtIndex:[self.tableView indexPathForSelectedRow].row];
        
        mapViewController.dumps = [NSArray arrayWithObject:dump];
	}
}

@end
