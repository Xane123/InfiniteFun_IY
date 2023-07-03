# Infinite Fun (an Infinite Yield mod for Royale High)
The best command line script for Roblox, now with additional commands for Royale High exploiters! (This does **not** add any commands that would allow duplication of "exploited halos".)

To use Infinite Fun, execute this LoadString:
```
loadstring(game:HttpGet('https://raw.githubusercontent.com/Xane123/InfiniteFun_IY/master/source'))()
```

# Differences
* ESP
  * The ESP overlays overall look more interesting in experiences that don't use teams. In these, every player is given a random color, which is consistently used for them unless you or they re-join the server.
  * Text is slightly easier to read, with larger text and a more noticeable font, Fredoka One.
  * Display names and roleplay names (Royale High only) are used when available, letting you spot strange and/or interesting people from any distance. Combined with the player-specific coloring, it's easy to remember and recognize specific people on the server. (Long RP names and names that use "<3" are sanitized, but edge-cases and other uses of the '<' and '>' characters may break rich text formatting.)
* New commands!
  * **vdrop** - Infinite Yield's "vgoto" command with a different name! (The vgoto has been updated to use the PivotTo() method, restoring its intended behavior.) Glitchily moves the vehicle that you're sitting in to another player. This has only been tested with the Divinia Park boats in Royale High, which levitate down to whichever player that's targetted.
  * **goto** and **vgoto** have a new second argument that specifies your vertical offset after teleporting to them. This can be used, for example, at Diamond Beach (Royale High) to chase other players with flyijng jetskis (using vfly at high speeds), annoying them with its unpleasant looping sound.

 - Currently 378 commands (377 from IY, 1 new)
 - Open Source
 - 6 years of development (according to Infinite Yield)

## Developers
### Creator
Edge

### Developers
Moon
Zwolf
Toon

### Infinite Fun Modder
Xane M. / JoyfulFlowerMary

## Usage
Press your prefix key (defaults to ';') to show the command list and command line. Here, you can click a command to auto-fill it, or type a command's name to narrow your choices in the list. Hover over a command to read a brief description of what it does, along with its arguments, which are typed after the command, separated by spaces.

For example, to teleport ten studs above a random player, enter this command then press **enter**:
```
goto random 10
```
To repeat a command multiple times with a delay, use caret (^) characters to separate the number of times to repeat (use ```inf``` to never stop until the ```breakloops``` command is ran), the delay in seconds, and the command to execute. For example, to send "Infinite Fun!" in chat five times every half a second, use this command:
```
5^0.5^chat Infinte Fun!
```
Lastly, you can edit your keybinds (including click-teleport and part deletion key-holds) in the settings menu (⚙). Want to try it out and join the fun? Execute the LoadString above to do that!
## Contributing
There is no specific rules on contributing (as of now) just open a pull request and if it checks out we will merge it!

If you've made a pull request to Infinite Yield and it was accepted, it will be included in Infinite Fun when its code is updated (when a "git pull" is done).
