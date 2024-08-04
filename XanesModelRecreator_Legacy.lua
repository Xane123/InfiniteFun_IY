--[[
	XANE'S MODEL RECREATOR (SCRIPT/DECONSTRUCTOR PHASE) V3, WRITTEN IN 2024
	LAST UPDATED ON MAY 21ST, 2024
	
	A personal script of mine, released to the public to enable anyone to save models (and other supported instances)
	from any Roblox experience (as long as your Roblox app doesn't crash in the process of loading it)! Execute this
	script and a small button will appear at the top of your screen. Click/tap on it to open the GUI, then click on
	one of the four buttons at the top of the window to scan through that container, making a list of all of the
	supported Instances or (sentence I apparently never finished?)
	
	Click on an instance's icon to include it in this save (and do that again to deselect it), and use the page
	buttons at the bottom of the window to switch between pages of 100 Instances. If you're unsure of which
	Instance you're selecting, a box will be drawn around them, and you can use the camera button to focus on that
	object, if it supports changing the camera's subject to it. To return to your character, right-click or long
	tap that button.
	
	Instances can be selected from one or all of the containers. Switch between them using the top row of buttons,
	select anything that you want, give a name to this export using the text box at the bottom-right corner, then
	with one click/tap of the save button, your selection will be transformed into JSON files in your executor's
	"workspace" folder.
	
	At the moment, nothing can be done with these files, though you can manually recreate your saved Instances if
	you have a ton of patience and a JSON viewer/beautifier, but it's recommended to wait; In the future, a
	companion plugin will be made for Roblox Studio which takes all of the text and "reconstructs" anything that
	it can, right before your eyes!
	
	GLOBAL ARRAY (_G) SETTINGS
	For those in the know, you can change a couple settings that aren't accessible from the GUI by setting certain
	values in the _G dictionary! Here's the complete list of changes you can make:
	
	_G.PageLength (number) - Adjusts the length of each set of Instances which are shown in the GUI. By default,
	this is 24, but changing this will make each page longer or shorter. If it's small enough, the whole page fits!
	
	_G.AntiLagInterval (number) - To ensure the progress UI updates instead of the script freezing the client while
	it's indexing or saving instances, the recursive iteration function intentionally waits a frame after it checks
	every 25th Instance. If you have a weaker device, increase this to improve performance, though it'll come at
	the cost of longer indexing/saving times. If on a stronger device, I recommend decreasing this or using 0.
	_G.SkipPreSaveVerify (boolean) - Normally, this script makes sure the first couple instances within
	each selected instance exists and has a debug ID. For some reason, this seems to happen even when no
	changes have been made to a selection. If you don't care about incomplete captures or trust
	everything will be saved without problems, set this to TRUE to disable this check, which is described
	as "last-minute indexing" in the green progress toast UI.
]]--
if not game:IsLoaded() then game.Loaded:Wait() end
task.wait(1.5)
print("Xane's Model Reconstructor v3: Initializing... (Please work!)")

-- SERVICES
local Players			= game:GetService("Players")	-- These are the three locations that can be accessed using this script.
local Lighting			= game:GetService("Lighting")
local ReplicatedStorage	= game:GetService("ReplicatedStorage")
local ServerStorage		= game:GetService("ServerStorage")	-- This container stores the four "container imposter" Models for redirection.
local MaterialService	= game:GetService("MaterialService")

-- REFERENCES (PARTIAL, NOT INCLUDING GUI)
local PlayerGui			= Players.LocalPlayer:WaitForChild("PlayerGui")

-- VARIABLES

-- An array of Instance references, placed within string keys named after their Instance:GetDebugId() values. These are used for links between
-- Instances, allowing links between instances to be maintained after exporting models to JSON data. As this array can become pretty large, it's
-- cleared after conversions and closing the GUI. (This can't be done when switching between containers, as the user may have models selected
-- in an "unloaded" container at that point.
local DebugIDList 			= {}

-- STATIC DATA
local DefaultMessage	= "Welcome to Xane's Model Reconstructor v3, the ultimate instance capturer! Please choose a container above, select which instances you want, name it, then save!"

-- STATIC DATA & FUNCTIONS
-- Arrays of properties shared by multiple classes, used to simplify the main class data array/list below.
-- If any list contains a property starting with "UseCmnList_", the script should iterate through the array named after its value here.
local CommonPropList					= {
	Instance							= {
		Name							= "string",
		Parent							= "Instance"
	},
	Attachment							= {
		Axis							= "Vector3",
		SecondaryAxis					= "Vector3",
		CFrame							= "CFrame",	-- Set the CFrame last, in case the previous properties are redundant.
		Visible							= "boolean"
	},
	Decal								= {
		Color3							= "Color3",
		Face							= "EnumItem",	-- Inherited from FaceInstance class
		LocalTransparencyModifier		= "number",
		Texture							= "string",
		Transparency					= "number",
		ZIndex							= "number"
	},
	Model								= {
		LevelOfDetail					= "EnumItem",
		ModelStreamingMode				= "EnumItem",
		PrimaryPart						= "Instance"
	},
	BasePart							= {
		Anchored						= "boolean",
		BackSurface						= "EnumItem",
		BottomSurface					= "EnumItem",
		CFrame							= "CFrame",
		CanCollide						= "boolean",
		CanQuery						= "boolean",
		CanTouch						= "boolean",
		CastShadow						= "boolean",
		CollisionGroup					= "string",
		Color							= "Color3",
		EnableFluidForces				= "boolean",
		FrontSurface					= "EnumItem",
		LeftSurface						= "EnumItem",
		LocalTransparencyModifier		= "number",
		Locked							= "boolean",
		Massless						= "boolean",
		Material						= "EnumItem",
		MaterialVariant					= "string",
		PivotOffset						= "CFrame",
		Reflectance						= "number",
		RightSurface					= "EnumItem",
		RootPriority					= "number",
		Size							= "Vector3",
		TopSurface						= "EnumItem",
		Transparency					= "number"
	},
	Constraint							= {
		Attachment0						= "Instance",
		Attachment1						= "Instance",
		Color							= "BrickColor",
		Enabled							= "boolean",
		Visible							= "boolean"
	},
	JointInstance						= {
		C0								= "CFrame",
		C1								= "CFrame",
		Enabled							= "boolean",
		Part0							= "Instance",
		Part1							= "Instance"
	},
	Light								= {
		Brightness						= "number",
		Color							= "Color3",
		Enabled							= "boolean",
		Shadows							= "boolean"
	},
	Motor								= {
		CurrentAngle					= "number",
		DesiredAngle					= "number",
		MaxVelocity						= "number"
	},
	SpotAndSurfaceLight					= {
		Angle							= "number",
		Face							= "EnumItem",
		Range							= "number"
	},
	SurfaceGuiBase						= {
		Active							= "boolean",
		Adornee							= "Instance",
		Face							= "EnumItem",
	},
	BaseWrap							= {
		CageMeshId						= "string",
		CageOrigin						= "CFrame",
		ImportOrigin					= "CFrame"
	},
	PBRMapSet							= {
		ColorMap						= "string",
		MetalnessMap					= "string",
		NormalMap						= "string",
		RoughnessMap					= "string"
	},
	LayerCollector						= {	-- Used by ScreenGui's and possibly moe classes.
		Enabled							= "boolean",
		ResetOnSpawn					= "boolean",
		ZIndexBehavior					= "EnumItem"
	},
	GuiButton							= {
		AutoButtonColor					= "boolean",
		Modal							= "boolean",
		Selected						= "boolean",
		Style							= "EnumItem"
	},
	GuiObject							= {
		Active							= "boolean",
		AnchorPoint						= "Vector2",
		AutomaticSize					= "EnumItem",
		BackgroundColor3				= "Color3",
		BackgroundTransparency			= "number",
		BorderColor3					= "Color3",
		BorderMode						= "EnumItem",
		BorderSizePixel					= "number",
		ClipsDescendants				= "boolean",
		-- Draggable					= "boolean",
		Interactable					= "boolean",
		LayoutOrder						= "number",
		Position						= "UDim2",
		Rotation						= "number",
		Selectable						= "boolean",
		SelectionOrder					= "number",
		Size							= "UDim2",
		SizeConstraint					= "EnumItem",
		Visible							= "boolean",
		ZIndex							= "number"
	},
	GuiBase2d							= {
		AutoLocalize					= "boolean"
	},
	GuiTextElement						= {	-- TextButtons and TextLabels have the exact same properties!
		FontFace						= "Font",
		LineHeight						= "number",
		MaxVisibleGraphemes				= "number",
		RichText						= "boolean",
		Text							= "string",
		TextColor3						= "Color3",
		TextDirection					= "EnumItem",
		TextScaled						= "boolean",
		TextSize						= "number",
		TextStrokeColor3				= "Color3",
		TextStrokeTransparency			= "number",
		TextTransparency				= "number",
		TextTruncate					= "EnumItem",
		TextWrapped						= "boolean",
		TextXAlignment					= "EnumItem",
		TextYAlignment					= "EnumItem"
	},
	GuiImageElement						= {	-- Properties reused between ImageLabels and ImageButtons.
		Image							= "string",
		ImageColor3						= "Color3",
		ImageRectOffset					= "Vector2",
		ImageRectSize					= "Vector2",
		ImageTransparency				= "number",
		ResampleMode					= "EnumItem",
		ScaleType						= "EnumItem",
		SliceCenter						= "Rect",
		SliceScale						= "number",
		TileSize						= "UDim2"
	},
	UIGridStyleLayout					= {
		FillDirection					= "EnumItem",
		HorizontalAlignment				= "EnumItem",
		SortOrder						= "EnumItem",
		VerticalAlignment				= "EnumItem"
	}
}

-- A very long, complex array of dictionary entries that specifies what properties should be saved for specific instance classes, and what
-- their types are. This may look almost identical to its plugin counterpart, but there are some differences. For example, MeshParts' MeshId
-- property is included in the script version so it saves its value, but it's commented out in the plugin, since modifying that property
-- directly will cause errors and break its functions.

-- When iterating through one of these property lists, make sure it's always done from top to bottom; Sometimes, the properties have to be set
-- out of alphabetical order! Also, Don't use a "UseCmnList_" definition to inherit from the "Instance" list above! The final script will
-- automatically do that to simplify things.

-- When ay reference to an Instance is found by the Studio plugin, just silently add each of the properties to an array index named after the
-- instance's "intended debug ID", then go back through that list afte all instances have been "imported" and use the complete "debug ID" array
-- to link each of the properties to their intended "reconstructed" instances.
local ClassData							= {
	["AdGui"]							= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "📊",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "parent"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			UseCmnList_1				= "LayerCollector",	-- Common properties that this class shares with others.
			UseCmnList_2				= "GuiBase2d",
			UseCmnList_3				= "SurfaceGuiBase",
			AdShape						= "EnumItem",
			EnableVideoAds				= "boolean",
			FallbackImage				= "string",
		}
	},
	["Attachment"]						= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "🔌",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= false,	-- Don't attempt to make an Instance of this type if testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			UseCmnList_1				= "Attachment"	-- Common properties that this class shares with others.
		}
	},
	["Accessory"]						= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "👚",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "child"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			AccessoryType				= "EnumItem",
			AttachmentPoint				= "CFrame"	-- Inherited from Accoutrement (What even is that word?)
		}
	},
	["Animation"]						= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "🤺",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			AnimationId					= "string"
		}
	},
	["AnimationController"]				= {	-- AnimationController instances don't have any properties other than standard Instance ones.
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "🤺",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
		}
	},
	--[[["Animator"]						= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "🤺",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= false,	-- Don't attempt to make an Instance of this type if testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			PreferLodEnabled			= "boolean"
		}
	},]]--
	["Atmosphere"]						= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "⛅",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			Color						= "Color3",
			Decay						= "Color3",
			Density						= "number",
			Glare						= "number",
			Haze						= "number",
			Offset						= "number"
		}
	},
	["Backpack"]						= {	-- Backpacks don't have any properties other than standard Instance ones.
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "🎒",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
		}
	},
	["Beam"]							= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "⚡",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "parent"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			Attachment0					= "Instance",
			Attachment1					= "Instance",
			LightInfluence				= "number",	-- Brightness is only used if LightInfluence is set to a low value.
			Brightness					= "number",
			Color						= "ColorSequence",
			CurveSize0					= "number",
			CurveSize1					= "number",
			Enabled						= "boolean",
			FaceCamera					= "boolean",
			LightEmission				= "number",
			Segments					= "number",
			Texture						= "string",
			TextureLength				= "number",
			TextureMode					= "EnumItem",
			TextureSpeed				= "number",
			Transparency				= "NumberSequence",
			Width0						= "number",
			Width1						= "number",
			ZOffset						= "number"
		}
	},
	["BillboardGui"]					= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "🛑",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			UseCmnList_1				= "LayerCollector",	-- Common properties that this class shares with others.
			UseCmnList_2				= "GuiBase2d",
			Active						= "boolean",
			Adornee						= "Instance",
			AlwaysOnTop					= "boolean",
			Brightness					= "number",
			ClipsDescendants			= "boolean",
			DistanceLowerLimit			= "number",
			DistanceStep				= "number",
			DistanceUpperLimit			= "number",
			ExtentsOffset				= "Vector3",
			ExtentsOffsetWorldSpace		= "Vector3",
			LightInfluence				= "number",
			MaxDistance					= "number",
			Size						= "UDim2",
			SizeOffset					= "Vector2",
			StudsOffset					= "Vector3",
			StudsOffsetWorldSpace		= "Vector3"
		}
	},
	["BloomEffect"]						= {	-- Decals' properties are reused for Textures.
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "🌄",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			Enabled						= "boolean",	-- Inherited from PostEffect class
			Intensity					= "number",
			Size						= "number",
			Threshold					= "number"
		}
	},
	["BlurEffect"]						= {	-- Decals' properties are reused for Textures.
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "🌄",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			Enabled						= "boolean",	-- Inherited from PostEffect class
			Size						= "number",
		}
	},
	["Bone"]						= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "🦴",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			UseCmnList_1				= "Attachment",	-- Common properties that this class shares with others.
			Transform					= "CFrame"
		}
	},
	["BoolValue"]					= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "🔢",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			Value						= "boolean"
		}
	},
	["BrickColorValue"]					= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "🔢",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			Value						= "BrickColor"
		}
	},
	["Camera"]							= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "🎥",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no"	-- Cameras aren't used much outside of ViewportFrames so I don't want to script viewing them.
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			CameraType					= "EnumItem",
			CameraSubject				= "Instance",
			FieldOfViewMode				= "EnumItem",
			DiagonalFieldOfView			= "number",
			MaxAxisFieldOfView			= "number",
			FieldOfView					= "number",
			Focus						= "CFrame",
			HeadLocked					= "boolean",
			HeadScale					= "number",
			VRTiltAndRollEnabled		= "boolean",
			CFrame						= "CFrame"
		}
	},
	["CanvasGroup"]						= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "🏢",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			UseCmnList_1				= "GuiObject",	-- Common properties that this class shares with others.
			UseCmnList_2				= "GuiBase2d",
			GroupColor3					= "Color3",
			GroupTransparency			= "number"
		}
	},
	["CFrameValue"]					= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "🔢",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			Value						= "CFrame"
		}
	},
	["Color3Value"]					= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "🔢",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			Value						= "Color3"
		}
	},
	["ColorCorrectionEffect"]			= {	-- Decals' properties are reused for Textures.
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "🌄",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			Enabled						= "boolean",	-- Inherited from PostEffect class
			Brightness					= "number",
			Contrast					= "number",
			Saturation					= "number",
			TintColor					= "Color3"
		}
	},
	["Configuration"]					= {	-- Configuration folders don't have any properties other than standard Instance ones.
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "⚙",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
		}
	},
	["CornerWedgePart"]					= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "🧱",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "yes"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			UseCmnList_1				= "BasePart"	-- Use all of the properties shared by all BasePart instances.
		}
	},
	["Decal"]							= {	-- Decals' properties are reused for Textures.
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "📄",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			UseCmnList_1				= "Decal",	-- Common properties that this class shares with others.
		}
	},
	["DepthOfFieldEffect"]						= {	-- Decals' properties are reused for Textures.
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "🌄",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			Enabled						= "boolean",	-- Inherited from PostEffect class
			FarIntensity				= "number",
			FocusDistance				= "number",
			InFocusRadius				= "number",
			NearIntensity				= "number"
		}
	},
	["DoubleConstrainedValue"]			= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "🔢",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			MaxValue					= "number",
			MinValue					= "number"
		}
	},
	["Fire"]							= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "🔥",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "parent"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			Color						= "Color3",
			Enabled						= "boolean",
			Heat						= "number",
			SecondaryColor				= "Color3",
			Size						= "number",
			TimeScale					= "number"
		}
	},
	["Folder"]							= {	-- Folders don't have any properties other than standard Instance ones.
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "📁",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
		}
	},
	["Frame"]						= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "🖼",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			UseCmnList_1				= "GuiObject",	-- Common properties that this class shares with others.
			UseCmnList_2				= "GuiBase2d",
			Style						= "EnumItem"
		}
	},
	["Highlight"]						= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "🔳",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "parent"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			Adornee						= "Instance",
			DepthMode					= "EnumItem",
			Enabled						= "boolean",
			FillColor					= "Color3",
			FillTransparency			= "number",
			OutlineColor				= "Color3",
			OutlineTransparency			= "number"
		}
	},
	["HingeConstraint"]					= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "🧷",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			UseCmnList_1				= "Constraint",	-- Common properties that this class shares with others.
			ActuatorType				= "EnumItem",
			AngularResponsiveness		= "number",
			AngularVelocity				= "number",
			LimitsEnabled				= "boolean",
			LowerAngle					= "number",
			MotorMaxAcceleration		= "number",
			MotorMaxTorque				= "number",
			Radius						= "number",
			Restitution					= "number",
			ServoMaxTorque				= "number",
			TargetAngle					= "number",
			UpperAngle					= "number"
		}
	},
	["Humanoid"]						= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "🙍🏼‍",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			AutoJumpEnabled				= "boolean",
			AutoRotate					= "boolean",
			AutomaticScalingEnabled		= "boolean",
			BreakJointsOnDeath			= "boolean",
			CameraOffset				= "Vector3",
			DisplayDistanceType			= "EnumItem",
			DisplayName					= "string",
			-- EvaluateStateMachine		= "boolean",
			Health						= "number",
			HealthDisplayDistance		= "number",
			HealthDisplayType			= "EnumItem",
			HipHeight					= "number",
			JumpHeight					= "number",
			JumpPower					= "number",
			MaxHealth					= "number",
			MaxSlopeAngle				= "number",
			NameDisplayDistance			= "number",
			NameOcclusion				= "EnumItem",
			PlatformStand				= "boolean",
			RequiresNeck				= "boolean",
			RigType						= "EnumItem",	-- Should this property be captured?
			UseJumpPower				= "boolean",
			WalkSpeed					= "number"
		}
	},
	["HumanoidDescription"]						= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "👤",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			BackAccessory				= "string",
			BodyTypeScale				= "number",
			ClimbAnimation				= "number",
			DepthScale					= "number",
			Face						= "number",
			FaceAccessory				= "string",
			FallAnimation				= "number",
			FrontAccessory				= "string",
			GraphicTShirt				= "number",
			HairAccessory				= "string",
			HatAccessory				= "string",
			Head						= "number",
			HeadColor					= "Color3",
			HeadScale					= "number",
			HeightScale					= "number",
			IdleAnimation				= "number",
			JumpAnimation				= "number",
			LeftArm						= "number",
			LeftArmColor				= "Color3",
			LeftLeg						= "number",
			LeftLegColor				= "Color3",
			MoodAnimation				= "number",
			NeckAccessory				= "string",
			Pants						= "number",
			ProportionScale				= "number",
			RightArm					= "number",
			RightArmColor				= "Color3",
			RightLeg					= "number",
			RightLegColor				= "Color3",
			RunAnimation				= "number",
			Shirt						= "number",
			ShouldersAccessory			= "string",
			SwimAnimation				= "number",
			Torso						= "number",
			TorsoColor					= "Color3",
			WaistAccessory				= "string",
			WalkAnimation				= "number",
			WidthScale					= "number"
		}
	},
	["ImageButton"]						= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "🏞",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			UseCmnList_1				= "GuiImageElement",	-- Common properties that this class shares with others.
			UseCmnList_2				= "GuiButton",
			UseCmnList_3				= "GuiObject",
			UseCmnList_4				= "GuiBase2d",
			HoverImage					= "string",
			PressedImage				= "string"
		}
	},
	["ImageLabel"]						= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "🏞",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			UseCmnList_1				= "GuiImageElement",	-- Common properties that this class shares with others.
			UseCmnList_2				= "GuiObject",
			UseCmnList_3				= "GuiBase2d"
		}
	},
	["IntValue"]						= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "🔢",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			Value						= "number"
		}
	},
	["IntConstrainedValue"]				= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "🔢",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			MaxValue					= "number",
			MinValue					= "number"
		}
	},
	["LineForce"]						= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "↗",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			UseCmnList_1				= "Constraint",	-- Common properties that this class shares with others.
			ApplyAtCenterOfMass			= "boolean",
			InverseSquareLaw			= "boolean",
			Magnitude					= "number",
			MaxForce					= "number",
			ReactionForceEnabled		= "boolean"
		}
	},
	["MaterialVariant"]					= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "🏁",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= false,-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			UseCmnList_1				= "PBRMapSet",	-- Common properties that this class shares with others.
			BaseMaterial				= "EnumItem",
			CustomPhysicalProperties	= "PhysicalProperties",
			MaterialPattern				= "EnumItem",
			StudsPerTile				= "number",
		}
	},
	["MeshPart"]						= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "🧭",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "yes"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			UseCmnList_1				= "BasePart",	-- Use all of the properties shared by all BasePart instances.
			DoubleSided					= "boolean",
			TextureID					= "string",
			MeshId						= "string",	-- Comment this line out in the plugin! MeshIds can't be set directly, only used on creation.
			RenderFidelity				= "EnumItem",	-- Comment this out too...
			CollisionFidelity			= "EnumItem"	-- ...and this one! (This inherits from the "TriangleMeshPart" class, also used by unions.)
		}
	},
	["Model"]							= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "🔳",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "yes"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			UseCmnList_1				= "Model"	-- Other classes inherit from this one.
		}
	},
	["Motor"]							= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "🛵",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			UseCmnList_1				= "Motor",
			UseCmnList_2				= "JointInstance"
		}
	},
	["Motor6D"]							= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "💪🏼",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			UseCmnList_1				= "Motor",
			UseCmnList_2				= "JointInstance",
			Transform					= "CFrame"
		}
	},
	["NumberValue"]						= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "🔢",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			Value						= "number"
		}
	},
	["ObjectValue"]						= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "🔢",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			Value						= "Instance"
		}
	},
	["Pants"]							= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "👕",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "parent"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			PantsTemplate				= "string",
			Color3						= "Color3"	-- Inherited from Clothing class
		}
	},
	["Part"]							= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "🧱",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "yes"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			UseCmnList_1				= "BasePart",	-- Use all of the properties shared by all BasePart instances.
			Shape						= "EnumItem"
		}
	},
	["ParticleEmitter"]							= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "✨",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "parent"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			Acceleration				= "Vector3",
			LightInfluence				= "number",	-- Brightness is only used if LightInfluence is set to a low value.
			Brightness					= "number",
			Color						= "ColorSequence",
			Drag						= "number",
			EmissionDirection			= "EnumItem",
			Enabled						= "boolean",
			FlipbookFramerate			= "NumberRange",
			FlipbookIncompatible		= "string",
			FlipbookLayout				= "EnumItem",
			FlipbookMode				= "EnumItem",
			FlipbookStartRandom			= "boolean",
			Lifetime					= "NumberRange",
			LightEmission				= "number",
			LockedToPart				= "boolean",
			Orientation					= "EnumItem",
			Rate						= "number",
			RotSpeed					= "NumberRange",
			Rotation					= "NumberRange",
			Shape						= "EnumItem",
			ShapeInOut					= "EnumItem",
			ShapePartial				= "number",
			ShapeStyle					= "EnumItem",
			Size						= "NumberSequence",
			Speed						= "NumberRange",
			SpreadAngle					= "Vector2",
			Squash						= "NumberSequence",
			Texture						= "string",
			TimeScale					= "number",
			Transparency				= "NumberSequence",
			VelocityInheritance			= "number",
			WindAffectsDrag				= "boolean",
			ZOffset						= "number"
		}
	},
	["PlaneConstraint"]					= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "🧷",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			UseCmnList_1				= "Constraint"	-- Common properties that this class shares with others.
		}
	},
	["Player"]							= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "👤",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= false,	-- Don't attempt to make an Instance of this type if testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			AutoJumpEnabled				= "boolean",
			CameraMaxZoomDistance		= "number",
			CameraMinZoomDistance		= "number",
			CameraMode					= "EnumItem",
			CanLoadCharacterAppearance	= "boolean",
			Character					= "Instance",
			CharacterAppearanceId		= "number",
			DevCameraOcclusionMode		= "EnumItem",
			DevComputerCameraMode		= "EnumItem",
			DevComputerMovementMode		= "EnumItem",
			DevEnableMouseLock			= "boolean",
			DevTouchCameraMode			= "EnumItem",
			DevTouchMovementMode		= "EnumItem",
			DisplayName					= "string",
			HealthDisplayDistance		= "number",
			NameDisplayDistance			= "number",
			Neutral						= "boolean",
			-- ReplicationFocus			= "Instance",
			-- RespawnLocation			= "Instance",
			-- Team						= "Instance",
			TeamColor					= "BrickColor",
			UserId						= "number"
		}
	},
	["PlayerGui"]							= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "📱",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= false,	-- Don't attempt to make an Instance of this type if testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			ScreenOrientation			= "EnumItem",
		}
	},
	["PointLight"]					= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "💡",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "parent"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			UseCmnList_1				= "Light",	-- Common properties that this class shares with others.
			Range						= "number"
		}
	},
	["PrismaticConstraint"]				= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "🧷",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			UseCmnList_1				= "SlidingBallConstraint",	-- Common properties that this class shares with others.
			UseCmnList_2				= "Constraint"
		}
	},
	["RodConstraint"]				= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "🧷",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			UseCmnList_1				= "Constraint",	-- Common properties that this class shares with others.
			Length						= "boolean",
			LimitAngle0					= "number",
			LimitAngle1					= "number",
			LimitsEnabled				= "boolean",
			Thickness					= "number"
		}
	},
	["RopeConstraint"]					= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "🧷",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			UseCmnList_1				= "Constraint",	-- Common properties that this class shares with others.
			Length						= "number",
			Restitution					= "number",
			Thickness					= "number",
			WinchEnabled				= "boolean",
			WinchForce					= "number",
			WinchResponsiveness			= "number",
			WinchSpeed					= "number",
			WinchTarget					= "number"
		}
	},
	["ScreenGui"]						= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "📱",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			UseCmnList_1				= "LayerCollector",	-- Common properties that this class shares with others.
			UseCmnList_2				= "GuiBase2d",
			ClipToDeviceSafeArea		= "boolean",
			DisplayOrder				= "number",
			IgnoreGuiInset				= "boolean",
			SafeAreaCompatibility		= "EnumItem",
			ScreenInsets				= "EnumItem"
		}
	},
	["ScrollingFrame"]						= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "🖼",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			UseCmnList_1				= "GuiObject",	-- Common properties that this class shares with others.
			UseCmnList_2				= "GuiBase2d",
			AutomaticCanvasSize			= "EnumItem",
			BottomImage					= "string",
			CanvasPosition				= "Vector2",
			CanvasSize					= "UDim2",
			ElasticBehavior				= "EnumItem",
			HorizontalScrollBarInset	= "EnumItem",
			MidImage					= "string",
			ScrollBarImageColor3		= "Color3",
			ScrollBarImageTransparency	= "number",
			ScrollBarThickness			= "number",
			ScrollingDirection			= "EnumItem",
			ScrollingEnabled			= "boolean",
			TopImage					= "string",
			VerticalScrollBarInset		= "EnumItem",
			VerticalScrollBarPosition	= "EnumItem"
		}
	},
	["Seat"]							= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "🪑",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "yes"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			UseCmnList_1				= "BasePart",	-- Use all of the properties shared by all BasePart instances.
			Shape						= "EnumItem",	-- Inherited from Part class
			Disabled					= "boolean"
		}
	},
	["Shirt"]							= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "👕",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "parent"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			ShirtTemplate				= "string",
			Color3						= "Color3"	-- Inherited from Clothing class
		}
	},
	["ShirtGraphic"]					= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "🎽",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "parent"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			Graphic						= "string",
			Color3						= "Color3"
		}
	},
	["Sky"]								= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "🌄",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			CelestialBodiesShown		= "boolean",
			MoonAngularSize				= "number",
			MoonTextureId				= "string",
			SkyboxBk					= "string",
			SkyboxDn					= "string",
			SkyboxFt					= "string",
			SkyboxLf					= "string",
			SkyboxRt					= "string",
			SkyboxUp					= "string",
			StarCount					= "number",
			SunAngularSize				= "number",
			SunTextureId				= "string"
		}
	},
	["Smoke"]							= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "☁",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "parent"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			Color						= "Color3",
			Enabled						= "boolean",
			Opacity						= "number",
			RiseVelocity				= "number",
			Size						= "number",
			TimeScale					= "number"
		}
	},
	["Sparkles"]							= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "✨",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "parent"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			Color						= "Color3",
			Enabled						= "boolean",
			SparkleColor				= "Color3",
			TimeScale					= "number"
		}
	},
	["SpawnLocation"]					= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "🌌",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "yes"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			UseCmnList_1				= "BasePart",	-- Use all of the properties shared by all BasePart instances.
			Shape						= "EnumItem",	-- Inherited from Part class
			AllowTeamChangeOnTouch		= "boolean",
			Duration					= "number",
			Enabled						= "boolean",
			Neutral						= "boolean",
			TeamColor					= "BrickColor"
		}
	},
	["SpecialMesh"]						= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "🥘",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= false,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "parent"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			MeshType					= "EnumItem",
			MeshId						= "string",		-- Inherited from FileMesh
			TextureId					= "string",		-- Inherited from FileMesh
			Offset						= "Vector3",	-- Inherited from DataModelMesh
			Scale						= "Vector3",	-- Inherited from DataModelMesh
			VertexColor					= "Vector3"		-- Inherited from DataModelMesh
		}
	},
	["SpotLight"]					= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "💡",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "parent"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			UseCmnList_1				= "Light",	-- Common properties that this class shares with others.
			UseCmnList_2				= "SpotAndSurfaceLight"
		}
	},
	["SpringConstraint"]				= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "🧷",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			UseCmnList_1				= "Constraint",	-- Common properties that this class shares with others.
			Coils						= "number",
			Damping						= "number",
			FreeLength					= "number",
			LimitsEnabled				= "boolean",
			MaxForce					= "number",
			MaxLength					= "number",
			MinLength					= "number",
			Radius						= "number",
			Stiffness					= "number",
			Thickness					= "number"
		}
	},
	["StringValue"]						= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "🔢",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			Value						= "string"
		}
	},
	["SunRaysEffect"]					= {	-- Decals' properties are reused for Textures.
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "🌞",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			Enabled						= "boolean",	-- Inherited from PostEffect class
			Intensity					= "number",
			Spread						= "number"
		}
	},
	["SurfaceAppearance"]				= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "🏐",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			UseCmnList_1				= "PBRMapSet",	-- Common properties that this class shares with others.
			AlphaMode					= "EnumItem",
		}
	},
	["SurfaceGui"]					= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "🌘",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			UseCmnList_1				= "LayerCollector",	-- Common properties that this class shares with others.
			UseCmnList_2				= "GuiBase2d",
			UseCmnList_3				= "SurfaceGuiBase",
			AlwaysOnTop					= "boolean",
			Brightness					= "number",
			CanvasSize					= "Vector2",
			ClipsDescendants			= "boolean",
			LightInfluence				= "number",
			MaxDistance					= "number",
			PixelsPerStud				= "number",
			SizingMode					= "EnumItem",
			ToolPunchThroughDistance	= "number",
			ZOffset						= "number"
		}
	},
	["SurfaceLight"]					= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "💡",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "parent"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			UseCmnList_1				= "Light",	-- Common properties that this class shares with others.
			UseCmnList_2				= "SpotAndSurfaceLight"
		}
	},
	["TextBox"]							= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "🖊",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			UseCmnList_1				= "GuiTextElement",	-- Common properties that this class shares with others.
			UseCmnList_2				= "GuiObject",
			UseCmnList_3				= "GuiBase2d",
			ClearTextOnFocus			= "boolean",
			-- CursorPosition				= "number",
			MultiLine					= "boolean",
			PlaceholderColor3			= "Color3",
			PlaceholderText				= "string",
			-- SelectionStart				= "number",
			ShowNativeInput				= "boolean",
			TextEditable				= "boolean"
		}
	},
	["TextButton"]						= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "🔠",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			UseCmnList_1				= "GuiTextElement",	-- Common properties that this class shares with others.
			UseCmnList_2				= "GuiButton",
			UseCmnList_3				= "GuiObject",
			UseCmnList_4				= "GuiBase2d"
		}
	},
	["TextLabel"]						= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "🔠",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			UseCmnList_1				= "GuiTextElement",	-- Common properties that this class shares with others.
			UseCmnList_2				= "GuiObject",
			UseCmnList_3				= "GuiBase2d"
		}
	},
	["Texture"]							= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "📄",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			UseCmnList_1				= "Decal",	-- Common properties that this class shares with others.
			OffsetStudsU				= "number",
			OffsetStudsV				= "number",
			StudsPerTileU				= "number",
			StudsPerTileV				= "number"
		}
	},
	["Tool"]							= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "🛠",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "child"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			UseCmnList_1				= "Model",	-- Common properties that this class shares with others.
			CanBeDropped				= "boolean",
			Enabled						= "boolean",
			Grip						= "CFrame",
			ManualActivationOnly		= "boolean",
			RequiresHandle				= "boolean",
			ToolTip						= "string",
			TextureId					= "string"	-- Inherited from BackpackItem
		}
	},
	["Trail"]							= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "🎗",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "parent"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			Attachment0					= "Instance",
			Attachment1					= "Instance",
			LightInfluence				= "number",	-- Brightness is only used if LightInfluence is set to a low value.
			Brightness					= "number",
			Color						= "ColorSequence",
			Enabled						= "boolean",
			FaceCamera					= "boolean",
			Lifetime					= "number",
			LightEmission				= "number",
			MaxLength					= "number",
			MinLength					= "number",
			Texture						= "string",
			TextureLength				= "number",
			TextureMode					= "EnumItem",
			Transparency				= "number",
			WidthScale					= "NumberSequence"
		}
	},
	["TrussPart"]					= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "💈",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "yes"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			UseCmnList_1				= "BasePart",	-- Use all of the properties shared by all BasePart instances.
			Style						= "EnumItem"
		}
	},
	["UIAspectRatioConstraint"]			= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "⏹",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			AspectRatio					= "number",
			AspectType					= "EnumItem",
			DominantAxis				= "EnumItem"
		}
	},
	["UICorner"]			= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "⏹",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			CornerRadius				= "UDim"
		}
	},
	["UIFlexItem"]							= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "🔛",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			FlexMode					= "EnumItem",
			GrowRatio					= "number",
			ItemLineAlignment			= "EnumItem",
			ShrinkRatio					= "number"
		}
	},
	["UIGradient"]			= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "🎨",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			Color						= "ColorSequence",
			Enabled						= "boolean",
			Offset						= "Vector2",
			Rotation					= "number",
			Transparency				= "NumberSequence"
		}
	},
	["UIGridLayout"]					= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "⏹",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no",	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			UseCmnList_1				= "UIGridStyleLayout",
			CellPadding					= "UDim2",
			CellSize					= "UDim2",
			FillDirectionMaxCells		= "number",
			StartCorner					= "EnumItem"
		}
	},
	["UIListLayout"]					= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "⏹",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			UseCmnList_1				= "UIGridStyleLayout",
			HorizontalFlex				= "EnumItem",
			ItemLineAlignment			= "EnumItem",
			Padding						= "UDim",
			VerticalFlex				= "EnumItem",
			Wraps						= "boolean"
		}
	},
	["UIPadding"]						= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "◻",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			PaddingBottom				= "UDim",
			PaddingLeft					= "UDim",
			PaddingRight				= "UDim",
			PaddingTop					= "UDim"
		}
	},
	["UIPageLayout"]					= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "⏹",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no",	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			UseCmnList_1				= "UIGridStyleLayout",
			Animated					= "boolean",
			Circular					= "boolean",
			EasingDirection				= "EnumItem",
			EasingStyle					= "EnumItem",
			GamepadInputEnabled			= "boolean",
			Padding						= "UDim",
			ScrollWheelInputEnabled		= "boolean",
			TouchInputEnabled			= "boolean",
			TweenTime					= "number"
		}
	},
	["UIScale"]							= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "↗",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			Scale						= "number"
		}
	},
	["UISizeConstraint"]			= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "⏹",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			MaxSize						= "Vector2",
			MinSize						= "Vector2"
		}
	},
	["UIStroke"]			= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "🖇",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			ApplyStrokeMode				= "EnumItem",
			Color						= "Color3",
			Enabled						= "boolean",
			LineJoinMode				= "EnumItem",
			Thickness					= "number",
			Transparency				= "number"
		}
	},
	["UITableLayout"]					= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "⏹",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no",	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			UseCmnList_1				= "UIGridStyleLayout",
			FillEmptySpaceColumns		= "boolean",
			FillEmptySpaceRows			= "boolean",
			MajorAxis					= "EnumItem",
			Padding						= "UDim2"
		}
	},
	["UITextSizeConstraint"]			= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "⏹",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			MaxTextSize						= "number",
			MinTextSize						= "number"
		}
	},
	["UniversalConstraint"]				= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "🧷",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			UseCmnList_1				= "Constraint",	-- Common properties that this class shares with others.
			LimitsEnabled				= "boolean",
			MaxAngle					= "number",
			Radius						= "number",
			Restitution					= "number"
		}
	},
	["Vector3Value"]					= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "🔢",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			Value						= "Vector3"
		}
	},
	["VectorForce"]						= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "↗",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			UseCmnList_1				= "Constraint",	-- Common properties that this class shares with others.
			ApplyAtCenterOfMass			= "boolean",
			Force						= "Vector3",
			RelativeTo					= "EnumItem"
		}
	},
	["VehicleSeat"]							= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "🚗",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "yes"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			UseCmnList_1				= "BasePart",	-- Use all of the properties shared by all BasePart instances.
			Disabled					= "boolean",
			HeadsUpDisplay				= "boolean",
			MaxSpeed					= "number",
			Torque						= "number",
			TurnSpeed					= "number"
		}
	},
	["ViewportFrame"]					= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "📊",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			UseCmnList_1				= "GuiObject",	-- Common properties that this class shares with others.
			UseCmnList_2				= "GuiBase2d",
			Ambient						= "Color3",
			CurrentCamera				= "Instance",
			ImageColor3					= "Color3",
			ImageTransparency			= "number",
			LightColor					= "Color3",
			LightDirection				= "Vector3"
		}
	},
	["WedgePart"]						= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "🧱",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "yes"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			UseCmnList_1				= "BasePart"	-- Use all of the properties shared by all BasePart instances.
		}
	},
	["Weld"]							= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "🔗",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= true,	-- Create an Instance of this type when testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			UseCmnList_1				= "JointInstance"
		}
	},
	["WorldModel"]							= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "🌎",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= false,	-- Don't attempt to make an Instance of this type if testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			UseCmnList_1				= "Model"	-- Common properties that this class shares with others.
		}
	},
	["WrapLayer"]						= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "↔",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= false,	-- Don't attempt to make an Instance of this type if testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			UseCmnList_1				= "BaseWrap",	-- Common properties that this class shares with others.
			AutoSkin					= "EnumItem",
			BindOffset					= "CFrame",
			Enabled						= "boolean",
			Order						= "number",
			Puffiness					= "number",
			ReferenceMeshId				= "string",
			ReferenceOrigin				= "CFrame",
			ShrinkFactor				= "number"
		}
	},
	["WrapTarget"]						= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "↔",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= false,	-- Don't attempt to make an Instance of this type if testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		},
		Props							= {		-- List of properties that should be saved or loaded to/from JSON for this instance.
			UseCmnList_1				= "BaseWrap",	-- Common properties that this class shares with others.
			Stiffness					= "number"
		}
	},

	-- The four Instance classes below are only ever displayed in the list, never exported or imported, so they're intentionally folder-like.
	["Workspace"]						= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "🌎",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= false,	-- Don't attempt to make an Instance of this type if testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		}
	},
	["Players"]							= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "👥",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= false,	-- Don't attempt to make an Instance of this type if testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		}
	},
	["Lighting"]						= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "🌤",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= false,	-- Don't attempt to make an Instance of this type if testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		}
	},
	["ReplicatedStorage"]				= {
		ListView						= {		-- Properties that customize how this instance is displayed in the list (only used in the script).
			Icon						= "📦",	-- Emoji used to represent this instance when it's unselected.
			CreateTest					= false,	-- Don't attempt to make an Instance of this type if testing the script in Roblox Studio.
			CanView						= "no"	-- Can the camera focus on this instance?
		}
	},
}

