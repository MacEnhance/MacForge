### 0.21.1

-   UI redesign
-   Major code clean / Organization
-   macforge:// links now just use the bundleID
-   MacForge can now host a UI for plugin settings [@jslegendre](https://github.com/jslegendre)
-   Improvements made to injector
-   Removed option for multiple sources
-   Removed search bar from discover view
-   Removed navigation bar from discover view
-   Updated Xcode Plugin template
-   Updated Demo Plugin
-   Updated information regarding AMFI
-   Updated SIP notification window

### 0.14.2

-   Helper changed to using XPC connection for injection [@jslegendre](https://github.com/jslegendre)
-   Fix helper hanging if SIP is enabled
-   Removed reddit sidebar button
-   Feedback button moved to about

### 0.14.1

-    Fixed Helper freezing if injection failed
-    Fixed Helper crashing if injector not installed
-    Fixed Helper failing to launch
-    Changelogs now use markdown format
-    Discover view can be navigated with arrow keys
-    Accounts tab is back but partly non-functional

### 0.13.3

-    Randomize featured view order
-    Fix bundle page not registering Applications as installed
-    Bug fixes

### 0.13.2

-    Custom icons now load in discover view
-    Option to hide Helper Application menubar item
-    Updates to System tab information
-    Improved SIP detection
-    Fix Helper crash on failed inject
-    Revert Helper async injection
-    Bug fixes

### 0.13.1

-    New Application and Menubar icon
-    Description and Previews are now hidden in bundle view if they don't exist
-    Bundle view description resized to fit content
-    Gif will play on bundle view
-    Option to use ⌘0 - 7 to select tabs
-    Fixed macforge:// not always loading the package
-    Helper injects asynchronously
-    Bug fixes

### 0.12.4

-    Added support for trials
-    Can now cut/copy/paste text
-    Fix preview images displaying out of order
-    Stop bundle downgrades showing as updates
-    Bug fixes 

### 0.12.3

-    Min macOS version bumped to 1### 0.12
-    Application is now notarized
-    More fixes for macforge:// not showing package if app was launched by url in some cases
-    Share button now copies https:// link to bundle
-    Fix crash when double clicking update
-    Fix not adding Xcode template
-    Fix text on macOS below 1### 0.14 in dark mode
-    Fix helper not respecting automatic plugin update preferences
-    Fix helper only checking for plugin updates once
-    Fix helper not checking for MacForge updates
-    Bug fixes

### 0.12.2

-    Custom icons now show in bundle view
-    Added short transition for showing image previews
-    Fix installing bundles by opening them with MacForge
-    Purchases will now work on all user accounts for a machine
-    Bug fixes

### 0.12.1

-    Support for macforge:// url scheme
-    Search field in tab bar now searches discover tab
-    MacForge now properly checks for installed applications
-    MacForge can now directly launch installed applications
-    Adjustments to Featured tab
-    Fix image scaling on bundle pages
-    Added the ability to click image previews to show a larger view
-    Share button now copies macforge:// url for the bundle to clipboard
-    Bug fixes

### 0.11.3

-    Fix major delay in loading featured view and discover view
-    Removed some duplicate/unused code

### 0.11.2

-    Fix purchaseValidationApp only running on 1### 0.15
-    Fix Featured view height
-    Bug fixes

### 0.11.1

-    Fix helper asking to uninstall if duplicate copy of MacForge was in trash
-    Download from discover view without entering bundle view
-    Lots of user interface adjustments
-    Source management is moving to Preferences tab
-    Account tab allows for account creation
-    3rd parties can now sell plugins

### 0.10.3

-    Featured page improvements
-    Fix error pop-up
-    Fix codesign issue
-    Bug fixes

### 0.10.2

-    Fix install error if .zip contained __MACOS folder
-    Updated preferences tab UI
-    Bug fixes

### 0.10.1

-    Minimum macOS version bumped to 1### 0.11
-    UI design adjustments
-    Download progress for featured items
-    Bug fixes


### 0.9.11

-    Bug fixes


### 0.9.10

-    Fix some typos
-    Use SDWebImage for loading images from repos
-    Bug fixes


### 0.9.9

-    Fix Helper app crash

### 0.9.8

-    Bug fixes

### 0.9.7

-    Fix crash on system tab if an item in the list was removed form the system
-    Bug fixes

### 0.9.5

-    Mostly functional implementation of featured tab
-    Slightly faster start-up time
-    Bug fixes

### 0.9.4

-    Support for installing .app and .theme packages
-    Support for installing zip with multiple contents
-    Discover view shows package type (app, plugin, theme)
-    Misc changes

### 0.9.3

-    Featured tab early implementation (UI testing only)


### 0.9.2

-    Catalina support
-    Better handle loading of images from the web
-    Switch back to sparkle for updates 
-    Updated Paddle framework
-    Ability to purchase plugins
-    Preview images for plugins
-    Drag and Drop for adding to application blacklist

### 0.8.0

-    Renamed application to MacForge
-    New Icon
-    Mojave support
-    Now installs plugins to /Library/Application Support/MacEnhance/Plugins
-    Switch from SIMBL to  mach_inject
      -    Allows loading on Mojave (macOS 1### 0.14)
      -    Doesn't require SIP to be off to install helpers
      -    Requires SIP to be off to load into applications
      -    You can use "csrutil enable --without debug --without fs"
      -    New System Integrity Protection warning 
      -    Removed system component warnings
-    SIMBLAgent (injector) is now the MacForgeHelper
      -    Helper is now in charge of injection
      -    Helper automatically tries to load new bundles when main app is closed
      -    Helper checks for bundle updates in background    
      -    Helper can automatically keep bundles up to date
      -    Plugins won't automatically load if MacForgeHelper isn't open
      -    Can be run via command line
      -    ./MacForgeHelper -i BUNDLE_ID ---- injects into specific app
      -    ./MacForgeHelper -u ---- updates all plugins
      -    MacForgeHelper is a menubar application
-    UI redesign
      -    Redesigned to resemble Mojave App Store
      -    Larger sidebar buttons
      -    Larger window size
      -    Window is now resize-able
      -    Window uses system light / dark mode
      -    Switch from colored circles to check boxes for toggles
      -    Mojave Dark mode support
-    Manage view
      -    Implemented search (name or bundle ID)
-    Discover view 
      -    Improved search (name or bundle ID)
-    System view
      -    Removed SIMBL info
      -    Added MacForge info
      -    Revised Blacklist view
-    About view
      -    Shifted view to left
      -    Added button to quickly start building a plugin in Xcode 
-    Added DockTilePlugin to show bundle updates in dock when app is closed
-    Included plugin with fixes for a few issues caused when plugins are loaded into Archive Utility and TextEdit
-    Automatically add Xcode template for making plugins
-    Fix some array out of bounds issues
-    Fix errors caused if plugin was in two locations
-    Fix launch at login bugs
-    Faster startup
-    Bug fixes

### 0.7.2

-    Fix Mojave lag

### 0.7.1

-    Fix plugins not downloading from changes tab
-    Updates to System Info tab

### 0.7.0

-    Window now stays vibrant in background
-    Updating disabled plugins now properly updates the disabled plugin instead of installing the update in /Library/Application Support/SIMBL/Plugins/
-    Updated mySIMBLFramework
-    Added mySIMBL to default SIMBLBlacklist (for safety)
-    Code clean
-    UI Adjustments
-    Bug fixes
-    Redesigned sidebar
      -    Smaller buttons
      -    Icons for each button
      -    Buttons with views are moved to top
-    Redesigned Manage view
      -    Manage view is now searchable
      -    Reveal in Finder is now an eye icon
      -    Trash now trashes in one click
      -    Toggle between single and all users with person icon
      -    Toggle between enabled and disabled with green/red circle icon
      -    Add or Remove source view is now a child of main window
-    Redesigned Discover view 
      -    Discover view now has subview  "Sources" view and "All Plugins" view
      -    All Plugins is a combined list of all plugins from all repos
      -    All Plugins is searchable
-    Bundle pages improved
      -    Fix some title sizing issues
      -    Extended description box to fill length of view
      -    Fix Donate and Contact buttons being switched
      -    Fix buttons getting stuck in on or off state
-    Redesigned SIMBL tab 
      -    Renamed tab to System Info
      -    Removed allow load in Xcode/Safari
      -    Now has Apple Mobile File Integrity status
      -    Now has toggle for Apple Mobile File Integrity
      -    Both 'Apple Mobile File Integrity' and 'System Integrity Protection' must be disabled to allow loading into some apps like:
      -    iTunes
      -    Xcode
      -    Safari
-    Better icon loading for plugins
      -    Icons will use plugin image instead of Stock app icon if target app has no icon
      -    More custom icons for stock apps without icons

### 0.5.3

-    Fixed issues with Xcode and Safari Tech Preview toggles
-    UI Adjustments
-    Bug fixes

### 0.5.1

-    Improved inject into all applications method
-    Improved locating of applications for SIMBL Blacklist
-    Improved launch time
-    Fix SIMBLAgent update/install failing when SIP is enabled
-    Fix System Integrity Protection status now displays properly
-    New default repo
-    New toggles allowing injection into Xcode and Safari Tech Preview
-    New button to uninstall SIMBL
-    DevMate integration
-    Bug fixes    

### 0.4.3

-    Fixes 1### 0.9 not setting up window
-    Fixes SIMBLAgent not automatically loading plugins

### 0.4.2

-    Fixes mySIMBLAgent crash

### 0.4.1

-    New  Updates tab
      -    Update all plugins
      -    Update individual plugins
      -    New repo packages.plist format
-    New SIMBL tab
      -    Show SIMBL status
      -    Show SIMBLAgent status
      -    Show System Integrity Protection status
      -    SIMBL Blacklist
      -    SIMBL Logging options have moved here
      -    Load into all applications has moved here
-    Sources tab
      -    Show checkmark for downloaded plugins (enabled and disabled)
      -    Improved bundle page information
-    Sparkle 1.15.1
-    PFMoveApplication updated
-    UI Changes
-    Improve system app injection time
-    Improve injection method
-    Improve login item method
-    Fix bundle info not updating if a new version was installed
-    Fix window stuck floating after SIMBL update message
-    Fix SIMBL update window not showing the parent app
-    Fix warning logging
-    Bug fixes

### 0.3.1

-    Fix SIMBLAgent crashing on 1### 0.11 and below
-    Fix sources view navigation not working properly on 1### 0.9
-    Fix missing sdef file in osax
-    Bug fixes

### 0.3.0

-    macOS 1### 0.12 support
-    SIMBL Agent updated
      -    SIMBL Agent moved to /Library/Application Support/SIMBL
      -    Injects into root applications (Dock, Finder, Spotlight, etc)
      -    Injects into apps that loaded before itself
-    Warning dialog for SIMBL updates
-    Warning dialog for System Integrity Protection
-    SIMBL updates handled by main app instead of helper
-    UI Changes
-    Removed WAYAppStoreWindow
-    Fixed not being able to toggle plugin if folder didn't exist
-    Fix admin script not running on 1### 0.12
-    Bug fixes

### 0.2.6

-    New Icon
-    Much faster directory updates
-    Scan for Parasite bundles
-    Better version checking bundle updates
-    Altered tabs
-    Code sign fix
-    Bug fixes

### 0.2.5

-    New Icon
-    Better repo refreshing
-    UI Adjustments
-    Updated PFMoveApplication
-    Updated INAppStoreWindow
-    Updated Sparkle

### 0.2.1

-    Add / Remove sources
-    Better plugin pages
-    Repo sorted by package name

### 0.2.0

-    Sources view implemented 
      -    One repo included
      -    Basic repo implementation
      -    Structure
      -    Source View (Root)
      -    Source Bundles
      -    Bundle Page
-    UI adjustments
-    Code refactoring
-    Startup tab preference
-    Bundles use icon of first application in SIMBLTargetApplications if no icon provided
-    View source button in about page
-    Cells selectable in tables

### 0.1.6

-    UI adjustments

### 0.1.5

-    UI adjustments
-    Changed fonts
-    Almost all preferences working
-    Updated about page

### 0.1.4

-    UI adjustments
-    Inject into apps button
-    Preferences mostly complete
-    Delete bundle requires two clicks

### 0.1.3

-    UI Adjustments
-    Automatic updates via sparkle
-    Delete bundle (Trash can)

### 0.1.2

-    Helper agent
-    System Integrity Protection warning
-    Inject into specified system apps
-    Offers to move self to /Applications
-    Show bundle in Finder (Magnifying Glass)
-    Bundles will display custom icon if located in <bundle>/Contents/icon.icns
-    Easy bundle installation
      -    Drag and drop install bundles in /Library/Application Support/SIMBL/Plugins
      -    Open bundles with app to install in /Library/Application Support/SIMBL/Plugins
-    Show bundle developer page (Globe Icon)
      -    plist value is string 'DevURL'
-    Toggle bundles between (Colored Circle Icon)
      -    /Library/Application Support/SIMBL/Plugins
      -    /Library/Application Support/SIMBL/Plugins (Disabled)
      -    ~/Library/Application Support/SIMBL/Plugins (User only)
-    Watch for changes to
      -    /Library/Application Support/SIMBL/Plugins
      -    /Library/Application Support/SIMBL/Plugins (Disabled)
      -    ~/Library/Application Support/SIMBL/Plugins
