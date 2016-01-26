function ZO_Tooltip:LayoutCollectibleFromLink(collectibleLink)
    local collectibleId = GetCollectibleIdFromLink(collectibleLink)
    if collectibleId then
        local name, description, _, _, _, purchasable, _, _, hint, isPlaceholder = GetCollectibleInfo(collectibleId)
        local nickname = GetCollectibleNickname(collectibleId)
        local unlockState = GetCollectibleUnlockStateById(collectibleId)
        self:LayoutCollectible(nil, name, nickname, unlockState, purchaseable, description, hint, isPlaceholder)
    end
end

function ZO_Tooltip:LayoutCollectible(collectionName, collectibleName, collectibleNickname, unlockState, isPurchasable, description, hint, isPlaceholder)
    if not isPlaceholder then
        --things added to the topSection stack upwards
        local topSection = self:AcquireSection(self:GetStyle("topSection"))

        if collectionName then
            topSection:AddLine(zo_strformat(SI_COLLECTIBLE_NAME_FORMATTER, collectionName))
        end

        topSection:AddLine(GetString("SI_COLLECTIBLEUNLOCKSTATE", unlockState))

        self:AddSection(topSection)
    end

    self:AddLine(zo_strformat(SI_COLLECTIBLE_NAME_FORMATTER, collectibleName), qualityNormal, self:GetStyle("title"))
    
    local headerSection = self:AcquireSection(self:GetStyle("bodyHeader"))

    if collectibleNickname and collectibleNickname ~= "" then
        headerSection:AddLine(zo_strformat(SI_GAMEPAD_COLLECTIONS_NICKNAME_FORMAT, collectibleNickname), qualityNormal, self:GetStyle("bodyHeader"))
    end

    self:AddSection(headerSection)

    local bodySection = self:AcquireSection(self:GetStyle("collectionsInfoSection"))

    if description then
        bodySection:AddLine(zo_strformat(SI_GAMEPAD_COLLECTIONS_DESCRIPTION_FORMATTER, description), self:GetStyle("bodyDescription"))
    end

    if isPurchasable then 
        bodySection:AddLine(GetString(SI_COLLECTIBLE_TOOLTIP_PURCHASABLE), self:GetStyle("bodyDescription"))
    end

    if hint then
        bodySection:AddLine(zo_strformat(SI_GAMEPAD_COLLECTIONS_DESCRIPTION_FORMATTER, hint), self:GetStyle("bodyDescription"))
    end

    self:AddSection(bodySection)
end