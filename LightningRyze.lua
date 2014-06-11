--[[ Lightning Ryze - Let's go let's go
	Changelog:
		0.002:
			-Fixed CastSpell error cause by ignite
			-Fixed bug with long combo
		0.001: Initial release
--]]

local ryze_autoupdate = false
local silentUpdate = false

local version = 0.002

local scriptName = "LightningRyze"

myHero = GetMyHero()

if myHero.charName ~= 'Ryze' then return end

--{ Sourcelib check
local sourceLibFound = true
if FileExist(LIB_PATH .. "SourceLib.lua") then
    require "SourceLib"
else
    sourceLibFound = false
    DownloadFile("https://raw.github.com/TheRealSource/public/master/common/SourceLib.lua", LIB_PATH .. "SourceLib.lua", function() print("<font color=\"#6699ff\"><b>" .. scriptName .. ":</b></font> <font color=\"#FFFFFF\">SourceLib downloaded! Please reload!</font>") end)
end

if not sourceLibFound then print("Can't find sourcelib") return end
--}

--{ Auto update
if ryze_autoupdate then
	SourceUpdater(scriptName, version, "raw.github.com", "/LazerBoL/BoL/master/" .. scriptName .. ".lua", SCRIPT_PATH .. GetCurrentEnv().FILE_NAME, "/LazerBoL/BoL/master/version/" .. scriptName .. ".version"):SetSilent(silentUpdate):CheckUpdate()
end
--}

--{ Lib downloader
 local libDownloader = Require(scriptName)
        libDownloader:Add("VPrediction", "https://raw.github.com/Hellsing/BoL/master/common/VPrediction.lua")
        libDownloader:Add("SOW",         "https://raw.github.com/Hellsing/BoL/master/common/SOW.lua")
		libDownloader:Add("Selector",    "https://raw.githubusercontent.com/pqmailer/BoL_Scripts/master/Paid/Selector.lua")
        libDownloader:Check()

 if libDownloader.downloadNeeded then return end
--}

function RyzeData()
	SpellData = {
		Q = {range = 625    ,delay = 0.25    ,speed = 1400},
		W = {range = 600    ,delay = 0.25    ,speed = math.huge},
		E = {range = 600    ,delay = 0.25    ,speed = 1000}, 
		R = {range = -1     ,delay = 0.25    ,speed = math.huge} 
	}
	MainCombo = {ItemManager:GetItem("DFG"):GetId(), _Q , _E , _W, _IGNITE, _AA}
	maxQRWE = {1,2,3,1,1,4,1,2,1,2,4,2,2,3,3,4,3,3}	
	LastFlashTime = 0
end

