local ZO_PlayerEmoteQuickslot = ZO_InteractiveRadialMenuController:Subclass()

function ZO_PlayerEmoteQuickslot:New(...)
    return ZO_InteractiveRadialMenuController.New(self, ...)
end

function ZO_PlayerEmoteQuickslot:Initialize(control, entryTemplate, animationTemplate, entryAnimationTemplate)
    ZO_InteractiveRadialMenuController.Initialize(self, control, entryTemplate, animationTemplate, entryAnimationTemplate)
end

-- functions overridden from base
function ZO_PlayerEmoteQuickslot:PrepareForInteraction()
    if not SCENE_MANAGER:IsShowing("hud") then
        return false
    end
    return true
end

function ZO_PlayerEmoteQuickslot:SetupEntryControl(control, data)
    if data then
        control.label:SetText(data.name)
        if data.selected then
            if control.glow then
                 control.glow:SetAlpha(1)
            end
            control.animation:GetLastAnimation():SetAnimatedControl(nil)
        else
            if control.glow then
                 control.glow:SetAlpha(0)
            end
            control.animation:GetLastAnimation():SetAnimatedControl(control.glow)
        end

        if IsInGamepadPreferredMode() then
		    control.label:SetFont("ZoFontGamepad54")
	    else
		    control.label:SetFont("ZoInteractionPrompt")
	    end
    end
end

local EMPTY_QUICKSLOT_TEXTURE = "EsoUI/Art/Quickslots/quickslot_emptySlot.dds"
local EMPTY_QUICKSLOT_STRING = GetString(SI_QUICKSLOTS_EMPTY)

function ZO_PlayerEmoteQuickslot:PopulateMenu()
    local slottedEmotes = PLAYER_EMOTE_MANAGER:GetSlottedEmotes()
    for i, emote in ipairs(slottedEmotes) do
        local type = emote.type
        local id = emote.id
        
        local found = false
        local name, icon, callback

        if type == ACTION_TYPE_EMOTE then
            local emoteInfo = PLAYER_EMOTE_MANAGER:GetEmoteItemInfo(id)
            found = emoteInfo ~= nil
            if found then
				if emoteInfo.isOverriddenByPersonality then
					icon = GAMEPAD_PLAYER_EMOTE:GetPersonalityEmoteIconForCategory(emoteInfo.emoteCategory)				
					name = ZO_PERSONALITY_EMOTES_COLOR:Colorize(emoteInfo.displayName)
				else
					icon = GAMEPAD_PLAYER_EMOTE:GetEmoteIconForCategory(emoteInfo.emoteCategory)
					name = emoteInfo.displayName
				end

                callback = function() PlayEmoteByIndex(emoteInfo.emoteIndex) end
            end
        elseif type == ACTION_TYPE_QUICK_CHAT then
            found = QUICK_CHAT_MANAGER:HasQuickChat(id)
            if found then
                icon = QUICK_CHAT_MANAGER:GetQuickChatIcon()
                name = QUICK_CHAT_MANAGER:GetFormattedQuickChatName(id)
                callback = function() QUICK_CHAT_MANAGER:PlayQuickChat(id) end
            end
        end
        
        if found then
            local data = {name = name}
            self.menu:AddEntry(name, icon, icon, callback, data)
        else
            self.menu:AddEntry(EMPTY_QUICKSLOT_STRING, EMPTY_QUICKSLOT_TEXTURE, EMPTY_QUICKSLOT_TEXTURE, nil, {name=EMPTY_QUICKSLOT_STRING})
        end
    end
end

-- Global Functions

function ZO_PlayerEmoteRadialMenuEntryTemplate_OnInitialized(self)
    self.label = self:GetNamedChild("Label")
    ZO_SelectableItemRadialMenuEntryTemplate_OnInitialized(self)
end

function ZO_PlayerEmoteQuickslot_Initialize(control)
    PLAYER_EMOTE_QUICKSLOT = ZO_PlayerEmoteQuickslot:New(control, "ZO_PlayerEmoteRadialMenuEntryTemplate", nil, "SelectableItemRadialMenuEntryAnimation")
end