--[[
 _                                   _                             
( )                                 ( )                            
| |       _ _   ___    __   _ __    | |     _   _        
| |  _  /'_` )/',__) /'__`\( '__)   | |  _ ( ) ( )(`\/')  
| |_( )( (_| |\__, \(  ___/| |      | |_( )| (_) | >  <            
(____/'`\__,_)(____/`\____)(_)      (____/'`\___/'(_/\_)     

Changelog: 
	1.05:
		-Fix bug with packet cast
	1.04:
		-Add VPrediction for free user
	1.03
		-Fixed bug auto ulti
		-Added auto ulti if killable
		-Added toggle to turn-off auto pop E(hot-key: T)
	1.02
		-Combo now will use Q,AA,E,AA if possible
		-Steal blue now will use Q/E if killable and when in range instead of only use ultimate:
		-Add auto use R on stun target, will use R on  stunned/immobilized/rooted/snared/suppressed target if there are > 0 amount of your ally are near(include you) or killable target
		-Change 'auto use R if can hit x enemy' to only use if  > 0 amount of your ally are near(include you) or killable target.
		-Fixed bug with auto ignite.
		-Fixed auto pop E feature sometimes doesn't pop when enemy in range.
	1.01:
		-Added Jungle Steal feature
		-Add auto use Ultimate if can hit x enemy around
	1.00:
		-Release
--]]
local currVersion = "1.05"
_G.Lux_Autoupdate = true

if myHero.charName ~= "Lux" then return end

--{ Auto Update


local REQUIRED_LIBS = {}
if VIP_USER then
	REQUIRED_LIBS = {
		["SOW"] = "https://raw.githubusercontent.com/Hellsing/BoL/master/common/SOW.lua",
		["VPrediction"] = "https://raw.githubusercontent.com/Hellsing/BoL/master/common/VPrediction.lua",
		["Collision"] = "https://bitbucket.org/Klokje/public-klokjes-bol-scripts/raw/b891699e739f77f77fd428e74dec00b2a692fdef/Common/Collision.lua",
		["Selector"] = "https://raw.githubusercontent.com/pqmailer/BoL_Scripts/master/Paid/Selector.lua",
		["Prodiction"] = "https://bitbucket.org/Klokje/public-klokjes-bol-scripts/raw/master/Common/Prodiction.lua"
	}
else
	REQUIRED_LIBS = {
		["SOW"] = "https://raw.githubusercontent.com/Hellsing/BoL/master/common/SOW.lua",
		["VPrediction"] = "https://raw.githubusercontent.com/Hellsing/BoL/master/common/VPrediction.lua",
		["Selector"] = "https://raw.githubusercontent.com/pqmailer/BoL_Scripts/master/Paid/Selector.lua"
	}
end

local DOWNLOADING_LIBS, DOWNLOAD_COUNT = false, 0

function AfterDownload()
	DOWNLOAD_COUNT = DOWNLOAD_COUNT - 1
	if DOWNLOAD_COUNT == 0 then
		DOWNLOADING_LIBS = false
		print("<b><font color=\"#FF0000\">Laser Lux - Illuminate the Enemy:</font></b> <font color=\"#FFFFFF\">Required libraries downloaded successfully, please reload (double F9).</font>")
	end
end

for DOWNLOAD_LIB_NAME, DOWNLOAD_LIB_URL in pairs(REQUIRED_LIBS) do
	if FileExist(LIB_PATH .. DOWNLOAD_LIB_NAME .. ".lua") then
		require(DOWNLOAD_LIB_NAME)
	else
		DOWNLOADING_LIBS = true
		DOWNLOAD_COUNT = DOWNLOAD_COUNT + 1
		DownloadFile(DOWNLOAD_LIB_URL, LIB_PATH .. DOWNLOAD_LIB_NAME..".lua", AfterDownload)
	end
end

if DOWNLOADING_LIBS then return end

local UPDATE_NAME = "Laser Lux - Illuminate the Enemy"
local UPDATE_HOST = "raw.github.com"
local UPDATE_PATH = "/LazerBoL/BoL/master/Laser%20Lux%20-%20Illuminate%20the%20Enemy.lua"
local UPDATE_FILE_PATH = SCRIPT_PATH..UPDATE_NAME..".lua"
local UPDATE_URL = "http://"..UPDATE_HOST..UPDATE_PATH

function AutoupdaterMsg(msg) print("<b><font color=\"#FF0000\">"..UPDATE_NAME..":</font></b> <font color=\"#FFFFFF\">"..msg..".</font>") end
if _G.Lux_Autoupdate then
	local ServerData = GetWebResult(UPDATE_HOST, UPDATE_PATH)
	if ServerData then
		local ServerVersion = string.match(ServerData, "local currVersion = \"%d+.%d+\"")
		ServerVersion = string.match(ServerVersion and ServerVersion or "", "%d+.%d+")
		if ServerVersion then
			ServerVersion = tonumber(ServerVersion)
			if tonumber(currVersion) < ServerVersion then
				AutoupdaterMsg("New version available"..ServerVersion)
				AutoupdaterMsg("Updating, please don't press F9")
				DownloadFile(UPDATE_URL, UPDATE_FILE_PATH, function () AutoupdaterMsg("Successfully updated. ("..currVersion.." => "..ServerVersion.."), press F9 twice to load the updated version.") end)	 
			else
				AutoupdaterMsg("You have got the latest version ("..ServerVersion..")")
			end
		end
	else
		AutoupdaterMsg("Error downloading version info")
	end
end
--}

function LuxData()
	objE = nil
	objQ = nil
	Recalling = false
	QCasting = 0
	Spell = {
		Q = {range = 1300, delay = 0.25, speed = 1200, width = 80},
		W = {range = 1175, delay = 0.25, speed = 1400, width = 110},
		E = {range = 1100, delay = 0.25, speed = 1300,  width = 275},
		R = {range = 3340, delay = 1.35, speed = math.huge, width = 190}
	}
	MaxEQ = {1,3,2,3,3,4,3,1,3,1,4,1,1,2,2,4,2,2}
	IgniteSlot = ((myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") and SUMMONER_1) or (myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") and SUMMONER_2) or nil)
