-- ================================================================
-- DailyTracker v2.3
-- Auteur : Tibiscui - Kirin Tor
-- Auto-sizing hauteur/largeur robuste + tri par faction
-- ================================================================

local ADDON = "DailyTracker"
DailyTrackerData = DailyTrackerData or {}

DailyTrackerDB = DailyTrackerDB or {
  pos         = {point="CENTER", x=0, y=0},
  open        = false,
  extension   = "Midnight",
  selectedFac = nil,
  sections    = {weekly=true, daily=true, onetime=false},
  groups      = {principale=true, secondaire=true, pvp=false},
  mmAngle     = 220,
  filter      = "all",

}

-- ================================================================
-- DETECTION AUTO
-- ================================================================
local function IsQuestDone(questID)
  if not questID then return false end
  if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then
    return C_QuestLog.IsQuestFlaggedCompleted(questID) == true
  end
  return IsQuestFlaggedCompleted and IsQuestFlaggedCompleted(questID) == true or false
end

-- ================================================================
-- CONSTANTES VISUELLES
-- ================================================================
local TYPE_COLORS = {
  weekly  = {r=0.30, g=0.60, b=1.00},
  onetime = {r=1.00, g=0.82, b=0.00},
  daily   = {r=0.30, g=0.85, b=0.30},
}
local TYPE_LABELS = {
  weekly  = "[Hebdo]",
  onetime = "[Unique]",
  daily   = "[Quotidien]",
}
local EXT_TAB_COLORS = {
  Midnight     = {r=0.58, g=0.30, b=0.95},
  TheWarWithin = {r=0.55, g=0.75, b=0.95},
}
local EXT_LABELS    = {Midnight="MID", TheWarWithin="TWW"}
local EXT_FULLNAMES = {
  Midnight     = "Midnight (12.0)",
  TheWarWithin = "The War Within (11.0)",
}
local EXT_ORDER = {"Midnight","TheWarWithin"}

local CAT_DEFS = {
  {key="principale", label="Factions Principales", col={r=1.00,g=0.82,b=0.00}},
  {key="secondaire", label="Factions Secondaires", col={r=0.30,g=0.70,b=1.00}},
  {key="pvp",        label="PvP",                  col={r=0.95,g=0.30,b=0.30}},
}
local GROUP_DEFAULTS = {principale=true, secondaire=true, pvp=false}

-- ================================================================
-- LAYOUT
-- ================================================================
local TAB_COL_W  = 70
local TAB_H      = 26
local TAB_GAP    = 2
local MARGIN_L   = 14
local MARGIN_R   = 14
local MARGIN_BOT = 18
local CX         = TAB_COL_W + MARGIN_L + 4
-- Hauteurs des zones fixes (depuis le haut de la fenêtre, positives)
local H_TITLE    = 48   -- titre + drag + sep1
local H_FILTER   = 22   -- barre filtre + sep2
local Y_GROUPS   = H_TITLE + H_FILTER + 4  -- où commence la liste factions
local W_MIN = 520 ; local W_MAX = 920
local H_MIN = 350 ; local H_MAX = 980

-- ================================================================
-- HELPERS
-- ================================================================
local function GetActiveFactions(extKey)
  local d = DailyTrackerData and DailyTrackerData[extKey or DailyTrackerDB.extension]
  return d and d.factions or {}
end

local function GetFactionsByCategory(cat, extKey)
  local result = {}
  for _, fac in ipairs(GetActiveFactions(extKey)) do
    if (fac.category or "secondaire") == cat then table.insert(result,fac) end
  end
  table.sort(result, function(a,b) return a.name < b.name end)
  return result
end

local function GetSelectedFac()
  local sf = DailyTrackerDB.selectedFac
  if not sf then return nil, nil end
  return sf.cat, sf.name
end
local function SetSelectedFac(cat, name)
  DailyTrackerDB.selectedFac = {cat=cat, name=name}
end

local function GetFactionQuestStats(fac)
  local total, done = 0, 0
  for _, q in ipairs(fac.quests or {}) do
    if q.type ~= "onetime" then
      total = total + 1
      if IsQuestDone(q.questID) then done = done + 1 end
    end
  end
  return done, total
end

local function GetExtStats(extKey)
  local total, done = 0, 0
  for _, fac in ipairs(GetActiveFactions(extKey)) do
    local d, t = GetFactionQuestStats(fac); done=done+d; total=total+t
  end
  return done, total
end

-- ================================================================
-- FRAME PRINCIPALE
-- ================================================================
local mainFrame

