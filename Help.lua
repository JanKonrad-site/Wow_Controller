-- First-run and command help panel.

function OctoPort:CreateHelpPanel()
  if self.helpPanel then return end

  local frame = CreateFrame("Frame", "OctoPortHelpPanel", UIParent)
  frame:SetWidth(610)
  frame:SetHeight(500)
  frame:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
  frame:SetFrameStrata("DIALOG")
  frame:SetClampedToScreen(true)
  frame:EnableMouse(true)
  frame:SetMovable(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", function() this:StartMoving() end)
  frame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
  frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 10, right = 10, top = 10, bottom = 10 },
  })

  local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOP", frame, "TOP", 0, -24)
  title:SetText("WOW CONTROLLER  |  OVLADANI PRO OCTOWOW")
  title:SetTextColor(0.24, 0.84, 0.81)

  local subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  subtitle:SetPoint("TOP", title, "BOTTOM", 0, -8)
  subtitle:SetText("D-pad cile  |  12 schopnosti  |  editovatelne radialni menu")

  local body = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  body:SetPoint("TOPLEFT", frame, "TOPLEFT", 38, -88)
  body:SetWidth(534)
  body:SetJustifyH("LEFT")
  body:SetJustifyV("TOP")
  body:SetText(
    "1. Klikni na NASTAVIT KLAVESY. WOW Controller zazalohuje puvodni vazby a pouzije vlastni nekolidujici klavesy.\n\n" ..
    "2. V Armoury Crate nastav ABXY na F9-F12, D-pad na sipky, LB na Shift, LT na Ctrl a tlacitko Menu na F8. A uz nesmi posilat Enter - chat je v radialnim menu.\n\n" ..
    "3. D-pad nahoru/dolu prepina pratele a vlevo/vpravo nepritele. A potvrzuje dialog nebo pouzije prvni schopnost, B se vraci nebo pouzije druhou. X a Y jsou dalsi schopnosti.\n\n" ..
    "4. Podrz Menu, pravou packou vyber polozku a pust Menu nebo stiskni A. Tlacitkem KOLO EDIT upravis vsech osm pozic.\n\n" ..
    "5. Auto quest prijme zobrazeny quest. Kdyz si ho chces precist, drz pri otevreni LB. Auto target doplni nejblizsiho nepritele jen tehdy, kdyz nemas zadny zivy cil."
  )

  local warning = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  warning:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 38, 108)
  warning:SetWidth(534)
  warning:SetJustifyH("LEFT")
  warning:SetText("OctoWoW 1.12.2 nema nativni XInput. Armoury Crate musi posilat uvedene klavesy; addon pak resi kontext, HUD, cile, questy a radialni menu.")

  local setup = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  setup:SetWidth(145)
  setup:SetHeight(24)
  setup:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 38, 38)
  setup:SetText("NASTAVIT KLAVESY")
  setup:SetScript("OnClick", function()
    OctoPort:ApplyRecommendedBindings()
  end)

  local edit = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  edit:SetWidth(115)
  edit:SetHeight(24)
  edit:SetPoint("LEFT", setup, "RIGHT", 8, 0)
  edit:SetText("LISTY EDIT")
  edit:SetScript("OnClick", function()
    OctoPort.config.editMode = true
    OctoPort:UpdateLayer(true)
    OctoPort.helpPanel:Hide()
  end)

  local wheel = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  wheel:SetWidth(115)
  wheel:SetHeight(24)
  wheel:SetPoint("LEFT", edit, "RIGHT", 8, 0)
  wheel:SetText("KOLO EDIT")
  wheel:SetScript("OnClick", function()
    OctoPort.helpPanel:Hide()
    OctoPort:ToggleRadialEditor()
  end)

  local close = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  close:SetWidth(85)
  close:SetHeight(24)
  close:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -38, 38)
  close:SetText("ZAVRIT")
  close:SetScript("OnClick", function() OctoPort.helpPanel:Hide() end)

  local autoTarget = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  autoTarget:SetWidth(145)
  autoTarget:SetHeight(22)
  autoTarget:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 38, 69)
  autoTarget:SetScript("OnClick", function()
    OctoPort.config.autoTarget = not OctoPort.config.autoTarget
    this:SetText(OctoPort.config.autoTarget and "AUTO TARGET: ON" or "AUTO TARGET: OFF")
  end)

  local autoQuest = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  autoQuest:SetWidth(145)
  autoQuest:SetHeight(22)
  autoQuest:SetPoint("LEFT", autoTarget, "RIGHT", 8, 0)
  autoQuest:SetScript("OnClick", function()
    OctoPort.config.autoAcceptQuests = not OctoPort.config.autoAcceptQuests
    this:SetText(OctoPort.config.autoAcceptQuests and "AUTO QUEST: ON" or "AUTO QUEST: OFF")
  end)

  frame:SetScript("OnShow", function()
    autoTarget:SetText(OctoPort.config.autoTarget and "AUTO TARGET: ON" or "AUTO TARGET: OFF")
    autoQuest:SetText(OctoPort.config.autoAcceptQuests and "AUTO QUEST: ON" or "AUTO QUEST: OFF")
  end)

  self.helpPanel = frame
  frame:Hide()
end

function OctoPort:ToggleHelp(forceOpen)
  self:CreateHelpPanel()
  if forceOpen or not self.helpPanel:IsVisible() then
    self.helpPanel:Show()
  else
    self.helpPanel:Hide()
  end
end
