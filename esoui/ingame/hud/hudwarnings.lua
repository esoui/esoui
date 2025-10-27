ZO_ForceConsoleWarning = ZO_InitializingObject:Subclass()

function ZO_ForceConsoleWarning:Initialize(control)
    self.control = control

    FORCE_CONSOLE_WARNING_FRAGMENT = ZO_HUDFadeSceneFragment:New(control)
end

function ZO_ForceConsoleWarning.OnControlInitialized(control)
    FORCE_CONSOLE_WARNING = ZO_ForceConsoleWarning:New(control)
end

ZO_AddOnMemoryDisplay = ZO_InitializingObject:Subclass()

if IsConsoleUI() then
    function ZO_AddOnMemoryDisplay:Initialize(control)
        self.control = control
        self.memoryLabel = control:GetNamedChild("Memory")
        self.nextUpdateTimeS = 0
        self.isVisible = false

        if ZO_IsForceConsoleFlow() then
            self.control:SetAnchor(CENTER, FORCE_CONSOLE_WARNING.control, CENTER, 0, -20)
        end

        self.control:SetHandler("OnUpdate", function(_, timeS)
            self:Update(timeS)
        end)

        ADD_ON_MEMORY_DISPLAY_FRAGMENT = ZO_HUDFadeSceneFragment:New(control)

        local function OnAddOnsLoaded(_, name)
            local DEFAULTS = { isVisible = false }
            self.savedVars = ZO_SavedVars:New("ZO_Ingame_SavedVariables", 1, "ZO_AddOnMemoryDisplay", DEFAULTS)
            if self.savedVars.isVisible then
                HUD_SCENE:AddFragment(ADD_ON_MEMORY_DISPLAY_FRAGMENT)
                HUD_UI_SCENE:AddFragment(ADD_ON_MEMORY_DISPLAY_FRAGMENT)
            end
        end
        self.control:RegisterForEvent(EVENT_ADD_ONS_LOADED, OnAddOnsLoaded)
    end

    function ZO_AddOnMemoryDisplay:Update(timeS)
        if self.nextUpdateTimeS < timeS then
            self.nextUpdateTimeS = timeS + 1

            self.memoryLabel:SetText(zo_strformat(SI_CONSOLE_ADDON_MEM_USAGE_FORMATTER, string.format("%.2f", GetTotalUserAddOnMemoryPoolUsageMB()), GetTotalUserAddOnMemoryPoolCapacityMB()))
        end
    end

    function ZO_AddOnMemoryDisplay:Toggle()
        self.savedVars.isVisible = not self.savedVars.isVisible
        if self.savedVars.isVisible then
            HUD_SCENE:AddFragment(ADD_ON_MEMORY_DISPLAY_FRAGMENT)
            HUD_UI_SCENE:AddFragment(ADD_ON_MEMORY_DISPLAY_FRAGMENT)
        else
            HUD_SCENE:RemoveFragment(ADD_ON_MEMORY_DISPLAY_FRAGMENT)
            HUD_UI_SCENE:RemoveFragment(ADD_ON_MEMORY_DISPLAY_FRAGMENT)
        end
    end

    SLASH_COMMANDS[GetString(SI_SLASH_ADD_ON_MEM_DISPLAY)] = function()
        ADD_ON_MEMORY_DISPLAY:Toggle()
    end
end

function ZO_AddOnMemoryDisplay.OnControlInitialized(control)
    if IsConsoleUI() then
        ADD_ON_MEMORY_DISPLAY = ZO_AddOnMemoryDisplay:New(control)
    end
end