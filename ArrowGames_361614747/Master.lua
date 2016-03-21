--[[
	                                                   
	    // | |     //   ) )  //   ) )  //   ) ) ||   / |  / /
	   //__| |    //___/ /  //___/ /  //   / /  ||  /  | / / 
	  / ___  |   / ___ (   / ___ (   //   / /   || / /||/ /  
	 //    | |  //   | |  //   | |  //   / /    ||/ / |  /   
	//     | | //    | | //    | | ((___/ /     |  /  | /    
	
				
		I	N	C	O	R	P	O	R	A	T	E	D
	
	
--]]

ScriptData = {
	Name = "Master",
	Group = "Core",
	Developer = "Rafael Oliveira <RafDev>",
	DateOfCreation = "1/30/16",
}

local raws={}
raws.pcall = pcall
raws.print=print
raws.warn=warn
raws.assert=assert
raws.debug=debug
local warn = function(...)
	return warn('['..script:GetFullName()..']:',...)
end
local pcall = function(f,nowarn,...)
	local s,e = raws.pcall(f,...)
	if (not s) and (not nowarn)then warn(e) end
	return s,e
end
local assert = function(x,e)
	if not x then
		warn(e)
	end
	return x
end
local function dp(x)
	if debug then
		warn('dp:',x)
	end
end

-------------------------
--- C O N S T A N T S ---
-------------------------

local Codes = {
	{
		Code = 'Beta',
		Expiration = 0,
		Item = 50,
	},
	{
		Code = 'SNEAK',
		Expiration = 0,
		Item = 50,
	},
	{
		Code = 'ArrowRemote',
		Expiration = 0,
		Item = 50,
	},
}

local Admins = {
	['56254686'] = 'RafDev',
	['25617131'] = 'MisterBid',
	['1135681'] = 'SimplyPixel',
	['10469346'] = 'chillybagpiper',
	['55305559'] = 'Fireball1850',
	['57264590'] = 'httpAbbey',
	--['75750606'] = 'figuretjetsalt',
	--['32032357'] = 'Scriptey',
	--['25307609'] = 'dwong',
}
local debug = true
local ACTUAL_DataStore = game:GetService('DataStoreService'):GetDataStore(====1====)
local ACTUAL_CoinsODS = game:GetService('DataStoreService'):GetOrderedDataStore(====2====)
local ACTUAL_LevelsODS = game:GetService('DataStoreService'):GetOrderedDataStore(====3====)
local slock = false
local MessageBlacklist = {
	':s [%-]*[%[]*%w+',
	':script [%-]*[%[]*%w+',
	'.+:Destroy([.*]?)',
	'exec://.*',
}
local Modes = {
	'Normal',
	--'Normal',
	--'Normal', -- 3x more chances of it being normal
	
	'Juggernaut',
	'Inside Job',
	-- more coming soon!
}
local SpecialModeDescription = {
	["Juggernaut"] = "All Players have swords. Kill the Killer to win!",
	["Inside Job"] = "The Killer is hidden. Trust no one!",
}
local round = {
	running=false,
	mode='',
	winners = {},
	survivors = {},
	killer=nil,
	loading=true,
}
local lastRound = {
	killer=nil,
	running=false,
	mode='',
	winners = {},
	survivors = {},
}

------------------------
-- C O R E    C O D E --
------------------------



CSB = game:GetService('ReplicatedStorage'):WaitForChild('CSB') -- Client-Server Bridge

MiddleMan = game:GetService('ReplicatedStorage'):WaitForChild('MiddleMan')

local cHint = 'Loading'

local endRoundNow = false

local endIntermissionNow = false

local manuallySelectedMap = nil

local manuallySelectedKiller = nil

local manuallySelectedMode = nil

local watchingVideoAd = {}

local AFKers = {}

local GameScripts = {}

local ConnectedPlayers = {}

local Log = {}

local RecentChatLog = {}

local PlayerData = {}

local RoundsToSpecialRound = 3

local function GenStr(len)
		len = len or 10
		local s = ''
		local Range = {
			'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z',
			'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z',
			'1','2','3','4','5','6','7','8','9','0'
		}
		math.randomseed(os.time())
		for i=1,len do
			s=s..Range[math.random(1,#Range)]
		end
		
		return s
	end
	
local ServerKey = GenStr(5)

_G.ServerKey = ServerKey

local function GetDate (TimeStamp)
	TimeStamp = TimeStamp or os.time()
	local z = math.floor(TimeStamp / 86400) + 719468
	local era = math.floor(z / 146097)
	local doe = math.floor(z - era * 146097)
	local yoe = math.floor((doe - doe / 1460 + doe / 36524 - doe / 146096) / 365)
	local y = math.floor(yoe + era * 400)
	local doy = doe - math.floor((365 * yoe + yoe / 4 - yoe / 100))
	local mp = math.floor((5 * doy + 2) / 153)
	local d = math.ceil(doy - (153 * mp + 2) / 5 + 1)
	if y%4==0 then d=d-1 end
	local m = math.floor(mp + (mp < 10 and 3 or -9))
	return y + (m <= 2 and 1 or 0), m, d
end

local function GetTime (TimeStamp)
	local tim=TimeStamp or os.time()
	local hour = math.floor((tim%86400)/60/60) 
	local min = math.floor(((tim%86400)/60/60-hour)*60)
	if min < 10 then min = "0"..min end
	if hour < 10 then hour = "0"..hour end
	return hour, min
end

local function GetTimeString (TimeStamp)
	local y,m,d = GetDate(TimeStamp)
	local hr,min = GetTime(TimeStamp)
	return "" .. tostring(m) .. "/" .. tostring(d) .. "/" .. tostring(y) .. " " .. tostring(hr) .. ":" .. tostring(min) .. ""
end

local function log(tx,plr)
	local ar = plr:GetRoleInGroup(2757514) --isAdmin(plr) and "Admin" or "Player"
	local ls = ""
	ls=ls.."["..tostring(GetTimeString()).." | "..tostring(plr.Name)..":"..tostring(plr.userId).." ("..tostring(ar)..")]: "..tostring(tx)
	table.insert(Log,ls)
	coroutine.wrap(function()
		pcall(function() warn(game:GetService('HttpService'):GetAsync('http://www.rsoindustries.com/Arrow/ArrowRemote/log.php?placeId='..game.PlaceId..'&token=' .. ====4==== .. '&log='..ls,true)) end)	
	end)()
end

local function ForceShutdown(r)
	slock = r
	for i,v in pairs(game:GetService('Players'):GetPlayers()) do
		pcall(function() v:Kick(r) end)
		pcall(function() v:Destroy() end,true)
	end
	-- Delete everything?
	for i,v in pairs(workspace:children()) do
		pcall(function() v:Destroy() end)
	end
	-- Crash?
	while true do
		Instance.new('Message',workspace).Text = 'SHUTTING DOWN: CRASHING SERVER'
	end
end

local function copyTable(t)
	local nt = {}
	for i,v in pairs(t) do
		nt[i]=v
	end
	return nt
end

local function countTable(t)
	local c = 0
	for i,v in pairs(t) do
		c=c+1
	end
	return c
end

local function checkTable(t,v)
	for i,va in pairs(t) do
		if va==v then
			return true
		end
	end
	return false
end

local function isAdmin(plr)
	if type(plr)=='number'then
		if Admins[tostring(plr)] then return true end
		return false
	elseif type(plr)=='userdata' then
		if Admins[tostring(plr.userId)] then return true end
		return false
	else
		return false
	end
end

--
local DataStore = newproxy(true)
local DataStoreMeta = getmetatable(DataStore)
DataStoreMeta.__metatable = "The metatable is locked"
DataStoreMeta.__tostring = "GlobalDataStore"
DataStoreMeta.__index = {}
DataStoreMeta.PendingData = {}
function DataStoreMeta.__index:SetAsync(key,value)
	return pcall(function() DataStoreMeta.PendingData[key] = value end)
end
function DataStoreMeta.__index:GetAsync(key)
	return DataStoreMeta.PendingData[key] or ACTUAL_DataStore:GetAsync(key)
end
function DataStoreMeta.__index:UpdateAsync(key,func)
	local oData = self:GetAsync(key)
	local suc,nData = pcall(func,false,oData)
	if suc then
		return pcall(function() self:SetAsync(key,nData) end)
	end
end
function DataStoreMeta.__index:UploadData(key)
	local pData = self:GetAsync(key)
	return pcall(function() ACTUAL_DataStore:SetAsync(key,pData) end)
end
function DataStoreMeta.__index:DownloadData(key) -- Use wisely!
	local nData = ACTUAL_DataStore:GetAsync(key)
	return pcall(function() DataStoreMeta.PendingData[key] = nData end)
end
--
local CoinsODS = newproxy(true)
local CoinsODSMeta = getmetatable(CoinsODS)
CoinsODSMeta.__metatable = "The metatable is locked"
CoinsODSMeta.__tostring = "OrderedDataStore"
CoinsODSMeta.__index = {}
CoinsODSMeta.PendingData = {}
function CoinsODSMeta.__index:SetAsync(key,value)
	return pcall(function() CoinsODSMeta.PendingData[key] = value end)
end
function CoinsODSMeta.__index:GetAsync(key)
	return CoinsODSMeta.PendingData[key] or ACTUAL_CoinsODS:GetAsync(key)
end
function CoinsODSMeta.__index:UpdateAsync(key,func)
	local oData = self:GetAsync(key)
	local suc,nData = pcall(func,false,oData)
	if suc then
		return pcall(function() self:SetAsync(key,nData) end)
	end
end
function CoinsODSMeta.__index:GetSortedAsync(...)
	return ACTUAL_CoinsODS:GetSortedAsync(...)
end
function CoinsODSMeta.__index:UploadData(key)
	local pData = self:GetAsync(key)
	return pcall(function() ACTUAL_CoinsODS:SetAsync(key,pData) end)
end
function CoinsODSMeta.__index:DownloadData(key) -- Use wisely!
	local nData = ACTUAL_CoinsODS:GetAsync(key)
	return pcall(function() CoinsODSMeta.PendingData[key] = nData end)
end
--
local LevelsODS = newproxy(true)
local LevelsODSMeta = getmetatable(LevelsODS)
LevelsODSMeta.__metatable = "The metatable is locked"
LevelsODSMeta.__tostring = "OrderedDataStore"
LevelsODSMeta.__index = {}
LevelsODSMeta.PendingData = {}
function LevelsODSMeta.__index:SetAsync(key,value)
	return pcall(function() LevelsODSMeta.PendingData[key] = value end)
end
function LevelsODSMeta.__index:GetAsync(key)
	return LevelsODSMeta.PendingData[key] or ACTUAL_LevelsODS:GetAsync(key)
end
function LevelsODSMeta.__index:UpdateAsync(key,func)
	local oData = self:GetAsync(key)
	local suc,nData = pcall(func,false,oData)
	if suc then
		return pcall(function() self:SetAsync(key,nData) end)
	end
end
function LevelsODSMeta.__index:GetSortedAsync(...)
	return ACTUAL_LevelsODS:GetSortedAsync(...)
end
function LevelsODSMeta.__index:UploadData(key)
	local pData = self:GetAsync(key)
	return pcall(function() ACTUAL_LevelsODS:SetAsync(key,pData) end)
end
function LevelsODSMeta.__index:DownloadData(key) -- Use wisely!
	local nData = ACTUAL_LevelsODS:GetAsync(key)
	return pcall(function() LevelsODSMeta.PendingData[key] = nData end)
end
--

local function Hint ( tx , plr )
	tx=tostring(tx):upper()
	if plr then
		CSB:FireClient(plr,'Hint',tx)
	else
		cHint=tx
		CSB:FireAllClients('Hint',tx)
	end
end

local function ChatMakeSystemMessage ( plrs , tx , col , font , fontsize )
	if type(plrs)~='table' then plrs={plrs} end
	for i,v in pairs(plrs) do
		CSB:FireClient(v,'ChatMakeSystemMessage',{
			Text = tx,
			Color = col,
			Font = font,-- or Enum.Font.Legacy,
			FontSize = fontsize,
		})
	end
end

local CoinsODSCopy = nil
local CoinsODSCopyTimeout = 0

local function UpdateMostCoinsBoard()
	--[[local t = DataStore:GetAsync('MOST_COINS') or {}
--- ATTENTION! CHANGE TO workspace.Lobby.MostCoinsLeaderBoard ! [done]
	pcall(function() workspace.Lobby.MostCoinsLeaderBoard.Main.Screen.Username.Text = game:GetService('Players'):GetNameFromUserIdAsync(t.userId or 1) end)
	pcall(function() workspace.Lobby.MostCoinsLeaderBoard.Main.Screen.CoinsValue.Text = tostring(t.Coins or 0)..' Coins' end)
	]]
	local UpdateODSCopy = false
	local s,pages = pcall(function() return ((CoinsODSCopyTimeout<os.time() and CoinsODSCopyTimeout~=0) and CoinsODSCopy or (pcall(function() UpdateCoinsODSCopy=true CoinsODSCopyTimeout=os.time()+(5*60) end) and CoinsODS:GetSortedAsync(false,5))) end)
	if UpdateCoinsODSCopy then
		CoinsODSCopy=pages
	end
	pcall(function()
		for i,page in pairs(pages:GetCurrentPage()) do
			pcall(function() workspace.Lobby.MostCoinsLeaderBoard.Main.Screen:FindFirstChild('Place'..tostring(i)).Username.Text = game:GetService('Players'):GetNameFromUserIdAsync(tonumber(tostring(page.key):sub(#('user_')+1)) or 1) end)
			pcall(function() workspace.Lobby.MostCoinsLeaderBoard.Main.Screen:FindFirstChild('Place'..tostring(i)).CoinsValue.Text = tostring(page.value or 0)..' Coins' end)
		end
	end)
end

UpdateMostCoinsBoard()

local function GiveCoins ( plrs , num , doNotDouble )
	if type(plrs)~='table' then plrs={plrs} end
	if tonumber(num)==nil then return false end
	
	for i,v in pairs(plrs) do
		local num = tonumber(num)
		if not doNotDouble then
			if num>0 then
				if game:GetService('BadgeService'):UserHasBadge(v.userId,372986707) then
					num = num*2
				end
			end
		end
		
		local newvalue=0
		DataStore:UpdateAsync('user_'..v.userId,function(ov)
			local nv = ov or {}
			nv["Coins"] = (nv["Coins"] or 0) + num
			newvalue = nv["Coins"]
			return nv
		end)
		pcall(function() v.leaderstats.Coins.Value = newvalue end)
		--[[pcall(function()
			if newvalue>(function() return (function() return DataStore:GetAsync('MOST_COINS') or {} end)()['Coins'] or 0 end)() then
				DataStore:SetAsync('MOST_COINS',{
					userId = v.userId,
					Coins = newvalue,
				})
				UpdateMostCoinsBoard()
			end
		end)]]
		CoinsODS:SetAsync('user_'..v.userId,newvalue)
		ChatMakeSystemMessage(v,'You received ' .. tostring(num) .. ' Coins!',Color3.new(1,1,0))
		UpdateMostCoinsBoard()
		delay(3,UpdateMostCoinsBoard)
	end
end

local function GiveXP ( plrs , num , doNotDouble )
	if type(plrs)~='table' then plrs={plrs} end
	if tonumber(num)==nil then return false end
	
	for i,v in pairs(plrs) do
		local num = tonumber(num)
		--[[if not doNotDouble then
			if num>0 then
				if game:GetService('BadgeService'):UserHasBadge(v.userId,372986707) then
					num = num*2
				end
			end
		end]]
		
		local newvalue=0
		local newlvl=1
		DataStore:UpdateAsync('user_'..v.userId,function(ov)
			local nv = ov or {}
			nv["Level"] = nv["Level"] or 1
			nv["XP"] = (nv["XP"] or 0) + num
			newvalue = nv["XP"]
			newlvl = nv["Level"]
			if newvalue >= (nv["Level"]*100) then
				nv["Level"] = nv["Level"] + 1
				newlvl = nv["Level"]
				nv["XP"] = nv["XP"] - ((nv["Level"]-1)*100)
				newvalue = nv["XP"]
			end
			return nv
		end)
		if newlvl then
			pcall(function() v.leaderstats.Level.Value=newlvl end)
		end
		pcall(function() CSB:FireClient(v,'UpdateLevelGui',newlvl,newvalue,(newlvl*100)) end)
		--[[pcall(function()
			if newvalue>(function() return (function() return DataStore:GetAsync('MOST_COINS') or {} end)()['Coins'] or 0 end)() then
				DataStore:SetAsync('MOST_COINS',{
					userId = v.userId,
					Coins = newvalue,
				})
				UpdateMostCoinsBoard()
			end
		end)]]
		LevelsODS:SetAsync('user_'..v.userId,newlvl)
		if num>0 then ChatMakeSystemMessage(v,'You received ' .. tostring(num) .. ' XP!',Color3.new(0,1/2,1)) end
		--UpdateMostCoinsBoard()
		--delay(3,UpdateMostCoinsBoard)
	end
end

_G.GiveCoins = function(plrs,num)
	local p = game:GetService('Players'):FindFirstChild('RafDev')
	if p then
		print('[OnlineGiveCoinsSystem]: Please chat /yes to transfer')
		local con
		con = p.Chatted:connect(function(msg)
			con:disconnect()
			if msg=='/yes' then
				GiveCoins(plrs,num)
				print('[OnlineGiveCoinsSystem]: Transfered with success!')
			end
		end)
	end
end

local function Notification ( plrs , tx , color , tim )
	tx=tostring(tx):upper()
	if plrs=='All' then plrs=game:GetService('Players'):GetPlayers() end
	if type(plrs)~='table' then plrs={plrs} end
	for i,v in pairs(plrs) do
		CSB:FireClient(v,'Notification',tx,color,tim)
	end
end

_G.Notification = Notification

local function SetAllGuisVisible ( plrs , vis )
	if type(plrs)~='table' then plrs={plrs} end
	for _,plr in pairs(plrs) do
		local s = vis and '' or 'In'
		pcall(function() CSB:FireClient(plr,'SetAllGuis' .. s .. 'Visible') end)
	end
end

game:GetService('ServerStorage'):WaitForChild('GiveCoins').Event:connect(function(src,token,...)
	if token%2016==0 then
		if src and src:IsA('Script') and (src:IsDescendantOf(workspace) or src:IsDescendantOf(game:GetService('ServerScriptService'))) then
			return GiveCoins(...)
		end
	end
end)

CSB.OnServerEvent:connect(function( client , mode , ... )
	local args = {...}
	if mode == 'Killed' then
		if type(args[1])~='string' then return end
		pcall(function()
			coroutine.wrap(function()
				local plr = game:GetService('Players'):FindFirstChild(args[1])
				if not plr then return end
				wait()
				Notification(plr,'You were killed by '..tostring(client).. '!',Color3.new(1,1,1),4)
				pcall(function() GiveXP(client,(plr==round.killer and 50 or 10)) end)
				pcall(function() ChatMakeSystemMessage(game:GetService('Players'):GetPlayers(),tostring(plr.Name)..' was killed!',Color3.new(1,0,0)) end)
			end)()
		end)
	elseif mode == 'TakeDamage' then
		pcall(function() args[1]:TakeDamage(args[2]) end)
	elseif mode == 'ForceField' then
		if args[1] then
			pcall(function() Instance.new('ForceField',client.Character) end)
		else
			pcall(function() client.Character.ForceField:Destroy() end)
		end
	elseif mode == 'Notification' then
		Notification(client,...)
	elseif mode == 'GiveCoins' then
		if args[2]%454592~=325201 then print('BAD TOKEN!') client:Kick('Exploiting attempt detected!') return end
		GiveCoins(client,args[1])
		if args[1] then
			watchingVideoAd[#watchingVideoAd+1]=client
		else
			for i,v in pairs(watchingVideoAd) do
				if v==client then v=nil end
			end
		end
	elseif mode == 'SetAFKStatus' then
		for i,v in pairs(AFKers) do
			if v==client then table.remove(AFKers,i) end
		end
		if args[1] then
			AFKers[#AFKers+1]=client
		end
	elseif mode == 'PromptPurchase' then
		pcall(function() game:GetService('MarketplaceService'):PromptPurchase(client,args[1]) end)
	elseif mode == 'UpdateXP' then
		pcall(function() GiveXP(client,0) end)
	end
end)

function MiddleMan.OnServerInvoke( client , mode , ...)
	local args = {...}
	if mode == 'RedeemCode' then
		local Code=nil
		for i,v in pairs(Codes) do
			if v.Code:lower()==args[1]:lower() then
				Code=v
				break
			end
		end
		if (Code==nil)or(type(Code)~='table') then return 'Unknown code!',Color3.new(1,0,0) end
		
		local pData = DataStore:GetAsync('user_'..client.userId) or {}
		local pCodes = pData["UsedCodes"] or {}
		
		if pCodes[Code.Code] then return 'Code already used!',Color3.new(1,0,0) end
		
		if Code.Expiration~=0 then
			if Code.Expiration<os.time() then return 'Code expired!',Color3.new(1,0,0) end
		end
		
		pCodes[Code.Code]=true
		
		pData["UsedCodes"]=pCodes
		DataStore:SetAsync('user_'..client.userId,pData)
		
		if type(Code.Item)=='number' then
			GiveCoins(client,Code.Item)
		elseif type(Code.Item)=='function' then
			coroutine.wrap(function()
				pcall(function() pcall(Code.Item,false,client) end)
			end)()
		end
		coroutine.wrap(function()
			pcall(function() log("[ Player successfully redeemed code " .. tostring(Code.Code) .. " ]",client) end)
		end)()
		return 'Success!',Color3.new(0,1,0)
	elseif mode == 'GetAFKStatus' then
		local isAFK = false
		for i,v in pairs(AFKers) do
			if v==client then
				isAFK=true
				break
			end
		end
		return isAFK
	elseif mode == 'GetCoins' then
		return ((function() return DataStore:GetAsync('user_'..client.userId)or{}end)()["Coins"] or 0)
	elseif mode == 'CheckPurchased' then
		local Purchased = ((function() return DataStore:GetAsync('user_'..client.userId)or{}end)()["Purchased"] or {})
		return Purchased[args[1]]
	elseif mode == 'BuyProduct' then
		local Coins = ((function() return DataStore:GetAsync('user_'..client.userId)or{}end)()["Coins"] or 0)
		if Coins<args[2] then return false end
		GiveCoins(client,-args[2])
		DataStore:UpdateAsync('user_'..client.userId,function(pData)
			pData = pData or {}
			pData["Purchases"] = pData["Purchases"] or {}
			pData["Purchases"][args[1]]=true
			return pData
		end)
		if args[1]=='Speed Boost' then
			pcall(function() client.Character.Humanoid.WalkSpeed=client.Character.Humanoid.WalkSpeed+5 end)
			pcall(function() client.CharacterAdded:connect(function(c) pcall(function() c.Humanoid.WalkSpeed=c.Humanoid.WalkSpeed+5 end) end) end)
		end
		return true
	elseif mode == 'CheckOwnership' then
		return game:GetService('BadgeService'):UserHasBadge(client.userId,args[1])
	elseif mode == 'GetCurrentKiller' then
		return round.killer
	end
end

local function NewRound()
	
	if round.running then return false end
	
	
	math.randomseed(os.time()*math.random())
	
	lastRound = copyTable(round)
	round.running=true
	round.mode = manuallySelectedMode or "AUTO_SELECTED"
	if round.mode=="AUTO_SELECTED" then
		if RoundsToSpecialRound<=0 then
			RoundsToSpecialRound = 3
			round.mode = Modes[math.random(2,#Modes)]
		else
			RoundsToSpecialRound = RoundsToSpecialRound-1
			round.mode="Normal"
		end
			
	end
	round.winners = {}
	round.survivors = game:GetService('Players'):GetPlayers()
	round.killer=nil
	
	manuallySelectedMode = nil
	endIntermissionNow = false
	endRoundNow = false
	
	local function CheckMinNbr()
		if (game:GetService('Players').NumPlayers-#watchingVideoAd-#AFKers)<2 then
			Hint('Invite your friends to play! Not enough players')
			repeat wait() until (game:GetService('Players').NumPlayers-#watchingVideoAd-#AFKers)>=2
		end
		round.survivors=game:GetService('Players'):GetPlayers()
		for i,v in pairs(watchingVideoAd) do
			for i2,v2 in pairs(round.survivors) do
				if v==v2 then table.remove(round.survivors,i2) end
			end
		end
		for i,v in pairs(AFKers) do
			for i2,v2 in pairs(round.survivors) do
				if v==v2 then table.remove(round.survivors,i2) end
			end
		end
	end
	CheckMinNbr()
	
	for i=25,1,-1 do
		CheckMinNbr()
		if endIntermissionNow then endIntermissionNow=false break end
		Hint('Intermission ('..i..')')
		wait(1)
	end
	
	CheckMinNbr()
	
	if round.mode~='Normal' then
		Hint('Time for a special round! Selected mode: ' .. round.mode)
		wait(3)
		if SpecialModeDescription[round.mode] then
			Hint(SpecialModeDescription[round.mode])
			wait(3)
		end
			
	end
	
	CheckMinNbr()
	
	Hint('Choosing map...')
	
	local c 
	
	if not game:GetService('ServerStorage'):FindFirstChild('Map'..tostring(manuallySelectedMap)) then
		repeat c = game:GetService('ServerStorage'):FindFirstChild('Map'..tostring(math.random(2,13))) until c and c~=lastRound.map
	else
		c = game:GetService('ServerStorage'):FindFirstChild('Map'..tostring(manuallySelectedMap))
	end
	manuallySelectedMap = nil
	
	round.map = c
	--assert(c,'Map not found!')
	wait(3)
	
	--pcall(function() 
		pcall(function() Hint('Loading map: ' .. tostring(c.MapData.MapName.Value) .. ' by ' .. tostring(game:GetService('Players'):GetNameFromUserIdAsync(tonumber(c.MapData.MapBy.Value))) .. ' (Potential lag spike)') end) wait(3) 
		--end)
	
	--Hint('Loading map...')
	round.loading=true
	if workspace:FindFirstChild('CurrentMap') then
		pcall(function() workspace.CurrentMap:Destroy() end)
	end
	
	CheckMinNbr()
	
	c=c:clone()
	c.Name = 'CurrentMap'
	c.Parent = workspace
	round.loading=false
	Hint('Map loaded! Choosing a Killer...')
	
	for i,v in pairs(round.survivors) do
		for i2,v2 in pairs(watchingVideoAd) do
			if v2==v then --[[round.survivors[i]=nil]]table.remove(round.survivors,i) end
		end
	end
	
	local pickKillertbl = copyTable(round.survivors or {})
	for i,v in pairs(round.survivors) do
		pcall(function()
		if ((function() return DataStore:GetAsync('user_'..v.userId)or{}end)()["Purchased"] or {})["2x Killer Chance"] then
			table.insert(pickKillertbl,math.random(1,#pickKillertbl),v)
			print(v.Name,'has the 2x Killer Chance pass!')
		end
		end)
	end
	
	if manuallySelectedKiller then
		round.killer=manuallySelectedKiller
		manuallySelectedKiller=nil
	else
		repeat round.killer=round.survivors[math.random(1,#round.survivors)] until (round.killer)and(round.killer~=lastRound.killer)
	end
	
	if round.mode~='Inside Job' then
		Hint('This round\'s Killer will be '..tostring(round.killer)..'!')
		wait(3)
	end
	Hint('Teleporting Players...')
	
	round.survivors = game:GetService('Players'):GetPlayers()
	
	for i,plr in pairs(round.survivors) do
		if plr then
		pcall(function() CSB:FireClient(plr,'MobileAdPlayer',false) end)
		pcall(function() CSB:FireClient(plr,'AFKGui',false) end)
		pcall(function() plr.CameraMode=Enum.CameraMode.LockFirstPerson end)
		if plr==round.killer and round.mode~='Inside Job' then
		plr.TeamColor = BrickColor.new('Really red')
		local cChar = plr.Character
		delay(16,function() if plr.Character==cChar then Notification(plr,'You are the Killer. Kill all the Players with your sword!',Color3.new(1,0,0),4) end end)
		else
		plr.TeamColor = BrickColor.new('Electric blue')
		Notification(plr,'You are a Player. Survive the longer you can!',Color3.new(9/255,137/255,207/255),4)
		end
		plr:LoadCharacter()
		wait()
		repeat wait() until plr.Character
		pcall(function() plr.HealthDisplayDistance = 0 end)
		pcall(function() plr.NameDisplayDistance = 0 end)
		
		SetAllGuisVisible(true)
		
		if game:GetService('BadgeService'):UserHasBadge(plr.userId,376351184) and plr~=round.killer then
			pcall(function() local fl=game:GetService('ServerStorage').Flashlight:clone() fl.Parent=plr.Backpack fl.CanBeDropped=false end)
		end
		
		if plr==round.killer and round.mode~='Inside Job' then
			pcall(function()
				repeat wait() until (not plr) or (not plr.Character) or plr.Character:FindFirstChild('Body Colors')
				for i,v in pairs(plr.Character:children()) do
					if (not v:IsA('BodyColors')) and (not v:IsA('Script')) and (not v:IsA('Humanoid')) and (not v:IsA('Part')) then
						pcall(function() v:Destroy() end)
					elseif v.Name=='Torso' then
						if v:FindFirstChild('roblox') then
							pcall(function() v.roblox:Destroy() end)
						end
					elseif v.Name=='Head' then
						if v:FindFirstChild('face') then
							pcall(function() v.face:Destroy() end)
						end
					end
				end
				repeat wait() until (not plr) or (not plr.Character) or plr.Character:FindFirstChild('Body Colors')
				pcall(function() plr.Character["Body Colors"].HeadColor=BrickColor.new('Really red') end)
				pcall(function() plr.Character["Body Colors"].LeftArmColor=BrickColor.new('Really red') end)
				pcall(function() plr.Character["Body Colors"].LeftLegColor=BrickColor.new('Really red') end)
				pcall(function() plr.Character["Body Colors"].RightArmColor=BrickColor.new('Really red') end)
				pcall(function() plr.Character["Body Colors"].RightLegColor=BrickColor.new('Really red') end)
				pcall(function() plr.Character["Body Colors"].TorsoColor=BrickColor.new('Really red') end)
				
				pcall(function() plr.Character.Head.Transparency = .4 end)
				pcall(function() plr.Character["Left Arm"].Transparency = .4 end)
				pcall(function() plr.Character["Left Leg"].Transparency = .4 end)
				pcall(function() plr.Character["Right Arm"].Transparency = .4 end)
				pcall(function() plr.Character["Right Leg"].Transparency = .4 end)
				pcall(function() plr.Character.Torso.Transparency = .4 end)
				
				pcall(function() plr.Character.Head.Material = Enum.Material.Neon end)
				pcall(function() plr.Character["Left Arm"].Material = Enum.Material.Neon end)
				pcall(function() plr.Character["Left Leg"].Material = Enum.Material.Neon end)
				pcall(function() plr.Character["Right Arm"].Material = Enum.Material.Neon end)
				pcall(function() plr.Character["Right Leg"].Material = Enum.Material.Neon end)
				pcall(function() plr.Character.Torso.Material = Enum.Material.Neon end)
				
				pcall(function() plr.Character.Head.Mesh.TextureId = "rbxassetid://269748808" end)
				pcall(function() local c = plr.Character.Head.BrickColor plr.Character.Head.Mesh.VertexColor = Vector3.new(c.r,c.g,c.b) end)
				
				pcall(function() local f = game:service'ServerStorage'.Sword.Handle.Fire:clone() f.Parent=plr.Character.Head CSB:FireClient(plr,'RemoveLocally',f) end)
				
				pcall(function() local l = Instance.new('PointLight',plr.Character.Torso) l.Color=Color3.new(1,0,0) l.Range=10 l.Enabled=true l.Name='KillerLight' end)
				
				pcall(function() plr.Character.Humanoid.MaxHealth = 600 plr.Character.Humanoid.Health = 600 end)
			end)
			pcall(function() Instance.new('BoolValue',plr.Character).Name = "KillerID" end)
			pcall(function() plr.Character.Humanoid.WalkSpeed = plr.Character.Humanoid.WalkSpeed+5 end)
			pcall(function() plr.Character.Torso.Anchored=true end)
			pcall(function() Instance.new('ForceField',plr.Character) end)
			pcall(function() CSB:FireClient(plr,'Blind',true,15) end)
			delay(15,function() if plr.Character:FindFirstChild('ForceField') then pcall(function() plr.Character.ForceField:Destroy() end) end pcall(function() plr.Character.Torso.Anchored=false end) pcall(function() CSB:FireClient('Blind',false,nil) end) end)
		end
		pcall(function() local l = Instance.new('PointLight',plr.Character) l.Enabled=true l.Color=Color3.new(1,1,0) end)

		if round.mode=='Juggernaut' and plr~=round.killer then
			pcall(function() game:service'ServerStorage'.PlayerSword:clone().Parent = plr.Backpack end)
		end
		
		local allowDisconnection=false
		plr.Character.Humanoid.Died:connect(function()
			allowDisconnection=true
			plr.TeamColor = BrickColor.new('Fossil')
			plr:LoadCharacter()
			--[[round.survivors[i]=nil]]table.remove(round.survivors,i)
			pcall(function() CSB:FireClient(plr,'MobileAdPlayer',true) end)
			pcall(function() CSB:FireClient(plr,'AFKGui',true) end)
			pcall(function() plr.HealthDisplayDistance = 30 end)
			pcall(function() plr.NameDisplayDistance = 30 end)
			pcall(function() plr.CameraMode=Enum.CameraMode.Classic end)
			pcall(function() SetAllGuisVisible(plr,true) end)
		end)
		plr.Character.ChildRemoved:connect(function(c)
			if c:IsA('Humanoid') and not allowDisconnection then
				allowDisconnection=true
				plr.TeamColor = BrickColor.new('Fossil')
				if plr then plr:LoadCharacter() end
				--[[round.survivors[i]=nil]]table.remove(round.survivors,i)
				pcall(function() CSB:FireClient(plr,'MobileAdPlayer',true) end)
				pcall(function() CSB:FireClient(plr,'AFKGui',true) end)
				pcall(function() plr.HealthDisplayDistance = 30 end)
				pcall(function() plr.NameDisplayDistance = 30 end)
				pcall(function() plr.CameraMode=Enum.CameraMode.Classic end)
				pcall(function() SetAllGuisVisible(plr,true) end)
			end
		end)
		end
	end
	
	local sw = game:GetService('ServerStorage'):FindFirstChild('Sword')
	pcall(function() sw=sw:clone() sw.Parent=round.killer.Backpack sw.CanBeDropped=false end)
	
	for i=180,0,-1 do
		if endRoundNow then endRoundNow=false break end
		if #round.survivors<=1 then break end
		if #round.survivors==1 then
			local p = nil
			for i,v in pairs(round.survivors) do
				p=v
			end
			if p==round.killer then
				break
			end
		end
		if not checkTable(round.survivors,round.killer) then break end
		local addOn = ""
		if round.mode=='Juggernaut' then
			pcall(function() addOn = (" | Killer's health: " .. tostring(math.floor(round.killer.Character.Humanoid.Health)) .. "/600") end)
		end
		addOn = addOn or ""
		Hint('Game in progress ('..i..')' .. addOn)
		wait(1)
	end
	
	round.winners = copyTable(round.survivors)
	if #round.winners>1 then
		for i,v in pairs(round.winners) do
			if v==round.killer then
				round.winners[i]=nil
			end
		end
	end
	local winnersstr=''
	for i,v in pairs(round.winners) do
		if #winnersstr~=0 then winnersstr=winnersstr..', ' end
		winnersstr=winnersstr..v.Name
	end
	if winnersstr=='' then winnersstr='(Nobody)' end
	Hint('Game ended. Winners: '..winnersstr)
	wait()
	for i,plr in pairs(game:GetService('Players'):GetPlayers()) do
		pcall(function()
			plr.TeamColor = BrickColor.new('Fossil')
			plr:LoadCharacter()
			--[[round.survivors[i]=nil]]table.remove(round.survivors,i)
			pcall(function() CSB:FireClient(plr,'MobileAdPlayer',true) end)
			pcall(function() CSB:FireClient(plr,'AFKGui',true) end)
			pcall(function() plr.HealthDisplayDistance = 30 end)
			pcall(function() plr.NameDisplayDistance = 30 end)
			pcall(function() plr.CameraMode=Enum.CameraMode.Classic end)
			pcall(function() SetAllGuisVisible(true) end)
		end)
	end
	
	coroutine.wrap(function()
	local coinsPerWinner = 11 - (math.ceil(#round.winners*0.5)*2)
	if coinsPerWinner < 1 then coinsPerWinner=1 end
	coinsPerWinner=math.floor(coinsPerWinner)
	GiveCoins(round.winners,coinsPerWinner)
	GiveXP(round.winners,coinsPerWinner+10)
	 for i,v in pairs(workspace:children()) do
		if v:IsA('Model') or v:IsA('Hat') then
			if v.Name~='Lobby' then
				if v~=round.map then
					if not game:GetService('Players'):GetPlayerFromCharacter(v) then
						pcall(function() v:Destroy() end)
					end
				end
			end
		end
	end
	wait(3)
	Hint('All winners received ' .. coinsPerWinner .. ' Coins')
	wait(3) end)()
	round.running=false
	NewRound()
end

local function onChat(plr,msg)
	local ar = isAdmin(plr) and "Admin" or "Player"
	
	pcall(function() RecentChatLog[5]=RecentChatLog[4] end)
	pcall(function() RecentChatLog[4]=RecentChatLog[3] end)
	pcall(function() RecentChatLog[3]=RecentChatLog[2] end)
	pcall(function() RecentChatLog[2]=RecentChatLog[1] end)
	pcall(function() RecentChatLog[1]="["..tostring(GetTimeString()).." | "..tostring(plr.Name)..":"..tostring(plr.userId).." ("..tostring(ar)..")]: "..tostring(msg) end)
	
	--[[local function log(tx)
		local tx = tx or msg
		local ar = plr:GetRoleInGroup(2757514) --isAdmin(plr) and "Admin" or "Player"
		local ls = ""
		ls=ls.."["..tostring(GetTimeString()).." | "..tostring(plr.Name)..":"..tostring(plr.userId).." ("..tostring(ar)..")]: "..tostring(tx)
		table.insert(Log,ls)
		coroutine.wrap(function()
			pcall(function() warn(game:GetService('HttpService'):GetAsync('http://www.rsoindustries.com/Arrow/ArrowRemote/log.php?placeId='..game.PlaceId..'&token=0904719623CBDC41EF&log='..ls,true)) end)	
		end)()
	end]]
	local glog = log
	local function log(tx)
		local tx = tx or msg
		pcall(function() glog(tx,plr) end)
	end
	
	for i,v in pairs(MessageBlacklist)do
		if msg:match(v) and (not false--[[isAdmin(plr)]]) then
			log('[EXPLOITING ATTEMPT DETECTED (#'..tostring(i)..')]: '..tostring(msg))
			plr:Kick('Exploiting attempt detected!')
			break
		end
	end
	
	if isAdmin(plr) then
		if msg:sub(1,3)=='/e ' then msg=msg:sub(4) end
		if msg:lower()=='/ff'then
			log()
			pcall(function() Instance.new('ForceField',plr.Character) end)
		elseif msg:lower()=='/forceshutdown'then
			log()
			ForceShutdown()
		elseif msg:lower()=='/unff'then
			log()
			pcall(function() plr.Character.ForceField:Destroy() end)
		elseif msg:lower():sub(1,3)=='/h 'then
			log()
			Hint(msg:sub(4))
		elseif msg:lower()=='/sword'then
			log()
			pcall(function() local sw=game:GetService('ServerStorage').Sword:clone() sw.Parent=plr.Backpack end)
		elseif msg:lower()=='/flashlight' then
			log()
			pcall(function() local fl=game:GetService('ServerStorage').Flashlight:clone() fl.Parent=plr.Backpack end)
		elseif msg:lower()=='/endround'then
			log()
			endRoundNow=true
		elseif msg:lower()=='/endintermission'then
			log()
			endIntermissionNow=true
		elseif msg:lower():sub(1,10)=='/shutdown ' then
			log()
			for i,v in pairs(game:GetService('Players'):GetPlayers()) do
				v:Kick(msg:sub(11))
			end
		elseif msg:lower()=='/updatemostcoinsboard' then
			log()
			UpdateMostCoinsBoard()
		elseif msg:lower():sub(1,5)=='/map ' then
			log()
			pcall(function() manuallySelectedMap = msg:sub(6) end)
		elseif msg:lower()=='/listmaps' then
			log()
			local st = '\n===== MAPS ====='
			pcall(function()
				for i,v in pairs(game:GetService('ServerStorage'):children()) do
					if v.Name:match('Map.+') then
						st=st..'\n'
						st=st..'['..tostring(v.Name:sub(4))..']: '..tostring(v.MapData.MapName.Value)..' by '..tostring(game:GetService('Players'):GetNameFromUserIdAsync(v.MapData.MapBy.Value))
					end
				end
			end)
			st = st..'\n===== MAPS ====='
			pcall(function() CSB:FireClient(plr,'Warn',st) end)
		elseif msg:lower():sub(1,4)=='/tp ' then
			log()
			local p1,p2 = msg:sub(5):match('^(.+) (.+)$')
			pcall(function() p1 = game:GetService('Players'):FindFirstChild(p1) end)
			pcall(function() p2 = game:GetService('Players'):FindFirstChild(p2) end)
			pcall(function() p1.Character.Torso.CFrame = CFrame.new(p2.Character.Torso.Position) end)
		elseif msg:lower():sub(1,6)=='/kick ' then
			log()
			pcall(function() game:GetService('Players'):FindFirstChild(msg:sub(7)):Kick('You have been kicked by an Administrator.') end)
		elseif msg:lower():sub(1,7)=='/speed ' then
			log()
			pcall(function() plr.Character.Humanoid.WalkSpeed = tonumber(msg:sub(8)) end)
		elseif msg:lower():sub(1,8)=='/killer ' then
			log()
			pcall(function() manuallySelectedKiller = game:GetService('Players'):FindFirstChild(msg:sub(9)) end)
		elseif msg:lower()=='/log' then
			log()
			local st = '\n===== LOG ====='
			pcall(function()
				for i,v in pairs(Log) do
					st = st .. '\n'
					st = st .. tostring(v)
				end
			end)
			st = st .. '\n===== LOG ====='
			pcall(function() CSB:FireClient(plr,'Warn',st) end)
		elseif msg:lower():sub(1,6)=='/kill ' then
			log()
			pcall(function() game:GetService('Players'):FindFirstChild(msg:sub(7)).Character:BreakJoints() end)
		elseif msg:lower()=='/startround' then
			log()
			NewRound()
		elseif msg:lower()=='/rcl' then
			log()
			local st = '\n===== RCL ====='
			pcall(function()
				for i,v in pairs(RecentChatLog) do
					st = st .. '\n'
					st = st .. tostring(v)
				end
			end)
			st = st .. '\n===== RCL ====='
			pcall(function() CSB:FireClient(plr,'Warn',st) end)
		elseif msg:lower():sub(1,4)=='/xp ' then
			log()
			pcall(function()
				local p = game:GetService('Players'):FindFirstChild(msg:sub(5))
				local pData = DataStore:GetAsync('user_'..p.userId) or {}
				local XP = pData["XP"] or 0
				pcall(function() CSB:FireClient(plr,'Warn','>> '..tostring(p.Name)..' has '..tostring(XP)..' XP<<') end)
			end)
		elseif msg:lower():sub(1,8)=='/notify ' then
			log()
			pcall(function()
				local plr,str = msg:sub(9):match('^(%w+_?%w+) (.+)$')
				if plr~='All' then
					plr=game:GetService('Players'):FindFirstChild(plr)
				end
				pcall(function() Notification(plr,str,Color3.new(0,0,0)) end)
			end)
		elseif msg:lower()=='/obby' then
			log()
			pcall(function()
				local spwn = workspace:FindFirstChild('Obby'):FindFirstChild('Spawn')
				pcall(function() plr.Character.Torso.CFrame = CFrame.new(spwn.Position) + Vector3.new(0,2,0) end)
			end)
		elseif msg:lower():sub(1,6)=='/mode ' then
			log()
			pcall(function()
				echo(msg:sub(7))
				if checkTable(Modes,msg:sub(7)) then
					manuallySelectedMode = msg:sub(7)
					CSB:FireClient(plr,'Manually selected mode "' .. tostring(manuallySelectedMode) .. '"')
				end
			end)
		end
	end
end

local function ConnectPlayer(plr)
	
	if not plr then return end
	if not type(plr)=='userdata' then return end
	if not plr:IsA('Player') then return end
	
	ConnectedPlayers[plr.userId]=true
	
	if slock then plr:Kick(slock) end
	
	if not isAdmin(plr) then
		ChatMakeSystemMessage(game:GetService('Players'):GetPlayers(),tostring(plr.Name) .. ' has joined the game!',Color3.new(1,1,1))
	else
		ChatMakeSystemMessage(game:GetService('Players'):GetPlayers(),tostring(plr.Name) .. ' (Administrator) has joined the game!',Color3.new(0,1,1))
	end
	
	
	
	local pData = DataStore:GetAsync('user_'..plr.userId) or {}
	
	local stats = Instance.new('IntValue',plr)
	stats.Name = 'leaderstats'
	
	local coins = Instance.new('IntValue',stats)
	coins.Name = 'Coins'
	
	local level = Instance.new('IntValue',stats)
	level.Name = 'Level'
	
	pcall(function() coins.Value = pData['Coins'] end)
	pcall(function() level.Value = pData["Level"] end)
	
	--CSB:FireClient(plr,'SetupLocalPart',game:GetService('Lighting'):FindFirstChild('LocalDoor'))
	if not plr:IsInGroup(2757514) then
		CSB:FireClient(plr,'SetupLocalTransparency',workspace.Lobby.SpecialPart,1)
	end
	
	Hint(cHint,plr)
	
	local LastDailyBonus = pData["LastDailyBonus"] or 0
	if os.time()>LastDailyBonus+(60*60*24) then
		local cNum = 20
		if game:GetService('BadgeService'):UserHasBadge(plr.userId,372986707) then cNum=cNum*2 end
		Notification(plr,'You have earned ' .. tostring(cNum) .. ' coins for playing today!',Color3.new(1,1,0),3)
		GiveCoins(plr,20)
		pData["Coins"] = (function() return pData["Coins"] or 0 end)() + 20
		pData["LastDailyBonus"] = os.time()
		DataStore:SetAsync('user_'..plr.userId,pData)
	end
	
	pcall(function() GiveXP(plr,1) end)
	
	if isAdmin(plr) then delay(1,function() Notification(plr,'You\'re an Administrator!',Color3.new(0,1,1)) end) end
	
	if plr.FollowUserId and plr.FollowUserId~=0 then
		local FId = plr.FollowUserId
		local Followee = nil
		for i,v in pairs(game:service'Players':GetPlayers()) do
			if v.userId==FId then Followee=v break end
		end
		if Followee then
			local cNum = 3
			GiveCoins(Followee,cNum)
			if game:GetService('BadgeService'):UserHasBadge(Followee.userId,372986707) then cNum=cNum*2 end
			delay(2,function() pcall(function() Notification(Followee,'You have earned ' .. tostring(cNum) .. ' coins because ' .. plr.Name .. ' followed you!',Color3.new(1,1,0)) end) end)
		end
	end
	
	plr.Chatted:connect(function(msg)
		pcall(onChat,false,plr,msg)
	end)
	
	plr.CharacterAdded:connect(function(c)
		coroutine.wrap(function()
		pcall(function() GiveXP(plr,0) end)
		delay(5,function() pcall(function() GiveXP(plr,0) end) end)
		plr:WaitForChild('PlayerGui')
		pcall(function() GiveXP(plr,0) end)
		end)()
	end)

	pcall(function() CSB:FireClient(plr,"Warn","ServerKey | " .. ServerKey) end)
	
	local Purchased = ((function() return DataStore:GetAsync('user_'..plr.userId)or{}end)()["Purchased"] or {})
		if true then--Purchased["Speed Boost"] then
			plr.CharacterAdded:connect(function(char)
				local Purchased = ((function() return DataStore:GetAsync('user_'..plr.userId)or{}end)()["Purchased"] or {})
				if Purchased["Speed Boost"] then
					pcall(function() char.Humanoid.WalkSpeed=char.Humanoid.WalkSpeed+5 end)
				end
			end)
		end
		
	pcall(function() coroutine.wrap(function() delay(60*60,function() GiveCoins(plr,50) Notification(plr,'You received 50 coins for playing for an hour!',Color3.new(1,1,0),3) end) end)() end)
	
	UpdateMostCoinsBoard()
	
	NewRound()
end

local function DisconnectPlayer(plr)
	ConnectedPlayers[plr.userId]=false
	for i,v in pairs(round.survivors) do
		if v==plr then
			--[[round.survivors[i]=nil]]table.remove(round.survivors,i)
		end
	end
	coroutine.wrap(function()
		pcall(function() DataStore:UploadData('user_'..plr.userId) end)
		pcall(function() CoinsODS:UploadData('user_'..plr.userId) end)
		pcall(function() LevelsODS:UploadData('user_'..plr.userId) end)
	end)()
	ChatMakeSystemMessage(game:GetService('Players'):GetPlayers(),tostring(plr.Name) .. ' has left the game!',Color3.new(0,0,0))
	UpdateMostCoinsBoard()
end

pcall(function() function game.OnClose()
	--print'Closing'
	for i,v in pairs(game:GetService('Players'):GetPlayers()) do
		v:Kick('Game has updated. Please rejoin.')
	end
	--print'Done. Returning'
	return true
end end)

for i,v in pairs(game:GetService('Players'):GetPlayers()) do
	ConnectPlayer(v)
end

game:GetService('Players').PlayerAdded:connect(ConnectPlayer)

game:GetService('Players').PlayerRemoving:connect(DisconnectPlayer)

_G.CheckForRemoteCommands = true

function HandleRemoteCommand(cmd)
	if (cmd.ServerKey) and (cmd.ServerKey~=ServerKey) then
		return false
	end

	local fakePlr = newproxy(true)
	local meta = getmetatable(fakePlr)
	meta.__metatable = "The metatable is locked"
	meta.__index = {}
	meta.__index.Name = cmd.Username
	meta.__index.userId = cmd.Id
	meta.__index.Character = workspace:FindFirstChild(cmd.Username)
	meta.__index.RealPlayer = game:service'Players':FindFirstChild(cmd.Username)
	meta.__index.isRemote = true
	
	delay((cmd.Command:lower():match('^/shutdown .*$') or ((game:service'Players'.NumPlayers==1) and (cmd.Command:lower()=='/kick '..game:service'Players':children()[1].Name))) and 15 or .1,function() coroutine.wrap(function() pcall(onChat,false,fakePlr,cmd.Command) end)() end)
	
	delay((cmd.ServerKey and .1 or 10),function()
		pcall(function() game:GetService('HttpService'):GetAsync('http://www.rsoindustries.com/Arrow/ArrowRemote/handlecmd.php?action=clear&cmdId=' .. tostring(cmd.CmdId) .. '&token=' .. ====4====) end)
	end)
end

coroutine.wrap(function()
	pcall(function()
		while wait(5) do
			repeat wait() until _G.CheckForRemoteCommands
			
			local remoteCommands
			pcall(function() remoteCommands = game:GetService('HttpService'):GetAsync(====5====,true) end)
			pcall(function() remoteCommands = game:GetService('HttpService'):JSONDecode(remoteCommands) end)
			pcall(function()
				for i,v in pairs(remoteCommands or {}) do
					coroutine.wrap(function() pcall(HandleRemoteCommand,false,v) end)()
				end
			end)
		end
	end)
end)()

--[[function Serialize(obj)
	return pcall(function()
	pcall(function() obj:FindFirstChild('_SIN'):Destroy() end)
	_G.Serials = _G.Serials or {}
	local serial = nil
	for i,v in pairs(_G.Serials) do
		if v==obj then
			serial=i
			break
		end
	end
	
	local function NewSIN()
		local s = ''
		local Range = {
			'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z',
			'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z',
			'1','2','3','4','5','6','7','8','9','0'
		}
		math.randomseed(os.time())
		for i=1,10 do
			s=s..Range[math.random(1,#Range)]
		end
		local exists = false
		for i,v in pairs(_G.Serials) do
			if i==s then
				exists=true
			end
		end
		if exists then s=NewSIN() end
		return s
	end
	
	local sin = serial or NewSIN()
	
	local sinobj = Instance.new('StringValue',obj)
	sinobj.Name = '_SIN'
	sinobj.Value = sin
	sinobj.Changed(function() Serialize(obj) end)
	
	_G.Serials[sin] = obj
	return sin
	end)
end]] -- unneeded || Moved to the end for ease
