//
//  ViewController.h
//  InstaPoster
//
//  Created by P. Mark Anderson on 9/19/13.
//  Copyright (c) 2013 Steinbacher Design. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SM3DAR.h"

@interface ViewController : UIViewController <SM3DARDelegate>
@property (weak, nonatomic) IBOutlet SM3DARMapView *mapView;

@end
