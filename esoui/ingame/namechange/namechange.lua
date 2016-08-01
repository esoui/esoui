ZO_NameChange = ZO_Object:Subclass()

function ZO_NameChange:New()
    local obj = ZO_Object.New(self)
    obj:Initialize()
    return obj
end

function ZO_NameChange:Initialize()
    EVENT_MANAGER:RegisterForEvent("ZO_NameChange", EVENT_ADD_ON_LOADED, function(_, addOnName)
        if addOnName == "ZO_Ingame" then
            local sv = ZO_SavedVars:NewAccountWide("ZO_Ingame_SavedVariables", 1, "NameChange", {})

            --initialize all of the id to name mappings on the first login so if they buy a bunch of rename tokens we have all
            --the mappings built for each character
            for i = 1, GetNumCharacters() do
                local name, _, _, _, _, _, characterId = GetCharacterInfo(i)
                if sv[characterId] == nil then
                    --Strip the grammar markup
                    sv[characterId] = zo_strformat("<<1>>", name)
                end
            end

            local characterId = GetCurrentCharacterId()
            self.oldCharacterName = sv[characterId]
            self.newCharacterName = GetUnitName("player")
            sv[characterId] = self.newCharacterName
        end
    end)   
end

function ZO_NameChange:DidNameChange()
    return self.oldCharacterName ~= self.newCharacterName
end

function ZO_NameChange:GetOldCharacterName()
    return self.oldCharacterName
end

NAME_CHANGE = ZO_NameChange:New()