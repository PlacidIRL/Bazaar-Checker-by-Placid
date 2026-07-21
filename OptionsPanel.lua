local BazaarChecker = BazaarChecker

-- Registers a panel under Esc -> Interface -> AddOns, so the wishlist can be managed there
-- instead of (or in addition to) the standalone popup window and its slash command.
function BazaarChecker:BuildOptionsPanel()
    if self.optionsPanel then return end
    if not InterfaceOptions_AddCategory then return end -- defensive: skip if unavailable rather than error

    local panel = CreateFrame("Frame", "BazaarCheckerOptionsPanel", UIParent)
    panel.name = "Bazaar Checker |cff4b0082by Placid|r"
    panel:Hide()

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -16)
    title:SetText("Bazaar Checker |cff4b0082by Placid|r")

    local subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    subtitle:SetPoint("RIGHT", panel, "RIGHT", -16, 0)
    subtitle:SetJustifyH("LEFT")
    subtitle:SetText("Wishlisted items are checked against the Bazaar vendor's stock every time you open it.")

    self:BuildWishlistContent(panel, 68)

    InterfaceOptions_AddCategory(panel)
    self.optionsPanel = panel
end
