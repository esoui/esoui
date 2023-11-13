
-- Group Listing Base Data

ZO_GroupListingData_Base = ZO_InitializingObject:Subclass()

ZO_GroupListingData_Base.GetTitle = ZO_GroupListingData_Base:MUST_IMPLEMENT()
ZO_GroupListingData_Base.GetCategory = ZO_GroupListingData_Base:MUST_IMPLEMENT()
ZO_GroupListingData_Base.GetSize = ZO_GroupListingData_Base:MUST_IMPLEMENT()
ZO_GroupListingData_Base.GetNumRoles = ZO_GroupListingData_Base:MUST_IMPLEMENT()
ZO_GroupListingData_Base.GetDescription = ZO_GroupListingData_Base:MUST_IMPLEMENT()
ZO_GroupListingData_Base.GetPlaystyle = ZO_GroupListingData_Base:MUST_IMPLEMENT()
-- Expects roleType as a parameter
-- Should return desiredCount and attainedCount
ZO_GroupListingData_Base.GetRoleStatusCount = ZO_GroupListingData_Base:MUST_IMPLEMENT()
ZO_GroupListingData_Base.DoesGroupRequireChampion = ZO_GroupListingData_Base:MUST_IMPLEMENT()
ZO_GroupListingData_Base.DoesGroupRequireVOIP = ZO_GroupListingData_Base:MUST_IMPLEMENT()
ZO_GroupListingData_Base.DoesGroupRequireInviteCode = ZO_GroupListingData_Base:MUST_IMPLEMENT()
ZO_GroupListingData_Base.DoesGroupAutoAcceptRequests = ZO_GroupListingData_Base:MUST_IMPLEMENT()
ZO_GroupListingData_Base.GetChampionPoints = ZO_GroupListingData_Base:MUST_IMPLEMENT()
ZO_GroupListingData_Base.GetDesiredRoleCount = ZO_GroupListingData_Base:MUST_IMPLEMENT()
ZO_GroupListingData_Base.GetAttainedRoleCount = ZO_GroupListingData_Base:MUST_IMPLEMENT()

ZO_GroupListingData_Base.GetStatusIndicatorIcon = ZO_GroupListingData_Base:MUST_IMPLEMENT()
ZO_GroupListingData_Base.GetStatusIndicatorText = ZO_GroupListingData_Base:MUST_IMPLEMENT()
ZO_GroupListingData_Base.GetWarningText = ZO_GroupListingData_Base:MUST_IMPLEMENT()
ZO_GroupListingData_Base.GetJoinabilityResult = ZO_GroupListingData_Base:MUST_IMPLEMENT()

-- Group Listing Search Data

ZO_GroupListingSearchData = ZO_GroupListingData_Base:Subclass()

function ZO_GroupListingSearchData:Initialize(listingIndex)
    local primaryOptionText, secondaryOptionText = GetGroupFinderSearchListingOptionsSelectionTextByIndex(listingIndex)

    self.listingIndex = listingIndex
    self.category = GetGroupFinderSearchListingCategoryByIndex(listingIndex)
    self.primaryOptionText = primaryOptionText
    self.secondaryOptionText = secondaryOptionText
    self.size = GetGroupFinderSearchListingGroupSizeByIndex(listingIndex)
    self.numRoles = GetGroupFinderSearchListingNumRolesByIndex(listingIndex)
end

function ZO_GroupListingSearchData:GetListingIndex()
    return self.listingIndex
end

function ZO_GroupListingSearchData:GetTitle()
    return GetGroupFinderSearchListingTitleByIndex(self:GetListingIndex())
end

function ZO_GroupListingSearchData:GetCategory()
    return self.category
end

function ZO_GroupListingSearchData:GetPrimaryOptionText()
    return self.primaryOptionText
end

function ZO_GroupListingSearchData:GetSecondaryOptionText()
    return self.secondaryOptionText
end