-- StoreValue (takes any and string, returns varied content)
-- Takes an arbitrary value and tries to convert it to a value which could be stored in a JSON dictionary. For
-- most variable types, this just takes its components and splits them up into a basic array.
local function StoreValue(_value , _type )
	-- While the "type" argument is respected in most of this function, if the value provided is nil, it takes priority over everything else.
	-- 
	if typeof(_value) == "nil"  then
		return nil	-- JSON supports nil values! It writes "null" instead of "nil".
	end
	
	-- Basic variables can be used as-is, safely.
	if _type == "boolean" or _type == "number" or _type == "string" then
		return _value
	elseif _type == "Color3" then
		return {_value.R, _value.G, _value.B}
	elseif _type == "BrickColor" then
		return _value.Name	-- Store the BrickColor's name, which can be used to recreate it later using BrickColor.new([name]).
	elseif _type == "ColorSequence" or _type == "NumberSequence" then	-- Sequences will be stored in their "string" form.
		if _value and tostring(_value):sub(-1,-1) ~= " " then return tostring(_value)	-- If the string doesn't end in an erroneous space, save as-is.
		else return tostring(_value):sub(1,-2)											-- Does it? If so, don't include the last character!
		end
	elseif _type == "NumberRange" then
		return {_value.Min, _value.Max}
	elseif _type == "UDim" then
		return {_value.Scale, _value.Offset}
	elseif _type == "UDim2" then
		return {_value.Width.Scale, _value.Width.Offset, _value.Height.Scale, _value.Height.Offset}
	elseif _type == "Rect" then	-- Rects are stored as the minimum Vector2 XY values followed by their "max" counterparts. Use Rect.new([1],[2],[3],[4])!
		return {_value.Min.X,_value.Min.Y,_value.Max.X,_value.Max.Y}
	elseif _type == "Font" then
		return {_value.Family, _value.Weight.Value, _value.Style.Value}	-- Save this font's properties. Reconstruct it using Font.new(family, weight, style).
	elseif _type == "Vector2" then
		return {_value.X, _value.Y}
	elseif _type == "Vector3" then
		return {_value.X, _value.Y, _value.Z}
	elseif _type == "EnumItem" then	-- Store the Enum's name, followed by the item within it. Reconstruct using Enum[item 1][item 2].
		return {tostring(_value.EnumType), _value.Name}
	elseif _type == "CFrame" then
		local X,Y,Z,R00,R01,R02,R10,R11,R12,R20,R21,R22 = _value:GetComponents()
		return {X,Y,Z,R00,R01,R02,R10,R11,R12,R20,R21,R22}	-- Return all components of this CoordinateFrame.
	elseif _type == "Instance" then
		local DebugIDMatch  = nil	-- By default, this function will store the equivalent of "nil" if nothing's found.
		for i , v in pairs(DebugIDList) do	-- Iterate through the debug ID list and try to find this instance's ID within it.
			if v == _value then
				DebugIDMatch = i	-- If a match is found, we'll use that in place of a proper Instance reference.
				break
			end
		end
		
		return DebugIDMatch	-- If this instance's debug ID wasn't found, this will store "nil" instead, which should be fine.
	elseif _type == "PhysicalProperties" then
		return {
			_value.Density,
			_value.Friction,
			_value.Elasticity,
			_value.FrictionWeight,
			_value.ElasticityWeight
		}
	elseif _type == "Faces" then	-- Create a list filled with Enum.FaceId values that can be passed to Faces.new() to reconstruct it.
		local __value  = nil
		local FaceIdList	= {}
		if __value.Top then table.insert(FaceIdList, 1) end
		if __value.Bottom then table.insert(FaceIdList, 4) end
		if __value.Left then table.insert(FaceIdList, 3) end
		if __value.Right then table.insert(FaceIdList, 0) end
		if __value.Back then table.insert(FaceIdList, 2) end
		if __value.Front then table.insert(FaceIdList, 5) end
		return FaceIdList
	end
