-- Hold-menu radial launcher and context-aware controller buttons.

local _G = _G or getfenv(0)

local radialPositions = {
  { x =   0, y =  112, dx =  0.000, dy =  1.000 },
  { x =  79, y =   79, dx =  0.707, dy =  0.707 },
  { x = 112, y =    0, dx =  1.000, dy =  0.000 },
  { x =  79, y =  -79, dx =  0.707, dy = -0.707 },
  { x =   0, y = -112, dx =  0.000, dy = -1.000 },
  { x = -79, y =  -79, dx = -0.707, dy = -0.707 },
  { x =-112, y =    0, dx = -1.000, dy =  0.000 },
  { x = -79, y =   79, dx = -0.707, dy =  0.707 },
}

local radialActions = {}
local radialActionOrder = {}

local function AddRadialAction(id, label, icon, handler)
  radialActions[id] = { id = id, label = label, icon = icon, handler = handler }
  table.insert(radialActionOrder, id)
end

local function ToggleBags()
  OctoPort_ToggleBags()
end

local function ToggleMap()
  ToggleWorldMap()
end

local function ToggleQuests()
  ToggleQuestLog()
end

local function ToggleCharacterPanel()
  ToggleCharacter("PaperDollFrame")
end

local function ToggleSpells()
  ToggleSpellBook(BOOKTYPE_SPELL)
end

local function ToggleTalents()
  ToggleTalentFrame()
end

local function ToggleSocial()
  ToggleFriendsFrame()
end

local function ToggleBattleLog()
  ToggleCombatLog()
end

local function OpenChat()
  ChatFrame_OpenChat("")
end

local function ToggleHelp()
  OctoPort:ToggleHelp(true)
end

local function ToggleRun()
  ToggleAutoRun()
end

local function ToggleMenu()
  ToggleGameMenu()
end

local function ItemNameFromLink(link)
  if not link then return nil end
  local _, _, itemName = string.find(link, "%[(.-)%]")
  return itemName
end

local function UsePreferredMount()
  local wanted = OctoPort.config and OctoPort.config.mountName or ""
  if wanted == "" then
    OctoPort:Print("Set a mount first: /octoport mount NAME")
    return
  end

  local wantedLower = string.lower(wanted)
  local spellIndex = 1
  while true do
    local spellName = GetSpellName(spellIndex, BOOKTYPE_SPELL)
    if not spellName then break end
    if string.find(string.lower(spellName), wantedLower, 1, true) then
      CastSpell(spellIndex, BOOKTYPE_SPELL)
      return
    end
    spellIndex = spellIndex + 1
  end

  for bag = 0, 4 do
    local slots = GetContainerNumSlots(bag) or 0
    for slot = 1, slots do
      local itemName = ItemNameFromLink(GetContainerItemLink(bag, slot))
      if itemName and string.find(string.lower(itemName), wantedLower, 1, true) then
        UseContainerItem(bag, slot)
        return
      end
    end
  end

  OctoPort:Print("Mount not found in the spellbook or bags: " .. wanted)
end

AddRadialAction("map",       "MAPA",       "Interface\\Icons\\INV_Misc_Map_01", ToggleMap)
AddRadialAction("quests",    "QUESTY",     "Interface\\Icons\\INV_Misc_Note_02", ToggleQuests)
AddRadialAction("bags",      "BATOHY",     "Interface\\Icons\\INV_Misc_Bag_08", ToggleBags)
AddRadialAction("character", "POSTAVA",    "Interface\\Icons\\INV_Chest_Cloth_17", ToggleCharacterPanel)
AddRadialAction("mount",     "MOUNT",      "Interface\\Icons\\Ability_Mount_RidingHorse", UsePreferredMount)
AddRadialAction("chat",      "CHAT",       "Interface\\Icons\\INV_Letter_15", OpenChat)
AddRadialAction("combatlog", "BATTLE LOG", "Interface\\Icons\\INV_Scroll_03", ToggleBattleLog)
AddRadialAction("spellbook", "KOUZLA",     "Interface\\Icons\\INV_Misc_Book_09", ToggleSpells)
AddRadialAction("talents",   "TALENTY",    "Interface\\Icons\\Spell_Nature_Lightning", ToggleTalents)
AddRadialAction("social",    "PRATELE",    "Interface\\Icons\\INV_Misc_GroupLooking", ToggleSocial)
AddRadialAction("autorun",   "AUTO BEH",   "Interface\\Icons\\Ability_Rogue_Sprint", ToggleRun)
AddRadialAction("help",      "NAPOVEDA",   "Interface\\Icons\\INV_Misc_QuestionMark", ToggleHelp)
AddRadialAction("menu",      "MENU",       "Interface\\Icons\\INV_Misc_Gear_01", ToggleMenu)

