# FlashReloader
A work-in-progress scaleform UI reloader proxy for reducing the need to restart the workshop tools for every UI update.

## Instructions
Install the FlashReloader.swf in your addon's resource/flash3 directory.
Rename your old custom_ui.txt to be "reloader.txt".  FlashReloader will use this file to determine which UI files to proxy on reload.
Use the custom_ui.txt provided for you in this repo in place of your old one(it contains only a reference to this swf.)

When you launch the workshop tools, you should see your UI as normal with only a single "UPDATE+RESTART" button added to the bottom right of the screen.  If you require the restart.lua provided (or simply copy in the command registration) inside your game mode vscript code, then clicking this button will unload all UI files handled by FlashReloader.swf and then restart the game 2.5 seconds later.  Issuing a "restart" to the console may also work, though it's possible for the game to reload quicker than it garbage collects the old UI.

When you want to release your game mode, you can rename your "reloader.txt" to be "custom_ui.txt" once more, and the game should load everything the same (but without the reloader proxy).

## Coding Instructions
It is still very possible to get your UI files to be "stuck" and uncollected by dota during a restart if your code does not manually unload things like Timers and external gameAPI override references.  In your UI file, you can create an "onUnloaded" function which will be called by Dota or the reloader proxy when the game is restarting.  Make sure that you stop any running timers, adn remove event liteners that have been added to objects which are not attached to/present in your UI file.  If a reference to some object or function in your UI file is not cleaned up by the time the game restarts, your UI file class won't be collected and will get "stuck" on future game restarts, and will likely require a complete restart of the tools to remedy.

## Please Note!
This code is still unproven, and I've found many cases where a file seems to get "stuck" and uncollectable for no discernable reason.  If you notice anything and report it, I may be able to find out why and fix it.