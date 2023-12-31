
//	Base implementation modified by Antonio Pertusa on June 19 2012
//
//  BPXLUUIDHandler.m
//  UUIDHandler
//
//  Created by Doug Russell on 2/29/12.
//  Copyright (c) 2012 Black Pixel. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "BPXLUUIDHandler.h"
#import "mirbot-Swift.h"

#ifndef ARCLOGIC
#define ARCLOGIC

#ifdef HASARC
#undef HASARC
#endif
#ifdef HASWEAK
#undef HASWEAK
#endif
#ifdef STRONG
#undef STRONG
#endif
#ifdef __STRONG
#undef __STRONG
#endif
#ifdef WEAK
#undef WEAK
#endif
#ifdef __WEAK
#undef __WEAK
#endif
#ifdef __BRIDGE
#undef __BRIDGE
#endif

#define HASARC __has_feature(objc_arc)

#define HASWEAK __has_feature(objc_arc_weak)

#if HASARC
#define IF_ARC(ARCBlock, NOARCBlock) ARCBlock
#define NO_ARC(NoARCBlock)
#define __BRIDGE __bridge
#define STRONG strong
#define __STRONG __strong
#if HASWEAK
#define __WEAK __weak
#define WEAK weak
#define NO_WEAK(NoWeakBlock)
#else
#define WEAK assign
#define __WEAK __unsafe_unretained
#define NO_WEAK(NoWeakBlock) NoWeakBlock
#endif
#else
#define IF_ARC(ARCBlock, NOARCBlock) NOARCBlock
#define NO_ARC(NoARCBlock) NoARCBlock
#define __BRIDGE
#define STRONG retain
#define __STRONG
#define WEAK assign
#define __WEAK
#define NO_WEAK(NoWeakBlock) NoWeakBlock
#endif

#endif

@implementation BPXLUUIDHandler

static CFStringRef account = CFSTR("bpxl_uuid_account");
static CFStringRef service = CFSTR("bpxl_uuid_service");

// API: New method

+(NSString *)retrieveUserIdFromICloud
{
    NSString *iCloudUserid=nil;
    
    // Try to retrieve userid from iCloud
    NSUbiquitousKeyValueStore *keyStore=[NSUbiquitousKeyValueStore defaultStore];
    
    if (keyStore!=nil)
    {
        NSDictionary *dict = [keyStore dictionaryRepresentation];
        iCloudUserid = [dict objectForKey:@"userid"];
        
        //NSLog(@"ICLOUD UID: %@",iCloudUserid);
    }
    return iCloudUserid;
}


