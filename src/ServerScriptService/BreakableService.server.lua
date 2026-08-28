local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Config=require(ReplicatedStorage:WaitForChild("Config"))
local Remotes=ReplicatedStorage:WaitForChild("Remotes")
local Action=Remotes:WaitForChild("Action")
local State=Remotes:WaitForChild("State")

local active={}
local function stateFor(p) return p:GetAttribute("StikeliLoaded") end
local function getData(p) return _G.StikeliData and _G.StikeliData[p] end

-- Main server script exposes its session table through this read-only bridge.
_G.StikeliData = _G.StikeliData or {}
local function bindPlayers()
    for _,p in ipairs(Players:GetPlayers()) do if not _G.StikeliData[p] then _G.StikeliData[p]={} end end
end
Players.PlayerAdded:Connect(bindPlayers); bindPlayers()

local function playerPower(player)
    local d=_G.StikeliData[player]; if not d then return 5 end
    local total=0
    for _,uid in ipairs(d.EquippedPets or {}) do
        for _,pet in ipairs(d.Pets or {}) do if pet.UID==uid then local cfg=Config.Pets[pet.ConfigId]; total+=cfg and cfg.Power or 0; break end end
    end
    return math.max(5,total) * (1 + ((d.Upgrades and d.Upgrades.PetDamage) or 0)*0.12)
end

local function setupBreakable(part)
    if not part:IsA("BasePart") or not part:GetAttribute("Health") then return end
    active[part]={Health=part:GetAttribute("Health"), MaxHealth=part:GetAttribute("Health"), Busy=false}
    part:SetAttribute("MaxHealth",active[part].MaxHealth)
    local gui=Instance.new("BillboardGui"); gui.Name="HealthBar"; gui.Size=UDim2.fromOffset(120,22); gui.StudsOffset=Vector3.new(0,4,0); gui.AlwaysOnTop=true; gui.Parent=part
    local bar=Instance.new("Frame"); bar.Size=UDim2.fromScale(1,1); bar.Parent=gui
    local fill=Instance.new("Frame"); fill.Name="Fill"; fill.Size=UDim2.fromScale(1,1); fill.Parent=bar
end
for _,x in ipairs(workspace:GetDescendants()) do setupBreakable(x) end
workspace.DescendantAdded:Connect(setupBreakable)

local function hit(player,part)
    local b=active[part]; local d=_G.StikeliData[player]
    if not b or not d or b.Busy then return end
    local area=part:GetAttribute("Area") or 1
    if not table.find(d.AreasUnlocked or {},area) then return end
    b.Busy=true
    b.Health-=playerPower(player)
    if b.Health<=0 then
        local reward=part:GetAttribute("CoinReward") or 50
        reward=math.floor(reward*(1+((d.Upgrades and d.Upgrades.CoinMultiplier) or 0)*0.15))
        d.Coins+=reward; d.Diamonds+=math.max(1,math.floor(reward/100)); d.Stats.CoinsEarned+=reward; d.Stats.BreakablesBroken+=1; d.Quests.Breakables=(d.Quests.Breakables or 0)+1
        State:FireClient(player,{Coins=d.Coins,Diamonds=d.Diamonds,Pets=d.Pets,EquippedPets=d.EquippedPets,AreasUnlocked=d.AreasUnlocked,CurrentArea=d.CurrentArea,Upgrades=d.Upgrades,Stats=d.Stats,Event="BreakReward",Reward=reward})
        part.Transparency=1; part.CanCollide=false
        task.delay(5,function() if part.Parent then b.Health=b.MaxHealth; part.Transparency=0; part.CanCollide=true; b.Busy=false end end)
    else
        b.Busy=false
        local gui=part:FindFirstChild("HealthBar"); if gui then local fill=gui.Frame.Fill; fill.Size=UDim2.new(math.clamp(b.Health/b.MaxHealth,0,1),0,1,0) end
    end
end

Action.OnServerEvent:Connect(function(player,action,target)
    if action=="AttackBreakable" and typeof(target)=="Instance" and target:IsDescendantOf(workspace) then hit(player,target) end
end)
