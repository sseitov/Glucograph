//
//  StorageManager.m
//  Glucograph
//
//  Created by Sergey Seitov on 07.04.14.
//  Copyright (c) 2014 Sergey Seitov. All rights reserved.
//

#import "StorageManager.h"

static NSString* databasePathForName(NSString* name)
{	
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	return [documentsDirectory stringByAppendingString:[NSString stringWithFormat:@"/%@.sqlite", name]];
}

@implementation Blood


+ (Blood*)bloodForDate:(NSDate*)date
{
    Blood* blood = [[Blood alloc] init];
    blood.date = date;
    blood.comment = @"";
    blood.morning = 0;
    blood.evening = 0;
    return blood;
}

@end

@interface StorageManager ()

@property (readwrite, nonatomic) sqlite3 *masterDB;

@end

@implementation StorageManager

SYNTHESIZE_SINGLETON_FOR_CLASS(StorageManager);

- (NSData*)getDBData
{
    return [NSData dataWithContentsOfFile:databasePathForName(@"Glucograph2")];
}

- (void)setDBFromData:(NSData*)data
{
    sqlite3_close(_masterDB);
    _masterDB = 0;
    NSString *dbPath = databasePathForName(@"Glucograph2");
    [data writeToFile:dbPath atomically:YES];
    sqlite3_open([dbPath UTF8String], &_masterDB);
}

- (sqlite3*)createDatabase:(NSString*)dbPath
{
	BOOL success = [[NSFileManager defaultManager] createFileAtPath:dbPath contents:nil attributes:nil];
	if (!success) {
		return nil;
	}
	
	sqlite3 *db = NULL;
	if (sqlite3_open([dbPath UTF8String], &db) != SQLITE_OK) {
		sqlite3_close(db);
		return nil;
	}
	sqlite3_stmt *pStmt;
	NSString *sql = @"\
CREATE TABLE bloods (\
day timestamp NOT NULL PRIMARY KEY UNIQUE, \
morning float NOT NULL, \
evening float NOT NULL, \
comment text NOT NULL)";
	
	if(sqlite3_prepare(db, [sql UTF8String], -1, &pStmt, NULL) != SQLITE_OK) {
		NSLog(@"SQL %@ Error: '%s'", sql, sqlite3_errmsg(db));
		sqlite3_finalize(pStmt);
		sqlite3_close(db);
		return nil;
	}
	sqlite3_step(pStmt);
	sqlite3_finalize(pStmt);
	
	return db;
}

- (BOOL)restoreDb:(NSString*)path
{
	sqlite3 *db = NULL;
	if (sqlite3_open([path UTF8String], &db) != SQLITE_OK) {
		sqlite3_close(db);
		return NO;
	}
    sqlite3_stmt *pStmt;
	if (sqlite3_prepare(db, "select datetime(ZDATE,'unixepoch','31 years','localtime'),zmorning,zevening,zcomment from zblood",
                        -1, &pStmt, NULL) != SQLITE_OK) {
		NSLog(@"SQL Error: '%s'", sqlite3_errmsg(db));
		sqlite3_finalize(pStmt);
		return NO;
	}
	while (sqlite3_step(pStmt) == SQLITE_ROW) {
        Blood* blood = [[Blood alloc] init];
        NSString *strDate = [NSString stringWithUTF8String:(const char*)sqlite3_column_text(pStmt, 0)];
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
        blood.date = [df dateFromString:strDate];
        blood.morning = (float)sqlite3_column_double(pStmt, 1);
        blood.evening = (float)sqlite3_column_double(pStmt, 2);
        const unsigned char* comment = sqlite3_column_text(pStmt, 3);
        if (comment) {
            blood.comment = [NSString stringWithUTF8String:(const char*)comment];
        } else {
            blood.comment = @"";
        }
        [self storeBlood:blood];
    }
	sqlite3_finalize(pStmt);
    return YES;
}