local function Clamp(value, minimum, maximum)
  if value < minimum then return minimum end
  if value > maximum then return maximum end
  return value
end

local function IsClickable(button)
  if not button or not button:IsVisible() then return false end
  if button.IsEnabled then
    local enabled = button:IsEnabled()
    if not enabled or enabled == 0 then return false end
  end
  return true
end

local function ClickFirstVisible(names)
  for index = 1, table.getn(names) do
    local button = _G[names[index]]
    if IsClickable(button) then
      button:Click()
      return true
    end
  end
  return false
end

function OctoPort:ConfirmVisibleUI()
  local editBox = DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.editBox
  if editBox and editBox:IsVisible() and ChatEdit_SendText then
    ChatEdit_SendText(editBox, 1)
    if ChatEdit_OnEscapePressed then ChatEdit_OnEscapePressed(editBox) end
    return true
  end

  return ClickFirstVisible({
    "StaticPopup1Button1",
    "QuestFrameAcceptButton",
    "QuestFrameCompleteButton",
    "QuestFrameCompleteQuestButton",
    "GossipTitleButton1",
  })
end

function OctoPort:CancelVisibleUI()
  local editBox = DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.editBox
  if editBox and editBox:IsVisible() then
    if ChatEdit_OnEscapePressed then
      ChatEdit_OnEscapePressed(editBox)
    else
      editBox:Hide()
    end
    return true
  end

  if ClickFirstVisible({
    "StaticPopup1Button2",
    "QuestFrameDeclineButton",
    "QuestFrameGoodbyeButton",
  }) then
    return true
  end

  local closableFrames = {
    "GameMenuFrame",
    "QuestFrame",
    "GossipFrame",
    "MerchantFrame",
    "WorldMapFrame",
    "CharacterFrame",
    "SpellBookFrame",
    "FriendsFrame",
    "QuestLogFrame",
    "TalentFrame",
  }

  for index = 1, table.getn(closableFrames) do
    local frame = _G[closableFrames[index]]
    if frame and frame:IsVisible() then
      ToggleGameMenu()
      return true
    end
  end

  return false
end

function OctoPort:HandleContextButton(slot)
  if self.radialFrame and self.radialFrame:IsVisible() and self.radialEditor then
    if slot == 2 then
      self:HideRadial()
      self:Print("Radial menu editor closed.")
      return true
    end
  end

  if self.radialFrame and self.radialFrame:IsVisible() and not self.radialEditor then
    if slot == 1 then
      self.radialConfirmed = true
      self:ActivateRadialSelection()
      self:HideRadial()
      return true
    elseif slot == 2 then
      self.radialCancelled = true
      self:HideRadial()
      return true
    end
  end

  if slot == 1 then return self:ConfirmVisibleUI() end
  if slot == 2 then return self:CancelVisibleUI() end
  return false
end

function OctoPort:GetRadialAction(index)
  if not self.config or not self.config.radialSlots then return nil end
  return radialActions[self.config.radialSlots[index]]
end

function OctoPort:RefreshRadial()
  if not self.radialFrame or not self.config then return end

  for index = 1, 8 do
    local segment = self.radialSegments[index]
    local action = self:GetRadialAction(index)
    if segment and action then
      segment.icon:SetTexture(action.icon)
      segment.label:SetText(action.label)
    end
  end
end

