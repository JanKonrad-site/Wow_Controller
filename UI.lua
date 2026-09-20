-- Non-invasive controller HUD for WoW 1.12.
--
-- This file deliberately does not reparent Blizzard action buttons and does
-- not replace global FrameXML functions. The HUD mirrors action-slot state in
-- its own frames; real actions still execute only after a controller keypress.

local buttonLayout = {
  [1] = { 128, -40, "A", 0.20, 0.90, 0.25 },
  [2] = { 168,   0, "B", 0.95, 0.20, 0.20 },
  [3] = {  88,   0, "X", 0.20, 0.55, 1.00 },
  [4] = { 128,  40, "Y", 1.00, 0.82, 0.15 },
}

local targetLayout = {
  { direction = "up",    x = -128, y =  40, glyph = "^", caption = "PRATEL -" },
  { direction = "right", x =  -88, y =   0, glyph = ">", caption = "NEPRITEL +" },
  { direction = "down",  x = -128, y = -40, glyph = "v", caption = "PRATEL +" },
  { direction = "left",  x = -168, y =   0, glyph = "<", caption = "NEPRITEL -" },
}

local layerDefinitions = {
  base  = { title = "ZAKLAD" },
  shift = { title = "LB" },
  ctrl  = { title = "LT" },
}

local function MakeText(parent, template, text)
  local label = parent:CreateFontString(nil, "OVERLAY", template)
  label:SetText(text or "")
  return label
end

local function MakeBackdrop(frame, borderRed, borderGreen, borderBlue)
  frame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Buttons\\UI-Quickslot2",
    tile = true,
    tileSize = 8,
    edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
  })
  frame:SetBackdropColor(0.025, 0.04, 0.055, 0.94)
  frame:SetBackdropBorderColor(borderRed or 0.50, borderGreen or 0.56, borderBlue or 0.60, 0.92)
end

local function CreateMirrorButton(parent, slot)
  local data = buttonLayout[slot]
  local button = CreateFrame("Frame", nil, parent)
  button:SetWidth(42)
  button:SetHeight(42)
  button:SetPoint("CENTER", parent, "CENTER", data[1], data[2])
  MakeBackdrop(button, data[4], data[5], data[6])

  local icon = button:CreateTexture(nil, "ARTWORK")
  icon:SetPoint("TOPLEFT", button, "TOPLEFT", 5, -5)
  icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -5, 5)
  icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")

  local shade = button:CreateTexture(nil, "OVERLAY")
  shade:SetAllPoints(icon)
  shade:SetTexture("Interface\\Buttons\\WHITE8X8")
  shade:SetVertexColor(0, 0, 0, 0)

  local glyph = MakeText(button, "GameFontNormalSmall", data[3])
  glyph:SetPoint("TOPRIGHT", button, "TOPRIGHT", 3, 4)
  glyph:SetTextColor(data[4], data[5], data[6])

  local count = MakeText(button, "NumberFontNormalSmall", "")
  count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -3, 3)

  button.icon = icon
  button.shade = shade
  button.glyph = glyph
  button.count = count
  button.slot = slot
  return button
end

local function CreateTargetPad(parent)
  local pad = CreateFrame("Frame", "OctoPortTargetPad", parent)
  pad:SetWidth(210)
  pad:SetHeight(100)
  pad:SetPoint("CENTER", parent, "CENTER", 0, 0)

  for index = 1, table.getn(targetLayout) do
    local data = targetLayout[index]
    local node = CreateFrame("Frame", nil, pad)
    node:SetWidth(34)
    node:SetHeight(34)
    node:SetPoint("CENTER", pad, "CENTER", data.x, data.y)
    MakeBackdrop(node, 0.72, 0.78, 0.82)

    local glyph = MakeText(node, "GameFontNormal", data.glyph)
    glyph:SetPoint("CENTER", node, "CENTER", 0, 1)
    glyph:SetTextColor(0.82, 0.86, 0.90)

    local caption = MakeText(node, "GameFontDisableSmall", data.caption)
    if data.direction == "up" then
      caption:SetPoint("BOTTOM", node, "TOP", 0, 1)
    elseif data.direction == "down" then
      caption:SetPoint("TOP", node, "BOTTOM", 0, -1)
    else
      caption:SetPoint("LEFT", node, "RIGHT", 3, 0)
    end

    node.direction = data.direction
    pad[index] = node
  end

  return pad
end

local function GetBaseActionSlot(slot)
  local page = CURRENT_ACTIONBAR_PAGE or 1
  if page == 1 and GetBonusBarOffset then
    local offset = GetBonusBarOffset() or 0
    if offset > 0 then
      page = (NUM_ACTIONBAR_PAGES or 6) + offset
    elseif BonusActionBarFrame and BonusActionBarFrame.lastBonusBar then
      page = (NUM_ACTIONBAR_PAGES or 6) + BonusActionBarFrame.lastBonusBar
    end
  end
  return slot + ((page - 1) * (NUM_ACTIONBAR_BUTTONS or 12))
end

function OctoPort:GetActionSlot(layerName, slot)
  if layerName == "shift" then return 60 + slot end
  if layerName == "ctrl" then return 48 + slot end
  return GetBaseActionSlot(slot)
