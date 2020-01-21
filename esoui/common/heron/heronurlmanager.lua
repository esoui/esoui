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
        {
            text = SI_DIALOG_DISMISS,
        },
    },
}

ESO_Dialogs["HERON_PROMPT_USER_TO_SEND_EMAIL"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    canQueue = true,
    title =
    {
        text = SI_CONFIRM_SEND_EMAIL_TITLE,
    },
    mainText =
    {
        text = SI_HERON_PROMPT_USER_TO_SEND_EMAIL_TEXT,
    },
    buttons =
    {
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
    local EMAIL_MATCH_PATTERN = "^mailto:(.+)"
    local emailAddress = zo_strmatch(urlString, EMAIL_MATCH_PATTERN)
    if emailAddress then
        ZO_Dialogs_ShowPlatformDialog("HERON_PROMPT_USER_TO_SEND_EMAIL", nil, { mainTextParams = { emailAddress } })
    else
        ZO_Dialogs_ShowPlatformDialog("HERON_PROMPT_USER_TO_VISIT_URL", nil, { mainTextParams = { urlString } })
    end
end

HERON_URL_MANAGER = ZO_HeronURLManager:New()
