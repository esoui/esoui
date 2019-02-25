ZO_TABBAR_MOVEMENT_TYPES = 
{
    PAGE_FORWARD = ZO_PARAMETRIC_MOVEMENT_TYPES.LAST,
    PAGE_BACK = ZO_PARAMETRIC_MOVEMENT_TYPES.LAST + 1,
    PAGE_NAVIGATION_FAILED = ZO_PARAMETRIC_MOVEMENT_TYPES.LAST + 2
}

ZO_PARAMETRIC_SCROLL_MOVEMENT_SOUNDS =
{
    [ZO_PARAMETRIC_MOVEMENT_TYPES.MOVE_NEXT] = SOUNDS.GAMEPAD_MENU_DOWN,
    [ZO_PARAMETRIC_MOVEMENT_TYPES.MOVE_PREVIOUS] = SOUNDS.GAMEPAD_MENU_UP,
    [ZO_PARAMETRIC_MOVEMENT_TYPES.JUMP_NEXT] = SOUNDS.GAMEPAD_MENU_JUMP_DOWN,
    [ZO_PARAMETRIC_MOVEMENT_TYPES.JUMP_PREVIOUS] = SOUNDS.GAMEPAD_MENU_JUMP_UP,
    [ZO_TABBAR_MOVEMENT_TYPES.PAGE_FORWARD] = SOUNDS.GAMEPAD_PAGE_FORWARD,
    [ZO_TABBAR_MOVEMENT_TYPES.PAGE_BACK] = SOUNDS.GAMEPAD_PAGE_BACK,
    [ZO_TABBAR_MOVEMENT_TYPES.PAGE_NAVIGATION_FAILED] = SOUNDS.GAMEPAD_PAGE_NAVIGATION_FAILED,
}

local function GamepadParametricScrollListPlaySound(movementType)
    PlaySound(ZO_PARAMETRIC_SCROLL_MOVEMENT_SOUNDS[movementType])
end

--------------------------------------------
-- ZO_GamepadVerticalParametricScrollList
--------------------------------------------
ZO_GamepadVerticalParametricScrollList = ZO_ParametricScrollList:Subclass()

function ZO_GamepadVerticalParametricScrollList:New(...)
    local list = ZO_ParametricScrollList.New(self, ...)
    return list
end

function ZO_GamepadVerticalParametricScrollList:Initialize(control)
    ZO_ParametricScrollList.Initialize(self, control, PARAMETRIC_SCROLL_LIST_VERTICAL, ZO_GamepadOnDefaultScrollListActivatedChanged)

    self:SetHeaderPadding(GAMEPAD_HEADER_DEFAULT_PADDING, GAMEPAD_HEADER_SELECTED_PADDING)
    self:SetUniversalPostPadding(GAMEPAD_DEFAULT_POST_PADDING)

    self:SetPlaySoundFunction(GamepadParametricScrollListPlaySound)
end



--------------------------------------------
-- ZO_GamepadVerticalItemParametricScrollList
--------------------------------------------
ZO_GamepadVerticalItemParametricScrollList = ZO_GamepadVerticalParametricScrollList:Subclass()

function ZO_GamepadVerticalItemParametricScrollList:New(control)
    local list = ZO_GamepadVerticalParametricScrollList.New(self, control)
    list:SetUniversalPostPadding(GAMEPAD_DEFAULT_POST_PADDING)
    return list
end



--------------------------------------------
-- ZO_GamepadHorizontalParametricScrollList
--------------------------------------------
ZO_GamepadHorizontalParametricScrollList = ZO_ParametricScrollList:Subclass()

function ZO_GamepadHorizontalParametricScrollList:New(control, onActivatedChangedFunction, onCommitWithItemsFunction, onClearedFunction)
    onActivatedChangedFunction = onActivatedChangedFunction or ZO_GamepadOnDefaultScrollListActivatedChanged
    local list = ZO_ParametricScrollList.New(self, control, PARAMETRIC_SCROLL_LIST_HORIZONTAL, onActivatedChangedFunction, onCommitWithItemsFunction, onClearedFunction)
    list:SetHeaderPadding(GAMEPAD_HEADER_DEFAULT_PADDING, GAMEPAD_HEADER_SELECTED_PADDING)
    list:SetPlaySoundFunction(GamepadParametricScrollListPlaySound)
    return list
end



--------------------------------------------
-- ZO_GamepadTabBarScrollList
--------------------------------------------
ZO_TABBAR_ICON_WIDTH = 50
ZO_TABBAR_ICON_HEIGHT = 50

ZO_GamepadTabBarScrollList = ZO_GamepadHorizontalParametricScrollList:Subclass()