end

--[[
	Roblox2Lua
	----------
	
	This code was generated using
	Deluct's Roblox2Lua plugin.
]]--

--// Instances

local xane_mdlrecreator_gui = Instance.new("ScreenGui")
xane_mdlrecreator_gui.IgnoreGuiInset = false
xane_mdlrecreator_gui.ResetOnSpawn = true
xane_mdlrecreator_gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
xane_mdlrecreator_gui.Name = "XaneMDLRecreatorGUI"
xane_mdlrecreator_gui:SetAttribute("XaneProtectedDoNotShowInReconstructorGui",true)	-- Hide this instance from the Reconstructor script itself.
xane_mdlrecreator_gui.Parent = game:GetService("CoreGui")

-- TOP BUTTONS (HIDE & CANCEL BUTTONS)
local toggle_frame = Instance.new("Frame")
toggle_frame.AnchorPoint = Vector2.new(0.5, 0)
toggle_frame.BackgroundTransparency = 1
toggle_frame.BorderSizePixel = 0
toggle_frame.Position = UDim2.new(0.5, 0, 0.0625, 0)
toggle_frame.Size = UDim2.new(0.25, 0, 0.09375, 0)
toggle_frame.SizeConstraint = Enum.SizeConstraint.RelativeYY
toggle_frame.Visible = true
toggle_frame.Name = "ToggleFrame"
toggle_frame.Parent = xane_mdlrecreator_gui

local toggle_list_layout = Instance.new("UIListLayout")
toggle_list_layout.Name = "ToggleBtnList"
toggle_list_layout.FillDirection = Enum.FillDirection.Horizontal
toggle_list_layout.Padding = UDim.new(0.001,0)
toggle_list_layout.Parent = toggle_frame

