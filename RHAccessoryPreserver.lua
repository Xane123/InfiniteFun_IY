-- SERVICES
local Players								= game:GetService("Players")
local Lighting								= game:GetService("Lighting")

-- Look for the "base" folder that this script will save everything into. (Sub-folders will be created for each item.)
local SaveBase : Folder?					= Lighting:FindFirstChild("Clothing Captures")
if not SaveBase then
	SaveBase								= Instance.new("Folder")
	SaveBase.Name							= "Clothing Captures"
	SaveBase.Parent							= Lighting
end
local SaveFolder : Folder?					= nil

-- REFERENCES - PLAYER
local LocalPlayer							= Players.LocalPlayer
local PlayerGui								= LocalPlayer.PlayerGui

-- CONSTANTS
local Color_ButtonEnabled					= Color3.new(0.4,0.875,1)
local Color_ButtonDisabled					= Color3.new(0.2,0.4425,0.5)
local BarPos_Active							= UDim2.fromScale(0.975,0.025)
local BarPos_Inactive						= UDim2.fromScale(0.975,-0.333)

local EquippedStorage						= workspace:FindFirstChild("EquippedStorage")
if not EquippedStorage then
	error("RH Accessory Preserver - You aren't currently playing Royale High, or are in a realm without an EquippedStorage folder.")
end

-- CONNECTIONS & VARIABLES
--[[
	This script is designed in a mostly event-driven fashion, relying on Roblox's ChildAdded/ChildRemoved events to
	determine when the player (un)equips an item (which adds/removes a Model from their EquippedStorage sub-folder)
	and re-evaluate what its target is. When the close button is tapped, everything is cleaned up, which is easy
	because of these variables.
	
	For the record, there isn't a text field or button for choosing which category to save from. When this script
	initializes or the player (un)equips an accessory, a skirt, or shoes ("heels" internally), it checks all three
	folders in order:
	
	1.	If the player is wearing any accessories, that category is always chosen. In the event they're wearing more
		than one, saving will be disabled; Only equip the item you want to save forms of!
	2.	If no accessories are equipped, it checks for a skirt (which is placed in its own folder for some reason).
	3.	When neither of the previous conditions are met, it checks for a dummy Model in their Heels folder. When
		these are saved, the full character model is cloned, as shoes REPLACE leg parts for some reason.
]]--
local Conn_SaveBtn : RBXScriptConnection	= nil	-- Attempts to save the current accessory, skirt, or shoes (character model), in order.
local Conn_CheckBtn : RBXScriptConnection	= nil	-- Manually scans the player's sub-folders for a single accessory to target.
local Conn_CloseBtn : RBXScriptConnection	= nil	-- Disconnects all event connections, destroys the GUI, and hopefully ends this script.
local Conn_CAdded1 : RBXScriptConnection	= nil	-- ChildAdded event (for Accessories/[player] folder)
local Conn_CAdded2 : RBXScriptConnection	= nil	-- ChildAdded event (for Skirts/[player] folder)
local Conn_CAdded3 : RBXScriptConnection	= nil	-- ChildAdded event (for Heels/[player] folder)
local Conn_CRemoved1 : RBXScriptConnection	= nil	-- ChildRemoved event (for Accessories/[player] folder)
local Conn_CRemoved2 : RBXScriptConnection	= nil	-- ChildRemoved event (for Skirts/[player] folder)
local Conn_CRemoved3 : RBXScriptConnection	= nil	-- ChildRemoved event (for Heels/[player] folder)
local Conn_SidebarVis : RBXScriptConnection	= nil	-- Toggle GUI visibility toggle detection event.
local Conn_CharAdded : RBXScriptConnection	= nil	-- This player's CharacterAdded event. This ends the script, as it breaks GUI references.
local Conn_CharRemove : RBXScriptConnection	= nil	-- This player's CharacterRemoving event, which also causes a self-destruct.

