local BazaarChecker = BazaarChecker

-- Shared wishlist row-list + add-box builder, used by both the standalone popup window
-- (MainFrame.lua) and the embedded Interface Options panel (OptionsPanel.lua) so there's a
-- single place that renders the wishlist and a single place that can break.

local ROW_HEIGHT = 20
local views = {}
local editBoxes = {}

-- Lets shift-clicking an item link insert into whichever of our custom edit boxes currently
-- has focus, the same way it would insert into the normal chat edit box.
local orig_ChatEdit_InsertLink = ChatEdit_InsertLink
ChatEdit_InsertLink = function(text)
    for _, box in ipairs(editBoxes) do
        if box:IsVisible() and box:HasFocus() then
            box:Insert(text)
            return true
        end
    end
    return orig_ChatEdit_InsertLink(text)
end

local function CreateRow(scrollChild, index)
    local row = CreateFrame("Frame", nil, scrollChild)
    row:SetHeight(ROW_HEIGHT)
    row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -(index - 1) * ROW_HEIGHT)
    row:SetPoint("RIGHT", scrollChild, "RIGHT", 0, 0)
    row.stripe = row:CreateTexture(nil, "BACKGROUND")
    row.stripe:SetAllPoints()
    row.stripe:SetTexture("Interface\\Buttons\\WHITE8x8")
    row.stripe:SetVertexColor(1, 1, 1, 0)

    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(16, 16)
    row.icon:SetPoint("LEFT", row, "LEFT", 2, 0)

    row.iconBtn = CreateFrame("Button", nil, row)
    row.iconBtn:SetAllPoints(row.icon)
    row.iconBtn:SetScript("OnEnter", function(self)
        if not row.itemLink then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink(row.itemLink)
        GameTooltip:Show()
    end)
    row.iconBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.text:SetPoint("LEFT", row.icon, "RIGHT", 4, 0)
    row.text:SetPoint("RIGHT", row, "RIGHT", -20, 0)
    row.text:SetJustifyH("LEFT")

    -- A plain Button (unlike a plain Frame) reliably supports OnEnter/OnLeave/OnClick, so this
    -- covers hover-tooltip + click-to-link for the name text without relying on the
    -- OnHyperlink* script set, which isn't available on generic Frames on this client.
    row.textBtn = CreateFrame("Button", nil, row)
    row.textBtn:SetAllPoints(row.text)
    row.textBtn:SetScript("OnEnter", function(self)
        if not row.itemLink then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink(row.itemLink)
        GameTooltip:Show()
    end)
    row.textBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    row.textBtn:SetScript("OnClick", function()
        if row.itemLink then SetItemRef(row.itemLink, row.itemLink, "LeftButton") end
    end)

    row.removeBtn = CreateFrame("Button", nil, row)
    row.removeBtn:SetSize(14, 14)
    row.removeBtn:SetPoint("RIGHT", row, "RIGHT", -2, 0)
    row.removeBtn.tex = row.removeBtn:CreateTexture(nil, "ARTWORK")
    row.removeBtn.tex:SetAllPoints()
    row.removeBtn.tex:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
    row.removeBtn:SetScript("OnClick", function()
        if row.itemID then BazaarChecker:RemoveFromWishlist(row.itemID) end
    end)
    row.removeBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("Remove from wishlist")
        GameTooltip:Show()
    end)
    row.removeBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    return row
end

local function GetRow(view, i)
    local row = view.rows[i]
    if row then return row end
    row = CreateRow(view.scrollChild, i)
    view.rows[i] = row
    return row
end

local function DoRefresh(self)
    local sorted = {}
    for _, entry in pairs(self.db.wishlist) do
        table.insert(sorted, entry)
    end
    table.sort(sorted, function(a, b) return (a.name or "") < (b.name or "") end)

    for _, view in ipairs(views) do
        for i, entry in ipairs(sorted) do
            local row = GetRow(view, i)
            row.text:SetText(entry.link or entry.name or ("Item " .. entry.itemID))
            row.icon:SetTexture(entry.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
            row.itemID = entry.itemID
            row.itemLink = entry.link
            row.stripe:SetVertexColor(1, 1, 1, (i % 2 == 0) and 0.04 or 0)
            row:Show()
        end

        for i = #sorted + 1, #view.rows do
            view.rows[i]:Hide()
        end

        view.scrollChild:SetHeight(math.max(1, #sorted * ROW_HEIGHT))

        if view.emptyLabel then
            if #sorted == 0 then view.emptyLabel:Show() else view.emptyLabel:Hide() end
        end
        if view.countLabel then
            view.countLabel:SetText(#sorted .. " item" .. (#sorted ~= 1 and "s" or "") .. " on your wishlist")
        end
    end
end

-- Wrapped in pcall so a crash part-way through (e.g. one bad entry) surfaces as a visible chat
-- error instead of silently leaving every view stuck showing stale/zero data.
function BazaarChecker:RefreshWishlistUI()
    local ok, err = pcall(DoRefresh, self)
    if not ok then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[Bazaar Checker]|r UI refresh error: " .. tostring(err))
    end
end

function BazaarChecker:HandleAddInput(text)
    text = strtrim(text or "")
    if text == "" then return end

    local itemID = self:GetItemIDFromLink(text) or tonumber(text)
    if not itemID then
        self:Print("Enter a valid item link or item ID.")
        return
    end
    self:AddToWishlist(itemID)
end

-- Builds the add box + scrollable wishlist row list inside `parent`, anchored `topOffset` pixels
-- below its top edge, and registers it as a "view" so RefreshWishlistUI keeps it in sync.
function BazaarChecker:BuildWishlistContent(parent, topOffset)
    local editBox = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    editBox:SetSize(148, 20)
    editBox:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, -topOffset)
    editBox:SetAutoFocus(false)
    -- Guarded: not every client build exposes this EditBox method, and a missing method here
    -- would otherwise abort this whole function partway through.
    if editBox.SetHyperlinksEnabled then
        editBox:SetHyperlinksEnabled(true)
    end
    editBox:SetScript("OnEnterPressed", function(self)
        BazaarChecker:HandleAddInput(self:GetText())
        self:SetText("")
        self:ClearFocus()
    end)
    editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    table.insert(editBoxes, editBox)

    local addBtn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    addBtn:SetSize(50, 20)
    addBtn:SetText("Add")
    addBtn:SetPoint("LEFT", editBox, "RIGHT", 10, 0)
    addBtn:SetScript("OnClick", function()
        BazaarChecker:HandleAddInput(editBox:GetText())
        editBox:SetText("")
        editBox:ClearFocus()
    end)

    local hint = parent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", editBox, "BOTTOMLEFT", 2, -4)
    hint:SetText("Shift-click an item or type its ID")

    local scrollFrame = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -(topOffset + 38))
    scrollFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -28, 16)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(1, 1)
    scrollFrame:SetScrollChild(scrollChild)

    local function SyncWidth()
        scrollChild:SetWidth(math.max(1, scrollFrame:GetWidth()))
    end
    parent:SetScript("OnSizeChanged", SyncWidth)
    SyncWidth()

    local emptyLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    emptyLabel:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 2, -4)
    emptyLabel:SetPoint("RIGHT", scrollFrame, "RIGHT", -2, 0)
    emptyLabel:SetText("No items on your wishlist yet.\nShift-click an item link above,\nor type its item ID, then Add.")
    emptyLabel:SetJustifyH("LEFT")

    local countLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    countLabel:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 10, 4)

    table.insert(views, { rows = {}, scrollChild = scrollChild, emptyLabel = emptyLabel, countLabel = countLabel })
end
