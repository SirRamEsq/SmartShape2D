
SmartShape2D for Godot 4 (alpha 2) porting attempt. 
Current state : 
- Parsing errors, API changes mostly corrected. 
- Button class pressed signal doesn't seem to working correctly. Therefor button pressed signals are commented out.
- Since Reference class being removed in Godot 4, it is replaced by either RefCounted or Resource. It's unclear to me in which case it supposed to be replaced by. Either way because Godot 4 is more strict with static type declaration, more typecasting is needed.
- Current state of version alpha 2 parser/compiler isn't giving any errors and custom class nodes isn't showing up in node explorer.

SmartShape2D
---
![Sample Image]( ./addons/rmsmartshape/documentation/imgs/sample.png )
![Sample Gif]( ./addons/rmsmartshape/documentation/imgs/sample.gif )

SmartShape2D + Aseprite tutorial can be found here (Thanks Picster!):

[![VideoTutorial](https://img.youtube.com/vi/r-pd2yuNPvA/0.jpg)](http://www.youtube.com/watch?v=r-pd2yuNPvA)

SmartShape2D tutorial can be found here (Thanks LucyLavend!):

[![VideoTutorial](https://img.youtube.com/vi/45PldDNCQhw/0.jpg)](https://www.youtube.com/watch?v=45PldDNCQhw)

# About
This plugin allows you to create nicely textured 2D polys.
Simply place a few points then create / assign the shape material and you should have a good looking polygon.

The textures used are similar to what you would use if making terrain using TileMaps/TileSets


**This plugin is under ACTIVE DEVELOPMENT! If you find any issues, by all means let us know.
Read the section below on Contributing and post an issue if one doesn't already exist**

**If you enjoy this tool and want to support its development, [I'd appreciate a coffee ](https://www.buymeacoffee.com/SirRamESQ) :)**
<a href="https://www.buymeacoffee.com/SirRamESQ">
  <img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" align="left" height="48">
</a>

# Support
- Supported and Tested on Godot 3.2
- Should work with later versions of Godot 3.x

# Demo
A Sample Godot Project can be found here:
https://github.com/SirRamEsq/SmartShape2D-DemoProject

# Documentation
- [How To Install]( ./addons/rmsmartshape/documentation/Install.md )
- [Quick Start]( ./addons/rmsmartshape/documentation/Quickstart.md )
- [Migrating from 1.x]( ./addons/rmsmartshape/documentation/Migration.md )
- [Shapes]( ./addons/rmsmartshape/documentation/Shapes.md )
- [Toolbar]( ./addons/rmsmartshape/documentation/Toolbar.md )
- [Resources]( ./addons/rmsmartshape/documentation/Resources.md )
- [Normals]( ./addons/rmsmartshape/documentation/Normals.md )
- [Controls and Hotkeys]( ./addons/rmsmartshape/documentation/Controls.md )
- [FAQ]( ./addons/rmsmartshape/documentation/FAQ.md )
- [Version History]( ./addons/rmsmartshape/documentation/VersionHistory.md )

# Contibuting
## Issues
If you have any suggestions or find any bugs, feel free to add an issue.

Please include the following three bits of information in each issue posted:
- Bug / Suggestion
- Godot Version
- SmartShape2D Version

Some Guidelines for Issues:
- Attaching a sample project where the issue exists is the fastest way for us to see what's going on
- Try to be as descriptive as possible
- Pictures and screenshots will also be very helpful

Issues can be added [here](https://github.com/SirRamEsq/SmartShape2D/issues)

## Development
We have a set of tests we run against the code (courtesy of [GUT](https://github.com/bitwes/Gut)).
If making a merge request, please ensure that the tests pass. If the tests have been updated appropriately to pass, please note this in the merge request.

## Discord
We have a Discord server for the plugin. https://discord.gg/mHWDPBD3vu

Here, you can:
- Ask for help
- Showcase your project
- Speak with the developers directly