end
function OnLoad()
	--{ Variables
	LuxData()
	myHero = GetMyHero()
	
	-- Orbwalk & VPrediction
	VP = VPrediction()
	OW = SOW(VP)
	
	Selector.Instance()
	-- Target Selector
	if VIP_USER then
		-- Collision
		Col = Collision(Spell.Q.range,Spell.Q.speed,Spell.Q.delay,Spell.Q.width)
	end
	ts = TargetSelector(TARGET_LESS_CAST,1250,DAMAGE_MAGIC,false)
	ts.name = "AllClass TS"
	
	-- Minion & Jungle Mob
	EnemyMinion = minionManager(MINION_ENEMY,Spell.Q.range,myHero,MINION_SORT_HEALTH_ASC)
	JungMinion = minionManager(MINION_JUNGLE, Spell.Q.range, myHero, MINION_SORT_MAXHEALTH_DEC)
	StealMinion = minionManager(MINION_JUNGLE,Spell.R.range,myHero,MINION_SORT_HEALTH_ASC)
	--}
	
	--{ Create Menu
	Menu = scriptConfig("Laser Lux","LaserLux")
		--{ Script Information
		Menu:addSubMenu("[ Lux : Script Information]","Script")
		Menu.Script:addParam("Author","Author: Lazer",SCRIPT_PARAM_INFO,"")
		Menu.Script:addParam("Credits","Credits: Pain,ViceVersa,shagratt, Klokje,",SCRIPT_PARAM_INFO,"")
		Menu.Script:addParam("Credits1","honda7,Bilbao,turtlebot,Vadash,barasia283",SCRIPT_PARAM_INFO,"")
		Menu.Script:addParam("Version","Version: " .. currVersion,SCRIPT_PARAM_INFO,"")
		--}
		
		--{ General/Key Bindings
		Menu:addSubMenu("[ Lux : General ]","General")
		Menu.General:addParam("Combo","Combo",SCRIPT_PARAM_ONKEYDOWN,false,32)
		Menu.General:addParam("Harass","Harass",SCRIPT_PARAM_ONKEYDOWN,false,string.byte("C"))
		Menu.General:addParam("Shield","Manual Shield",SCRIPT_PARAM_ONKEYDOWN,false,string.byte("X"))
		Menu.General:addParam("Farm","Farm/Jungle",SCRIPT_PARAM_ONKEYDOWN,false,string.byte("V"))
		Menu.General:addParam("Steal1","Steal press",SCRIPT_PARAM_ONKEYDOWN,false,string.byte("Z"))
		Menu.General:addParam("Steal2","Steal toggle",SCRIPT_PARAM_ONKEYTOGGLE,false,string.byte("N"))
		Menu.General:addParam("toggleE","Turn off auto E",SCRIPT_PARAM_ONKEYTOGGLE,false,string.byte("T"))
		--}
		
		--{ Target Selector
		Menu:addSubMenu("[ Lux : Target Selector ]","TS")
		Menu.TS:addParam("TS","Target Selector",SCRIPT_PARAM_LIST,1,{"AllClass","SAC: Reborn","MMA","Selector"})
		Menu.TS:addTS(ts)
		--}
		
		--{ Orbwalking
		Menu:addSubMenu("[ Lux : Orbwalking ]","Orbwalking")
		OW:LoadToMenu(Menu.Orbwalking)
		--}
		
		--{ Combo Settings
		Menu:addSubMenu("[ Lux : Combo ]","Combo")
		Menu.Combo:addParam("Q","Use Q in combo",SCRIPT_PARAM_ONOFF,true)
		Menu.Combo:addParam("E","Use E in combo",SCRIPT_PARAM_ONOFF,true)
		Menu.Combo:addParam("I","Use item in combo",SCRIPT_PARAM_ONOFF,true)
		
		Menu.Combo:addSubMenu("Q - LightBinding Settings","Lig")
		Menu.Combo.Lig:addParam("Near","Auto Q when enemy is near",SCRIPT_PARAM_ONOFF,true)
		Menu.Combo:addSubMenu("R - Ultimate Settings","Ult")
		Menu.Combo.Ult:addParam("R","Cast Ultimate mode",SCRIPT_PARAM_LIST,1,{"Killable enemy","Combo","Always Use","None"})
		Menu.Combo.Ult:addParam("AutoR","Auto use R if can hit",SCRIPT_PARAM_LIST,3,{"None",">0 targets",">1 targets",">2 targets",">3 targets",">4 targets"})
		Menu.Combo.Ult:addParam("AutoRStun","Auto use R on stun target",SCRIPT_PARAM_ONOFF,true)
		Menu.Combo.Ult:addParam("AutoRKill","Auto use R if killable",SCRIPT_PARAM_ONOFF,true)
		--}
		
		--{ Harass Settings
		Menu:addSubMenu("[ Lux : Harass ]","Harass")
		Menu.Harass:addParam("Q","Use Q in 'Harass'",SCRIPT_PARAM_ONOFF,true)
		Menu.Harass:addParam("E","Use E in 'Harass'",SCRIPT_PARAM_ONOFF,false)
		--}
		
		--{ Jungle/Farm Settings
		Menu:addSubMenu("[ Lux : Farm/Jungle Settings ]","Farm")
		Menu.Farm:addParam("Q","Use Q to 'Farm/Jungle'",SCRIPT_PARAM_ONOFF,true)
		Menu.Farm:addParam("E","Use E to 'Farm/Jungle'",SCRIPT_PARAM_ONOFF,true)
		Menu.Farm:addParam("Mana","Don't farm if mana < %",SCRIPT_PARAM_SLICE,20,0,100)
		Menu.Farm:addSubMenu("Steal with skill","Steal")
		Menu.Farm.Steal:addParam("important","Baron/Dragon steal",SCRIPT_PARAM_ONOFF,true)
		Menu.Farm.Steal:addParam("blue","steal blue buff",SCRIPT_PARAM_ONOFF,false)
		Menu.Farm.Steal:addParam("red","steal red buff",SCRIPT_PARAM_ONOFF,false)
		--}
		
		--{ Shield Settings
		Menu:addSubMenu("[ Lux : Shield]","Shield")
		Menu.Shield:addParam("G","[Global Settings]",SCRIPT_PARAM_INFO,"")
		Menu.Shield:addParam("GAlly","    Ally To Shield",SCRIPT_PARAM_LIST,1,{"Lowest Ally","Ally Near Mouse","Prioritized Ally"})
		Menu.Shield:addSubMenu("Shield: Priority Menu","Priority")
		for i = 1, heroManager.iCount do
			local hero = heroManager:GetHero(i)
			if hero.team == myHero.team then
				Menu.Shield.Priority:addParam(hero.charName,hero.charName,SCRIPT_PARAM_SLICE,1,1,5,0)
			end
		end
		Menu.Shield:addParam("A","[Automation Settings ]",SCRIPT_PARAM_INFO,"")
		Menu.Shield:addParam("Auto","    Automatically Shield Allies",SCRIPT_PARAM_ONOFF,true)
		Menu.Shield:addParam("At","    Automatically Shield when lux is targeted",SCRIPT_PARAM_ONOFF,true)
		Menu.Shield:addParam("Amh","    Minium Health Percentage to shield",SCRIPT_PARAM_SLICE,40,0,100,0)
		Menu.Shield:addParam("Amn","    Minium Mana Percentage to shield",SCRIPT_PARAM_SLICE,40,0,100,0)
		Menu.Shield:addParam("M","[Manual Settings]",SCRIPT_PARAM_INFO,"")
		Menu.Shield:addParam("Mmh","    Minium Health Percentage to shield",SCRIPT_PARAM_SLICE,40,0,100,0)
		Menu.Shield:addParam("Mmn","    Minium Mana Percentage to shield",SCRIPT_PARAM_SLICE,40,0,100,0)
		--}
		
		--{ Draw Settings
		Menu:addSubMenu("[ Lux : Draw ]","Draw")
		Menu.Draw:addSubMenu("Skill Info","Skill")
		
		Menu.Draw.Skill:addParam("QRange","Draw Q range",SCRIPT_PARAM_ONOFF,true)
		Menu.Draw.Skill:addParam("QColor","Set Q color",SCRIPT_PARAM_COLOR,{255,255,0,0})
		Menu.Draw.Skill:addParam("WInfo","---------------------------------",SCRIPT_PARAM_INFO,"")
		Menu.Draw.Skill:addParam("WRange","Draw W range",SCRIPT_PARAM_ONOFF,true)
		Menu.Draw.Skill:addParam("WColor","Set W color",SCRIPT_PARAM_COLOR,{255,255,255,0})
		Menu.Draw.Skill:addParam("EInfo","---------------------------------",SCRIPT_PARAM_INFO,"")
		Menu.Draw.Skill:addParam("ERange","Draw E range",SCRIPT_PARAM_ONOFF,true)
		Menu.Draw.Skill:addParam("EColor","Set E color",SCRIPT_PARAM_COLOR,{255,0,255,0})
		Menu.Draw.Skill:addParam("RInfo","---------------------------------",SCRIPT_PARAM_INFO,"")
		Menu.Draw.Skill:addParam("RRange","Draw R range",SCRIPT_PARAM_ONOFF,true)
		Menu.Draw.Skill:addParam("RColor","Set R color",SCRIPT_PARAM_COLOR,{255,0,255,255})
		Menu.Draw.Skill:addParam("RKill","Draw Ultimate kill",SCRIPT_PARAM_ONOFF,true)
		
		Menu.Draw:addParam("KillText","Draw Killable Text",SCRIPT_PARAM_ONOFF,true)
		Menu.Draw:addParam("LFC","Use Lag free circle",SCRIPT_PARAM_ONOFF,true)
		--}
		
		--{ Extra Settings
		Menu:addSubMenu("[ Lux : Extra Settings ]","Extra")
		Menu.Extra:addParam("AutoI","Auto Ignite on killable enemy",SCRIPT_PARAM_ONOFF,true)
		Menu.Extra:addParam("PopE","Auto pop E when enemy in range",SCRIPT_PARAM_ONOFF,true)
		if VIP_USER then
			Menu.Extra:addParam("Packet","Use Packet to cast spell",SCRIPT_PARAM_ONOFF,false)
		end
		
		Menu.Extra:addParam("AutoLevel","Auto Level Sequence",SCRIPT_PARAM_LIST,1,{"None","Max E,Q"})
		--}
		
		--{ Prediction Mode
		Menu:addSubMenu("[ Lux : Prediction Setting ]","Predict")
		if VIP_USER then
			Menu.Predict:addParam("G","[General Prediction Settings]",SCRIPT_PARAM_INFO,"")
			Menu.Predict:addParam("Mode","    Prediction Mode",SCRIPT_PARAM_LIST,1,{"VPrediction","Prodiction","VIP Prediction"})
			Menu.Predict:addParam("D","[Detail Prediction Settings]",SCRIPT_PARAM_INFO,"")
			Menu.Predict:addParam("VPHitChance","    VPrediction HitChance",SCRIPT_PARAM_LIST,3,{"[0]Target Position","[1]Low Hitchance","[2]High Hitchance","[3]Target slowed/close","[4]Target immobile","[5]Target Dashing"})
			Menu.Predict:addParam("VIPHitChance","    VIP HitChance: ",SCRIPT_PARAM_SLICE,0.7,0.1,1,2)
		else
			Menu.Predict:addParam("G","[General Prediction Settings]",SCRIPT_PARAM_INFO,"")
			Menu.Predict:addParam("Mode","    Prediction Mode",SCRIPT_PARAM_LIST,1,{"VPrediction","Free Prediction"})
			Menu.Predict:addParam("D","[Detail Prediction Settings]",SCRIPT_PARAM_INFO,"")
			Menu.Predict:addParam("VPHitChance","    VPrediction HitChance",SCRIPT_PARAM_LIST,3,{"[0]Target Position","[1]Low Hitchance","[2]High Hitchance","[3]Target slowed/close","[4]Target immobile","[5]Target Dashing"})
		end
		--}
		
		--{ Perma Show
		Menu.Script:permaShow("Author")
		Menu.General:permaShow("Combo")
		Menu.Combo.Ult:permaShow("R")
		if VIP_USER then
		Menu.Combo.Ult:permaShow("AutoR")
		end
		Menu.General:permaShow("Harass")
		Menu.General:permaShow("Shield")
		Menu.General:permaShow("Farm")
		Menu.General:permaShow("Steal1")
		Menu.General:permaShow("Steal2")
		Menu.General:permaShow("toggleE")
		Menu.Draw.Skill:permaShow("EInfo")
		Menu.Predict:permaShow("Mode")
		Menu.Extra:permaShow("PopE")
		Menu.Extra:permaShow("AutoLevel")
		Menu.Shield:permaShow("Auto")
		--}
		
		-- { Other Prediction
	if VIP_USER then
		Prodiction = ProdictManager.GetInstance()
		ProdictQ = Prodiction:AddProdictionObject(_Q,Spell.Q.range,Spell.Q.speed,Spell.Q.delay,Spell.Q.width)
		ProdictW = Prodiction:AddProdictionObject(_W,Spell.W.range,Spell.W.speed,Spell.W.delay,Spell.W.width)
		ProdictE = Prodiction:AddProdictionObject(_E,Spell.E.range,Spell.E.speed,Spell.E.delay,Spell.E.width)
		ProdictR = Prodiction:AddProdictionObject(_R,Spell.R.range,Spell.R.speed,Spell.R.delay,Spell.R.width)
		
		VipPredictQ = TargetPredictionVIP(Spell.Q.range,Spell.Q.speed,Spell.Q.delay,Spell.Q.width)
		VipPredictW = TargetPredictionVIP(Spell.W.range,Spell.W.speed,Spell.W.delay,Spell.W.width)
		VipPredictE = TargetPredictionVIP(Spell.E.range,Spell.E.speed,Spell.E.delay,Spell.E.width)
	VipPredictR = TargetPredictionVIP(Spell.R.range,Spell.R.speed,Spell.R.delay,Spell.R.width)
	end
	FreePredictQ = TargetPrediction(Spell.Q.range,Spell.Q.speed/1000,Spell.Q.delay*1000,Spell.Q.width)
	FreePredictW = TargetPrediction(Spell.W.range,Spell.W.speed/1000,Spell.W.delay*1000,Spell.W.width)
	FreePredictE = TargetPrediction(Spell.E.range,Spell.E.speed/1000,Spell.E.delay*1000,Spell.E.width)
	FreePredictR = TargetPrediction(Spell.R.range,Spell.R.speed/1000,Spell.R.delay*1000,Spell.R.width)

	--}
		
		--{ Print
		PrintChat("<font color='#ff0000'>L</font><font color='#ffc000'>a</font><font color='#ffff00'>s</font><font color='#3fff00'>e</font><font color='#00ff00'>r</font><font color='#00ffc0'> </font><font color='#00ffff'>L</font><font color='#00C0ff'>u</font><font color='#0000ff'>x</font><font color='#3f00ff'> </font><font color='#ff00ff'>L</font><font color='#ff00c0'>o</font><font color='#ff0000'>a</font><font color='#ffC000'>d</font><font color='#ffff00'>e</font><font color='#3fff00'>d</font><font color='#ffffff'> - You are using version ".. currVersion .. "</font>")
		--}
	--}
