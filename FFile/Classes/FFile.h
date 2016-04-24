//
//  FFile.h
//  Pods
//
//  Created by muqq on 2016/4/24.
//
//

#import <Foundation/Foundation.h>
#import <Firebase/Firebase.h>
#import <AWSS3/AWSS3.h>
#import <AWSCore/AWSCore.h>
#import <SPTPersistentCache/SPTPersistentCache.h>

typedef void (^FURLResultBlock)(NSURL *url, NSError *error);
typedef void (^FBooleanResultBlock)(BOOL succeeded, NSError *error);
typedef void (^FDataResultBlock)(NSData *data, NSError *error);



@interface FFile : NSObject

@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *objectId;
@property (nonatomic, getter=isDataAvailable, readonly) BOOL isDataAvailable;

+ (void)setup:(NSString *)awsIdentityPoolId s3URL:(NSString *)s3URL s3Bucket:(NSString *)bucket s3Region:(AWSRegionType)regionTyoe firebaseURL:(NSString *)firebaseURL;

- (instancetype)initWithName:(NSString *)name filePath:(NSURL *)path;

- (instancetype)initWithName:(NSString *)name data:(NSData *)data fileExtension:(NSString *)fileExtension;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

- (void)saveInBackgroundWithBlock:(FBooleanResultBlock)block;

- (void)getDataInBackgroundWithBlock:(FDataResultBlock)block;

// this method should be called only after save in background
- (NSDictionary *)dictionary;


@end
