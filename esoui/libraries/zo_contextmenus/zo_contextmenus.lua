local mouseUpRefCounts = {}
local currentOnMenuItemAddedCallback = nil
local currentOnMenuHiddenCallback = nil
local selectedIndex = nil
local lastCommandWasFromMenu = true

local DEFAULT_TEXT_COLOR = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_NORMAL))
local DEFAULT_TEXT_HIGHLIGHT = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_CONTEXT_HIGHLIGHT))

MENU_ADD_OPTION_LABEL = 1
MENU_ADD_OPTION_CHECKBOX = 2

MENU_TYPE_DEFAULT = 1
MENU_TYPE_COMBO_BOX = 2
MENU_TYPE_TEXT_ENTRY_DROP_DOWN = 3

local menuInfo =
{
    [MENU_TYPE_DEFAULT] =
    {
        backdropEdge = "EsoUI/Art/Tooltips/UI-Border.dds",
        backdropCenter = "EsoUI/Art/Tooltips/UI-TooltipCenter.dds",
        backdropInsets = {16,16,-16,-16},
        backdropEdgeWidth = 128,
        backdropEdgeHeight = 16,
    },
    [MENU_TYPE_COMBO_BOX] =
    {
        backdropEdge = "EsoUI/Art/Miscellaneous/dropDown_edge.dds",
        backdropCenter = "EsoUI/Art/Miscellaneous/dropDown_center.dds",
        backdropInsets = {16, 16, -16, -16},
        backdropEdgeWidth = 128,
        backdropEdgeHeight = 16,
    },
    [MENU_TYPE_TEXT_ENTRY_DROP_DOWN] =
    {
        backdropEdge = "EsoUI/Art/Miscellaneous/textEntry_dropDown_edge.dds",
        backdropCenter = "EsoUI/Art/Miscellaneous/textEntry_dropDown_center.dds",
        backdropInsets = {8, 8, -8, -8},
        backdropEdgeWidth = 64,
        backdropEdgeHeight = 8,
        hideMunge = true,
    },
}

local function AnchorMenuToMouse(menuToAnchor)
    local x, y = GetUIMousePosition()
    local width, height = GuiRoot:GetDimensions()
    
    menuToAnchor:ClearAnchors()
    
    local right = true
    if(x + ZO_Menu.width > width) then
        right = false
    end
    local bottom = true
    if(y + ZO_Menu.height > height) then
        bottom = false
    end

    if(right) then
        if(bottom) then
            menuToAnchor:SetAnchor(TOPLEFT, nil, TOPLEFT, x, y)
        else
            menuToAnchor:SetAnchor(BOTTOMLEFT, nil, TOPLEFT, x, y)
        end
    else
        if(bottom) then
            menuToAnchor:SetAnchor(TOPRIGHT, nil, TOPLEFT, x, y)
        else
            menuToAnchor:SetAnchor(BOTTOMRIGHT, nil, TOPLEFT, x, y)
        end
    end
end

local function UpdateMenuDimensions(menuEntry)
    if(ZO_Menu.currentIndex > 0) then
        local textWidth, textHeight = GetControl(menuEntry.item, "Name"):GetTextDimensions()
        local checkboxWidth, checkboxHeight = 0, 0
        if(menuEntry.checkbox) then
            checkboxWidth, checkboxHeight = menuEntry.checkbox:GetDesiredWidth(), menuEntry.checkbox:GetDesiredHeight()
        end

        local entryWidth = textWidth + checkboxWidth + ZO_Menu.menuPad * 2
        local entryHeight = zo_max(textHeight, checkboxHeight)

        if(entryWidth > ZO_Menu.width) then
            ZO_Menu.width = entryWidth
        end
        
        ZO_Menu.height = ZO_Menu.height + entryHeight + menuEntry.itemYPad
        
        -- More adjustments will come later...this just needs to set the height
        -- HACK: Because anchor processing doesn't happen right away, and because GetDimensions
        -- does NOT return desired dimensions...this will actually need to remember the height
        -- that the label was set to.  And to remember it, we need to find the menu item in the 
        -- appropriate menu...
        menuEntry.item.storedHeight = entryHeight
    end
end