end

--{ Enemy in range of myHero
function CountEnemyInRange(target,range)
	local count = 0
	for i = 1, heroManager.iCount do
		local hero = heroManager:GetHero(i)
		if hero.team ~= myHero.team and hero.visible and not hero.dead and GetDistanceSqr(target,hero) <= range*range then
			count = count + 1
		end
	end
	return count
end
-- Allies in range
function CountAllyInRange(target,range)
	local count = 0
	for i = 1, heroManager.iCount do
		local hero = heroManager:GetHero(i)
		if hero.team == myHero.team and hero.visible and not hero.dead and GetDistanceSqr(target,hero) <= range*range then
			count = count + 1
		end
	end
	return count
end
--}

--{ Target Selector
function GrabTarget()
	if  _G.Selector_Enabled and Menu.TS.TS == 4 then
		return Selector.GetTarget(SelectorMenu.Get().mode, nil, {distance = MaxRange()})
	elseif _G.MMA_Loaded and Menu.TS.TS == 3 then
		return _G.MMA_ConsideredTarget(MaxRange())		
	elseif _G.AutoCarry and Menu.TS.TS == 2 then
		return _G.AutoCarry.Crosshair:GetTarget()
	else
		ts.range = MaxRange()
		ts:update()
		return ts.target
	end
end
function MaxRange()
	if QREADY then
		return Spell.Q.range
	elseif EREADY then
		return Spell.E.range
	else
		return myHero.range + 50
	end
end
--}


