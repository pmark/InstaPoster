//
//  ViewController.m
//  InstaPoster
//
//  Created by P. Mark Anderson on 9/19/13.
//  Copyright (c) 2013 Steinbacher Design. All rights reserved.
//

#import "ViewController.h"
#import "ObjCBSON.h"
#import "MongoConnection.h"
#import "MongoDBCollection.h"
#import "MongoKeyedPredicate.h"
#import <SDWebImage/UIImageView+WebCache.h>

@interface ViewController ()

@property (nonatomic, strong) MongoDBCollection *mongoCollection;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self mongoSetup];
    
#if 0
    NSDictionary *post = @{
                           @"imageUrl": @"http://distilleryimage8.ak.instagram.com/ee729fda24a211e393f522000aeb4102_7.jpg",
                           @"name": @"test",
                           @"coordinates": @{
                                   @"latitude" : @(43.0469),
                                   @"longitude" : @(-76.1442)
                                   }
                           };
    
    [self createPost:post];
#endif
    
    [self getPost];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.mapView.sm3dar startCamera];
}

- (void)mongoSetup
{
    NSError *error = nil;
    MongoConnection *dbConn = [MongoConnection connectionForServer:@"ds047438.mongolab.com:47438"
                                                             error:&error];
    
    if (error)
    {
        NSLog(@"Error connecting to DB: %@", error);
        self.mongoCollection = nil;
    }
    else
    {
        NSLog(@"Connected to DB.");

        [dbConn authenticate:@"instaposter"
                    username:@"ios"
                    password:@"instapassword"
                       error:&error];
        
        if (error)
        {
            NSDictionary *serverStatus = [self.mongoCollection lastOperationDictionary];
            NSLog(@"Error authenticating with DB: %@\n\n%@\n\n", error, serverStatus);
            self.mongoCollection = nil;
        }
        else
        {
            self.mongoCollection = [dbConn collectionWithName:@"instaposter.posts"];
        }
    }
}

- (void)createPost:(NSDictionary*)post
{
    NSError *error = nil;
    [self.mongoCollection insertDictionary:post
                              writeConcern:nil
                                     error:&error];
    
    if (error)
    {
        NSDictionary *serverStatus = [self.mongoCollection lastOperationDictionary];
        NSLog(@"Error creating post: %@\n\n%@\n\n", error, serverStatus);
    }
    else
    {
        NSLog(@"Created post.");
    }
}

- (void)getPost
{
    NSError *error = nil;
    MongoKeyedPredicate *predicate = [MongoKeyedPredicate predicate];
    [predicate keyPath:@"name" matches:@"test"];
    BSONDocument *resultDoc = [self.mongoCollection findOneWithPredicate:predicate
                                                                   error:&error];
    if (error)
    {
        NSLog(@"Error fetching post: %@", error);
    }
    else
    {
        NSDictionary *result = [BSONDecoder decodeDictionaryWithDocument:resultDoc];
        NSLog(@"fetch result: %@", result);
    }
}

- (NSArray*)fetchAllPosts
{
    NSError *error = nil;
    MongoKeyedPredicate *predicate = [MongoKeyedPredicate predicate];
    [predicate keyPath:@"name" matches:@"test"];
    NSArray *results = [self.mongoCollection findAllWithError:&error];
    NSMutableArray *posts = [NSMutableArray arrayWithCapacity:[results count]];
    
    if (error)
    {
        NSLog(@"Error fetching posts: %@", error);
    }
    else
    {
        NSLog(@"Fetch results: %i", [results count]);
        
        for (BSONDocument *doc in results)
        {
            [posts addObject:[BSONDecoder decodeDictionaryWithDocument:doc]];
        }
    }
    
    return posts;
}

- (void)sm3darLoadPoints:(SM3DARController *)sm3dar
{
    NSMutableArray *points = [NSMutableArray array];
    
    for (NSDictionary *post in [self fetchAllPosts])
    {
        NSDictionary *locationData = [post objectForKey:@"coordinates"];
        NSNumber *latitude = [locationData objectForKey:@"latitude"];
        NSNumber *longitude = [locationData objectForKey:@"longitude"];
        
        if (latitude && longitude)
        {
            CLLocationCoordinate2D coord;
            coord.longitude = [longitude doubleValue];
            coord.latitude = [latitude doubleValue];
            CLLocation *location = [[CLLocation alloc] initWithCoordinate:coord
                                                                 altitude:(rand() % 100)
                                                       horizontalAccuracy:-1
                                                         verticalAccuracy:-1
                                                                timestamp:nil];
            
            NSString *strImageUrl = [post objectForKey:@"imageUrl"];
            NSURL *imageUrl = (strImageUrl ? [NSURL URLWithString:strImageUrl] : nil);

            if (imageUrl)
            {
                SM3DARPointOfInterest *poi = [[SM3DARPointOfInterest alloc] initWithLocation:location
                                                                                       title:[post objectForKey:@"name"]
                                                                                    subtitle:nil
                                                                                         url:imageUrl
                                                                                  properties:post];
                
//                [points addObject:poi];
                
                [self.mapView addAnnotation:poi];
                [self setPoiImage:poi];
            }
            
        }
        
    }
    
//    [self.mapView addAnnotations:points];
    [self.mapView zoomMapToFit];
}

- (void)setPoiImage:(SM3DARPointOfInterest*)poi
{
    __weak SM3DARIconMarkerView *v = (SM3DARIconMarkerView*)poi.view;
    NSString *strImageUrl = [poi.properties objectForKey:@"imageUrl"];
    NSURL *imageUrl = (strImageUrl ? [NSURL URLWithString:strImageUrl] : nil);
    
    if (imageUrl)
    {
        [v.icon setImageWithURL:imageUrl
               placeholderImage:[UIImage imageNamed:@"3dar_marker_icon1.png"]
                        options:SDWebImageRefreshCached
                       progress:^(NSUInteger receivedSize, long long expectedSize) {
                       }
                      completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                          NSLog(@"Done: %.0f, %.0f, ERROR: %@", image.size.width, image.size.height, error);
                          
                          CGRect f = v.icon.frame;
                          f.size = CGSizeMake(200, 200);
                          v.icon.frame = f;
                      }];
    }
    
}

@end
