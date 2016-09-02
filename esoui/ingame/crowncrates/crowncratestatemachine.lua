ZO_CROWN_CRATE_TRIGGER_COMMANDS =
{
    SCENE_SHOWN = "OnSceneShowing",
    CAT_SUMMON_COMPLETE = "UI_Greet", -- Anim Note
    CAT_GREETING_COMPLETE = "UI_OpenManifest", -- Anim Note
    MANIFEST_IN_COMPLETE = "OnManifestInComplete",
    DEAL_REQUESTED = "OnDealRequested",
    MANIFEST_OUT_COMPLETE = "OnManifestOutComplete",
    PRIMARY_DEAL_COMPLETE_CAT = "UI_Deal_Primary", -- Anim Note
    PRIMARY_DEAL_COMPLETE = "OnPrimaryDealComplete",
    BONUS_DEAL_COMPLETE_CAT = "UI_Deal_Bonus", -- Anim Note
    BONUS_DEAL_COMPLETE = "OnBonusDealComplete",
    CARD_REVEALED = "OnCardRevealed",
    CARD_OUT_COMPLETE = "OnCardOutComplete",
    CARD_DEAL_COMPLETE = "OnCardDealComplete",
    CARD_SELECTED = "OnCardSelected",
    FLIP_CARD = "OnFlipCard",
    CARD_DESELECTED = "OnCardDeselected",
    CARD_FLIP_COMPLETE = "OnFlipComplete",
    CARD_GEMIFY_COMPLETE = "OnGemifyComplete",
    CARD_LEAVE = "OnCardLeave",
    BACK_TO_MANIFEST = "BackToManifest",
}

---------------
--Hand States--
---------------

ZO_CROWN_CRATE_STATE_MACHINE = ZO_StateMachine_Base:New("CROWN_CRATE_STATE_MACHINE")

--States--
ZO_CROWN_CRATE_STATES =
{
    START = ZO_StateMachine_State:New(ZO_CROWN_CRATE_STATE_MACHINE, "START"), --1
    SUMMON_CAT = ZO_StateMachine_State:New(ZO_CROWN_CRATE_STATE_MACHINE, "SUMMON_CAT"), --2
    MANIFEST_IN = ZO_StateMachine_State:New(ZO_CROWN_CRATE_STATE_MACHINE, "MANIFEST_IN"), --3
    MANIFEST = ZO_StateMachine_State:New(ZO_CROWN_CRATE_STATE_MACHINE, "MANIFEST"), --4
    MANIFEST_OUT = ZO_StateMachine_State:New(ZO_CROWN_CRATE_STATE_MACHINE, "MANIFEST_OUT"), --5
    CAT_PRIMARY_DEAL = ZO_StateMachine_State:New(ZO_CROWN_CRATE_STATE_MACHINE, "CAT_PRIMARY_DEAL"), --6
    UI_PRIMARY_DEAL = ZO_StateMachine_State:New(ZO_CROWN_CRATE_STATE_MACHINE, "UI_PRIMARY_DEAL"), --7
    CAT_BONUS_DEAL = ZO_StateMachine_State:New(ZO_CROWN_CRATE_STATE_MACHINE, "CAT_BONUS_DEAL"), --8
    UI_BONUS_DEAL = ZO_StateMachine_State:New(ZO_CROWN_CRATE_STATE_MACHINE, "UI_BONUS_DEAL"), --9
    ACTIVE_HAND_MANIPULATION = ZO_StateMachine_State:New(ZO_CROWN_CRATE_STATE_MACHINE, "ACTIVE_HAND_MANIPULATION"), --10
    ALL_REVEALED = ZO_StateMachine_State:New(ZO_CROWN_CRATE_STATE_MACHINE, "ALL_REVEALED"), --11
    CARDS_OUT_BACK = ZO_StateMachine_State:New(ZO_CROWN_CRATE_STATE_MACHINE, "CARDS_OUT_BACK"), --12
    CARDS_OUT_NEXT = ZO_StateMachine_State:New(ZO_CROWN_CRATE_STATE_MACHINE, "CARDS_OUT_NEXT"), --13
    FRAMING_PLAYER = ZO_StateMachine_State:New(ZO_CROWN_CRATE_STATE_MACHINE, "FRAMING_PLAYER"), --14
}

