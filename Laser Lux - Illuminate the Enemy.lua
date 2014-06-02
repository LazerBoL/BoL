--[[
 _                                   _                             
( )                                 ( )                            
| |       _ _   ___    __   _ __    | |     _   _        
| |  _  /'_` )/',__) /'__`\( '__)   | |  _ ( ) ( )(`\/')  
| |_( )( (_| |\__, \(  ___/| |      | |_( )| (_) | >  <            
(____/'`\__,_)(____/`\____)(_)      (____/'`\___/'(_/\_)     

--Report:
Cast Skill hut
Nen su~a logic ultimate
--]]
local currVersion = "1.00"
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
		["VPrediction"] = "https://raw.githubusercontent.com/Hellsing/BoL/master/common/VPrediction.lua"
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
	
	-- Target Selector
	if VIP_USER then
		Selector.Instance()
		-- Collision
		Col = Collision(Spell.Q.range,Spell.Q.speed,Spell.Q.delay,Spell.Q.width)
	end
	ts = TargetSelector(TARGET_LESS_CAST,1250,DAMAGE_MAGIC,false)
	ts.name = "AllClass TS"
	
	-- Minion & Jungle Mob
	EnemyMinion = minionManager(MINION_ENEMY,Spell.Q.range,myHero,MINION_SORT_HEALTH_ASC)
	JungMinion = minionManager(MINION_JUNGLE, Spell.Q.range, myHero, MINION_SORT_MAXHEALTH_DEC)
	
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
		Menu.Combo:addParam("R","Cast Ultimate mode",SCRIPT_PARAM_LIST,1,{"Killable enemy","Combo","Always Use","None"})
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
		Menu.Extra:addParam("AutoQ","Auto Q when enemy hero near Lux",SCRIPT_PARAM_ONOFF,true)
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
			Menu.Predict:addParam("Mode","    Prediction Mode",SCRIPT_PARAM_LIST,1,{"Free Prediction"})
		end
		--}
		
		--{ Perma Show
		Menu.Script:permaShow("Author")
		Menu.General:permaShow("Combo")
		Menu.Combo:permaShow("R")
		Menu.General:permaShow("Harass")
		Menu.General:permaShow("Shield")
		Menu.General:permaShow("Farm")
		Menu.Draw.Skill:permaShow("WInfo")
		if VIP_USER then
			Menu.Predict:permaShow("Mode")
		end
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
				CastPosition,HitChance,Position = VP:GetLineCastPosition(unit, Spell.Q.delay, Spell.Q.width, Spell.Q.range, Spell.Q.speed)
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
		local CastPosition = FreePredictQ:GetPrediction(unit)
		EnemyMinion:update()
		if CastPosition ~= nil and not GetMinionCollision(myHero,unit,Spell.Q.width) then
			SpellCast(_Q,CastPosition)
		end
	end
end

function WLineCast(unit)
	if VIP_USER then
		-- VPrediction
		if Menu.Predict.Mode == 1 then
			CastPosition,HitChance,Position = VP:GetLineCastPosition(unit, Spell.W.delay, Spell.W.width, Spell.W.range, Spell.W.speed)
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
		local CastPosition = FreePredictW:GetPrediction(unit)
		if CastPosition ~= nil then
			SpellCast(_W,CastPosition)
		end
	end
end

function ECircularCast(unit)
	if VIP_USER then
		if Menu.Predict.Mode == 1 then
		--VPredict already have MEC
			local CastPosition,HitChance,points = VP:GetCircularCastPosition(unit, Spell.E.delay, Spell.E.width, Spell.E.range, Spell.E.speed)
			if CastPosition ~= nil and HitChance >= (Menu.Predict.VPHitChance - 1) then
				SpellCast(_E,CastPosition)
			end
		else
			--Other Predict: use VPrediction to check MEC
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
	else
		--Free Prediction
		local CastPosition = FreePredictE:GetPrediction(unit)
		if CastPosition ~= nil then
			SpellCast(_E,CastPosition)
		end
	end
end
function RLineCast(unit)
	if VIP_USER then
			-- VPrediction
		if Menu.Predict.Mode == 1 then
			CastPosition,HitChance,Position = VP:GetLineCastPosition(unit, Spell.R.delay, Spell.R.width, Spell.R.range, Spell.R.speed)
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
		local CastPosition = FreePredictR:GetPrediction(unit)
		if CastPosition ~= nil then
			SpellCast(_R,CastPosition)
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
	
	
	--{ Auto Q when enemy hero are near
	if Menu.Extra.AutoQ then
		for i = 1, heroManager.iCount do
			local hero = heroManager:GetHero(i)
			if hero.team ~= myHero.team and ValidTarget(hero,400) then
				QLineCast(hero)
			end
		end
	end
	--}
	
	--{ Auto Pop E when enemy in range
	if Menu.Extra.PopE then
		for i = 1, heroManager.iCount do
			local hero = heroManager:GetHero(i)
			if hero.team ~= myHero.team and objE ~= nil and ValidTarget(hero) and GetDistanceSqr(objE,hero) <= Spell.E.width * Spell.E.width then
				CastSpell(_E)
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
			
			if IsIlluminate(TARGET) or not (QREADY and EREADY) then
				OW:EnableAttacks()
			end
			
			if Menu.Combo.Q and GetDistanceSqr(myHero,TARGET) <= Spell.Q.range * Spell.Q.range then
				QLineCast(TARGET)
			end
			if Menu.Combo.E and GetDistanceSqr(myHero,TARGET) <= Spell.E.range * Spell.E.range then
				ECircularCast(TARGET)
			end
			
		end
		if Menu.Combo.R == 1 then
			for i = 1, heroManager.iCount do
				local hero = heroManager:GetHero(i)
				if hero.team ~= myHero.team and ValidTarget(hero,Spell.R.range) and getDmg("R",hero,myHero) > hero.health then
					RLineCast(hero)
				end
			end
		elseif Menu.Combo.R == 2 then
			RLineCast(TARGET)
		elseif Menu.Combo.R == 3 then
				for i = 1, heroManager.iCount do
				local hero = heroManager:GetHero(i)
				if hero.team ~= myHero.team and ValidTarget(hero,Spell.R.range) then
					RLineCast(hero)
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
      if Menu.Farm.E and myHero:CanUseSpell(_E) == READY and ValidTarget(JungMinion.objects[1],Spell.E.range) then
				if objE ~= nil and GetDistanceSqr(objE,JungMinion.objects[1]) <= Spell.E.width * Spell.E.width then
					CastSpell(_E)
				else
					SpellCast(_E,JungMinion.objects[1])
				end
      end
			myHero:Attack(JungMinion.objects[1])
    end
	end
	--}
	
	--{ Auto Ignite
	if Menu.Extra.AutoI then
		for i = 1, heroManager.iCount do
			local hero = heroManager:GetHero(i)
			if hero.team ~= myHero.team and ValidTarget(hero,650) and getDmg("IGNITE",hero,myHero) > hero.health then
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
	if obj.name:find("LuxLightstrike") then
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
	if obj.name:find("LuxLightstrike") or (objE ~= nil and obj.name == objE.name) then
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
