# DiscordClient
*Newer version of https://github.com/0zBug/Daylight/*

# Documentation
## client.lua
### Start
**Start a connection between your bot and discord.**
```html
<void> Client:Start(<string> Token)
```
### Close
**Closes the connection between your bot and discord.**
``` html
<void> Client:Close(<void)
```
### Connect
**Connects the the specified event**
```html
<void> Client:Connect(<string> Event, <function> Callback)
```
## handler.lua
### AddCommand
**Adds a command to your bot**
```html
<void> Client:AddCommand(<string> Name, <string> Description, <function> Callback)
```
