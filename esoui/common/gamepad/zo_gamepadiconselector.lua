local ICON_PER_ROW = 6
local ICON_PADDING = 40
local ICON_SIZE = 64
local ICON_OFFSET_X = 0
local ICON_OFFSET_Y = 0

ZO_ICONSELECTOR_MOVEMENT_TYPES = 
{
    MOVE_RIGHT = 1,
    MOVE_LEFT = 2,
    MOVE_UP = 3,
    MOVE_DOWN = 4,

    -- LAST allows derived classes to start their movement enumerations after the base movements 
    LAST = 5,
}

function ZO_IconSelectorPlaySound(type)
    if type == ZO_ICONSELECTOR_MOVEMENT_TYPES.MOVE_RIGHT then
        PlaySound(SOUNDS.HOR_LIST_ITEM_SELECTED)
    elseif type == ZO_ICONSELECTOR_MOVEMENT_TYPES.MOVE_LEFT then
        PlaySound(SOUNDS.HOR_LIST_ITEM_SELECTED)
    elseif type == ZO_ICONSELECTOR_MOVEMENT_TYPES.MOVE_UP then
        PlaySound(SOUNDS.GAMEPAD_MENU_UP)
    elseif type == ZO_ICONSELECTOR_MOVEMENT_TYPES.MOVE_DOWN then
        PlaySound(SOUNDS.GAMEPAD_MENU_DOWN)
    end
end

--------------------
-- Util Functions --
--------------------

local function GetGridRowCol(index, itemsPerRow)
    local row = zo_floor((index - 1) / itemsPerRow)
    local col = (index - 1) % itemsPerRow

    return row, col
end

local function GetGridIndex(row, col, itemsPerRow)
    local index = (row * itemsPerRow) + col

    return index
end

----------------------------
-- ZO_GamepadIconSelector --
----------------------------

ZO_GamepadIconSelector = ZO_Object:Subclass()

function ZO_GamepadIconSelector:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_GamepadIconSelector:Initialize(control, settings)
    self.control = control
    self.control.iconSelectorObject = self
    
    self.iconsPerRow = ICON_PER_ROW
    self.iconPadding = ICON_PADDING
    self.iconSize = ICON_SIZE
    self.iconOffsetX = ICON_OFFSET_X
    self.iconOffsetY = ICON_OFFSET_Y    

    if(settings.iconsPerRow) then
        self.iconsPerRow = settings.iconsPerRow
    end

    if(settings.iconPadding) then
        self.iconPadding = settings.iconPadding
    end
        
    if(settings.iconSize) then
        self.iconSize = settings.iconSize
    end
        
    if(settings.iconOffsetX) then
        self.iconOffsetX = settings.iconOffsetX
    end

    if(settings.iconOffsetY) then
        self.iconOffsetY = settings.iconOffsetY
    end

    if(settings.totalIcons > self.iconsPerRow) then
        self.vertMovementController = ZO_MovementController:New(MOVEMENT_CONTROLLER_DIRECTION_VERTICAL)
    end
    self.horzMovementController = ZO_MovementController:New(MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL)

    self.onPlaySoundFunction = ZO_IconSelectorPlaySound

    self.iconHighlight = control:GetNamedChild("Highlight")
    self.iconHighlight:SetHidden(true)
    
    self.iconHighlightHint = self.iconHighlight:GetNamedChild("Hint")

    self.iconSelectorControls = {}
    local iconSelectorId = 0
    for i = 1, settings.totalIcons do
        local iconSelector = CreateControlFromVirtual(settings.uniqueName, control, "ZO_GamepadIconSelectorElementTemplate", iconSelectorId)
        iconSelector.iconIndex = i

        iconSelector:SetDimensions(self.iconSize, self.iconSize)

        local row, col = GetGridRowCol(i, self.iconsPerRow)

        iconSelector:SetAnchor(TOPLEFT, nil, TOPLEFT, col * (self.iconSize + self.iconPadding) + self.iconOffsetX, row * (self.iconSize + self.iconPadding) + self.iconOffsetY)
        settings.initFunc(iconSelector, i)
        iconSelectorId = iconSelectorId + 1
        table.insert(self.iconSelectorControls, iconSelector)
    end

    local defaultHighlightIndex = 1
    if(settings.defaultHighlightIndex) then
        defaultHighlightIndex = settings.defaultHighlightIndex
    end
    self:HighlightIconControl(defaultHighlightIndex)
end

function ZO_GamepadIconSelector:ForAllIconControls(func, ...)
    for i = 1, #self.iconSelectorControls do
        func(self.iconSelectorControls[i], i, ...)
    end
end

------------------------
-- Selector Highlight --
------------------------