function ZO_GroupListingSearchData:GetSize()
    return self.size
end

function ZO_GroupListingSearchData:GetNumRoles()
    return self.numRoles
end

function ZO_GroupListingSearchData:GetDescription()
    return GetGroupFinderSearchListingDescriptionByIndex(self:GetListingIndex())
end

function ZO_GroupListingSearchData:GetOwnerDisplayName()
    return GetGroupFinderSearchListingLeaderDisplayNameByIndex(self:GetListingIndex())
end

function ZO_GroupListingSearchData:GetOwnerCharacterName()
    return GetGroupFinderSearchListingLeaderCharacterNameByIndex(self:GetListingIndex())
end

function ZO_GroupListingSearchData:GetPlaystyle()
    return GetGroupFinderSearchListingPlaystyleByIndex(self:GetListingIndex())
end

function ZO_GroupListingSearchData:GetRoleStatusCount(roleType)
    return GetGroupFinderSearchListingRoleStatusCount(self:GetListingIndex(), roleType)
end

function ZO_GroupListingSearchData:DoesGroupRequireChampion()
    return DoesGroupFinderSearchListingRequireChampion(self:GetListingIndex())
end

function ZO_GroupListingSearchData:DoesGroupRequireVOIP()
    return DoesGroupFinderSearchListingRequireVOIP(self:GetListingIndex())
end

function ZO_GroupListingSearchData:DoesGroupRequireInviteCode()
    return DoesGroupFinderSearchListingRequireInviteCode(self:GetListingIndex())
end

function ZO_GroupListingSearchData:DoesGroupAutoAcceptRequests()
    return DoesGroupFinderSearchListingAutoAcceptRequests(self:GetListingIndex())
end

function ZO_GroupListingSearchData:GetChampionPoints()
    return GetGroupFinderSearchListingChampionPointsByIndex(self:GetListingIndex())
end

function ZO_GroupListingSearchData:GetDesiredRoleCount(roleType)
    local desiredCount, attainedCount = GetGroupFinderSearchListingRoleStatusCount(self:GetListingIndex(), roleType)
    return desiredCount
end

function ZO_GroupListingSearchData:GetAttainedRoleCount(roleType)
    local desiredCount, attainedCount = GetGroupFinderSearchListingRoleStatusCount(self:GetListingIndex(), roleType)
    return attainedCount
end

function ZO_GroupListingSearchData:GetAttainedRoleCount(roleType)
    return GetGroupFinderUserTypeGroupListingAttainedRoleCount(self:GetInternalUserType(), roleType)
end

function ZO_GroupListingSearchData:GetStatusIndicatorIcon()
    local joinabilityResult = self:GetJoinabilityResult()
    if joinabilityResult == GROUP_FINDER_ACTION_RESULT_FAILED_ENTITLEMENT_REQUIREMENT then
        if IsInGamepadPreferredMode() then
            return "EsoUI/Art/LFG/Gamepad/gp_LFG_groupFinder_tooltip_dlc_required.dds"
        else
            return "EsoUI/Art/LFG/LFG_groupFinder_tooltip_dlc_required.dds"
        end
    end
end

function ZO_GroupListingSearchData:GetStatusIndicatorText()
    local joinabilityResult = self:GetJoinabilityResult()
    if joinabilityResult == GROUP_FINDER_ACTION_RESULT_FAILED_ENTITLEMENT_REQUIREMENT then
        return GetString(SI_GROUP_FINDER_TOOLTIP_REQUIRES_DLC_LABEL)
    end
end

function ZO_GroupListingSearchData:GetWarningText()
    local joinabilityResult = self:GetJoinabilityResult()
    if joinabilityResult == GROUP_FINDER_ACTION_RESULT_FAILED_ALREADY_JOINED_GROUP
    or joinabilityResult == GROUP_FINDER_ACTION_RESULT_FAILED_ROLE_REQUIREMENT
    or joinabilityResult == GROUP_FINDER_ACTION_RESULT_FAILED_LISTING_NOT_AVAILABLE
    or joinabilityResult == GROUP_FINDER_ACTION_RESULT_FAILED_CP_REQUIREMENT then
        return GetString("SI_GROUPFINDERACTIONRESULT", joinabilityResult)
    end
