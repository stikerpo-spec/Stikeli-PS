local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Store = DataStoreService:GetDataStore("StikeliPS_PlayerData_v1")
local Remotes = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder"); Remotes.Name="Remotes"; Remotes.Parent=ReplicatedStorage
local function remote(name,className) local r=Remotes:FindFirstChild(name) or Instance.new(className); r.Name=name; r.Parent=Remotes; return r end
local Action=remote("Action","RemoteEvent"); local State=remote("State","RemoteEvent"); local Request=remote("Request","RemoteFunction")
local sessions={}; local cooldowns={}; _G.StikeliData=sessions
local function defaultData()
 local uid=HttpService:GenerateGUID(false)
 return {Version=Config.DataVersion,Coins=Config.StartingCoins,Diamonds=Config.StartingDiamonds,Pets={{UID=uid,ConfigId=1,Name="Starter Cat",Variant="Normal",Level=1,XP=0,Locked=false,Favorite=true}},EquippedPets={uid},AreasUnlocked={1},CurrentArea=1,Upgrades={},Quests={Breakables=0,Eggs=0},Achievements={},Collection={[1]=true},Cosmetics={},Titles={},DailyRewards={Day=1,LastClaim=0},Stats={CoinsEarned=0,DiamondsEarned=0,EggsOpened=0,BreakablesBroken=0,Trades=0,Playtime=0},Settings={Music=true,Sounds=true,Particles=true,LowGraphics=false,DamageNumbers=true,TradeRequests=true}}
end
local function sanitize(data)
 if type(data)~="table" then return defaultData() end
 local d=defaultData(); for k,v in pairs(data) do d[k]=v end
 d.Coins=math.max(0,math.floor(tonumber(d.Coins) or 0)); d.Diamonds=math.max(0,math.floor(tonumber(d.Diamonds) or 0))
 if type(d.Pets)~="table" then d.Pets={} end; if type(d.EquippedPets)~="table" then d.EquippedPets={} end; if type(d.AreasUnlocked)~="table" then d.AreasUnlocked={1} end; if type(d.Upgrades)~="table" then d.Upgrades={} end
 return d
end
local function load(p)
 local data
 for attempt=1,5 do local ok,res=pcall(function() return Store:GetAsync("p:"..p.UserId) end); if ok then data=res; break end; task.wait(attempt) end
 data=sanitize(data); sessions[p]=data; return data
end
local function save(p)
 local d=sessions[p]; if not d then return false end
 for attempt=1,5 do local ok=pcall(function() Store:UpdateAsync("p:"..p.UserId,function() return d end) end); if ok then return true end; task.wait(attempt) end
 return false