--Edges--
ZO_CROWN_CRATE_EDGES =
{
    START_TO_FRAMING_PLAYER = ZO_StateMachine_Edge:New(ZO_CROWN_CRATE_STATES.START, ZO_CROWN_CRATE_STATES.FRAMING_PLAYER), --1 -> 14
    FRAMING_PLAYER_TO_SUMMON_CAT = ZO_StateMachine_Edge:New(ZO_CROWN_CRATE_STATES.FRAMING_PLAYER, ZO_CROWN_CRATE_STATES.SUMMON_CAT), --14 -> 2
    SUMMON_CAT_TO_MANIFEST_IN = ZO_StateMachine_Edge:New(ZO_CROWN_CRATE_STATES.SUMMON_CAT, ZO_CROWN_CRATE_STATES.MANIFEST_IN), --2 -> 3
    MANIFEST_IN_TO_MANIFEST = ZO_StateMachine_Edge:New(ZO_CROWN_CRATE_STATES.MANIFEST_IN, ZO_CROWN_CRATE_STATES.MANIFEST), --3 -> 4
    MANIFEST_TO_MANIFEST_OUT = ZO_StateMachine_Edge:New(ZO_CROWN_CRATE_STATES.MANIFEST, ZO_CROWN_CRATE_STATES.MANIFEST_OUT), --4 -> 5
    MANIFEST_OUT_TO_MANIFEST_IN = ZO_StateMachine_Edge:New(ZO_CROWN_CRATE_STATES.MANIFEST_OUT, ZO_CROWN_CRATE_STATES.MANIFEST_IN), --5 -> 3
    MANIFEST_OUT_TO_CAT_PRIMARY_DEAL = ZO_StateMachine_Edge:New(ZO_CROWN_CRATE_STATES.MANIFEST_OUT, ZO_CROWN_CRATE_STATES.CAT_PRIMARY_DEAL), --5 -> 6
    CAT_PRIMARY_DEAL_TO_UI_PRIMARY_DEAL = ZO_StateMachine_Edge:New(ZO_CROWN_CRATE_STATES.CAT_PRIMARY_DEAL, ZO_CROWN_CRATE_STATES.UI_PRIMARY_DEAL), --6 -> 7
    UI_PRIMARY_DEAL_TO_ACTIVE_HAND_MANIPULATION = ZO_StateMachine_Edge:New(ZO_CROWN_CRATE_STATES.UI_PRIMARY_DEAL, ZO_CROWN_CRATE_STATES.ACTIVE_HAND_MANIPULATION), --7 -> 10
    UI_PRIMARY_DEAL_TO_CAT_BONUS_DEAL = ZO_StateMachine_Edge:New(ZO_CROWN_CRATE_STATES.UI_PRIMARY_DEAL, ZO_CROWN_CRATE_STATES.CAT_BONUS_DEAL), --7 -> 8
    CAT_BONUS_DEAL_TO_UI_BONUS_DEAL = ZO_StateMachine_Edge:New(ZO_CROWN_CRATE_STATES.CAT_BONUS_DEAL, ZO_CROWN_CRATE_STATES.UI_BONUS_DEAL), --8 -> 9
    UI_BONUS_DEAL_TO_ACTIVE_HAND_MANIPULATION = ZO_StateMachine_Edge:New(ZO_CROWN_CRATE_STATES.UI_BONUS_DEAL, ZO_CROWN_CRATE_STATES.ACTIVE_HAND_MANIPULATION), --9 -> 10
    ACTIVE_HAND_MANIPULATION_TO_ALL_REVEALED = ZO_StateMachine_Edge:New(ZO_CROWN_CRATE_STATES.ACTIVE_HAND_MANIPULATION, ZO_CROWN_CRATE_STATES.ALL_REVEALED), --10 -> 11
    ALL_REVEALED_TO_CARDS_OUT_BACK = ZO_StateMachine_Edge:New(ZO_CROWN_CRATE_STATES.ALL_REVEALED, ZO_CROWN_CRATE_STATES.CARDS_OUT_BACK), --11 -> 12 (Back to Manifest)
    ALL_REVEALED_TO_CARDS_OUT_NEXT = ZO_StateMachine_Edge:New(ZO_CROWN_CRATE_STATES.ALL_REVEALED, ZO_CROWN_CRATE_STATES.CARDS_OUT_NEXT), --11 -> 13 (Open next pack)
    CARDS_OUT_BACK_TO_MANIFEST_IN = ZO_StateMachine_Edge:New(ZO_CROWN_CRATE_STATES.CARDS_OUT_BACK, ZO_CROWN_CRATE_STATES.MANIFEST_IN), --12 -> 3
    CARDS_OUT_NEXT_TO_MANIFEST_IN = ZO_StateMachine_Edge:New(ZO_CROWN_CRATE_STATES.CARDS_OUT_NEXT, ZO_CROWN_CRATE_STATES.MANIFEST_IN), --13 -> 3
    CARDS_OUT_NEXT_TO_CAT_PRIMARY_DEAL = ZO_StateMachine_Edge:New(ZO_CROWN_CRATE_STATES.CARDS_OUT_NEXT, ZO_CROWN_CRATE_STATES.CAT_PRIMARY_DEAL), --13 -> 6
}

