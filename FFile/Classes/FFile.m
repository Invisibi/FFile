//
//  FFile.m
//  Pods
//
//  Created by muqq on 2016/4/24.
//
//

#import "FFile.h"

@interface FFile()

@property (nonatomic, strong) NSData *data;
@property (nonatomic, strong) NSString *fileExtension;
@property (nonatomic, strong) NSURL *filePath;

@end

@implementation FFile

static NSString *_s3URL;
static NSString *_s3Bucket;
static SPTPersistentCache *cache;
static NSString *const kFileKeyPath = @"files";
static NSString *cachePath;

- (BOOL)isDataAvailable {
    return self.data != nil;
}

+ (void)setup:(NSString *)awsIdentityPoolId s3URL:(NSString *)s3URL s3Bucket:(NSString *)bucket s3Region:(AWSRegionType)regionTyoe {
    AWSCognitoCredentialsProvider *credentialsProvider = [[AWSCognitoCredentialsProvider alloc] initWithRegionType:regionTyoe identityPoolId:awsIdentityPoolId];
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:regionTyoe credentialsProvider:credentialsProvider];
    [AWSServiceManager defaultServiceManager].defaultServiceConfiguration = configuration;
    _s3URL = s3URL;
    _s3Bucket = bucket;

    cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject stringByAppendingString:@"/com.kymco.sunray.cache/"];
    SPTPersistentCacheOptions *options = [[SPTPersistentCacheOptions alloc] initWithCachePath:cachePath identifier:@"com.kymco.sunray.cache" defaultExpirationInterval:60 * 60 * 24 garbageCollectorInterval:(NSUInteger)(1.5 * SPTPersistentCacheDefaultGCIntervalSec) debug:^(NSString * _Nonnull string) {
        NSLog(@"%@", string);
    }];

    SPTPersistentCache *SPTCache = [[SPTPersistentCache alloc] initWithOptions:options];
    cache = SPTCache;
}

- (instancetype)initWithName:(NSString *)name filePath:(NSURL *)path {
    self = [super init];
    if (self) {
        self.filePath = path;
        self.fileExtension = path.pathExtension;
        self.objectId = [NSString stringWithFormat:@"%@-%@.%@", [[NSUUID UUID] UUIDString], name, self.fileExtension];
    }
    return self;
}

- (instancetype)initWithName:(NSString *)name data:(NSData *)data fileExtension:(NSString *)fileExtension {
    self = [super init];
    if (self) {
        self.data = data;
        self.fileExtension = fileExtension;
        self.objectId = [NSString stringWithFormat:@"%@-%@.%@", [[NSUUID UUID] UUIDString], name, self.fileExtension];
    }
    return self;
}

- (instancetype)initWithobjectId:(NSString *)objectId {
    self = [super init];
    if (self) {
        NSString *URLPath = [NSString stringWithFormat:@"%@%@/file/%@", _s3URL, _s3Bucket, objectId];
        ;
        self.url = [[NSURL alloc] initWithString:URLPath];
        self.objectId = objectId;
    }
    return self;
}

- (void)getDataInBackgroundWithBlock:(FDataResultBlock)block {
    if (self.objectId) {
        NSString *key = [NSString stringWithFormat:@"%@%@/file/%@", _s3URL, _s3Bucket, self.objectId];
        key = [key stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
        [self loadCache:key block:block];
    } else {
        NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:-101 userInfo:@{NSLocalizedDescriptionKey: @"Invalid FFile"}];
        block(nil, error);
    }
}

- (void)getFilePathInBackgroundWithBlock:(FURLResultBlock)block {
    [self getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        if (error) {
            block(nil, error);
        } else {
            NSString *key = [NSString stringWithFormat:@"%@%@/file/%@", _s3URL, _s3Bucket, self.objectId];
            key = [key stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
            NSString *filePath = [cachePath stringByAppendingString:[NSString stringWithFormat:@"ht/%@", key]];
            NSURL *fileURL = [NSURL fileURLWithPath:filePath];
            block(fileURL, nil);
        }
    }];
}

- (void)loadCache:(NSString *)key block:(FDataResultBlock)block {
    [cache loadDataForKey:key withCallback:^(SPTPersistentCacheResponse * _Nonnull response) {
        if (response.result == SPTPersistentCacheResponseCodeOperationSucceeded) {
            block(response.record.data, nil);
        } else if (response.result == SPTPersistentCacheResponseCodeNotFound) {
            if (self.data) {
                [self storeCache:key data:self.data block:block];
            } else if (self.filePath.path) {
                NSData *data = [NSData dataWithContentsOfFile:self.filePath.path];
                [self storeCache:key data:data block:block];
            } else if (self.url) {
                __weak FFile *weakself = self;
                dispatch_queue_t backgroundQueue = dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0);
                dispatch_async(backgroundQueue, ^{
                    NSData *data = [NSData dataWithContentsOfURL:weakself.url];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weakself storeCache:key data:data block:block];
                    });
                });
            } else {
                NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:-101 userInfo:@{NSLocalizedDescriptionKey: @"Invalid FFile"}];
                block(nil, error);
                return;
            }
        } else {
            block(nil, response.error);
        }
    } onQueue:dispatch_get_main_queue()];
}

