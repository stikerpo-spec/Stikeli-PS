# Stikeli-PS

A standalone browser-based pet-simulator-style game. No Roblox dependency.

## Included
- Pet collection, upgrades, leveling and equipment
- Eggs and rarity-based hatching
- Breakable objects with damage/rewards
- 10 worlds / 50 areas
- Progression, quests, achievements and profile statistics
- Trading Plaza simulation and marketplace listings
- Admin panel for testing
- Responsive desktop/mobile layout
- Local persistent save via `localStorage`
- Original names, visuals and mechanics; no copied game assets

## Run
Open `index.html` in a browser, or enable GitHub Pages for the repository. The game is a static web app and needs no build step.

## Multiplayer note
A static GitHub Pages site cannot securely provide real cross-user multiplayer trading or server-side accounts by itself. Stikeli-PS therefore implements the gameplay and marketplace/trading interfaces locally in the browser. A later backend can replace the local persistence layer without changing the UI architecture.