local Permissions							= {
	CanSave = false,								-- If TRUE, allows cloning the player's current targetted clothing when clicking 💾Save.
	CanCheck = false,								-- When set, the user can look for their targeted accessory.
	CanClose = true									-- Disables the close button if this is false. Doesn't prevent emergency shutdowns.
}
local Target : Model?						= nil	-- When set, this is the Model that will be cloned and named based on the preview GUI.
local SaveName : string						= ""	-- Generated name for the current accessory's toggle and variations. (It's pretty long!)

local FullFolder1 : Folder?					= EquippedStorage:FindFirstChild("Accessories")
local FullFolder2 : Folder?					= EquippedStorage:FindFirstChild("Skirts")
local FullFolder3 : Folder?					= EquippedStorage:FindFirstChild("Heels")

if not FullFolder1 or not FullFolder2 or not FullFolder3 then
	error("RH Accessory Preserver - The standard Accessories, Skirts, and Heels folders can't be located, so execution can't continue.")
end

local AccessoryFolder : Folder?				= FullFolder1:FindFirstChild(LocalPlayer.Name)
local SkirtFolder : Folder?					= FullFolder2:FindFirstChild(LocalPlayer.Name)
local HeelFolder : Folder?					= FullFolder3:FindFirstChild(LocalPlayer.Name)

-- REFERENCES - RH's PREVIEW GUI
--[[
	This script grabs most of its info from the sidebar that's shown when the player equips an item with multiple
	"toggles" (forms) and/or variations (alternative designs or appearances for parts of this toggle). Whenever
	the player tries to save a specific version (toggle and variation combination), a name is dynamically made
	using the item's name, current toggle number, and all variations' numbers and titles.
	
	This name doubles as an idenfifier; If this exact version has already been saved to Lighting, nothing
	will happen.
]]--
local GUI_Base			= PlayerGui.PreviewToggles
local GUI_ToggleList	= GUI_Base.PreviewTogglesFrame.Inner	-- Grid of toggle previews. The selected toggle has an outline around it.
local GUI_VarList		= GUI_Base.PreviewTogglesFrame.DynamicToggleVariants.ToggleCycleFrame	-- List of variation categories!

-- SCRIPT GUI
-- Although this script is relatively simple, it uses a GUI to show its current status and make it easy to save and stop the script.
--[[
	Roblox2Lua
	----------
	
	This code was generated using
	Deluct's Roblox2Lua plugin.
]]--
local xcapture_gui = Instance.new("ScreenGui")
xcapture_gui.DisplayOrder = 100
xcapture_gui.IgnoreGuiInset = false
xcapture_gui.ResetOnSpawn = true
xcapture_gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
xcapture_gui.Name = "XCaptureGUI"
xcapture_gui.Parent = game:GetService("CoreGui")

local message = Instance.new("TextLabel")
message.Font = Enum.Font.RobotoCondensed
message.Text = "Hello, exploiter! This script is still initializing, so...just sit tight, alright?"
message.TextColor3 = Color3.new(1, 1, 1)
message.TextScaled = true
message.TextStrokeColor3 = Color3.new(0.921569, 0.345098, 0.823529)
message.TextStrokeTransparency = 0
message.TextTruncate = Enum.TextTruncate.AtEnd
message.TextWrapped = true
message.AnchorPoint = Vector2.new(1, 0)
message.BackgroundColor3 = Color3.new(0.972549, 0.843137, 1)
message.BorderSizePixel = 0
message.Position = UDim2.new(0.975, 0, 0.025, 0)
message.Size = UDim2.new(0.475, 0, 0.125, 0)
message.Visible = true
message.Name = "Message"
message.Parent = xcapture_gui

local trash = Instance.new("UICorner")
trash.CornerRadius = UDim.new(0.25, 0)
trash.Parent = message

local save_button = Instance.new("TextButton")
save_button.Font = Enum.Font.DenkOne
save_button.Text = "💾"
save_button.TextColor3 = Color3.new(0, 0, 0)
save_button.TextSize = 32
save_button.TextWrapped = true
save_button.AnchorPoint = Vector2.new(1, 0)
save_button.BackgroundColor3 = Color3.new(0.509804, 0.878431, 1)
save_button.BorderSizePixel = 0
save_button.Position = UDim2.new(1, 0, 1, 0)
save_button.Size = UDim2.new(1, 0, 1, 0)
save_button.SizeConstraint = Enum.SizeConstraint.RelativeYY
save_button.Visible = true
save_button.Name = "SaveButton"
save_button.Parent = message

