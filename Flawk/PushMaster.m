//
//  PushMaster.m
//  Flawk
//
//  Created by Justin Brower on 3/6/16.
//  Copyright © 2016 Big Sweet Software Projects. All rights reserved.
//

#import "PushMaster.h"

@implementation PushMaster

+ (void)sendLocationRequestPushToUser:(Friend *)f completion:(void (^)(BOOL sent, NSError *error))completion {
    /*
     Query for the user's device token.
     */
    NSString *uid = [NSString stringWithFormat:@"facebook:%@", f.fbid];
    [[[[[[API sharedAPI] firebase] childByAppendingPath:@"users"] childByAppendingPath:uid] childByAppendingPath:@"push_token"] observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        if (!snapshot.exists) {
            // Fail gracefully. This user has no push token.
            completion(false, nil);
        } else {
            // Attempt to send the push.
            NSString *token = [snapshot value];
            NSString *message = [NSString stringWithFormat:@"%@: where you @?", [[API sharedAPI].this_user name]];
            NSDictionary *payload = @{@"request" : @"location", @"from" : [[API sharedAPI].this_user fbid], @"message" :@{@"title" : [[API sharedAPI].this_user name], @"body" : @"where you @?"}, @"category" : @"REQUEST_LOCATION_CATEGORY", @"sound" : @"default"};
            
            
            NSDictionary *params = @{@"name" : [[API sharedAPI] this_user].name, @"fbid" : [[API sharedAPI] this_user].fbid, @"target" : token};
            
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://flawkpush.appspot.com/whereAtRequest"]];
            [request setHTTPMethod:@"POST"];
            [request setHTTPBody:[NSJSONSerialization dataWithJSONObject:params options:nil error:nil]];
            [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
            
            [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                NSString *htmlresponse = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                if (!error)
               {
                   NSLog(@"Sent push! %@", htmlresponse);
               } else {
                   NSLog(@"Failed to send push! %@", htmlresponse);
               }
            }] resume];
            
        }
    }];
}




+ (void)sendAcknowledgePushToUser:(Friend *)f completion:(void (^)(BOOL sent, NSError *error))completion {
    /*
     Query for the user's device token.
     */
    NSString *uid = [NSString stringWithFormat:@"facebook:%@", f.fbid];
    [[[[[[API sharedAPI] firebase] childByAppendingPath:@"users"] childByAppendingPath:uid] childByAppendingPath:@"push_token"] observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        if (!snapshot.exists) {
            // Fail gracefully. This user has no push token.
            if (completion != nil) {
                completion(false, nil);
            }
        } else {
            // Attempt to send the push.
            NSString *token = [snapshot value];
            NSDictionary *params = @{@"name" : [[API sharedAPI] this_user].name, @"fbid" : [[API sharedAPI] this_user].fbid, @"target" : token};
            
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://flawkpush.appspot.com/acknowledge"]];
            [request setHTTPMethod:@"POST"];
            [request setHTTPBody:[NSJSONSerialization dataWithJSONObject:params options:nil error:nil]];
            [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
            
            [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                NSString *htmlresponse = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                if (!error)
                {
                    NSLog(@"Sent push! %@", htmlresponse);
                } else {
                    NSLog(@"Failed to send push! %@", htmlresponse);
                }
                if (completion) {
                    completion(error == nil, error);
                }
            }] resume];
            
        }
    }];
}



+ (void)sendFriendRequestPushToUser:(Friend *)f completion:(void (^)(BOOL sent, NSError *error))completion {
    /*
     Query for the user's device token.
     */
    NSString *uid = [NSString stringWithFormat:@"facebook:%@", f.fbid];
    [[[[[[API sharedAPI] firebase] childByAppendingPath:@"users"] childByAppendingPath:uid] childByAppendingPath:@"push_token"] observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        if (!snapshot.exists) {
            // Fail gracefully. This user has no push token.
            completion(false, nil);
        } else {
            // Attempt to send the push.
            NSString *token = [snapshot value];
            NSDictionary *params = @{@"name" : [[API sharedAPI] this_user].name, @"fbid" : [[API sharedAPI] this_user].fbid, @"target" : token};
            
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://flawkpush.appspot.com/fr_request"]];
            [request setHTTPMethod:@"POST"];
            [request setHTTPBody:[NSJSONSerialization dataWithJSONObject:params options:nil error:nil]];
            [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
            
            [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                NSString *htmlresponse = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                if (!error)
                {
                    NSLog(@"Sent push! %@", htmlresponse);
                } else {
                    NSLog(@"Failed to send push! %@", htmlresponse);
                }
            }] resume];
            
        }
    }];
}