function ZO_GamepadIconSelector:ModifyHighlightIndex(rowDiff, colDiff)
    local oldHighlightIndex = self.highlightIndex
    local itemsPerRow = self.iconsPerRow
    local totalItems = #self.iconSelectorControls

    local minCol = 0
    local minRow = 0

    local row, col = GetGridRowCol(self.highlightIndex, itemsPerRow)
    local maxRow, maxCol = GetGridRowCol(totalItems, itemsPerRow)
    
    col = col + colDiff

    if(row ~= maxRow) then
        if(col < minCol) then
            col = itemsPerRow - 1
        elseif(col > itemsPerRow - 1) then
            col = minCol
        end
    else
        if(col < minCol) then
            col = maxCol
        elseif(col > maxCol) then
            col = minCol
        end
    end

    row = row + rowDiff

    if(row < minRow) then
        row = maxRow
    elseif (row > maxRow) then
        row = 0
    end

    if(row == maxRow and col > maxCol) then
        if(rowDiff > 0) then
            row = minRow
        else
            row = row - 1
        end
    end
        
    local newHighlightIndex = GetGridIndex(row, col, itemsPerRow) + 1

    self:HighlightIconControl(newHighlightIndex)

    return newHighlightIndex ~= oldHighlightIndex
end

function ZO_GamepadIconSelector:HighlightIconControl(index)
    local control = self.iconSelectorControls[index]
    self.highlightIndex = index
    self.iconHighlight:ClearAnchors()
    self.iconHighlight:SetAnchor(CENTER, control, CENTER, 0, 0)
    self.iconHighlight:SetHidden(false)

    if(control.highlightHint) then
        self.iconHighlightHint:SetText(control.highlightHint)
        self.iconHighlightHint:SetHidden(false)
    else
        self.iconHighlightHint:SetHidden(true)
    end
end

function ZO_GamepadIconSelector:GetHighlightIndex()
    return self.highlightIndex
end

function ZO_GamepadIconSelector_RefreshIconSelectionIndicator(control, index, selectedIconIndex)
    local selectedIndicator = control:GetNamedChild("SelectedIndicator")
    selectedIndicator:SetHidden(index ~= selectedIconIndex)
end

-------------------------
-- Movement Controller --
-------------------------

function ZO_GamepadIconSelector:Activate()
    self:SetDirectionalInputEnabled(true)
end

function ZO_GamepadIconSelector:Deactivate()
    self:SetDirectionalInputEnabled(false)
end

function ZO_GamepadIconSelector:SetDirectionalInputEnabled(enabled)
    if(self.directionInputEnabled ~= enabled) then
        self.directionInputEnabled = enabled
        self.iconHighlight:SetHidden(not enabled)

        if enabled then
            DIRECTIONAL_INPUT:Activate(self, self.control)
        else
            DIRECTIONAL_INPUT:Deactivate(self)
        end
    end
end

function ZO_GamepadIconSelector:UpdateDirectionalInput()
    if(self.horzMovementController) then
        local result = self.horzMovementController:CheckMovement()
        if result == MOVEMENT_CONTROLLER_MOVE_NEXT then
            self:MoveRight()
        elseif result == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then
            self:MoveLeft()
        end
    end

    if(self.vertMovementController) then
        local result = self.vertMovementController:CheckMovement()
        if result == MOVEMENT_CONTROLLER_MOVE_NEXT then
            self:MoveDown()
        elseif result == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then
            self:MoveUp()
        end
    end
end

function ZO_GamepadIconSelector:MoveUp()
    if self:ModifyHighlightIndex(-1, 0) then
        self.onPlaySoundFunction(ZO_ICONSELECTOR_MOVEMENT_TYPES.MOVE_UP)
    end
end

function ZO_GamepadIconSelector:MoveDown()
    if self:ModifyHighlightIndex(1, 0) then
        self.onPlaySoundFunction(ZO_ICONSELECTOR_MOVEMENT_TYPES.MOVE_DOWN)
    end
end

function ZO_GamepadIconSelector:MoveLeft()
    if self:ModifyHighlightIndex(0, -1) then
        self.onPlaySoundFunction(ZO_ICONSELECTOR_MOVEMENT_TYPES.MOVE_LEFT)
    end
end

function ZO_GamepadIconSelector:MoveRight()
    if self:ModifyHighlightIndex(0, 1) then
        self.onPlaySoundFunction(ZO_ICONSELECTOR_MOVEMENT_TYPES.MOVE_RIGHT)
    end
end

function ZO_GamepadIconSelector:SetPlaySoundFunction(fn)
    self.onPlaySoundFunction = fn
end
