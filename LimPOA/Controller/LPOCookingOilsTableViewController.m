//
//  LPOCookingOilsTableViewController.m
//  LimPOA
//
//  Created by Filipe Alvarenga on 15/05/14.
//  Copyright (c) 2014 Filipe Alvarenga. All rights reserved.
//

#import "LPOCookingOilsTableViewController.h"

@interface LPOCookingOilsTableViewController ()

@property (nonatomic, strong) NSMutableArray *cookingOilPoints;
@property (nonatomic, assign) CLLocationCoordinate2D currentLocation;
@property (nonatomic, strong) LPOLocationManager *locationManager;

@end

@implementation LPOCookingOilsTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self startLocationManager];
}

#pragma mark - Lazy Instantiation

- (NSMutableArray *)cookingOilPoints
{
    if (!_cookingOilPoints) {
        _cookingOilPoints = [[NSMutableArray alloc] initWithArray:[[LPOCookingOilManager new] selectAllCookingOilsOrderedByDistanceFromLocation:self.currentLocation]];
    }
    
    return _cookingOilPoints;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.cookingOilPoints.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CookingOilCell" forIndexPath:indexPath];
    
    CookingOil *cookingOil = (CookingOil *)[self.cookingOilPoints objectAtIndex:indexPath.row];
    
    UILabel *cookingOilName = (UILabel *)[cell viewWithTag:100];
    UILabel *cookingOilAddress = (UILabel *)[cell viewWithTag:200];
    UILabel *distanceToCoookingOilPoint = (UILabel *)[cell viewWithTag:300];
    
    cookingOilName.text = cookingOil.name;
    cookingOilAddress.text = cookingOil.address;
    distanceToCoookingOilPoint.text = [NSString stringWithFormat:@"%.2fkm", [cookingOil.distance doubleValue]];
    
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

#pragma mark - LPOLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocation:(CLLocation *)location
{
    CLLocation *current = [[CLLocation alloc] initWithLatitude:self.currentLocation.latitude longitude:self.currentLocation.longitude];
    
    if ([current distanceFromLocation:location] > 100) {
        self.currentLocation = location.coordinate;
    }
}

@end
