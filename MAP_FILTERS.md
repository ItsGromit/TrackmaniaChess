# Map Filter System

The TrackmaniaChess server now supports customizable map filters that the lobby host can configure before starting a game. This allows for fine-grained control over which maps are selected for race challenges.

## Developer Blacklists

The server supports optional developer-configured blacklists (configured in the server's config file):
- **Blacklisted Authors**: Exclude all maps by specific authors
- **Blacklisted Mappacks**: Exclude all maps from specific mappacks

**Note:** To find a mappack ID, visit the mappack page on trackmania.exchange and look at the URL. For example:
`https://trackmania.exchange/mappackshow/12345` → Mappack ID is `12345`

## How It Works

1. When a lobby is created, it starts with default filters: Kacky and LOL tags are blacklisted
2. The lobby host can customize filters at any time before starting the game
3. When a capture occurs during gameplay, the server fetches a random map using the configured filters
4. All players in the lobby are notified when filters are updated

**Note:** The only automatic filtering is the exclusion of Kacky and LOL tagged maps. All other filtering is controlled by the lobby host.

## Message Protocol

### Setting Map Filters (Host Only)

```json
{
  "type": "set_map_filters",
  "lobbyId": "ABC123",
  "filters": {
    "authortimemax": 45,
    "authortimemin": 20,
    "tags": ["Tech", "Speed"],
    "excludeTags": ["Ice", "Plastic"],
    "maptype": "Race",
    "author": "Nadeo",
    "name": "Winter"
  }
}
```

**Note:**
- `tags` - Whitelist mode: Include maps with at least one of these tags
- `excludeTags` - Blacklist mode: Exclude maps with any of these tags
- Both can be used together for fine-grained control

### Getting Current Filters

```json
{
  "type": "get_map_filters",
  "lobbyId": "ABC123"
}
```

Response:
```json
{
  "type": "map_filters",
  "lobbyId": "ABC123",
  "filters": { ... }
}
```

### Filter Update Notification

When filters are updated, all lobby members receive:
```json
{
  "type": "map_filters_updated",
  "lobbyId": "ABC123",
  "filters": { ... }
}
```

## Available Filter Options

### Time-based Filters
- **authortimemax** (number): Maximum author time in seconds (e.g., `60` for maps under 1 minute)
- **authortimemin** (number): Minimum author time in seconds (e.g., `20` for maps over 20 seconds)

### Tag Filters

**Whitelist Mode (Include Tags):**
- **tags** (array of strings): Include maps that have **at least one** of these tags (e.g., `["Tech", "Speed", "Dirt"]`)
  - Uses OR logic: a map will be included if it has Tech OR Speed OR Dirt
  - Example: Selecting `["Tech", "Speed"]` will return maps with Tech, maps with Speed, or maps with both

**Blacklist Mode (Exclude Tags):**
- **excludeTags** (array of strings): Exclude maps with any of these tags (e.g., `["Ice", "Plastic"]`)
  - Maps with Ice OR Plastic tags will be excluded
  - Kacky and LOL tags are excluded by default but can be removed from the blacklist if desired

**Available Tags (Complete TMX List):**
All tags available on TrackmaniaExchange can be used for filtering. The complete list includes:
- `Altered Nadeo`
- `Arena`
- `Backwards`
- `Bobsleigh`
- `Bugslide`
- `Bumper`
- `Competitive`
- `CruiseControl`
- `DesertCar`
- `Dirt`
- `Educational`
- `Endurance`
- `EngineOff`
- `FlagRush`
- `Fragile`
- `Freeblocking`
- `Freestyle`
- `FullSpeed`
- `Grass`
- `Ice`
- `Kacky`
- `LOL`
- `Magnet`
- `Mini`
- `Minigame`
- `Mixed`
- `MixedCar`
- `Moving Items`
- `Mudslide`
- `MultiLap`
- `Nascar`
- `NoBrake`
- `NoGrip`
- `NoSteer`
- `Obstacle`
- `Offroad`
- `Pathfinding`
- `Pipes`
- `Plastic`
- `Platform`
- `Press Forward`
- `Puzzle`
- `Race`
- `RallyCar`
- `Reactor`
- `Remake`
- `Royal`
- `RPG`
- `RPG-Immersive`
- `Sausage`
- `Scenery`
- `Signature`
- `Slow Motion`
- `SnowCar`
- `SpeedDrift`
- `SpeedFun`
- `SpeedMapping`
- `SpeedTech`
- `Stunt`
- `Tech`
- `Transitional`
- `Trial`
- `Turtle`
- `Underwater`
- `Water`
- `Wood`
- `ZrT`

### Map Type Filter
- **maptype** (string): Filter by map type (e.g., `"Race"`)

### Other Filters
- **author** (string): Filter by map author username
- **name** (string): Search for maps with this name

## Default Filters

When a lobby is created, the following default filters are applied:
- **Max Author Time**: 300 seconds (5 minutes) - essentially no limit
- **Blacklisted Tags**: `Kacky` and `LOL` (can be removed if desired)
- **Blacklist Mode**: Enabled by default

### Whitelist and Blacklist Combined
```json
{
  "tags": ["Tech", "Speed"],
  "excludeTags": ["Ice", "Plastic", "Kacky", "LOL"],
  "authortimemax": 60
}
```
This will include Tech or Speed maps, but exclude any that have Ice, Plastic, Kacky, or LOL tags.

## Fallback Behavior

If no maps match the filters, or if the TMX API is unavailable, the server automatically fetches maps from the current official Trackmania campaign using the TMX API. This ensures that:

1. **Players always have the maps**: Campaign maps are downloaded by all players during regular gameplay
2. **Auto-updates**: The fallback automatically uses the current season's campaign (e.g., Fall 2025, Winter 2025)
3. **Reliable**: As official Nadeo maps, they're guaranteed to be available on TMX

If the campaign fetch also fails (extremely rare), the server falls back to hardcoded Winter 2025 campaign maps as a last resort.

## Implementation Notes

- Filters are stored per-lobby and transferred to the game when it starts
- Only the lobby host can set filters
- All players see the current filter configuration
- Filters persist for the duration of the game
- On rematch, the same filters are maintained