function OnLoad()
	--{ Variables
	RyzeData()
	VP = VPrediction()
	OW = SOW(VP)
	STS = SimpleTS()
	DM = DrawManager()
	DLib = DamageLib()
	--}
	Selector.Instance()
	--{ Spell data
	Q = Spell(_Q, SpellData.Q.range)
	W = Spell(_W, SpellData.W.range)
	E = Spell(_E, SpellData.E.range)
	R = Spell(_R, SpellData.R.range)
	
	DLib:RegisterDamageSource(_Q, _MAGIC, 35,  25,  {_MAGIC,_MAGIC}, {_AP,_MAXMANA}, {0.4,  0.065}, function() return (player:CanUseSpell(_Q) == READY) end)
	DLib:RegisterDamageSource(_W, _MAGIC, 25,  35,  {_MAGIC,_MAGIC}, {_AP,_MAXMANA}, {0.6,  0.045}  , function() return (player:CanUseSpell(_W) == READY) end)
	DLib:RegisterDamageSource(_E, _MAGIC, 30,  20,  {_MAGIC,_MAGIC}, {_AP,_MAXMANA}, {0.35, 0.01}   , function() return (player:CanUseSpell(_E) == READY) end)
	
	__Q = 1234
	__W = 1235
	__E = 1236
	DLib:RegisterDamageSource(__Q, _MAGIC, 35,  25,  {_MAGIC,_MAGIC}, {_AP,_MAXMANA}, {0.4,  0.065})
	DLib:RegisterDamageSource(__W, _MAGIC, 25,  35,  {_MAGIC,_MAGIC}, {_AP,_MAXMANA}, {0.6,  0.045})
	DLib:RegisterDamageSource(__E, _MAGIC, 30,  20,  {_MAGIC,_MAGIC}, {_AP,_MAXMANA},  {0.35, 0.01})
	--}
	
	--{ Menu
	Menu = scriptConfig("Lightning Ryze","LightningRyze")
	
	--Author
	Menu:addSubMenu("[ Ryze : Script Information ]","Script")
		Menu.Script:addParam("Author","Author: Lazer",SCRIPT_PARAM_INFO,"")
		Menu.Script:addParam("Credits","Credits: Pain,ViceVersa,turtlebot,",SCRIPT_PARAM_INFO,"")
		Menu.Script:addParam("Credits1","Honda7,Hellsing,shagratt,Feez",SCRIPT_PARAM_INFO,"")
		Menu.Script:addParam("Version","Version: " .. version,SCRIPT_PARAM_INFO,"")
	--General
	Menu:addSubMenu("[ Ryze : General ]","General")
		Menu.General:addParam("Combo","Combo",SCRIPT_PARAM_ONKEYDOWN,false,32)
		Menu.General:addParam("Harass","Harass",SCRIPT_PARAM_ONKEYDOWN,false,string.byte("C"))
		Menu.General:addParam("Farm","Farm/Jungle press",SCRIPT_PARAM_ONKEYDOWN,false,string.byte("V"))
	
	--Target Selector
	Menu:addSubMenu("[ Ryze : Target Selector ]","TS")
		Menu.TS:addParam("TS","Target Selector",SCRIPT_PARAM_LIST,2,{"AllClass","STS","SAC: Reborn","MMA","Selector"})
		ts = TargetSelector(TARGET_LESS_CAST,625,DAMAGE_MAGIC,false)
		ts.name = "AllClass TS"
		Menu.TS:addTS(ts)
		
	--Orbwalking
	Menu:addSubMenu("[ Ryze : Orbwalking ]","Orbwalking")
		OW:LoadToMenu(Menu.Orbwalking)
	
	--Combo
	Menu:addSubMenu("[ Ryze : Combo ]","Combo")
		Menu.Combo:addParam("Mode","Combo mode",SCRIPT_PARAM_LIST,1,{"Mixed mode","Burst combo","Long combo"})
		Menu.Combo:addParam("R","Use R in combo",SCRIPT_PARAM_ONOFF,true)
		Menu.Combo:addParam("Item","Use item in combo",SCRIPT_PARAM_ONOFF,true)
		Menu.Combo:addParam("Ignite","Use ignite in combo",SCRIPT_PARAM_ONOFF,true)
		
	--Harass
	Menu:addSubMenu("[ Ryze : Harass ]","Harass")
		Menu.Harass:addParam("Q","Use Q to harass",SCRIPT_PARAM_ONOFF,true)
		Menu.Harass:addParam("W","Use W to harass",SCRIPT_PARAM_ONOFF,false)
		Menu.Harass:addParam("E","Use E to harass",SCRIPT_PARAM_ONOFF,true)
		
	--Jungle/Farm Settings
	Menu:addSubMenu("[ Ryze : Farm/Jungle Settings ]","Farm")
		Menu.Farm:addParam("LInfo","--------Farm Lane settings--------",SCRIPT_PARAM_INFO,"")
		Menu.Farm:addParam("LQ","Use Q to 'Farm/Jungle'",SCRIPT_PARAM_ONOFF,true)
		Menu.Farm:addParam("LW","Use W to 'Farm/Jungle'",SCRIPT_PARAM_ONOFF,false)
		Menu.Farm:addParam("LE","Use E to 'Farm/Jungle'",SCRIPT_PARAM_ONOFF,false)
		Menu.Farm:addParam("LR","Use R to 'Farm/Jungle'",SCRIPT_PARAM_ONOFF,false)
		Menu.Farm:addParam("Mana","Don't farm if mana < %",SCRIPT_PARAM_SLICE,20,0,100)
		
		Menu.Farm:addParam("JInfo","--------Farm jungle settings--------",SCRIPT_PARAM_INFO,"")
		Menu.Farm:addParam("JQ","Use Q to 'Farm/Jungle'",SCRIPT_PARAM_ONOFF,true)
		Menu.Farm:addParam("JW","Use W to 'Farm/Jungle'",SCRIPT_PARAM_ONOFF,true)
		Menu.Farm:addParam("JE","Use E to 'Farm/Jungle'",SCRIPT_PARAM_ONOFF,true)
		Menu.Farm:addParam("JR","Use R to 'Farm/Jungle'",SCRIPT_PARAM_ONOFF,true)
		
		
	--Interrupt Settings
	Menu:addSubMenu("[ Ryze : Auto interrupt settings ]","Interrupt")
	Interrupter(Menu.Interrupt, OnTargetInterruptable)
	
	--Extra Settings
	Menu:addSubMenu("[ Ryze: Extra Settings ]","Extra")
	if VIP_USER then
		Menu.Extra:addParam("Packet","Use Packet cast",SCRIPT_PARAM_ONOFF,false)
	end
	Menu.Extra:addParam("AutoIgnite","Auto ignite if killable",SCRIPT_PARAM_ONOFF,true)
	Menu.Extra:addParam("AutoLevel","Auto level sequence",SCRIPT_PARAM_LIST,1,{"None","QRWE"})
	
	--Draw Settings
	Menu:addSubMenu("[ Ryze : Draw ]","Draw")
		DM:CreateCircle(myHero, SpellData.Q.range, 1, {255, 100, 0, 255}):AddToMenu(Menu.Draw, "Q Range", true, true, true)
		DM:CreateCircle(myHero, SpellData.W.range, 1, {255, 0, 100, 255}):AddToMenu(Menu.Draw, "W,E Range", true, true, true)
		
		-- Predicted damage tick on health bar
		DLib:AddToMenu(Menu.Draw, MainCombo)

	-- Minion & Jungle Mob
	EnemyMinion = minionManager(MINION_ENEMY,625,myHero,MINION_SORT_HEALTH_ASC)
	JungMinion = minionManager(MINION_JUNGLE,625,myHero,MINION_SORT_MAXHEALTH_DEC)
	
	--}
	
	TickLimiter(OnTick10, 10)
	TickLimiter(OnTick1, 1)
	
	--{ Perma show
	Menu.Script:permaShow("Author")
	Menu.General:permaShow("Combo")
	Menu.General:permaShow("Harass")
	Menu.General:permaShow("Farm")
	Menu.Combo:permaShow("Mode")
	Menu.Combo:permaShow("Ignite")
	--}
	
	--{ All loaded
	print("<font color='#FFBF00'>Lightning </font><font color='#0064FF'>Ryze</font><font color='#00FFFF'> v" .. version .."</font>")
	--}
