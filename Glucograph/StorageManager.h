//
//  StorageManager.h
//  Glucograph
//
//  Created by Sergey Seitov on 07.04.14.
//  Copyright (c) 2014 Sergey Seitov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SynthesizeSingleton.h"
#include <sqlite3.h>

@interface Blood : NSObject

@property (nonatomic, strong) NSDate* date;
@property (nonatomic, readwrite) float evening;
@property (nonatomic, readwrite) float morning;
@property (nonatomic, strong) NSString* comment;

+ (Blood*)bloodForDate:(NSDate*)date;

@end

@interface StorageManager : NSObject

+ (StorageManager *)sharedStorageManager;

- (NSData*)getDBData;
- (void)setDBFromData:(NSData*)data;

- (Blood*)getBloodForDate:(NSDate*)date;
- (void)removeBloodForDate:(NSDate*)date;
- (void)setMorningBlood:(float)value forDate:(NSDate*)date;
- (void)setEveningBlood:(float)value forDate:(NSDate*)date;
- (void)setComment:(NSString*)comment forDate:(NSDate*)date;

@end