local toggle_button = Instance.new("TextButton")
toggle_button.Font = Enum.Font.RobotoCondensed
toggle_button.Text = "Save Instances!"
toggle_button.TextColor3 = Color3.new(1, 1, 1)
toggle_button.TextScaled = true
toggle_button.TextSize = 14
toggle_button.TextStrokeTransparency = 0
toggle_button.TextWrapped = true
-- toggle_button.AnchorPoint = Vector2.new(0.5, 0.5)
toggle_button.BackgroundColor3 = Color3.new(0.882353, 0.756863, 0.615686)
toggle_button.BorderColor3 = Color3.new(0, 0, 0)
toggle_button.BorderSizePixel = 0
-- toggle_button.Position = UDim2.new(0.5, 0, 0.5, 0)
toggle_button.Size = UDim2.fromScale(0.5, 1)
toggle_button.LayoutOrder = 1
toggle_button.Visible = true
toggle_button.Name = "ToggleButton"
toggle_button.Parent = toggle_frame

local clear_button = Instance.new("TextButton")
clear_button.Font = Enum.Font.RobotoCondensed
clear_button.Text = "Clear Selection"
clear_button.TextColor3 = Color3.new(1, 1, 1)
clear_button.TextScaled = true
clear_button.TextSize = 14
clear_button.TextStrokeTransparency = 0
clear_button.TextWrapped = true
-- clear_button.AnchorPoint = Vector2.new(0.5, 0.5)
clear_button.BackgroundColor3 = Color3.new(0.882353, 0.623529, 0.686275)
clear_button.BorderColor3 = Color3.new(0, 0, 0)
clear_button.BorderSizePixel = 0
-- clear_button.Position = UDim2.new(0.5, 0, 0.5, 0)
clear_button.Size = UDim2.fromScale(0.5, 1)
clear_button.LayoutOrder = 2
clear_button.Visible = false
clear_button.Name = "ClearButton"
clear_button.Parent = toggle_frame

local uicorner = Instance.new("UICorner")
uicorner.CornerRadius = UDim.new(0.125, 0)
uicorner.Parent = toggle_button

-- THE MAIN WINDOW
local main_frame = Instance.new("Frame")
main_frame.AnchorPoint = Vector2.one / 2
main_frame.BackgroundColor3 = Color3.new(0.219608, 0.321569, 0.627451)
main_frame.BackgroundTransparency = 0.25
main_frame.BorderColor3 = Color3.new(0, 0, 0)
main_frame.BorderSizePixel = 0
main_frame.Position = UDim2.fromScale(0.5, 1.75)	-- This Frame starts off-screen, revealed by clicking the toggle button at the top of the screen.
main_frame.Size = UDim2.fromScale(0.75, 0.725)
main_frame.Visible = true
main_frame.ZIndex = 2
main_frame.Name = "MainFrame"
main_frame.Parent = xane_mdlrecreator_gui

local uicorner_2 = Instance.new("UICorner")
uicorner_2.CornerRadius = UDim.new(0.025, 0)
uicorner_2.Parent = main_frame

--- STATUS MESSAGE
local message = Instance.new("TextLabel")
message.Font = Enum.Font.Gotham
message.Text = DefaultMessage
message.TextColor3 = Color3.new(1, 1, 1)
message.TextScaled = true
message.TextSize = 14
message.TextStrokeTransparency = 0
message.TextWrapped = true
message.AutomaticSize = Enum.AutomaticSize.Y
message.BackgroundColor3 = Color3.new(1, 1, 1)
message.BackgroundTransparency = 1
message.BorderColor3 = Color3.new(0, 0, 0)
message.BorderSizePixel = 0
message.LayoutOrder = 2
message.Size = UDim2.new(1, 0, 0.0625, 0)
message.Visible = true
message.Name = "Message"
message.Parent = main_frame

local uitext_size_constraint = Instance.new("UITextSizeConstraint")
uitext_size_constraint.MaxTextSize = 24
uitext_size_constraint.MinTextSize = 8
uitext_size_constraint.Parent = message

local top_bar = Instance.new("Frame")
top_bar.AnchorPoint = Vector2.xAxis / 2
top_bar.BackgroundTransparency = 1
top_bar.BorderSizePixel = 0
top_bar.LayoutOrder = 1
top_bar.Position = UDim2.new(0.5, 0, 0, 4)
top_bar.Size = UDim2.new(1,-8, 0.094,0)
top_bar.Visible = true
top_bar.Name = "TopBar"
top_bar.Parent = main_frame

local topbar_layout = Instance.new("UIListLayout")
topbar_layout.HorizontalFlex = Enum.UIFlexAlignment.None
topbar_layout.Padding = UDim.new(0, 4)
topbar_layout.FillDirection = Enum.FillDirection.Horizontal
topbar_layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
topbar_layout.SortOrder = Enum.SortOrder.LayoutOrder
topbar_layout.Parent = top_bar

-- CONTAINER BUTTONS
local container1 = Instance.new("TextButton")
container1.Font = Enum.Font.RobotoCondensed
container1.Text = "🌎Workspace"
container1.TextColor3 = Color3.new(1, 1, 1)
container1.TextScaled = true
container1.TextSize = 14
container1.TextStrokeTransparency = 0
container1.TextWrapped = true
container1.Modal = true
container1.AutomaticSize = Enum.AutomaticSize.X
container1.BackgroundColor3 = Color3.new(0.596078, 0.921569, 0.921569)
container1.BorderColor3 = Color3.new(0, 0, 0)
container1.BorderSizePixel = 0
container1.LayoutOrder = 1
container1.Size = UDim2.fromScale(0.125,1)
container1.SizeConstraint = Enum.SizeConstraint.RelativeXY
container1.Visible = true
container1.Name = "Container1"
container1.Parent = top_bar

local uitext_size_constraint_2 = Instance.new("UITextSizeConstraint")
uitext_size_constraint_2.MaxTextSize = 24
uitext_size_constraint_2.MinTextSize = 6
uitext_size_constraint_2.Parent = container1

local container4 = Instance.new("TextButton")
container4.Font = Enum.Font.RobotoCondensed
container4.Text = "📦ReplicatedStorage"
container4.TextColor3 = Color3.new(1, 1, 1)
container4.TextScaled = true
container4.TextSize = 14
container4.TextStrokeTransparency = 0
container4.TextWrapped = true
container4.Modal = true
container4.AutomaticSize = Enum.AutomaticSize.X
container4.BackgroundColor3 = Color3.new(0.596078, 0.921569, 0.921569)
container4.BorderColor3 = Color3.new(0, 0, 0)
container4.BorderSizePixel = 0
container4.LayoutOrder = 4
container4.Size = UDim2.fromScale(0.125,1)
container4.SizeConstraint = Enum.SizeConstraint.RelativeXY
container4.Visible = true
container4.Name = "Container4"
container4.Parent = top_bar

local uitext_size_constraint_3 = Instance.new("UITextSizeConstraint")
uitext_size_constraint_3.MaxTextSize = 24
uitext_size_constraint_3.MinTextSize = 6
uitext_size_constraint_3.Parent = container4

local container3 = Instance.new("TextButton")
container3.Font = Enum.Font.RobotoCondensed
container3.Text = "🌟Lighting"
container3.TextColor3 = Color3.new(1, 1, 1)
container3.TextScaled = true
container3.TextSize = 14
container3.TextStrokeTransparency = 0
container3.TextWrapped = true
container3.Modal = true
container3.AutomaticSize = Enum.AutomaticSize.X
container3.BackgroundColor3 = Color3.new(0.596078, 0.921569, 0.921569)
container3.BorderColor3 = Color3.new(0, 0, 0)
container3.BorderSizePixel = 0
container3.LayoutOrder = 3
container3.Size = UDim2.fromScale(0.125,1)
container3.SizeConstraint = Enum.SizeConstraint.RelativeXY
container3.Visible = true
container3.Name = "Container3"
container3.Parent = top_bar

local uitext_size_constraint_4 = Instance.new("UITextSizeConstraint")
uitext_size_constraint_4.MaxTextSize = 24
uitext_size_constraint_4.MinTextSize = 6
uitext_size_constraint_4.Parent = container3

local container2 = Instance.new("TextButton")
container2.Font = Enum.Font.RobotoCondensed
container2.Text = "👥Players"
container2.TextColor3 = Color3.new(1, 1, 1)
container2.TextScaled = true
container2.TextSize = 14
container2.TextStrokeTransparency = 0
container2.TextWrapped = true
container2.Modal = true
container2.AutomaticSize = Enum.AutomaticSize.X
container2.BackgroundColor3 = Color3.new(0.596078, 0.921569, 0.921569)
container2.BorderColor3 = Color3.new(0, 0, 0)
container2.BorderSizePixel = 0
container2.LayoutOrder = 2
container2.Size = UDim2.fromScale(0.125,1)
container2.SizeConstraint = Enum.SizeConstraint.RelativeXY
container2.Visible = true
container2.Name = "Container2"
container2.Parent = top_bar

local container5 = Instance.new("TextButton")
container5.Font = Enum.Font.RobotoCondensed
container5.Text = "🕺🏼Characters"
container5.TextColor3 = Color3.new(1, 1, 1)
container5.TextScaled = true
container5.TextSize = 14
container5.TextStrokeTransparency = 0
container5.TextWrapped = true
container5.Modal = true
container5.AutomaticSize = Enum.AutomaticSize.X
container5.BackgroundColor3 = Color3.new(0.596078, 0.921569, 0.921569)
container5.BorderColor3 = Color3.new(0, 0, 0)
container5.BorderSizePixel = 0
container5.LayoutOrder = 0
container5.Size = UDim2.fromScale(0.1,1)
container5.SizeConstraint = Enum.SizeConstraint.RelativeXY
container5.Visible = true
container5.Name = "Container5"
container5.Parent = top_bar

local uitext_size_constraint_5 = Instance.new("UITextSizeConstraint")
uitext_size_constraint_5.MaxTextSize = 24
uitext_size_constraint_5.MinTextSize = 6
uitext_size_constraint_5.Parent = container2

local uilist_layout_2 = Instance.new("UIListLayout")
uilist_layout_2.Padding = UDim.new(0, 4)
uilist_layout_2.VerticalFlex = Enum.UIFlexAlignment.Fill
uilist_layout_2.HorizontalAlignment = Enum.HorizontalAlignment.Center
uilist_layout_2.SortOrder = Enum.SortOrder.LayoutOrder
uilist_layout_2.Parent = main_frame

local instance_list = Instance.new("ScrollingFrame")
instance_list.AutomaticCanvasSize = Enum.AutomaticSize.Y
instance_list.CanvasSize = UDim2.new(0, 0, 0, 0)
instance_list.BackgroundColor3 = Color3.new(1, 1, 1)
instance_list.BackgroundTransparency = 1
instance_list.BorderColor3 = Color3.new(0, 0, 0)
instance_list.BorderSizePixel = 0
instance_list.LayoutOrder = 3
instance_list.Size = UDim2.new(1, 0, 0.675, 0)
instance_list.Visible = true
instance_list.Name = "InstanceList"
instance_list.Parent = main_frame

local uilist_layout_3 = Instance.new("UIListLayout")
uilist_layout_3.Padding = UDim.new(0, 8)
uilist_layout_3.HorizontalAlignment = Enum.HorizontalAlignment.Center
uilist_layout_3.SortOrder = Enum.SortOrder.LayoutOrder
uilist_layout_3.Parent = instance_list

-- "EXPLORER" ROW TEMPLATE
local template_entry = Instance.new("Frame")
template_entry.BackgroundColor3 = Color3.new(1, 1, 1)
template_entry.BackgroundTransparency = 0.875
template_entry.BorderColor3 = Color3.new(0, 0, 0)
template_entry.BorderSizePixel = 0
template_entry.Size = UDim2.new(1, 0, 0.0925, 0)
template_entry.Visible = false
template_entry.Name = "TemplateEntry"
template_entry.Parent = instance_list

local checkbox_button = Instance.new("TextButton")
checkbox_button.Font = Enum.Font.SourceSans
checkbox_button.Text = "❗"
checkbox_button.TextColor3 = Color3.new(0, 0, 0)
checkbox_button.TextScaled = true
checkbox_button.TextSize = 14
checkbox_button.TextWrapped = true
checkbox_button.Modal = true
checkbox_button.BackgroundColor3 = Color3.new(1, 1, 1)
checkbox_button.BackgroundTransparency = 1
checkbox_button.BorderColor3 = Color3.new(0, 0, 0)
checkbox_button.BorderSizePixel = 0
checkbox_button.LayoutOrder = 2
checkbox_button.Size = UDim2.new(1, 0, 1, 0)
checkbox_button.SizeConstraint = Enum.SizeConstraint.RelativeYY
checkbox_button.Visible = true
checkbox_button.Name = "SelectButton"
checkbox_button.Parent = template_entry

local uilist_layout_4 = Instance.new("UIListLayout")
uilist_layout_4.HorizontalFlex = Enum.UIFlexAlignment.None
uilist_layout_4.FillDirection = Enum.FillDirection.Horizontal
uilist_layout_4.SortOrder = Enum.SortOrder.LayoutOrder
uilist_layout_4.Parent = template_entry

local indent = Instance.new("Frame")
indent.BackgroundColor3 = Color3.new(1, 1, 1)
indent.BackgroundTransparency = 1
indent.BorderSizePixel = 0
indent.LayoutOrder = 1
indent.Size = UDim2.fromScale(0.01825, 1)
indent.Visible = false
indent.Name = "Indent"
indent.Parent = template_entry

local indent_outline = Instance.new("UIStroke")
indent_outline.Color = Color3.new(0.825,0.933,1)
indent_outline.Transparency = 0.725
indent_outline.Thickness = 1
indent_outline.Parent = indent

local inst_name = Instance.new("TextLabel")
inst_name.Font = Enum.Font.RobotoCondensed
inst_name.Text = "Template Row"
inst_name.TextColor3 = Color3.new(1, 1, 1)
inst_name.TextScaled = true
inst_name.TextSize = 14
inst_name.TextStrokeTransparency = 0
inst_name.TextWrapped = true
inst_name.TextXAlignment = Enum.TextXAlignment.Left
inst_name.BackgroundColor3 = Color3.new(1, 1, 1)
inst_name.BackgroundTransparency = 1
inst_name.BorderColor3 = Color3.new(0, 0, 0)
inst_name.BorderSizePixel = 0
inst_name.LayoutOrder = 3
inst_name.Size = UDim2.fromScale(0.75, 1)
inst_name.Visible = true
inst_name.Name = "InstName"
inst_name.Parent = template_entry

local uitext_size_constraint_6 = Instance.new("UITextSizeConstraint")
uitext_size_constraint_6.MaxTextSize = 28
uitext_size_constraint_6.MinTextSize = 6
uitext_size_constraint_6.Parent = inst_name

local cam_action_btn = Instance.new("TextButton")
cam_action_btn.Font = Enum.Font.SourceSans
cam_action_btn.Text = "📸"
cam_action_btn.TextColor3 = Color3.new(0, 0, 0)
cam_action_btn.TextScaled = true
cam_action_btn.TextSize = 14
cam_action_btn.TextWrapped = true
cam_action_btn.Modal = true
cam_action_btn.BackgroundColor3 = Color3.new(1, 1, 1)
cam_action_btn.BackgroundTransparency = 1
cam_action_btn.BorderColor3 = Color3.new(0, 0, 0)
cam_action_btn.BorderSizePixel = 0
cam_action_btn.LayoutOrder = 4
cam_action_btn.Size = UDim2.new(1, 0, 1, 0)
cam_action_btn.SizeConstraint = Enum.SizeConstraint.RelativeYY
cam_action_btn.Visible = true
cam_action_btn.Name = "CamActionButton"
cam_action_btn.Parent = template_entry

local cam_revert_btn = Instance.new("TextButton")
cam_revert_btn.Font = Enum.Font.SourceSans
cam_revert_btn.Text = "🔁"
cam_revert_btn.TextColor3 = Color3.new(0, 0, 0)
cam_revert_btn.TextTransparency = 1	-- This button was going to be used, but now its functions are handled by the "camera" button to its left.
cam_revert_btn.TextScaled = true
cam_revert_btn.TextSize = 14
cam_revert_btn.TextWrapped = true
cam_revert_btn.Modal = true
cam_revert_btn.BackgroundColor3 = Color3.new(1, 1, 1)
cam_revert_btn.BackgroundTransparency = 1
cam_revert_btn.BorderColor3 = Color3.new(0, 0, 0)
cam_revert_btn.BorderSizePixel = 0
cam_revert_btn.LayoutOrder = 5
cam_revert_btn.Size = UDim2.new(1, 0, 1, 0)
cam_revert_btn.SizeConstraint = Enum.SizeConstraint.RelativeYY
cam_revert_btn.Visible = true
cam_revert_btn.Name = "CamRevertButton"
cam_revert_btn.Parent = template_entry

