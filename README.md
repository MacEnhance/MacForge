![Banner](web/banner.png)

MacPlus is an open-source plugin manager for macOS. It lets you discover, install and manage plugins to improve the user experience of macOS without the need for manually cloning/building or copying files.

[![Chat](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/MacPlus/Lobby)

![Preview](web/preview.png)

## Installation

- Download the [latest release](https://github.com/w0lfschild/app_updates/raw/master/MacPlus/MacPlus_master.zip)
- Unzip the download if your browser does not do so automatically
- Open MacPlus
- MacPlus will ask to be moved to /Applications
- MacPlus may ask to install or update helper tools
- In order for plugins to load into system applications you may be required to [disable System Integrity Protection](https://apple.stackexchange.com/questions/208478/how-do-i-disable-system-integrity-protection-sip-aka-rootless-on-os-x-10-11), MacPlus will inform you but cannot automate this process
- Start installing and using plugins

## Requirements

- MacPlus supports macOS 10.10 and above
- plugins distributed through may have different application and system requirements

## Features

- Discover
    - Find, download and update plugins
    - Search for plugins (by name or ID)
    - Easy to host your own repository
    - Add or remove repositories


- Manage
    - Delete plugins (Trash can)
    - Show plugins in Finder (Eye icon)
    - Enable/Disable plugins (Check box)
    - Toggle plugins between single user and all users (User icon)
    - Search for plugins (by name or ID)
    - MacPlus automatically detect existing plugins located in 


- Install plugins simply
    - Drag and drop plugins onto MacPlus to automatically install them
    - MacPlus can open files with the `.bundle` extension to automatically install them


- Stay up to date
    - Show plugin updates in the updates tab
    - Option to automatically keep plugins up to date
    - Updates are shown as a badge on the MacUpdate icon


- Stay safe
    - Blacklist applications to avoid issues

- And much more...

## Creating a plugin

-

## Submitting a plugin

- Head over to the [MacPlus plugin repository](https://github.com/w0lfschild/macplugins)
- [Fork](https://github.com/w0lfschild/macplugins/fork) the project
- Add your compiled and zipped plugin to the bundles folder
- Edit packages_v2.plist to include your submission
- Submit a [pull request](https://github.com/w0lfschild/macplugins/compare)

## Troubleshooting

- Having problems? Submit an issue here: [submit](https://github.com/w0lfschild/MacPlus/issues/new)

## Uninstalling

- Trashing `MacPlus` will stop it from loading into applications 
- If you want a full clean select `Preferences` from the sidebar, then click `unistall MacPlus`. Log out and back in for changes to fully apply.

## Developement

- [Wolfgang Baird](https://github.com/w0lfschild) ([@w0lfschild](https://github.com/w0lfschild))
