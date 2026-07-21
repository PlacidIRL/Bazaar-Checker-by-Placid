BazaarChecker = BazaarChecker or {}
local BazaarChecker = BazaarChecker

-- The currency item the Bazaar vendor prices its stock in.
BazaarChecker.BAZAAR_TOKEN_ITEM_ID = 975001

-- The vendor's name (Tiraxis, The Ethereal Bazaar). Used as a reliable fallback way to
-- recognize the vendor in case the extended-cost API doesn't detect Bazaar Token pricing.
BazaarChecker.VENDOR_NAME = "Tiraxis"

-- Shared dark purple accent, matches the "by Placid" branding used across the other addons.
BazaarChecker.ACCENT_COLOR = { 0.29, 0.0, 0.51 }
BazaarChecker.PREFIX_COLOR = "cff4b0082"

local DEFAULT_SETTINGS = {
    soundEnabled = true,
    alertSound = "RaidWarning",
    minimapAngle = 215,
    minimapHide = false,
}

function BazaarChecker:InitDB()
    BazaarCheckerDB = BazaarCheckerDB or {}
    BazaarCheckerDB.settings = BazaarCheckerDB.settings or {}

    for key, value in pairs(DEFAULT_SETTINGS) do
        if BazaarCheckerDB.settings[key] == nil then
            BazaarCheckerDB.settings[key] = value
        end
    end

    BazaarCheckerDB.wishlist = BazaarCheckerDB.wishlist or {}

    self.db = BazaarCheckerDB

    -- Pre-warm the client's item cache so the token's name/icon are ready before the first scan.
    GetItemInfo(self.BAZAAR_TOKEN_ITEM_ID)
end

function BazaarChecker:Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|" .. self.PREFIX_COLOR .. "[Bazaar Checker]|r " .. msg)
end

-- Shared flat panel skin (solid color + thin accent border) so every window reads as one UI.
function BazaarChecker:ApplyFlatSkin(frame)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    frame:SetBackdropColor(0.05, 0.05, 0.07, 0.95)
    local a = self.ACCENT_COLOR
    frame:SetBackdropBorderColor(a[1], a[2], a[3], 0.9)
end

function BazaarChecker:GetItemIDFromLink(link)
    if not link then return nil end
    local id = link:match("item:(%d+)")
    return id and tonumber(id) or nil
end

function BazaarChecker:OnLogin()
    if self.BuildMainFrame then self:BuildMainFrame() end
    if self.BuildOptionsPanel then self:BuildOptionsPanel() end
    if self.BuildMinimapButton then self:BuildMinimapButton() end
    if self.RefreshWishlistUI then self:RefreshWishlistUI() end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        BazaarChecker:InitDB()
        BazaarChecker:OnLogin()
    end
end)

--------------------------------------------------------------------------
-- Wishlist management
--------------------------------------------------------------------------

function BazaarChecker:AddToWishlist(itemID)
    itemID = tonumber(itemID)
    if not itemID then
        self:Print("Enter a valid item link or item ID.")
        return
    end

    if self.db.wishlist[itemID] then
        self:Print("That item is already on your wishlist.")
        return
    end

    local name, link, quality, _, _, _, _, _, _, icon = GetItemInfo(itemID)
    if not name then
        -- Not in the local item cache yet (e.g. a bare ID that's never been seen client-side).
        -- Queue it and retry for a few seconds while the server responds.
        self:QueuePendingAdd(itemID)
        return
    end

    self.db.wishlist[itemID] = { itemID = itemID, name = name, link = link, icon = icon }
    self:Print(link .. " added to your wishlist.")
    if self.RefreshWishlistUI then self:RefreshWishlistUI() end
end

function BazaarChecker:RemoveFromWishlist(itemID)
    local entry = self.db.wishlist[itemID]
    if not entry then return end

    self.db.wishlist[itemID] = nil
    self:Print((entry.link or entry.name or ("item " .. itemID)) .. " removed from your wishlist.")
    if self.RefreshWishlistUI then self:RefreshWishlistUI() end
end

-- Retry queue for items whose data isn't cached client-side on the first GetItemInfo() call.
local pending = {}
local pendingWatcher = CreateFrame("Frame")
local pendingAccum = 0
pendingWatcher:SetScript("OnUpdate", function(self, elapsed)
    if next(pending) == nil then return end
    pendingAccum = pendingAccum + elapsed
    if pendingAccum < 0.2 then return end
    pendingAccum = 0

    for itemID, tries in pairs(pending) do
        local name, link, quality, _, _, _, _, _, _, icon = GetItemInfo(itemID)
        if name then
            pending[itemID] = nil
            BazaarChecker.db.wishlist[itemID] = { itemID = itemID, name = name, link = link, icon = icon }
            BazaarChecker:Print(link .. " added to your wishlist.")
            if BazaarChecker.RefreshWishlistUI then BazaarChecker:RefreshWishlistUI() end
        else
            tries = tries + 1
            if tries >= 25 then -- ~5 seconds
                pending[itemID] = nil
                BazaarChecker:Print("Could not find item ID " .. itemID .. " - is it correct?")
            else
                pending[itemID] = tries
            end
        end
    end
end)

function BazaarChecker:QueuePendingAdd(itemID)
    pending[itemID] = 0
end

--------------------------------------------------------------------------
-- Slash commands
--------------------------------------------------------------------------

SLASH_BAZAARCHECKER1 = "/bazaar"
SLASH_BAZAARCHECKER2 = "/bzc"
SlashCmdList["BAZAARCHECKER"] = function(msg)
    msg = strtrim(msg or "")
    if msg == "rescan" then
        if BazaarChecker.ScanVendor then BazaarChecker:ScanVendor() end
        return
    end
    if msg ~= "" then
        local itemID = BazaarChecker:GetItemIDFromLink(msg) or tonumber(msg)
        if itemID then
            BazaarChecker:AddToWishlist(itemID)
            return
        end
    end
    if BazaarChecker.ToggleMainFrame then BazaarChecker:ToggleMainFrame() end
end
