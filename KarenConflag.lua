local inCombat = false
local locked = true
local throttle = 0
local configPreview = false

local defaults = { x = 0, y = -200, size = 40, opacityCD = 0.4, opacityReady = 1.0 }

local function HasConflagrate()
    for i = 1, GetNumTalents(3) do
        local name, _, _, _, rank = GetTalentInfo(3, i)
        if name == "Conflagrate" and rank > 0 then
            return true
        end
    end
    return false
end

local frame = CreateFrame("Frame", "KarenConflagFrame", UIParent)
frame:SetWidth(defaults.size)
frame:SetHeight(defaults.size)
frame:SetPoint("CENTER", UIParent, "CENTER", defaults.x, defaults.y)

local icon = frame:CreateTexture(nil, "BACKGROUND")
icon:SetAllPoints(frame)
icon:SetTexture("Interface\\Icons\\Spell_Fire_Fireball")

local glow = frame:CreateTexture(nil, "OVERLAY")
glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
glow:SetWidth(defaults.size * 2)
glow:SetHeight(defaults.size * 2)
glow:SetPoint("CENTER", frame, "CENTER", 0, 0)
glow:SetBlendMode("ADD")
glow:Hide()

local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
text:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")
text:SetAllPoints(frame)
text:SetTextColor(1, 1, 1)

frame:SetScript("OnUpdate", function()
    if not inCombat and not configPreview then return end
    throttle = throttle + arg1
    if throttle < 0.1 then return end
    throttle = 0

    local opacityCD    = KarenConflagDB and KarenConflagDB.opacityCD    or 0.4
    local opacityReady = KarenConflagDB and KarenConflagDB.opacityReady or 1.0

    if configPreview and not inCombat then
        icon:SetVertexColor(1, 1, 1)
        icon:SetAlpha(opacityReady)
        local size = KarenConflagDB and KarenConflagDB.size or defaults.size
        frame:SetWidth(size)
        frame:SetHeight(size)
        glow:Hide()
        text:SetText("")
        return
    end
    local start, duration = GetSpellCooldown("Conflagrate")
    if duration and duration > 1.5 then
        local remaining = (start + duration) - GetTime()
        if remaining > 0 then
            icon:SetVertexColor(1, 1, 1)
            icon:SetAlpha(opacityCD)
            local size = KarenConflagDB and KarenConflagDB.size or defaults.size
            frame:SetWidth(size)
            frame:SetHeight(size)
            glow:Hide()
            text:SetText(string.format("%.1f", remaining))
            return
        end
    end
    -- ready: scale + alpha pulse + glow
    local pulse = 0.6 + 0.4 * math.abs(math.sin(GetTime() * 3))
    local size = KarenConflagDB and KarenConflagDB.size or defaults.size
    local scaled = size * (1 + 0.15 * math.abs(math.sin(GetTime() * 3)))
    frame:SetWidth(scaled)
    frame:SetHeight(scaled)
    glow:SetWidth(scaled * 2)
    glow:SetHeight(scaled * 2)
    glow:SetAlpha(pulse)
    glow:Show()
    icon:SetVertexColor(1, 1, 1)
    icon:SetAlpha(opacityReady * pulse)
    text:SetText("")
end)

local function ApplySettings()
    local db = KarenConflagDB
    frame:SetWidth(db.size)
    frame:SetHeight(db.size)
    glow:SetWidth(db.size * 2)
    glow:SetHeight(db.size * 2)
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", db.x, db.y)
end

-- Config window
local cfg = CreateFrame("Frame", "KarenConflagConfig", UIParent)
cfg:SetWidth(340)
cfg:SetHeight(450)
cfg:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
local cfgbg = cfg:CreateTexture(nil, "BACKGROUND")
cfgbg:SetAllPoints(cfg)
cfgbg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
cfg:EnableMouse(true)
cfg:SetMovable(true)
cfg:RegisterForDrag("LeftButton")
cfg:SetScript("OnDragStart", function() cfg:StartMoving() end)
cfg:SetScript("OnDragStop", function() cfg:StopMovingOrSizing() end)
cfg:SetScript("OnShow", function()
    configPreview = true
    frame:Show()
end)
cfg:SetScript("OnHide", function()
    configPreview = false
    if not inCombat then frame:Hide() end
end)
cfg:Hide()

local title = cfg:CreateFontString(nil, "OVERLAY", "GameFontNormal")
title:SetPoint("TOP", cfg, "TOP", 0, -16)
title:SetText("KarenConflag")

local function MakeSlider(parent, label, minVal, maxVal, step, yOffset, getValue, setValue)
    local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, yOffset)
    lbl:SetText(label)

    local sliderName = "KarenConflagSlider" .. label
    local slider = CreateFrame("Slider", sliderName, parent, "OptionsSliderTemplate")
    slider:SetWidth(160)
    slider:SetHeight(16)
    slider:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, yOffset - 16)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)
    slider:SetValue(getValue())
    getglobal(sliderName .. "Low"):SetText(minVal)
    getglobal(sliderName .. "High"):SetText(maxVal)
    getglobal(sliderName .. "Text"):SetText("")

    local valText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    valText:SetPoint("LEFT", slider, "RIGHT", 6, 0)
    valText:SetText(tostring(math.floor(getValue())))

    slider:SetScript("OnValueChanged", function()
        setValue(this:GetValue())
        valText:SetText(tostring(math.floor(this:GetValue())))
        ApplySettings()
    end)
    return slider, valText
end

