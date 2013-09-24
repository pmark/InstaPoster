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

@end
