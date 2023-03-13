# LaunchBar Action to search/list Swift Evolution Proposals

Inspired by https://oleb.net/blog/2023/alfred-swift-evolution/ this is a copy
of the Alfred workflow https://github.com/attaswift/alfred-swift-evolution/,
slighlty adjusted for LaunchBar.

![LaunchBar-Action](https://user-images.githubusercontent.com/746/224668059-a9c924cf-5908-466f-a646-5f0752019edd.png)

## Testing

To try the script manually (in `~/Library/Application
Support/LaunchBar/Actions/SwiftEvolutionProposals.lbaction`):

Run:

```
swift Contents/Scripts/default.swift collection
```

Where `collection` is an argument for the script. 
This is the argument passed to the script when a search query is entered into LaunchBar.