--{ Ally Selector
function GrabAlly(range)
	if Menu.Shield.GAlly == 1 then
		return LowestAlly(range)
	elseif Menu.Shield.GAlly == 2 then
		return NearMouseAlly(range)
	elseif Menu.Shield.GAlly == 3 then
		return PrioritizedAlly(range)
	end
end
function LowestAlly(range)
	for i = 1, heroManager.iCount do
		hero = heroManager:GetHero(i)
		if hero ~= nil and hero.team == myHero.team and not hero.dead and GetDistance(myHero,hero) <= range then
			if heroTarget == nil then
				heroTarget = hero
			elseif hero.health/hero.maxHealth < heroTarget.health/heroTarget.maxHealth then
				heroTarget = hero
			end
		end
	end
	return heroTarget
end
function NearMouseAlly(range)
	for i = 1, heroManager.iCount do
		hero = heroManager:GetHero(i)
		if hero.team == myHero.team and not hero.dead and GetDistance(myHero,hero) <= range then
			if heroTarget == nil then
				heroTarget = hero
			elseif GetDistance(myHero,hero) < GetDistance(myHero,heroTarget) then
				heroTarget = hero
			end
		end
	end
	return heroTarget
end
function PrioritizedAlly(range)
	for i = 1, heroManager.iCount do
		hero = heroManager:GetHero(i)
		if hero.team == myHero.team and not hero.dead and GetDistance(myHero,hero) <= range then
			if heroTarget == nil then
				heroTarget = hero
			elseif Menu.Shield.Priority[hero.charName] < Menu.Shield.Priority[heroTarget] then
				heroTarget = hero
			end
		end
	end
	return heroTarget
end
--}

