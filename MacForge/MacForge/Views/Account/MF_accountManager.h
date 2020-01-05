//
//  MF_accountManager.h
//  MacForge
//
//  Created by Wolfgang Baird on 12/25/19.
//  Copyright © 2019 MacEnhance. All rights reserved.
//

#import <Foundation/Foundation.h>

@import FirebaseAuth;

NS_ASSUME_NONNULL_BEGIN

@interface MF_accountManager : NSObject

- (void)createAccountWithUsername:(NSString *)username
                            email:(NSString *)email
                         password:(NSString *)password
                      andPhotoURL:(NSURL *)photoURL
            withCompletionHandler:(void (^)(FIRAuthDataResult * _Nullable authResult, NSError * _Nullable err))handler;

- (void)loginAccountWithEmail:(NSString *)email
                  andPassword:(NSString *)password
        withCompletionHandler:(void (^)(FIRAuthDataResult * _Nullable authResult, NSError * _Nullable err))handler;

- (void)updateAccountWithUsername:(NSString *)username
                      andPhotoURL:(NSURL *)photoURL
            withCompletionHandler:(void (^)(FIRAuthDataResult * _Nullable authResult, NSError * _Nullable err))handler;

@end

NS_ASSUME_NONNULL_END
