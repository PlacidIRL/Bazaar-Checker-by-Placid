local BazaarChecker = BazaarChecker

local ROW_HEIGHT = 36
local HEADER_HEIGHT = 30
local rows = {}

local alertFrame = CreateFrame("Frame", "BazaarCheckerAlertFrame", UIParent)
alertFrame:SetSize(340, HEADER_HEIGHT + ROW_HEIGHT + 14)
alertFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
alertFrame:SetFrameStrata("HIGH")
alertFrame:SetMovable(true)
alertFrame:EnableMouse(true)
alertFrame:RegisterForDrag("LeftButton")
alertFrame:SetScript("OnDragStart", alertFrame.StartMoving)
alertFrame:SetScript("OnDragStop", alertFrame.StopMovingOrSizing)
BazaarChecker:ApplyFlatSkin(alertFrame)
alertFrame:Hide()

local title = alertFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
title:SetPoint("TOP", alertFrame, "TOP", 0, -8)
title:SetText("|cff4b0082Bazaar Checker|r - wishlist item found!")

local closeBtn = CreateFrame("Button", nil, alertFrame, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", alertFrame, "TOPRIGHT", -2, -2)
closeBtn:SetScript("OnClick", function() alertFrame:Hide() end)

local function GetAlertRow(i)
    local row = rows[i]
    if row then return row end

    row = CreateFrame("Frame", nil, alertFrame)
    row:SetHeight(ROW_HEIGHT)
    row:SetPoint("TOPLEFT", alertFrame, "TOPLEFT", 12, -(HEADER_HEIGHT + (i - 1) * ROW_HEIGHT))
    row:SetPoint("RIGHT", alertFrame, "RIGHT", -12, 0)

    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(28, 28)
    row.icon:SetPoint("LEFT", row, "LEFT", 0, 0)

    row.iconBtn = CreateFrame("Button", nil, row)
    row.iconBtn:SetAllPoints(row.icon)
    row.iconBtn:SetScript("OnEnter", function(self)
        if not row.itemLink then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink(row.itemLink)
        GameTooltip:Show()
    end)
    row.iconBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.nameText:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 6, -1)
    row.nameText:SetPoint("RIGHT", row, "RIGHT", -66, 0)
    row.nameText:SetJustifyH("LEFT")

    -- A plain Button (unlike a plain Frame) reliably supports OnEnter/OnLeave/OnClick, so this
    -- covers hover-tooltip + click-to-link for the name text without relying on the
    -- OnHyperlink* script set, which isn't available on generic Frames on this client.
    row.nameBtn = CreateFrame("Button", nil, row)
    row.nameBtn:SetAllPoints(row.nameText)
    row.nameBtn:SetScript("OnEnter", function(self)
        if not row.itemLink then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink(row.itemLink)
        GameTooltip:Show()
    end)
    row.nameBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    row.nameBtn:SetScript("OnClick", function()
        if row.itemLink then SetItemRef(row.itemLink, row.itemLink, "LeftButton") end
    end)

    row.priceIcon = row:CreateTexture(nil, "ARTWORK")
    row.priceIcon:SetSize(14, 14)
    row.priceIcon:SetPoint("BOTTOMLEFT", row.icon, "BOTTOMRIGHT", 6, 1)

    row.priceText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.priceText:SetPoint("LEFT", row.priceIcon, "RIGHT", 4, 0)

    row.buyBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    row.buyBtn:SetSize(56, 20)
    row.buyBtn:SetText("Buy")
    row.buyBtn:SetPoint("RIGHT", row, "RIGHT", 0, -2)
    row.buyBtn:SetScript("OnClick", function()
        if row.itemID then BazaarChecker:BuyItem(row.itemID) end
    end)

    rows[i] = row
    return row
end

local function DoShowFoundItems(self, items)
    for i, item in ipairs(items) do
        local row = GetAlertRow(i)
        row.itemLink = item.link
        row.itemID = item.itemID

        row.icon:SetTexture(GetItemIcon(item.itemID) or "Interface\\Icons\\INV_Misc_QuestionMark")
        row.nameText:SetText(item.link)

        if item.tokenPrice then
            local _, _, _, _, _, _, _, _, _, tokenIcon = GetItemInfo(self.BAZAAR_TOKEN_ITEM_ID)
            row.priceIcon:SetTexture(tokenIcon or "Interface\\Icons\\INV_Misc_Coin_02")
            row.priceIcon:Show()
            row.priceText:SetText(item.tokenPrice .. " Bazaar Token" .. (item.tokenPrice ~= 1 and "s" or ""))
        elseif item.copperPrice and item.copperPrice > 0 then
            row.priceIcon:Hide()
            row.priceText:SetText(GetCoinTextureString(item.copperPrice))
        elseif item.page then
            -- The vendor's Bazaar Token price isn't reachable through any client API on this
            -- server, so point at the page instead - close enough to find it fast.
            row.priceIcon:Hide()
            row.priceText:SetText("Page " .. item.page)
        else
            row.priceIcon:Hide()
            row.priceText:SetText("")
        end

        row:Show()

        local priceMsg = item.tokenPrice and (item.tokenPrice .. " Bazaar Tokens")
            or item.page and ("page " .. item.page .. " of the vendor")
            or "sale"
        self:Print(item.link .. " is available for " .. priceMsg .. "!")
    end

    for i = #items + 1, #rows do
        rows[i]:Hide()
    end

    alertFrame:SetHeight(HEADER_HEIGHT + #items * ROW_HEIGHT + 14)
    alertFrame:Show()

    if self.db.settings.soundEnabled then
        PlaySoundFile("Sound\\Interface\\RaidWarning.wav", "Master")
    end
end

-- Wrapped in pcall so a crash while building the popup surfaces as a visible chat error
-- instead of silently swallowing the "item found" alert.
function BazaarChecker:ShowFoundItems(items)
    local ok, err = pcall(DoShowFoundItems, self, items)
    if not ok then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[Bazaar Checker]|r Alert popup error: " .. tostring(err))
    end
end

function BazaarChecker:HideAlertPopup()
    alertFrame:Hide()
end