end

function ZO_GroupListingSearchData:GetJoinabilityResult()
    return GetGroupFinderSearchListingJoinabilityResult(self:GetListingIndex())
end

function ZO_GroupListingSearchData:IsActiveApplication()
    return IsGroupFinderSearchListingActiveApplication(self:GetListingIndex())
end

function ZO_GroupListingSearchData:GetFirstLockingCollectibleId()
    return GetGroupFinderSearchListingFirstLockingCollectibleId(self:GetListingIndex())
end

-- Group Listing User Type Data

ZO_GroupListingUserTypeData = ZO_GroupListingData_Base:Subclass()

function ZO_GroupListingUserTypeData:Initialize(userType, isEditable)
    self.userType = userType
    self.editableUserType = isEditable and userType or nil
    self.attainedRolesAtEdit = {}
    self.desiredRolesAtEdit = {}
end

function ZO_GroupListingUserTypeData:SetUserType(userType)
    self.userType = userType
end

function ZO_GroupListingUserTypeData:SetEditableUserType(editableUserType)
    self.editableUserType = editableUserType
end

function ZO_GroupListingUserTypeData:GetUserType()
    return self.userType
end

function ZO_GroupListingUserTypeData:GetInternalUserType()
    return self.editableUserType or self.userType
end

function ZO_GroupListingUserTypeData:HasUserTypeChanged()
    return HasUserTypeGroupListingChanged(self:GetInternalUserType())
end

function ZO_GroupListingUserTypeData:IsUserTypeActive()
    return HasGroupListingForUserType(self.userType)
end

function ZO_GroupListingUserTypeData:UpdateOptions()
    UpdateGroupFinderUserTypeGroupListingOptions(self:GetInternalUserType())
end

function ZO_GroupListingUserTypeData:SetTitle(title)
    SetGroupFinderUserTypeGroupListingTitle(self:GetInternalUserType(), title)
end

function ZO_GroupListingUserTypeData:GetTitle()
    return GetGroupFinderUserTypeGroupListingTitle(self:GetInternalUserType())
end

function ZO_GroupListingUserTypeData:SetCategory(category)
    SetGroupFinderUserTypeGroupListingCategory(self:GetInternalUserType(), category)
end

function ZO_GroupListingUserTypeData:GetCategory()
    return GetGroupFinderUserTypeGroupListingCategory(self:GetInternalUserType())
end

function ZO_GroupListingUserTypeData:SetPrimaryOption(index)
    SetGroupFinderUserTypeGroupListingPrimaryOption(self:GetInternalUserType(), index)
end

function ZO_GroupListingUserTypeData:GetNumPrimaryOptions()
    return GetGroupFinderUserTypeGroupListingNumPrimaryOptions(self:GetInternalUserType())
end

function ZO_GroupListingUserTypeData:GetPrimaryOptionByIndex(index)
    return GetGroupFinderUserTypeGroupListingPrimaryOptionByIndex(self:GetInternalUserType(), index)
end

function ZO_GroupListingUserTypeData:GetPrimaryOptionText()
    local primaryOptionText, secondaryOptionText = GetGroupFinderUserTypeGroupListingOptionsSelectionText(self:GetInternalUserType())
    return primaryOptionText
end

function ZO_GroupListingUserTypeData:SetSecondaryOption(index)
    SetGroupFinderUserTypeGroupListingSecondaryOption(self:GetInternalUserType(), index)
end

function ZO_GroupListingUserTypeData:GetNumSecondaryOptions()
    return GetGroupFinderUserTypeGroupListingNumSecondaryOptions(self:GetInternalUserType())