function ZO_GamepadTabBarScrollList:New(control, leftIcon, rightIcon, onActivatedChangedFunction, onCommitWithItemsFunction, onClearedFunction)
    local list = ZO_GamepadHorizontalParametricScrollList.New(self, control, onActivatedChangedFunction, onCommitWithItemsFunction, onClearedFunction)
    list:EnableAnimation(false)
    list:SetDirectionalInputEnabled(false)
    list:SetHideUnselectedControls(true)

    local function CreateButtonIcon(name, parent, keycode, anchor)
        local buttonIcon = CreateControl(name, parent, CT_BUTTON)
        buttonIcon:SetNormalTexture(ZO_Keybindings_GetTexturePathForKey(keycode))
        buttonIcon:SetDimensions(ZO_TABBAR_ICON_WIDTH, ZO_TABBAR_ICON_HEIGHT)
        buttonIcon:SetAnchor(anchor, control, anchor)
        return buttonIcon
    end

    list.leftIcon = leftIcon or CreateButtonIcon("$(parent)LeftIcon", control, KEY_GAMEPAD_LEFT_SHOULDER, LEFT)
    list.rightIcon = rightIcon or CreateButtonIcon("$(parent)RightIcon", control, KEY_GAMEPAD_RIGHT_SHOULDER, RIGHT)

    list:SetEntryAnchors({ BOTTOM, BOTTOM })

    list:InitializeKeybindStripDescriptors()
    list.control = control
    list:SetPlaySoundFunction(GamepadParametricScrollListPlaySound)

    control:SetHandler("OnEffectivelyHidden", ZO_ConveyorSceneFragment_ResetMovement)

    return list
end

function ZO_GamepadTabBarScrollList:Activate()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
    ZO_GamepadHorizontalParametricScrollList.Activate(self)
end

function ZO_GamepadTabBarScrollList:Deactivate()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    ZO_GamepadHorizontalParametricScrollList.Deactivate(self)
end

function ZO_GamepadTabBarScrollList:InitializeKeybindStripDescriptors()
    local control = self:GetControl()
    local debugName = "Gamepad Tab Bar"
    if control then
        debugName = debugName .. " " .. control:GetName()
    end
    self.keybindStripDescriptor =
    {
        {
            --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
            name = debugName .. " Left Shoulder",
            keybind = "UI_SHORTCUT_LEFT_SHOULDER",
            ethereal = true,
            callback = function()
                if self.active then
                    self:MovePrevious()
                end
            end,
        },

        {
            --Ethereal binds show no text, the name field is used to help identify the keybind when debugging. This text does not have to be localized.
            name = debugName .. " Right Shoulder",
            keybind = "UI_SHORTCUT_RIGHT_SHOULDER",
            ethereal = true,
            callback = function()
                if self.active then
                    self:MoveNext()
                end
            end,
        },
    }
end

function ZO_GamepadTabBarScrollList:Commit(dontReselect)
    if #self.dataList > 1 then
        self.leftIcon:SetHidden(false)
        self.rightIcon:SetHidden(false)
    else
        self.leftIcon:SetHidden(true)
        self.rightIcon:SetHidden(true)
    end

    ZO_GamepadHorizontalParametricScrollList.Commit(self, dontReselect)

    self:RefreshPips()
end

function ZO_GamepadTabBarScrollList:SetPipsEnabled(enabled, divider)
    self.pipsEnabled = enabled

    if not divider then
        -- There is a default divider in the tabbar control
        divider = self.control:GetNamedChild("Divider")
    end

    if not self.pips and enabled then
        self.pips = ZO_GamepadPipCreator:New(divider)
    end

    self:RefreshPips()
end

function ZO_GamepadTabBarScrollList:RefreshPips()
    if not self.pipsEnabled then
        if self.pips then
            self.pips:RefreshPips()
        end
        return
    end

    local selectedIndex = self.targetSelectedIndex or self.selectedIndex

    local numPips = 0
    local selectedPipIndex = 0
    for i = 1,#self.dataList do
        if self.dataList[i].canSelect ~= false then
            numPips = numPips + 1

            local active = (selectedIndex == i)
            if active then
                selectedPipIndex = numPips
            end
        end
    end

    self.pips:RefreshPips(numPips, selectedPipIndex)
end

function ZO_GamepadTabBarScrollList:SetSelectedIndex(selectedIndex, allowEvenIfDisabled, forceAnimation)
    ZO_GamepadHorizontalParametricScrollList.SetSelectedIndex(self, selectedIndex, allowEvenIfDisabled, forceAnimation)
    self:RefreshPips()
end

