do
    local pendingJumpToGroupLeaderPrompt = nil

    local function TryShowJumpToGroupLeaderPrompt()
        --LFG groups use their own jump notification
        if IsInLFGGroup() then
            return
        end

        local isGamepadMode = IsInGamepadPreferredMode()

        --Gamepad dialogs are attached to scenes, so if one isn't ready on load, then defer it to EVENT_PLAYER_ACTIVATED
        if isGamepadMode and not SCENE_MANAGER:GetCurrentScene() then
            return
        end

        --The location of the group leader may not be available immediately
        if(pendingJumpToGroupLeaderPrompt) then
            local groupLeaderUnitTag = GetGroupLeaderUnitTag()
            local groupLeaderZoneName = GetUnitZone(groupLeaderUnitTag)
            if(groupLeaderZoneName ~= "") then
                pendingJumpToGroupLeaderPrompt = nil
                if(IsGroupMemberInRemoteRegion(groupLeaderUnitTag)) then
                    local canJump, result = CanJumpToGroupMember(groupLeaderUnitTag)
                    if canJump then
                        if(GetUnitZone("player") == groupLeaderZoneName) then
                            ZO_Dialogs_ShowPlatformDialog("JUMP_TO_GROUP_LEADER_OCCURANCE_PROMPT", nil, {mainTextParams = {groupLeaderZoneName}})
                        else
                            ZO_Dialogs_ShowPlatformDialog("JUMP_TO_GROUP_LEADER_WORLD_PROMPT", nil, {mainTextParams = {groupLeaderZoneName}})
                        end
                    elseif result == JUMP_TO_PLAYER_RESULT_ZONE_COLLECTIBLE_LOCKED then
                        local zoneIndex = GetUnitZoneIndex(groupLeaderUnitTag)
                        local collectibleId = GetCollectibleIdForZone(zoneIndex)
                        local categoryName, collectibleName = ZO_GetCollectibleCategoryAndName(collectibleId)
                        ZO_Dialogs_ShowPlatformDialog("JUMP_TO_GROUP_LEADER_WORLD_COLLECTIBLE_LOCKED_PROMPT", { collectibleName = collectibleName }, { mainTextParams = { groupLeaderZoneName, collectibleName, categoryName } })
                    end
                end
            end
        end
    end

    local function OnUnitCreated(unitTag)
        if ZO_Group_IsGroupUnitTag(unitTag) then
            TryShowJumpToGroupLeaderPrompt()     
        end
    end
    local function OnGroupMemberJoined(rawCharacterName)
        if(GetRawUnitName("player") == rawCharacterName) then
            local groupLeaderUnitTag = GetGroupLeaderUnitTag()
            if(not AreUnitsEqual(groupLeaderUnitTag, "player")) then
                pendingJumpToGroupLeaderPrompt = true
                TryShowJumpToGroupLeaderPrompt()
            end
        end
    end
    local function OnZoneUpdate(unitTag, newZone)
        if(ZO_Group_IsGroupUnitTag(unitTag)) then
            TryShowJumpToGroupLeaderPrompt()
        end
    end
    local function OnPlayerActivated()
        if pendingJumpToGroupLeaderPrompt then
            TryShowJumpToGroupLeaderPrompt()
        end
    end
    local function OnLeaderUpdate()
        if pendingJumpToGroupLeaderPrompt then
            TryShowJumpToGroupLeaderPrompt()
        end
    end

    EVENT_MANAGER:RegisterForEvent("JumpToLeader_OnUnitCreated", EVENT_UNIT_CREATED, function(event, ...) OnUnitCreated(...) end)
    EVENT_MANAGER:RegisterForEvent("JumpToLeader_OnGroupMemberJoined", EVENT_GROUP_MEMBER_JOINED, function(event, ...) OnGroupMemberJoined(...) end)
    EVENT_MANAGER:RegisterForEvent("JumpToLeader_OnZoneUpdate", EVENT_ZONE_UPDATE, function(event, ...) OnZoneUpdate(...) end)
    EVENT_MANAGER:RegisterForEvent("JumpToLeader_OnPlayerActivated", EVENT_PLAYER_ACTIVATED, function(event, ...) OnPlayerActivated(...) end)
    EVENT_MANAGER:RegisterForEvent("JumpToLeader_OnLeaderUpdate", EVENT_LEADER_UPDATE, function(eventCode, ...) OnLeaderUpdate(...) end)
end