trash = Instance.new("UICorner")
trash.CornerRadius = UDim.new(1, 0)
trash.Parent = save_button

local check_button = Instance.new("TextButton")
check_button.Font = Enum.Font.Highway
check_button.Text = "Check"
check_button.TextColor3 = Color3.new(1, 1, 1)
check_button.TextScaled = true
check_button.TextSize = 32
check_button.TextStrokeColor3 = Color3.new(0.215686, 0.54902, 0.784314)
check_button.TextStrokeTransparency = 0
check_button.TextWrapped = true
check_button.AnchorPoint = Vector2.new(1, 0.5)
check_button.BackgroundColor3 = Color3.new(0.509804, 0.878431, 1)
check_button.BorderSizePixel = 0
check_button.Position = UDim2.new(0, 0, 0.5, 0)
check_button.Size = UDim2.new(1, 0, 1, 0)
check_button.SizeConstraint = Enum.SizeConstraint.RelativeYY
check_button.Visible = true
check_button.Name = "CheckButton"
check_button.Parent = save_button

trash = Instance.new("UICorner")
trash.CornerRadius = UDim.new(1, 0)
trash.Parent = check_button

local close_button = Instance.new("ImageButton")
close_button.Image = "rbxassetid://11739785350"
close_button.ScaleType = Enum.ScaleType.Fit
close_button.AnchorPoint = Vector2.new(0.75, 0.25)
close_button.BackgroundColor3 = Color3.new(1, 1, 1)
close_button.BackgroundTransparency = 1
close_button.BorderColor3 = Color3.new(0.105882, 0.164706, 0.207843)
close_button.Position = UDim2.new(0, 0, 0.75, 0)
close_button.Rotation = -90
close_button.Size = UDim2.new(0.675000012, 0, 0.675000012, 0)
close_button.SizeConstraint = Enum.SizeConstraint.RelativeYY
close_button.Visible = true
close_button.ZIndex = 100
close_button.Name = "CloseButton"
close_button.Parent = message

-- FUNCTIONS
local function DisconnectEvent(_event : RBXScriptConnection)
	if _event then
		_event:Disconnect()
		_event = nil
	end
	
	return nil
end

-- Updates the specified "permission" and changes the color of its associated button.
local ButtonInfo = {
	["save"]		= {
		OnColor		= Color_ButtonEnabled,
		OffColor	= Color_ButtonDisabled,
		Instance	= save_button,
		Variable	= "CanSave"
	},
	["check"]		= {
		OnColor		= Color_ButtonEnabled,
		OffColor	= Color_ButtonDisabled,
		Instance	= check_button,
		Variable	= "CanCheck"
	},
	["close"]		= {
		Instance	= close_button,
		Variable	= "CanClose"
	},
	
}
local function UpdateButton(_buttonName : "save"|"check"|"close", _enabled : boolean)
	if _buttonName == "save" or _buttonName == "check" or _buttonName == "close" then
		Permissions[ButtonInfo[_buttonName]] = _enabled
		
		-- If this is a basic text-based button, its background changes colors based on if it's enabled or not.
		if ButtonInfo[_buttonName].OnColor then
			if _enabled then ButtonInfo[_buttonName].Instance.BackgroundColor3 = ButtonInfo[_buttonName].OnColor
			else ButtonInfo[_buttonName].Instance.BackgroundColor3 = ButtonInfo[_buttonName].OffColor
			end
		else ButtonInfo[_buttonName].Instance.Visible = _enabled
		end
	end
	
	return nil
end

