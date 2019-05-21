------------------
-- Guild Finder --
------------------

ZO_GUILD_FINDER_APPLICATIONS_KEYBOARD_ENTRY_HEIGHT = 32

ZO_GuildFinder_Applications_Keyboard = ZO_GuildFinder_Panel_Shared:Subclass()

function ZO_GuildFinder_Applications_Keyboard:New(...)
    return ZO_GuildFinder_Panel_Shared.New(self, ...)
end

function ZO_GuildFinder_Applications_Keyboard:Initialize(control)
    ZO_GuildFinder_Panel_Shared.Initialize(self, control)
    self.subcategoryManagers = {}
end

function ZO_GuildFinder_Applications_Keyboard:SetSubcategoryValue(newValue)
    if self.subcategoryValue ~= newValue then
        self:HideCategory()

        self.subcategoryValue = newValue

        self:ShowCategory()
    end
end

function ZO_GuildFinder_Applications_Keyboard:ShowCategory()
    if self.subcategoryValue then
        self.subcategoryManagers[self.subcategoryValue]:ShowCategory()
    end
end

function ZO_GuildFinder_Applications_Keyboard:HideCategory()
    if self.subcategoryValue then
        self.subcategoryManagers[self.subcategoryValue]:HideCategory()
    end
end

function ZO_GuildFinder_Applications_Keyboard:SetSubcategoryManager(subcategory, manager)
    self.subcategoryManagers[subcategory] = manager
end

function ZO_GuildFinder_Applications_Keyboard:GetSubcategoryManager(subcategory)
    return self.subcategoryManagers[subcategory]
end