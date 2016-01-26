
GAMEPAD_BUY_BAG_SPACE_SCENE_NAME = "gamepad_buy_bag_space"

ZO_BuyBagSpace_Gamepad = ZO_Object:Subclass()

function ZO_BuyBagSpace_Gamepad:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

local function BuyBagSpaceAndAlert()
    BuyBagSpace()
    ZO_AlertNoSuppression(UI_ALERT_CATEGORY_ALERT, nil, zo_strformat(SI_GAMEPAD_BUY_BAG_SPACE_ALERT_MESSAGE, NUM_BACKPACK_SLOTS_PER_UPGRADE))
end

function ZO_BuyBagSpace_Gamepad:Initialize(control)
    
    self.control = control
    self.buySpace = ZO_BuySpaceGamepad:New(control:GetNamedChild("BuySpace"), zo_strformat(SI_BUY_BAG_SPACE, NUM_BACKPACK_SLOTS_PER_UPGRADE), GetString(SI_BUY_BAG_SPACE_CANNOT_AFFORD), BuyBagSpaceAndAlert)

    self.header = control:GetNamedChild("HeaderContainer"):GetNamedChild("Header")
    ZO_GamepadGenericHeader_Initialize(self.header, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE)
    self.headerData = {
        titleText = GetString(SI_PROMPT_TITLE_BUY_BAG_SPACE)
    }
    ZO_GamepadGenericHeader_RefreshData(self.header, self.headerData)

    GAMEPAD_BUY_BAG_SPACE_SCENE = ZO_InteractScene:New(GAMEPAD_BUY_BAG_SPACE_SCENE_NAME, SCENE_MANAGER, BUY_BAG_SPACE_INTERACTION)
    
    local StateChanged = function(oldState, newState)
        if newState == SCENE_SHOWING then
            self.buySpace:Activate(self.cost)
        elseif newState == SCENE_HIDDEN then
            self.buySpace:Deactivate()
        end
    end

    GAMEPAD_BUY_BAG_SPACE_SCENE:RegisterCallback("StateChange", StateChanged)
end

function ZO_BuyBagSpace_Gamepad:Show(cost)
    self.cost = cost
    SCENE_MANAGER:Show(GAMEPAD_BUY_BAG_SPACE_SCENE_NAME)
end

function ZO_BuyBagSpace_Gamepad:Hide()
    SCENE_MANAGER:Hide(GAMEPAD_BUY_BAG_SPACE_SCENE_NAME)
end

function ZO_BuyBagSpace_Gamepad_Initialize(control)
    BUY_BAG_SPACE_GAMEPAD = ZO_BuyBagSpace_Gamepad:New(control)
end