-- Cross-hotbar style HUD built from the original 1.12 action buttons.
-- No spell is cast by Lua. Every action still comes from a real key press.

local _G = _G or getfenv(0)

local buttonLayout = {
  [1] = { 128, -40, "A", 0.20, 0.90, 0.25 },
  [2] = { 168,   0, "B", 0.95, 0.20, 0.20 },
  [3] = {  88,   0, "X", 0.20, 0.55, 1.00 },
  [4] = { 128,  40, "Y", 1.00, 0.82, 0.15 },
  [5] = {-128,  40, "^", 0.82, 0.86, 0.90 },
  [6] = { -88,   0, ">", 0.82, 0.86, 0.90 },
  [7] = {-128, -40, "v", 0.82, 0.86, 0.90 },
  [8] = {-168,   0, "<", 0.82, 0.86, 0.90 },
}

local layerDefinitions = {
  base  = { title = "ZAKLAD", modifier = "",      framePrefix = "ActionButton" },
  shift = { title = "LB",     modifier = "SHIFT", framePrefix = "MultiBarBottomLeftButton" },
  ctrl  = { title = "LT",     modifier = "CTRL",  framePrefix = "MultiBarBottomRightButton" },
}

local function MakeText(parent, template, text)
  local label = parent:CreateFontString(nil, "OVERLAY", template)
  label:SetText(text or "")
  return label
end

local function SaveButtonState(button)
  if not button or OctoPort.originalButtons[button] then return end
  local point, relativeTo, relativePoint, x, y = button:GetPoint(1)
  local hotkey = _G[button:GetName() .. "HotKey"]
  OctoPort.originalButtons[button] = {
    parent = button:GetParent(),
    scale = button:GetScale(),
    alpha = button:GetAlpha(),
    shown = button:IsShown(),
    point = point,
    relativeTo = relativeTo,
    relativePoint = relativePoint,
    x = x,
    y = y,
    hotkeyShown = hotkey and hotkey:IsShown(),
  }
end

local function AddBadge(button, slot)
  if not button then return end
  if button.octoBadge then
    button.octoBadge:Show()
    local existingHotkey = _G[button:GetName() .. "HotKey"]
    if existingHotkey then existingHotkey:Hide() end
    return
  end
  local data = buttonLayout[slot]
  if not data then return end

  local badge = CreateFrame("Frame", nil, button)
  badge:SetWidth(19)
  badge:SetHeight(19)
  badge:SetPoint("TOPRIGHT", button, "TOPRIGHT", 5, 5)
  badge:SetFrameLevel(button:GetFrameLevel() + 5)

  local texture = badge:CreateTexture(nil, "ARTWORK")
  texture:SetAllPoints(badge)
  texture:SetTexture("Interface\\Buttons\\UI-Quickslot2")
  texture:SetVertexColor(data[4], data[5], data[6])

  local text = MakeText(badge, "GameFontNormalSmall", data[3])
  text:SetPoint("CENTER", badge, "CENTER", 0, 1)
  text:SetTextColor(data[4], data[5], data[6])

  badge.texture = texture
  badge.text = text
  button.octoBadge = badge

  local hotkey = _G[button:GetName() .. "HotKey"]
  if hotkey then hotkey:Hide() end
end

local function SetButtonPoint(button, parent, slot)
  if not button or not buttonLayout[slot] then return end
  local data = buttonLayout[slot]
  SaveButtonState(button)
  button:SetParent(parent)
  button:ClearAllPoints()
  button:SetPoint("CENTER", parent, "CENTER", data[1], data[2])
  button:SetScale(1.08)
  button:SetAlpha(1)
  AddBadge(button, slot)
  local hotkey = _G[button:GetName() .. "HotKey"]
  if hotkey then hotkey:Hide() end
end

