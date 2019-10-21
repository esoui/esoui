ESO_Dialogs["HERON_PROMPT_USER_TO_VISIT_URL"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    canQueue = true,
    title =
    {
        text = SI_CONFIRM_OPEN_URL_TITLE,
    },
    mainText =
    {
        text = SI_HERON_PROMPT_USER_TO_VISIT_URL_TEXT,
    },
    buttons =
    {
        [1] =
        {
            text = SI_DIALOG_DISMISS,
        },
    },
}

ZO_HeronURLManager = ZO_Object:Subclass()

function ZO_HeronURLManager:New(...)
    local object = ZO_Object.New(self)
    object:Initialize()
    return object
end

function ZO_HeronURLManager:Initialize()
    local function OnHeronURLRequested(_, urlString)
        self:VisitHeronURL(urlString)
    end
    EVENT_MANAGER:RegisterForEvent("ZO_HeronURLManager", EVENT_HERON_URL_REQUESTED, OnHeronURLRequested)
end

function ZO_HeronURLManager:VisitHeronURL(urlString)
    ZO_Dialogs_ShowPlatformDialog("HERON_PROMPT_USER_TO_VISIT_URL", nil, { mainTextParams = { urlString } })
end

HERON_URL_MANAGER = ZO_HeronURLManager:New()