function OctoPort:SetRadialSelection(index)
  if self.radialSelection == index then return end
  self.radialSelection = index

  for slot = 1, 8 do
    local segment = self.radialSegments and self.radialSegments[slot]
    if segment then
      if slot == index then
        segment:SetBackdropBorderColor(0.24, 0.94, 0.88, 1)
        segment:SetBackdropColor(0.04, 0.28, 0.30, 0.98)
      else
        segment:SetBackdropBorderColor(0.60, 0.66, 0.70, 0.92)
        segment:SetBackdropColor(0.025, 0.04, 0.055, 0.94)
      end
    end
  end

  local action = index and self:GetRadialAction(index)
  if self.radialCenterText then
    self.radialCenterText:SetText(action and action.label or "VYBER")
  end
end

function OctoPort:UpdateRadialSelection()
  if not self.radialFrame or not self.radialFrame:IsVisible() or self.radialEditor then return end

  local cursorX, cursorY = GetCursorPosition()
  local scale = self.radialFrame:GetEffectiveScale()
  if not scale or scale == 0 then scale = 1 end
  cursorX = cursorX / scale
  cursorY = cursorY / scale

  local centerX, centerY = self.radialFrame:GetCenter()
  if not centerX or not centerY then return end
  local dx = cursorX - centerX
  local dy = cursorY - centerY
  local lengthSquared = (dx * dx) + (dy * dy)
  if lengthSquared < 576 then
    self:SetRadialSelection(nil)
    return
  end

  local bestIndex = 1
  local bestDot = nil
  for index = 1, 8 do
    local position = radialPositions[index]
    local dot = (dx * position.dx) + (dy * position.dy)
    if not bestDot or dot > bestDot then
      bestDot = dot
      bestIndex = index
    end
  end
  self:SetRadialSelection(bestIndex)
end

function OctoPort:ActivateRadialSelection()
  local action = self.radialSelection and self:GetRadialAction(self.radialSelection)
  if action and action.handler then action.handler() end
end

function OctoPort:CycleRadialAction(index, direction)
  local current = self.config.radialSlots[index]
  local currentIndex = 1
  for position = 1, table.getn(radialActionOrder) do
    if radialActionOrder[position] == current then currentIndex = position end
  end

  currentIndex = currentIndex + direction
  if currentIndex < 1 then currentIndex = table.getn(radialActionOrder) end
  if currentIndex > table.getn(radialActionOrder) then currentIndex = 1 end
  self.config.radialSlots[index] = radialActionOrder[currentIndex]
  self:RefreshRadial()
  self:SetRadialSelection(index)
end