end

function ZO_GroupListingUserTypeData:GetSecondaryOptionByIndex(index)
    return GetGroupFinderUserTypeGroupListingSecondaryOptionByIndex(self:GetInternalUserType(), index)
end

function ZO_GroupListingUserTypeData:GetSecondaryOptionText()
    local primaryOptionText, secondaryOptionText = GetGroupFinderUserTypeGroupListingOptionsSelectionText(self:GetInternalUserType())
    return secondaryOptionText
end

function ZO_GroupListingUserTypeData:SetSize(index)
    SetGroupFinderUserTypeGroupListingGroupSize(self:GetInternalUserType(), index)
end

function ZO_GroupListingUserTypeData:GetSize()
    return GetGroupFinderUserTypeGroupListingGroupSize(self:GetInternalUserType())
end

function ZO_GroupListingUserTypeData:GetSizeMin()
    return GetGroupFinderUserTypeGroupSizeIterationBegin(self:GetInternalUserType())
end

function ZO_GroupListingUserTypeData:GetSizeMax()
    return GetGroupFinderUserTypeGroupSizeIterationEnd(self:GetInternalUserType())
end

function ZO_GroupListingUserTypeData:GetNumRoles()
    return GetGroupFinderUserTypeGroupListingNumRoles(self:GetInternalUserType())
end

function ZO_GroupListingUserTypeData:SetDescription(description)
    SetGroupFinderUserTypeGroupListingDescription(self:GetInternalUserType(), description)
end

function ZO_GroupListingUserTypeData:GetDescription()
    return GetGroupFinderUserTypeGroupListingDescription(self:GetInternalUserType())
end

function ZO_GroupListingUserTypeData:GetOwnerDisplayName()
    return GetGroupFinderUserTypeGroupListingLeaderDisplayName(self:GetInternalUserType())
end

function ZO_GroupListingUserTypeData:GetOwnerCharacterName()
    return GetGroupFinderUserTypeGroupListingLeaderCharacterName(self:GetInternalUserType())
end

function ZO_GroupListingUserTypeData:SetPlaystyle(index)
    SetGroupFinderUserTypeGroupListingPlaystyle(self:GetInternalUserType(), index)
end

function ZO_GroupListingUserTypeData:GetPlaystyle()
    return GetGroupFinderUserTypeGroupListingPlaystyle(self:GetInternalUserType())
end

function ZO_GroupListingUserTypeData:GetRoleStatusCount(roleType)
    local desiredCount = self:GetDesiredRoleCount(roleType)
    local attainedCount = self:GetAttainedRoleCount(roleType)
    return desiredCount, attainedCount
end

function ZO_GroupListingUserTypeData:SetGroupRequiresChampion(setValue)
    SetGroupFinderUserTypeGroupListingRequiresChampion(self:GetInternalUserType(), setValue)
end

function ZO_GroupListingUserTypeData:DoesGroupRequireChampion()
    return DoesGroupFinderUserTypeGroupListingRequireChampion(self:GetInternalUserType())
end

function ZO_GroupListingUserTypeData:SetGroupRequiresVOIP(setValue)
    SetGroupFinderUserTypeGroupListingRequiresVOIP(self:GetInternalUserType(), setValue)
end

function ZO_GroupListingUserTypeData:DoesGroupRequireVOIP()
    return DoesGroupFinderUserTypeGroupListingRequireVOIP(self:GetInternalUserType())
end

function ZO_GroupListingUserTypeData:SetGroupRequiresInviteCode(setValue)
    SetGroupFinderUserTypeGroupListingRequiresInviteCode(self:GetInternalUserType(), setValue)
end

function ZO_GroupListingUserTypeData:DoesGroupRequireInviteCode()
    return DoesGroupFinderUserTypeGroupListingRequireInviteCode(self:GetInternalUserType())
end

