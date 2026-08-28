local Config = {}

Config.GameName = "Stikeli-PS"
Config.DataVersion = 1
Config.StartingCoins = 250
Config.StartingDiamonds = 25
Config.BasePetSlots = 4
Config.BaseStorage = 50
Config.AutosaveSeconds = 60
Config.RemoteRateLimit = 12
Config.HatchCooldown = 0.45
Config.CoinMultiplier = 1
Config.DiamondMultiplier = 1
Config.PetPowerGrowth = 1.45
Config.AreaGrowth = 8

Config.Rarities = {
    {Name="Common", Weight=6000, Multiplier=1},
    {Name="Rare", Weight=2500, Multiplier=2},
    {Name="Epic", Weight=1000, Multiplier=4},
    {Name="Legendary", Weight=400, Multiplier=8},
    {Name="Mythic", Weight=90, Multiplier=18},
    {Name="Divine", Weight=9, Multiplier=40},
    {Name="Secret", Weight=1, Multiplier=100},
}

Config.Worlds = {}
local worldNames = {"Meadow Kingdom","Ocean Realm","Sky Realm","Desert Realm","Frozen Realm","Space Realm","Magic Realm","Toy Realm","Cyber Realm","Galaxy Realm"}
local areaNames = {"Sunny Meadows","Crystal Forest","Mystic River","Golden Hills","Ancient Ruins"}
for w, worldName in ipairs(worldNames) do
    local world = {Id=w, Name=worldName, Areas={}}
    for a, areaName in ipairs(areaNames) do
        local index = (w-1)*5+a
        world.Areas[a] = {
            Id=index,
            Name=(w == 1 and areaName or (worldName .. " - " .. areaName)),
            Cost=index == 1 and 0 or math.floor(250 * (Config.AreaGrowth ^ (index-2))),
            World=w,
            BreakableHealth=math.floor(100 * (Config.AreaGrowth ^ (index-1))),
            CoinReward=math.floor(50 * (Config.AreaGrowth ^ (index-1))),
            EggMultiplier=math.max(1, index * 1.5),
        }
    end
    Config.Worlds[w] = world
end

Config.PetFamilies = {"Cat","Bunny","Fox","Dog","Dragon","Penguin","Wolf","Tiger","Shark","Unicorn","Phoenix","Golem","Axolotl","Owl","Bear","Dino","Slime","Robot","Raccoon","Bee"}
Config.Pets = {}
local rarityNames = {"Common","Rare","Epic","Legendary","Mythic","Divine","Secret"}
for i=1,500 do
    local rarityIndex = ((i-1) % 100 < 60 and 1) or ((i-1)%100 < 85 and 2) or ((i-1)%100 < 95 and 3) or ((i-1)%100 < 99 and 4) or ((i-1)%100 < 100 and 5) or 6
    if i % 137 == 0 then rarityIndex = 7 end
    local family = Config.PetFamilies[((i-1) % #Config.PetFamilies)+1]
    local tier = math.floor((i-1) / #Config.PetFamilies) + 1
    Config.Pets[i] = {
        Id=i, Name=(tier > 1 and ("Crystal " .. family .. " " .. tier) or ("Starter " .. family)),
        Species=family, Rarity=rarityNames[rarityIndex], Power=math.floor(5 * (Config.PetPowerGrowth ^ (tier-1))) * Config.Rarities[rarityIndex].Multiplier,
        Level=1, XP=0, Variant="Normal", Huge=(i % 211 == 0), Titan=(i % 487 == 0), Secret=(rarityIndex == 7),
    }
end

Config.Eggs = {}
for i=1,100 do
    local areaId = ((i-1) % 50)+1
    local pool = {}
    local start = ((i-1)*5)%500+1
    for j=0,4 do pool[#pool+1] = ((start+j-1)%500)+1 end
    Config.Eggs[i] = {Id=i, Name="World "..math.ceil(areaId/5).." Egg "..((i-1)%5+1), Area=areaId, Cost=math.floor(250 * (1.6^(areaId-1))), PetPool=pool}
end

Config.Upgrades = {
    CoinMultiplier={BaseCost=100, Growth=2.2, MaxLevel=25},
    DiamondMultiplier={BaseCost=250, Growth=2.25, MaxLevel=25},
    PetDamage={BaseCost=150, Growth=2.1, MaxLevel=25},
    WalkSpeed={BaseCost=100, Growth=1.8, MaxLevel=10},
    EggLuck={BaseCost=300, Growth=2.4, MaxLevel=20},
    PetSlots={BaseCost=500, Growth=3, MaxLevel=12},
    Storage={BaseCost=250, Growth=1.9, MaxLevel=20},
}

return Config
