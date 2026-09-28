--[[
    Legal docs providers abstract out the platform specific details of obtaining non-eula legal docs, they should implement:
    ShouldShowEULA() -> bool
    NextLegalDoc() -> LegalDocData or nil
    PreviousLegalDoc() -> LegalDocData or nil
    OnDocsFinished()
]]--


-- EULAs are loaded from disk, but other types of docs need to be asynchronously fetched from services. We only fetch the docs that have not yet been accepted.
ZO_RemoteLegalDocsProvider = ZO_InitializingObject:Subclass()

function ZO_RemoteLegalDocsProvider:Initialize()
    self.haveFetchedRemoteDocs = false
    self.nextLegalDocIndex = nil
    EVENT_MANAGER:RegisterForEvent("ZO_RemoteLegalDocsProvider", EVENT_FETCHED_LEGAL_DOCS, function()
        self.haveFetchedRemoteDocs = true
        self.nextLegalDocIndex = 1
        ZO_PregameStateManager_SetState("LegalAgreements")
    end)
end

function ZO_RemoteLegalDocsProvider:ShouldShowEULA()
    return ShouldShowEULA(EULA_TYPE_PREGAME_EULA)
end

do
    local DOC_TYPE_TO_EULA_TYPE =
    {
        ["terms_of_use"] = EULA_TYPE_TERMS_OF_SERVICE,
        ["privacy_policy"] = EULA_TYPE_PRIVACY_POLICY,
        ["code_of_conduct"] = EULA_TYPE_CODE_OF_CONDUCT,
    }

    function ZO_RemoteLegalDocsProvider:NextLegalDoc()
        if self:ShouldShowEULA() then
            local eulaText, agreeText, disagreeText = GetEULADetails(EULA_TYPE_PREGAME_EULA)
            return
            {
                name = GetString(SI_WINDOW_TITLE_EULA), 
                text = eulaText,
                eulaType = EULA_TYPE_PREGAME_EULA,
                positiveButtonPrompt = agreeText,
                negativeButtonPrompt = disagreeText,
                acceptFunction = function() AgreeToEULA() end,
            }
        elseif self.haveFetchedRemoteDocs and self.nextLegalDocIndex <= GetNumLegalDocs() then
            local i = self.nextLegalDocIndex
            self.nextLegalDocIndex = self.nextLegalDocIndex + 1
            local docType = GetLegalDocType(i)
            local eulaType = DOC_TYPE_TO_EULA_TYPE[docType]

            internalassert(eulaType ~= nil, string.format("Unhandled legal document type %s", docType))

            local positiveButtonText = GetString("SI_EULATYPE_POSITIVEBUTTONTEXT", eulaType)
            local negativeButtonText = GetString("SI_EULATYPE_NEGATIVEBUTTONTEXT", eulaType)

            if positiveButtonText == "" then
                positiveButtonText = GetString(SI_LEGAL_BUTTON_AGREE)
            end

            if negativeButtonText == "" then
                negativeButtonText = GetString(SI_LEGAL_BUTTON_DISAGREE)
            end

            return
            {
                name = GetLegalDocTitle(i),
                text = GetLegalDocContent(i),
                eulaType = eulaType,
                positiveButtonPrompt = positiveButtonText,
                negativeButtonPrompt = negativeButtonText,
                acceptFunction = function() end,
            }
        end
        return nil
    end
end

function ZO_RemoteLegalDocsProvider:PreviousLegalDoc()
    -- Set next legal doc to the doc before the current doc.
    -- current nextLegalDoc index is currentDocIndex + 1, so subtract 2 to counteract that
    if self.haveFetchedRemoteDocs and self.nextLegalDocIndex > 2 then
        self.nextLegalDocIndex = self.nextLegalDocIndex - 2
        return self:NextLegalDoc()
    end
    return nil
end

function ZO_RemoteLegalDocsProvider:OnDocsFinished()
    if not self.haveFetchedRemoteDocs then
        -- we need to attempt to log in, which will fail us if there are any remote docs we need to accept. To do this we'll just advance the state
        -- then we will fetch those docs and restart the flow
        if IsInGamepadPreferredMode() then
            ZO_PregameStateManager_AdvanceState()
        else
            LOGIN_KEYBOARD:DoLogin()
        end
    else
        if IsInGamepadPreferredMode() then
            -- We have already fetched the docs and accepted at this point, but remote legal docs require an extra confirmation step before we consider them to be accepted, then we'll advance
            ZO_Dialogs_ShowGamepadDialog("LEGAL_AGREEMENT_UPDATED_ACKNOWLEDGE_GAMEPAD")
        else
            ZO_Dialogs_ShowDialog("LEGAL_AGREEMENT_UPDATED_ACKNOWLEDGE_KEYBOARD")
        end
    end
end

REMOTE_LEGAL_DOCS_PROVIDER = ZO_RemoteLegalDocsProvider:New()