function ZO_ConfirmSendGift_Shared_ShouldRestartGiftFlow(giftResult)
    return giftResult == GIFT_ACTION_RESULT_CANNOT_GIFT_TO_PLAYER or giftResult == GIFT_ACTION_RESULT_RECIPIENT_NOT_FOUND
end