-- BOTTOM BAR (PAGINATION BUTTONS, NAME ENTRY, AND SAVE BUTTON)
local bot_bar = Instance.new("Frame")
bot_bar.AnchorPoint = Vector2.new(0.5,1)
bot_bar.BackgroundTransparency = 1
bot_bar.BorderSizePixel = 0
bot_bar.LayoutOrder = 4
bot_bar.Position = UDim2.new(0.5, 0, 0, -4)
bot_bar.Size = UDim2.new(1,-8, 0.094,0)
bot_bar.Visible = true
bot_bar.Name = "BottomBar"
bot_bar.Parent = main_frame

local botbar_layout = Instance.new("UIListLayout")
botbar_layout.HorizontalFlex = Enum.UIFlexAlignment.None
botbar_layout.Padding = UDim.new(0, 4)
botbar_layout.FillDirection = Enum.FillDirection.Horizontal
botbar_layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
botbar_layout.SortOrder = Enum.SortOrder.LayoutOrder
botbar_layout.Parent = bot_bar

local prevPageButton = Instance.new("TextButton")
prevPageButton.Font = Enum.Font.RobotoCondensed
prevPageButton.Text = "◀ Prev"
prevPageButton.TextColor3 = Color3.new(1, 1, 1)
prevPageButton.TextScaled = true
prevPageButton.TextSize = 14
prevPageButton.TextStrokeTransparency = 0
prevPageButton.TextWrapped = true
prevPageButton.Modal = true
prevPageButton.AutomaticSize = Enum.AutomaticSize.X
prevPageButton.BackgroundColor3 = Color3.new(0.596078, 0.921569, 0.921569)
prevPageButton.BorderColor3 = Color3.new(0, 0, 0)
prevPageButton.BorderSizePixel = 0
prevPageButton.LayoutOrder = 1
prevPageButton.Size = UDim2.fromScale(0.1125,1)
prevPageButton.SizeConstraint = Enum.SizeConstraint.RelativeXY
prevPageButton.Visible = true
prevPageButton.Name = "PrevPage"
prevPageButton.Parent = bot_bar

local prevPageBtnSizeConstraint = Instance.new("UITextSizeConstraint")
prevPageBtnSizeConstraint.MaxTextSize = 24
prevPageBtnSizeConstraint.MinTextSize = 6
prevPageBtnSizeConstraint.Parent = prevPageButton

local nextPageButton = Instance.new("TextButton")
nextPageButton.Font = Enum.Font.RobotoCondensed
nextPageButton.Text = "Next ▶"
nextPageButton.TextColor3 = Color3.new(1, 1, 1)
nextPageButton.TextScaled = true
nextPageButton.TextSize = 14
nextPageButton.TextStrokeTransparency = 0
nextPageButton.TextWrapped = true
nextPageButton.Modal = true
nextPageButton.AutomaticSize = Enum.AutomaticSize.X
nextPageButton.BackgroundColor3 = Color3.new(0.596078, 0.921569, 0.921569)
nextPageButton.BorderColor3 = Color3.new(0, 0, 0)
nextPageButton.BorderSizePixel = 0
nextPageButton.LayoutOrder = 2
nextPageButton.Size = UDim2.fromScale(0.1125,1)
nextPageButton.SizeConstraint = Enum.SizeConstraint.RelativeXY
nextPageButton.Visible = true
nextPageButton.Name = "NextPage"
nextPageButton.Parent = bot_bar

local nextPageBtnSizeConstraint = Instance.new("UITextSizeConstraint")
nextPageBtnSizeConstraint.MaxTextSize = 24
nextPageBtnSizeConstraint.MinTextSize = 6
nextPageBtnSizeConstraint.Parent = nextPageButton

local PoseCharCheckbox = Instance.new("TextButton")
PoseCharCheckbox.Font = Enum.Font.RobotoCondensed
PoseCharCheckbox.Text = "💃🏼Ignore characters"
PoseCharCheckbox.TextColor3 = Color3.new(1, 1, 1)
PoseCharCheckbox.TextScaled = true
PoseCharCheckbox.TextSize = 14
PoseCharCheckbox.TextStrokeTransparency = 0
PoseCharCheckbox.TextWrapped = true
PoseCharCheckbox.Modal = true
PoseCharCheckbox.AutomaticSize = Enum.AutomaticSize.X
PoseCharCheckbox.BackgroundColor3 = Color3.new(0.596078, 0.921569, 0.921569)
PoseCharCheckbox.BorderColor3 = Color3.new(0, 0, 0)
PoseCharCheckbox.BorderSizePixel = 0
PoseCharCheckbox.LayoutOrder = 3
PoseCharCheckbox.Size = UDim2.fromScale(0.2,1)
PoseCharCheckbox.SizeConstraint = Enum.SizeConstraint.RelativeXY
PoseCharCheckbox.Visible = true
PoseCharCheckbox.Name = "CBox_PoseChars"
PoseCharCheckbox.Parent = bot_bar

local pose_chars_size_constraint = Instance.new("UITextSizeConstraint")
pose_chars_size_constraint.MaxTextSize = 24
pose_chars_size_constraint.MinTextSize = 6
pose_chars_size_constraint.Parent = PoseCharCheckbox

-- JSON MODEL NAME ENTRY FIELD/TEXTBOX
local filename_box = Instance.new("TextBox")
filename_box.Font = Enum.Font.Ubuntu
filename_box.PlaceholderColor3 = Color3.new(0.239216, 0.392157, 0.290196)
filename_box.PlaceholderText = "What should this be called?"
filename_box.Text = ""
filename_box.TextColor3 = Color3.new(0.317647, 0.231373, 0.490196)
filename_box.TextScaled = true
filename_box.TextSize = 14
filename_box.TextStrokeColor3 = Color3.new(0.317647, 0.231373, 0.490196)
filename_box.TextStrokeTransparency = 0.5
filename_box.TextWrapped = true
filename_box.BackgroundColor3 = Color3.new(0.654902, 0.788235, 0.980392)
filename_box.BorderColor3 = Color3.new(0, 0, 0)
filename_box.BorderSizePixel = 0
filename_box.LayoutOrder = 6
filename_box.Position = UDim2.new(0, 4, 0, 4)
filename_box.Size = UDim2.fromScale(0.175,1)
filename_box.SizeConstraint = Enum.SizeConstraint.RelativeXY
filename_box.Visible = true
filename_box.ZIndex = 2
filename_box.Name = "FilenameBox"
filename_box.Parent = bot_bar

local uicorner_3 = Instance.new("UICorner")
uicorner_3.CornerRadius = UDim.new(0.22499999403953552, 0)
uicorner_3.Parent = filename_box

local label = Instance.new("TextLabel")
label.Font = Enum.Font.FredokaOne
label.Text = "JSON filename:"
label.TextColor3 = Color3.new(0.811765, 1, 0.431373)
label.TextScaled = true
label.TextSize = 14
label.TextStrokeColor3 = Color3.new(0.266667, 0.364706, 0.411765)
label.TextStrokeTransparency = 0
label.TextWrapped = true
label.TextXAlignment = Enum.TextXAlignment.Left
label.AnchorPoint = Vector2.new(0.5, 0)
label.BackgroundColor3 = Color3.new(1, 1, 1)
label.BackgroundTransparency = 1
label.BorderColor3 = Color3.new(0, 0, 0)
label.BorderSizePixel = 0
label.Position = UDim2.new(0.5, 4, -0.300000012, 0)
label.Size = UDim2.new(1, 0, 0.532999992, 0)
label.Visible = true
label.ZIndex = 2
label.Name = "Label"
label.Parent = filename_box

-- THE RH-ESQUE "3D" SAVE BUTTON
local save_button = Instance.new("TextButton")
save_button.Font = Enum.Font.Cartoon
save_button.Text = ""
save_button.TextColor3 = Color3.new(1, 1, 1)
save_button.TextScaled = true
save_button.TextSize = 14
save_button.TextWrapped = true
save_button.AnchorPoint = Vector2.new(1, 0)
save_button.BorderSizePixel = 0
save_button.LayoutOrder = 7
save_button.Position = UDim2.fromScale(0.125,1)
save_button.Size = UDim2.fromScale(0.125,1)
save_button.SizeConstraint = Enum.SizeConstraint.RelativeXY
save_button.Visible = true
save_button.Name = "SaveButton"
save_button.Parent = bot_bar

local uicorner_4 = Instance.new("UICorner")
uicorner_4.CornerRadius = UDim.new(0.125, 0)
uicorner_4.Parent = save_button

local button_top = Instance.new("TextLabel")
button_top.Font = Enum.Font.Cartoon
button_top.Text = "Save"
button_top.TextColor3 = Color3.new(1, 1, 1)
button_top.TextScaled = true
button_top.TextSize = 14
button_top.TextStrokeTransparency = 0
button_top.TextWrapped = true
button_top.AnchorPoint = Vector2.new(0.5, 1)
button_top.BackgroundColor3 = Color3.new(0.647059, 1, 0.678431)
button_top.BorderColor3 = Color3.new(0, 0, 0)
button_top.BorderSizePixel = 0
button_top.Position = UDim2.new(0.5, 0, 0.875, 0)
button_top.Selectable = true
button_top.Size = UDim2.new(1, 0, 1, 0)
button_top.Visible = true
button_top.ZIndex = 2
button_top.Name = "FakeTop"
button_top.Parent = save_button

local uicorner_5 = Instance.new("UICorner")
uicorner_5.CornerRadius = UDim.new(0.125, 0)
uicorner_5.Parent = button_top

local button_outline = Instance.new("UIStroke")
button_outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
button_outline.Color = Color3.new(0.388235, 0.705882, 0.627451)
button_outline.Thickness = 2
button_outline.Parent = button_top

local uigradient = Instance.new("UIGradient")
uigradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.new(0.752941, 0.752941, 0.752941)), ColorSequenceKeypoint.new(0.125, Color3.new(1, 1, 1)), ColorSequenceKeypoint.new(0.875, Color3.new(1, 1, 1)), ColorSequenceKeypoint.new(1, Color3.new(0.752941, 0.752941, 0.752941))})
uigradient.Parent = save_button

-- PROGRESS BOX (USED FOR INDEXING AND SAVING)
local progress_ui = Instance.new("TextLabel")
progress_ui.Font = Enum.Font.RobotoCondensed
progress_ui.Text = "Indexing instance\u{000D}\u{000A}56 / 203"
progress_ui.TextColor3 = Color3.new(1, 1, 1)
progress_ui.TextScaled = true
progress_ui.TextStrokeTransparency = 0
progress_ui.TextWrapped = true
progress_ui.AnchorPoint = Vector2.one / 2
progress_ui.BackgroundColor3 = Color3.new(0.161, 0.353, 0.224)
progress_ui.BackgroundTransparency = 0.25
progress_ui.BorderColor3 = Color3.new(0, 0, 0)
progress_ui.BorderSizePixel = 0
progress_ui.Position = UDim2.fromScale(0.5, 0.5)
progress_ui.Size = UDim2.fromScale(0.425, 0.225)
progress_ui.Visible = false
progress_ui.ZIndex = 3
progress_ui.Name = "ProgressUI"
progress_ui.Parent = xane_mdlrecreator_gui

local ui_aspectratio_progress = Instance.new("UIAspectRatioConstraint")
ui_aspectratio_progress.AspectRatio = 3.5
ui_aspectratio_progress.Parent = progress_ui

local uitextsize_progress = Instance.new("UITextSizeConstraint")
uitextsize_progress.MaxTextSize = 50
uitextsize_progress.MinTextSize = 10
uitextsize_progress.Parent = progress_ui

local uicorner_progress = Instance.new("UICorner")
uicorner_progress.CornerRadius = UDim.new(0.125, 0)
uicorner_progress.Parent = progress_ui

local template_selbox = Instance.new("SelectionBox")	-- A box that appears around any selected instances that support rendering it around them.
template_selbox.Name = "XaneSelBoxTemplate"
template_selbox.LineThickness = 0.03125
template_selbox.Transparency = 0.25
template_selbox.SurfaceTransparency = 0.925
template_selbox:SetAttribute("XaneProtectedDoNotShowInReconstructorGui",true)	-- Hide this instance from the Reconstructor script itself.
template_selbox.Parent = xane_mdlrecreator_gui

print("UI created!")

-- DATA FOR THE ANIMATED SAVE BUTTON
local Position_Raised		= UDim2.fromScale(0.5,0.875)
local Position_Pressed		= UDim2.fromScale(0.5,1)
local BtnColor_Ready		= Color3.fromRGB(160,255,224)	-- Save button colors.
local BtnColor_Caution		= Color3.fromRGB(212,255,204)	-- Used if the selected file already exists.
local BtnColor_Disabled		= Color3.fromRGB(126,128,130)	-- Used until a valid model and filename are entered.

local RowOpacityNormal		= 0.875
local RowOpacitySelected	= 0.75

local CurrentContainer		= nil

type VisibleListEntry		= {
	CheckboxClickEvent	: RBXScriptConnection,	-- Connection which lets the user (de)select this item. (This also updates its icon.)
	CameraFocusEvent	: RBXScriptConnection,	-- Click event for a button which makes the user's camera focus on this instance.
	CamRevertEvent1		: RBXScriptConnection,	-- Right-click event, which brings the camera back to the player.
	CamRevertEvent2		: RBXScriptConnection,	-- Alternative camera reverting event, for mobile devices (long tap).
	Instance			: Instance,				-- Reference to this instance, used to access its properties if needed.
	RowBase				: Frame,				-- A reference to this row's container Frame.
	Checkbox			: TextButton,			-- The toggle-box found at the left side of this row/entry.
	SelectBox			: SelectionBox,			-- This Instance's SelectionBox, which is created and destroyed as needed upon its selection.
	IsSelectAllRow		: boolean				-- If TRUE, selecting this row will deselect all instances within the selected container.
}

-- VARIABLES (SECOND SET)
local GUIShown				= true	-- This is set to TRUE when the main window is visible, used by the toggle button at the top of the screen.
local IsBusy				= false	-- Marks the main window as busy. This disables all buttons, so the script can execute code in peace.
local PoseCharacters		= nil	-- When this is "no", any selected character models will stop their animations before they're captured.

-- List of Instances' debug IDs that the user has marked for saving. Instance references could've been stored here, but this...seems cooler.
local Selection 
	= {}

-- An array of dictionary entries which keeps all of the events and references needed by each instance shown in the main UI list.
-- As creating too many rows will lag the client when the list updates (scrolling, generating, etc), this array should be limited to
-- 100 or so entries at any time.

-- The full list (which has less data in each entry) is InternalList below.
local ListData  = {}

local PageLength			= _G.PageLength or 100	-- How many instances should be listed at a time.
local AntiLagInterval		= _G.AntiLagInterval or 15	-- To reduce lag, intensive actions are paused on every Nth processed Instance.
local SkipPreSaveVerify		= _G.SkipPreSaveVerify or false	-- Skip the failsafe "last-minute indexing" before saving if something's missing?
local Offset				= 0		-- The current "page" of instances that are being shown to the user.
type InternalListEntry		= {
	Instance			: Instance,	-- Instance which this entry represents. Its class and name are used when generating the visible list.
	Level				: number	-- Represents the depth this instance was placed at in the hierarchy during the scan. 0 is the container itself.
}

