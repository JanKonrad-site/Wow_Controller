-- First-run and command help panel.

function OctoPort:CreateHelpPanel()
  if self.helpPanel then return end

  local frame = CreateFrame("Frame", "OctoPortHelpPanel", UIParent)
  frame:SetWidth(610)
  frame:SetHeight(470)
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
  subtitle:SetText("Tri vrstvy = 24 schopnosti bez pousteni pacek")

  local body = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  body:SetPoint("TOPLEFT", frame, "TOPLEFT", 38, -88)
  body:SetWidth(534)
  body:SetJustifyH("LEFT")
  body:SetJustifyV("TOP")
  body:SetText(
    "1. Klikni na NASTAVIT KLAVESY. OctoPort ulozi puvodni vazby a nastavi 1-8, SHIFT+1-8 a CTRL+1-8.\n\n" ..
    "2. V Armoury Crate SE vytvor pro WoW.exe profil v rezimu Desktop. Nastav ABXY na 1-4, D-pad na 5-8, LB na Shift a LT na Ctrl.\n\n" ..
    "3. Pravou packou pohybuj mysi. RB je levy klik, RT pravy klik a otaceni kamery. L3 meni cil, R3 skace.\n\n" ..
    "4. Napis /octoport edit a mysi pretahni schopnosti do vsech tri vrstev. Stejnym prikazem se vrat do herniho rezimu.\n\n" ..
    "Dalsi: F = interakce, R = vsechny batohy, M = mapa, NumLock = automaticky beh. Shift+L3 voli predchoziho nepritele, Ctrl+L3 nejblizsiho spojence."
  )

  local warning = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  warning:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 38, 82)
  warning:SetWidth(534)
  warning:SetJustifyH("LEFT")
  warning:SetText("OctoWoW 1.12.2 nema nativni XInput. Tlacitka proto na klavesy prevadi Armoury Crate SE; addon resi HUD, vrstvy a vazby uvnitr hry.")

  local setup = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  setup:SetWidth(175)
  setup:SetHeight(24)
  setup:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 38, 38)
  setup:SetText("NASTAVIT KLAVESY")
  setup:SetScript("OnClick", function()
    OctoPort:ApplyRecommendedBindings()
  end)

  local edit = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  edit:SetWidth(155)
  edit:SetHeight(24)
  edit:SetPoint("LEFT", setup, "RIGHT", 8, 0)
  edit:SetText("EDITACE LISTEK")
  edit:SetScript("OnClick", function()
    OctoPort.config.editMode = true
    OctoPort:UpdateLayer(true)
    OctoPort.helpPanel:Hide()
  end)

  local close = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  close:SetWidth(105)
  close:SetHeight(24)
  close:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -38, 38)
  close:SetText("ZAVRIT")
  close:SetScript("OnClick", function() OctoPort.helpPanel:Hide() end)

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
