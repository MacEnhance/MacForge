<!--![Banner](web/banner.png)-->

MacForge is an open-source plugin manager for macOS. It lets you discover, install and manage plugins to improve the user experience of macOS without the need for manually cloning/building or copying files.

[![Chat](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/MacEnhance/MacForge)

![Preview](web/preview.png)

## Installation

- Download the ~~[latest release](https://github.com/w0lfschild/app_updates/raw/master/MacForge/MacForge_master.zip) not yet available~~
- Unzip the download if your browser does not do so automatically
- Open MacForge
- MacForge will ask to be moved to /Applications
- MacForge may ask to install or update helper tools
- Disable System Integrity Protection
- Start installing and using plugins

## Functionallity notes

- Loading plugins into system applications requires that [System Integrity Protection](https://apple.stackexchange.com/questions/208478/how-do-i-disable-system-integrity-protection-sip-aka-rootless-on-os-x-10-11) is disabled
- Loading plugins into some applications may require [Apple Mobile File Integrity](https://www.theiphonewiki.com/wiki/AppleMobileFileIntegrity) to be disabled
- Loading plugins into some applications may require the plugin must be *signed* and in the `/Library` directory

## Requirements

- MacForge supports macOS 10.10 and above
- Plugins distributed through MacForge may have different application and system requirements

## Features

- Install plugins simply
- Drag and drop plugins onto MacForge to automatically install them
- MacForge can open files with the `.bundle` extension to automatically install them


- Featured
- browse a few hand picked quality plugins


- Manage
- Delete plugins (Trash can)
- Show plugins in Finder (Eye icon)
- Enable/Disable plugins (Check box)
- Toggle plugins between single user and all users (User icon)
- Search for plugins (by name or ID)
- MacForge automatically detect existing plugins located in 


- Discover
- Browse existing plugins
- Search though all existing plugins (by name, bundle ID)
- See what each reposityory has to offer
- Add or remove reposityories
- It's easy to host your own repository on GitHub!
- Discover, download and update plugins


- Changes (coming soon)
- See new and recently updated tweaks


- Updates
- Check what installed plugins have updates
- Quickly update all plugins


- System Info
- Show some basic information about the installation
- Blacklist applications from loading plugins


- Preferences
- Option to automatically keep plugins up to date
- Miscillaneous settings


- And much more...

## Creating a plugin

- Download and install `MacForge`
- Open `MacForge`
- Open `Xcode` and navigate `File` > `New` > `Project...`
- Search for `MacForge Plugin`
- Select it and press `Next`
- Enter a  `Product Name` and target bundle id e.g. `com.apple.loginwindow` and press `Next`
- Select a location for your project and press `Create`
- Add your code
- You can find header dumps of most Apple Applications [HERE](https://github.com/w0lfschild/macOS_headers)
- Build your code
- Open your plugin with `MacForge`

## Submitting a plugin

- Head over to the [MacForge plugin repository](https://github.com/w0lfschild/macplugins)
- [Fork](https://github.com/w0lfschild/macplugins/fork) the project
- Add your compiled and zipped plugin to the bundles folder
- Edit packages_v2.plist to include your submission
- Submit a [pull request](https://github.com/w0lfschild/macplugins/compare)

## Troubleshooting

- Having problems? Submit an issue here: [submit](https://github.com/w0lfschild/MacForge/issues/new)

## Uninstalling

- Trashing `MacForge` will stop it from loading into applications 
- ~~If you want a mostly full clean select `Preferences` from the sidebar, then click `Uninstall MacForge`. Log out and back in for changes to fully apply.~~

## Developement

- [Wolfgang Baird](https://github.com/w0lfschild) ([@w0lfschild](https://github.com/w0lfschild)) ([MacEnhance](https://www.macenhance.com/))
