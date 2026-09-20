-- Non-invasive controller HUD for WoW 1.12.
--
-- This file deliberately does not reparent Blizzard action buttons and does
-- not replace global FrameXML functions. The HUD mirrors action-slot state in
-- its own frames; real actions still execute only after a controller keypress.

local faceLayout = {
  { id = "A", x = 128, y = -40, glyph = "A", red = 0.20, green = 0.90, blue = 0.25 },
  { id = "B", x = 168, y =   0, glyph = "B", red = 0.95, green = 0.20, blue = 0.20 },
  { id = "X", x =  88, y =   0, glyph = "X", red = 0.20, green = 0.55, blue = 1.00 },
  { id = "Y", x = 128, y =  40, glyph = "Y", red = 1.00, green = 0.82, blue = 0.15 },
}

local actionDpadLayout = {
  { id = "DUP",    x = -128, y =  40, glyph = "^", red = 0.72, green = 0.78, blue = 0.82 },
  { id = "DRIGHT", x =  -88, y =   0, glyph = ">", red = 0.72, green = 0.78, blue = 0.82 },
  { id = "DDOWN",  x = -128, y = -40, glyph = "v", red = 0.72, green = 0.78, blue = 0.82 },
  { id = "DLEFT",  x = -168, y =   0, glyph = "<", red = 0.72, green = 0.78, blue = 0.82 },
}

local targetLayout = {
  { direction = "up",    x =   0, y =  40, glyph = "^", caption = "PRATEL -" },
  { direction = "right", x =  40, y =   0, glyph = ">", caption = "NEPRITEL +" },
  { direction = "down",  x =   0, y = -40, glyph = "v", caption = "PRATEL +" },
  { direction = "left",  x = -40, y =   0, glyph = "<", caption = "NEPRITEL -" },
}

local layerDefinitions = {
  base = { title = "ZAKLAD", controls = faceLayout },
  lt = { title = "LT", controls = nil },
  rt = { title = "RT", controls = nil },
}

local layeredControls = {}
for index = 1, table.getn(faceLayout) do table.insert(layeredControls, faceLayout[index]) end
for index = 1, table.getn(actionDpadLayout) do table.insert(layeredControls, actionDpadLayout[index]) end
layerDefinitions.lt.controls = layeredControls
layerDefinitions.rt.controls = layeredControls

local actionIndices = { A = 1, B = 2, X = 3, Y = 4, DUP = 5, DRIGHT = 6, DDOWN = 7, DLEFT = 8 }
local faceByNumber = { "A", "B", "X", "Y" }

