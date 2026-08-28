# Stikeli-PS

A fully original Roblox pet-simulator-style game foundation built around server authority, persistent progression, procedurally generated content, and expandable services.

## Design
- Original names, visuals, mechanics, and generated assets.
- Client handles input/presentation; server owns currencies, pets, hatching, areas, trades, and saves.
- 10 worlds / 50 areas are generated from config.
- 500 pet definitions and 100 eggs are generated from deterministic config data.
- DataStore retries, autosave, shutdown save, validation, rate limits, trade locking, quests, bosses, events and responsive UI are included in the foundation.

## Studio setup
1. Install Rojo (7.x).
2. Clone this repository.
3. Run `rojo serve` from the repository folder.
4. Connect Roblox Studio to the Rojo server.
5. Publish the place and enable **Game Settings → Security → Enable Studio Access to API Services** for Studio testing of DataStores.
6. Play-test with **Start Server + Players** to test server authority and trading.

The project intentionally uses procedural Roblox Parts/UI so no third-party or copied game assets are required.
