local BazaarChecker = BazaarChecker

function BazaarChecker:BuildMainFrame()
    if self.mainFrame then return end

    local mainFrame = CreateFrame("Frame", "BazaarCheckerMainFrame", UIParent)
    mainFrame:SetSize(260, 340)
    mainFrame:SetPoint("CENTER", UIParent, "CENTER", 300, 0)
    mainFrame:SetFrameStrata("MEDIUM")
    mainFrame:SetMovable(true)
    mainFrame:EnableMouse(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", mainFrame.StartMoving)
    mainFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relPoint, x, y = self:GetPoint()
        BazaarChecker.db.settings.mainFramePoint = { point = point, relPoint = relPoint, x = x, y = y }
    end)
    self:ApplyFlatSkin(mainFrame)
    mainFrame:Hide()

    local pos = self.db.settings.mainFramePoint
    if pos then
        mainFrame:ClearAllPoints()
        mainFrame:SetPoint(pos.point, UIParent, pos.relPoint, pos.x, pos.y)
    end

    local title = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 10, -8)
    title:SetText("Bazaar Checker |cff4b0082by Placid|r")

    local closeBtn = CreateFrame("Button", nil, mainFrame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -2, -2)
    closeBtn:SetScript("OnClick", function() mainFrame:Hide() end)

    local divider = mainFrame:CreateTexture(nil, "ARTWORK")
    divider:SetHeight(1)
    divider:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 8, -26)
    divider:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -8, -26)
    divider:SetTexture("Interface\\Buttons\\WHITE8x8")
    local a = self.ACCENT_COLOR
    divider:SetVertexColor(a[1], a[2], a[3], 0.8)

    self:BuildWishlistContent(mainFrame, 42)

    self.mainFrame = mainFrame
end

function BazaarChecker:ToggleMainFrame()
    if not self.mainFrame then return end
    if self.mainFrame:IsShown() then
        self.mainFrame:Hide()
    else
        self.mainFrame:Show()
    end
end