function ClearMenu()
    local owner = ZO_Menu.owner
    if(type(owner) == "userdata") then
        owner:SetHandler("OnEffectivelyHidden", nil)
    end

    ZO_Menu:SetHidden(true)
    SetAddMenuItemCallback(nil) -- just in case this wasn't cleared
    SetMenuHiddenCallback(nil)
    ZO_MenuHighlight:SetHidden(true)
    ZO_Menu_SetSelectedIndex(nil)
    
    if(ZO_Menu.itemPool)
    then
        ZO_Menu.itemPool:ReleaseAllObjects()
    end

    if(ZO_Menu.checkBoxPool) then
        ZO_Menu.checkBoxPool:ReleaseAllObjects()
    end
    
    ZO_Menu.nextAnchor = ZO_Menu
    
    ZO_Menu:SetDimensions(0, 0)
    ZO_Menu.currentIndex = 1
    ZO_Menu.width = 0
    ZO_Menu.height = 0
    ZO_Menu.items = {}
    ZO_Menu.spacing = 0
    ZO_Menu.menuPad = 8
    ZO_Menu.owner = nil
end

function IsMenuVisisble()
    return mouseUpRefCounts[ZO_Menu] ~= nil
end

function SetMenuMinimumWidth(minWidth)
    ZO_Menu.width = minWidth
end

function SetMenuSpacing(spacing)
    ZO_Menu.spacing = spacing
end

function SetMenuPad(menuPad)
    ZO_Menu.menuPad = menuPad
end

local function SetMenuOwner(owner)
    if(type(owner) == "userdata") then
        owner:SetHandler("OnEffectivelyHidden", ClearMenu)
    end

    ZO_Menu.owner = owner
end

function GetMenuOwner(menu)
    local menu = menu or ZO_Menu
    return ZO_Menu.owner
end

function MenuOwnerClosed(potentialOwner)
    if(IsMenuVisisble() and (GetMenuOwner() == potentialOwner)) then
        ClearMenu()
    end
end

