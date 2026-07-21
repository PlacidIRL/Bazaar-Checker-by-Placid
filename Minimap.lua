local BazaarChecker = BazaarChecker

local function GetPositionOnMinimap(angle)
    local radius = (Minimap:GetWidth() / 2) + 5
    local rad = math.rad(angle)
    return math.cos(rad) * radius, math.sin(rad) * radius
end

function BazaarChecker:BuildMinimapButton()
    if self.minimapButton then return end
    if self.db.settings.minimapHide then return end

    local button = CreateFrame("Button", "BazaarCheckerMinimapButton", Minimap)
    button:SetSize(31, 31)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:RegisterForClicks("LeftButtonUp")
    button:RegisterForDrag("LeftButton")

    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetTexture("Interface\\Icons\\INV_Misc_Coin_02")
    icon:SetSize(18, 18)
    icon:SetPoint("CENTER", button, "CENTER", 0, 1)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT", button, "TOPLEFT")

    local function UpdatePosition(angle)
        local x, y = GetPositionOnMinimap(angle)
        button:ClearAllPoints()
        button:SetPoint("CENTER", Minimap, "CENTER", x, y)
    end

    local dragging = false
    button:SetScript("OnUpdate", function(self)
        if not dragging then return end
        local mx, my = Minimap:GetCenter()
        local px, py = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        px, py = px / scale, py / scale
        local angle = math.deg(math.atan2(py - my, px - mx))
        UpdatePosition(angle)
        BazaarChecker.db.settings.minimapAngle = angle
    end)

    button:SetScript("OnDragStart", function() dragging = true end)
    button:SetScript("OnDragStop", function() dragging = false end)

    button:SetScript("OnClick", function()
        BazaarChecker:ToggleMainFrame()
    end)

    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("Bazaar Checker")
        GameTooltip:AddLine("|cffffff00Left-click|r toggle wishlist window", 1, 1, 1)
        GameTooltip:AddLine("|cffffff00Drag|r to move this button", 1, 1, 1)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)

    UpdatePosition(self.db.settings.minimapAngle or 215)

    self.minimapButton = button
end