end

--{ Target Selector
function GrabTarget()
	if  _G.Selector_Enabled and Menu.TS.TS == 5 then
		return Selector.GetTarget(SelectorMenu.Get().mode, nil, {distance = MaxRange()})
	elseif _G.MMA_Loaded and Menu.TS.TS == 4 then
		return _G.MMA_ConsideredTarget(MaxRange())		
	elseif _G.AutoCarry and Menu.TS.TS == 3 then
		return _G.AutoCarry.Crosshair:GetTarget()
	elseif Menu.TS.TS == 2 then
		return STS:GetTarget(MaxRange())
	else
		ts.range = MaxRange()
		ts:update()
		return ts.target
	end
end

function GrabTargetInRange(rangeT)
	if  _G.Selector_Enabled and Menu.TS.TS == 5 then
		return Selector.GetTarget(SelectorMenu.Get().mode, nil, {distance = rangeT})
	elseif _G.MMA_Loaded and Menu.TS.TS == 4 then
		return _G.MMA_ConsideredTarget(rangeT)		
	elseif _G.AutoCarry and Menu.TS.TS == 3 then
		return _G.AutoCarry.Crosshair:GetTarget()
	elseif Menu.TS.TS == 2 then
		return STS:GetTarget(rangeT)
	else
		ts.range = rangeT
		ts:update()
		return ts.target
	end
end

function MaxRange()
	if Q:IsReady() then
		return SpellData.Q.range
	elseif W:IsReady() then
		return SpellData.W.range
	elseif E:IsReady() then
		return SpellData.E.range
	else
		return myHero.range + 50
	end
end
--}

--{Interrupt
function OnTargetInterruptable(unit,spell)
	if W:IsReady() and unit then
		SpellCast(_W,unit)
	end
end
--}

