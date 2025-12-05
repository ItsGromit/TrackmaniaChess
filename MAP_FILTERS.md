# Map Filter System

The TrackmaniaChess server now supports customizable map filters that the lobby host can configure before starting a game. This allows for fine-grained control over which maps are selected for race challenges.

## Developer Blacklist

As the server developer, you can globally blacklist certain authors or mappacks by editing the configuration at the top of `server.js`:

```javascript
// ---------- Developer Blacklist Configuration ----------
// Add authors you want to exclude from random map selection
const BLACKLISTED_AUTHORS = [

];

// Add mappack IDs you want to exclude from random map selection
const BLACKLISTED_MAPPACKS = [

];
```

These blacklists are applied automatically to ALL map selections, regardless of lobby filter settings. This is useful for:
- Excluding low-quality or inappropriate content creators
- Preventing your own test/WIP mappacks from appearing in random selection
- Blocking specific problematic mappacks

**Note:** To find a mappack ID, visit the mappack page on trackmania.exchange and look at the URL. For example:
`https://trackmania.exchange/mappackshow/12345` → Mappack ID is `12345`

## How It Works

1. When a lobby is created, it starts with empty map filters (defaults to maps under 60 seconds)
2. The lobby host can set filters at any time before starting the game
3. When a capture occurs during gameplay, the server fetches a random map using the configured filters
4. All players in the lobby are notified when filters are updated

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
    "excludeTags": ["Kacky", "LOL"],
    "difficulty": "Advanced",
    "maptype": "Race",
    "author": "Nadeo",
    "name": "Winter"
  }
}
```

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
- **tags** (array of strings): Only include maps with these tags (e.g., `["Tech", "Speed", "Dirt"]`)
- **excludeTags** (array of strings): Exclude maps with these tags (e.g., `["Kacky", "LOL"]`)

### Difficulty Filter
- **difficulty** (string): One of:
  - `"Beginner"`
  - `"Intermediate"`
  - `"Advanced"`
  - `"Expert"`
  - `"Lunatic"`
  - `"Impossible"`

### Map Type Filter
- **maptype** (string): Filter by map type (e.g., `"Race"`)

### Other Filters
- **author** (string): Filter by map author username
- **name** (string): Search for maps with this name

## Example Use Cases

### Sprint Maps Only
```json
{
  "authortimemax": 30,
  "tags": ["Speed"]
}
```

### Technical Maps (30-60 seconds)
```json
{
  "authortimemin": 30,
  "authortimemax": 60,
  "tags": ["Tech"],
  "difficulty": "Advanced"
}
```

### Campaign-style Maps
```json
{
  "author": "Nadeo",
  "authortimemax": 45
}
```

### No Kacky/Meme Maps
```json
{
  "excludeTags": ["Kacky", "LOL", "Meme"],
  "authortimemax": 60
}
```

## Fallback Behavior

If no maps match the filters, or if the TMX API is unavailable, the server falls back to the current Winter 2025 campaign tracks (maps 1-5).

## Implementation Notes

- Filters are stored per-lobby and transferred to the game when it starts
- Only the lobby host can set filters
- All players see the current filter configuration
- Filters persist for the duration of the game
- On rematch, the same filters are maintained