-- The "actual" internal list of instances, which were found during the initial scan after clicking one of the "container" buttons.
-- To reduce lag, only a subset of this list is used at any time to generate the "visible list" (the ListData array). This array is wiped
-- when the UI is hidden and when switching between containers.

-- Entry 1 will always be a special entry which (de)selects the container itself.
local InternalList  = {}

-- An array of nested dictionary entries which contain any applicable properties of each supported instance. When a model is being
-- exported, the data gathered during the scan is put into this table. When multiple instances are exported at the same time, each
-- to-be JSON file's contents is exported from here, then this table is cleared before the next capture starts.
local OngoingExportData = {}

-- Roblox doesn't allow multiple copies of a container (workspace, ReplicatedStorage, etc.), so an "imposter" model is created for each of the
-- four selectable containers, used instead of one of them if an instance was formerly parented to one. This array links the actual containers'
-- debug IDs to the four fake Models; When an instance is captured, its parent is forcibly changed to one of these dummies if it matches any
-- of the containers' debug IDs.
local ContainerRedirections  = {}

-- Speaking of containers' imposters, let's create the four Models now then place them in ServerStorage, which is basically unused on the client.

-- Class names to treat as the forbidden containers. (Not used here.)
local ContainerList = { "Workspace", "Players", "Lighting", "ReplicatedStorage"}
for _,locat  in pairs({workspace,Players,Lighting,ReplicatedStorage}) do
	local dummyModel = Instance.new("Model", ServerStorage)
	dummyModel.Name = locat.Name
	ContainerRedirections[locat:GetDebugId()] = dummyModel:GetDebugId()
end

-- FUNCTIONS

--[[
	IsInstanceAllowed (takes Instance reference, returns boolean)
	Checks for some specific instances that shouldn't be saved, either because they cause softlocks/glitches or
	would be useless in the context of saving instances or places within experiences. Here are the reasons:
	
	Camera within workspace - This conflicts with Studio's editor camera, and isn't particularly useful.
	Character inside Player - Player character links are unstable, and usually lock up this script.
]]--
local function IsInstanceAllowed(_instance )
	if not _instance.Parent then return false
	elseif (_instance.Parent == workspace and _instance:IsA("Camera")) or
		(_instance.Parent:IsA("Player") and _instance.Name == "Character")
	then
		return false
	else return true
	end
end

local function ChangeButtonState(_release , _color , _text )
	if _text then button_top.Text = _text end
	if _color then
		button_top.BackgroundColor3 = _color
		local btnH, btnS, btnV = _color:ToHSV()

		button_outline.Color = Color3.fromHSV(btnH, btnS+(btnS/4), btnV-(btnV/6))
		save_button.BackgroundColor3 = Color3.fromHSV(btnH, btnS+(btnS/3), btnV-(btnV/4))
	end

	-- If the button is already in the same state as this command would change it to, stop the function here.
	if _release == save_button.Active then return nil
	else
		save_button.Active = _release	-- Immediately update whether the user can click on this button before playing the animation.
		button_top:TweenPosition(
			_release and Position_Raised or Position_Pressed,
			Enum.EasingDirection.InOut,
			Enum.EasingStyle.Quad,
			0.125,
			true
		)
		return nil
	end
end
-- Initially disable the save button.
ChangeButtonState(false, BtnColor_Disabled, "Can't save")

local function CheckSavePrerequisites()
	if filename_box.Text:len() > 0 and		-- Make sure the TextBox isn't empty and the filename doesn't contain invalid characters.
		not filename_box.Text:find("/") and
		not filename_box.Text:find("\"") and
		not filename_box.Text:find("\\") and
		not filename_box.Text:find(":") and
		not filename_box.Text:find("*") and
		not filename_box.Text:find("?") and
		#Selection > 0	-- Ensure the player has at least one Instance selected before letting them export.
	then
		local FileStatus = nil
		pcall(function()
			FileStatus = readfile(filename_box.Text .. "_header.json")
		end)
		if FileStatus then ChangeButtonState(true, BtnColor_Caution, "Overwrite")
		else ChangeButtonState(true, BtnColor_Ready, "Save!")
		end
	else ChangeButtonState(false, BtnColor_Disabled, "Can't save")
	end
	
	clear_button.Visible = #Selection > 0	-- A second button will appear at the top of the screen to deselect everything if anything's marked.
	message.Text = DefaultMessage
end

-- Looks through the "debug ID to instance" association list, trying to find an index named after the provided ID. If one is found, its associated
-- instance is returned.
local function GetInstanceFromDebugID(_id : string)
	local MatchedInst						= nil
	for ListID : string, inst in pairs(DebugIDList) do	-- Iterate through the debug ID list and try to find this instance's ID within it.
		if ListID == _id then
			MatchedInst						= inst
			break
		end
	end
	
	return MatchedInst
end

-- Very simply clears the list of debug IDs, used to get "persistent" instance references that survive exportation.
local function EmptyDebugIDCache()
	if #DebugIDList > 0 then table.clear(DebugIDList) end
end

-- Disconnects all events within the list shown in the main window, then removes all of its rows.
local function ClearVisibleList()
	if #ListData > 0 then
		for i,entry in ListData do
			-- Disconnect all of the button events' connections before destroying this row.
			if entry.CheckboxClickEvent then
				entry.CheckboxClickEvent:Disconnect()
				ListData[i].CheckboxClickEvent = nil
			end
			if entry.CameraFocusEvent then
				entry.CameraFocusEvent:Disconnect()
				ListData[i].CameraFocusEvent = nil
			end
			if entry.CamRevertEvent1 then
				entry.CamRevertEvent1:Disconnect()
				ListData[i].CamRevertEvent1 = nil
			end
			if entry.CamRevertEvent2 then
				entry.CamRevertEvent2:Disconnect()
				ListData[i].CamRevertEvent2 = nil
			end
			
			if entry.SelectBox then
				entry.SelectBox:Destroy()
				entry.SelectBox = nil
			end
			
			entry.Checkbox:Destroy()
			entry.Checkbox = nil
			
			entry.RowBase:Destroy()
			entry.RowBase = nil
		end
		
		table.clear(ListData)	-- Remove all of the now-useless entries from the array.
	end
end

-- Visually updates a given row to make it apppear to be (de)selected.
local function UpdateRowVisualState(_entry, _select)
	if _select then
		_entry.RowBase.BackgroundTransparency = RowOpacitySelected
		_entry.Checkbox.Text = "✅"
	else
		_entry.RowBase.BackgroundTransparency = RowOpacityNormal
		_entry.Checkbox.Text = ClassData[_entry.Instance.ClassName].ListView.Icon	-- Revert this checkbox's icon to the class icon.
	end
end