function OctoPort:CreateRadial()
  if self.radialFrame then return end

  local frame = CreateFrame("Frame", "OctoPortRadial", UIParent)
  frame:SetWidth(330)
  frame:SetHeight(330)
  frame:SetFrameStrata("FULLSCREEN_DIALOG")
  frame:SetClampedToScreen(true)
  frame:Hide()

  local center = CreateFrame("Frame", nil, frame)
  center:SetWidth(92)
  center:SetHeight(92)
  center:SetPoint("CENTER", frame, "CENTER", 0, 0)
  center:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 12,
    edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
  })
  center:SetBackdropColor(0.02, 0.03, 0.045, 0.98)
  center:SetBackdropBorderColor(0.18, 0.75, 0.72, 0.95)
  center:EnableMouse(true)
  center:SetScript("OnMouseDown", function()
    if OctoPort.radialEditor then
      OctoPort:HideRadial()
      OctoPort:Print("Radial menu editor closed.")
    end
  end)

  local centerText = center:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  centerText:SetPoint("CENTER", center, "CENTER", 0, 6)
  centerText:SetText("VYBER")
  centerText:SetTextColor(0.24, 0.84, 0.81)

  local centerHint = center:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  centerHint:SetPoint("TOP", centerText, "BOTTOM", 0, -4)
  centerHint:SetText("A / PUST MENU")

  self.radialSegments = {}
  for index = 1, 8 do
    local slotIndex = index
    local position = radialPositions[index]
    local segment = CreateFrame("Button", nil, frame)
    segment:SetWidth(72)
    segment:SetHeight(72)
    segment:SetPoint("CENTER", frame, "CENTER", position.x, position.y)
    segment:SetBackdrop({
      bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true,
      tileSize = 12,
      edgeSize = 10,
      insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    segment:SetBackdropColor(0.025, 0.04, 0.055, 0.94)
    segment:SetBackdropBorderColor(0.60, 0.66, 0.70, 0.92)
    segment:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    local icon = segment:CreateTexture(nil, "ARTWORK")
    icon:SetWidth(34)
    icon:SetHeight(34)
    icon:SetPoint("TOP", segment, "TOP", 0, -7)

    local label = segment:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("BOTTOM", segment, "BOTTOM", 0, 7)
    label:SetWidth(66)

    segment:SetScript("OnEnter", function()
      if OctoPort.radialEditor then OctoPort:SetRadialSelection(slotIndex) end
    end)
    segment:SetScript("OnClick", function()
      if not OctoPort.radialEditor then return end
      local direction = arg1 == "RightButton" and -1 or 1
      OctoPort:CycleRadialAction(slotIndex, direction)
    end)

    segment.icon = icon
    segment.label = label
    self.radialSegments[index] = segment
  end

  frame:SetScript("OnUpdate", function()
    if OctoPort.radialEditor then return end
    OctoPort:UpdateRadialSelection()
  end)

  self.radialFrame = frame
  self.radialCenterText = centerText
  self.radialCenterHint = centerHint
end

function OctoPort:ShowRadial(editor)
  self:CreateRadial()
  self.radialEditor = editor and true or false
  self.radialFrame:ClearAllPoints()

  if self.radialEditor then
    self.radialFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
    self.radialCenterHint:SetText("STRED / B = HOTOVO")
  else
    local scale = UIParent:GetEffectiveScale()
    if not scale or scale == 0 then scale = 1 end
    local x, y = GetCursorPosition()
    x = x / scale
    y = y / scale
    x = Clamp(x, 170, UIParent:GetWidth() - 170)
    y = Clamp(y, 170, UIParent:GetHeight() - 170)
    self.radialFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
    self.radialCenterHint:SetText("A / PUST MENU")
    self.radialWasOpened = true
  end

  for index = 1, 8 do
    self.radialSegments[index]:EnableMouse(self.radialEditor)
  end

  self:RefreshRadial()
  self:SetRadialSelection(nil)
  self.radialFrame:Show()
  PlaySound("igMainMenuOpen")
end

function OctoPort:HideRadial()
  if self.radialFrame then self.radialFrame:Hide() end
  self.radialEditor = false
  self:SetRadialSelection(nil)
end

function OctoPort:ToggleRadialEditor()
  if self.radialFrame and self.radialFrame:IsVisible() and self.radialEditor then
    self:HideRadial()
    self:Print("Radial menu editor closed.")
  else
    self:ShowRadial(true)
    self:Print("Radial editor: left click moves forward, right click moves back.")
  end
end

function OctoPort:HandleRadialKey(keystate)
  if keystate == "down" then
    if self.radialEditor then
      self:HideRadial()
      self:Print("Radial menu editor closed.")
      return
    end
    self.radialKeyDown = true
    self.radialHoldElapsed = 0
    self.radialWasOpened = false
    self.radialConfirmed = false
    self.radialCancelled = false
    return
  end

  if not self.radialKeyDown then return end
  self.radialKeyDown = false

  if self.radialWasOpened then
    if self.radialFrame and self.radialFrame:IsVisible() then
      if not self.radialConfirmed and not self.radialCancelled then
        self:ActivateRadialSelection()
      end
      self:HideRadial()
    end
  else
    ToggleGameMenu()
  end
end

local radialDriver = CreateFrame("Frame", "OctoPortRadialDriver", UIParent)
radialDriver:SetScript("OnUpdate", function()
  if not OctoPort.radialKeyDown or OctoPort.radialWasOpened then return end
  OctoPort.radialHoldElapsed = (OctoPort.radialHoldElapsed or 0) + arg1
  local threshold = OctoPort.config and OctoPort.config.radialHold or 0.35
  if OctoPort.radialHoldElapsed >= threshold then
    OctoPort:ShowRadial(false)
  end
end)