-- Disconnects all event connections, slides the main GUI off-screen, then destroys this script and the ScreenGui.
local function Shutdown(_playAnim : boolean)
	DisconnectEvent(Conn_CharAdded)
	DisconnectEvent(Conn_CharRemove)
	DisconnectEvent(Conn_CAdded1)
	DisconnectEvent(Conn_CAdded2)
	DisconnectEvent(Conn_CAdded3)
	DisconnectEvent(Conn_CRemoved1)
	DisconnectEvent(Conn_CRemoved2)
	DisconnectEvent(Conn_CRemoved3)
	DisconnectEvent(Conn_SaveBtn)
	DisconnectEvent(Conn_CheckBtn)
	DisconnectEvent(Conn_CloseBtn)
	DisconnectEvent(Conn_SidebarVis)
	
	if _playAnim then
		message:TweenPosition(
			BarPos_Inactive,
			Enum.EasingDirection.InOut,
			Enum.EasingStyle.Back,
			0.75,
			true
		)
		task.wait(0.75)
	end
	xcapture_gui:Destroy()
	
	warn("RH Accessory Preserver has shut down. Please execute the script again if you would like to continue saving things!")
	script:Destroy()
end

-- If the player's character respawns, all GUI references break, which would glitch this script out. Let's avoid that by immediately closing.
Conn_CharAdded	= LocalPlayer.CharacterAdded:Connect(function() Shutdown(false) end)
Conn_CharRemove	= LocalPlayer.CharacterRemoving:Connect(function() Shutdown(false) end)

-- Clicking the close button destroys the GUI, but plays the animation. This only works when it isn't cloning a Model, though.
Conn_CloseBtn	= close_button.MouseButton1Click:Connect(function() if Permissions.CanClose then Shutdown(true); end; end)

-- GetTargetInFolder (takes Folder reference, returns a specifically-formatted dictionary)
-- Sees if the provided Folder contains a single item, returning it as a "target". If there are no or 2+ items
-- inside of it, only the total will be returned.
local function GetTargetInFolder(_directory : Folder)
	local details : {
		Target : Model?,
		Count : number
	} = {
		Target = nil,
		Count = 0
	}
	
	if _directory then
		details.Count = #_directory:GetChildren()
		if details.Count == 1 then	-- If there's just one Model in the Folder, return it as a possible target!
			details.Target = _directory:GetChildren()[1]
		end
	end
	
	return details
end