--Triggers--
do
    local ALL_REVEALED_TO_CARDS_OUT_NEXT_KEYBIND = 
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,
        keybind = "UI_SHORTCUT_PRIMARY",
        name = function()
            local currentCrateId = GetCurrentCrownCrateId()
            local currentCrateName = GetCrownCrateName(currentCrateId)
            local remainingCount = GetCrownCrateCount(currentCrateId)
            local remainingCountColor = remainingCount == 0 and ZO_ERROR_COLOR or ZO_SELECTED_TEXT
            remainingCount = remainingCountColor:Colorize(remainingCount)
            return zo_strformat(SI_CROWN_CRATE_OPEN_NEXT_KEYBIND, currentCrateName, remainingCount)
        end,
        callback = nil,
        enabled = function()
                        local currentCrateId = GetCurrentCrownCrateId()

                        if GetCrownCrateCount(currentCrateId) == 0 then
                            return false, GetString("SI_LOOTCRATEOPENRESPONSE", LOOT_CRATE_OPEN_RESPONSE_OUT_OF_LOOT_CRATE)
                        end
                        
                        local numSlotsForCrate = GetInventorySpaceRequiredToOpenCrownCrate(currentCrateId)
                        local freeSlots = GetNumBagFreeSlots(BAG_BACKPACK)
                        if freeSlots <  numSlotsForCrate then
                            return false, zo_strformat(GetString("SI_LOOTCRATEOPENRESPONSE", LOOT_CRATE_OPEN_RESPONSE_FAIL_NO_INVENTORY_SPACE), numSlotsForCrate - freeSlots)
                        end

                        return true
                  end
    }

    local function FilterOpenResponseSuccess(eventCode, crateId, response)
        return response == LOOT_CRATE_OPEN_RESPONSE_SUCCESS
    end

    local function FilterOpenResponseFailed(eventCode, crateId, response)
        return response ~= LOOT_CRATE_OPEN_RESPONSE_SUCCESS
    end

    local function CreateServerResponseAndAnimationMultiTrigger(animationCompleteTriggerCommand, serverResponseFilterCallback, animationEventCountCallback)
        local animationTrigger = ZO_StateMachine_TriggerStateCallback:New(animationCompleteTriggerCommand)
        local serverResponseTrigger = ZO_StateMachine_TriggerEventManager:New(EVENT_CROWN_CRATE_OPEN_RESPONSE)

        serverResponseTrigger:SetFilterCallback(serverResponseFilterCallback)
        if animationEventCountCallback then
            animationTrigger:SetEventCount(animationEventCountCallback)
        end

        return ZO_StateMachine_MultiTrigger:New(animationTrigger, serverResponseTrigger)
    end

    local function ManifestOutEventCountCallback()
        local packsOnPage = CROWN_CRATES_PACK_CHOOSING:GetNumPacksToDisplayOnPage(CROWN_CRATES_PACK_CHOOSING:GetCurrentPage())
        -- If there are no packs, expect the manifest to tell us it's done immediately
        return packsOnPage > 0 and packsOnPage or 1
    end

    ZO_CROWN_CRATE_TRIGGERS =
    {
        START_TO_FRAMING_PLAYER = ZO_StateMachine_TriggerStateCallback:New(ZO_CROWN_CRATE_TRIGGER_COMMANDS.SCENE_SHOWN), --1 -> 14
        FRAMING_PLAYER_TO_SUMMON_CAT = ZO_StateMachine_TriggerEventManager:New(EVENT_GAME_CAMERA_CHARACTER_FRAMING_STARTED), --14 -> 2
        SUMMON_CAT_TO_MANIFEST_IN = ZO_StateMachine_TriggerAnimNote:New(ZO_CROWN_CRATE_TRIGGER_COMMANDS.CAT_SUMMON_COMPLETE), --2 -> 3
        MANIFEST_IN_TO_MANIFEST = ZO_StateMachine_TriggerStateCallback:New(ZO_CROWN_CRATE_TRIGGER_COMMANDS.MANIFEST_IN_COMPLETE), --3 -> 4
        MANIFEST_TO_MANIFEST_OUT = ZO_StateMachine_TriggerStateCallback:New(ZO_CROWN_CRATE_TRIGGER_COMMANDS.DEAL_REQUESTED), --4 -> 5
        MANIFEST_OUT_TO_MANIFEST_IN = CreateServerResponseAndAnimationMultiTrigger(ZO_CROWN_CRATE_TRIGGER_COMMANDS.MANIFEST_OUT_COMPLETE, FilterOpenResponseFailed, ManifestOutEventCountCallback), --5 -> 3
        MANIFEST_OUT_TO_CAT_PRIMARY_DEAL = CreateServerResponseAndAnimationMultiTrigger(ZO_CROWN_CRATE_TRIGGER_COMMANDS.MANIFEST_OUT_COMPLETE, FilterOpenResponseSuccess, ManifestOutEventCountCallback), --5 -> 6
        CAT_PRIMARY_DEAL_TO_UI_PRIMARY_DEAL = ZO_StateMachine_TriggerAnimNote:New(ZO_CROWN_CRATE_TRIGGER_COMMANDS.PRIMARY_DEAL_COMPLETE_CAT), --6 -> 7
        UI_PRIMARY_DEAL_TO_ACTIVE_HAND_MANIPULATION = ZO_StateMachine_TriggerStateCallback:New(ZO_CROWN_CRATE_TRIGGER_COMMANDS.PRIMARY_DEAL_COMPLETE), --7 -> 10
        UI_PRIMARY_DEAL_TO_CAT_BONUS_DEAL = ZO_StateMachine_TriggerStateCallback:New(ZO_CROWN_CRATE_TRIGGER_COMMANDS.PRIMARY_DEAL_COMPLETE), --7 -> 8
        CAT_BONUS_DEAL_TO_UI_BONUS_DEAL = ZO_StateMachine_TriggerAnimNote:New(ZO_CROWN_CRATE_TRIGGER_COMMANDS.BONUS_DEAL_COMPLETE_CAT), --8 -> 9
        UI_BONUS_DEAL_TO_ACTIVE_HAND_MANIPULATION = ZO_StateMachine_TriggerStateCallback:New(ZO_CROWN_CRATE_TRIGGER_COMMANDS.BONUS_DEAL_COMPLETE), --9 -> 10
        ACTIVE_HAND_MANIPULATION_TO_ALL_REVEALED = ZO_StateMachine_TriggerStateCallback:New(ZO_CROWN_CRATE_TRIGGER_COMMANDS.CARD_REVEALED), --10 -> 11
        ALL_REVEALED_TO_CARDS_OUT_BACK = ZO_StateMachine_TriggerStateCallback:New(ZO_CROWN_CRATE_TRIGGER_COMMANDS.BACK_TO_MANIFEST), --11 -> 12
        ALL_REVEALED_TO_CARDS_OUT_NEXT = ZO_StateMachine_TriggerKeybind:New(ALL_REVEALED_TO_CARDS_OUT_NEXT_KEYBIND), --11 -> 13
        CARDS_OUT_BACK_TO_MANIFEST_IN = ZO_StateMachine_TriggerStateCallback:New(ZO_CROWN_CRATE_TRIGGER_COMMANDS.CARD_OUT_COMPLETE), --12 -> 3
        CARDS_OUT_NEXT_TO_MANIFEST_IN = CreateServerResponseAndAnimationMultiTrigger(ZO_CROWN_CRATE_TRIGGER_COMMANDS.CARD_OUT_COMPLETE, FilterOpenResponseFailed, GetNumCurrentCrownCrateTotalRewards), --13 -> 3
        CARDS_OUT_NEXT_TO_CAT_PRIMARY_DEAL = CreateServerResponseAndAnimationMultiTrigger(ZO_CROWN_CRATE_TRIGGER_COMMANDS.CARD_OUT_COMPLETE, FilterOpenResponseSuccess, GetNumCurrentCrownCrateTotalRewards), --13 -> 6
    }