-- The HUD is split into explicit header, content, and footer bands. The old
-- 158px frame centered the controls beneath its labels, so target captions
-- and the editor's third row overlapped text and buttons.
local hudLayout = {
  width = 510,
  normalHeight = 206,
  normalContentY = -3,
  editorHeight = 520,
  editorMinimumY = 270,
  editorPositions = { base = 142, lt = 0, rt = -142 },
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

local function CursorCarriesAction()
  if CursorHasItem and CursorHasItem() then return true end
  if CursorHasSpell and CursorHasSpell() then return true end
  if CursorHasMacro and CursorHasMacro() then return true end
  return false
end

local function CanEditActionSlots()
  local locked = (InCombatLockdown and InCombatLockdown()) or
    (UnitAffectingCombat and UnitAffectingCombat("player"))
  if locked then
    if OctoPort.SetEditorStatus then OctoPort:SetEditorStatus("V BOJI NELZE MENIT AKCE", true) end
    return false
  end
  return true
end

local function CreateMirrorButton(parent, data)
  local button = CreateFrame("Button", nil, parent)
  button:SetWidth(42)
  button:SetHeight(42)
  button:SetPoint("CENTER", parent, "CENTER", data.x, data.y)
  button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  button:RegisterForDrag("LeftButton")
  button:EnableMouse(false)
  MakeBackdrop(button, data.red, data.green, data.blue)

  local icon = button:CreateTexture(nil, "ARTWORK")
  icon:SetPoint("TOPLEFT", button, "TOPLEFT", 5, -5)
  icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -5, 5)
  icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")

  local shade = button:CreateTexture(nil, "OVERLAY")
  shade:SetAllPoints(icon)
  shade:SetTexture("Interface\\Buttons\\WHITE8X8")
  shade:SetVertexColor(0, 0, 0, 0)

  local glyph = MakeText(button, "GameFontNormalSmall", data.glyph)
  glyph:SetPoint("TOPRIGHT", button, "TOPRIGHT", 3, 4)
  glyph:SetTextColor(data.red, data.green, data.blue)

  local count = MakeText(button, "NumberFontNormalSmall", "")
  count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -3, 3)

  button.icon = icon
  button.shade = shade
  button.glyph = glyph
  button.count = count
  button.control = data.id
  button:SetScript("OnEnter", function()
    if not OctoPort.config or not OctoPort.config.editMode or not this.action then return end
    GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
    if GameTooltip.SetAction then GameTooltip:SetAction(this.action) else GameTooltip:SetText("Action " .. this.action) end
    GameTooltip:Show()
  end)
  button:SetScript("OnLeave", function() GameTooltip:Hide() end)
  button:SetScript("OnDragStart", function()
    if not OctoPort.config or not OctoPort.config.editMode or not this.action or not CanEditActionSlots() then return end
    if PickupAction then
      PickupAction(this.action)
      OctoPort:SetEditorStatus("SLOT " .. this.action .. " JE NA KURZORU")
    end
  end)
  button:SetScript("OnReceiveDrag", function()
    if not OctoPort.config or not OctoPort.config.editMode or not this.action or not CursorCarriesAction() or not CanEditActionSlots() then return end
    if PlaceAction then
      PlaceAction(this.action)
      OctoPort:SetEditorStatus("AKCE PRIRAZENA DO SLOTU " .. this.action)
      OctoPort:UpdateActionMirrors(true)
    end
  end)
  button:SetScript("OnClick", function()
    if not OctoPort.config or not OctoPort.config.editMode or not this.action then return end
    if not CanEditActionSlots() then return end
    if CursorCarriesAction() and arg1 ~= "RightButton" and PlaceAction then
      PlaceAction(this.action)
      OctoPort:SetEditorStatus("AKCE PRIRAZENA DO SLOTU " .. this.action)
      OctoPort:UpdateActionMirrors(true)
    elseif arg1 == "RightButton" and PickupAction then
      PickupAction(this.action)
      OctoPort:SetEditorStatus("SLOT " .. this.action .. " JE NA KURZORU")
    end
  end)
  return button
end

local function CreateTargetPad(parent)
  local pad = CreateFrame("Frame", "OctoPortTargetPad", parent)
  -- Include the four captions in the declared bounds, not only the nodes.
  pad:SetWidth(232)
  pad:SetHeight(140)
  pad:SetPoint("CENTER", parent, "CENTER", -130, 0)

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
    elseif data.direction == "right" then
      caption:SetPoint("LEFT", node, "RIGHT", 3, 0)
    else
      caption:SetPoint("RIGHT", node, "LEFT", -3, 0)
    end

    node.direction = data.direction
    node.captionText = caption
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
  local control = type(slot) == "number" and faceByNumber[slot] or slot
  local index = actionIndices[control]
  if not index then return nil end
  if layerName == "lt" then return 60 + index end
  if layerName == "rt" then return 48 + index end
  if index > 4 then return nil end
  return GetBaseActionSlot(index)
end