--[[
	Request1ModelValidation (takes nothing, returns nothing)
	An update function, which scans this player's Accessories, Skirts, and Heels sub-folders (in that order)
	for a single item to later "save" (clone to its sub-folder in Lighting). When scanning a folder, this
	function only advances if it's empty, so it's recommended to not wear any accessories or skirts in general
	to ensure that it picks the correct category when the player's in Try On mode, which equips the clothes
	like normal internally.
	
	If a folder just contains one instance, it's picked as the target, and the preview GUI is scanned for info
	like the item's name, current toggle, and any variations' names and numbers. This forms the final name
	that the cloned Model will use, and will prevent the player from accidentally saving something they already
	have in its folder.
]]--
local UpdateQueued = false
local function Request1ModelValidation()
	UpdateButton("save", false)	-- Disable the save button, but don't disable the checking button, as you can't scan while already doing it.
	Target = nil		-- Invalidate the current target.
	SaveFolder = nil	-- Similarly, disassociate with the previous save destination.
	
	if not UpdateQueued then
		message.Text = "Checking for a compatible target..."
		UpdateQueued = true
		
		if GUI_Base.PreviewTogglesFrame.Visible then
			local temp_folderList = {AccessoryFolder,SkirtFolder,HeelFolder}
			for num,category in temp_folderList do
				local temp_result = GetTargetInFolder(category)
				if temp_result.Count > 0 then	-- Even if the folder contains multiple items, this function won't bother checking other folders
					if temp_result.Count == 1 and temp_result.Target then
						Target = temp_result.Target
						message.Text = "Found " .. Target.Name .. "! Trying to get a more specific name for it..."
						
						-- Although a "shoes" Model is placed in the Heels sub-folder, it only contains a value with its name! The actual
						-- 3D model is within the player's character model, so it has to be saved.
						if Target.Name == "Heels" then
							Target = LocalPlayer.Character
						end
						break
					end
					if num < #temp_folderList then
						message.Text = "You're wearing 2+ " .. category.Name .. "! Unequip everything to check " ..
							temp_folderList[num+1].Name .. " or just wear the single item you want to save, then tap CHECK again."
					else message.Text = "You aren't wearing any accessories, a skirt, or shoes. Please equip or use Try On (Shop) to continue."
					end
					break
				end
			end
		else
			message.Text = "The preview sidebar isn't on! Please try on one accessory, skirt, or heels, then CHECK again."
		end
		
		-- If a valid target was found, assume it's the selected item that the player's customizing.
		if Target then
			local ItemName : TextLabel					= GUI_Base.PreviewTogglesFrame:FindFirstChild("ItemName")
			local ToggleNum : number					= 0
			-- Array of dictionary entries about each "category"'s name, and the current variation's name and number.
			local VariationInfo							= {}
			
			-- Now that we know the item's actual name from RH's GUI, let's prepare our "save" folder, using it as its name.
			SaveFolder = SaveBase:FindFirstChild(ItemName.Text)
			if not SaveFolder then	-- If the sub-folder doesn't exist, create a new one.
				SaveFolder								= Instance.new("Folder")
				SaveFolder.Name							= ItemName.Text
				SaveFolder.Parent						= SaveBase
			end
			
			-- Figure out the player's current toggle number by checking each sub-frame's UIStroke visibility. Selected toggles have an outline.
			for _,toggle in GUI_ToggleList:GetChildren() do
				if toggle:IsA("Frame") then
					if toggle:FindFirstChild("UIStrokeSelected") and toggle:FindFirstChild("UIStrokeSelected").Enabled then
						ToggleNum = tonumber(toggle.ToggleNumber.Text)	-- Get the small number in its upper left corner and use that.
						break
					end
				end
			end
			
			-- Next, iterate through this item's variation "categories" and get their information by using some "string magic".
			for _,category in GUI_VarList:GetChildren() do
				if category:IsA("Frame") then
					local temp_newEntry	= {
						CategoryName	= category.Name:sub(7),	-- Remove the first 6 letters (which are usually "Cycle ").
						VarName			= "Unknown",
						VarNumber		= -1
					}
					
					-- Unfortunately, Royale High crams both the current variation and its name into the same string, so the cryptic-looking
					-- "code" below figures out where the left-most number and name are, and slices the original string up, storing the info.
					local VariationStr:string	= category.CurrentCycleItem.Text	-- This includes both the number and name ("(1/5) Angel").
					local slashPos				= VariationStr:find("/",1,true)		-- The slash separates the current and total variations.
					local _,rightParenLoc		= VariationStr:find(") ",1,true)	-- The right parentheses and space are the name's left bound.
					
					temp_newEntry.VarNumber		= tonumber(VariationStr:sub(2,slashPos-1))
					temp_newEntry.VarName		= VariationStr:sub(rightParenLoc+1)
					
					table.insert(VariationInfo, category.LayoutOrder, temp_newEntry)	-- Insert this entry at its position in RH's list.
				end
			end
			
			-- Finally, assemble this Model's final name, starting with its given name and toggle number.
			SaveName = ItemName.Text .. " Toggle " .. ToggleNum
			if #VariationInfo > 0 then
				SaveName ..= " @"	-- Add a separator character before appending the variation information to the Model's name.
				for num,category in VariationInfo do	-- Append each variation's category name, number, and variant name to the name. This is messy.
					SaveName ..= " " .. category.CategoryName .. " " .. category.VarName .. "(" .. category.VarNumber .. ")"
					if num < #VariationInfo then SaveName ..= " /" end	-- If this isn't the last variation, add a separator before continuing.
				end
				
				table.clear(VariationInfo)	-- Clear this table to slightly lower memory usage, if it matters here.
			end
			
			if not SaveFolder:FindFirstChild(SaveName) then
				message.Text	= "Ready to save!\u{000D}\u{000A}" .. SaveName
				UpdateButton("save", true)
				UpdateButton("check", true)
			else
				message.Text	= "You've already saved this specific toggle and variant combination. Please try another one then CHECK again."
			end
		end
		
		-- To stop checks from happening too frequently, intentionally stall for a second after every scan.
		task.wait(1)
		UpdateQueued = false
	end