--{ Combo
assert(load(Base64Decode("G0x1YVIAAQQEBAgAGZMNChoKAAAAAAAAAAAAAQIDAAAAJQAAAAgAAIAfAIAAAQAAAAQKAAAAU3BlbGxDYXN0AAEAAAACAAAABQAAAAIACBkAAACBAAAAwUAAAAaBQAAbAQAAF4ADgAbBQAAHAUECB0FBAhsBAAAXQAKABkFBAEGBAQCLgQAAigGAg8dBwgCKwQGEHYGAAQyBQgIdQQABF8AAgAbBQgBAAQAAgAGAAB1BgAEfAIAADAAAAAQUAAAARW5jcnlwdGVkIGJ5IGJpbGJhbwAEEwAAAEFwcHJvdmVkIGJ5IEtsb2tqZQAECQAAAFZJUF9VU0VSAAQFAAAATWVudQAEBgAAAEV4dHJhAAQHAAAAUGFja2V0AAQHAAAAU19DQVNUAAQIAAAAc3BlbGxJZAAEEAAAAHRhcmdldE5ldHdvcmtJZAAECgAAAG5ldHdvcmtJRAAEBQAAAHNlbmQABAoAAABDYXN0U3BlbGwAAAAAAAEAAAAAABAAAABAb2JmdXNjYXRlZC5sdWEAGQAAAAIAAAACAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAFAAAABQAAAAUAAAAFAAAABQAAAAUAAAAFAAAABQAAAAUAAAAFAAAABQAAAAUAAAAFAAAABQAAAAUAAAAEAAAAAgAAAGEAAAAAABkAAAACAAAAYgAAAAAAGQAAAAIAAABjAAEAAAAZAAAAAgAAAGQAAgAAABkAAAABAAAABQAAAF9FTlYAAQAAAAEAEAAAAEBvYmZ1c2NhdGVkLmx1YQADAAAABQAAAAIAAAAFAAAAAAAAAAEAAAAFAAAAX0VOVgA="), nil, "bt", _ENV))()
-- Enemy in range of myHero
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

-- Credits: Feez
function isFacing(source, target, lineLength)
	local sourceVector = Vector(source.visionPos.x, source.visionPos.z)
	local sourcePos = Vector(source.x, source.z)
	sourceVector = (sourceVector-sourcePos):normalized()
	sourceVector = sourcePos + (sourceVector*(GetDistance(target, source)))
	return GetDistanceSqr(target, {x = sourceVector.x, z = sourceVector.y}) <= (lineLength and lineLength^2 or 90000)
end
-- End credits

function ComboMixed(UseR,target)
	if target == nil then return end
	local enemyPos = VP:GetPredictedPos(target,SpellData.W.delay)
	
	if os.clock() - LastFlashTime  < 1 and W:IsReady() then
		SpellCast(_W,target)
	else
		if DLib:IsKillable(target, {_Q}) and Q:IsReady() then
			SpellCast(_Q,target)
		elseif DLib:IsKillable(target, {_E}) and E:IsReady() then
			SpellCast(_E,target)
		elseif DLib:IsKillable(target, {_W}) and W:IsReady() then
			SpellCast(_W,target)
		elseif enemyPos ~= nil and GetDistanceSqr(myHero,enemyPos) >= SpellData.W.range * SpellData.W.range and not isFacing(target,myHero) then
			SpellCast(_W,target)
		else
			local comboDmg = DLib:CalcSpellDamage(target,__Q) * 2 + DLib:CalcSpellDamage(target,__W) + DLib:CalcSpellDamage(target,__E)
			if (Q:IsReady() and W:IsReady() and E:IsReady() and comboDmg > target.health) or (comboDmg > target.maxHealth) then 
				if Q:IsReady() then SpellCast(_Q,target)
				else if R:IsReady() and UseR then R:Cast() 
				else if W:IsReady()  then SpellCast(_W,target) 
				else if E:IsReady()  then SpellCast(_E,target) 
				end	end end end
			elseif math.abs(myHero.cdr) >= 0.2 then
				if CountEnemyInRange(target,300) > 1 then
					--Combo QRQEQWQ when 2 enemy near
					if LastCast == "Q" then
						if Q:IsReady()  then SpellCast(_Q,target) end
						if R:IsReady() and UseR then R:Cast() end
						if not (R:IsReady() and UseR) then SpellCast(_W,target) end
						if not (R:IsReady() and UseR) and not W:IsReady() then SpellCast(_E,target) end
					else
						SpellCast(_Q,target)
					end
				else
					--Combo QWQEQRQ when only one target
					if LastCast == "Q" then
						if Q:IsReady()  then SpellCast(_Q,target) end
						if W:IsReady() then SpellCast(_W,target) end
						if not W:IsReady() then	SpellCast(_E,target) end
						if not W:IsReady() and not E:IsReady() and UseR and R:IsReady() then R:Cast() end
					else
						if Q:IsReady() then SpellCast(_Q,target) end
					end
				end
			else
				--Combo QRWQEQ
				if Q:IsReady()  then SpellCast(_Q,target)
				else if R:IsReady() and UseR then R:Cast() 
				else if E:IsReady()  then SpellCast(_E,target) 
				else if W:IsReady()  then SpellCast(_W,target) 
				end	end end end
			end
		end
	end
end

function ComboBurst(UseR,target)
	if target == nil then return end
	local enemyPos = VP:GetPredictedPos(target,SpellData.W.delay)
	
	if os.clock() - LastFlashTime  < 1 and W:IsReady() then
		SpellCast(_W,target)
	else
		if DLib:IsKillable(target, {_Q}) and Q:IsReady() then
			SpellCast(_Q,target)
		elseif DLib:IsKillable(target, {_E}) and E:IsReady() then
			SpellCast(_E,target)
		elseif DLib:IsKillable(target, {_W}) and W:IsReady() then
			SpellCast(_W,target)
		elseif enemyPos ~= nil and GetDistanceSqr(myHero,enemyPos) >= SpellData.W.range * SpellData.W.range and not isFacing(target,myHero) then
			SpellCast(_W,target)
		else
			--Combo QRWQEQ
			if Q:IsReady()  then SpellCast(_Q,target)
			else if R:IsReady() and UseR then R:Cast() 
			else if E:IsReady()  then SpellCast(_E,target) 
			else if W:IsReady()  then SpellCast(_W,target) 
			end	end end end
		end
	end
end

function ComboLong(UseR,target)
	if target == nil then return end
	local enemyPos = VP:GetPredictedPos(target,SpellData.W.delay)
	
	if os.clock() - LastFlashTime  < 1 and W:IsReady() then
		SpellCast(_W,target)
	else
		if DLib:IsKillable(target, {_Q}) and Q:IsReady() then
			SpellCast(_Q,target)
		elseif DLib:IsKillable(target, {_E}) and E:IsReady() then
			SpellCast(_E,target)
		elseif DLib:IsKillable(target, {_W}) and W:IsReady() then
			SpellCast(_W,target)
		elseif enemyPos ~= nil and GetDistanceSqr(myHero,enemyPos) >= SpellData.W.range * SpellData.W.range and not isFacing(target,myHero) then
			SpellCast(_W,target)
		else
			if CountEnemyInRange(target,300) > 1 then
					--Combo QRQEQWQ when 2 enemy near
				if LastCast == "Q" then
					if Q:IsReady()  then SpellCast(_Q,target) end
					if R:IsReady() and UseR then R:Cast() end
					if not (R:IsReady() and UseR) then SpellCast(_W,target) end
					if not (R:IsReady() and UseR) and not W:IsReady()  then SpellCast(_E,target) end
				else
					SpellCast(_Q,target)
				end
			else
				--Combo QWQEQRQ when only one target
				if LastCast == "Q" then
					if Q:IsReady()  then SpellCast(_Q,target) end
					if W:IsReady() then SpellCast(_W,target) end
					if not W:IsReady() then	SpellCast(_E,target) end
					if not W:IsReady() and not E:IsReady() and UseR and R:IsReady() then R:Cast() end
				else
					if Q:IsReady() then SpellCast(_Q,target) end
				end
			end
		end
	end
end

--}


