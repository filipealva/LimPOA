//
//  LPOEcoPointMapViewController.m
//  LimPOA
//
//  Created by Filipe Alvarenga on 6/23/14.
//  Copyright (c) 2014 Filipe Alvarenga. All rights reserved.
//

#import "LPOEcoPointMapViewController.h"
#import "LPOEcoPointDetailTableViewController.h"
#import "LPOEcoPointPointAnnotation.h"
#import "EcoPoint.h"
#import "CMMapLauncher.h"

static const NSString *WAZE_TITLE = @"Waze";
static const NSString *GOOGLE_MAPS_TITLE = @"Google Maps";

@interface LPOEcoPointMapViewController () <UIActionSheetDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@end

@implementation LPOEcoPointMapViewController
{
	BOOL isGoogleMapsInstalled;
	BOOL isWazeInstalled;
	NSMutableArray *routeButtons;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"map_view_title", nil);
    
    [self updateAnnotationsWithPlaces:self.ecoPoints];
    [self zoomToFitMapWithAnnotations:self.mapView.annotations];
    
    [self.mapView setShowsUserLocation:YES];
}


- (MKPointAnnotation *)mapViewAnnotationWithPlace:(EcoPoint *)ecoPoint
{
	for (MKPointAnnotation *annotation in self.mapView.annotations) {
		if ([annotation isKindOfClass:[LPOEcoPointPointAnnotation class]]) {
			LPOEcoPointPointAnnotation *annotationObject = (LPOEcoPointPointAnnotation *)annotation;
            
			if ([[[annotationObject.ecoPoint objectID] URIRepresentation] isEqual:[[ecoPoint objectID] URIRepresentation]]) {
				return annotationObject;
			}
		}
	}
	
	return nil;
}

- (void)updateAnnotationsWithPlaces:(NSArray *)ecoPointList
{
    NSMutableArray *ecoPoints = [[NSMutableArray alloc] initWithArray:ecoPointList];
	NSMutableArray *annotations = [[NSMutableArray alloc] init];
	
	// Get annotations that isn't on MapView new annotations
	for (EcoPoint *ecoPoint in ecoPointList) {
		LPOEcoPointPointAnnotation *annotation = (LPOEcoPointPointAnnotation *)[self mapViewAnnotationWithPlace:ecoPoint];
        
		if (annotation) {
            [ecoPoints removeObject:ecoPoint];
		}
	}
	
    // Construct Annotations
	for (int i = 0; i < ecoPoints.count; i++) {
		EcoPoint *ecoPoint = [ecoPoints objectAtIndex:i];
		LPOEcoPointPointAnnotation *annotation = [[LPOEcoPointPointAnnotation alloc] init];
		[annotation setEcoPoint:ecoPoint];
		[annotation setCoordinate:CLLocationCoordinate2DMake([ecoPoint.latitude doubleValue], [ecoPoint.longitude doubleValue])];
		[annotation setTitle:ecoPoint.neighborhood];
		[annotation setSubtitle:ecoPoint.address];
		[annotations addObject:annotation];
	}
	
    // Add new set of annotations to MapView
	[self.mapView addAnnotations:annotations];
    
    // Animate Annotation, if there is only one
    if (self.mapView.annotations.count == 1) {
        [self.mapView selectAnnotation:[annotations objectAtIndex:0] animated:YES];
    }
}

// Zoom MapView to fit all annotations on screen
- (void)zoomToFitMapWithAnnotations:(NSArray *)annotations
{
    if (self.mapView.annotations.count == 0) {
        return;
    }
    
    CLLocationCoordinate2D topLeftCoord;
    topLeftCoord.latitude = -90;
    topLeftCoord.longitude = 180;
    
    CLLocationCoordinate2D bottomRightCoord;
    bottomRightCoord.latitude = 90;
    bottomRightCoord.longitude = -180;
    
    for (MKPointAnnotation *annotation in annotations) {
        topLeftCoord.longitude = fmin(topLeftCoord.longitude, annotation.coordinate.longitude);
        topLeftCoord.latitude = fmax(topLeftCoord.latitude, annotation.coordinate.latitude);
        bottomRightCoord.longitude = fmax(bottomRightCoord.longitude, annotation.coordinate.longitude);
        bottomRightCoord.latitude = fmin(bottomRightCoord.latitude, annotation.coordinate.latitude);
    }
    
    MKCoordinateRegion region;
    region.center.latitude = topLeftCoord.latitude - (topLeftCoord.latitude - bottomRightCoord.latitude) * 0.5;
    region.center.longitude = topLeftCoord.longitude + (bottomRightCoord.longitude - topLeftCoord.longitude) * 0.5;
    region.span.latitudeDelta = fabs(topLeftCoord.latitude - bottomRightCoord.latitude) * 1.2;
    region.span.longitudeDelta = fabs(bottomRightCoord.longitude - topLeftCoord.longitude) * 1.2;
    
    region = [self.mapView regionThatFits:region];
    [self.mapView setRegion:region animated:YES];
}