end

--Add triggers to edges--
ZO_CROWN_CRATE_EDGES.START_TO_FRAMING_PLAYER:AddTrigger(ZO_CROWN_CRATE_TRIGGERS.START_TO_FRAMING_PLAYER)
ZO_CROWN_CRATE_EDGES.FRAMING_PLAYER_TO_SUMMON_CAT:AddTrigger(ZO_CROWN_CRATE_TRIGGERS.FRAMING_PLAYER_TO_SUMMON_CAT)
ZO_CROWN_CRATE_EDGES.SUMMON_CAT_TO_MANIFEST_IN:AddTrigger(ZO_CROWN_CRATE_TRIGGERS.SUMMON_CAT_TO_MANIFEST_IN)
ZO_CROWN_CRATE_EDGES.MANIFEST_IN_TO_MANIFEST:AddTrigger(ZO_CROWN_CRATE_TRIGGERS.MANIFEST_IN_TO_MANIFEST)
ZO_CROWN_CRATE_EDGES.MANIFEST_TO_MANIFEST_OUT:AddTrigger(ZO_CROWN_CRATE_TRIGGERS.MANIFEST_TO_MANIFEST_OUT)
ZO_CROWN_CRATE_EDGES.MANIFEST_OUT_TO_MANIFEST_IN:AddTrigger(ZO_CROWN_CRATE_TRIGGERS.MANIFEST_OUT_TO_MANIFEST_IN)
ZO_CROWN_CRATE_EDGES.MANIFEST_OUT_TO_CAT_PRIMARY_DEAL:AddTrigger(ZO_CROWN_CRATE_TRIGGERS.MANIFEST_OUT_TO_CAT_PRIMARY_DEAL)
ZO_CROWN_CRATE_EDGES.CAT_PRIMARY_DEAL_TO_UI_PRIMARY_DEAL:AddTrigger(ZO_CROWN_CRATE_TRIGGERS.CAT_PRIMARY_DEAL_TO_UI_PRIMARY_DEAL)
ZO_CROWN_CRATE_EDGES.UI_PRIMARY_DEAL_TO_ACTIVE_HAND_MANIPULATION:AddTrigger(ZO_CROWN_CRATE_TRIGGERS.UI_PRIMARY_DEAL_TO_ACTIVE_HAND_MANIPULATION)
ZO_CROWN_CRATE_EDGES.UI_PRIMARY_DEAL_TO_CAT_BONUS_DEAL:AddTrigger(ZO_CROWN_CRATE_TRIGGERS.UI_PRIMARY_DEAL_TO_CAT_BONUS_DEAL)
ZO_CROWN_CRATE_EDGES.CAT_BONUS_DEAL_TO_UI_BONUS_DEAL:AddTrigger(ZO_CROWN_CRATE_TRIGGERS.CAT_BONUS_DEAL_TO_UI_BONUS_DEAL)
ZO_CROWN_CRATE_EDGES.UI_BONUS_DEAL_TO_ACTIVE_HAND_MANIPULATION:AddTrigger(ZO_CROWN_CRATE_TRIGGERS.UI_BONUS_DEAL_TO_ACTIVE_HAND_MANIPULATION)
ZO_CROWN_CRATE_EDGES.ACTIVE_HAND_MANIPULATION_TO_ALL_REVEALED:AddTrigger(ZO_CROWN_CRATE_TRIGGERS.ACTIVE_HAND_MANIPULATION_TO_ALL_REVEALED)
ZO_CROWN_CRATE_EDGES.ALL_REVEALED_TO_CARDS_OUT_BACK:AddTrigger(ZO_CROWN_CRATE_TRIGGERS.ALL_REVEALED_TO_CARDS_OUT_BACK)
ZO_CROWN_CRATE_EDGES.ALL_REVEALED_TO_CARDS_OUT_NEXT:AddTrigger(ZO_CROWN_CRATE_TRIGGERS.ALL_REVEALED_TO_CARDS_OUT_NEXT)
ZO_CROWN_CRATE_EDGES.CARDS_OUT_BACK_TO_MANIFEST_IN:AddTrigger(ZO_CROWN_CRATE_TRIGGERS.CARDS_OUT_BACK_TO_MANIFEST_IN)
ZO_CROWN_CRATE_EDGES.CARDS_OUT_NEXT_TO_MANIFEST_IN:AddTrigger(ZO_CROWN_CRATE_TRIGGERS.CARDS_OUT_NEXT_TO_MANIFEST_IN)
ZO_CROWN_CRATE_EDGES.CARDS_OUT_NEXT_TO_CAT_PRIMARY_DEAL:AddTrigger(ZO_CROWN_CRATE_TRIGGERS.CARDS_OUT_NEXT_TO_CAT_PRIMARY_DEAL)