+ (void)sendAcceptedFriendRequestPushToUser:(Friend *)f completion:(void (^)(BOOL sent, NSError *error))completion {
    /*
     Query for the user's device token.
     */
    NSString *uid = [NSString stringWithFormat:@"facebook:%@", [f fbid]];
    [[[[[[API sharedAPI] firebase] childByAppendingPath:@"users"] childByAppendingPath:uid] childByAppendingPath:@"push_token"] observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        if (!snapshot.exists) {
            // Fail gracefully. This user has no push token.
            completion(false, nil);
        } else {
            // Attempt to send the push.
            NSString *token = [snapshot value];
            NSDictionary *params = @{@"name" : [[API sharedAPI] this_user].name, @"fbid" : [[API sharedAPI] this_user].fbid, @"target" : token};
            
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://flawkpush.appspot.com/accept_request"]];
            [request setHTTPMethod:@"POST"];
            [request setHTTPBody:[NSJSONSerialization dataWithJSONObject:params options:nil error:nil]];
            [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
            
            [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                NSString *htmlresponse = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                if (!error)
                {
                    NSLog(@"Sent push! %@", htmlresponse);
                } else {
                    NSLog(@"Failed to send push! %@", htmlresponse);
                }
            }] resume];
            
        }
    }];
}








/* 
         {
         "group_id": "welcome",
         "push_time": "2015-06-01T14:00:00",
         "recipients" : {
         "tokens" : ["USER_PUSH_TOKEN"],
         "custom_ids" : ["CUSTOM_USER_ID"]
         },
         "message": {
         "title": "Hello!",
         "body": "How's it going?"
         },
         "custom_payload": "{\"tag\":\"wake up push\", \"landing_screen\":\"greeting\"}"
         }
 */



+ (void)sendPushWithCustomPayload:(NSDictionary *)payload toUsersWithTokens:(NSArray *)tokens pushType:(NSString *)type completion:(void (^)(BOOL success, NSError *error))completion {
    
    NSMutableDictionary *realPayload = [NSMutableDictionary dictionary];
    
    // add in the base payload stuff
    [realPayload setObject:type forKey:@"group_id"];
    [realPayload setObject:@"now" forKey:@"push_time"];
    [realPayload setObject:@{@"tokens" : tokens} forKey:@"recipients"];
    
    if ([payload objectForKey:@"message"] != nil) {
        [realPayload setObject:payload[@"message"] forKey:@"message"];
    }
    
    // add in the existing / custom payload keys
    /*for (NSString *key in payload) {
        [realPayload setObject:payload[key] forKey:key];
    }*/
    [realPayload setObject:[[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:payload options:0 error:nil] encoding:NSUTF8StringEncoding] forKey:@"custom_payload"];
    
    [PushMaster sendPushWithPayload:realPayload completion:completion];
}



+ (void)sendPushWithPayload:(NSDictionary *)payload completion:(void (^)(BOOL success, NSError *error))completion {
    NSError *error;
    
    NSString *batchAPIKey = @"DEV56DCC99EA675ECD595B1AC57E43";
    NSString *batchRESTkey = @"b6e1d79b98184b2a0bc011f2f55c7398";
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.batch.com/1.0/%@/transactional/send", batchAPIKey]]];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:batchRESTkey forHTTPHeaderField:@"X-Authorization"];
    [request setHTTPMethod:@"POST"];
    
    NSData *jsonBody = [NSJSONSerialization dataWithJSONObject:payload options:0 error:&error];
    NSString *jsonBodyString = [[NSString alloc] initWithData:jsonBody encoding:NSUTF8StringEncoding];
    
    [request setHTTPBody:jsonBody];
    
    if (error != nil) {
        completion(false, error);
    }
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
       if (error == nil) {
            NSString *results = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            completion(true, nil);
        } else {
            completion(false, error);
        }
    }] resume];
}


+ (void)sendMessageToUser:(Friend *)f message:(NSString *)message {
    
    
}

@end