function OctoPort:CreateRoot()
  if self.root then return end

  self.originalButtons = self.originalButtons or {}
  self.layers = {}

  local root = CreateFrame("Frame", "OctoPortHUD", UIParent)
  root:SetWidth(400)
  root:SetHeight(150)
  root:SetFrameStrata("MEDIUM")
  root:SetClampedToScreen(true)
  root:SetMovable(true)
  root:RegisterForDrag("LeftButton")
  root:SetScript("OnDragStart", function()
    if OctoPort.config.moveMode then this:StartMoving() end
  end)
  root:SetScript("OnDragStop", function()
    this:StopMovingOrSizing()
    local cx, cy = this:GetCenter()
    if cx and cy then
      OctoPort.config.x = cx - (UIParent:GetWidth() / 2)
      OctoPort.config.y = cy
    end
    OctoPort:ApplyLayout()
  end)

  local background = CreateFrame("Frame", nil, root)
  background:SetAllPoints(root)
  background:SetFrameLevel(root:GetFrameLevel())
  background:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
  })
  background:SetBackdropColor(0.025, 0.04, 0.055, 0.88)
  background:SetBackdropBorderColor(0.18, 0.75, 0.72, 0.75)

  local title = MakeText(root, "GameFontNormal", "WOW CONTROLLER")
  title:SetPoint("TOP", root, "TOP", 0, -8)
  title:SetTextColor(0.24, 0.84, 0.81)

  local active = MakeText(root, "GameFontHighlightSmall", "ZAKLAD")
  active:SetPoint("TOP", title, "BOTTOM", 0, -2)

  local hint = MakeText(root, "GameFontDisableSmall", "LB = SHIFT   LT = CTRL   L3 = CIL   R3 = SKOK")
  hint:SetPoint("BOTTOM", root, "BOTTOM", 0, 7)

  for key, definition in pairs(layerDefinitions) do
    local layer = CreateFrame("Frame", "OctoPortLayer_" .. key, root)
    layer:SetWidth(390)
    layer:SetHeight(100)
    layer:SetPoint("CENTER", root, "CENTER", 0, 0)

    local layerLabel = MakeText(layer, "GameFontNormalSmall", definition.title)
    layerLabel:SetPoint("LEFT", layer, "LEFT", 8, 0)
    layerLabel:SetTextColor(0.24, 0.84, 0.81)
    layer.layerLabel = layerLabel
    layer.buttons = {}

    self.layers[key] = layer
  end

  self.root = root
  self.background = background
  self.activeLayerText = active
  self.hintText = hint

  local hidden = CreateFrame("Frame", "OctoPortHiddenButtons", UIParent)
  hidden:Hide()
  self.hiddenButtons = hidden

  root:SetScript("OnUpdate", function()
    OctoPort.updateElapsed = (OctoPort.updateElapsed or 0) + arg1
    if OctoPort.updateElapsed < 0.05 then return end
    OctoPort.updateElapsed = 0
    OctoPort:UpdateLayer(false)
  end)
end

function OctoPort:CaptureAndPositionButtons()
  if not self.root then return end

  for key, definition in pairs(layerDefinitions) do
    local layer = self.layers[key]
    for slot = 1, 8 do
      local button = _G[definition.framePrefix .. slot]
      if button then
        SetButtonPoint(button, layer, slot)
        layer.buttons[slot] = button
      end
    end
  end

  -- Bonus action buttons replace the base layer for stances, stealth and forms.
  self.bonusButtons = self.bonusButtons or {}
  for slot = 1, 8 do
    local button = _G["BonusActionButton" .. slot]
    if button then
      SetButtonPoint(button, self.layers.base, slot)
      self.bonusButtons[slot] = button
    end
  end

  -- Slots 9-12 are not part of the controller diamond. Keep them from
  -- following ActionButton8 after the default UI updates its anchors.
  local unusedPrefixes = {
    "ActionButton",
    "BonusActionButton",
    "MultiBarBottomLeftButton",
    "MultiBarBottomRightButton",
  }
  for _, prefix in pairs(unusedPrefixes) do
    for slot = 9, 12 do
      local button = _G[prefix .. slot]
      if button then
        SaveButtonState(button)
        button:SetParent(self.hiddenButtons)
      end
    end
  end

  self:UpdateBonusButtons(true)
end

function OctoPort:UpdateBonusButtons(force)
  local bonusVisible = BonusActionBarFrame and BonusActionBarFrame:IsVisible()
  if not force and self.lastBonusVisible == bonusVisible then return end
  self.lastBonusVisible = bonusVisible

  for slot = 1, 8 do
    local normal = self.layers.base.buttons[slot]
    local bonus = self.bonusButtons and self.bonusButtons[slot]
    if normal then
      normal:SetAlpha(bonusVisible and 0 or 1)
      normal:EnableMouse(not bonusVisible)
    end
    if bonus then
      bonus:SetAlpha(bonusVisible and 1 or 0)
      bonus:EnableMouse(bonusVisible)
      bonus:Show()
    end
  end
end

function OctoPort:GetActiveLayer()
  if IsControlKeyDown and IsControlKeyDown() then return "ctrl" end
  if IsShiftKeyDown and IsShiftKeyDown() then return "shift" end
  return "base"