static CFMutableDictionaryRef CreateKeychainQueryDictionary(void)
{
    CFMutableDictionaryRef query = CFDictionaryCreateMutable(kCFAllocatorDefault, 4, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(query, kSecClass, kSecClassGenericPassword);
    CFDictionarySetValue(query, kSecAttrAccount, account);
    CFDictionarySetValue(query, kSecAttrService, service);
#if !TARGET_IPHONE_SIMULATOR
    if ([BPXLUUIDHandler accessGroup])
    {
        CFDictionarySetValue(query, kSecAttrAccessGroup, (__BRIDGE CFTypeRef)[BPXLUUIDHandler accessGroup]);
    }
#endif
    return query;
}

+ (NSString *)generateUUID
{
    /*#if TARGET_IPHONE_SIMULATOR
     #pragma clang diagnostic push
     #pragma clang diagnostic ignored "-Wdeprecated-declarations"
     return [[UIDevice currentDevice] uniqueIdentifier];
     #pragma clang diagnostic pop
     #endif
     */
    CFUUIDRef uuidRef = CFUUIDCreate(NULL);
    CFStringRef uuidStringRef = CFUUIDCreateString(NULL, uuidRef);
    CFRelease(uuidRef);
    NSString *uuid;
    IF_ARC(
           uuid = ((__bridge_transfer id)(objc_objectptr_t)(uuidStringRef)); // objc_retainedObject(uuidStringRef);
           ,
           uuid = [(NSString *)uuidStringRef autorelease];
           )
    return uuid;
}


// API: modified method
+ (NSString *)storeUUID:(BOOL)itemExists withUserId:(NSString *)uid
{
    // Build a query
    CFMutableDictionaryRef query = CreateKeychainQueryDictionary();
    
    // API: begin mods
    NSString *uuid;
    
    if (uid==nil) uuid= [[self class] generateUUID];
    else uuid=uid;
    // API: end mods
    
    CFDataRef dataRef;
    IF_ARC(
           // This CFBridgingRetain will erroneously raise a static analyzer warning in Xcode 4.2.x,
           // The warning is fixed in 4.3+
           dataRef = CFBridgingRetain([uuid dataUsingEncoding:NSUTF8StringEncoding]);
           ,
           dataRef = CFRetain([uuid dataUsingEncoding:NSUTF8StringEncoding]);
           )
    OSStatus status;
    if (itemExists)
    {
        CFMutableDictionaryRef passwordDictionaryRef = CFDictionaryCreateMutable(kCFAllocatorDefault, 4, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        CFDictionarySetValue(passwordDictionaryRef, kSecValueData, dataRef);
        status = SecItemUpdate(query, passwordDictionaryRef);
        CFRelease(passwordDictionaryRef);
    }
    else
    {
        CFDictionarySetValue(query, kSecValueData, dataRef);
        status = SecItemAdd(query, NULL);
    }
    
    if (status != noErr)
    {
        NSLog(@"BPXLUUIDHandler Keychain Save Error: %d", (int)status);
        uuid = nil;
    }
    
    CFRelease(dataRef);
    CFRelease(query);
    
    return uuid;
}


// API: new method called when userid was not found in keychain
+(NSString *)retrieveOrCreate
{
    
    // Try to retrieve userid from iCloud
    NSString *iCloudUserid=[[self class] retrieveUserIdFromICloud];
    
    if (iCloudUserid!=nil)
    {
        // Propagate to keychain
        return [[self class] storeUUID:NO withUserId:iCloudUserid];
    }
    
    else {
        
        // If no userid was found in icloud, generate a new one from keychain and propagate
        NSString *keychainUserId= [[self class] storeUUID:NO withUserId:nil];
        
        // Propagate to iCloud
        NSUbiquitousKeyValueStore *keyStore=[NSUbiquitousKeyValueStore defaultStore];
        if (keyStore)
        {
            [keyStore setString:keychainUserId forKey:@"userid"];
            [keyStore synchronize];
        }
        
        // Set firsttime = YES for showing help messages
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        appDelegate.firstTime=[NSNumber numberWithBool:YES];
        appDelegate.firstClassifiedObject=[NSNumber numberWithBool:YES];
        
        //AppDelegate *appDelegate2 = [[AppDelegate alloc] init];
        
        return keychainUserId;
    }
}

static NSString *_uuid = nil;

+ (NSString *)UUID
{
    if (_uuid != nil)
        return _uuid;
    
    // Build a query
    CFMutableDictionaryRef query = CreateKeychainQueryDictionary();
    
    // See if the attribute exists
    CFTypeRef attributeResult = NULL;
    OSStatus status = SecItemCopyMatching(query, (CFTypeRef *)&attributeResult);
    if (attributeResult != NULL)
        CFRelease(attributeResult);
    
    if (status != noErr)
    {
        CFRelease(query);
        if (status == errSecItemNotFound) // If there's no entry, store one
        {
            return [[self class] retrieveOrCreate];
        }
        else // Any other error, log it and return nil
        {
            NSLog(@"BPXLUUIDHandler Unhandled Keychain Error %d", (int)status);
            return nil;
        }
    }
    
    // Fetch stored attribute
    CFDictionaryRemoveValue(query, kSecReturnAttributes);
    CFDictionarySetValue(query, kSecReturnData, (id)kCFBooleanTrue);
    CFTypeRef resultData = NULL;
    status = SecItemCopyMatching(query, &resultData);
    
    if (status != noErr)
    {
        CFRelease(query);
        if (status == errSecItemNotFound) // If there's no entry, store one
        {
            return [[self class] retrieveOrCreate];
        }
        else // Any other error, log it and return nil
        {
            NSLog(@"BPXLUUIDHandler Unhandled Keychain Error %d", (int)status);
            return nil;
        }
    }
    
    if (resultData != NULL)
    {
        IF_ARC(
               _uuid = [[NSString alloc] initWithData:((__bridge_transfer id)(objc_objectptr_t)(resultData)) encoding:NSUTF8StringEncoding];
               ,
               _uuid = [[NSString alloc] initWithData:(NSData *)resultData encoding:NSUTF8StringEncoding];
               CFRelease(resultData);
               )
    }
    
    CFRelease(query);
    
    return _uuid;
}

+ (void)reset
{
    NO_ARC([_uuid release];)
    _uuid = nil;
    
    // Build a query
    CFMutableDictionaryRef query = CreateKeychainQueryDictionary();
    
    // See if the attribute exists
    CFTypeRef attributeResult = NULL;
    CFDictionarySetValue(query, kSecReturnAttributes, (id)kCFBooleanTrue);
    OSStatus status = SecItemCopyMatching(query, (CFTypeRef *)&attributeResult);
    if (attributeResult != NULL)
        CFRelease(attributeResult);
    
    if (status == errSecItemNotFound) 
    {
        CFRelease(query);
        return;
    }
    
    status = SecItemDelete(query);
    if (status != noErr)
    {
        NSLog(@"BPXLUUIDHandler Keychain Delete Error: %d", (int)status);
    }
    CFRelease(query);
}

static NSString *_accessGroup = nil;

+ (NSString *)accessGroup
{
    return _accessGroup;
}

+ (void)setAccessGroup:(NSString *)accessGroup
{
    NO_ARC(
           [accessGroup retain];
           [_accessGroup release];
           )
    _accessGroup = accessGroup;
}

@end