end

function OctoPort:CreateRoot()
  if self.root then return end

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

  local hint = MakeText(root, "GameFontDisableSmall", "D-PAD = CILE   A = POTVRDIT   DRZ MENU = KOLO")
  hint:SetPoint("BOTTOM", root, "BOTTOM", 0, 7)

  local settings = CreateFrame("Button", nil, root, "UIPanelButtonTemplate")
  settings:SetWidth(32)
  settings:SetHeight(20)
  settings:SetPoint("TOPRIGHT", root, "TOPRIGHT", -8, -7)
  settings:SetText("WC")
  settings:SetScript("OnClick", function()
    if OctoPort.ToggleConfig then OctoPort:ToggleConfig(true) end
  end)

  local targetName = MakeText(root, "GameFontHighlightSmall", "BEZ CILE")
  targetName:SetPoint("TOPLEFT", root, "TOPLEFT", 12, -10)
  targetName:SetWidth(105)
  targetName:SetJustifyH("LEFT")

  for key, definition in pairs(layerDefinitions) do
    local layer = CreateFrame("Frame", "OctoPortLayer_" .. key, root)
    layer:SetWidth(390)
    layer:SetHeight(100)
    layer:SetPoint("CENTER", root, "CENTER", 0, 0)
    layer.buttons = {}
    for slot = 1, 4 do
      layer.buttons[slot] = CreateMirrorButton(layer, slot)
    end
    self.layers[key] = layer
  end

  self.root = root
  self.background = background
  self.activeLayerText = active
  self.hintText = hint
  self.targetNameText = targetName
  self.targetPad = CreateTargetPad(root)
  self.settingsButton = settings

  root:SetScript("OnUpdate", function()
    OctoPort.updateElapsed = (OctoPort.updateElapsed or 0) + arg1
    if OctoPort.updateElapsed < 0.10 then return end
    OctoPort.updateElapsed = 0
    OctoPort:UpdateLayer(false)
    OctoPort:UpdateActionMirrors()
    OctoPort:UpdateTargetDisplay()
  end)
end

function OctoPort:GetActiveLayer()
  if self.controllerLayerState then
    if self.controllerLayerState.ctrl then return "ctrl" end
    if self.controllerLayerState.shift then return "shift" end
  end

  local mapping = self.config and self.config.nativeModifiers or { SHIFT = "shift", CTRL = "ctrl" }
  if IsControlKeyDown and IsControlKeyDown() and mapping.CTRL then return mapping.CTRL end
  if IsShiftKeyDown and IsShiftKeyDown() and mapping.SHIFT then return mapping.SHIFT end
  if IsAltKeyDown and IsAltKeyDown() and mapping.ALT then return mapping.ALT end
  return "base"
end

function OctoPort:UpdateActionMirrors()
  if not self.layers or not self.config or not self.config.enabled then return end
  for layerName, layer in pairs(self.layers) do
    for slot = 1, 4 do
      local button = layer.buttons[slot]
      local action = self:GetActionSlot(layerName, slot)
      button.action = action
      local texture = GetActionTexture(action)
      if texture then
        button.icon:SetTexture(texture)
        button.icon:SetVertexColor(1, 1, 1)
      else
        button.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        button.icon:SetVertexColor(0.35, 0.38, 0.42)
      end

      local usable = IsUsableAction(action)
      local inRange = IsActionInRange(action)
      if (usable == nil or usable == 0) or inRange == 0 then
        button.shade:SetVertexColor(0, 0, 0, 0.62)
      else
        button.shade:SetVertexColor(0, 0, 0, 0)
      end

      local count = GetActionCount(action) or 0
      button.count:SetText(count > 1 and count or "")
    end
  end
end

function OctoPort:PrepareAutomaticTarget()
  if not self.config or not self.config.enabled or not self.config.autoTarget then return end
  if UnitExists("target") and not UnitIsDead("target") then return end
  TargetNearestEnemy()
end

function OctoPort:HandleControllerAction(slot, keystate)
  self.controllerPressed = self.controllerPressed or {}
  self.contextConsumed = self.contextConsumed or {}

  if self.HandleConfigAction and self:HandleConfigAction(slot, keystate) then return end

  if keystate == "down" then
    if self.HandleContextButton and self:HandleContextButton(slot) then
      self.contextConsumed[slot] = true
      return
    end
    local layerName = self:GetActiveLayer()
    local action = self:GetActionSlot(layerName, slot)
    local button = self.layers and self.layers[layerName] and self.layers[layerName].buttons[slot]
    self.controllerPressed[slot] = { button = button, action = action }
    if button then button:SetBackdropColor(0.04, 0.28, 0.30, 0.98) end
    return
  end

  if self.contextConsumed[slot] then
    self.contextConsumed[slot] = nil
    return
  end

  local pressed = self.controllerPressed[slot]
  self.controllerPressed[slot] = nil
  if not pressed or not pressed.action then return end
  if pressed.button then pressed.button:SetBackdropColor(0.025, 0.04, 0.055, 0.94) end
  if not HasAction(pressed.action) then return end
  self:PrepareAutomaticTarget()
  UseAction(pressed.action, 0)
