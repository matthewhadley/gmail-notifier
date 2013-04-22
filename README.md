# gmail-notifier

Get OSX message center notifications for new unread emails.

![notification](https://raw.github.com/wiki/diffsky/gmail-notifier/notification.jpg)

# Installation

- clone the repo somewhere then copy the `gmail-notifier` directory into your `/Applications` directory (or create a symlink to the cloned repo).
- make sure you have a keychain entry with your gmail details, where the account value is your gmail address
- by default checks for new emails happen every 10seconds, edit the `gmail-notifier/gmail-notifier.plist` file if you wish to change that interval
- configure gmail-notifier run at login with this command `launchctl load /Applications/gmail-notifier/gmail-notifier.plist`

You should now start getting notifications.

To deactivate run `launchctl unload /Applications/gmail-notifier/gmail-notifier.plist`

# Credits

The functionality for displaying the notifications is all from [terminal-notifier](https://github.com/alloy/terminal-notifier).
A bundled version of that app is provided so that the icon can be modified to [look more like gmail](http://www.iconarchive.com/show/handycons-2-icons-by-jankoatwarpspeed/gmail-icon.html). This is due to a [restriction in notification center](https://github.com/alloy/terminal-notifier/issues/31#issuecomment-9169599) that means it only shows app's icon. So there is a [forked version of terminal-notifier with this changed icon](https://github.com/diffsky/terminal-notifier/tree/gmail-notifier).