-- An important function, responsible for turning an Instance into data, which is later encoded as a JSON array/dictionary.
-- This function is also responsible for remapping/re-parenting direct children of containers to the fake "Models" found in
-- ServerStorage at runtime. Though there was a third argument to this function that made it remove the Instance's parent,
-- it has been removed; If an Instance references a debug ID with no cooresponding Instance, the Studio plugin should just
-- parent it to that container's "main model" (which is its counterpart to the "imposter" models).
local function CaptureInstance(_instance , _destination )
	local replacementParent  = nil
	local ParentDebugId  = nil
	
	-- Does this instance still have a parent? Usually, every instance should be parented, but as the Instance list is only generated
	-- on request (when the user taps on one of the container buttons), any of the Instances that they've chosen may have been removed
	-- by the game by the time they start trying to capture them! If this instance has a parent, try to get its debug ID for reference.
	if _instance.Parent then
		-- Check to see if this instance's parent is one of the four supported containers. We can't recreate these containers, so let's
		-- try to find a new "imposter" to parent it to.
		for oldId ,newId  in pairs(ContainerRedirections) do
			if _instance.Parent:GetDebugId() == oldId then	-- Looks like we have a match! Link it to this container's fake counterpart.
				replacementParent = newId	-- We'll save this instance with false metadata, linking it to the "wrong" Model.
				break
			end
		end
		
		-- Also, see if this Instance's parent has had its debug ID stored in that array. If it has, store that in a second variable.
		-- If the parent isn't a known container or a known instance in general, the property will be set to nil/"null" instead.
		for debugId , inst  in pairs(DebugIDList) do
			if _instance.Parent:GetDebugId() == debugId then	-- If a match is found, return that and stop iterating early.
				ParentDebugId = debugId
				break
			end
		end
	end
	local InstDictionary	= {	-- Every Instance has references to its name, class, debug ID, and its parent's debug ID.
		Name				= _instance.Name,
		ClassName			= _instance.ClassName,
		DebugId				= _instance:GetDebugId(),
		Parent				=	-- Assign this instance's parent based on if it has a replacement or has a parent.
			if replacementParent then replacementParent	-- Is this parented to a known container? Use the dummy Model's debug ID instead.
			elseif ParentDebugId then ParentDebugId		-- If not, has its parent in the debug ID database? Link to that here!
			else StoreValue(nil, "nil")					-- Otherwise, the parent's nil, so it'll be imported under this container's model.
	}
	-- print("Wrote basic property set for", _instance.Name, "whose parent is ID", InstDictionary.Parent)
	
	-- Additional properties specific to this class are added to this dictionary entry next. If a property's name starts
	-- with "UseCmnList_", a secondary list of properties is checked and added to this list.
	for property1 ,type1  in pairs(ClassData[_instance.ClassName].Props) do
		if property1:find("UseCmnList_") then
			-- print("This instance type uses a shared property list,", type1)
			-- print("Does that shared list exist?")
			if CommonPropList[type1] then
				for property2 , type2  in pairs(CommonPropList[type1]) do
					InstDictionary[property2] = StoreValue(_instance[property2], type2)
				end
			end
		else	-- If this is a property listed inline for this class, just try to store its value in the dictionary entry.
			InstDictionary[property1] = StoreValue(_instance[property1], type1)
			-- print("Property", property1, "found! Adding value to table as", InstDictionary[property1])
		end
	end
	
	-- Lastly, see if this Instance has any attributes and/or tags; These will be exported with in the instances' serialized JSON versins.
	local temp_attribList = _instance:GetAttributes()
	local temp_attribcount = 0	-- Figure out how many attributes this instance has.
	for _,_ in pairs(temp_attribList) do temp_attribcount += 1 end
	if temp_attribcount > 0 then
		InstDictionary.Attributes = {}	-- It has some? Create an empty dictionary entry, then store all of them in here.
		for name,value in pairs(temp_attribList) do
			InstDictionary.Attributes[name] = StoreValue(value, typeof(value))
		end
	end
	
	-- Are there any tags on this Instance? If there are, add them to a new sub-array like with attributes. (This time it's a basic array, though!)
	if #_instance:GetTags() > 0 then
		InstDictionary.Tags = {}
		for _,tag in pairs(_instance:GetTags()) do table.insert(InstDictionary.Tags, tag) end
	end
	
	_destination[#_destination+1] = InstDictionary
	return true
end

--[[
	One of the most important functions in the Model Reconstructor script! This function iterates through all of the children of
	an instance, recursively repeating the process as it advances deeper into the hierarchy, performing an action on every
	instance that it finds.
	
	If _mode is "list", every instance is added to the "explorer" list in the window. With "capture", it creates dictionary entries
	for each instance, adding them to _dest (a table). _level increases on every recursion, and determines where the next call
	will write its data to. Lastly, this just "caches" all instances' debug IDs within the specified Instance in "debug" mode.
]]--
local AntiLagInstCounter		= 0	-- A counter, which determines when ApplyChildAction() will wait for a frame to keep the client from completely freezing.
local ProgressVars					= {
	TotalInstances					= nil,	-- A count of all descendants of the selected container, used for the progress UI while indexing only.
	CurrentInstance					= 0,	-- When TotalInstances is setup, this represents how many Instances that ApplyChildAction has checked.
	ProcessVerb						= "Indexing"
}

local function ApplyChildAction(_base , _mode, _level, _dest )
	-- If a capture is just starting, capture the selected Instance itself as level 1, then everything within it as higher levels.
	-- This is pretty hackish, but it's debatably the best way to approach this scenario.
	-- If the base Instance is one of the four containers, it's ignored, only capturing the instances within it.
	if _mode == "capture" and _level <= 1 then
		-- print("Capturing base instance", _base:GetFullName())
		if not table.find(ContainerList, _base.ClassName) then CaptureInstance(_base, _dest) end
		_level += 1
		-- _dest = _dest[#_dest]
	end
	
	for num,inst  in pairs(_base:GetChildren()) do
		AntiLagInstCounter += 1	-- Always count Instances towards the anti-lag code; Lag is annoying (and risky for exploiters), y'know!
		if ProgressVars.TotalInstances then	-- If we're tracking all of the instances to show progress (in UI), increment the "current" counter.
			ProgressVars.CurrentInstance += 1
		end
		
		-- See if this Instance's class is supported by this script. If it isn't, ignore it and advance to the next one in line.
		if ClassData[inst.ClassName] and IsInstanceAllowed(inst) and
			not inst:GetAttribute("XaneProtectedDoNotShowInReconstructorGui")
		then
			-- "Cache" any Instances encountered by this script if they're supported. In "debug" mode, this is all this function does.
			if not table.find(DebugIDList, inst) then DebugIDList[inst:GetDebugId()] = inst end
			
			if _mode == "list" then	-- Log all supported instances to the instance list.
				local newEntry  = {
					Instance = inst,
					Level = _level
				}
				table.insert(InternalList, newEntry)
			elseif _mode == "capture" then
				CaptureInstance(inst, _dest)
				
				-- print("Added instance definition for", inst.Name, "!")
				--table.insert(_dest, InstDictionary)	-- Add this Instance's serialized form to the dictionary!
			end
			
			if AntiLagInstCounter % AntiLagInterval or 25 == 0 then task.wait() end	-- Wait a frame every so often.
			
			-- Does this instance have any child instances? Start a new instance of this function, checking those out for now.
			if #inst:GetChildren() > 0 then
				if _mode == "list" then
					ApplyChildAction(inst, "list", _level+1, nil)
				elseif _mode == "capture" then
					-- print("Destination is",_dest, "and current instance is", inst:GetFullName())
					-- print("It has",#_dest,"entries in it. The next recursion should write tis dictionary entries there.")
					ApplyChildAction(inst, "capture", _level+1, _dest)	-- _dest[#_dest])
				else ApplyChildAction(inst, "debug", _level+1, nil)
				end
			end
		elseif ProgressVars.TotalInstances then	-- If an Instance's skipped during indexing, still count all of its descendants in the count.
			local temp_descendants = #inst:GetDescendants()
			if temp_descendants > 0 then
				ProgressVars.CurrentInstance += temp_descendants
			end
		end
		
		-- Lastly, update the progress window's text, if it's currently needed (or relevant).
		if ProgressVars.TotalInstances then
			progress_ui.Text =
				ProgressVars.ProcessVerb.." instances...\u{000D}\u{000A}"..ProgressVars.CurrentInstance.." / "..ProgressVars.TotalInstances
		end
	end
end

-- An iffy function that does what ApplyChildAction()'s "list" mode used to do, only now in a for loop. It destroys the
-- current "visible list" then rebuilds it using data from the full, pre-generated internal instance list.
local function RedrawVisibleList()
	if #ListData > 0 then
		ClearVisibleList()
	end
	
	for i = (PageLength*Offset)+1, (PageLength*Offset)+PageLength-1 do
		-- Make sure we haven't reached the end of the list yet. If we have, stop creating entries now.
		if InternalList[i] then
			-- Make sure this Instance isn't a "bad actor" which could cause a softlock or wouldn't assist this export.
			if not IsInstanceAllowed(InternalList[i].Instance) then continue end
			
			-- If execution reaches this point, this Instance is supported, so let's add it to our temporary list!
			local NewEntry  = {
				Instance				= InternalList[i].Instance,
				RowBase					= template_entry:Clone(),
				Checkbox				= nil,
				CheckboxClickEvent		= nil,
				CameraFocusEvent		= nil,
				CamRevertEvent1			= nil,
				CamRevertEvent2			= nil
			}
			NewEntry.RowBase.Name		= "Listing_" .. i	-- Name each row's Frame after its ordering, just to make it easier for those sifting through UI instances.
			NewEntry.Checkbox			= NewEntry.RowBase:WaitForChild("SelectButton")
			
			local temp_instName			= NewEntry.RowBase:WaitForChild("InstName")
			
			-- Before continuing, determine how big a row should be in pixels rather than scale. Since executors are behind the times,
			-- they unfortyunately don't support Roblox's new CSS-esque flexible UI containers, so there isn't an easy way to make the
			-- "instance name" label fill the space the icon on the left side and camera button on the right side exactly. It's dumb!
			
			-- TODO: I just cannot get rows to be just long enough to squeeze the camera button onto the right edge of each row, regardless
			-- of indentation. For some reason, with or without a delay, AbsoluteSize is always 0, 0! I'm sorry for this awful alt. sizing...
			temp_instName.Size = UDim2.fromScale(1 - (indent.Size.X.Scale * InternalList[i].Level) - 0.0825,1)
			NewEntry.RowBase:WaitForChild("CamActionButton").AnchorPoint = Vector2.xAxis
			--[[
				task.wait()
				
				print("Row X scale was calculated as", 1 - (indent.Size.X.Scale * InternalList[i].Level))
				print("Just the subtracted value is", indent.Size.X.Scale * InternalList[i].Level)
				print("Absolute size is", temp_instName.AbsoluteSize)
				print("Final X size is somehow", temp_instName.AbsoluteSize.X-temp_instName.AbsoluteSize.Y)
				
				temp_instName.Size = UDim2.fromOffset(	-- Take the size determined above and subtract one square icon's size from it.
					temp_instName.AbsoluteSize.X-temp_instName.AbsoluteSize.Y,
					temp_instName.AbsoluteSize.Y
				)
			]]--
			
			temp_instName.Text = InternalList[i].Instance.Name
			local temp_newIndent = NewEntry.RowBase:WaitForChild("Indent")	-- Hold a reference to the original indent, which will be duplicated based on this instance's "level".
			temp_newIndent.Visible = InternalList[i].Level > 0
			if InternalList[i].Level > 1 then	-- If this Instance is at the second level or deeper, duplicate the indent as needed, forming a grid for clarity left of the list.
				for i = 2, InternalList[i].Level do
					local temp_additionalIndent = temp_newIndent:Clone()
					temp_additionalIndent.Parent = temp_newIndent.Parent
				end
			end
			
			NewEntry.Checkbox.Text = ClassData[InternalList[i].Instance.ClassName].ListView.Icon
			
			-- If this object has been previously selected, highlight it now.
			if table.find(Selection, InternalList[i].Instance:GetDebugId()) then
				UpdateRowVisualState(NewEntry, true)
			end
			
			NewEntry.RowBase.Visible = true
			
			-- Add functionality to the the two buttons found on the ends of this row.
			local temp_camButton  = NewEntry.RowBase:WaitForChild("CamActionButton")
			temp_camButton.Visible = ClassData[InternalList[i].Instance.ClassName].ListView.CanView ~= "no"
			if temp_camButton.Visible then
				NewEntry.CameraFocusEvent = temp_camButton.MouseButton1Click:Connect(function()
					if ClassData[InternalList[i].Instance.ClassName].ListView.CanView == "parent" then
						local temp_ancestor = InternalList[i].Instance:FindFirstAncestorWhichIsA("BasePart")
						if temp_ancestor then
							workspace.CurrentCamera.CameraSubject = temp_ancestor
						end
					elseif ClassData[InternalList[i].Instance.ClassName].ListView.CanView == "child" then
						local temp_child = InternalList[i].Instance:FindFirstChildWhichIsA("BasePart")
						if temp_child then
							workspace.CurrentCamera.CameraSubject = InternalList[i].Instance.Parent
						else
							-- Hide the camera button if nothing camera-compatible is found within this instance.
							NewEntry.RowBase:FindFirstChild("CamActionButton").Visible = false
						end
					else
						workspace.CurrentCamera.CameraSubject = InternalList[i].Instance
					end
				end)
				NewEntry.CamRevertEvent1 = temp_camButton.MouseButton2Click:Connect(function()
					workspace.CurrentCamera.CameraSubject = Players.LocalPlayer.Character:WaitForChild("Humanoid")
				end)
				NewEntry.CamRevertEvent2 = temp_camButton.TouchLongPress:Connect(function()
					workspace.CurrentCamera.CameraSubject = Players.LocalPlayer.Character:WaitForChild("Humanoid")
				end)
			end
			
			NewEntry.CheckboxClickEvent = NewEntry.Checkbox.MouseButton1Click:Connect(function()
				-- If this Instance is currently selected, remove it from the list and undo changes to this row on the list.
				local SelectionIndex	= table.find(Selection, InternalList[i].Instance:GetDebugId())
				if SelectionIndex then
					table.remove(Selection, SelectionIndex)
					UpdateRowVisualState(NewEntry, false)
					
					-- If this Instance is visually selected in-world, remove the box that's around it.
					if NewEntry.SelectBox then
						NewEntry.SelectBox:Destroy()
						NewEntry.SelectBox = nil	-- Make sure the other part of this mini-function knows that the box no longer exists.
					end
				else
					table.insert(Selection, InternalList[i].Instance:GetDebugId())
					
					UpdateRowVisualState(NewEntry, true)
					if InternalList[i].Level > 0 then	-- If the container itself was just selected, deselect anything within it.
						local SelectionDelQueue = {}	-- Keep track of the array indices that'll be removed after this for loop.
						local Cleared = false			-- The selection array will be endlessly checked until this flag is set to TRUE.
						while not Cleared do
							for i1,debugId in ipairs(Selection) do	-- For each selected Instance...
								local MatchedInstance = nil	-- ...try to to find an Instance with a matching debug ID!
								for i2,entry  in pairs(InternalList) do
									if debugId == entry.Instance:GetDebugId() then
										MatchedInstance = entry.Instance
										break
									end
								end
								
								if MatchedInstance and MatchedInstance:IsDescendantOf(InternalList[i].Instance) then
									table.remove(Selection, i1)	-- The table.remove() function messes up arrays' orders, so let's start over...
									break
								elseif i1 >= #Selection and not Cleared then
									Cleared = true	-- Without this action, the while loop would force this for loop to completely restart.
								end
							end
						end
						Cleared = false
					end
					
					-- Also, create a SelectionBox for this instance, to make it easier to tell what has been selected in messy games (like Royale High).
					-- Only do this for child instances within the workspace, and obviously, don't draw a box around the workspace itself.
					if InternalList[i].Level > 0 and InternalList[i].Instance:IsDescendantOf(workspace) and not NewEntry.SelectBox then
						NewEntry.SelectBox					= template_selbox:Clone()
						NewEntry.SelectBox.Color3			= Color3.fromHSV(math.random(), 0.125+(math.random()/5), 1-(math.random()/16))	-- Use a random color.
						NewEntry.SelectBox.SurfaceColor3	= NewEntry.SelectBox.Color3
						NewEntry.SelectBox.Adornee			= InternalList[i].Instance
						NewEntry.SelectBox.Parent			= InternalList[i].Instance
					end
				end
				
				CheckSavePrerequisites()	-- If the user's entered a filename and has at least one instance selected, allow them to start exporting things!
			end)
			
			NewEntry.RowBase.Parent = instance_list
			table.insert(ListData, NewEntry)
		else break
		end
	end
end

-- Slides the main window on/off the screen. Normally, this is prevented when anything important is happening, but _force will bypass restrictions.
local function ToggleUI(_force )
	if not IsBusy or _force then
		if GUIShown then
			IsBusy = true
			toggle_button.Text = "Save Instances!"
			toggle_button.BackgroundColor3 = BtnColor_Ready
			main_frame:TweenPosition(UDim2.fromScale(0.5, 2.0), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 0.333, true)
			task.wait(0.125)
			IsBusy = false
		else
			IsBusy = true
			toggle_button.Text = "Hide GUI"
			toggle_button.BackgroundColor3 = BtnColor_Caution
			main_frame:TweenPosition(UDim2.fromScale(0.5, 0.55), Enum.EasingDirection.Out, Enum.EasingStyle.Back, 0.35, true)
			task.wait(0.35)
			IsBusy = false
		end
		
		GUIShown = not GUIShown
	end
end
toggle_button.MouseButton1Click:Connect(function() ToggleUI(false) end)
ToggleUI(false)

local function ChangeListSource(_base )
	if not IsBusy then
		IsBusy = true	-- Disable all interface buttons until the list has been updated. (Hopefully, no errors occur!)
		ToggleUI(false)
		
		if #ListData > 0 then ClearVisibleList() end
		if #InternalList > 0 then table.clear(InternalList) end
		
		-- Set up and show the "indexing progress" UI, which will be updated by ApplyChildAction(), so the user isn't left in the dark.
		ProgressVars.TotalInstances = #_base:GetDescendants()
		ProgressVars.CurrentInstance = 0
		ProgressVars.ProcessVerb = "Indexing"
		progress_ui.Visible = true	-- For now, make the UI pop up rather than sliding in like the other frames would.
		
		ApplyChildAction(_base, "list", 1, nil)	-- Generate the full list of Instances within the new container.
		table.insert(InternalList, 1, {	-- Slip a fake entry for the container itself into the start of the list.
			Instance = _base,
			Level = 0
		})
		-- If the new container hasn't had its debug ID added to that list, it could lead to errors when saving Instances to files.
		-- Quickly associate this  container with its debug ID if one doesn't already exist.
		if not table.find(DebugIDList, _base) then
			DebugIDList[_base:GetDebugId()] = _base
		end
		
		progress_ui.Visible = false	-- Hide the progress UI; We're about to display the list that was just generated.
		Offset = 0					-- Always start from the beginning of a container's Instance list.
		RedrawVisibleList()
		task.wait(0.425)
		
		ToggleUI(false)
		IsBusy = false
	end
end
container1.MouseButton1Click:Connect(function() ChangeListSource(workspace) end)
container2.MouseButton1Click:Connect(function() ChangeListSource(Players) end)
container3.MouseButton1Click:Connect(function() ChangeListSource(Lighting) end)
container4.MouseButton1Click:Connect(function() ChangeListSource(ReplicatedStorage) end)

-- "Container 5" is a special case; Rather than indexing every instance within a container, it specifically tries to find each player's
-- character model and indexes ITS contents. If playing Royale High, its EquippedStorage folder is checked for and also indexed.
local function IndexCharacters(_includeNPCs)
	if not IsBusy then
		IsBusy = true	-- Disable all interface buttons until the list has been updated. (Hopefully, no errors occur!)
		ToggleUI(false)
		
		-- Clear the full and visible lists if they're already occupied by another container button's instances.
		if #ListData > 0 then ClearVisibleList() end
		if #InternalList > 0 then table.clear(InternalList) end
		
		for _,player in pairs(Players:GetPlayers()) do
			local PlayerChar			= player.Character	-- Try to access this player's character model.
			if not PlayerChar then							-- If it hasn't been created yet, retry a couple of times, then give up.
				local CharTries			= 10
				local success			= false
				while CharTries > 0 do
					success, _ = pcall(function()
						PlayerChar = player.Character
					end)
					if success then break end				-- Did we find it? Let's move on!
					task.wait(0.25)
					CharTries -= 1
				end
				
				if not PlayerChar then continue end			-- If their character is still inaccessible, just move on to the next player.
			end
			
			-- If execution reaches this point, we have a player character to index!
			
			-- Unlike every other "mode", we won't be listing every instance within character models to save time; A player could leave the
			-- server within a minute, after all! Just index the character models directly.
			table.insert(InternalList, {
				Instance = PlayerChar,
				Level = 1
			})
			
			-- If the new container hasn't had its debug ID added to that list, it could lead to errors when saving Instances to files.
			-- Quickly associate this  container with its debug ID if one doesn't already exist.
			if not table.find(DebugIDList, PlayerChar) then
				DebugIDList[PlayerChar:GetDebugId()] = PlayerChar
			end
			
			-- progress_ui.Visible = false	-- Hide the progress UI; We're about to display the list that was just generated.
		end
		
		-- Check for a folder named "EquippedStorage", which Royale High places clothes that players are wearing inside. This folder should be
		-- listed first, as the user probably doesn't want to save characters with missing body parts or anything weird-looking.
		local RH_EquippedStorage = workspace:FindFirstChild("EquippedStorage")
		if RH_EquippedStorage then
			table.insert(InternalList, 1, {
				Instance = RH_EquippedStorage,
				Level = 1
			})
			
			-- Like everything, make sure EquippedStorage's debug ID is in the array before continuing, or this script won't "find a reference" later.
			if not table.find(DebugIDList, RH_EquippedStorage) then
				DebugIDList[RH_EquippedStorage:GetDebugId()] = RH_EquippedStorage
			end
		end
		
		if _includeNPCs then
			for a,v in pairs(workspace:GetDescendants()) do
				if a%AntiLagInterval then task.wait() end
				
				-- Check if this instance contains a Humanoid, which also has an Animator inside of it. If it isn't linked to a player,
				-- it's an NPC model and will be listed after all of the players' character models.
				local temp_humanoid = v:FindFirstChildOfClass("Humanoid")
				if temp_humanoid then
					local temp_animator = v:FindFirstChildOfClass("Animator")
					if temp_animator then
						if not Players:GetPlayerFromCharacter(v) then
							-- TODO: Consider if this block of code could be turned into some sort of function. This has been used 3 times now!
							table.insert(InternalList, {
								Instance = v,
								Level = 1
							})
							-- Does this NPC have its debug ID cached yet? Add it to the list if it isn't already in there!
							if not table.find(DebugIDList, v) then
								DebugIDList[v:GetDebugId()] = v
							end
						end
					end
				end
			end
		end
		
		Offset = 0							-- Always start from the beginning of a container's Instance list.
		RedrawVisibleList()
		task.wait(0.425)
		
		ToggleUI(false)
		IsBusy = false
	end
end
container5.MouseButton1Click:Connect(function() IndexCharacters(false) end)
-- container5.MouseButton2Click:Connect(function() IndexCharacters(true) end)
-- container5.TouchLongPress:Connect(function() IndexCharacters(true) end)

prevPageButton.MouseButton1Click:Connect(function()
	-- If advancing to the next page would go beyond the full Instance list's bounds, ignore this action. Otherwise, update the visible list.
	if not IsBusy and Offset > 0 then
		IsBusy = true	-- Prevent other actions from occurring until the list has been finalized.
		Offset -= 1
		RedrawVisibleList()
		instance_list.CanvasPosition = Vector2.yAxis * instance_list.AbsoluteCanvasSize.Y	-- Jump to the end of the visible list.
		IsBusy = false	-- It is now safe to close the main window and export.
	end
end)
nextPageButton.MouseButton1Click:Connect(function()
	-- If advancing to the next page would go beyond the full Instance list's bounds, ignore this action. Otherwise, update the visible list.
	if not IsBusy and ((Offset*PageLength)+1)+PageLength <= #InternalList then
		IsBusy = true	-- Prevent other actions from occurring until the list has been finalized.
		Offset += 1
		RedrawVisibleList()
		instance_list.CanvasPosition = Vector2.zero	-- Jump to the top of the visible list.
		IsBusy = false	-- It is now safe to close the main window and export.
	end
end)
PoseCharCheckbox.MouseButton1Click:Connect(function()
	if not IsBusy then
		
		-- Update the value and text. This looks confusing, but each click moves to the next value (nil, "no", then "yes") so the button's text
		-- reflects the NEXT option, the one it becomes within that block. Hopefully this makes sense.
		if PoseCharacters == "yes" then	-- TODO: Characters automatically lose their pose if their parts aren't anchored, so the 2nd choice can go!
			PoseCharacters = nil
			PoseCharCheckbox.Text = "💃🏼Ignore characters"
		elseif not PoseCharacters then
			PoseCharacters = "no"
			PoseCharCheckbox.Text = "❌ Save char. poses"
		elseif PoseCharacters == "no" then
			PoseCharacters = "yes"
			PoseCharCheckbox.Text = "✅ Save char. poses"
		end
	end
end)

local function ClearSelection()
	EmptyDebugIDCache()	-- When the main window is hidden, all debug IDs are forgotten and the instance list is emptied.
	ClearVisibleList()
	table.clear(InternalList)
	table.clear(Selection)	-- Deselect all Instances, which comnpletes the main window's reset.
	CheckSavePrerequisites()		-- Make the save button check to see if it should allow exporting of the...deselected instances (it won't).
end

-- If the clear button is visible, tappping it will deselect everything then redraw whatever page the window was showing.
clear_button.MouseButton1Click:Connect(function()
	ClearSelection()
	RedrawVisibleList()
end)

-- If the user just finished using the model name text box, validate their selection and name to determine if they're allowed to save it now.
local LastSafeName	= ""
filename_box.FocusLost:Connect(function()
	if not IsBusy then	-- As long as saving or something important isn't happening now, save the current file name to a variable. It's used below.
		LastSafeName = filename_box.Text
		CheckSavePrerequisites()
	else	-- If something is happening, don't let the user change the save's name!
		filename_box.Text = LastSafeName
	end
end)

-- Unfreezes frozen char. parts, shows the GUI, and unsets the "busy" flag, restoring the ability to select instances again.
-- If _success is set, this function also deselects everything and redraws the list.
local AnchoredCharParts : {BasePart} = {}	-- If character pose saving is on, characters are completely frozen until capturing finishes.
local function PostSaveCleanup(_success)
	if #AnchoredCharParts > 0 then
		for _,part:BasePart in pairs(AnchoredCharParts) do
			part.Anchored = false
		end
		table.clear(AnchoredCharParts)
	end
	
	ChangeButtonState(true)
	IsBusy = false
	
	if _success then
		ClearSelection()
		RedrawVisibleList()
	end
	
	ToggleUI(false)
end

-- The save button, as expected, saves all of the selected Instances. This is one of the moe important functions, though it's ironically last.
save_button.MouseButton1Click:Connect(function()
	if not save_button.Active or IsBusy then return nil end
	IsBusy = true
	
	local AnchoredCharParts  = {}	-- If character pose saving is on, characters are completely frozen until capturing finishes.
	ChangeButtonState(false)
	message.Text = "Preparing to export the selected instances..."
	
	-- Check to make sure that every selected Instance still exists, cleaning up any "dead" references if they're found in it.
	-- As table.remove() shifts arrays' contents around as it removes things from them, we have to do another one of THESE endless
	-- for loops, restarting every time something has to be removed from the list.
	local OrigSelectionSize = #Selection	-- Note how many Instances are selected before cleaning the array up. If that lowers, this is used.
	local SelectionCleanedUp = false
	local Restarting = false	-- When this is TRUE, the outer for loop will break immediately, letting the loop start from the beginning.
	while not SelectionCleanedUp do
		for num,id in pairs(Selection) do	-- For each selected Instance...
			message.Text = "Checking instance " .. num .. "/" .. #Selection .. "..."
			local MatchedInstance = nil	-- ...convert its debug ID into an Instance reference using the debug ID list.
			for debugId , inst  in pairs(DebugIDList) do
				if id == debugId then	-- If a match is found, grab it and use it to see if it still has a parent.
					MatchedInstance = inst
					break
				end
				
				-- Does this Instance have a parent? If it doesn't, remove it from the selection then start over.
				if MatchedInstance and not MatchedInstance.Parent then
					table.remove(Selection, num)
					message.Text = "Welp, Instance ID " .. id .. " doesn't exist now, so it isn't included now."
					print("Instance ID", id, "couldn't be found, so it won't be saved.")
					task.wait(1.5)	-- Wait one and a half seconds so the message above can be read before it's updated again.
					Restarting = true	-- Cut off this process now, to make sure that the entire selectiong gets scanned.
					break
				end
			end
			
			-- Are we about to start over? If so, unset that flag then let the while loop do the rest.
			if Restarting then break end
		end
		
		-- If the for loop completed without requesting a do-over, this while loop can safely end now. Otherwise, unset the flag and start over.
		if not Restarting then
			SelectionCleanedUp = true
		else Restarting = false
		end
	end
	
	-- If any Instances were unparented or removed since they were selected, notify the user before proceeding.
	if #Selection < OrigSelectionSize then
		message.Text = "Unfortunately, only " .. #Selection .. " of " .. OrigSelectionSize .. " instances will be saved."
		task.wait(3)
	end
	
	-- First, let's write the "header" file, which will tell the Studio plugin where it should place each exported "model", the export's
	-- folder name (its filename), and other information. To get this info, we have to look through the currently-selected instances and
	-- figure out if anything was saved from PlayerGui, ReplicatedStorage, or Lighting.
	local HeaderContents	= {
		Metadata			= {
			Name			= filename_box.Text,	-- Place all exported instances from this package into a Model named this (see below).
			PlaceId			= game.PlaceId or 0,	-- The ID of the place where this rip was done, which will be saved as an IntValue.
			GameId			= game.GameId or 0,		-- This experience's ID number, for reference, just like the previous ID.
		},
		
		-- Any MaterialVariants found within MaterialService are stored here, in a format similar to that of pieces' entries.
		MaterialVariants	= {},
		
		-- Lighting properties are always saved, but they aren't used unless "Apply" is set to TRUE.
		LightingProperties						= {
			Ambient								= StoreValue(Lighting.Ambient, "Color3"),
			Brightness							= Lighting.Brightness,
			ColorShift_Top						= StoreValue(Lighting.ColorShift_Top, "Color3"),
			ColorShift_Bottom					= StoreValue(Lighting.ColorShift_Bottom, "Color3"),
			EnvironmentDiffuseScale				= Lighting.EnvironmentDiffuseScale,
			EnvironmentSpecularScale			= Lighting.EnvironmentSpecularScale,
			GlobalShadows						= Lighting.GlobalShadows,
			OutdoorAmbient						= StoreValue(Lighting.OutdoorAmbient, "Color3"),
			ShadowSoftness						= Lighting.ShadowSoftness,
			ClockTime							= Lighting.ClockTime,
			GeographicLatitude					= Lighting.GeographicLatitude,
			FogColor							= StoreValue(Lighting.FogColor, "Color3"),
			FogEnd								= Lighting.FogEnd,
			FogStart							= Lighting.FogStart
		},
		
		-- Store all four containers' "imposter" debug IDs. Before the Studio plugin starts to "import" instances, it should create four
		-- dummy Models, one in each of the supported containers. As each is created, it must be associated with its respective "debug ID"
		-- in this array, which should be consistent with debug IDs used by captured instances which were direct children of workspace,
		-- ReplicatedStorage, or another container.
		
		-- When no matches are found for a "debug ID" when they're being linked, the instances should be forcibly parented to the Model
		-- in that piece's container (which can be found in the PieceInfo array within the header). Also, each Model should be named
		-- after the export ([header].Metadata.Name).
		ImposterIds								= {
			ContainerRedirections[workspace:GetDebugId()],
			ContainerRedirections[Players:GetDebugId()],
			ContainerRedirections[Lighting:GetDebugId()],
			ContainerRedirections[ReplicatedStorage:GetDebugId()]
		},
		
		-- Stores info about every part of this export. This is used to validate that enough JSON entries have been provided and where to
		-- place their contents. (Captures within PlayerGui are put in StarterGUI, and every other container adds the models' contents to
		-- a subfolder within that specific location.)
		PieceInfo								= {
		}
	}
	for i,debugID  in pairs(Selection) do
		message.Text = "Attempting to get a reference to piece " .. i .. "/" .. #Selection .. " (ID " .. debugID .. ")"
		-- Try to find this debug ID in the full list's keys. If a match is gotten, get its cooresponding Instance and use that next.
		local MatchedInst : Instance? = GetInstanceFromDebugID(debugID)
		
		-- While we're doing things relating to debug IDs, let's make sure this instance's descendants have also been scanned before by
		-- seeing if their IDs are on the list too! This should only be done for targets with at least a couple child instances, though.
		-- Since this is typically triggered when it's unnecessary, this can be skipped using _G.SkipPreSaveVerify.
		if MatchedInst and not SkipPreSaveVerify then
			local temp_descendants = MatchedInst:GetDescendants()
			
			-- Check if a few instances' debug IDs have been indexed. If any of them haven't, every descendant's debug ID will be cached immediately.
			if #temp_descendants > 0 then
				local FullIndexNeeded = false
				for i = 1, math.min(#temp_descendants, 5) do	-- Check up to 5 instances within this target.
					local temp_descendantFound = GetInstanceFromDebugID(temp_descendants[i]:GetDebugId())
					if not temp_descendantFound then FullIndexNeeded = true; break; end
				end
				
				-- If we need to, we'll account for every single instance within this target!
				if FullIndexNeeded then
					ProgressVars.TotalInstances = #temp_descendants
					ProgressVars.CurrentInstance = 0
					ProgressVars.ProcessVerb = "Last-minute indexing"
					progress_ui.Visible = true	-- For now, make the UI pop up rather than sliding in like the other frames would.
					ApplyChildAction(MatchedInst, "debug", 1)
				end
			end
		end
		
		-- Generate this piece's GUID and set its import location now, so this piece can always be imported, even if its instance isn't checked.
		local PieceEntry							= {
			InsertLocation							= "workspace",
			BaseInstName							= "UnknownBaseInstance",
			GUID									= game:GetService("HttpService"):GenerateGUID(false)
		}
		-- Could we find this selected Instance? Figure out its container, then write that down for the plugin.
		if MatchedInst then
			local inWorkspace, inPlayers, inPlayerGui, inLighting, inRepStore =
				MatchedInst:IsDescendantOf(workspace),
				MatchedInst:IsDescendantOf(Players),
				MatchedInst:IsDescendantOf(PlayerGui),
				MatchedInst:IsDescendantOf(Lighting),
				MatchedInst:IsDescendantOf(ReplicatedStorage)
			
			PieceEntry.BaseInstName				= MatchedInst.Name
			PieceEntry.InsertLocation	=
				if inPlayers then "players"
				elseif inPlayerGui then "playergui"
				elseif inLighting then "lighting"
				elseif inRepStore then "repstore"
				else "workspace"
			
			-- If this Instance is inside the workspace, it could contain character models; If any are found, they can be saved in their current
			-- pose or reverted to their "bind pose", allowing anyone to pose or animate any character model in Roblox Studio!
			-- Character models in ReplicatedStorage are either pre-posed or aren't animated, since Roblox doesn't run script code in there.
			-- Because this could greatly slow down big captures, none of this code is ran unless character posing is enabled.
			if PoseCharacters == "yes" or PoseCharacters == "no" then
				for _, descendant  in pairs(MatchedInst:GetDescendants()) do
					-- print("Processing", inst.Name)
					if descendant:IsA("Model") and descendant.ClassName ~= "Tool" then	-- A Model could be a Character! See if it has a Humanoid and Animator.
						print("Found a model! Is it a character?", descendant:GetFullName())
						local ChildHumanoid  = descendant:FindFirstChildOfClass("Humanoid", 1)
						if ChildHumanoid then
							print("It has a Humanoid!")
							local ChildAnimator  = ChildHumanoid:FindFirstChildOfClass("Animator", 1)
							if ChildAnimator then
								print("What should we do?")
								if PoseCharacters == "no" then
									print("Trying to stop all ongoing animations/poses for", ChildAnimator:GetFullName())
									for _,anim  in pairs(ChildAnimator:GetPlayingAnimationTracks()) do anim:Stop(0) end
									task.wait(0.03125)	-- Give the character a split-second to stop animating before proceeding.
								else
									print("Trying to temporarily anchor all of the parts inside", MatchedInst:GetFullName())
									for _, inst1  in pairs(descendant:GetDescendants()) do
										if inst1:IsA("BasePart") and not inst1.Anchored then
											table.insert(AnchoredCharParts, inst1)	-- Remember to unanchor this part after capturing every Instance.
											inst1.Anchored = true
										end
									end
								end
							end
						end
					end
				end
			end
		end
		
		HeaderContents.PieceInfo[i]		= PieceEntry	-- Add this piece's information to the array, then continue and add the rest of them.
	end
	
	-- Just before the header is written to file, any material definitions are written down in its MaterialVariants sub-array.
	local MatList						= MaterialService:GetDescendants()
	if #MatList > 0 then
		for i,material  in pairs(MatList) do
			message.Text = "Grabbing material variants... (" .. (i/#MatList)*100 .. "%)"
			if material:IsA("MaterialVariant") then
				table.insert(HeaderContents.MaterialVariants, {
					Name				= material.Name,
					BaseMaterial		= StoreValue(material.BaseMaterial, "EnumItem"),
					MaterialPattern		= StoreValue(material.MaterialPattern, "EnumItem"),
					ColorMap			= material.ColorMap,
					NormalMap			= material.NormalMap,
					MetalnessMap		= material.MetalnessMap,
					RoughnessMap		= material.RoughnessMap,
					StudsPerTile		= material.StudsPerTile
				})
			end
		end
	end
	
	-- Write the header/metadata to this export's "main file".
	writefile(filename_box.Text .. "_header.json", game:GetService("HttpService"):JSONEncode(HeaderContents))
	
	-- With the header data written to a file, the actual exporting can begin! Hide the main interface, as it's probably disabled at this point.
	ToggleUI(true)
	
	for i,target in pairs(Selection) do
		-- Set up and show the "indexing progress" UI, which will be updated by ApplyChildAction(), so the user isn't left in the dark.
		ProgressVars.TotalInstances = #DebugIDList[target]:GetDescendants()
		ProgressVars.CurrentInstance = 0
		ProgressVars.ProcessVerb = "Saving selection " .. i .. "'s"
		message.Text = "Saving selection " .. i .. "/" .. #Selection .. " (" .. HeaderContents.PieceInfo[i].BaseInstName .. ")"
		progress_ui.Visible = true	-- For now, make the UI pop up rather than sliding in like the other frames would.
		
		OngoingExportData = {}	-- Always ensure the "scrapbook" array is empty before exporting part of this "model".
		local success, msg = pcall(function() ApplyChildAction(DebugIDList[target], "capture", 1, OngoingExportData) end)	-- Try to "capture"!
		if not success then
			progress_ui.Visible = false	-- Hide the progress UI.
			message.Text = "Oh no! Piece #" .. i .. " couldn't be captured because of this error: \"" .. msg .. "\"."
			PostSaveCleanup(false)
			error("Piece " .. i .. " of export " .. filename_box.Text .. " couldn't be completely captured.")
		end
		if #OngoingExportData > 0 then
			OngoingExportData[1].GUID	= HeaderContents.PieceInfo[i].GUID	-- Add this piece's GUID to the first instance entry as a "property".
			pcall(function()
				writefile(filename_box.Text .. "_piece" .. i .. ".json", game:GetService("HttpService"):JSONEncode(OngoingExportData))
			end)
			
			if i == #Selection then	-- Was that the last piece? If so, we're done! Clear the user's selection and finish up.
				progress_ui.Visible = false
				message.Text = "Done! Transfer the new JSON files in your workspace folder to your PC, " ..
					"then paste each of them into the Studio plugin's text fields, adding more as needed." ..
					"Make sure the 'header' goes first, followed by each piece IN ORDER!"
				PostSaveCleanup(true)
			end
		else
			progress_ui.Visible = false	-- Hide the progress UI; We're about to display the list that was just put generated.
			message.Text = "Uh-oh! Piece #" .. i .. " wasn't saved for some reason!"
			PostSaveCleanup(false)
			error("Piece " .. i .. " of export " .. filename_box.Text .. " wasn't converted to a dictionary correctly.")
		end
	end
end)