- (id)init
{
    self = [super init];
    if (self) {
        NSString *dbPath = databasePathForName(@"Glucograph2");
        if ([[NSFileManager defaultManager] fileExistsAtPath:dbPath] == NO) {
            _masterDB = [self createDatabase:dbPath];
        } else {
            sqlite3_open([dbPath UTF8String], &_masterDB);
        }
        NSString *oldPath = databasePathForName(@"Glucograph");
        if ([[NSFileManager defaultManager] fileExistsAtPath:oldPath] == YES) {
            [self restoreDb:oldPath];
            [[NSFileManager defaultManager] removeItemAtPath:oldPath error:nil];
        } else {
            NSLog(@"no restore");
        }
    }
    return self;
}

- (void)storeBlood:(Blood*)blood
{
    sqlite3_stmt *pStmt;
    NSString* sql = [NSString stringWithFormat:@"insert or replace into bloods (day,morning,evening,comment) values (%f,%f,%f,'%@')",
                     [blood.date timeIntervalSince1970], blood.morning, blood.evening, blood.comment];
	if (sqlite3_prepare(_masterDB, [sql UTF8String], -1, &pStmt, NULL) != SQLITE_OK) {
		NSLog(@"SQL Error: '%s'", sqlite3_errmsg(_masterDB));
		sqlite3_finalize(pStmt);
		return;
	}
    if(sqlite3_step(pStmt) != SQLITE_DONE) {
		NSLog(@"SQL %@ Error: '%s'", sql, sqlite3_errmsg(_masterDB));
	}
	sqlite3_finalize(pStmt);
    [[NSUserDefaults standardUserDefaults] setDouble:[[NSDate date] timeIntervalSince1970] forKey:@"localModified"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (Blood*)getBloodForDate:(NSDate*)date
{
    sqlite3_stmt *pStmt;
    NSString* sql = [NSString stringWithFormat:@"select morning,evening,comment from bloods where day=%f", [date timeIntervalSince1970]];
	if (sqlite3_prepare(_masterDB, [sql UTF8String], -1, &pStmt, NULL) != SQLITE_OK) {
		NSLog(@"SQL Error: '%s'", sqlite3_errmsg(_masterDB));
		sqlite3_finalize(pStmt);
		return nil;
	}
    Blood* blood = [Blood bloodForDate:date];
    if (sqlite3_step(pStmt) == SQLITE_ROW) {
        blood.morning = (float)sqlite3_column_double(pStmt, 0);
        blood.evening = (float)sqlite3_column_double(pStmt, 1);
        const unsigned char* t = sqlite3_column_text(pStmt, 2);
        if (t) {
            blood.comment = [NSString stringWithUTF8String:(const char*)t];
        } else {
            blood.comment = @"";
        }
    }
    return blood;
}

- (void)removeBloodForDate:(NSDate*)date
{
    sqlite3_stmt *pStmt;
    NSString* sql = [NSString stringWithFormat:@"delete from bloods where day=%f", [date timeIntervalSince1970]];
	if (sqlite3_prepare(_masterDB, [sql UTF8String], -1, &pStmt, NULL) != SQLITE_OK) {
		NSLog(@"SQL Error: '%s'", sqlite3_errmsg(_masterDB));
		sqlite3_finalize(pStmt);
		return;
	}
    if(sqlite3_step(pStmt) != SQLITE_DONE) {
		NSLog(@"SQL %@ Error: '%s'", sql, sqlite3_errmsg(_masterDB));
	}
	sqlite3_finalize(pStmt);
}

- (void)setMorningBlood:(float)value forDate:(NSDate*)date
{
    Blood* blood = [self getBloodForDate:date];
    blood.morning = value;
    [self storeBlood:blood];
}

- (void)setEveningBlood:(float)value forDate:(NSDate*)date
{
    Blood* blood = [self getBloodForDate:date];
    blood.evening = value;
    [self storeBlood:blood];
}

- (void)setComment:(NSString*)comment forDate:(NSDate*)date
{
    Blood* blood = [self getBloodForDate:date];
    blood.comment = comment;
    [self storeBlood:blood];
}

@end