-- NOTE: If owner is a valid control, the menu system will use this to install an OnEffectivelyHidden handler
-- so that if the control is hidden for any reason, the menu will properly close.  The handler is currently
-- overwritten/removed, so make sure that you account for that if your controls need to have their own
-- effectively hidden handlers.  (Pending ZO_Hook work...)
function ShowMenu(owner, initialRefCount, menuType)
    if(next(ZO_Menu.items) == nil) then
        return false
    end

    menuType = menuType or MENU_TYPE_DEFAULT

    ZO_Menu:SetDimensions((ZO_Menu.menuPad * 2) + ZO_Menu.width, (ZO_Menu.menuPad * 2) + ZO_Menu.height + ZO_Menu.spacing * (#ZO_Menu.items - 1))

    -- Force the control that contains this label to the same size as the label
    -- so that mouse over and item click behavior works on each line without 
    -- needing to mouse over the actual text of the label.    
    -- Keep the height the same as it was...
    for k, v in pairs(ZO_Menu.items) do
        -- HACK: See note below about storing the height...
        v.item:SetDimensions(ZO_Menu.width, v.item.storedHeight)
    end
    
    if(ZO_Menu.menuType ~= menuType) then
        local menuInfo = menuInfo[menuType]
        ZO_MenuBG:SetCenterTexture(menuInfo.backdropCenter)
        ZO_MenuBG:SetEdgeTexture(menuInfo.backdropEdge, menuInfo.backdropEdgeWidth, menuInfo.backdropEdgeHeight)
        ZO_MenuBG:SetInsets(unpack(menuInfo.backdropInsets))
        ZO_MenuBGMungeOverlay:SetHidden(menuInfo.hideMunge)
    end

    ZO_Menu.menuType = menuType
    
    ZO_Menu:SetHidden(false)
    ZO_Menus:BringWindowToTop()

    AnchorMenuToMouse(ZO_Menu)

    -- Combobox will set this to two so that the first mouse up doesn't close the menu
    -- Otherwise, the first mouse up will close the menu.
    mouseUpRefCounts[ZO_Menu] = initialRefCount or 2

    -- The menu has been shown, get rid of the add item callback; it will be set again for other menus.
    SetAddMenuItemCallback(nil)

    SetMenuOwner(owner)

    return true
end

function AnchorMenu(control, offsetY)
    -- By default, the menu is shown where the mouse cursor is...
    -- but if valid anchor data is passed in, that's used instead.
    
    ZO_Menu:ClearAnchors()
    ZO_Menu:SetAnchor(TOPLEFT, control, BOTTOMLEFT, 0, offsetY)

    -- The menu must properly contain its contents, but if "control" is
    -- larger than the contents' widths, use "control" to size the menu.
    -- NOTE: Not using padding on purpose since I don't want to redo all the options dropdowns.  If something else breaks this, fix those by increasing their min width
    if(control:GetWidth() >= ZO_Menu.width) then
        ZO_Menu:SetAnchor(TOPRIGHT, control, BOTTOMRIGHT, 0, offsetY)
    end
end

function SetAddMenuItemCallback(itemAddedCallback)
    if(itemAddedCallback and type(itemAddedCallback) == "function") then
        currentOnMenuItemAddedCallback = itemAddedCallback
    else
        currentOnMenuItemAddedCallback = nil
    end
end

function SetMenuHiddenCallback(menuHiddenCallback)
    if(menuHiddenCallback and type(menuHiddenCallback) == "function") then
        currentOnMenuHiddenCallback = menuHiddenCallback
    else
        currentOnMenuHiddenCallback = nil
    end
end

function GetMenuPadding()
    return ZO_Menu.menuPad
end

function AddMenuItem(mytext, myfunction, itemType, myFont, normalColor, highlightColor, itemYPad)
    local menuItemControl = ZO_Menu.itemPool:AcquireObject()
    menuItemControl.OnSelect = myfunction
    menuItemControl.menuIndex = ZO_Menu.currentIndex

    local checkboxItemControl
    if(itemType == MENU_ADD_OPTION_CHECKBOX) then
        checkboxItemControl = ZO_Menu.checkBoxPool:AcquireObject()
        ZO_CheckButton_SetToggleFunction(checkboxItemControl, myfunction)
        checkboxItemControl.menuIndex = ZO_Menu.currentIndex
    end

    local addedItemIndex = ZO_Menu.currentIndex
    ZO_Menu.currentIndex = ZO_Menu.currentIndex + 1
    
    itemYPad = itemYPad or 0

    table.insert(ZO_Menu.items, { item = menuItemControl, checkbox = checkboxItemControl, itemYPad = itemYPad })
    
    menuItemControl:ClearAnchors()
    menuItemControl:SetHidden(false)

    if(checkboxItemControl) then
        checkboxItemControl:ClearAnchors()
        checkboxItemControl:SetHidden(false)
    end

    if(ZO_Menu.nextAnchor == ZO_Menu) then
        if(checkboxItemControl) then
            checkboxItemControl:SetAnchor(TOPLEFT, ZO_Menu.nextAnchor, TOPLEFT, ZO_Menu.menuPad, ZO_Menu.menuPad + itemYPad)
            menuItemControl:SetAnchor(TOPLEFT, checkboxItemControl, TOPRIGHT, 0, 0)
        else
            menuItemControl:SetAnchor(TOPLEFT, ZO_Menu.nextAnchor, TOPLEFT, ZO_Menu.menuPad, ZO_Menu.menuPad + itemYPad)
        end
    else
        if(checkboxItemControl) then
            checkboxItemControl:SetAnchor(TOPLEFT, ZO_Menu.nextAnchor, BOTTOMLEFT, 0, ZO_Menu.spacing + itemYPad)
            menuItemControl:SetAnchor(TOPLEFT, checkboxItemControl, TOPRIGHT, 0, 0)
        else
            menuItemControl:SetAnchor(TOPLEFT, ZO_Menu.nextAnchor, BOTTOMLEFT, 0, ZO_Menu.spacing + itemYPad)
        end
    end

    ZO_Menu.nextAnchor = checkboxItemControl or menuItemControl

    local nameControl = GetControl(menuItemControl, "Name")

    if myFont == nil then
        if not IsInGamepadPreferredMode() then
            myFont = "ZoFontGame"
        else
            myFont = "ZoFontGamepad22"
        end
    end
    
    nameControl.normalColor = normalColor or DEFAULT_TEXT_COLOR
    nameControl.highlightColor = highlightColor or DEFAULT_TEXT_HIGHLIGHT
    
    -- NOTE: Must set text AFTER the current index has been incremented.
    nameControl:SetFont(myFont)
    nameControl:SetText(mytext)
    UpdateMenuDimensions(ZO_Menu.items[#ZO_Menu.items])
    nameControl:SetColor(nameControl.normalColor:UnpackRGBA())

    if(currentOnMenuItemAddedCallback) then
        currentOnMenuItemAddedCallback()
    end

    return addedItemIndex
end

function UpdateMenuItemState(item, state)
    local menuEntry = ZO_Menu.items[item]
    if(menuEntry and menuEntry.checkbox) then
        ZO_CheckButton_SetCheckState(menuEntry.checkbox, state)
    end
end

function ZO_Menu_SelectItem(control)
    ZO_MenuHighlight:ClearAnchors()

    ZO_MenuHighlight:SetAnchor(TOPLEFT, control, TOPLEFT, -2, -2)
    ZO_MenuHighlight:SetAnchor(BOTTOMRIGHT, control, BOTTOMRIGHT, 2, 2)
   
    ZO_MenuHighlight:SetHidden(false)
    
    local nameControl = GetControl(control, "Name")
    nameControl:SetColor(nameControl.highlightColor:UnpackRGBA())
end

function ZO_Menu_UnselectItem(control)
    ZO_MenuHighlight:SetHidden(true)

    local nameControl = GetControl(control, "Name")
    nameControl:SetColor(nameControl.normalColor:UnpackRGBA())
end

function ZO_Menu_SetSelectedIndex(index)
    if(not ZO_Menu.items) then return end

    if(index) then
        index = zo_max(zo_min(index, #ZO_Menu.items), 1)
    end

    if(selectedIndex ~= index) then
        if(selectedIndex) then
            local entry = ZO_Menu.items[selectedIndex]
            if entry then 
                local control = entry.item
                if(control) then
                    ZO_Menu_UnselectItem(control)
                end
            end
        end

        selectedIndex = index

        if(selectedIndex) then
            local entry = ZO_Menu.items[selectedIndex]
            if entry then
                local control = entry.item

                if(control) then
                    ZO_Menu_SelectItem(control)
                end
            end
        end
    end
end

function ZO_Menu_GetNumMenuItems()
    return #ZO_Menu.items
end

function ZO_Menu_GetSelectedIndex()
    return selectedIndex
end

function ZO_Menu_GetSelectedText()
    local control = ZO_Menu.items[selectedIndex].item
    if(control) then
        return GetControl(control, "Name"):GetText()
    end
end

function ZO_Menu_EnterItem(control)
    ZO_Menu_SetSelectedIndex(control.menuIndex)
end

function ZO_Menu_ExitItem(control)
    if(selectedIndex == control.menuIndex)
    then
        ZO_Menu_SetSelectedIndex(nil)
    end
end

function ZO_Menu_ClickItem(control, button)
    if(button == MOUSE_BUTTON_INDEX_LEFT) then
        ZO_Menu_SetLastCommandWasFromMenu(true)
        local menuEntry = ZO_Menu.items[control.menuIndex]
        if(menuEntry and menuEntry.checkbox) then
            -- Treat this like the checkbox was clicked.
            ZO_CheckButton_OnClicked(menuEntry.checkbox, button)
        else
            -- Treat it like the label was clicked
            control.OnSelect()
            ClearMenu()
        end
    end
end

function ZO_Menu_OnHide(control)
    mouseUpRefCounts[ZO_Menu] = nil
    if(currentOnMenuHiddenCallback) then
        currentOnMenuHiddenCallback()
    end
end

local function OnGlobalMouseUp()
    local refCount = mouseUpRefCounts[ZO_Menu]
    if(refCount ~= nil) then
        local moc = WINDOW_MANAGER:GetMouseOverControl()
        if(moc:GetOwningWindow() ~= ZO_Menus) then
            refCount = refCount - 1
            mouseUpRefCounts[ZO_Menu] = refCount
            if(refCount <= 0) then                
                ClearMenu()
            end
        end
    end
end

local function ResetFunction(control)
    control:SetHidden(true)
    control:ClearAnchors()
    control.OnSelect = nil
    control.menuIndex = nil
end

local function ResetCheckbox(checkbox)
    ResetFunction(checkbox)
    ZO_CheckButton_SetToggleFunction(checkbox, nil)
end
    
local function EntryFactory(pool)
    return ZO_ObjectPool_CreateControl("ZO_MenuItem", pool, ZO_Menu)
end

local function CheckBoxFactory(pool)
    return ZO_ObjectPool_CreateControl("ZO_MenuItemCheckButton", pool, ZO_Menu)
end

function ZO_Menu_Initialize()
    --Pre-allocate these so the control closures (for OnMouseUp) are created as secure code and add-ons can use them.
    ZO_Menu.itemPool = ZO_ObjectPool:New(EntryFactory, ResetFunction)
    for i = 1, 30 do
        ZO_Menu.itemPool:AcquireObject()
    end
    ZO_Menu.itemPool:ReleaseAllObjects()

    ZO_Menu.checkBoxPool = ZO_ObjectPool:New(CheckBoxFactory, ResetCheckbox)
    for i = 1, 30 do
        ZO_Menu.checkBoxPool:AcquireObject()
    end
    ZO_Menu.checkBoxPool:ReleaseAllObjects()

    ClearMenu()
 
    EVENT_MANAGER:RegisterForEvent("ZO_Menu_OnGlobalMouseUp", EVENT_GLOBAL_MOUSE_UP, OnGlobalMouseUp)
end

function ZO_Menu_WasLastCommandFromMenu()
    return lastCommandWasFromMenu
end

function ZO_Menu_SetLastCommandWasFromMenu(menuCommand)
    lastCommandWasFromMenu = menuCommand
end