end
local function publicState(p) local d=sessions[p]; if not d then return nil end; return {Coins=d.Coins,Diamonds=d.Diamonds,Pets=d.Pets,EquippedPets=d.EquippedPets,AreasUnlocked=d.AreasUnlocked,CurrentArea=d.CurrentArea,Upgrades=d.Upgrades,Stats=d.Stats} end
local function push(p) State:FireClient(p,publicState(p)) end
local function limited(p,key,interval) cooldowns[p]=cooldowns[p] or {}; local now=os.clock(); if now-(cooldowns[p][key] or 0)<interval then return false end; cooldowns[p][key]=now; return true end
local function hatch(p,id)
 local d=sessions[p]; local egg=Config.Eggs[tonumber(id) or 0]; if not d or not egg or not limited(p,"hatch",Config.HatchCooldown) then return end
 if not table.find(d.AreasUnlocked,egg.Area) or d.Coins<egg.Cost then return end
 d.Coins-=egg.Cost; local cfg=Config.Pets[egg.PetPool[math.random(1,#egg.PetPool)]]; local uid=HttpService:GenerateGUID(false)
 table.insert(d.Pets,{UID=uid,ConfigId=cfg.Id,Name=cfg.Name,Variant="Normal",Level=1,XP=0,Locked=false,Favorite=false}); d.Collection[cfg.Id]=true; d.Stats.EggsOpened+=1; d.Quests.Eggs+=1; push(p); State:FireClient(p,{Event="Hatched",Pet=cfg})
end
local function equipBest(p)
 local d=sessions[p]; if not d then return end; local slots=Config.BasePetSlots+(d.Upgrades.PetSlots or 0); table.sort(d.Pets,function(a,b) return (Config.Pets[a.ConfigId] and Config.Pets[a.ConfigId].Power or 0)>(Config.Pets[b.ConfigId] and Config.Pets[b.ConfigId].Power or 0) end); d.EquippedPets={}; for i=1,math.min(slots,#d.Pets) do d.EquippedPets[i]=d.Pets[i].UID end; push(p)
end
local function areaFor(id) local n=tonumber(id); if not n or n<1 or n>50 then return nil end; return Config.Worlds[math.ceil(n/5)].Areas[((n-1)%5)+1] end
Action.OnServerEvent:Connect(function(p,action,...)
 if type(action)~="string" or not limited(p,"remote",1/Config.RemoteRateLimit) then return end
 if action=="Hatch" then hatch(p,...)
 elseif action=="EquipBest" then equipBest(p)
 elseif action=="UnlockArea" then local d=sessions[p]; local a=areaFor((...)); if d and a and not table.find(d.AreasUnlocked,a.Id) and d.Coins>=a.Cost then d.Coins-=a.Cost; table.insert(d.AreasUnlocked,a.Id); d.CurrentArea=a.Id; push(p) end
 elseif action=="SetArea" then local d=sessions[p]; local id=tonumber((...)); if d and id and table.find(d.AreasUnlocked,id) then d.CurrentArea=id; push(p) end
 elseif action=="Upgrade" then local name=(...); local d=sessions[p]; local cfg=Config.Upgrades[name]; if d and cfg then local level=d.Upgrades[name] or 0; local cost=math.floor(cfg.BaseCost*(cfg.Growth^level)); if level<cfg.MaxLevel and d.Diamonds>=cost then d.Diamonds-=cost; d.Upgrades[name]=level+1; push(p) end end end
end)
Request.OnServerInvoke=function(p,action) if action=="GetState" then return publicState(p) end end
local function createWorld()
 local folder=workspace:FindFirstChild("StikeliWorld") or Instance.new("Folder"); folder.Name="StikeliWorld"; folder.Parent=workspace
 for i=1,10 do local pad=Instance.new("Part"); pad.Name="Area_"..i; pad.Size=Vector3.new(70,1,70); pad.Position=Vector3.new((i-1)*80,0,0); pad.Anchored=true; pad.Parent=folder; local label=Instance.new("BillboardGui"); label.Size=UDim2.fromOffset(220,60); label.StudsOffset=Vector3.new(0,8,0); label.AlwaysOnTop=true; label.Parent=pad; local text=Instance.new("TextLabel"); text.Size=UDim2.fromScale(1,1); text.BackgroundTransparency=1; text.Text="AREA "..i; text.TextScaled=true; text.Parent=label
  for b=1,5 do local chest=Instance.new("Part"); chest.Name="Breakable_"..i.."_"..b; chest.Size=Vector3.new(5,4,5); chest.Position=pad.Position+Vector3.new((b-3)*12,3,10); chest.Anchored=true; chest.Parent=folder; chest:SetAttribute("Health",math.floor(100*(Config.AreaGrowth^(i-1)))); chest:SetAttribute("Area",i); chest:SetAttribute("CoinReward",math.floor(50*(Config.AreaGrowth^(i-1)))) end
 end
end
Players.PlayerAdded:Connect(function(p) load(p); push(p) end)
Players.PlayerRemoving:Connect(function(p) save(p); sessions[p]=nil; cooldowns[p]=nil end)
task.spawn(function() while task.wait(Config.AutosaveSeconds) do for p in pairs(sessions) do save(p) end end end)
game:BindToClose(function() for p in pairs(sessions) do save(p) end end)
createWorld()
