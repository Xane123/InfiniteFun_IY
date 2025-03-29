![Infinite Fun's logo graphic - From top to bottom, there's lilac-colored, italic text that says "Infinite", multi-colored, puffy "FUN" letters, then a smaller, white credit message: "AN Infinite Fun MOD".](https://raw.githubusercontent.com/Xane123/InfiniteFun_IY/master/logo.png)
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
  * **clearscreen** (shortcut: ```cscr```) - Hides all GUI (core and experience) for the specified number of seconds, then restores them. This is perfect for taking screenshots and recording videos without the forced Roblox button in the upper-left corner of the screen messing it up. (This command doesn't hide GUIs created by exploit scripts, so please hide those manually beforehand.)
  * **goto** and **vgoto** have a new second argument that specifies your vertical offset after teleporting to them. This can be used, for example, at Diamond Beach (Royale High) to chase other players with flyijng jetskis (using vfly at high speeds), annoying them with its unpleasant looping sound.
  * **betterwelds** (shortcut: ```bweld```) - Replaces active WeldConstraints in the workspace with classic Welds, improving the reliability and usability of saved character models and clothes from games that use these modern welds like *Dress to Impress*.
  * Three commands have been added that load my other scripts!
  * * **loadapi** - Sets up my Recreation API (Xane123/Roblox-Scripts/API_Recreation.luau), which adds functions and variables related to saving (and eventually loading) instances to and from JSON files! My scripts use it.
    * **recreator** (shortcut: ```xmr```) - Xane's Model Recreator, a mostly user-friendly GUI frontend for the Recreation API. Mark then save nearly anything to JSON files, which can be imported into Roblox Studio using my plugin!
    * **rhsave** - RH Accessory Preserver, a somewhat picky script that can capture specific toggle/variation combinations in Royale High. You can save your captured models using the "saveplace" command, which saves the whole realm to a RBXLX file. Clothes are stored in the "Clothing Captures" sub-folder within the Lighting service. You may also use Xane's Model Recreator to just save that folder to JSON files, but this isn't as recommended, since the Recreation API cannot save unions.

 - Currently 394 commands (389 from IY, 7 added in IF)
 - Open Source
 - 6+ years of development (according to Infinite Yield)

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

For example, to save the current place/realm to "Testing.rbxlx" using [UniversalSynSaveInstance](https://github.com/luau/UniversalSynSaveInstance), including players' character models in Lighting, enter this command then press **enter**:
```
saveplace external players named Testing
```
To repeat a command multiple times with a delay, use caret (^) characters to separate the number of times to repeat (use ```inf``` to never stop until the ```breakloops``` command is ran), the delay in seconds, and the command to execute. For example, to warp above a random player five times every half a second, use this command:
```
5^0.5^goto random 6
```
Lastly, you can edit your keybinds (including click-teleport and part deletion key-holds) in the settings menu (⚙). Want to try it out and join the fun? Execute the LoadString above to do that!
## Contributing
I am a bad manager, so I do not believe I could handle pull requests properly, or be able to trust that they will not break any of my commonly-used commands. If you would like to contribute to Infinite Fun, I recommend creating a pull request for Infinite Yield instead; Any accepted changes will be merged into Infinite Fun manually every few months or so.
