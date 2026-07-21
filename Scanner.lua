local BazaarChecker = BazaarChecker

-- GetMerchantNumItems()/GetMerchantItemLink() cover every item the vendor sells, not just the
-- 10 currently visible in the UI - the "pages" are purely a display grouping, so a single pass
-- over the full index range scans all ~11 pages instantly with no need to click Next Page.

local scanFrame = CreateFrame("Frame")
scanFrame:RegisterEvent("MERCHANT_SHOW")
scanFrame:RegisterEvent("MERCHANT_CLOSED")
scanFrame:SetScript("OnEvent", function(self, event)
    if event == "MERCHANT_SHOW" then
        BazaarChecker:ScanVendor()
    elseif event == "MERCHANT_CLOSED" then
        if BazaarChecker.HideAlertPopup then BazaarChecker:HideAlertPopup() end
    end
end)

-- Returns the quantity of Bazaar Tokens required for a merchant slot, or nil if that slot
-- isn't priced in Bazaar Tokens (e.g. priced in gold, or in some other currency item).
function BazaarChecker:GetBazaarTokenCost(merchantIndex)
    if not GetMerchantItemCostInfo or not GetMerchantItemCostItem then return nil end

    local costCount = GetMerchantItemCostInfo(merchantIndex)
    if not costCount or costCount == 0 then return nil end

    for costIndex = 1, costCount do
        local texture, value, link = GetMerchantItemCostItem(merchantIndex, costIndex)
        if link then
            local costItemID = self:GetItemIDFromLink(link)
            if costItemID == self.BAZAAR_TOKEN_ITEM_ID then
                return value
            end
        end
    end

    return nil
end

local function DoScanVendor(self)
    local numItems = GetMerchantNumItems()
    if not numItems or numItems == 0 then return end

    local found = {}
    local isBazaarVendor = false

    -- Recognize the vendor by name first - this doesn't depend on the extended-cost API
    -- actually working, so it still functions even if that API turns out to behave
    -- differently than expected on this server.
    local npcName = UnitName("npc")
    if npcName and self.VENDOR_NAME and npcName:lower() == self.VENDOR_NAME:lower() then
        isBazaarVendor = true
    end

    for i = 1, numItems do
        local tokenPrice = self:GetBazaarTokenCost(i)
        if tokenPrice then isBazaarVendor = true end

        local itemLink = GetMerchantItemLink(i)
        if itemLink then
            local itemID = self:GetItemIDFromLink(itemLink)
            if itemID and self.db.wishlist[itemID] then
                local _, _, price, _, numAvailable = GetMerchantItemInfo(i)
                -- numAvailable is -1 for unlimited stock; 0 means sold out this rotation.
                if numAvailable == nil or numAvailable == -1 or numAvailable > 0 then
                    table.insert(found, {
                        itemID = itemID,
                        merchantIndex = i,
                        link = itemLink,
                        tokenPrice = tokenPrice,
                        copperPrice = price,
                        page = math.ceil(i / (MERCHANT_ITEMS_PER_PAGE or 10)),
                    })
                end
            end
        end
    end

    -- Only treat this as "the Bazaar" if its name matched or it sells something for Bazaar
    -- Tokens - this keeps ordinary vendors from silently being scanned and spamming a
    -- "not found" message, while still working if either signal alone succeeds.
    if not isBazaarVendor then return end

    if #found > 0 then
        if self.ShowFoundItems then self:ShowFoundItems(found) end
    else
        self:Print("None of your wishlisted items are available here right now.")
    end
end

-- Wrapped in pcall so a crash mid-scan surfaces as a visible chat error instead of silently
-- doing nothing the moment you open the vendor.
function BazaarChecker:ScanVendor()
    local ok, err = pcall(DoScanVendor, self)
    if not ok then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[Bazaar Checker]|r Scan error: " .. tostring(err))
    end
end

-- Re-resolves the item's current merchant slot at click time rather than trusting a slot
-- captured during the scan, since buying other items can shift stock indices.
function BazaarChecker:BuyItem(itemID)
    if not MerchantFrame or not MerchantFrame:IsShown() then
        self:Print("Open the vendor window to buy this item.")
        return
    end

    local numItems = GetMerchantNumItems()
    for i = 1, (numItems or 0) do
        local link = GetMerchantItemLink(i)
        if link and self:GetItemIDFromLink(link) == itemID then
            BuyMerchantItem(i, 1)
            return
        end
    end

    self:Print("That item is no longer available.")
end