end

function OctoPort:UpdateLayer(force)
  if not self.root or not self.config or not self.config.enabled then return end
  self:UpdateBonusButtons(false)

  local active = self:GetActiveLayer()
  if not force and self.lastLayer == active and self.lastEditMode == self.config.editMode then return end
  self.lastLayer = active
  self.lastEditMode = self.config.editMode

  if self.config.editMode then
    local positions = { base = 100, shift = 10, ctrl = -80 }
    for key, layer in pairs(self.layers) do
      layer:ClearAllPoints()
      layer:SetPoint("CENTER", self.root, "CENTER", 0, positions[key])
      layer:SetAlpha(key == active and 1 or 0.72)
      layer:Show()
      for slot = 1, 8 do
        if layer.buttons[slot] then layer.buttons[slot]:Show() end
      end
    end
    self.root:SetHeight(340)
    self.activeLayerText:SetText("EDITACE LISEK")
    self.hintText:SetText("Pretahni schopnosti mysi  |  /octoport edit = hotovo")
  else
    for key, layer in pairs(self.layers) do
      layer:ClearAllPoints()
      layer:SetPoint("CENTER", self.root, "CENTER", 0, 0)
      layer:SetAlpha(1)
      if key == active then
        layer:Show()
        for slot = 1, 8 do
          if layer.buttons[slot] then layer.buttons[slot]:Show() end
        end
      else
        layer:Hide()
      end
    end
    self.root:SetHeight(150)
    self.activeLayerText:SetText(layerDefinitions[active].title)
    self.hintText:SetText("LB = SHIFT   LT = CTRL   L3 = CIL   R3 = SKOK")
  end
end

function OctoPort:ApplyLayout()
  if not self.root or not self.config then return end
  self.root:SetScale(self.config.scale or 1)
  self.root:ClearAllPoints()
  local y = self.config.y or 122
  if self.config.editMode and y < 170 then y = 170 end
  self.root:SetPoint("CENTER", UIParent, "BOTTOM", self.config.x or 0, y)
  self:SetMoveMode(self.config.moveMode)
end

function OctoPort:SetMoveMode(enabled)
  if not self.root then return end
  local changed = self.lastMoveMode ~= (enabled and true or false)
  self.lastMoveMode = enabled and true or false
  self.config.moveMode = enabled and true or false
  self.root:EnableMouse(self.config.moveMode)
  if self.config.moveMode then
    self.background:SetBackdropBorderColor(1.0, 0.65, 0.15, 1)
    self.activeLayerText:SetText("TAHNI MYSI")
    if changed then
      self:Print("HUD unlocked. Drag the panel with the left mouse button; /octoport move locks it.")
    end
  else
    self.background:SetBackdropBorderColor(0.18, 0.75, 0.72, 0.75)
    self:UpdateLayer(true)
  end
end

function OctoPort:RestoreDefaultButtons()
  if not self.originalButtons then return end
  for button, state in pairs(self.originalButtons) do
    button:SetParent(state.parent)
    button:ClearAllPoints()
    if state.point then
      button:SetPoint(state.point, state.relativeTo, state.relativePoint, state.x, state.y)
    end
    button:SetScale(state.scale or 1)
    button:SetAlpha(state.alpha or 1)
    button:EnableMouse(true)
    if button.octoBadge then button.octoBadge:Hide() end
    local hotkey = _G[button:GetName() .. "HotKey"]
    if hotkey then
      if state.hotkeyShown then hotkey:Show() else hotkey:Hide() end
    end
    if state.shown then button:Show() else button:Hide() end
  end
end

function OctoPort:SetUIEnabled(enabled)
  if enabled then
    self:CaptureAndPositionButtons()
    self.root:Show()
    self:ApplyLayout()
    self:UpdateLayer(true)
  else
    self:RestoreDefaultButtons()
    self.root:Hide()
  end
end

function OctoPort:InitializeUI()
  self:CreateRoot()
  self:ApplyLayout()
  self:SetUIEnabled(self.config.enabled)

  if UIParent_ManageFramePositions and not self.manageHooked then
    self.manageHooked = true
    self.originalManageFramePositions = UIParent_ManageFramePositions
    UIParent_ManageFramePositions = function(a1, a2, a3)
      OctoPort.originalManageFramePositions(a1, a2, a3)
      if OctoPort.config and OctoPort.config.enabled then
        OctoPort:CaptureAndPositionButtons()
        OctoPort:UpdateLayer(true)
      end
    end
  end
end