--Add Conditionals--
ZO_CROWN_CRATE_EDGES.UI_PRIMARY_DEAL_TO_ACTIVE_HAND_MANIPULATION:SetConditional(function() return GetNumCurrentCrownCrateBonusRewards() == 0 end)
ZO_CROWN_CRATE_EDGES.UI_PRIMARY_DEAL_TO_CAT_BONUS_DEAL:SetConditional(function() return GetNumCurrentCrownCrateBonusRewards() > 0 end)

ZO_CROWN_CRATE_TRIGGERS.UI_PRIMARY_DEAL_TO_ACTIVE_HAND_MANIPULATION:SetEventCount(GetNumCurrentCrownCratePrimaryRewards)
ZO_CROWN_CRATE_TRIGGERS.UI_PRIMARY_DEAL_TO_CAT_BONUS_DEAL:SetEventCount(GetNumCurrentCrownCratePrimaryRewards)
ZO_CROWN_CRATE_TRIGGERS.UI_BONUS_DEAL_TO_ACTIVE_HAND_MANIPULATION:SetEventCount(GetNumCurrentCrownCrateBonusRewards)
ZO_CROWN_CRATE_TRIGGERS.ACTIVE_HAND_MANIPULATION_TO_ALL_REVEALED:SetEventCount(GetNumCurrentCrownCrateTotalRewards)