function ZO_GamepadTabBarScrollList:MovePrevious(allowWrapping, suppressFailSound)
    ZO_ConveyorSceneFragment_SetMovingBackward()
    local succeeded = ZO_ParametricScrollList.MovePrevious(self)
    if not succeeded and allowWrapping then
        ZO_ConveyorSceneFragment_SetMovingForward()
        self:SetLastIndexSelected() --Wrap
        succeeded = true
    end

    if succeeded then
        self.onPlaySoundFunction(ZO_TABBAR_MOVEMENT_TYPES.PAGE_BACK)
    elseif not suppressFailSound then
        self.onPlaySoundFunction(ZO_TABBAR_MOVEMENT_TYPES.PAGE_NAVIGATION_FAILED)
    end

    return succeeded
end

function ZO_GamepadTabBarScrollList:MoveNext(allowWrapping, suppressFailSound)
    ZO_ConveyorSceneFragment_SetMovingForward()
    local succeeded = ZO_ParametricScrollList.MoveNext(self)
    if not succeeded and allowWrapping then
        ZO_ConveyorSceneFragment_SetMovingBackward()
        ZO_ParametricScrollList.SetFirstIndexSelected(self)
        succeeded = true
    end

    if succeeded then
        self.onPlaySoundFunction(ZO_TABBAR_MOVEMENT_TYPES.PAGE_FORWARD)
    elseif not suppressFailSound then
        self.onPlaySoundFunction(ZO_TABBAR_MOVEMENT_TYPES.PAGE_NAVIGATION_FAILED)
    end

    return succeeded
end



--------------------------------------------
-- ZO_GamepadVerticalParametricScrollListSubList
--------------------------------------------
--  This is a parametric scroll list meant to be embedded as an entry within another parametric scroll list.
--  The main purpose of this class is to prevent managers that create a list with these type of entries from
--having to handle the logic for switching.

local SUB_LIST_CENTER_OFFSET = -70 --for aligning the sublist and the parent list entries

ZO_GamepadVerticalParametricScrollListSubList = ZO_GamepadVerticalParametricScrollList:Subclass()

function ZO_GamepadVerticalParametricScrollListSubList:New(control, parentList, parentKeybinds, onDataChosen)
    local manager = ZO_GamepadVerticalParametricScrollList.New(self, control, parentList, parentKeybinds, onDataChosen)
    return manager
end

function ZO_GamepadVerticalParametricScrollListSubList:Initialize(control, parentList, parentKeybinds, onDataChosen)
    ZO_GamepadVerticalParametricScrollList.Initialize(self, control)

    self.parentList = parentList
    self.parentKeybinds = parentKeybinds
    self.onDataChosen = onDataChosen

    self:InitializeKeybindStrip()
    self.control:SetHidden(true)

    self:SetFixedCenterOffset(SUB_LIST_CENTER_OFFSET)
end

function ZO_GamepadVerticalParametricScrollListSubList:Commit(dontReselect)
    ZO_ParametricScrollList.Commit(self, dontReselect) --no override in ZO_GamepadVerticalParametricScrollList

    --The list isn't shown yet, so we need to ensure the default selection is updated
    self:UpdateAnchors(self.targetSelectedIndex)

    --Need to do the callback for the default selection
    self.onDataChosen(self:GetTargetData())
end

function ZO_GamepadVerticalParametricScrollListSubList:CancelSelection()
    --If the list is recommitted while open, the original index may be invalid
    local indexToReturnTo = zo_clamp(self.indexOnOpen, 1, #self.dataList)

    self.targetSelectedIndex = indexToReturnTo
    self:UpdateAnchors(indexToReturnTo)
    self.onDataChosen(self:GetDataForDataIndex(indexToReturnTo))
end

function ZO_GamepadVerticalParametricScrollListSubList:InitializeKeybindStrip()
    local function OnEntered()
        self.onDataChosen(self:GetTargetData())
        self.didSelectEntry = true
        self:Deactivate()
    end
    local function OnBack()
        self:Deactivate()
    end

    self.keybindStripDescriptor = {}
    ZO_Gamepad_AddForwardNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, OnEntered)
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, OnBack)
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.keybindStripDescriptor, self)
end

function ZO_GamepadVerticalParametricScrollListSubList:Activate()
    self.parentList:Deactivate()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.parentKeybinds)

    ZO_GamepadVerticalParametricScrollList.Activate(self)
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
    self.control:SetHidden(false)

    self.indexOnOpen = self.selectedIndex
    self.didSelectEntry = false
end

function ZO_GamepadVerticalParametricScrollListSubList:Deactivate()
    if not self.active then
        return
    end

    if self.active and not self.didSelectEntry then
        self:CancelSelection()
    end

    ZO_GamepadVerticalParametricScrollList.Deactivate(self)
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)

    self.parentList:Activate()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.parentKeybinds)
    self.control:SetHidden(true)
end