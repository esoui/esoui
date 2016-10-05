ZO_MouseInputGroup = ZO_Object:Subclass()

ZO_MOUSE_INPUT_GROUP_MOUSE_OVER = "mouseOver"

function ZO_MouseInputGroup:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_MouseInputGroup:Initialize(rootControl)
    self.over = false
    self.inputTypeGroups = { }
    self.rootControl = rootControl

    self.refreshMouseOverFunction = function()
        self:RefreshMouseOver()
    end
    self.rootMouseEnterFunction = rootControl:GetHandler("OnMouseEnter")
    self.rootMouseExitFunction = rootControl:GetHandler("OnMouseExit")
    rootControl:SetHandler("OnMouseEnter", nil)
    rootControl:SetHandler("OnMouseExit", nil)
    self:Add(rootControl, ZO_MOUSE_INPUT_GROUP_MOUSE_OVER)
end

function ZO_MouseInputGroup:GetInputTypeGroup(inputType)
    if not self.inputTypeGroups[inputType] then
        self.inputTypeGroups[inputType] = {}
    end
    return self.inputTypeGroups[inputType]
end

function ZO_MouseInputGroup:Add(control, inputType)
    if control:IsMouseEnabled() then
        local groupControls = self:GetInputTypeGroup(inputType)
        table.insert(groupControls, control)
        if inputType == ZO_MOUSE_INPUT_GROUP_MOUSE_OVER then
            ZO_PreHookHandler(control, "OnMouseEnter", self.refreshMouseOverFunction)
            ZO_PreHookHandler(control, "OnMouseExit", self.refreshMouseOverFunction)
        end
    end
end

function ZO_MouseInputGroup:AddControlAndAllChildren(control, inputType)
    self:Add(control, inputType)
    for i = 1, control:GetNumChildren() do
        self:AddControlAndAllChildren(control:GetChild(i), inputType)
    end
end

function ZO_MouseInputGroup:IsControlInGroup(searchControl, inputType)
    local groupControls = self:GetInputTypeGroup(inputType)
    for _, control in ipairs(groupControls) do
        if searchControl == control then
            return true
        end 
    end
    return false
end

function ZO_MouseInputGroup:RefreshMouseOver()
    local currentMouseOverControlInGroup = false
    --there seems to be a weird case where 3D controls can be mouse entered when exiting UI mode. So we prevent this from registering enters when not in UI mode
    if SCENE_MANAGER:IsInUIMode() then
       currentMouseOverControlInGroup = self:IsControlInGroup(WINDOW_MANAGER:GetMouseOverControl(), ZO_MOUSE_INPUT_GROUP_MOUSE_OVER) 
    end
    if currentMouseOverControlInGroup ~= self.over then
        self.over = currentMouseOverControlInGroup
        if self.over then
            self.rootMouseEnterFunction(self.rootControl)
        else
            self.rootMouseExitFunction(self.rootControl)
        end
    end
end

--XML Handlers

function ZO_MouseOverGroupFromChildren_OnInitialized(self)
    local group = ZO_MouseInputGroup:New(self)
    group:AddControlAndAllChildren(self, ZO_MOUSE_INPUT_GROUP_MOUSE_OVER)
end