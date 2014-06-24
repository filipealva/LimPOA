//
//  LPOCookingOilMapViewController.h
//  LimPOA
//
//  Created by Filipe Alvarenga on 6/21/14.
//  Copyright (c) 2014 Filipe Alvarenga. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface LPOCookingOilMapViewController : UIViewController <MKMapViewDelegate>

@property (nonatomic, strong) NSMutableArray *cookingOils;

@end
