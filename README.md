# FFile

[![CI Status](http://img.shields.io/travis/muqq/FFile.svg?style=flat)](https://travis-ci.org/muqq/FFile)
[![Version](https://img.shields.io/cocoapods/v/FFile.svg?style=flat)](http://cocoapods.org/pods/FFile)
[![License](https://img.shields.io/cocoapods/l/FFile.svg?style=flat)](http://cocoapods.org/pods/FFile)
[![Platform](https://img.shields.io/cocoapods/p/FFile.svg?style=flat)](http://cocoapods.org/pods/FFile)

## Requirements
```ruby
iOS >= 8.0
```
## Installation

FFile is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "FFile"
```
## Getting Started

```swift
FFile.setup("<Your AWS identity pool Id>",
 s3URL: "<AWS Region URL>",
 s3Bucket: "<AWS bucket>", 
 s3Region: "<Your AWS bucket region>" 
```
### Description 
- identity pool Id: Follow this link:
http://docs.aws.amazon.com/mobile/sdkforios/developerguide/cognito-auth.html
- s3URL: https://s3-ap-northeast-1.amazonaws.com/
- s3Bucket: Muqq
- s3Region: AWSRegionAPNortheast1

## Save file
- Save to S3
```swift
let file = FFile(name: "example", data: data, fileExtension: "png")
file.saveInBackgroundWithBlock { success, error in
    if success {
        //Do something if success
    } else {
        // handle error
    }
}
```
- After saved to S3, upload the file reference with your data to firebase
```swift
//get your objectId and save it to anywhere
file.objectId
```
## Get data
```swift
//use objectId to get your file
let file = FFile(objectId: objectId)
file.getDataInBackgroundWithBlock { data, error in
    if error {
        // handle error
    } else {
        // use your data
    }
}
```
## Author

muqq, bbbb55952000@gmail.com

## License

FFile is available under the MIT license. See the LICENSE file for more info.
