local AddOnManager = GetAddOnManager()

function ZO_Tooltip:LayoutAddOnTooltip(data, isSpecificCharacterSelected)
    --Things added to the top section stack downward
    local topSection = self:AcquireSection(self:GetStyle("addOnTopSection"))

    local _, _, _, description, enabled, _, isOutOfDate = AddOnManager:GetAddOnInfo(data.addOnIndex)

    -- Does the addon have a dependency?
    if data.hasDependencyError then
        topSection:AddLine(ZO_ERROR_COLOR:Colorize(GetString("SI_ADDONLOADSTATE", ADDON_STATE_DEPENDENCIES_DISABLED)))
    end
    
    -- Is the addon out of date?
    if isOutOfDate then
        topSection:AddLine(GetString("SI_ADDONLOADSTATE", ADDON_STATE_VERSION_MISMATCH))
    end
    
    -- Determine whether the addon is enabled or disabled
    local showEnabled
    if isSpecificCharacterSelected then
        local canEnable = HasAgreedToEULA(EULA_TYPE_ADDON_EULA) and not data.hasDependencyError
        showEnabled = canEnable and enabled
    else
        showEnabled = HasAgreedToEULA(EULA_TYPE_ADDON_EULA) and not data.allDisabled
    end

    if showEnabled then
        topSection:AddLine(GetString(SI_GAMEPAD_ADDON_MANAGER_TOOLTIP_ENABLED))
    else
        topSection:AddLine(GetString(SI_GAMEPAD_ADDON_MANAGER_TOOLTIP_DISABLED))
    end
    self:AddSection(topSection)

    --Add the addon name
    self:AddLine(data.addOnName, self:GetStyle("addOnName"))

    --Add the author
    local authorSection = self:AcquireSection(self:GetStyle("addOnAuthorSection"))
    authorSection:AddLine(data.addOnAuthorByLine)
    self:AddSection(authorSection)

    --Add the description if there is one
    if description ~= "" then
        local bodySection = self:AcquireSection(self:GetStyle("bodySection"))
        bodySection:AddLine(description, self:GetStyle("bodyDescription"))
        self:AddSection(bodySection)
    end

    -- Add the dependency text if there is any
    if data.addOnDependencyText ~= "" then
        local dependencySection = self:AcquireSection(self:GetStyle("bodySection"))
        dependencySection:AddLine(GetString(SI_ADDON_MANAGER_DEPENDENCIES), self:GetStyle("bodyHeader"))
        dependencySection:AddLine(data.addOnDependencyText, self:GetStyle("bodyDescription"))
        self:AddSection(dependencySection)
    end

    -- If a specific character is not selected, include additional information about the enabled state of the addon
    if not isSpecificCharacterSelected then
        local enableSection = self:AcquireSection(self:GetStyle("bodySection"))
        if data.allEnabled then
            enableSection:AddLine(GetString(SI_ADDON_MANAGER_TOOLTIP_ENABLED_ALL), self:GetStyle("bodyDescription"))
        elseif data.allDisabled then
            enableSection:AddLine(GetString(SI_ADDON_MANAGER_TOOLTIP_ENABLED_NONE), self:GetStyle("bodyDescription"))
        else
            enableSection:AddLine(GetString(SI_ADDON_MANAGER_TOOLTIP_ENABLED_SOME), self:GetStyle("bodyDescription"))
        end
        self:AddSection(enableSection)
    end
end