function OnTick10()
	local TARGET = GrabTarget()
	OW:DisableAttacks()
	if IsKeyDown(string.byte("X")) then
		OW:EnableAttacks()
	end
	--{ Combo
	
	if Menu.General.Combo and ValidTarget(TARGET) then
		
		if Menu.Combo.Item then 
			ItemManager:CastOffensiveItems(TARGET)
		end
		if Menu.Combo.Ignite and _IGNITE ~= nil then
			if DLib:IsKillable(TARGET, MainCombo) then
				CastSpell(_IGNITE, TARGET)
			end
		end
		if Menu.Combo.Mode == 1 then
			ComboMixed(Menu.Combo.R,TARGET)
		elseif Menu.Combo.Mode == 2 then
			ComboBurst(Menu.Combo.R,TARGET)
		elseif Menu.Combo.Mode == 3 then
			ComboLong(Menu.Combo.R,TARGET)
		end
		if not Q:IsReady() and not W:IsReady() then
			OW:EnableAttacks()
		end
	end
	--}
	
	--{ Harass
	if Menu.General.Harass then
		OW:EnableAttacks()
		if ValidTarget(TARGET) then
			if Menu.Harass.Q then
				SpellCast(_Q,TARGET)
			end
			if Menu.Harass.W then
				SpellCast(_W,TARGET)
			end
			if Menu.Harass.E then
				SpellCast(_E,TARGET)
			end
		end
	end
	--}
	
	--{ Farm/Jungle
	--Lane
	if Menu.General.Farm then
		OW:EnableAttacks()
		if Menu.General.Combo or Menu.General.Harass then return end
		--Lane
		EnemyMinion:update()
		if myHero.mana/myHero.maxMana * 100 > Menu.Farm.Mana and ValidTarget(EnemyMinion.objects[1],SpellData.Q.range) then
			if Menu.Farm.LQ and Q:IsReady() then 
				local delay = SpellData.Q.delay + GetDistance(EnemyMinion.objects[1].visionPos, myHero.visionPos) / SpellData.Q.speed - 0.07
				local predictedHealth = VP:GetPredictedHealth(EnemyMinion.objects[1], delay)
				if predictedHealth <= DLib:CalcSpellDamage(EnemyMinion.objects[1],_Q) and predictedHealth > 0 then
					SpellCast(_Q,EnemyMinion.objects[1])
				end
			end
			if Menu.Farm.LE and E:IsReady() then 
				if DLib:IsKillable(EnemyMinion.objects[1], {_E,_AA}) then 
					SpellCast(_E,EnemyMinion.objects[1])
				end
			end
			if Menu.Farm.LR and R:IsReady() then
				R:Cast()
			end
			if Menu.Farm.LW and W:IsReady() then 
				if DLib:IsKillable(EnemyMinion.objects[1], {_W}) then 
					SpellCast(_W,EnemyMinion.objects[1])
				end
			end			
		end
	end
	if Menu.General.Farm then
		--Jungle
		JungMinion:update()
		OW:EnableAttacks()
		if ValidTarget(JungMinion.objects[1],SpellData.Q.range) then
			if math.abs(myHero.cdr) >= 0.2 then
				if LastCast == "Q" then
					if Menu.Farm.JQ and Q:IsReady() then SpellCast(_Q,JungMinion.objects[1]) end
					if R:IsReady() and Menu.Farm.JR then R:Cast() end
					if not (R:IsReady() and Menu.Farm.JR) and Menu.Farm.JW then SpellCast(_W,JungMinion.objects[1]) end
					if not (R:IsReady() and Menu.Farm.JR) and not (W:IsReady() and Menu.Farm.JW) and Menu.Farm.JE then SpellCast(_E,JungMinion.objects[1]) end
				else
					SpellCast(_Q,JungMinion.objects[1])
				end
			else
				if Menu.Farm.JQ and Q:IsReady() then SpellCast(_Q,JungMinion.objects[1]) 
				else if Menu.Farm.JR and R:IsReady() then R:Cast()
				else if Menu.Farm.JE and E:IsReady() then SpellCast(_E,JungMinion.objects[1])
				else if Menu.Farm.JW and W:IsReady() then SpellCast(_W,JungMinion.objects[1])				
				end end end end
			end
		end
			
		if OW:CanAttack() and OW:InRange(JungMinion.objects[1])  then
			myHero:Attack(JungMinion.objects[1])
		end		
	end
	--}
	
	--{ Extra
	if Menu.Extra.AutoIgnite and ValidTarget(TARGET) then
		if _IGNITE ~= nil and DLib:IsKillable(TARGET, {_IGNITE}) then
			CastSpell(_IGNITE, TARGET)
		end
	end
	--}
end

function OnTick1()	
	--{ Auto level
	if Menu.Extra.AutoLevel == 2 then
		autoLevelSetSequence(maxQRWE)
	end
	--}
end

function OnProcessSpell(unit,spell)
	if unit.isMe then
		if spell.name:lower() == "overload" then
			LastCast = "Q"
		elseif spell.name:lower() == "runeprison" then
			LastCast = "W"
		elseif spell.name:lower() == "spellflux" then
			LastCast = "E"
		elseif spell.name:lower() == "desperatepower" then
			LastCast = "R"
		elseif spell.name:lower() == "summonerflash" then
			LastFlashTime = os.clock()
		end
	end
end

