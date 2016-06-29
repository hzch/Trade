//
//  CHDBManager.m
//  trade
//
//  Created by Jiang on 16/6/28.
//  Copyright © 2016年 hzch. All rights reserved.
//

#import "CHDBManager.h"
#import <FMDB/FMDB.h>

@interface CHDBManager ()
@property (nonatomic) FMDatabase *db;
@end

@implementation CHDBManager

+ (instancetype)sharedInstance
{
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self initDB];
    }
    return self;
}

- (void)initDB
{
    FMDatabase *db = [FMDatabase databaseWithPath:[self.class dbPath]];
    [db open];
    _db = db;
    BOOL success = [_db executeUpdate:[self.class sqlToCreatList]];
    if (!success) {
        NSLog(@"%@",_db.lastError);
    }
}

- (void)addItem:(CHTradeItem*)item
{
    NSString* sql = [NSString stringWithFormat:@"INSERT OR REPLACE INTO list (number,date,dateString,status,refunds,name,color,price,count) VALUES (?,?,?,?,?,?,?,?,?)"];
    NSArray *values = @[item.number,item.date,item.dateString,item.status,item.refunds,item.name,item.color,item.price,item.count];
    BOOL success = [self.db executeUpdate:sql withArgumentsInArray:values];
    if (!success) {
        NSLog(@"%@",self.db.lastError);
    }
}

+ (NSError *)save
{
    NSError *error;
    [[NSFileManager defaultManager] copyItemAtPath:[self dbPath] toPath:[self savePath] error:&error];
    return error;
}

+ (NSError *)clean
{
    NSError *error;
    [[NSFileManager defaultManager] moveItemAtPath:[self dbPath] toPath:[self savePath] error:&error];
    if (error == nil) {
        [[self sharedInstance] initDB];
    }
    return error;
}

+ (NSString *)dbPath
{
    NSString *docPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    return [docPath stringByAppendingPathComponent:@"trade.db"];
}

+ (NSString *)savePath
{
    NSString *docPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat: @"yyyyMMddHHmmss"];
    NSString *date = [dateFormatter stringFromDate:[NSDate date]];
    NSString *name = [NSString stringWithFormat:@"trade-%@.db",date];
    return [docPath stringByAppendingPathComponent:name];
}

+ (NSString *)sqlToCreatList
{
    return @"CREATE TABLE IF NOT EXISTS list ("
    @" number TEXT KEY NOT NULL,"
    @" date INTEGER NOT NULL,"
    @" dateString TEXT NOT NULL,"
    @" status TEXT NOT NULL,"
    
    @" refunds TEXT NOT NULL,"
    @" name TEXT NOT NULL,"
    @" color TEXT NOT NULL,"
    @" price REAL NOT NULL,"
    @" count INTEGER NOT NULL,"
    @" primary key(number, name, color))";
}

/*
 
 
 return @"CREATE TABLE IF NOT EXISTS " TABLENAME_MAILBOX "("
 MAILBOX_ID @" TEXT KEY NOT NULL,"
 MAILBOX_ACCOUNTRAWID @" INTEGER REFERENCES " TABLENAME_ACCOUNT @" (" MAILACT_ID @") " @"ON DELETE CASCADE,"
 MAILBOX_ACCOUNTRAWTYPE @" INTEGER,"
 MAILBOX_NAME @" TEXT NOT NULL,"
 MAILBOX_TYPE @" INTEGER NOT NULL,"
 MAILBOX_FLAG @" INTEGER DEFAULT 0,"
 MAILBOX_SELECTABLE @" INTEGER DEFAULT 1,"
 MAILBOX_UIDVALID @" INTEGER DEFAULT 1,"
 MAILBOX_UIDFRACTURED @" INTEGER DEFAULT 0,"
 MAILBOX_REMINDTYPE @" INTEGER DEFAULT 0,"
 MAILBOX_SYNCKEY @" TEXT,"
 MAILBOX_PARENTID @" TEXT,"
 MAILBOX_FOLDERTYPE @" INTEGER DEFAULT 0,"
 MAILBOX_ENCRYPTION @" INTEGER DEFAULT 0,"
 @"primary key(" MAILBOX_ID @"," MAILBOX_ACCOUNTRAWID @"))";
 */
@end
