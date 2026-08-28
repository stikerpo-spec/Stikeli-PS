local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local TweenService=game:GetService("TweenService")
local player=Players.LocalPlayer
local Remotes=ReplicatedStorage:WaitForChild("Remotes")
local Action=Remotes:WaitForChild("Action")
local State=Remotes:WaitForChild("State")
local Request=Remotes:WaitForChild("Request")
local Config=require(ReplicatedStorage:WaitForChild("Config"))

local gui=Instance.new("ScreenGui"); gui.Name="StikeliPS_UI"; gui.ResetOnSpawn=false; gui.Parent=player:WaitForChild("PlayerGui")
local function corner(o,r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 12); c.Parent=o end
local function button(parent,text,pos,size)
 local b=Instance.new("TextButton"); b.Text=text; b.Position=pos; b.Size=size; b.BackgroundTransparency=.08; b.TextScaled=true; b.Font=Enum.Font.GothamBold; b.Parent=parent; corner(b,10); return b
end
local top=Instance.new("Frame"); top.Size=UDim2.new(1,-24,0,70); top.Position=UDim2.fromOffset(12,12); top.BackgroundTransparency=.08; top.Parent=gui; corner(top,16)
local title=Instance.new("TextLabel"); title.Text="🐾 STIKELI-PS"; title.Size=UDim2.fromOffset(240,70); title.BackgroundTransparency=1; title.TextScaled=true; title.Font=Enum.Font.GothamBlack; title.Parent=top
local coins=Instance.new("TextLabel"); coins.Position=UDim2.new(0,250,0,0); coins.Size=UDim2.fromOffset(180,70); coins.BackgroundTransparency=1; coins.TextScaled=true; coins.Font=Enum.Font.GothamBold; coins.Parent=top
local gems=coins:Clone(); gems.Position=UDim2.new(0,440,0,0); gems.Parent=top
local area=coins:Clone(); area.Position=UDim2.new(0,630,0,0); area.Parent=top
local menu=Instance.new("Frame"); menu.Size=UDim2.fromOffset(150,300); menu.Position=UDim2.fromOffset(12,100); menu.BackgroundTransparency=.12; menu.Parent=gui; corner(menu,16)
local inv=button(menu,"🐾 PETS",UDim2.fromOffset(10,10),UDim2.new(1,-20,0,48))
local hatch=button(menu,"🥚 EGGS",UDim2.fromOffset(10,68),UDim2.new(1,-20,0,48))
local upgrades=button(menu,"⬆ UPGRADES",UDim2.fromOffset(10,126),UDim2.new(1,-20,0,48))
local worlds=button(menu,"🌎 WORLDS",UDim2.fromOffset(10,184),UDim2.new(1,-20,0,48))
local best=button(menu,"⚡ EQUIP BEST",UDim2.fromOffset(10,242),UDim2.new(1,-20,0,48))

local panel=Instance.new("Frame"); panel.Size=UDim2.fromOffset(520,430); panel.Position=UDim2.new(.5,-260,.5,-180); panel.BackgroundTransparency=.04; panel.Visible=false; panel.Parent=gui; corner(panel,18)
local panelTitle=Instance.new("TextLabel"); panelTitle.Size=UDim2.new(1,-60,0,55); panelTitle.Position=UDim2.fromOffset(18,10); panelTitle.BackgroundTransparency=1; panelTitle.TextScaled=true; panelTitle.Font=Enum.Font.GothamBlack; panelTitle.Parent=panel
local close=button(panel,"X",UDim2.new(1,-55,0,10),UDim2.fromOffset(40,40)); close.MouseButton1Click:Connect(function() panel.Visible=false end)
local list=Instance.new("ScrollingFrame"); list.Size=UDim2.new(1,-30,1,-80); list.Position=UDim2.fromOffset(15,70); list.BackgroundTransparency=1; list.ScrollBarThickness=6; list.Parent=panel
local layout=Instance.new("UIGridLayout"); layout.CellSize=UDim2.fromOffset(150,80); layout.CellPadding=UDim2.fromOffset(8,8); layout.Parent=list
local function clear() for _,x in ipairs(list:GetChildren()) do if x:IsA("GuiButton") or x:IsA("TextLabel") then x:Destroy() end end end
local function showPets(state)
 panel.Visible=true; panelTitle.Text="YOUR PETS"; clear()
 for _,p in ipairs(state.Pets or {}) do local cfg=Config.Pets[p.ConfigId]; local b=button(list,(cfg and cfg.Name or "Pet").."\nPower: "..(cfg and cfg.Power or 0),UDim2.fromOffset(0,0),UDim2.fromOffset(150,80)); b.MouseButton1Click:Connect(function() end) end
end
local function showEggs(state)
 panel.Visible=true; panelTitle.Text="EGGS"; clear()
 for i,e in ipairs(Config.Eggs) do if table.find(state.AreasUnlocked or {},e.Area) then local b=button(list,e.Name.."\n💰 "..e.Cost,UDim2.fromOffset(0,0),UDim2.fromOffset(150,80)); b.MouseButton1Click:Connect(function() Action:FireServer("Hatch",e.Id) end) end end
end
local function showUpgrades()
 panel.Visible=true; panelTitle.Text="UPGRADES"; clear()
 for name,cfg in pairs(Config.Upgrades) do local b=button(list,name.."\nLevel: 0",UDim2.fromOffset(0,0),UDim2.fromOffset(150,80)); b.MouseButton1Click:Connect(function() Action:FireServer("Upgrade",name) end) end
end
local function showWorlds(state)
 panel.Visible=true; panelTitle.Text="WORLDS & AREAS"; clear()
 for w,world in ipairs(Config.Worlds) do for _,a in ipairs(world.Areas) do local unlocked=table.find(state.AreasUnlocked or {},a.Id); local text=(unlocked and "🔓 " or "🔒 ")..a.Name.."\n"..(unlocked and "ENTER" or "💰 "..a.Cost); local b=button(list,text,UDim2.fromOffset(0,0),UDim2.fromOffset(150,80)); b.MouseButton1Click:Connect(function() if unlocked then Action:FireServer("SetArea",a.Id) else Action:FireServer("UnlockArea",a.Id) end end) end end
end
local state=Request:InvokeServer("GetState") or {}
local function render(s) state=s or state; coins.Text="💰 "..tostring(state.Coins or 0); gems.Text="💎 "..tostring(state.Diamonds or 0); area.Text="📍 Area "..tostring(state.CurrentArea or 1) end
render(state)
State.OnClientEvent:Connect(function(s) if s.Event=="Hatched" then panelTitle.Text="✨ HATCHED: "..s.Pet.Name; panel.Visible=true; task.delay(1.5,function() end) else render(s) end end)
inv.MouseButton1Click:Connect(function() showPets(state) end)
hatch.MouseButton1Click:Connect(function() showEggs(state) end)
upgrades.MouseButton1Click:Connect(showUpgrades)
worlds.MouseButton1Click:Connect(function() showWorlds(state) end)
best.MouseButton1Click:Connect(function() Action:FireServer("EquipBest") end)

local hint=Instance.new("TextLabel"); hint.Size=UDim2.fromOffset(520,55); hint.Position=UDim2.new(.5,-260,1,-70); hint.BackgroundTransparency=.2; hint.Text="Break the glowing crates to earn Coins, then hatch stronger Pets!"; hint.TextScaled=true; hint.Font=Enum.Font.GothamMedium; hint.Parent=gui; corner(hint,14)
