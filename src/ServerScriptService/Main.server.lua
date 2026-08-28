local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local Store = DataStoreService:GetDataStore("StikeliPS_PlayerData_v1")

local Remotes = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder")
Remotes.Name = "Remotes"
Remotes.Parent = ReplicatedStorage
local function remote(name, className)
    local r = Remotes:FindFirstChild(name) or Instance.new(className)
    r.Name = name; r.Parent = Remotes; return r
end
local Action = remote("Action", "RemoteEvent")
local State = remote("State", "RemoteEvent")
local Request = remote("Request", "RemoteFunction")

local sessions = {}
local cooldowns = {}

local function defaultData()
    local starterId = HttpService:GenerateGUID(false)
    return {
        Version=Config.DataVersion, Coins=Config.StartingCoins, Diamonds=Config.StartingDiamonds,
        Pets={{UID=starterId, ConfigId=1, Name="Starter Cat", Variant="Normal", Level=1, XP=0, Locked=false, Favorite=true}},
        EquippedPets={starterId}, AreasUnlocked={1}, CurrentArea=1, Upgrades={}, Quests={Breakables=0, Eggs=0},
        Achievements={}, Collection={1=true}, Cosmetics={}, Titles={}, DailyRewards={Day=1, LastClaim=0},
        Stats={CoinsEarned=0, DiamondsEarned=0, EggsOpened=0, BreakablesBroken=0, Trades=0, Playtime=0},
        Settings={Music=true, Sounds=true, Particles=true, LowGraphics=false, DamageNumbers=true, TradeRequests=true},
    }
end

local function sanitize(data)
    if type(data) ~= "table" then return defaultData() end
    local d=defaultData()
    for k,v in pairs(data) do d[k]=v end
    d.Coins=math.max(0, math.floor(tonumber(d.Coins) or 0))
    d.Diamonds=math.max(0, math.floor(tonumber(d.Diamonds) or 0))
    d.Pets=type(d.Pets)=="table" and d.Pets or {}
    d.EquippedPets=type(d.EquippedPets)=="table" and d.EquippedPets or {}
    d.AreasUnlocked=type(d.AreasUnlocked)=="table" and d.AreasUnlocked or {1}
    d.Upgrades=type(d.Upgrades)=="table" and d.Upgrades or {}
    return d
end

local function load(player)
    local key="p:"..player.UserId
    local data
    for attempt=1,5 do
        local ok,result=pcall(function() return Store:GetAsync(key) end)
        if ok then data=result; break end
        task.wait(attempt)
    end
    data=sanitize(data)
    sessions[player]=data
    return data
end

local function save(player)
    local data=sessions[player]; if not data then return false end
    local key="p:"..player.UserId
    for attempt=1,5 do
        local ok=pcall(function() Store:UpdateAsync(key,function() return data end) end)
        if ok then return true end
        task.wait(attempt)
    end
    return false
end

local function publicState(player)
    local d=sessions[player]
    if not d then return nil end
    return {Coins=d.Coins, Diamonds=d.Diamonds, Pets=d.Pets, EquippedPets=d.EquippedPets, AreasUnlocked=d.AreasUnlocked, CurrentArea=d.CurrentArea, Upgrades=d.Upgrades, Stats=d.Stats}
end
local function push(player) State:FireClient(player, publicState(player)) end
local function limited(player, action, interval)
    cooldowns[player]=cooldowns[player] or {}
    local now=os.clock(); local last=cooldowns[player][action] or 0
    if now-last < interval then return false end
    cooldowns[player][action]=now; return true
end
local function hasPet(d,uid)
    for _,p in ipairs(d.Pets) do if p.UID==uid then return p end end
end

