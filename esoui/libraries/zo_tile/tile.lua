----
-- ZO_Tile
----

ZO_Tile = ZO_CallbackObject:Subclass()

function ZO_Tile:New(...)
    local tile = ZO_CallbackObject.New(self)
    tile:Initialize(...)
    tile:PostInitialize()
    return tile
end

function ZO_Tile:Initialize(control)
    self.control = control
    control.object = self

    if self.InitializePlatform then
        self:InitializePlatform()
    end

    control:SetHandler("OnEffectivelyHidden", function() self:OnControlHidden() end)
    control:SetHandler("OnEffectivelyShown", function() self:OnControlShown() end)
end

function ZO_Tile:PostInitialize()
    if self.PostInitializePlatform then
        self:PostInitializePlatform()
    end
end

function ZO_Tile:GetControl()
    return self.control
end

function ZO_Tile:Reset()
    -- To be overridden    
end

function ZO_Tile:SetHidden(isHidden)
    self.control:SetHidden(isHidden)
end

function ZO_Tile:OnShow()
    -- To be overridden
end

function ZO_Tile:OnHide()
    -- To be overridden
end

function ZO_Tile:OnControlShown()
    if self.dirty then
        self:RefreshLayout()
    end
end

function ZO_Tile:OnControlHidden()
    -- To be overridden
end

function ZO_Tile:RefreshLayout()
    if self.control:IsHidden() then
        self.dirty = true
    else
        self.dirty = false
        self:RefreshLayoutInternal()
        self:FireCallbacks("OnRefreshLayout")
    end
end

-- Can only be called by the Tile class and its subclasses
function ZO_Tile:RefreshLayoutInternal()
    -- To be overridden
end

function ZO_Tile:MarkDirty()
    self.dirty = true
end

function ZO_Tile:Layout(data)
    if self.LayoutPlatform then
        self:LayoutPlatform(data)
    end
end

-------------
-- Global Tile Function
-------------

function ZO_DefaultGridTileHeaderSetup(control, data, selected)
    local label = control:GetNamedChild("Text")
    if label then
        label:SetText(data.header)
    end
end

function ZO_DefaultGridTileEntrySetup(control, data)
    if not data.isEmptyCell then
        control.object:Layout(data)
    end
end

function ZO_DefaultGridTileEntryReset(control)
    ZO_ObjectPool_DefaultResetControl(control)
    control.object:Reset()
end
