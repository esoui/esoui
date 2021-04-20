ZO_GRID_SCROLL_LIST_DEFAULT_TEMPLATE_KEYBOARD = "ZO_GridScrollList_Entry_Keyboard"
ZO_GRID_SCROLL_LIST_DEFAULT_TEMPLATE_DIMENSIONS_KEYBOARD = 32
ZO_GRID_SCROLL_LIST_DEFAULT_HEADER_TEMPLATE_KEYBOARD = "ZO_GridScrollList_Entry_Header_Keyboard"

-- ZO_AbstractGridScrollList_Keyboard --

ZO_AbstractGridScrollList_Keyboard = ZO_Object:Subclass()

function ZO_AbstractGridScrollList_Keyboard:New(...)
    local grid = ZO_Object.New(self)
    grid:Initialize(...)
    return grid
end

function ZO_AbstractGridScrollList_Keyboard:Initialize(control)
    -- To be overridden / added to if we have keyboard specific functionality
end

-- ZO_GridScrollList_Keyboard --

ZO_GridScrollList_Keyboard = ZO_Object.MultiSubclass(ZO_AbstractGridScrollList_Keyboard, ZO_AbstractGridScrollList)

function ZO_GridScrollList_Keyboard:New(...)
    return ZO_AbstractGridScrollList.New(self, ...)
end

function ZO_GridScrollList_Keyboard:Initialize(control, autofillRows)
    ZO_AbstractGridScrollList.Initialize(self, control, autofillRows)
    ZO_AbstractGridScrollList_Keyboard.Initialize(self, control)
end