function OctoPort:CreateRoot()
  if self.root then return end

  self.layers = {}
  local root = CreateFrame("Frame", "OctoPortHUD", UIParent)
  root:SetWidth(hudLayout.width)
  root:SetHeight(hudLayout.normalHeight)
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

  local hint = MakeText(root, "GameFontDisableSmall", "D-PAD = CILE   LT/RT = 8 AKCI   MENU = KOLO")
  hint:SetPoint("BOTTOM", root, "BOTTOM", 0, 9)

  local settings = CreateFrame("Button", nil, root, "UIPanelButtonTemplate")
  settings:SetWidth(32)
  settings:SetHeight(20)
  settings:SetPoint("TOPRIGHT", root, "TOPRIGHT", -8, -7)
  settings:SetText("WC")
  settings:EnableMouse(true)
  settings:SetScript("OnClick", function()
    if OctoPort.ToggleConfig then OctoPort:ToggleConfig(true) end
  end)

  local editorDone = CreateFrame("Button", nil, root, "UIPanelButtonTemplate")
  editorDone:SetWidth(86)
  editorDone:SetHeight(22)
  editorDone:SetPoint("BOTTOMRIGHT", root, "BOTTOMRIGHT", -10, 7)
  editorDone:SetText("HOTOVO")
  editorDone:SetScript("OnClick", function()
    if OctoPort.SetActionEditMode then OctoPort:SetActionEditMode(false) end
  end)
  editorDone:Hide()

  local editorStatus = MakeText(root, "GameFontHighlightSmall", "")
  editorStatus:SetPoint("BOTTOMLEFT", root, "BOTTOMLEFT", 12, 30)
  editorStatus:SetWidth(360)
  editorStatus:SetJustifyH("LEFT")
  editorStatus:Hide()

  local targetName = MakeText(root, "GameFontHighlightSmall", "BEZ CILE")
  targetName:SetPoint("TOPLEFT", root, "TOPLEFT", 12, -12)
  targetName:SetWidth(120)
  targetName:SetJustifyH("LEFT")

  for key, definition in pairs(layerDefinitions) do
    local layer = CreateFrame("Frame", "OctoPortLayer_" .. key, root)
    layer:SetWidth(500)
    layer:SetHeight(100)
    layer:SetPoint("CENTER", root, "CENTER", 0, hudLayout.normalContentY)
    layer.buttons = {}
    for index = 1, table.getn(definition.controls) do
      local control = definition.controls[index]
      layer.buttons[control.id] = CreateMirrorButton(layer, control)
    end
    local layerTitle = MakeText(layer, "GameFontNormalSmall", definition.title)
    layerTitle:SetPoint("TOP", layer, "TOP", 0, 4)
    layerTitle:SetTextColor(0.24, 0.84, 0.81)
    layer.titleText = layerTitle
    self.layers[key] = layer
  end

  self.root = root
  self.background = background
  self.activeLayerText = active
  self.hintText = hint
  self.targetNameText = targetName
  self.targetPad = CreateTargetPad(self.layers.base)
  self.settingsButton = settings
  self.editorDoneButton = editorDone
  self.editorStatusText = editorStatus

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
    if self.controllerLayerState.rt then return "rt" end
    if self.controllerLayerState.lt then return "lt" end
  end

  local mapping = self.config and self.config.nativeModifiers or { SHIFT = "lt", CTRL = "rt" }
  if IsControlKeyDown and IsControlKeyDown() and mapping.CTRL then return mapping.CTRL end
  if IsShiftKeyDown and IsShiftKeyDown() and mapping.SHIFT then return mapping.SHIFT end
  if IsAltKeyDown and IsAltKeyDown() and mapping.ALT then return mapping.ALT end
  return "base"
end

function OctoPort:UpdateActionMirrors(force)
  if not self.layers or not self.config then return end
  if not self.config.enabled and not self.config.editMode and not self.config.moveMode and not force then return end
  for layerName, layer in pairs(self.layers) do
    for control, button in pairs(layer.buttons) do
      local action = self:GetActionSlot(layerName, control)
      button.action = action
      local texture = action and GetActionTexture(action)
      if texture then
        button.icon:SetTexture(texture)
        button.icon:SetVertexColor(1, 1, 1)
      else
        button.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        button.icon:SetVertexColor(0.35, 0.38, 0.42)
      end

      local usable = action and IsUsableAction(action)
      local inRange = action and IsActionInRange(action)
      if (usable == nil or usable == 0) or inRange == 0 then
        button.shade:SetVertexColor(0, 0, 0, 0.62)
      else
        button.shade:SetVertexColor(0, 0, 0, 0)
      end

      local count = action and GetActionCount(action) or 0
      button.count:SetText(count > 1 and count or "")
    end
  end