function ZO_GroupListingUserTypeData:SetGroupAutoAcceptRequests(setValue)
    SetGroupFinderUserTypeGroupListingAutoAcceptRequests(self:GetInternalUserType(), setValue)
end

function ZO_GroupListingUserTypeData:DoesGroupAutoAcceptRequests()
    return DoesGroupFinderUserTypeGroupListingAutoAcceptRequests(self:GetInternalUserType())
end

function ZO_GroupListingUserTypeData:SetGroupEnforceRoles(setValue)
    SetGroupFinderUserTypeGroupListingEnforceRoles(self:GetInternalUserType(), setValue)
end

function ZO_GroupListingUserTypeData:DoesGroupEnforceRoles()
    return DoesGroupFinderUserTypeGroupListingEnforceRoles(self:GetInternalUserType())
end

function ZO_GroupListingUserTypeData:SetChampionPoints(championPoints)
    SetGroupFinderUserTypeGroupListingChampionPoints(self:GetInternalUserType(), championPoints)
end

function ZO_GroupListingUserTypeData:GetChampionPoints()
    return GetGroupFinderCreateGroupListingChampionPoints(self:GetInternalUserType())
end

function ZO_GroupListingUserTypeData:SetInviteCode(inviteCode)
    SetGroupFinderUserTypeGroupListingInviteCode(self:GetInternalUserType(), inviteCode)
end

function ZO_GroupListingUserTypeData:GetInviteCode()
    return GetGroupFinderUserTypeGroupListingInviteCode(self:GetInternalUserType())
end

function ZO_GroupListingUserTypeData:SetDesiredRoleCount(roleType, count)
    SetGroupFinderUserTypeGroupListingRoleCount(self:GetInternalUserType(), roleType, count)
end

function ZO_GroupListingUserTypeData:GetDesiredRoleCount(roleType)
    return GetGroupFinderUserTypeGroupListingDesiredRoleCount(self:GetInternalUserType(), roleType)
end

function ZO_GroupListingUserTypeData:UpdateDesiredRoleCountAtEdit(roleType)
    self.desiredRolesAtEdit[roleType] = self:GetDesiredRoleCount(roleType)
end

function ZO_GroupListingUserTypeData:SetDesiredRoleCountAtEdit(roleType, value)
    self.desiredRolesAtEdit[roleType] = value
    local currentNumDesiredRoles = 0
    for iteratorRoleType, count in pairs(self.desiredRolesAtEdit) do
        if iteratorRoleType ~= LFG_ROLE_INVALID then
            self:SetDesiredRoleCount(iteratorRoleType, count)
            currentNumDesiredRoles = currentNumDesiredRoles + count
        end
    end
    self.desiredRolesAtEdit[LFG_ROLE_INVALID] = GetGroupFinderUserTypeGroupListingNumRoles(GetCurrentGroupFinderUserType()) - currentNumDesiredRoles
    self:SetDesiredRoleCount(LFG_ROLE_INVALID, self.desiredRolesAtEdit[LFG_ROLE_INVALID])
end

function ZO_GroupListingUserTypeData:GetDesiredRoleCountAtEdit(roleType)
    return self.desiredRolesAtEdit[roleType]
end

function ZO_GroupListingUserTypeData:GetAttainedRoleCount(roleType)
    return GetGroupFinderUserTypeGroupListingAttainedRoleCount(self:GetInternalUserType(), roleType)
end

function ZO_GroupListingUserTypeData:UpdateAttainedRoleCountAtEdit(roleType)
    self.attainedRolesAtEdit[roleType] = self:GetAttainedRoleCount(roleType)
end

function ZO_GroupListingUserTypeData:GetAttainedRoleCountAtEdit(roleType)
    return self.attainedRolesAtEdit[roleType]
end

function ZO_GroupListingUserTypeData:DoesDesiredRolesMatchAttainedRoles()
    return DoesGroupFinderUserTypeGroupListingDesiredRolesMatchAttainedRoles(self:GetInternalUserType())
