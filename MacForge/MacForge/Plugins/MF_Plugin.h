//
//  MF_Plugin.h
//  MacForge
//
//  Created by Wolfgang Baird on 6/22/17.
//  Copyright © 2017 Wolfgang Baird. All rights reserved.
//

@import Paddle;
#import <Foundation/Foundation.h>

@interface MF_Plugin : NSObject <PADProductDelegate>

// Local or Repo
@property NSString      *bundleID;              // Must be unique
@property NSString      *bundleImage;           // Image to use for plugin

// Repo Files
@property NSDictionary  *webPlist;              // Copy of the plist info
@property NSDictionary  *webPaddle;             // Paddle information
@property NSString      *webDeveloperDonate;    // Donation url
@property NSString      *webDeveloperEmail;     // Contact email
@property NSString      *webRepository;         // Plugin repo                  -- Delete me
@property NSString      *webName;               // Name of the plugin
@property NSString      *webDescription;        // A longer description
@property NSString      *webDescriptionShort;   // A short description
@property NSString      *webTarget;             // Target applications
@property NSString      *webPublishDate;        // Publish date
@property NSString      *webVersion;            // Version
@property NSString      *webPrice;              // Price
@property NSString      *webDeveloper;          // Developer
@property NSString      *webCompatability;      // macOS version compatability
@property NSString      *webFileName;           // Download URL
@property NSString      *webSize;               // Size of plugin
@property Boolean       webFeatured;            // Plugin is featured
@property Boolean       webPaid;                // Plugin is paid
@property Boolean       webARM;                 // Plugin supports arm64/arm64e

// Paddle
@property NSString      *paddleEmail;
@property NSString      *paddleLicense;
@property PADProduct    *paddleProduct;

// Info
@property Boolean           checkedPurchase;
@property Boolean           hasPurchased;
@property NSImage           *featuredImage;
@property NSMutableArray    *previewImages;

// Local Files
@property NSDictionary  *localPlist;
@property NSString      *localName;
@property NSString      *localVersion;
@property NSString      *localDescription;
@property NSString      *localPath;
@property NSString      *localSize;
@property Boolean       needsUpdate;
@property Boolean       isInstalled;
@property Boolean       isEnabled;
@property Boolean       isUser;

@end