do
    local function ManifestInEventCountCallback()
        -- This essentially returns how many packs we expect to be on the first page.
        -- Since the manifest possibly hasn't actually begun loading yet at this point, we can't be sure it has page data, so determine it by hand
        local numOwnedCrateTypes = GetNumOwnedCrownCrateTypes()
        if numOwnedCrateTypes == 0 then
            -- If there are no packs, expect the manifest to tell us it's done immediately
            return 1
        elseif numOwnedCrateTypes > ZO_CROWN_CRATES_PACK_CHOOSING_PACKS_PER_PAGE then
            return ZO_CROWN_CRATES_PACK_CHOOSING_PACKS_PER_PAGE
        else
            return numOwnedCrateTypes
        end
    end

    ZO_CROWN_CRATE_TRIGGERS.MANIFEST_IN_TO_MANIFEST:SetEventCount(ManifestInEventCountCallback)
end

--Register actions on states--
ZO_CROWN_CRATE_STATES.START:RegisterCallback("OnActivated", function()
                                                                SetCrownCrateNPCVisible(false)
                                                                CROWN_CRATES_PACK_CHOOSING:ResetPacks()
                                                                CROWN_CRATES_PACK_OPENING:ResetCards()
                                                                SetFullscreenEffect(FULLSCREEN_EFFECT_NONE)
                                                            end)
ZO_CROWN_CRATE_STATES.SUMMON_CAT:RegisterCallback("OnActivated", function()
                                                                    SetCrownCrateNPCVisible(true)
                                                                end)
ZO_CROWN_CRATE_STATES.SUMMON_CAT:RegisterCallback("OnDeactivated", function()
                                                                    TriggerCrownCrateNPCAnimation(CROWN_CRATE_NPC_ANIMATION_TYPE_GREET_PLAYER)
                                                                end)
