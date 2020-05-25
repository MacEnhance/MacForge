<!--![Banner](web/banner.png)-->

## MacForge 🧩

MacForge is an open-source plugin manager for macOS. It lets you discover, install and manage plugins to improve the user experience of macOS without the need for manually cloning/building or copying files.

[![Discord](https://discordapp.com/api/guilds/608740492561219617/widget.png?style=banner2)](https://discordapp.com/channels/608740492561219617/608740492640911378)

## [Installation](https://github.com/w0lfschild/MacForge/wiki/Installation) 📂

- Download the [latest release](https://github.com/w0lfschild/app_updates/raw/master/MacForge/MacForge.zip)
- Unzip the download if your browser does not do so automatically
- Open MacForge and allow it to install helper tools
- Disable [System Integrity Protection](https://www.imore.com/how-turn-system-integrity-protection-macos)
- Disable *Library Validation* if needed `sudo defaults write /Library/Preferences/com.apple.security.libraryvalidation.plist DisableLibraryValidation -bool true`
- Start installing and using plugins

## Functionallity notes 📝

- Loading plugins into system applications requires that [System Integrity Protection](https://apple.stackexchange.com/questions/208478/how-do-i-disable-system-integrity-protection-sip-aka-rootless-on-os-x-10-11) is disabled
- Loading plugins into some applications may require *Library Validation* is disabled  `sudo defaults write /Library/Preferences/com.apple.security.libraryvalidation.plist DisableLibraryValidation -bool true`
- Loading plugins into some applications may require the plugin must be *signed* and in the `/Library` directory
- Some applications installed by MacForge may not require *System Integrity Protection* or *Library Validation* to be disabled to function

## System Requirements 🖥

- MacForge supports macOS 10.13 and above
- For macOS 10.12 and below check out [mySIMBL](https://github.com/w0lfschild/mySIMBL)
- Bundles distributed through MacForge may have different application and system requirements

## [Wiki](https://github.com/w0lfschild/MacForge/wiki/Home) 📑

## [Features](https://github.com/w0lfschild/MacForge/wiki/Features) 💪

- Discover what's new 🔍
    - Browse an extensive and growing collection of Plugins, Application and Themes!
    - Search for plugins (Name, Developer, ID)
    - See new and recently updated tweaks
    - Browse existing bundles
    - Search through all existing bundles (by name, bundle ID)
    - See what each repository has to offer
    - Add or remove repositories
    - It's easy to host your own repository on GitHub!
    - Discover, download and update bundles
    
- Manage bundles 📦
    - Drag and drop plugins `.bundle` onto MacForge to automatically install them
    - MacForge can open files with the `.bundle` extension to automatically install them
    - Blacklist applications from loading plugins
    - Quickly and easily manage plugins
    - Delete plugins
    - Show plugins in Finder
    - Enable/Disable plugins
    - Toggle plugins between single user and all users (User icon)

- Stay up to date 📲
    - Check what installed bundles have updates
    - Quickly update all bundles
    - Have MacForge automatically update bundles
    - Recieve notifications when MacForge detects updates

## [Developer 👨‍💻](https://github.com/w0lfschild/MacForge/wiki/Bundles-:-Creating)

- [Contributing Code 🤝](https://github.com/w0lfschild/MacForge/blob/master/CONTRIBUTING.md)
- [Help wanted 💵](https://github.com/w0lfschild/MacForge/issues/16)
- [Submitting Issues 🐞](https://github.com/w0lfschild/MacForge/issues/new/choose)
- [Creating a bundle 🏗](https://github.com/w0lfschild/MacForge/wiki/Bundles-:-Creating)
- [Publishing a bundle 🛳](https://github.com/w0lfschild/MacForge/wiki/Bundles-:-Publishing)
- [Sharing a bundle 🔗](https://github.com/w0lfschild/MacForge/wiki/Bundles-:-Linking)
- [Selling a bundle 💰](https://github.com/w0lfschild/MacForge/wiki/Bundles-:-Selling)

## Troubleshooting 🐛

- Having problems? Submit an issue here: [submit](https://github.com/w0lfschild/MacForge/issues/new/choose)

## [Uninstalling](https://github.com/w0lfschild/MacForge/wiki/Uninstallation) ❌

- Trashing `MacForge` will stop it from loading into applications 

## Developement ❤️

- [Wolfgang Baird](https://github.com/w0lfschild) ([@w0lfschild](https://github.com/w0lfschild)) ([MacEnhance](https://www.macenhance.com/))