--{ Prediction Cast
function SpellCast(spellSlot,castPosition)
	if VIP_USER and Menu.Extra.Packet then
		Packet("S_CAST", {spellId = spellSlot, fromX = castPosition.x, fromY = castPosition.z, toX = castPosition.x, toY = castPosition.z}):send()
	else
		CastSpell(spellSlot,castPosition.x,castPosition.z)
	end
end


function QLineCast(unit)
	if VIP_USER then
		local isCol,ColTable = Col:GetCollision(myHero,unit)
		if #ColTable <= 1 then
			-- VPrediction
			if Menu.Predict.Mode == 1 then
				local CastPosition,HitChance,Position = VP:GetLineCastPosition(unit, Spell.Q.delay, Spell.Q.width, Spell.Q.range, Spell.Q.speed,myHero)
				if CastPosition ~= nil and HitChance >= (Menu.Predict.VPHitChance - 1) then
					SpellCast(_Q,CastPosition)
				end
				
			-- Prodiction
			elseif Menu.Predict.Mode == 2 then
				local CastPosition = ProdictQ:GetPrediction(unit)
				if CastPosition ~= nil then
					SpellCast(_Q,CastPosition)
				end
				
			-- VIP Prediction
			elseif Menu.Predict.Mode == 3 then
				local CastPosition = VipPredictQ:GetPrediction(unit)
				local HitChance = VipPredictQ:GetHitChance(unit)
				if CastPosition ~= nil and HitChance > Menu.Predict.VIPHitChance then
					SpellCast(_Q,CastPosition)
				end
			end
		end
	else
		--Free prediction
		if Menu.Predict.Mode == 1 then
			local CastPosition,HitChance,Position = VP:GetLineCastPosition(unit, Spell.Q.delay, Spell.Q.width, Spell.Q.range, Spell.Q.speed,myHero,true)
			if CastPosition ~= nil and HitChance >= (Menu.Predict.VPHitChance - 1) then
				SpellCast(_Q,CastPosition)
			end
		
		elseif Menu.Predict.Mode == 2 then
			local CastPosition = FreePredictQ:GetPrediction(unit)
			EnemyMinion:update()
			if CastPosition ~= nil and not GetMinionCollision(myHero,unit,Spell.Q.width) then
				SpellCast(_Q,CastPosition)
			end
		end
	end
end

function WLineCast(unit)
	if VIP_USER then
		-- VPrediction
		if Menu.Predict.Mode == 1 then
			local CastPosition,HitChance,Position = VP:GetLineCastPosition(unit, Spell.W.delay, Spell.W.width, Spell.W.range, Spell.W.speed,myHero)
			if CastPosition ~= nil and HitChance >= (Menu.Predict.VPHitChance - 1) then
				SpellCast(_W,CastPosition)
			end
				
		-- Prodiction
		elseif Menu.Predict.Mode == 2 then
			local CastPosition = ProdictW:GetPrediction(unit)
			if CastPosition ~= nil then
				SpellCast(_W,CastPosition)
			end
			
		-- VIP Prediction
		elseif Menu.Predict.Mode == 3 then
			local CastPosition = VipPredictW:GetPrediction(unit)
			local HitChance = VipPredictW:GetHitChance(unit)
			if CastPosition ~= nil and HitChance > Menu.Predict.VIPHitChance then
				SpellCast(_W,CastPosition)
			end
		end
	else
		--Free prediction
		if Menu.Predict.Mode == 1 then
			local CastPosition,HitChance,Position = VP:GetLineCastPosition(unit, Spell.W.delay, Spell.W.width, Spell.W.range, Spell.W.speed,myHero)
			if CastPosition ~= nil and HitChance >= (Menu.Predict.VPHitChance - 1) then
				SpellCast(_W,CastPosition)
			end
				
		-- Prodiction
		elseif Menu.Predict.Mode == 2 then
			local CastPosition = FreePredictW:GetPrediction(unit)
			if CastPosition ~= nil then
				SpellCast(_W,CastPosition)
			end
		end
	end
end

function ECircularCast(unit)
	if objE ~= nil then return end
	if VIP_USER then
		-- All Prediction: use VPrediction to check MEC
		local mainCastPosition, mainHitChance, points, mainPosition = VP:GetCircularAOECastPosition(unit, Spell.E.delay, Spell.E.width, Spell.E.range, Spell.E.speed, myHero)
		if mainCastPosition ~= nil and mainHitChance > 2 and points > 1 then
			SpellCast(_E,mainCastPosition)
		else
			if Menu.Predict.Mode == 1 then
			--VPredict already have MEC
				local CastPosition,HitChance,points = VP:GetCircularCastPosition(unit, Spell.E.delay, Spell.E.width, Spell.E.range, Spell.E.speed,myHero)
				if CastPosition ~= nil and HitChance >= (Menu.Predict.VPHitChance - 1) then
					SpellCast(_E,CastPosition)
				end
			else
				--Prodiction
				if Menu.Predict.Mode == 2 then
					local CastPosition = ProdictE:GetPrediction(unit)
					if CastPosition ~= nil then
						SpellCast(_E,CastPosition)
					end
				--VIP Prediction
				elseif Menu.Predict.Mode == 3 then
					local CastPosition = VipPredictE:GetPrediction(unit)
					local HitChance = VipPredictE:GetHitChance(unit)
					if CastPosition ~= nil and HitChance > Menu.Predict.VIPHitChance then
						SpellCast(_E,CastPosition)
					end
				end
			end
		end
	else
		--Free Prediction
		if Menu.Predict.Mode == 1 then
			local mainCastPosition, mainHitChance, points, mainPosition = VP:GetCircularAOECastPosition(unit, Spell.E.delay, Spell.E.width, Spell.E.range, Spell.E.speed, myHero)
			if mainCastPosition ~= nil and mainHitChance > 2 and points > 1 then
				SpellCast(_E,mainCastPosition)
			else
				--VPredict already have MEC
				local CastPosition,HitChance,points = VP:GetCircularCastPosition(unit, Spell.E.delay, Spell.E.width, Spell.E.range, Spell.E.speed,myHero)
				if CastPosition ~= nil and HitChance >= (Menu.Predict.VPHitChance - 1) then
					SpellCast(_E,CastPosition)
				end
			end
		elseif Menu.Predict.Mode == 2 then
			local CastPosition = FreePredictE:GetPrediction(unit)
			if CastPosition ~= nil then
				SpellCast(_E,CastPosition)
			end
		end
	end
end
function RLineCast(unit)
	if VIP_USER then
		local isDashing, canHit, position = VP:IsDashing(unit, Spell.R.delay + 0.07 + GetLatency() / 2000, Spell.R.width, Spell.R.speed, myHero)
		local isImmobile, position2 = VP:IsImmobile(unit, Spell.R.delay + 0.07 + GetLatency() / 2000, Spell.R.width, Spell.R.speed, myHero)
		if isDashing and canHit and position ~= nil then
			SpellCast(_R,position)
		elseif isImmobile and position2 ~= nil then
			SpellCast(_R,position2)
		-- VPrediction
		elseif Menu.Predict.Mode == 1 then
			local CastPosition,HitChance,Position = VP:GetLineCastPosition(unit, Spell.R.delay, Spell.R.width, Spell.R.range, Spell.R.speed,myHero)
			if CastPosition ~= nil and HitChance >= (Menu.Predict.VPHitChance - 1) then
				SpellCast(_R,CastPosition)
			end
		-- Prodiction
		elseif Menu.Predict.Mode == 2 then
			local CastPosition = ProdictR:GetPrediction(unit)
			if CastPosition ~= nil then
				SpellCast(_R,CastPosition)
			end		
		-- VIP Prediction
		elseif Menu.Predict.Mode == 3 then
			local CastPosition = VipPredictR:GetPrediction(unit)
			local HitChance = VipPredictR:GetHitChance(unit)
			if CastPosition ~= nil and HitChance > Menu.Predict.VIPHitChance then
				SpellCast(_R,CastPosition)
			end
		end
	else
		--Free prediction
		if Menu.Predict.Mode == 1 then
			local isDashing, canHit, position = VP:IsDashing(unit, Spell.R.delay + 0.07 + GetLatency() / 2000, Spell.R.width, Spell.R.speed, myHero)
			local isImmobile, position2 = VP:IsImmobile(unit, Spell.R.delay + 0.07 + GetLatency() / 2000, Spell.R.width, Spell.R.speed, myHero)
			if isDashing and canHit and position ~= nil then
				SpellCast(_R,position)
			elseif isImmobile and position2 ~= nil then
				SpellCast(_R,position2)
			-- VPrediction
			else 
				local CastPosition,HitChance,Position = VP:GetLineCastPosition(unit, Spell.R.delay, Spell.R.width, Spell.R.range, Spell.R.speed,myHero)
				if CastPosition ~= nil and HitChance >= (Menu.Predict.VPHitChance - 1) then
					SpellCast(_R,CastPosition)
				end
			end
		elseif Menu.Predict.Mode == 2 then
			local CastPosition = FreePredictR:GetPrediction(unit)
			if TargetHaveBuff("stun",unit) or TargetHaveBuff("LuxLightBindingMis",unit) or TargetHaveBuff("suppression",unit)
				or TargetHaveBuff("RunePrison",unit) or TargetHaveBuff("DarkBindingMissile",unit) or TargetHaveBuff("caitlynyordletrapdebuff",unit)
				or TargetHaveBuff("CurseoftheSadMummy",unit) then
				SpellCast(_R,unit)
			end
			if CastPosition ~= nil then
				SpellCast(_R,CastPosition)
			end
		end
	end
end
--}