ZO_CROWN_CRATE_STATES.MANIFEST_IN:RegisterCallback("OnActivated", function()
                                                                    CROWN_CRATES:LockLocalSpaceToCurrentCamera()
                                                                    CROWN_CRATES_PACK_CHOOSING:Show()
                                                                    SetFullscreenEffect(FULLSCREEN_EFFECT_CHARACTER_FRAMING_BLUR, 2, 0)
                                                                    PlaySound(SOUNDS.CROWN_CRATES_MANIFEST_IN)
                                                                    --NPC passively reacts to your current supply of crates
                                                                    local numOwnedCrateTypes = GetNumOwnedCrownCrateTypes()
                                                                    if numOwnedCrateTypes == 0 then
                                                                        TriggerCrownCrateNPCAnimation(CROWN_CRATE_NPC_ANIMATION_TYPE_MANIFEST_ENTER_NO_CRATES)
                                                                    elseif numOwnedCrateTypes == 1 then
                                                                        TriggerCrownCrateNPCAnimation(CROWN_CRATE_NPC_ANIMATION_TYPE_MANIFEST_ENTER_ONE_CRATES)
                                                                    else
                                                                        TriggerCrownCrateNPCAnimation(CROWN_CRATE_NPC_ANIMATION_TYPE_MANIFEST_ENTER_MULTI_CRATES)
                                                                    end
                                                                end)
ZO_CROWN_CRATE_STATES.MANIFEST:RegisterCallback("OnActivated", function()
                                                                    CROWN_CRATES_PACK_CHOOSING:AddManifestKeybinds()
                                                                    CROWN_CRATES_PACK_CHOOSING:RefreshSelectedPack()
                                                                end)
ZO_CROWN_CRATE_STATES.MANIFEST:RegisterCallback("OnDeactivated", function()
                                                                    CROWN_CRATES_PACK_CHOOSING:RemoveManifestKeybinds()
                                                                end)
ZO_CROWN_CRATE_STATES.MANIFEST_OUT:RegisterCallback("OnActivated", function() 
                                                                        CROWN_CRATES_PACK_CHOOSING:AnimateChoice()
                                                                        PlaySound(SOUNDS.CROWN_CRATES_MANIFEST_OUT)
                                                                    end)
ZO_CROWN_CRATE_STATES.MANIFEST_OUT:RegisterCallback("OnDeactivated", function()
                                                                        CROWN_CRATES_PACK_CHOOSING:ResetPacks()
                                                                        SetFullscreenEffect(FULLSCREEN_EFFECT_NONE)
                                                                    end)
ZO_CROWN_CRATE_STATES.CAT_PRIMARY_DEAL:RegisterCallback("OnActivated", function()
                                                                            CROWN_CRATES_PACK_OPENING:ResetCards()
                                                                            -- We fire a flourish followed by the shuffle/deal.  Data controls what flourish fires, if any, then the deal will queue behind it
                                                                            -- The deal is what we really watch to move forward
                                                                            TriggerCrownCrateNPCAnimation(CROWN_CRATE_NPC_ANIMATION_TYPE_FLOURISH)
                                                                            TriggerCrownCrateNPCAnimation(CROWN_CRATE_NPC_ANIMATION_TYPE_DEAL_PRIMARY_CARDS)
                                                                       end)
ZO_CROWN_CRATE_STATES.UI_PRIMARY_DEAL:RegisterCallback("OnActivated", function()
                                                                            local success, worldX, worldY, worldZ = GetCrownCrateNPCBoneWorldPosition(GetCrownCrateNPCCardThrowingBoneName())
                                                                            if success then
                                                                                local localX, localY, localZ = CROWN_CRATES:GetCameraLocalPositionFromWorldPosition(worldX, worldY, worldZ)
                                                                                CROWN_CRATES_PACK_OPENING:StartPrimaryDealAnimation(localX, localY, localZ)
                                                                            end
                                                                            PlaySound(SOUNDS.CROWN_CRATES_DEAL_PRIMARY)
                                                                      end)
ZO_CROWN_CRATE_STATES.UI_PRIMARY_DEAL:RegisterCallback("OnDeactivated", function()
                                                                            TriggerCrownCrateNPCAnimation(CROWN_CRATE_NPC_ANIMATION_TYPE_PRIMARY_CARDS_DEALT)
                                                                      end)
                                                                      
ZO_CROWN_CRATE_STATES.CAT_BONUS_DEAL:RegisterCallback("OnActivated", function()
                                                                        TriggerCrownCrateNPCAnimation(CROWN_CRATE_NPC_ANIMATION_TYPE_DEAL_BONUS_CARDS)
                                                                     end)