end

function OctoPort:SetEditorStatus(message, isError)
  if not self.editorStatusText then return end
  self.editorStatusText:SetText(message or "")
  if isError then
    self.editorStatusText:SetTextColor(1.0, 0.30, 0.22)
  else
    self.editorStatusText:SetTextColor(0.30, 0.95, 0.72)
  end
  if self.config and self.config.editMode then self.editorStatusText:Show() end
end

function OctoPort:HandleControllerAction(slot, keystate)
  if self.HandleConfigAction and self:HandleConfigAction(slot, keystate) then return end
  if keystate == "down" and self.HandleContextButton then self:HandleContextButton(slot) end
  -- Combat actions never execute here. Session activation binds every action
  -- directly to Blizzard's native ACTIONBUTTON/MULTIACTIONBAR commands. This
  -- legacy handler remains only so ABXY can navigate our settings panel.
end

function OctoPort:TargetChanged()
  -- Native TARGET* bindings do the targeting. We only observe the resulting
  -- unit and pulse its target category; an event cannot reliably reveal
  -- whether the player requested the previous or next unit.
  if UnitExists("target") then
    if UnitCanAttack("player", "target") then
      self.targetFlashCategory = "hostile"
    else
      self.targetFlashCategory = "friendly"
    end
    self.targetFlashUntil = GetTime() + 0.30
  else
    self.targetFlashCategory = nil
    self.targetFlashUntil = nil
  end
  self:UpdateTargetDisplay()
end

function OctoPort:UpdateTargetDisplay()
  if not self.targetNameText then return end
  local targetExists = UnitExists("target")
  local targetCategory = nil
  if targetExists then
    local name = UnitName("target") or "CIL"
    self.targetNameText:SetText(string.upper(name))
    if UnitCanAttack("player", "target") then
      targetCategory = "hostile"
      self.targetNameText:SetTextColor(1.0, 0.28, 0.24)
    else
      targetCategory = "friendly"
      self.targetNameText:SetTextColor(0.30, 0.95, 0.45)
    end
  else
    self.targetNameText:SetText("BEZ CILE")
    self.targetNameText:SetTextColor(0.65, 0.68, 0.72)
    self.targetFlashCategory = nil
    self.targetFlashUntil = nil
  end

  local activeCategory = nil
  if self.targetFlashUntil and GetTime() < self.targetFlashUntil and self.targetFlashCategory == targetCategory then
    activeCategory = targetCategory
  end
  for index = 1, table.getn(targetLayout) do
    local node = self.targetPad and self.targetPad[index]
    if node then
      local isHostileNode = node.direction == "left" or node.direction == "right"
      local isFriendlyNode = node.direction == "up" or node.direction == "down"
      if (activeCategory == "hostile" and isHostileNode) or
         (activeCategory == "friendly" and isFriendlyNode) then
        node:SetBackdropBorderColor(0.24, 0.94, 0.88, 1)
      else
        node:SetBackdropBorderColor(0.72, 0.78, 0.82, 0.90)
      end
    end
  end
end