end

Conn_CheckBtn		= check_button.MouseButton1Click:Connect(function()
	if true then	-- Permissions.CanCheck then
		Request1ModelValidation()
	end
end)

-- Re-validate the current target when a Model is added/removed from player-specific sub-folders and when the toggle sidebar is shown.
-- Conn_CAdded1		= AccessoryFolder.ChildAdded:Connect(ValidateTarget)
-- Conn_CAdded2		= SkirtFolder.ChildAdded:Connect(ValidateTarget)
-- Conn_CAdded3		= HeelFolder.ChildAdded:Connect(ValidateTarget)
-- Conn_CRemoved1	= AccessoryFolder.ChildRemoved:Connect(ValidateTarget)
-- Conn_CRemoved2	= SkirtFolder.ChildRemoved:Connect(ValidateTarget)
-- Conn_CRemoved3	= HeelFolder.ChildRemoved:Connect(ValidateTarget)
Conn_SidebarVis		= GUI_Base.PreviewTogglesFrame:GetPropertyChangedSignal("Visible"):Connect(function()
	UpdateButton("check", GUI_Base.PreviewTogglesFrame.Visible)
	
	if GUI_Base.PreviewTogglesFrame.Visible then
		Request1ModelValidation()
		if Target then
			message.Text =
				"Choose the toggle and variation combo you want to save, then tap CHECK to get its details. If everything's fine, tap SAVE."
		end
	else
		Request1ModelValidation()
		message.Text = "The sidebar was hidden. Equip another SINGLE accessory, skirt, or shoes and you'll be able to save it."
	end
end)

save_button.MouseButton1Click:Connect(function()
	if Target then	-- Permissions.CanSave then
		UpdateButton("save", false)
		UpdateButton("check", false)
		UpdateButton("close", false)
		message.Text = "Saving model... (If this doesn't change, please check the F9 console!)\u{000D}\u{000A}" .. SaveName
		if not Target.Archivable then Target.Archivable = true end	-- Character models aren't saved, so we're fixing that before cloning it.
		
		local NewClone = Target:Clone()
		NewClone.Name = SaveName
		if NewClone:FindFirstChildOfClass("Humanoid") then	-- 2D clothes and the player's face texture(s) aren't saved when saving shoes.
			local shirt = NewClone:FindFirstChildOfClass("Shirt")
			local pants = NewClone:FindFirstChildOfClass("Pants")
			local shirtGFX = NewClone:FindFirstChildOfClass("ShirtGraphic")
			if shirt then shirt:Destroy() end
			if pants then pants:Destroy() end
			if shirtGFX then shirtGFX:Destroy() end
			
			local head = NewClone:FindFirstChild("Head")
			if head then
				for _,inst in head:GetChildren() do
					if inst:IsA("Decal") then inst:Destroy() end
				end
			end
		end
		
		NewClone.Parent = SaveFolder
		message.Text = "Save completed! Feel free to change toggles/variations now.\u{000D}\u{000A}" .. SaveName
		UpdateButton("close", true)
		UpdateButton("check", true)
	end
end)

-- Slide the bar onto the screen, now that everything's (hopefully) ready...
message:TweenPosition(
	BarPos_Active,
	Enum.EasingDirection.Out,
	Enum.EasingStyle.Quad,
	0.5,
	false
)

UpdateButton("check", GUI_Base.PreviewTogglesFrame.Visible)
UpdateButton("close", true)

message.Text = "Welcome to the RH Accessory Preserver!"
if GUI_Base.PreviewTogglesFrame.Visible then
	if GetTargetInFolder(AccessoryFolder).Count == 1 then
		message.Text ..= " Tap the CHECK button to 'save' your current toggle/variation combination to a folder in Lighting!"
	else
		message.Text ..= " Unequip all but one accessory, open the editing sidebar, then tap CHECK to select it for saving."
	end
else
	message.Text ..= " The editing sidebar isn't open currently. Please equip a single accessory, open its toggle list, then tap CHECK."
end