- (void)storeCache:(NSString *)key data:(NSData *)data block:(FDataResultBlock)block {
    [cache storeData:data forKey:key locked:YES withCallback:^(SPTPersistentCacheResponse * _Nonnull response) {
        if (response.result == SPTPersistentCacheResponseCodeOperationSucceeded) {
            block(data, nil);
        } else {
            block(nil, response.error);
        }
    } onQueue:dispatch_get_main_queue()];
}

- (void)saveInBackgroundWithBlock:(FBooleanResultBlock)block {
    [self saveInBackgroundWithBlock:block withProgressBlock:nil];
}

- (void)saveInBackgroundWithBlock:(FBooleanResultBlock)block withProgressBlock:(FProgressBlock)progressBlock {
    __weak FFile *weakSelf = self;
    FURLResultBlock saveCompletionBlock = ^void(NSURL *url, NSError *error) {
        if (error) {
            block(NO, error);
        } else {
            weakSelf.url = url;
            block(YES, nil);
        }
    };

    if (self.url) {
        block(YES, nil);
    } else if (self.filePath && self.objectId) {
        [self saveFileWithName:self.objectId path:self.filePath block:saveCompletionBlock progressBlock:progressBlock];
    } else if (self.data && self.objectId) {
        [self saveFileWithName:self.objectId data:self.data block:saveCompletionBlock progressBlock:progressBlock];
    } else {
        NSString *message = @"Should call get data first";
        NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:-100 userInfo:@{NSLocalizedDescriptionKey: message}];
        block(nil, error);
    }
}

- (void)saveFileWithName:(NSString *)name path:(NSURL *)path block:(FURLResultBlock)block progressBlock:(FProgressBlock)progressBlock {
    NSData *data = [NSData dataWithContentsOfFile:path.path];
    if (data) {
        [self saveFileWithName:name data:data block:block progressBlock:progressBlock];
    } else {
        NSString *message = [NSString stringWithFormat:@"Filed to find file at path %@", path.path];
        NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileNoSuchFileError userInfo:@{NSLocalizedDescriptionKey: message}];
        block(nil, error);
    }
}

- (void)saveFileWithName:(NSString *)name data:(NSData *)data block:(FURLResultBlock)block progressBlock:(FProgressBlock)progressBlock {
    NSString *cacheDirectory = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
    cacheDirectory = [cacheDirectory stringByAppendingString:@"/com.kymco.sunray.cache/"];
    dispatch_queue_t backgroundQueue = dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0);
    dispatch_async(backgroundQueue, ^{
        NSString *URLPath = [NSString stringWithFormat:@"%@%@/file/%@", _s3URL, _s3Bucket, name];
        ;
        NSString *encodeURL = [URLPath stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
        NSString *filePath = [NSString stringWithFormat:@"%@%@", cacheDirectory, encodeURL];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL isDirectory = YES;
        NSError *error;

        if (![fileManager fileExistsAtPath:cacheDirectory isDirectory:&isDirectory] || !isDirectory) {
            [fileManager createDirectoryAtPath:cacheDirectory withIntermediateDirectories:NO attributes:nil error:&error];
        }
        [data writeToFile:filePath atomically:YES];
        isDirectory = NO;

        if (![fileManager fileExistsAtPath:filePath isDirectory:&isDirectory] || isDirectory) {
            NSError * error = [NSError errorWithDomain:NSCocoaErrorDomain
                                                  code:NSFileNoSuchFileError
                                              userInfo:@{ NSLocalizedDescriptionKey: @"file not found" }];

            block(nil, error);
            return;
        }

        AWSS3TransferManagerUploadRequest *uploadRequest = [[AWSS3TransferManagerUploadRequest alloc] init];
        uploadRequest.bucket = _s3Bucket;
        uploadRequest.body = [NSURL fileURLWithPath:filePath];
        uploadRequest.ACL = AWSS3BucketCannedACLPublicReadWrite;
        uploadRequest.key = [NSString stringWithFormat:@"file/%@", name];
        AWSS3TransferManager *transferManager = [AWSS3TransferManager defaultS3TransferManager];
        [[transferManager upload:uploadRequest] continueWithBlock:^id(AWSTask *task) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (task.error) {
                    block(nil, task.error);
                } else {
                    [cache storeData:data forKey:encodeURL locked:YES withCallback:^(SPTPersistentCacheResponse * _Nonnull response) {
                        NSURL *url = [NSURL URLWithString:URLPath];
                        block(url, nil);
                    } onQueue:dispatch_get_main_queue()];
                }
            });
            return nil;
        }];

        if (progressBlock) {
            uploadRequest.uploadProgress =  ^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend){
                dispatch_async(dispatch_get_main_queue(), ^{
                    float progress = (float)totalBytesSent / (float)totalBytesExpectedToSend;
                    progressBlock(progress);
                });
            };
        }
    });
}


@end