local function hatch(player, eggId)
    local d=sessions[player]; local egg=Config.Eggs[tonumber(eggId) or 0]
    if not d or not egg or not limited(player,"hatch",Config.HatchCooldown) then return end
    if not table.find(d.AreasUnlocked,egg.Area) or d.Coins < egg.Cost then return end
    d.Coins-=egg.Cost
    local pick=egg.PetPool[math.random(1,#egg.PetPool)]
    local cfg=Config.Pets[pick]
    local uid=HttpService:GenerateGUID(false)
    table.insert(d.Pets,{UID=uid,ConfigId=cfg.Id,Name=cfg.Name,Variant="Normal",Level=1,XP=0,Locked=false,Favorite=false})
    d.Collection[cfg.Id]=true; d.Stats.EggsOpened+=1
    push(player)
    State:FireClient(player,{Event="Hatched",Pet=cfg})
end

local function equipBest(player)
    local d=sessions[player]; if not d then return end
    local slots=Config.BasePetSlots+(d.Upgrades.PetSlots or 0)
    table.sort(d.Pets,function(a,b) return (Config.Pets[a.ConfigId] and Config.Pets[a.ConfigId].Power or 0) > (Config.Pets[b.ConfigId] and Config.Pets[b.ConfigId].Power or 0) end)
    d.EquippedPets={}
    for i=1,math.min(slots,#d.Pets) do d.EquippedPets[i]=d.Pets[i].UID end
    push(player)
end

local function unlockArea(player, areaId)
    local d=sessions[player]; local area=Config.Worlds[math.ceil(areaId/5)] and Config.Worlds[math.ceil(areaId/5)].Areas[((areaId-1)%5)+1]
    if not d or not area or d.Coins<area.Cost then return end
    if table.find(d.AreasUnlocked,area.Id) then d.CurrentArea=area.Id else d.Coins-=area.Cost; table.insert(d.AreasUnlocked,area.Id); d.CurrentArea=area.Id end
    push(player)
end

Action.OnServerEvent:Connect(function(player,action,...)
    if type(action)~="string" or not limited(player,"remote",1/Config.RemoteRateLimit) then return end
    if action=="Hatch" then hatch(player,...)
    elseif action=="EquipBest" then equipBest(player)
    elseif action=="UnlockArea" then unlockArea(player,...)
    elseif action=="SetArea" then
        local id=tonumber((...)); local d=sessions[player]
        if d and id and table.find(d.AreasUnlocked,id) then d.CurrentArea=id; push(player) end
    elseif action=="Upgrade" then
        local name=(...); local d=sessions[player]; local cfg=Config.Upgrades[name]
        if d and cfg then local level=d.Upgrades[name] or 0; if level<cfg.MaxLevel then local cost=math.floor(cfg.BaseCost*(cfg.Growth^level)); if d.Diamonds>=cost then d.Diamonds-=cost; d.Upgrades[name]=level+1; push(player) end end end
    end
end)

Request.OnServerInvoke=function(player,action,...)
    if action=="GetState" then return publicState(player) end
    return nil
end

local function createWorld()
    local folder=workspace:FindFirstChild("StikeliWorld") or Instance.new("Folder")
    folder.Name="StikeliWorld"; folder.Parent=workspace
    local spawn=Instance.new("SpawnLocation"); spawn.Name="SunnyMeadowsSpawn"; spawn.Size=Vector3.new(8,1,8); spawn.Position=Vector3.new(0,2,0); spawn.Anchored=true; spawn.Parent=folder
    for i=1,10 do
        local pad=Instance.new("Part"); pad.Name="Area_"..i; pad.Size=Vector3.new(70,1,70); pad.Position=Vector3.new((i-1)*80,0,0); pad.Anchored=true; pad.Parent=folder
        local label=Instance.new("BillboardGui"); label.Size=UDim2.fromOffset(220,60); label.StudsOffset=Vector3.new(0,8,0); label.AlwaysOnTop=true; label.Parent=pad
        local text=Instance.new("TextLabel"); text.Size=UDim2.fromScale(1,1); text.BackgroundTransparency=1; text.Text="AREA "..i; text.TextScaled=true; text.Parent=label
        for b=1,5 do
            local chest=Instance.new("Part"); chest.Name="Breakable_"..i.."_"..b; chest.Size=Vector3.new(5,4,5); chest.Position=pad.Position+Vector3.new((b-3)*12,3,10); chest.Anchored=true; chest.Parent=folder
            chest:SetAttribute("Health",math.floor(100*(Config.AreaGrowth^(i-1)))); chest:SetAttribute("Area",i); chest:SetAttribute("CoinReward",math.floor(50*(Config.AreaGrowth^(i-1))))
        end
    end
end

Players.PlayerAdded:Connect(function(player)
    load(player); push(player)
end)
Players.PlayerRemoving:Connect(function(player) save(player); sessions[player]=nil; cooldowns[player]=nil end)
task.spawn(function() while task.wait(Config.AutosaveSeconds) do for player in pairs(sessions) do save(player) end end end)
game:BindToClose(function() for player in pairs(sessions) do save(player) end end)
createWorld()