function OctoPort:UpdateLayer(force)
  if not self.root or not self.config then return end
  if not force and not self.config.enabled and not self.config.editMode and not self.config.moveMode then return end
  local active = self:GetActiveLayer()
  if not force and self.lastLayer == active and self.lastEditMode == self.config.editMode then return end
  self.lastLayer = active
  self.lastEditMode = self.config.editMode

  if self.config.editMode then
    for key, layer in pairs(self.layers) do
      layer:ClearAllPoints()
      layer:SetPoint("CENTER", self.root, "CENTER", 0, hudLayout.editorPositions[key])
      layer:SetAlpha(key == active and 1 or 0.72)
      layer:Show()
      for _, button in pairs(layer.buttons) do button:EnableMouse(true) end
    end
    self.root:SetHeight(hudLayout.editorHeight)
    self.activeLayerText:SetText("20 EDITOVATELNYCH AKCI")
    self.hintText:ClearAllPoints()
    self.hintText:SetPoint("BOTTOMLEFT", self.root, "BOTTOMLEFT", 12, 9)
    self.hintText:SetWidth(360)
    self.hintText:SetJustifyH("LEFT")
    self.hintText:SetText("TAHNI AKCI NA SLOT; PRAVY KLIK = ZVEDNOUT")
    self.hintText:Show()
    if self.editorDoneButton then self.editorDoneButton:Show() end
    if self.editorStatusText then self.editorStatusText:Show() end
  else
    for key, layer in pairs(self.layers) do
      layer:ClearAllPoints()
      layer:SetPoint("CENTER", self.root, "CENTER", 0, hudLayout.normalContentY)
      layer:SetAlpha(1)
      for _, button in pairs(layer.buttons) do button:EnableMouse(false) end
      if key == active then layer:Show() else layer:Hide() end
    end
    self.root:SetHeight(hudLayout.normalHeight)
    self.activeLayerText:SetText(layerDefinitions[active].title)
    self.hintText:ClearAllPoints()
    self.hintText:SetPoint("BOTTOM", self.root, "BOTTOM", 0, 9)
    self.hintText:SetWidth(460)
    self.hintText:SetJustifyH("CENTER")
    self.hintText:SetText("D-PAD = CILE   LT/RT = 8 AKCI   MENU = KOLO")
    self.hintText:Show()
    if self.editorDoneButton then self.editorDoneButton:Hide() end
    if self.editorStatusText then self.editorStatusText:Hide() end
  end
end

function OctoPort:SetActionEditMode(enabled)
  if not self.root or not self.config then return end
  self.config.editMode = enabled and true or false
  if self.config.editMode then
    self.root:Show()
    self:SetEditorStatus("PRETAHNI KOUZLO NEBO PREDMET NA SLOT")
    self:ApplyLayout()
    self:UpdateLayer(true)
    self:UpdateActionMirrors(true)
  else
    for _, layer in pairs(self.layers or {}) do
      for _, button in pairs(layer.buttons or {}) do button:EnableMouse(false) end
    end
    if self.editorDoneButton then self.editorDoneButton:Hide() end
    if self.editorStatusText then self.editorStatusText:Hide() end
    self:UpdateLayer(true)
    self:SetMoveMode(self.config.moveMode)
    if not self.config.enabled then self.root:Hide() end
  end
end

function OctoPort:ApplyLayout()
  if not self.root or not self.config then return end
  self.root:SetScale(self.config.scale or 1)
  self.root:ClearAllPoints()
  local y = self.config.y or 122
  if self.config.editMode and y < hudLayout.editorMinimumY then y = hudLayout.editorMinimumY end
  self.root:SetPoint("CENTER", UIParent, "BOTTOM", self.config.x or 0, y)
  self:SetMoveMode(self.config.moveMode)
end

function OctoPort:SetMoveMode(enabled)
  if not self.root then return end
  self.config.moveMode = enabled and true or false
  self.root:EnableMouse(self.config.moveMode or self.config.editMode)
  if self.config.moveMode then
    self.root:Show()
    self:UpdateLayer(true)
    self:UpdateActionMirrors(true)
    self.background:SetBackdropBorderColor(1.0, 0.65, 0.15, 1)
    self.activeLayerText:SetText("TAHNI MYSI")
  else
    self.background:SetBackdropBorderColor(0.18, 0.75, 0.72, 0.75)
    self:UpdateLayer(true)
    if not self.config.enabled and not self.config.editMode then self.root:Hide() end
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
  elseif not self.config.editMode and not self.config.moveMode then
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