end

function OctoPort:TargetChanged(direction)
  self.targetFlashDirection = direction
  self.targetFlashUntil = GetTime() + 0.30
  self:UpdateTargetDisplay()
end

function OctoPort:UpdateTargetDisplay()
  if not self.targetNameText then return end
  if UnitExists("target") then
    local name = UnitName("target") or "CIL"
    self.targetNameText:SetText(string.upper(name))
    if UnitCanAttack("player", "target") then
      self.targetNameText:SetTextColor(1.0, 0.28, 0.24)
    else
      self.targetNameText:SetTextColor(0.30, 0.95, 0.45)
    end
  else
    self.targetNameText:SetText("BEZ CILE")
    self.targetNameText:SetTextColor(0.65, 0.68, 0.72)
  end

  local activeDirection = nil
  if self.targetFlashUntil and GetTime() < self.targetFlashUntil then activeDirection = self.targetFlashDirection end
  for index = 1, table.getn(targetLayout) do
    local node = self.targetPad and self.targetPad[index]
    if node then
      if node.direction == activeDirection then
        node:SetBackdropBorderColor(0.24, 0.94, 0.88, 1)
      else
        node:SetBackdropBorderColor(0.72, 0.78, 0.82, 0.90)
      end
    end
  end
end

function OctoPort:UpdateLayer(force)
  if not self.root or not self.config or not self.config.enabled then return end
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
    end
    self.root:SetHeight(340)
    self.activeLayerText:SetText("NAHLED TRI VRSTEV")
    self.hintText:SetText("Schopnosti upravuj na puvodnich Blizzard listach")
  else
    for key, layer in pairs(self.layers) do
      layer:ClearAllPoints()
      layer:SetPoint("CENTER", self.root, "CENTER", 0, 0)
      layer:SetAlpha(1)
      if key == active then layer:Show() else layer:Hide() end
    end
    self.root:SetHeight(150)
    self.activeLayerText:SetText(layerDefinitions[active].title)
    self.hintText:SetText("D-PAD = CILE   A = POTVRDIT   DRZ MENU = KOLO")
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
  self.config.moveMode = enabled and true or false
  self.root:EnableMouse(self.config.moveMode)
  if self.config.moveMode then
    self.background:SetBackdropBorderColor(1.0, 0.65, 0.15, 1)
    self.activeLayerText:SetText("TAHNI MYSI")
  else
    self.background:SetBackdropBorderColor(0.18, 0.75, 0.72, 0.75)
    self:UpdateLayer(true)
  end
end

function OctoPort:RestoreDefaultButtons()
  -- Kept as a compatibility entry point for 0.4.x callers. Version 0.5.0 no
  -- longer moves or modifies Blizzard buttons, so there is nothing to restore.
end

function OctoPort:SetUIEnabled(enabled)
  if not self.root then return end
  if enabled then
    self.root:Show()
    self:ApplyLayout()
    self:UpdateLayer(true)
    self:UpdateActionMirrors()
  else
    self.root:Hide()
    if self.radialFrame then self.radialFrame:Hide() end
  end
end

function OctoPort:CreateMinimapButton()
  if self.minimapButton then return end

  local anchor = Minimap or UIParent
  local button = CreateFrame("Button", "OctoPortMinimapButton", anchor)
  button:SetWidth(32)
  button:SetHeight(32)
  button:SetPoint("TOPLEFT", anchor, "TOPLEFT", -3, -3)
  button:SetFrameStrata("MEDIUM")
  button:SetFrameLevel((anchor.GetFrameLevel and anchor:GetFrameLevel() or 0) + 8)
  button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  button:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Buttons\\UI-Quickslot2",
    tile = true,
    tileSize = 8,
    edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
  })
  button:SetBackdropColor(0.025, 0.04, 0.055, 0.96)
  button:SetBackdropBorderColor(0.24, 0.84, 0.81, 1)

  local label = MakeText(button, "GameFontNormalSmall", "WC")
  label:SetPoint("CENTER", button, "CENTER", 0, 1)
  label:SetTextColor(0.24, 0.84, 0.81)

  button:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_LEFT")
    GameTooltip:SetText("WOW Controller")
    GameTooltip:AddLine("Levy klik: test ovladace", 1, 1, 1)
    GameTooltip:AddLine("Pravy klik: nastaveni", 0.75, 0.80, 0.85)
    GameTooltip:Show()
  end)
  button:SetScript("OnLeave", function() GameTooltip:Hide() end)
  button:SetScript("OnClick", function()
    if arg1 == "RightButton" then
      if OctoPort.ShowConfigTab then OctoPort:ShowConfigTab(1, true) end
    elseif OctoPort.StartRawInputTest then
      OctoPort:StartRawInputTest()
    elseif OctoPort.ShowConfigTab then
      OctoPort:ShowConfigTab(4, true)
    end
  end)

  self.minimapButton = button

end

function OctoPort:InitializeUI()
  self:CreateRoot()
  self:CreateMinimapButton()
  self:ApplyLayout()
  self:SetUIEnabled(self.config.enabled)
end