local function BuildUI()

  mainFrame = CreateFrame("Frame","DTMainFrame",UIParent,"BackdropTemplate")
  mainFrame:SetSize(W_MIN, H_MIN)
  mainFrame:SetClipsChildren(false)
  mainFrame:SetFrameStrata("HIGH")
  mainFrame:SetMovable(true)
  mainFrame:EnableMouse(true)
  mainFrame:EnableKeyboard(true)
  mainFrame:SetPropagateKeyboardInput(true)
  mainFrame:RegisterForDrag("LeftButton")
  mainFrame:SetScript("OnDragStart", mainFrame.StartMoving)
  mainFrame:SetScript("OnDragStop", function(s)
    s:StopMovingOrSizing()
    local point,_,_,x,y = s:GetPoint()
    DailyTrackerDB.pos = {point=point,x=x,y=y}
  end)
  mainFrame:SetScript("OnKeyDown", function(self,key)
    if key=="ESCAPE" then self:Hide(); DailyTrackerDB.open=false end
  end)
  mainFrame:SetBackdrop({
    bgFile="Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",
    tile=true,tileSize=32,edgeSize=32,
    insets={left=11,right=12,top=12,bottom=11},
  })
  mainFrame:SetBackdropColor(0.04,0.02,0.06,0.97)
  mainFrame:SetBackdropBorderColor(0.72,0.60,0.28,1.0)

  -- ----------------------------------------------------------
  -- TITRE FLOTTANT
  -- ----------------------------------------------------------
  local titleBg = CreateFrame("Frame",nil,mainFrame,"BackdropTemplate")
  titleBg:SetPoint("TOP",mainFrame,"TOP",0,14)
  titleBg:SetSize(360,44)
  titleBg:SetFrameLevel(mainFrame:GetFrameLevel()+2)
  titleBg:SetBackdrop({
    bgFile="Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",
    tile=true,tileSize=32,edgeSize=20,
    insets={left=7,right=7,top=7,bottom=7},
  })
  titleBg:SetBackdropColor(0.04,0.02,0.06,0.97)
  titleBg:SetBackdropBorderColor(0.72,0.60,0.28,1.0)

  local logoL = titleBg:CreateTexture(nil,"OVERLAY")
  logoL:SetSize(20,20)
  logoL:SetTexture("Interface\\AddOns\\DailyTracker\\medias\\DailyTracker")
  local logoR = titleBg:CreateTexture(nil,"OVERLAY")
  logoR:SetSize(20,20)
  logoR:SetTexture("Interface\\AddOns\\DailyTracker\\medias\\DailyTracker")

  local titleStr = titleBg:CreateFontString(nil,"OVERLAY")
  titleStr:SetFont("Fonts\\FRIZQT__.TTF",12,"OUTLINE")
  titleStr:SetPoint("CENTER",titleBg,"CENTER",0,5)
  titleStr:SetText("|cFFFFD700DailyTracker - |r|cFF9480FFMidnight|r")
  logoL:SetPoint("RIGHT",titleStr,"LEFT",-6,0)
  logoR:SetPoint("LEFT",titleStr,"RIGHT",6,0)
  mainFrame._titleStr = titleStr

  local byLine = titleBg:CreateFontString(nil,"OVERLAY")
  byLine:SetFont("Fonts\\FRIZQT__.TTF",9,"OUTLINE")
  byLine:SetPoint("TOP",titleStr,"BOTTOM",0,0)
  byLine:SetText("|cFFF58CBAby Tibiscui|r")

  local closeBtn = CreateFrame("Button",nil,mainFrame,"UIPanelCloseButton")
  closeBtn:SetPoint("TOPRIGHT",-5,-5)
  closeBtn:SetScript("OnClick",function()
    mainFrame:Hide(); DailyTrackerDB.open=false
  end)

  local drag = mainFrame:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
  drag:SetPoint("TOP",0,-30)
  drag:SetText("|cFF888888Glisser pour déplacer  —  /tdt|r")

  -- Séparateur doré sous titre (H_TITLE - H_FILTER - 4 = 22px depuis le haut)
  local sepTop = mainFrame:CreateTexture(nil,"ARTWORK")
  sepTop:SetTexture("Interface\\BUTTONS\\WHITE8X8")
  sepTop:SetPoint("TOPLEFT",  MARGIN_L, -44)
  sepTop:SetPoint("TOPRIGHT",-MARGIN_R, -44)
  sepTop:SetHeight(1)
  sepTop:SetVertexColor(0.72,0.60,0.28,0.9)

  -- ----------------------------------------------------------
  -- BARRE FILTRES HORIZONTALE  (entre sep haut et contenu)
  -- Alignée avec la zone contenu (CX → bord droit)
  -- ----------------------------------------------------------
  local filterDefs = {
    {key="all",     lbl="Tout",      col={r=0.85,g=0.85,b=0.85}},
    {key="weekly",  lbl="Hebdo",     col={r=0.30,g=0.60,b=1.00}},
    {key="daily",   lbl="Quotidien", col={r=0.30,g=0.85,b=0.30}},
    {key="onetime", lbl="Unique",    col={r=1.00,g=0.82,b=0.00}},
  }

  local filterBarBg = CreateFrame("Frame",nil,mainFrame,"BackdropTemplate")
  filterBarBg:SetPoint("TOPLEFT",  CX,       -46)
  filterBarBg:SetPoint("TOPRIGHT",-MARGIN_R, -46)
  filterBarBg:SetHeight(H_FILTER)
  filterBarBg:SetBackdrop({
    bgFile="Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
    tile=true,tileSize=8,edgeSize=6,
    insets={left=2,right=2,top=2,bottom=2},
  })
  filterBarBg:SetBackdropColor(0.04,0.02,0.08,0.90)
  filterBarBg:SetBackdropBorderColor(0.72,0.60,0.28,0.45)

  local filterBtns = {}
  local fBtnW = 70 ; local fBtnH = H_FILTER-4 ; local fBtnX = 4

  for _, fd in ipairs(filterDefs) do
    local btn = CreateFrame("Button",nil,filterBarBg,"BackdropTemplate")
    btn:SetPoint("LEFT",filterBarBg,"LEFT",fBtnX,0)
    btn:SetSize(fBtnW,fBtnH)
    btn:SetBackdrop({
      bgFile="Interface\\ChatFrame\\ChatFrameBackground",
      edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
      tile=true,tileSize=8,edgeSize=6,
      insets={left=2,right=2,top=2,bottom=2},
    })
    local acc = btn:CreateTexture(nil,"OVERLAY")
    acc:SetPoint("TOPLEFT",   btn,"TOPLEFT",  2,-2)
    acc:SetPoint("BOTTOMLEFT",btn,"BOTTOMLEFT",2, 2)
    acc:SetWidth(3) ; acc:SetTexture("Interface\\BUTTONS\\WHITE8X8")
    acc:SetVertexColor(fd.col.r,fd.col.g,fd.col.b,0.5)
    btn.accent = acc
    local lTxt = btn:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    lTxt:SetPoint("CENTER",btn,"CENTER",2,0)
    lTxt:SetText(string.format("|cFF%02X%02X%02X%s|r",
      math.floor(fd.col.r*255),math.floor(fd.col.g*255),math.floor(fd.col.b*255),fd.lbl))
    btn.col=fd.col ; btn.filterKey=fd.key
    filterBtns[fd.key]=btn
    fBtnX = fBtnX+fBtnW+2
    local capturedKey=fd.key
    btn:SetScript("OnClick",function()
      DailyTrackerDB.filter=capturedKey ; mainFrame:RefreshContent()
    end)
    btn:SetScript("OnEnter",function(s) s:SetBackdropBorderColor(fd.col.r,fd.col.g,fd.col.b,0.9) end)
    btn:SetScript("OnLeave",function(s)
      if DailyTrackerDB.filter~=capturedKey then
        s:SetBackdropBorderColor(fd.col.r*0.35,fd.col.g*0.35,fd.col.b*0.35,0.5) end
    end)
  end
  mainFrame.filterBtns = filterBtns

  -- Séparateur doré sous barre filtre
  local sepFilt = mainFrame:CreateTexture(nil,"ARTWORK")
  sepFilt:SetTexture("Interface\\BUTTONS\\WHITE8X8")
  sepFilt:SetPoint("TOPLEFT",  CX,       -(46+H_FILTER+2))
  sepFilt:SetPoint("TOPRIGHT",-MARGIN_R, -(46+H_FILTER+2))
  sepFilt:SetHeight(1)
  sepFilt:SetVertexColor(0.72,0.60,0.28,0.45)

  -- ----------------------------------------------------------
  -- COLONNE GAUCHE — acronymes seuls
  -- ----------------------------------------------------------
  local tabColBg = CreateFrame("Frame",nil,mainFrame,"BackdropTemplate")
  tabColBg:SetPoint("TOPLEFT",  MARGIN_L,-50)
  tabColBg:SetPoint("BOTTOMLEFT",mainFrame,"BOTTOMLEFT",MARGIN_L,MARGIN_BOT)
  tabColBg:SetWidth(TAB_COL_W)
  tabColBg:SetBackdrop({
    bgFile="Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
    tile=true,tileSize=8,edgeSize=6,
    insets={left=2,right=2,top=2,bottom=2},
  })
  tabColBg:SetBackdropColor(0.02,0.01,0.04,0.85)
  tabColBg:SetBackdropBorderColor(0.72,0.60,0.28,0.35)

  local extBtns = {}
  local extTabStartY = -58

  for idx, extKey in ipairs(EXT_ORDER) do
    local col  = EXT_TAB_COLORS[extKey] or {r=0.5,g=0.5,b=0.5}
    local yOff = extTabStartY-(idx-1)*(TAB_H+TAB_GAP)
    local eb   = CreateFrame("Button",nil,mainFrame,"BackdropTemplate")
    eb:SetPoint("TOPLEFT",MARGIN_L+2,yOff)
    eb:SetSize(TAB_COL_W-4,TAB_H)
    eb:SetBackdrop({
      bgFile="Interface\\ChatFrame\\ChatFrameBackground",
      edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
      tile=true,tileSize=8,edgeSize=6,
      insets={left=2,right=2,top=2,bottom=2},
    })
    eb:SetBackdropColor(col.r*0.12,col.g*0.12,col.b*0.12,0.95)
    eb:SetBackdropBorderColor(col.r*0.35,col.g*0.35,col.b*0.35,0.5)
    local accent = eb:CreateTexture(nil,"OVERLAY")
    accent:SetPoint("TOPLEFT",   eb,"TOPLEFT",  2,-2)
    accent:SetPoint("BOTTOMLEFT",eb,"BOTTOMLEFT",2, 2)
    accent:SetWidth(3) ; accent:SetTexture("Interface\\BUTTONS\\WHITE8X8")
    accent:SetVertexColor(col.r,col.g,col.b,0.5)
    local eTxt = eb:CreateFontString(nil,"OVERLAY","GameFontNormal")
    eTxt:SetPoint("CENTER",eb,"CENTER",2,0)
    eTxt:SetSize(TAB_COL_W-10,TAB_H-4)
    eTxt:SetText(string.format("|cFF%02X%02X%02X%s|r",
      math.floor(col.r*255),math.floor(col.g*255),math.floor(col.b*255),EXT_LABELS[extKey]))
    eTxt:SetWordWrap(false) ; eTxt:SetJustifyH("CENTER")
    eb.accent=accent ; eb.extKey=extKey ; eb.col=col
    local capturedKey=extKey
    eb:SetScript("OnClick",function()
      DailyTrackerDB.extension=capturedKey
      DailyTrackerDB.selectedFac=nil
      mainFrame:RefreshContent()
    end)
    eb:SetScript("OnEnter",function(s)
      GameTooltip:SetOwner(s,"ANCHOR_RIGHT")
      GameTooltip:AddLine(EXT_FULLNAMES[capturedKey],col.r,col.g,col.b)
      local d,t=GetExtStats(capturedKey)
      GameTooltip:AddLine(string.format("Activités : %d / %d",d,t),0.75,0.75,0.75)
      GameTooltip:Show()
    end)
    eb:SetScript("OnLeave",function() GameTooltip:Hide() end)
    table.insert(extBtns,eb)
  end
  mainFrame.extBtns = extBtns

  local sepVert = mainFrame:CreateTexture(nil,"ARTWORK")
  sepVert:SetTexture("Interface\\BUTTONS\\WHITE8X8")
  sepVert:SetPoint("TOPLEFT",   CX-2,-50)
  sepVert:SetPoint("BOTTOMLEFT",CX-2, MARGIN_BOT)
  sepVert:SetWidth(1)
  sepVert:SetVertexColor(0.72,0.60,0.28,0.55)

  -- ----------------------------------------------------------
  -- GROUPES PLIABLES (liste factions, ancrage absolu)
  -- ----------------------------------------------------------
  mainFrame.groupFrames = {}

  -- Retourne le Y absolu de fin des groupes (depuis le haut)
  local function RebuildGroups(startY)
    for _, f in ipairs(mainFrame.groupFrames) do f:Hide() end
    mainFrame.groupFrames = {}
    if not DailyTrackerDB.groups then
      DailyTrackerDB.groups={principale=true,secondaire=true,pvp=false}
    end
    local selCat,selName = GetSelectedFac()
    local curY = startY
    local ROW_H=20 ; local ROW_GAP=1 ; local GH_H=20

    for _, cd in ipairs(CAT_DEFS) do
      local cat      = cd.key
      local factions = GetFactionsByCategory(cat)
      local nbFac    = #factions
      local isOpen   = DailyTrackerDB.groups[cat]
      if isOpen==nil then isOpen=GROUP_DEFAULTS[cat] end
      local col=cd.col
      local r8=math.floor(col.r*255) ; local g8=math.floor(col.g*255) ; local b8=math.floor(col.b*255)

      local gh = CreateFrame("Button",nil,mainFrame,"BackdropTemplate")
      gh:SetPoint("TOPLEFT", CX,       -curY)
      gh:SetPoint("TOPRIGHT",-MARGIN_R,-curY)
      gh:SetHeight(GH_H)
      gh:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=8,edgeSize=6,insets={left=2,right=2,top=2,bottom=2}})
      gh:SetBackdropColor(col.r*0.18,col.g*0.18,col.b*0.18,1.0)
      gh:SetBackdropBorderColor(col.r*0.55,col.g*0.55,col.b*0.55,0.9)
      table.insert(mainFrame.groupFrames,gh)

      local arrow=gh:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
      arrow:SetPoint("LEFT",gh,"LEFT",6,0)
      arrow:SetText(isOpen and "|cFF888888-|r" or "|cFF888888+|r")
      local ghLabel=gh:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
      ghLabel:SetPoint("LEFT",gh,"LEFT",18,0)
      ghLabel:SetText(string.format("|cFF%02X%02X%02X%s|r",r8,g8,b8,cd.label))
      local ghBadge=gh:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
      ghBadge:SetPoint("RIGHT",gh,"RIGHT",-6,0)
      ghBadge:SetText(string.format("|cFF%02X%02X%02X%d|r",r8,g8,b8,nbFac))

      gh:SetScript("OnClick",function()
        DailyTrackerDB.groups[cat]=not DailyTrackerDB.groups[cat]
        mainFrame:RefreshContent()
      end)
      gh:SetScript("OnEnter",function(s) s:SetBackdropBorderColor(col.r,col.g,col.b,1.0) end)
      gh:SetScript("OnLeave",function(s) s:SetBackdropBorderColor(col.r*0.55,col.g*0.55,col.b*0.55,0.9) end)
      curY = curY+GH_H+ROW_GAP

      if isOpen and nbFac>0 then
        for _, fac in ipairs(factions) do
          local isSel=(selCat==cat and selName==fac.name)
          local fDone,fTotal=GetFactionQuestStats(fac)
          local pct=fTotal>0 and (fDone/fTotal) or 0
          local lr,lg,lb
          if pct>=1.0 then lr,lg,lb=0.30,0.90,0.45
          else local fc=fac.color or {r=0.5,g=0.5,b=0.5}; lr,lg,lb=fc.r,fc.g,fc.b end

          local row=CreateFrame("Button",nil,mainFrame,"BackdropTemplate")
          row:SetPoint("TOPLEFT", CX,       -curY)
          row:SetPoint("TOPRIGHT",-MARGIN_R,-curY)
          row:SetHeight(ROW_H)
          row:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=8,edgeSize=5,insets={left=1,right=1,top=1,bottom=1}})
          if isSel then
            row:SetBackdropColor(col.r*0.28,col.g*0.28,col.b*0.28,1.0)
            row:SetBackdropBorderColor(col.r,col.g,col.b,1.0)
          else
            row:SetBackdropColor(col.r*0.06,col.g*0.06,col.b*0.06,0.95)
            row:SetBackdropBorderColor(col.r*0.20,col.g*0.20,col.b*0.20,0.7)
          end
          table.insert(mainFrame.groupFrames,row)

          local dot=row:CreateTexture(nil,"OVERLAY")
          dot:SetPoint("LEFT",row,"LEFT",5,0) ; dot:SetSize(5,5)
          dot:SetTexture("Interface\\BUTTONS\\WHITE8X8")
          dot:SetVertexColor(col.r,col.g,col.b,0.9)

          local nameFS=row:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
          nameFS:SetPoint("LEFT",row,"LEFT",14,0)
          nameFS:SetPoint("RIGHT",row,"RIGHT",-105,0)
          nameFS:SetHeight(ROW_H) ; nameFS:SetJustifyH("LEFT") ; nameFS:SetWordWrap(false)
          local nameCol=isSel
            and string.format("|cFF%02X%02X%02X",r8,g8,b8)
            or  string.format("|cFF%02X%02X%02X",math.floor(col.r*0.72*255),math.floor(col.g*0.72*255),math.floor(col.b*0.72*255))
          nameFS:SetText(nameCol..fac.name.."|r")

          local MBAR_W=56
          local mbarBg=row:CreateTexture(nil,"ARTWORK")
          mbarBg:SetPoint("RIGHT",row,"RIGHT",-44,0) ; mbarBg:SetSize(MBAR_W,5)
          mbarBg:SetTexture("Interface\\BUTTONS\\WHITE8X8") ; mbarBg:SetVertexColor(0.08,0.06,0.12,0.9)
          local mbarFill=row:CreateTexture(nil,"OVERLAY")
          mbarFill:SetPoint("LEFT",mbarBg,"LEFT",0,0) ; mbarFill:SetHeight(5)
          mbarFill:SetWidth(math.max(1,math.floor(MBAR_W*pct)))
          mbarFill:SetTexture("Interface\\BUTTONS\\WHITE8X8") ; mbarFill:SetVertexColor(lr,lg,lb,0.9)

          local lvlFS=row:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
          lvlFS:SetPoint("RIGHT",row,"RIGHT",-4,0) ; lvlFS:SetWidth(38) ; lvlFS:SetJustifyH("RIGHT") ; lvlFS:SetHeight(ROW_H)
          if pct>=1.0 then lvlFS:SetText(string.format("|cFF4DCC72%d/%d|r",fDone,fTotal))
          else lvlFS:SetText(string.format("|cFF%02X%02X%02X%d/%d|r",math.floor(lr*255),math.floor(lg*255),math.floor(lb*255),fDone,fTotal)) end

          local facRef=fac ; local catRef=cat
          row:SetScript("OnClick",function() SetSelectedFac(catRef,facRef.name); mainFrame:RefreshContent() end)
          row:SetScript("OnEnter",function(s)
            s:SetBackdropBorderColor(col.r*0.7,col.g*0.7,col.b*0.7,1.0)
            GameTooltip:SetOwner(s,"ANCHOR_RIGHT")
            GameTooltip:AddLine(facRef.name,col.r,col.g,col.b)
            GameTooltip:AddLine("Zone : "..facRef.zone,0.8,0.8,0.8) ; GameTooltip:Show()
          end)
          row:SetScript("OnLeave",function(s)
            GameTooltip:Hide()
            if not(selCat==catRef and selName==facRef.name) then
              s:SetBackdropBorderColor(col.r*0.20,col.g*0.20,col.b*0.20,0.7) end
          end)
          curY=curY+ROW_H+ROW_GAP
        end
      end
      curY=curY+3
    end

    local sepG=mainFrame:CreateTexture(nil,"ARTWORK")
    sepG:SetTexture("Interface\\BUTTONS\\WHITE8X8")
    sepG:SetPoint("TOPLEFT", CX,       -curY)
    sepG:SetPoint("TOPRIGHT",-MARGIN_R,-curY)
    sepG:SetHeight(1) ; sepG:SetVertexColor(0.72,0.60,0.28,0.9)
    table.insert(mainFrame.groupFrames,sepG)
    return curY+6   -- Y absolu fin des groupes
  end
  mainFrame.RebuildGroups = RebuildGroups

  -- ----------------------------------------------------------
  -- BLOC QUÊTES (éléments créés une fois, repositionnés dynamiquement)
  -- ----------------------------------------------------------
  local questHeader = mainFrame:CreateFontString(nil,"OVERLAY","GameFontNormal")
  mainFrame._questHeader = questHeader

  local legend = mainFrame:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
  mainFrame._legend = legend
  legend:SetText("|cFF4D99FF[Hebdo]|r  |cFFFFCC00[Unique]|r  |cFF4DCC4D[Quotidien]|r")

  -- scrollBg ancré UNIQUEMENT par TOPLEFT + SetSize → resize propre
  local scrollBg = CreateFrame("Frame",nil,mainFrame,"BackdropTemplate")
  scrollBg:SetBackdrop({
    bgFile="Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
    tile=true,tileSize=8,edgeSize=8,
    insets={left=3,right=3,top=3,bottom=3},
  })
  scrollBg:SetBackdropColor(0.02,0.01,0.04,0.5)
  scrollBg:SetBackdropBorderColor(0.5,0.45,0.25,0.5)
  mainFrame.scrollBg = scrollBg

  local questContent = CreateFrame("Frame",nil,scrollBg)
  questContent:SetPoint("TOPLEFT", scrollBg,"TOPLEFT", 6,-6)
  questContent:SetPoint("TOPRIGHT",scrollBg,"TOPRIGHT",-6,-6)
  questContent:SetHeight(40)
  mainFrame.questContent = questContent

  -- ============================================================
  -- REFRESH CONTENT
  -- ============================================================
  mainFrame.RefreshContent = function(self)

    local extKey  = DailyTrackerDB.extension or "Midnight"
    local extCol  = EXT_TAB_COLORS[extKey] or {r=1,g=0.84,b=0}
    local filter  = DailyTrackerDB.filter or "all"

    -- Titre
    self._titleStr:SetText(string.format(
      "|cFFFFD700DailyTracker - |r|cFF%02X%02X%02X%s|r",
      math.floor(extCol.r*255),math.floor(extCol.g*255),math.floor(extCol.b*255),
      EXT_FULLNAMES[extKey] or extKey))

    -- Highlight onglets extension
    for _, eb in ipairs(self.extBtns or {}) do
      local col=eb.col or {r=0.5,g=0.5,b=0.5}
      if eb.extKey==extKey then
        eb:SetBackdropColor(col.r*0.40,col.g*0.40,col.b*0.40,1.0)
        eb:SetBackdropBorderColor(col.r,col.g,col.b,1.0)
        if eb.accent then eb.accent:SetVertexColor(col.r,col.g,col.b,1.0) end
      else
        eb:SetBackdropColor(col.r*0.12,col.g*0.12,col.b*0.12,0.95)
        eb:SetBackdropBorderColor(col.r*0.35,col.g*0.35,col.b*0.35,0.5)
        if eb.accent then eb.accent:SetVertexColor(col.r,col.g,col.b,0.5) end
      end
    end

    -- Highlight filtres
    for key,btn in pairs(self.filterBtns or {}) do
      local col=btn.col or {r=0.5,g=0.5,b=0.5}
      if key==filter then
        btn:SetBackdropColor(col.r*0.30,col.g*0.30,col.b*0.30,1.0)
        btn:SetBackdropBorderColor(col.r,col.g,col.b,1.0)
        if btn.accent then btn.accent:SetVertexColor(col.r,col.g,col.b,1.0) end
      else
        btn:SetBackdropColor(col.r*0.08,col.g*0.08,col.b*0.08,0.9)
        btn:SetBackdropBorderColor(col.r*0.25,col.g*0.25,col.b*0.25,0.5)
        if btn.accent then btn.accent:SetVertexColor(col.r,col.g,col.b,0.4) end
      end
    end

    -- Groupes
    -- startY = Y_GROUPS depuis le haut (absolu positif)
    local groupsEndY = RebuildGroups(Y_GROUPS)

    -- Faction sélectionnée
    local selCat,selName = GetSelectedFac()
    local fac = nil
    if selCat and selName then
      for _, f in ipairs(GetFactionsByCategory(selCat)) do
        if f.name==selName then fac=f; break end
      end
    end
    if not fac then
      for _, cd in ipairs(CAT_DEFS) do
        local list=GetFactionsByCategory(cd.key)
        if #list>0 then fac=list[1]; SetSelectedFac(cd.key,fac.name); break end
      end
    end
    if not fac then return end

    -- Positionnement du bloc quêtes (Y absolu depuis le haut)
    local qHeaderY = groupsEndY + 4
    local qLegendY = qHeaderY + 16
    local qScrollY = qLegendY + 14   -- Y absolu du haut du scrollBg

    self._questHeader:ClearAllPoints()
    self._questHeader:SetPoint("TOPLEFT",CX,-qHeaderY)
    self._questHeader:SetText("|cFFFFD700Activités : |r"..fac.name)

    self._legend:ClearAllPoints()
    self._legend:SetPoint("TOPLEFT",CX,-qLegendY)

    -- --------------------------------------------------------
    -- AUTO-SIZING HORIZONTAL
    -- On mesure le nom le plus long parmi les quêtes visibles
    -- --------------------------------------------------------
    local maxNameLen = 0
    for _, q in ipairs(fac.quests) do
      if (filter=="all" or filter==q.type) and #q.name>maxNameLen then
        maxNameLen=#q.name
      end
    end
    -- 7px/char + overhead (tag+icône+zone+rép+marges)
    local neededW  = CX + maxNameLen*7 + 240
    local newW     = math.max(W_MIN, math.min(W_MAX, neededW))
    self:SetWidth(newW)

    -- Largeur utile du scrollBg
    local sbW = newW - CX - MARGIN_R - 4

    -- Ancrage scrollBg : TOPLEFT seulement + SetSize (évite les conflits)
    self.scrollBg:ClearAllPoints()
    self.scrollBg:SetPoint("TOPLEFT",CX,-qScrollY)
    self.scrollBg:SetWidth(sbW)
    -- hauteur provisoire, sera mise à jour après construction des rows

    local qcW  = sbW - 12   -- 6px inset ×2
    local textW = qcW - 22

    -- --------------------------------------------------------
    -- Construction des lignes de quêtes
    -- --------------------------------------------------------
    for _, c in pairs({self.questContent:GetChildren()}) do c:Hide() end
    for _, r in pairs({self.questContent:GetRegions()})  do r:Hide() end

    -- Collecte des quêtes filtrées
    local questsFiltered = {}
    for _, q in ipairs(fac.quests) do
      if filter=="all" or filter==q.type then
        table.insert(questsFiltered,q)
      end
    end

    local y = 0   -- curseur Y relatif dans questContent (positif, augmente vers le bas)

    local function BuildQuestRow(quest, yOff, facRef)
      local tc   = TYPE_COLORS[quest.type]  or {r=1,g=1,b=1}
      local tlbl = TYPE_LABELS[quest.type]  or ""
      local fc   = (facRef and facRef.color) or {r=0.5,g=0.5,b=0.5}
      local done = IsQuestDone(quest.questID)

      local tipText      = quest.tip or ""
      local charsPerLine = math.max(20, math.floor(textW/7))
      local tipLines     = math.max(1, math.min(math.ceil(#tipText/charsPerLine),6))
      local rowH         = 64 + tipLines*14 + 6

      local row = CreateFrame("Button",nil,self.questContent,"BackdropTemplate")
      row:SetPoint("TOPLEFT",self.questContent,"TOPLEFT",2,-yOff)
      row:SetSize(qcW,rowH)
      row:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=8,edgeSize=6,insets={left=2,right=2,top=2,bottom=2}})
      if done then
        row:SetBackdropColor(0.05,0.05,0.05,0.6)
        row:SetBackdropBorderColor(0.3,0.3,0.3,0.4)
      else
        row:SetBackdropColor(tc.r*0.08,tc.g*0.08,tc.b*0.08,0.95)
        row:SetBackdropBorderColor(tc.r*0.4,tc.g*0.4,tc.b*0.4,0.6)
      end

      local si=row:CreateTexture(nil,"OVERLAY")
      si:SetPoint("TOPLEFT",row,"TOPLEFT",5,-7) ; si:SetSize(12,12)
      if quest.questID then
        if done then si:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready"); si:SetVertexColor(0.3,1.0,0.4,1)
        else si:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady"); si:SetVertexColor(0.7,0.3,0.3,0.7) end
      else si:SetTexture("Interface\\RaidFrame\\ReadyCheck-Waiting"); si:SetVertexColor(0.6,0.6,0.6,0.5) end

      local typeTag=row:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
      typeTag:SetPoint("TOPLEFT",row,"TOPLEFT",22,-6)
      if done then typeTag:SetText("|cFF555566"..tlbl.." ✓|r")
      else typeTag:SetText(string.format("|cFF%02X%02X%02X%s|r",math.floor(tc.r*255),math.floor(tc.g*255),math.floor(tc.b*255),tlbl)) end

      if quest.questID then
        local al=row:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
        al:SetPoint("TOPRIGHT",row,"TOPRIGHT",-6,-6)
        al:SetText(done and "|cFF44AA44✓ Auto|r" or "|cFF555566◌ Auto|r")
      end

      local qName=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
      qName:SetPoint("TOPLEFT",row,"TOPLEFT",22,-18)
      qName:SetSize(textW,16) ; qName:SetJustifyH("LEFT")
      qName:SetText(done and "|cFF888888"..quest.name.."|r" or "|cFFEEEEEE"..quest.name.."|r")

      local npcStr=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
      npcStr:SetPoint("TOPLEFT",row,"TOPLEFT",22,-32)
      npcStr:SetSize(textW,14) ; npcStr:SetJustifyH("LEFT")
      if done then npcStr:SetText("|cFF555555PNJ : "..quest.npc.."  Coord. : "..quest.coords.."|r")
      else npcStr:SetText("|cFF888888PNJ :|r |cFFCCBB88"..quest.npc.."|r  |cFF888888Coord. :|r |cFF99CCFF"..quest.coords.."|r") end

      local repStr=row:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
      repStr:SetPoint("TOPLEFT",row,"TOPLEFT",22,-44)
      repStr:SetSize(textW*0.55,14) ; repStr:SetJustifyH("LEFT")
      if done then repStr:SetText("|cFF555555Rép. : +"..quest.rep.."|r")
      else repStr:SetText(string.format("|cFF888888Rép. :|r |cFF%02X%02X%02X+%d|r",math.floor(fc.r*255),math.floor(fc.g*255),math.floor(fc.b*255),quest.rep or 0)) end

      local zStr=row:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
      zStr:SetPoint("TOPRIGHT",row,"TOPRIGHT",-6,-44) ; zStr:SetJustifyH("RIGHT")
      zStr:SetText(done and "|cFF444455"..quest.zone.."|r" or "|cFF555577"..quest.zone.."|r")

      if tipText~="" then
        local tipStr=row:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
        tipStr:SetPoint("TOPLEFT",row,"TOPLEFT",22,-58)
        tipStr:SetSize(textW,tipLines*14) ; tipStr:SetJustifyH("LEFT") ; tipStr:SetWordWrap(true)
        tipStr:SetText(done and "|cFF444455"..tipText.."|r" or "|cFF777777"..tipText.."|r")
      end

      row:EnableMouse(true)
      row:SetScript("OnEnter",function(s)
        s:SetBackdropBorderColor(tc.r,tc.g,tc.b,done and 0.5 or 0.9)
        GameTooltip:SetOwner(s,"ANCHOR_BOTTOMRIGHT")
        GameTooltip:AddLine(quest.name,1,1,1)
        if quest.questID then
          if done then GameTooltip:AddLine("✓ Complété (ID: "..quest.questID..")",0.3,0.9,0.4)
          else GameTooltip:AddLine("◌ Non complété (ID: "..quest.questID..")",0.8,0.5,0.3) end
        else GameTooltip:AddLine("(Pas de questID — suivi manuel)",0.5,0.5,0.7) end
        GameTooltip:AddLine("Zone : "..quest.zone,0.7,0.7,0.7)
        GameTooltip:AddLine("+"..quest.rep.." rép.",tc.r,tc.g,tc.b)
        if tipText~="" then GameTooltip:AddLine(" "); GameTooltip:AddLine(tipText,0.8,0.8,0.8,true) end
        if quest.mapID and TomTom then GameTooltip:AddLine("|cFFFFD700[Clic] Waypoint TomTom|r") end
        GameTooltip:Show()
      end)
      row:SetScript("OnLeave",function(s)
        GameTooltip:Hide()
        if done then s:SetBackdropBorderColor(0.3,0.3,0.3,0.4)
        else s:SetBackdropBorderColor(tc.r*0.4,tc.g*0.4,tc.b*0.4,0.6) end
      end)
      row:SetScript("OnClick",function()
        if (facRef and facRef.id) and C_Reputation and C_Reputation.SetWatchedFactionByID then
          C_Reputation.SetWatchedFactionByID(facRef.id)
        end
        if quest.coords and quest.mapID and TomTom then
          local x2,y2=quest.coords:match("([%d%.]+),%s*([%d%.]+)")
          if x2 and y2 then
            TomTom:AddWaypoint(quest.mapID,tonumber(x2)/100,tonumber(y2)/100,{title=quest.name,persistent=false})
            print("|cFFFFD700DailyTracker|r Waypoint : "..quest.name)
          end
        end
      end)
      return rowH
    end -- BuildQuestRow

    -- --------------------------------------------------------
    -- TRI PAR TYPE (accordéon Hebdo / Unique / Quotidien)
    -- --------------------------------------------------------
    local groups = {
      {key="weekly",  label="Quêtes hebdomadaires", quests={}},
      {key="onetime", label="Quêtes uniques",        quests={}},
      {key="daily",   label="Quêtes quotidiennes",   quests={}},
    }
    for _, quest in ipairs(questsFiltered) do
      for _, g in ipairs(groups) do
        if quest.type==g.key then table.insert(g.quests,quest) end
      end
    end

    for _, grp in ipairs(groups) do
      if #grp.quests>0 then
        local tc=TYPE_COLORS[grp.key] or {r=1,g=1,b=1}
        local isOpen=DailyTrackerDB.sections[grp.key]
        local grpDone=0
        for _, q in ipairs(grp.quests) do if IsQuestDone(q.questID) then grpDone=grpDone+1 end end
        local allDone=(grpDone==#grp.quests)

        local header=CreateFrame("Button",nil,self.questContent,"BackdropTemplate")
        header:SetPoint("TOPLEFT",self.questContent,"TOPLEFT",2,-y)
        header:SetSize(qcW,26)
        header:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=8,edgeSize=6,insets={left=2,right=2,top=2,bottom=2}})
        if allDone then header:SetBackdropColor(0.05,0.10,0.05,0.95); header:SetBackdropBorderColor(0.3,0.6,0.3,0.7)
        else header:SetBackdropColor(tc.r*0.15,tc.g*0.15,tc.b*0.15,0.95); header:SetBackdropBorderColor(tc.r*0.5,tc.g*0.5,tc.b*0.5,0.7) end

        local aTxt=header:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
        aTxt:SetPoint("LEFT",header,"LEFT",8,0)
        aTxt:SetText(isOpen and "|cFFFFD700-|r" or "|cFF888888+|r")
        local hTxt=header:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
        hTxt:SetPoint("LEFT",header,"LEFT",24,0)
        if allDone then hTxt:SetText(string.format("|cFF4DCC72%s  (%d/%d) ✓|r",grp.label,grpDone,#grp.quests))
        else hTxt:SetText(string.format("|cFF%02X%02X%02X%s|r  |cFF888888(%d/%d)|r",math.floor(tc.r*255),math.floor(tc.g*255),math.floor(tc.b*255),grp.label,grpDone,#grp.quests)) end

        local capturedKey=grp.key
        header:SetScript("OnClick",function()
          DailyTrackerDB.sections[capturedKey]=not DailyTrackerDB.sections[capturedKey]
          mainFrame:RefreshContent()
        end)
        header:SetScript("OnEnter",function(s) s:SetBackdropBorderColor(tc.r,tc.g,tc.b,0.9) end)
        header:SetScript("OnLeave",function(s) s:SetBackdropBorderColor(tc.r*0.5,tc.g*0.5,tc.b*0.5,0.7) end)

        local curRowY=y+28
        for _, quest in ipairs(grp.quests) do
          local rH=BuildQuestRow(quest,curRowY,fac)
          local ch={self.questContent:GetChildren()}
          local lc=ch[#ch]
          if lc and not isOpen then lc:Hide() end
          curRowY=curRowY+rH+2
        end
        if isOpen then y=curRowY+4 else y=y+28+4 end
      end
    end

    -- --------------------------------------------------------
    -- AUTO-SIZING VERTICAL — calcul propre et définitif
    -- questH = hauteur réelle du contenu (y = curseur final)
    -- newH = qScrollY + questH + padding_scrollBg + MARGIN_BOT
    -- --------------------------------------------------------
    local questH = math.max(40, y+12)
    self.questContent:SetHeight(questH)
    self.scrollBg:SetHeight(questH+14)

    -- qScrollY est le Y absolu (depuis le haut) du scrollBg
    -- donc la hauteur totale nécessaire de la fenêtre est :
    local newH = math.max(H_MIN, math.min(H_MAX, qScrollY + questH + 14 + MARGIN_BOT + 4))
    self:SetHeight(newH)

  end -- RefreshContent

  mainFrame:Hide()
end -- BuildUI

-- ================================================================
-- MINIMAP — structure identique à TibiRepTracker
-- ================================================================
local minimapBtn

local function GetMinimapRadius()
  return (Minimap:GetWidth() / 2) + 10
end

local function SetMinimapPos(angle)
  if DailyTrackerDB then DailyTrackerDB.mmAngle = angle end
  local r   = GetMinimapRadius()
  local rad = math.rad(angle)
  minimapBtn:ClearAllPoints()
  minimapBtn:SetPoint(
    "CENTER", Minimap, "CENTER",
    math.cos(rad) * r,
    math.sin(rad) * r
  )
end

local function BuildMinimapButton()

  -- ── Cadre principal ────────────────────────────────────────────
  minimapBtn = CreateFrame("Button", "DTMinimapBtn", Minimap)
  minimapBtn:SetSize(32, 32)
  minimapBtn:SetFrameStrata("MEDIUM")
  minimapBtn:SetFrameLevel(8)
  minimapBtn:SetMovable(false)
  minimapBtn:EnableMouse(true)
  minimapBtn:SetClampedToScreen(true)
  minimapBtn:SetToplevel(true)

  -- ── Couche 1 : icône custom avec mask circulaire (ARTWORK) ─────
  local icon = minimapBtn:CreateTexture(nil, "ARTWORK")
  icon:SetPoint("CENTER", minimapBtn, "CENTER", 0, 0)
  icon:SetSize(24, 24)
  icon:SetTexture("Interface\\AddOns\\DailyTracker\\medias\\DailyTracker")
  -- Mask circulaire Blizzard : coupe les coins pour un rendu parfaitement circulaire
  local mask = minimapBtn:CreateMaskTexture()
  mask:SetAllPoints(icon)
  mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
  icon:AddMaskTexture(mask)

  -- ── Couche 2 : ring doré Blizzard (OVERLAY) ────────────────────
  -- Offset standard DBIcon/Blizzard : TOPLEFT(0, 0) sur SIZE 52×52
  local ring = minimapBtn:CreateTexture(nil, "OVERLAY")
  ring:SetSize(52, 52)
  ring:SetPoint("TOPLEFT", minimapBtn, "TOPLEFT", 0, 0)
  ring:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

  -- ── Couche 3 : highlight circulaire au survol (ARTWORK) ────────
  -- Géré manuellement via OnEnter/OnLeave (les masks ignorent la couche HIGHLIGHT native)
  local hl = minimapBtn:CreateTexture(nil, "ARTWORK")
  hl:SetPoint("CENTER", minimapBtn, "CENTER", 0, 0)
  hl:SetSize(20, 20)
  hl:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask")
  hl:SetVertexColor(1, 1, 1, 0.25)
  hl:SetAlpha(0)  -- caché par défaut
  local hlMask = minimapBtn:CreateMaskTexture()
  hlMask:SetAllPoints(hl)
  hlMask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
  hl:AddMaskTexture(hlMask)
  minimapBtn._hl = hl

  -- ── Position initiale ──────────────────────────────────────────
  local savedAngle = (DailyTrackerDB and DailyTrackerDB.mmAngle) or 220
  SetMinimapPos(savedAngle)

  -- Repositionne si la minimap change de taille (ElvUI, Dominos, etc.)
  minimapBtn:SetScript("OnShow", function()
    SetMinimapPos((DailyTrackerDB and DailyTrackerDB.mmAngle) or 220)
  end)

  -- ── Drag orbital ───────────────────────────────────────────────
  minimapBtn:RegisterForDrag("LeftButton")

  minimapBtn:SetScript("OnDragStart", function(s)
    s:SetScript("OnUpdate", function()
      local mx, my  = Minimap:GetCenter()
      local uiScale = UIParent:GetEffectiveScale()
      local cx, cy  = GetCursorPosition()
      local angle   = math.deg(math.atan2(
        (cy / uiScale) - my,
        (cx / uiScale) - mx
      ))
      SetMinimapPos(angle)
    end)
  end)

  minimapBtn:SetScript("OnDragStop", function(s)
    s:SetScript("OnUpdate", nil)
  end)

  -- ── Recalcul du rayon si la minimap est redimensionnée ─────────
  local resizeWatcher = CreateFrame("Frame")
  resizeWatcher:RegisterEvent("MINIMAP_UPDATE_ZOOM")
  resizeWatcher:SetScript("OnEvent", function()
    SetMinimapPos((DailyTrackerDB and DailyTrackerDB.mmAngle) or 220)
  end)

  -- ── Clic : ouvrir / fermer ─────────────────────────────────────
  minimapBtn:SetScript("OnClick", function(_, button)
    if button == "LeftButton" then
      if mainFrame:IsShown() then
        mainFrame:Hide()
        DailyTrackerDB.open = false
      else
        mainFrame:Show()
        mainFrame:RefreshContent()
        DailyTrackerDB.open = true
      end
    end
  end)

  -- ── Tooltip + highlight ────────────────────────────────────────
  minimapBtn:SetScript("OnEnter", function(s)
    if s._hl then s._hl:SetAlpha(1) end
    local ext = DailyTrackerDB.extension or "Midnight"
    local d, t = GetExtStats(ext)
    GameTooltip:SetOwner(s, "ANCHOR_LEFT")
    GameTooltip:AddLine("|cFF40C7EBDailyTracker|r", 0.58, 0.30, 0.95)
    GameTooltip:AddLine(EXT_FULLNAMES[ext] or ext, 0.9, 0.9, 0.9)
    GameTooltip:AddLine(string.format("Activités : %d / %d", d, t), 0.3, 0.9, 0.5)
    GameTooltip:AddLine(" ", 1, 1, 1)
    GameTooltip:AddLine("|cFFFFD700Clic gauche|r : ouvrir / fermer", 0.7, 0.7, 0.7)
    GameTooltip:AddLine("|cFFFFD700Glisser|r : repositionner l'icône", 0.7, 0.7, 0.7)
    GameTooltip:Show()
  end)

  minimapBtn:SetScript("OnLeave", function(s)
    if s._hl then s._hl:SetAlpha(0) end
    GameTooltip:Hide()
  end)
end

-- ================================================================
-- COMPARTIMENT
-- ================================================================
function DailyTracker_OnAddonCompartmentClick()
  if mainFrame:IsShown() then mainFrame:Hide(); DailyTrackerDB.open=false
  else mainFrame:Show(); mainFrame:RefreshContent(); DailyTrackerDB.open=true end
end
function DailyTracker_OnAddonCompartmentEnter()
  GameTooltip:SetOwner(AddonCompartmentFrame,"ANCHOR_BOTTOMRIGHT")
  GameTooltip:AddLine("|cFFFFD700DailyTracker|r")
  GameTooltip:AddLine("Activités quotidiennes & hebdomadaires",0.8,0.8,0.9) ; GameTooltip:Show()
end
function DailyTracker_OnAddonCompartmentLeave() GameTooltip:Hide() end

-- ================================================================
-- SLASH
-- ================================================================
SLASH_DAILYTRACKER1="/tdt" ; SLASH_DAILYTRACKER2="/tibidaily"
SlashCmdList["DAILYTRACKER"]=function()
  if not mainFrame then return end
  if mainFrame:IsShown() then mainFrame:Hide(); DailyTrackerDB.open=false
  else mainFrame:Show(); mainFrame:RefreshContent(); DailyTrackerDB.open=true end
end

-- ================================================================
-- EVENEMENTS
-- ================================================================
local evFrame=CreateFrame("Frame")
evFrame:RegisterEvent("ADDON_LOADED") ; evFrame:RegisterEvent("PLAYER_LOGIN")
evFrame:RegisterEvent("QUEST_TURNED_IN") ; evFrame:RegisterEvent("QUEST_LOG_UPDATE")
evFrame:RegisterEvent("MAJOR_FACTION_RENOWN_LEVEL_CHANGED") ; evFrame:RegisterEvent("UPDATE_FACTION")
evFrame:RegisterEvent("ZONE_CHANGED") ; evFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
evFrame:RegisterEvent("ZONE_CHANGED_INDOORS")

evFrame:SetScript("OnEvent",function(_,event,arg1)
  if event=="ADDON_LOADED" and arg1==ADDON then
    if not DailyTrackerDB.sections then DailyTrackerDB.sections={weekly=true,daily=true,onetime=false} end
    if not DailyTrackerDB.filter   then DailyTrackerDB.filter="all" end
    if not DailyTrackerDB.groups   then DailyTrackerDB.groups={principale=true,secondaire=true,pvp=false} end

    BuildUI() ; BuildMinimapButton()
    local p=DailyTrackerDB.pos
    if p and p.x then
      mainFrame:ClearAllPoints()
      mainFrame:SetPoint(p.point or "CENTER",UIParent,p.point or "CENTER",p.x,p.y)
    else mainFrame:SetPoint("CENTER",UIParent,"CENTER",0,0) end
    if DailyTrackerDB.open then mainFrame:Show(); mainFrame:RefreshContent() end

  elseif event=="PLAYER_LOGIN" then
    C_Timer.After(2,function()
      print("|cFFFFD700DailyTracker|r v1.0 — |cFFFFD700/tdt|r pour ouvrir.")
      if mainFrame and mainFrame:IsShown() and mainFrame.RefreshContent then mainFrame:RefreshContent() end
    end)

  elseif event=="QUEST_TURNED_IN" or event=="QUEST_LOG_UPDATE" then
    if mainFrame and mainFrame:IsShown() and mainFrame.RefreshContent then
      C_Timer.After(0.3,function() mainFrame:RefreshContent() end)
    end

  elseif event=="MAJOR_FACTION_RENOWN_LEVEL_CHANGED" or event=="UPDATE_FACTION"
      or event=="ZONE_CHANGED" or event=="ZONE_CHANGED_NEW_AREA" or event=="ZONE_CHANGED_INDOORS" then
    if mainFrame and mainFrame:IsShown() and mainFrame.RefreshContent then mainFrame:RefreshContent() end
  end
end)