--{ Lag Free circle credits: vadash,ViceVersa,barasia283
function DrawCircleNextLvl(x, y, z, radius, width, color, chordlength)
	radius = radius or 300
	quality = math.max(8,math.floor(180/math.deg((math.asin((chordlength/(2*radius)))))))
	quality = 2 * math.pi / quality
	radius = radius*.92
	local points = {}
	for theta = 0, 2 * math.pi + quality, quality do
		local c = WorldToScreen(D3DXVECTOR3(x + radius * math.cos(theta), y, z - radius * math.sin(theta)))
		points[#points + 1] = D3DXVECTOR2(c.x, c.y)
	end
	DrawLines2(points, width or 1, color or 4294967295)
end


function DrawCircle2(x, y, z, radius, color)
	local vPos1 = Vector(x, y, z)
	local vPos2 = Vector(cameraPos.x, cameraPos.y, cameraPos.z)
	local tPos = vPos1 - (vPos1 - vPos2):normalized() * radius
	local sPos = WorldToScreen(D3DXVECTOR3(tPos.x, tPos.y, tPos.z))
	if Menu.Draw.LFC and OnScreen({ x = sPos.x, y = sPos.y }, { x = sPos.x, y = sPos.y })  then
		DrawCircleNextLvl(x, y, z, radius, 1, color, 75)
	else
		DrawCircle(x,y,z,radius,color)
	end
end
--}

--{ Passive check
function IsIlluminate(unit)
	 return TargetHaveBuff("luxilluminatingfraulein",unit)
end
--}

function OnTick()
	
	--{ Variables
	QREADY = myHero:CanUseSpell(_Q) == READY
	WREADY = myHero:CanUseSpell(_W) == READY
	EREADY = myHero:CanUseSpell(_E) == READY and objE == nil
	RREADY = myHero:CanUseSpell(_R) == READY and objQ == nil
	
	DfgSlot  = GetInventorySlotItem(3128)
	BftSlot  = GetInventorySlotItem(3188)
	
	DFGREADY = (DfgSlot ~= nil and myHero:CanUseSpell(DfgSlot) == READY)
	BFTREADY = (BftSlot ~= nil and myHero:CanUseSpell(BftSlot) == READY)
	IGNITEREADY = (IgniteSlot ~= nil and myHero:CanUseSpell(IgniteSlot) == READY)
	
	TARGET = GrabTarget()
	Ally = GrabAlly(Spell.W.range)
	
	--}
	--{ Auto Pop E when enemy in range
	if Menu.Extra.PopE and not Menu.General.toggleE then
		for i = 1, heroManager.iCount do
			local hero = heroManager:GetHero(i)
			local radius = Spell.E.width + VP:GetHitBox(hero)
			if hero.team ~= myHero.team and objE ~= nil and ValidTarget(hero) and GetDistanceSqr(objE,hero) <= radius * radius then
				CastSpell(_E)
			end
		end
	end
		--}
	
	--{ Auto Q 
	-- When enemy hero are near
	if Menu.Combo.Lig.Near then
		for i = 1, heroManager.iCount do
			local hero = heroManager:GetHero(i)
			if hero.team ~= myHero.team and ValidTarget(hero,400) then
				QLineCast(hero)
			end
		end
	end
	-- On Gap closer
	if VIP_USER then
		if Menu.Combo.Lig.GapCloser then
			for i = 1, heroManager.iCount do
				local hero = heroManager:GetHero(i)
				if hero.team ~= myHero.team and ValidTarget(hero,400) then
					local isDashing, canHit, position = VP:IsDashing(hero, Spell.Q.delay + 0.07 + GetLatency() / 2000, Spell.Q.width, Spell.Q.speed, myHero)
					if position ~= nil then
						local isCol,ColTable = Col:GetCollision(myHero,position)
						if #ColTable <= 1 then
							if isDashing and GetDistanceSqr(myHero,position) < Spell.Q.range * Spell.Q.range and canHit then
								SpellCast(_Q,position)
							end
						end
					end
				end
			end
			
		end
	end
	--}
	
	--{ Combo
	if Menu.General.Combo then		
		if ValidTarget(TARGET) then
			OW:DisableAttacks()
			if Menu.Combo.I and GetDistanceSqr(myHero,TARGET) <= 750 * 750 then
				if DFGREADY then
					CastSpell(DfgSlot,TARGET)
				end
				
				if BFTREADY then
					CastSpell(BftSlot,TARGET)
				end
			end
			
			if Menu.Combo.Q and GetDistanceSqr(myHero,TARGET) <= Spell.Q.range * Spell.Q.range then
				QLineCast(TARGET)
			end
			
			if Menu.Combo.E and GetDistanceSqr(myHero,TARGET) <= Spell.E.range * Spell.E.range and (not QREADY and objQ == nil or not Menu.Combo.Q)  then
				ECircularCast(TARGET)
			end
			
			if IsIlluminate(TARGET) or not (QREADY and EREADY) then
				OW:EnableAttacks()
			end
			
		end
		if Menu.Combo.Ult.R == 1 then
			for i = 1, heroManager.iCount do
				local hero = heroManager:GetHero(i)
				if hero.team ~= myHero.team and ValidTarget(hero,Spell.R.range) and getDmg("R",hero,myHero) > hero.health then
					RLineCast(hero)
				end
			end
		elseif Menu.Combo.Ult.R == 2 then
			if VIP_USER and ValidTarget(TARGET) then
				local isImmobile, position = VP:IsImmobile(TARGET, Spell.R.delay + 0.07 + GetLatency() / 2000, Spell.R.width, Spell.R.speed, myHero)
				if isImmobile and position ~= nil then
					RLineCast(TARGET)
				end
			else
				if TargetHaveBuff("stun",TARGET) or TargetHaveBuff("LuxLightBindingMis",TARGET) or TargetHaveBuff("suppression",TARGET)
					or TargetHaveBuff("RunePrison",TARGET) or TargetHaveBuff("DarkBindingMissile",TARGET) or TargetHaveBuff("caitlynyordletrapdebuff",TARGET)
					or TargetHaveBuff("CurseoftheSadMummy",TARGET) then
					SpellCast(_R,TARGET)
				end
			end
		elseif Menu.Combo.Ult.R == 3 then
			for i = 1, heroManager.iCount do
				local hero = heroManager:GetHero(i)
				if hero.team ~= myHero.team and ValidTarget(hero,Spell.R.range) then
					RLineCast(hero)
				end
			end		
		end
	end
	--}
	
	--{ Auto Use R on stunned target
	if Menu.Combo.Ult.AutoRStun then
		for i = 1, heroManager.iCount do
			local hero = heroManager:GetHero(i)
			if hero.team ~= myHero.team and ValidTarget(hero,Spell.R.range) then
				if VIP_USER or (not VIP_USER and Menu.Predict.mode == 1) then
					local isImmobile, position = VP:IsImmobile(hero, Spell.R.delay + 0.07 + GetLatency() / 2000, Spell.R.width, Spell.R.speed, Spell.R.sourcePosition)
					if isImmobile and position ~= nil and ( CountAllyInRange(hero,800) >= 1 or getDmg("R",hero,myHero) > hero.health ) then
						SpellCast(_R,position)
					end
				else
					if TargetHaveBuff("stun",hero) or TargetHaveBuff("LuxLightBindingMis",hero) or TargetHaveBuff("suppression",hero)
					or TargetHaveBuff("RunePrison",hero) or TargetHaveBuff("DarkBindingMissile",hero) or TargetHaveBuff("caitlynyordletrapdebuff",hero)
					or TargetHaveBuff("CurseoftheSadMummy",hero) and ( CountAllyInRange(hero,800) >= 1 or getDmg("R",hero,myHero) ) then
						SpellCast(_R,hero)
					end
				end
			end
		end
	end
	--}
	
	--{ Auto Use R on killable target
	if Menu.Combo.Ult.AutoRKill then
		for i = 1, heroManager.iCount do
			local hero = heroManager:GetHero(i)
			if hero.team ~= myHero.team and ValidTarget(hero,Spell.R.range) and getDmg("R",hero,myHero) > hero.health then
				RLineCast(hero)
			end
		end
	end
	--}
	
	--{ Auto Use R/Ultimate if x enemy around
	if VIP_USER or (not VIP_USER and Menu.Predict.mode == 1) then
		if Menu.Combo.Ult.AutoR > 1 then
			local minTarget = Menu.Combo.Ult.AutoR - 2
			for i = 1, heroManager.iCount do
				local hero = heroManager:GetHero(i)
				if hero.team ~= myHero.team and ValidTarget(hero,Spell.R.range) and ( CountAllyInRange(hero,800) >= 1 or getDmg("R",hero,myHero) > hero.health ) then
					mainCastPosition, mainHitChance, maxHit, Positions = VP:GetLineAOECastPosition(hero, Spell.R.delay, Spell.R.width, Spell.R.range, Spell.R.speed, myHero)
					if mainCastPosition ~= nil and maxHit > minTarget and mainHitChance >=2 then
						SpellCast(_R,mainCastPosition)
					end
				end
			end
		end
	end
	--}
	--{ Harass
	if Menu.General.Harass and ValidTarget(TARGET) then
		if Menu.Harass.Q then
			QLineCast(TARGET)
		end
		if Menu.Harass.E then
			ECircularCast(TARGET)
		end
	end
	--}
	
	--{ Shield
	if Ally and not Recalling and CountEnemyInRange(Ally,1000) > 0 and GetDistanceSqr(myHero,Ally) <= Spell.W.range * Spell.W.range then
		if Menu.Shield.Auto then
			if Menu.Shield.Amn < myHero.mana/myHero.maxMana * 100 and Menu.Shield.Amh > Ally.health/Ally.maxHealth * 100 then
				WLineCast(Ally)
			end
			if CountEnemyInRange(Ally,600) > 1 then
				WLineCast(Ally)
			end
		end
		
		if Menu.General.Shield then
			if (Menu.Shield.Mmn < myHero.mana/myHero.maxMana * 100 ) and ( Menu.Shield.Mmh > Ally.health/Ally.maxHealth * 100) then
				WLineCast(Ally)
			end
		end
		

	end
	--}
	
	--{ Farm/Jungle
	if Menu.General.Farm then		
		--Farm
		EnemyMinion:update()
		if myHero.mana/myHero.maxMana * 100 > Menu.Farm.Mana and ValidTarget(EnemyMinion.objects[1],Spell.Q.range) then
			if QREADY and Menu.Farm.Q then
				if VIP_USER then
					local qDmg = getDmg("Q",EnemyMinion.objects[1],myHero)
					local isCol,ColTable = Col:GetCollision(myHero,EnemyMinion.objects[1])
					if #ColTable == 0 and qDmg > EnemyMinion.objects[1].health then
						SpellCast(_Q,EnemyMinion.objects[1])
					elseif #ColTable == 1 and qDmg * 0.5 > EnemyMinion.objects[1].health then
						SpellCast(_Q,EnemyMinion.objects[1])
					end
				else
					--Free user
					if getDmg("Q",EnemyMinion.objects[1],myHero) >= EnemyMinion.objects[1].health and not GetMinionCollision(myHero,EnemyMinion.objects[1],Spell.Q.width) then 
						SpellCast(_Q,EnemyMinion.objects[1])
					end
				end
			end
			if myHero:CanUseSpell(_E) == READY and ValidTarget(EnemyMinion.objects[1],Spell.E.range) and Menu.Farm.E then
				if getDmg("E",EnemyMinion.objects[1],myHero) >= EnemyMinion.objects[1].health + 100 then 
					if objE == nil then
						SpellCast(_E,EnemyMinion.objects[1])
					end
				end
				if getDmg("E",EnemyMinion.objects[1],myHero) >= EnemyMinion.objects[1].health then
					if objE ~= nil then
						CastSpell(_E)
					end
				end
					
			end
		end
		--Jungle
		JungMinion:update()
		if ValidTarget(JungMinion.objects[1],Spell.Q.range) then
			if Menu.Farm.Q and QREADY then
				SpellCast(_Q,JungMinion.objects[1])
			end
		end
		if Menu.Farm.E and myHero:CanUseSpell(_E) == READY and ValidTarget(JungMinion.objects[1],Spell.E.range) then
			if objE ~= nil and GetDistanceSqr(objE,JungMinion.objects[1]) <= Spell.E.width * Spell.E.width then
				CastSpell(_E)
			else
				SpellCast(_E,JungMinion.objects[1])
			end
		end
			
		if OW:CanAttack() and ValidTarget(JungMinion.objects[1],myHero.range + 50)  then
			myHero:Attack(JungMinion.objects[1])
		end		
	end

	--}
	
	--{ Jungle Steal
	if Menu.General.Steal1 or Menu.General.Steal2 then
		StealMinion:update()
		if Menu.Farm.Steal.important then
			--Steal dragon/baron
			stealObj = nil
			for i, minion in pairs(StealMinion.objects) do
				if minion.maxHealth > 4000 then
					stealObj = minion
				end
			end
			if ValidTarget(stealObj) then
				if objE ~= nil or QREADY or EREADY and GetDistanceSqr(myHero,stealObj) < Spell.Q.range * Spell.Q.range then
					if objE ~= nil and stealObj.health < getDmg("E",stealObj,myHero) and GetDistanceSqr(objE,stealObj) <= Spell.E.width * Spell.E.width then
						CastSpell(_E)
					elseif QREADY and stealObj.health < getDmg("Q",stealObj,myHero) and GetDistanceSqr(myHero,stealObj) <= Spell.Q.range * Spell.Q.range then
						SpellCast(_Q,stealObj)
					elseif EREADY and stealObj.health < getDmg("E",stealObj,myHero) and GetDistanceSqr(myHero,stealObj) <= Spell.E.range * Spell.E.range then
						SpellCast(_E,stealObj)
					elseif EREADY and QREADY and stealObj.health < getDmg("E",stealObj,myHero) + getDmg("Q",stealObj,myHero) and GetDistanceSqr(myHero,stealObj) <= Spell.E.range * Spell.E.range then
						SpellCast(_Q,stealObj)
						SpellCast(_E,stealObj)
					end
				else
					if RREADY and stealObj.health < getDmg("R",stealObj,myHero) and GetDistanceSqr(myHero,stealObj) <= Spell.R.range * Spell.R.range then
						SpellCast(_R,stealObj)
					end	
				end
			end
		end
		
		if Menu.Farm.Steal.blue then
			--Steal blue buff
			blueObj = nil
			for i, minion in pairs(StealMinion.objects) do
				if minion.name == "AncientGolem1.1.1" or minion.name == "AncientGolem7.1.1" then
					blueObj = minion
				end
			end
			if ValidTarget(blueObj) then
				if objE ~= nil or QREADY or EREADY and GetDistanceSqr(myHero,blueObj) < Spell.Q.range * Spell.Q.range then
					if objE ~= nil and blueObj.health < getDmg("E",blueObj,myHero) and GetDistanceSqr(objE,blueObj) <= Spell.E.width * Spell.E.width then
						CastSpell(_E)
					elseif QREADY and blueObj.health < getDmg("Q",blueObj,myHero) and GetDistanceSqr(myHero,blueObj) <= Spell.Q.range * Spell.Q.range then
						SpellCast(_Q,blueObj)
					elseif EREADY and blueObj.health < getDmg("E",blueObj,myHero) and GetDistanceSqr(myHero,blueObj) <= Spell.E.range * Spell.E.range then
						SpellCast(_E,blueObj)
					elseif EREADY and QREADY and blueObj.health < getDmg("E",blueObj,myHero) + getDmg("Q",blueObj,myHero) and GetDistanceSqr(myHero,blueObj) <= Spell.E.range * Spell.E.range then
						SpellCast(_Q,blueObj)
						SpellCast(_E,blueObj)
					end
				else
					if RREADY and blueObj.health < getDmg("R",blueObj,myHero) and GetDistanceSqr(myHero,blueObj) <= Spell.R.range * Spell.R.range then
						SpellCast(_R,blueObj)
					end	
				end
			end
		end
		if Menu.Farm.Steal.red then
			redObj = nil
			for i, minion in pairs(StealMinion.objects) do
				if minion.name == "LizardElder4.1.1" or minion.name == "LizardElder10.1.1" then
					redObj = minion
				end
			end
			if ValidTarget(redObj) then
				if objE ~= nil or QREADY or EREADY and GetDistanceSqr(myHero,redObj) < Spell.Q.range * Spell.Q.range then
					if objE ~= nil and redObj.health < getDmg("E",redObj,myHero) and GetDistanceSqr(objE,redObj) <= Spell.E.width * Spell.E.width then
						CastSpell(_E)
					elseif QREADY and redObj.health < getDmg("Q",redObj,myHero) and GetDistanceSqr(myHero,redObj) <= Spell.Q.range * Spell.Q.range then
						SpellCast(_Q,redObj)
					elseif EREADY and redObj.health < getDmg("E",redObj,myHero) and GetDistanceSqr(myHero,redObj) <= Spell.E.range * Spell.E.range then
						SpellCast(_E,redObj)
					elseif EREADY and QREADY and redObj.health < getDmg("E",redObj,myHero) + getDmg("Q",redObj,myHero) and GetDistanceSqr(myHero,redObj) <= Spell.E.range * Spell.E.range then
						SpellCast(_Q,redObj)
						SpellCast(_E,redObj)
					end
				else
					if RREADY and redObj.health < getDmg("R",redObj,myHero) and GetDistanceSqr(myHero,redObj) <= Spell.R.range * Spell.R.range then
						SpellCast(_R,redObj)
					end	
				end
			end
		end
	end
	--}
	
	--{ Auto Ignite
	if Menu.Extra.AutoI then
		for i = 1, heroManager.iCount do
			local hero = heroManager:GetHero(i)
			if hero.team ~= myHero.team and ValidTarget(hero,650) and getDmg("IGNITE",hero,myHero) > hero.health and IgniteSlot ~= nil then
				CastSpell(IgniteSlot,hero)
			end
		end
	end
	--}
	
	--{ Auto level sequence
	if Menu.Extra.AutoLevel == 2 then
		autoLevelSetSequence(MaxEQ)
	end
	--}
end

function OnDraw()
	if QREADY and Menu.Draw.Skill.QRange then
		DrawCircle2(myHero.x,myHero.y,myHero.z,Spell.Q.range,ARGB(Menu.Draw.Skill.QColor[1],Menu.Draw.Skill.QColor[2],Menu.Draw.Skill.QColor[3],Menu.Draw.Skill.QColor[4]))
	end
	if WREADY and Menu.Draw.Skill.WRange then
		DrawCircle2(myHero.x,myHero.y,myHero.z,Spell.W.range,ARGB(Menu.Draw.Skill.WColor[1],Menu.Draw.Skill.WColor[2],Menu.Draw.Skill.WColor[3],Menu.Draw.Skill.WColor[4]))
	end
	if EREADY and Menu.Draw.Skill.ERange then
		DrawCircle2(myHero.x,myHero.y,myHero.z,Spell.E.range,ARGB(Menu.Draw.Skill.EColor[1],Menu.Draw.Skill.EColor[2],Menu.Draw.Skill.EColor[3],Menu.Draw.Skill.EColor[4]))
	end
	if Menu.Draw.Skill.RRange and myHero:GetSpellData(_R).level > 0 then
		DrawCircleMinimap(myHero.x,myHero.y,myHero.z,Spell.R.range)
	end
	
	if Menu.Draw.Skill.RKill and RREADY then
		for i = 1, heroManager.iCount do
			local hero = heroManager:GetHero(i)
			if hero.team ~= myHero.team and ValidTarget(hero,Spell.R.range) and getDmg("R",hero,myHero) > hero.health then
				local startPos = WorldToScreen(D3DXVECTOR3(myHero.x,myHero.y,myHero.z))
				local heroPos = WorldToScreen(D3DXVECTOR3(hero.x,hero.y,hero.z))
				DrawText("Ult Kill!",18,heroPos.x,heroPos.y,ARGB(255,0,255,0))
				DrawLineBorder(startPos.x,startPos.y,heroPos.x,heroPos.y,50,ARGB(255,0,255,255),3)
			end
		end
	end
	
	
end

function OnCreateObj(obj)
	if obj.name:find("LuxLightstrike_tar_green") then
		objE = obj
	end
	if obj.name:find("LuxLightBinding") then
		objQ = obj
	end
	if obj.name:find("TeleportHome") then
		Recalling = true
	end
end


function OnDeleteObj(obj)
	if obj.name:find("LuxLightstrike_tar_green") or (objE ~= nil and obj.name == objE.name) then
		objE = nil
	end
	if obj.name:find("LuxLightBinding") or (objQ ~= nil and obj.name == objQ.name) then
		objQ = nil
	end
	if obj.name:find("TeleportHome") or (Recalling == nil and obj.name == Recalling.name) then
		Recalling = false
	end
end

function OnProcessSpell(unit,spell)
	if unit.isMe and spell.name:find("LuxLightBinding") then
		QCasting = os.clock()
	end
	
	if Menu.Shield.At and unit.team ~= myHero.team and (unit.type =="obj_AI_Hero" or unit.type == "obj_AI_Turret") then
		local spellTarget = spell.target
		if spellTarget == myHero and not _G.Evade then
			if Ally ~= nil then
				WLineCast(Ally)
			else
				SpellCast(_W,myHero)
			end
		end
	end
end