end

function ZO_GroupListingUserTypeData:GetStatusIndicatorIcon()
    if self:GetUserType() == GROUP_FINDER_GROUP_LISTING_USER_TYPE_APPLIED_TO_GROUP_LISTING then
        if IsInGamepadPreferredMode() then
            return "EsoUI/Art/LFG/Gamepad/gp_LFG_groupFinder_tooltip_applied.dds"
        else
            return "EsoUI/Art/LFG/LFG_groupFinder_tooltip_applied.dds"
        end
    end
end

function ZO_GroupListingUserTypeData:GetStatusIndicatorText()
    if self:GetUserType() == GROUP_FINDER_GROUP_LISTING_USER_TYPE_APPLIED_TO_GROUP_LISTING then
        return GetString(SI_GROUP_FINDER_TOOLTIP_APPLIED_LABEL)
    end
end

function ZO_GroupListingUserTypeData:GetWarningText()
    -- This function is only used for search results, but it's called from shared code,
    -- so it needs to exist on UserTypeData as well.
end

function ZO_GroupListingUserTypeData:GetJoinabilityResult()
    -- This function is only used for search results, but it's called from shared code,
    -- so it needs to exist on UserTypeData as well.
end

-- Group Finder Pending Application Data
ZO_GroupFinderPendingApplicationData = ZO_InitializingObject:Subclass()

function ZO_GroupFinderPendingApplicationData:Initialize(applicantCharacterId)
    local displayName, characterName, classId, level, championPoints, role = GetGroupListingApplicationInfoByCharacterId(applicantCharacterId)

    self.characterId = applicantCharacterId
    self.displayName = displayName
    self.characterName = characterName
    self.classId = classId
    self.level = level
    self.championPoints = championPoints
    self.role = role
    self.endTimeS = GetFrameTimeSeconds() + self:GetTimeRemainingSeconds()
end

function ZO_GroupFinderPendingApplicationData:GetCharacterId()
    return self.characterId
end

function ZO_GroupFinderPendingApplicationData:GetDisplayName()
    return self.displayName
end

function ZO_GroupFinderPendingApplicationData:GetFormattedDisplayName()
    return ZO_FormatUserFacingDisplayName(self:GetDisplayName())
end

function ZO_GroupFinderPendingApplicationData:GetCharacterName()
    return self.characterName
end

function ZO_GroupFinderPendingApplicationData:GetClassId()
    return self.classId
end

function ZO_GroupFinderPendingApplicationData:GetClassName()
    local gender = GetGenderFromNameDescriptor(self.characterName)
    return zo_strformat(SI_CLASS_NAME, GetClassName(gender, self.classId))
end

function ZO_GroupFinderPendingApplicationData:GetClassIcon()
    if IsInGamepadPreferredMode() then
        return ZO_GetGamepadClassIcon(self.classId)
    else
        return ZO_GetClassIcon(self.classId)
    end
end

function ZO_GroupFinderPendingApplicationData:GetLevel()
    return self.level
end

function ZO_GroupFinderPendingApplicationData:GetChampionPoints()
    return self.championPoints
end

function ZO_GroupFinderPendingApplicationData:GetRole()
    return self.role
end

function ZO_GroupFinderPendingApplicationData:GetNote()
    if not self.note then
        self.note = GetGroupListingApplicationNoteByCharacterId(self.characterId)
    end
    return self.note
end

function ZO_GroupFinderPendingApplicationData:GetEndTimeSeconds()
    return self.endTimeS
end

function ZO_GroupFinderPendingApplicationData:GetTimeRemainingSeconds()
    return GetGroupListingApplicationTimeRemainingSecondsByCharacterId(self.characterId)
end

function ZO_GroupFinderPendingApplicationData:IsInPendingState()
    return IsGroupListingApplicationPendingByCharacterId(self.characterId)
end