#pragma mark - MKMapKitDelegate

- (CLLocationDistance)distanceBetweenLocation:(CLLocationCoordinate2D)locationA and:(CLLocationCoordinate2D)locationB
{
    CLLocation *newLocationA = [[CLLocation alloc] initWithLatitude:locationA.latitude longitude:locationA.longitude];
    CLLocation *newLocationB = [[CLLocation alloc] initWithLatitude:locationB.latitude longitude:locationB.longitude];
    
    return [newLocationA distanceFromLocation:newLocationB];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
	if ([annotation isKindOfClass:[MKUserLocation class]]) {
		return nil;
	}
    
	MKPinAnnotationView *annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"annotation"];
    
    if (self.mapView.annotations.count > 1) {
        [annotationView setRightCalloutAccessoryView:[UIButton buttonWithType:UIButtonTypeDetailDisclosure]];
    } else {
        [annotationView setRightCalloutAccessoryView:[UIButton buttonWithType:UIButtonTypeContactAdd]];
    }
    
	[annotationView setAnimatesDrop:YES];
    [annotationView setCanShowCallout:YES];
    
    return annotationView;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
	LPOEcoPointPointAnnotation *annotation = (LPOEcoPointPointAnnotation *)view.annotation;
    
    if (self.ecoPoints.count == 1) {
        [self buttonRoutePressed];
    } else {
        [self performSegueWithIdentifier:@"showEcoPointDetail" sender:annotation];
    }
}

#pragma mark - Actions

- (void)traceRouteWithApp:(CMMapApp)app
{
	EcoPoint *ecoPoint = [self.ecoPoints objectAtIndex:0];
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([ecoPoint.latitude doubleValue], [ecoPoint.longitude doubleValue]);
    CMMapPoint *point = [CMMapPoint mapPointWithName:ecoPoint.neighborhood coordinate:coordinate];
	[CMMapLauncher launchMapApp:app forDirectionsTo:point];
}

- (void)buttonRoutePressed
{
	routeButtons = [[NSMutableArray alloc] init];
	
	isGoogleMapsInstalled = [CMMapLauncher isMapAppInstalled:CMMapAppGoogleMaps];
	isWazeInstalled = [CMMapLauncher isMapAppInstalled:CMMapAppWaze];
	
	if (!isGoogleMapsInstalled && !isWazeInstalled) {
		[self traceRouteWithApp:CMMapAppAppleMaps];
	} else {
		[routeButtons addObject:NSLocalizedString(@"Maps", nil)];
		
		if (isGoogleMapsInstalled) {
			[routeButtons addObject:GOOGLE_MAPS_TITLE];
		}
		
		if (isWazeInstalled) {
			[routeButtons addObject:WAZE_TITLE];
		}
        
		UIActionSheet *actionSheet = [[UIActionSheet alloc] init];
		actionSheet.title = NSLocalizedString(@"place_title_route_options", nil);
		actionSheet.delegate = self;
		
		for (NSString *title in routeButtons) {
			[actionSheet addButtonWithTitle:title];
		}
		
		actionSheet.cancelButtonIndex = [actionSheet addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
		
		[actionSheet showInView:self.view];
	}
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex != routeButtons.count) {
		NSString *buttonTitle = routeButtons[buttonIndex];
        
		if (buttonIndex == 0) {
			[self traceRouteWithApp:CMMapAppAppleMaps];
		} else if ([buttonTitle isEqualToString:[NSString stringWithFormat:@"%@", GOOGLE_MAPS_TITLE]]) {
			[self traceRouteWithApp:CMMapAppGoogleMaps];
		} else {
			[self traceRouteWithApp:CMMapAppWaze];
		}
	}
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"showEcoPointDetail"]) {
		LPOEcoPointDetailTableViewController *detailViewControler = segue.destinationViewController;
        
        LPOEcoPointPointAnnotation *annotation = (LPOEcoPointPointAnnotation *)sender;
        
        EcoPoint *ecoPoint = annotation.ecoPoint;
        
        detailViewControler.ecoPoints = [NSArray arrayWithObject:ecoPoint];
	}
}

@end