ZO_CROWN_CRATE_STATES.UI_BONUS_DEAL:RegisterCallback("OnActivated", function()
                                                                        local success, worldX, worldY, worldZ = GetCrownCrateNPCBoneWorldPosition(GetCrownCrateNPCCardThrowingBoneName())
                                                                        if success then
                                                                            local localX, localY, localZ = CROWN_CRATES:GetCameraLocalPositionFromWorldPosition(worldX, worldY, worldZ)
                                                                            CROWN_CRATES_PACK_OPENING:StartBonusDealAnimation(localX, localY, localZ)
                                                                        end
                                                                        PlaySound(SOUNDS.CROWN_CRATES_DEAL_BONUS)
                                                                    end)

ZO_CROWN_CRATE_STATES.ACTIVE_HAND_MANIPULATION:RegisterCallback("OnActivated", function()
    CROWN_CRATES_PACK_OPENING:AddHandManipulationKeybinds()
    CROWN_CRATES_PACK_OPENING:RefreshSelectedCard()
end)
ZO_CROWN_CRATE_STATES.ACTIVE_HAND_MANIPULATION:RegisterCallback("OnDeactivated", function()
    CROWN_CRATES_PACK_OPENING:RemoveHandManipulationKeybinds()
end)

ZO_CROWN_CRATE_STATES.ALL_REVEALED:RegisterCallback("OnActivated", function()
    CROWN_CRATES_PACK_OPENING:AddAllRevealedKeybinds()
    --NPC passively reacts to you being done, depending on your current supply of crates
    if GetNumOwnedCrownCrateTypes() == 0 then
        TriggerCrownCrateNPCAnimation(CROWN_CRATE_NPC_ANIMATION_TYPE_ALL_CARDS_REVEALED_NO_CRATES)
    else
        TriggerCrownCrateNPCAnimation(CROWN_CRATE_NPC_ANIMATION_TYPE_ALL_CARDS_REVEALED_HAS_CRATES)
    end
end)
ZO_CROWN_CRATE_STATES.ALL_REVEALED:RegisterCallback("OnDeactivated", function()
    CROWN_CRATES_PACK_OPENING:RemoveAllRevealedKeybinds()
end)
ZO_CROWN_CRATE_STATES.CARDS_OUT_BACK:RegisterCallback("OnActivated", function()
    CROWN_CRATES_PACK_OPENING:StartLeaveAnimation()
    TriggerCrownCrateNPCAnimation(CROWN_CRATE_NPC_ANIMATION_TYPE_SWIPE_CARDS_AWAY)
end)
ZO_CROWN_CRATE_STATES.CARDS_OUT_NEXT:RegisterCallback("OnActivated", function()
    local currentCrownCrateId = GetCurrentCrownCrateId()
    SendCrownCrateOpenRequest(currentCrownCrateId)
    CROWN_CRATES_PACK_OPENING:StartLeaveAnimation() 
    TriggerCrownCrateNPCAnimation(CROWN_CRATE_NPC_ANIMATION_TYPE_SWIPE_CARDS_AWAY)
end)

function ZO_CrownCrateStateMachine_Reset()
    local currentState = ZO_CROWN_CRATE_STATE_MACHINE:GetCurrentState()
    if currentState and currentState ~= ZO_CROWN_CRATE_STATES.START then
        TriggerCrownCrateNPCAnimation(CROWN_CRATE_NPC_ANIMATION_TYPE_FAREWELL)
    end

    ZO_CROWN_CRATE_STATE_MACHINE:SetState(ZO_CROWN_CRATE_STATES.START)
end

do
    local DISABLED_BACK_STATES =
    {
        [ZO_CROWN_CRATE_STATES.MANIFEST_OUT] = true,
        [ZO_CROWN_CRATE_STATES.CAT_PRIMARY_DEAL] = true,
        [ZO_CROWN_CRATE_STATES.UI_PRIMARY_DEAL] = true,
        [ZO_CROWN_CRATE_STATES.CAT_BONUS_DEAL] = true,
        [ZO_CROWN_CRATE_STATES.UI_BONUS_DEAL] = true,
        [ZO_CROWN_CRATE_STATES.ACTIVE_HAND_MANIPULATION] = true,
    }

    function ZO_CrownCrateStateMachine_CanUseBackKeybind_Gamepad()
        local currentState = ZO_CROWN_CRATE_STATE_MACHINE:GetCurrentState()
        if  DISABLED_BACK_STATES[currentState] then
            return false
        else
            return true
        end
    end
end