local function MakePixelSlider(parent, label, yOffset, getDB, setDB, minVal, maxVal)
    minVal = minVal or -500
    maxVal = maxVal or 500
    local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, yOffset)
    lbl:SetText(label)

    local sliderName = "KarenConflagSlider" .. label
    local slider = CreateFrame("Slider", sliderName, parent, "OptionsSliderTemplate")
    slider:SetWidth(160)
    slider:SetHeight(16)
    slider:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, yOffset - 16)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(1)
    slider:SetValue(getDB())
    getglobal(sliderName .. "Low"):SetText(tostring(minVal))
    getglobal(sliderName .. "High"):SetText(tostring(maxVal))
    getglobal(sliderName .. "Text"):SetText("")

    local valText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    valText:SetPoint("LEFT", slider, "RIGHT", 6, 0)
    valText:SetText(tostring(math.floor(getDB())))

    local function refresh()
        valText:SetText(tostring(math.floor(getDB())))
        slider:SetValue(getDB())
        ApplySettings()
    end

    slider:SetScript("OnValueChanged", function()
        setDB(math.floor(this:GetValue()))
        valText:SetText(tostring(math.floor(this:GetValue())))
        ApplySettings()
    end)

    local btnMinus = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btnMinus:SetWidth(22)
    btnMinus:SetHeight(18)
    btnMinus:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, -16)
    btnMinus:SetText("-")
    btnMinus:SetScript("OnClick", function()
        setDB(getDB() - 1)
        refresh()
    end)

    local btnPlus = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btnPlus:SetWidth(22)
    btnPlus:SetHeight(18)
    btnPlus:SetPoint("LEFT", btnMinus, "RIGHT", 4, 0)
    btnPlus:SetText("+")
    btnPlus:SetScript("OnClick", function()
        setDB(getDB() + 1)
        refresh()
    end)
end

MakeSlider(cfg, "Opacity CD", 0.0, 1.0, 0.05, -36,
    function() return KarenConflagDB and KarenConflagDB.opacityCD or defaults.opacityCD end,
    function(v) KarenConflagDB.opacityCD = v end)

MakeSlider(cfg, "Opacity Ready", 0.0, 1.0, 0.05, -100,
    function() return KarenConflagDB and KarenConflagDB.opacityReady or defaults.opacityReady end,
    function(v) KarenConflagDB.opacityReady = v end)

MakePixelSlider(cfg, "Size", -164,
    function() return KarenConflagDB and KarenConflagDB.size or defaults.size end,
    function(v) KarenConflagDB.size = v end, 20, 120)

MakePixelSlider(cfg, "X", -240,
    function() return KarenConflagDB and KarenConflagDB.x or defaults.x end,
    function(v) KarenConflagDB.x = v end)

MakePixelSlider(cfg, "Y", -312,
    function() return KarenConflagDB and KarenConflagDB.y or defaults.y end,
    function(v) KarenConflagDB.y = v end)

-- Lock/Unlock button
local lockBtn = CreateFrame("Button", nil, cfg, "UIPanelButtonTemplate")
lockBtn:SetWidth(100)
lockBtn:SetHeight(22)
lockBtn:SetPoint("BOTTOM", cfg, "BOTTOM", -60, 14)
lockBtn:SetText(locked and "Unlock" or "Lock")
lockBtn:SetScript("OnClick", function()
    locked = not locked
    if locked then
        frame:SetMovable(false)
        frame:EnableMouse(false)
        lockBtn:SetText("Unlock")
        local x, y = frame:GetCenter()
        local cx, cy = UIParent:GetCenter()
        KarenConflagDB.x = math.floor(x - cx)
        KarenConflagDB.y = math.floor(y - cy)
    else
        frame:SetMovable(true)
        frame:EnableMouse(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", function() frame:StartMoving() end)
        frame:SetScript("OnDragStop", function()
            frame:StopMovingOrSizing()
            local x, y = frame:GetCenter()
            local cx, cy = UIParent:GetCenter()
            KarenConflagDB.x = math.floor(x - cx)
            KarenConflagDB.y = math.floor(y - cy)
        end)
        lockBtn:SetText("Lock")
    end
end)

local closeBtn = CreateFrame("Button", nil, cfg, "UIPanelButtonTemplate")
closeBtn:SetWidth(60)
closeBtn:SetHeight(22)
closeBtn:SetPoint("BOTTOM", cfg, "BOTTOM", 60, 14)
closeBtn:SetText("Close")
closeBtn:SetScript("OnClick", function() cfg:Hide() end)

frame:SetScript("OnEvent", function()
    if event == "VARIABLES_LOADED" then
        if not KarenConflagDB then KarenConflagDB = {} end
        if KarenConflagDB.x       == nil then KarenConflagDB.x       = defaults.x       end
        if KarenConflagDB.y       == nil then KarenConflagDB.y       = defaults.y       end
        if KarenConflagDB.size       == nil then KarenConflagDB.size       = defaults.size       end
        if KarenConflagDB.opacityCD  == nil then KarenConflagDB.opacityCD  = defaults.opacityCD  end
        if KarenConflagDB.opacityReady == nil then KarenConflagDB.opacityReady = defaults.opacityReady end
        ApplySettings()
    elseif event == "PLAYER_REGEN_DISABLED" then
        inCombat = true
        if HasConflagrate() then frame:Show() end
    elseif event == "PLAYER_REGEN_ENABLED" then
        inCombat = false
        if not configPreview then frame:Hide() end
    elseif event == "PLAYER_TALENT_UPDATE" then
        if not (inCombat and HasConflagrate()) and not configPreview then
            frame:Hide()
        end
    end
end)

frame:RegisterEvent("VARIABLES_LOADED")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("PLAYER_TALENT_UPDATE")

frame:Hide()

SLASH_KARENCONFLAG1 = "/karenconflag"
SlashCmdList["KARENCONFLAG"] = function()
    if cfg:IsShown() then cfg:Hide() else cfg:Show() end
end
