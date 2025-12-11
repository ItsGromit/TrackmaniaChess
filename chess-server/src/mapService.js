// mapService.js - Map fetching service

const https = require('https');
const { BLACKLISTED_AUTHORS, BLACKLISTED_MAPPACKS } = require('./config');

// Fetch a random short map from TrackmaniaExchange API (like Random Map Challenge plugin)
async function fetchRandomShortMap(filters = {}) {
  return new Promise((resolve) => {
    // Build query parameters based on filters
    // Use a random page offset to get different maps each time
    // Increased range to 0-199 for more variety (20,000 potential maps with limit=100)
    const randomPage = Math.floor(Math.random() * 200);

    // Randomly vary the sort order for more variety
    const sortOrders = ['TrackID', 'ReplayCount', 'AwardCount', 'AuthorTime', 'UploadedAt'];
    const randomSort = sortOrders[Math.floor(Math.random() * sortOrders.length)];
    const randomDirection = Math.random() < 0.5 ? 'ASC' : 'DESC';

    const params = new URLSearchParams({
      api: 'on',
      limit: '100', // Fetch 100 maps to choose from
      mtype: 'TM_Race', // Only race maps
      page: randomPage.toString(), // Random page for variety
      order: randomSort, // Random sort order
      orderdir: randomDirection // Random direction
    });

    console.log(`[Chess] Fetching maps from TMX page ${randomPage}, sorted by ${randomSort} ${randomDirection}`);

    // Apply filters (defaults if not specified)
    if (filters.authortimemax !== undefined) {
      params.append('authortimemax', filters.authortimemax);
    } else {
      params.append('authortimemax', '60'); // Default: 60 seconds
    }

    if (filters.authortimemin !== undefined) {
      params.append('authortimemin', filters.authortimemin);
    }

    // Tag filtering (include specific tags)
    if (filters.tags && filters.tags.length > 0) {
      filters.tags.forEach(tag => params.append('tags', tag));
    }

    // Exclude tags - always exclude Kacky and LOL maps by default
    const defaultExcludedTags = ['Kacky', 'LOL'];
    const allExcludedTags = [...defaultExcludedTags];

    if (filters.excludeTags && filters.excludeTags.length > 0) {
      // Add user-specified excluded tags
      filters.excludeTags.forEach(tag => {
        if (!allExcludedTags.includes(tag)) {
          allExcludedTags.push(tag);
        }
      });
    }

    // Apply all excluded tags
    allExcludedTags.forEach(tag => params.append('etags', tag));

    // Difficulty filter
    if (filters.difficulty) {
      params.append('difficulty', filters.difficulty);
    }

    // Map type filter (e.g., "Race")
    if (filters.maptype) {
      params.append('maptype', filters.maptype);
    }

    // Author filter
    if (filters.author) {
      params.append('author', filters.author);
    }

    // Map name search
    if (filters.name) {
      params.append('name', filters.name);
    }

    // Apply developer blacklists
    // Exclude blacklisted authors
    if (BLACKLISTED_AUTHORS.length > 0) {
      BLACKLISTED_AUTHORS.forEach(author => params.append('eauthor', author));
    }

    // Exclude blacklisted mappacks
    if (BLACKLISTED_MAPPACKS.length > 0) {
      BLACKLISTED_MAPPACKS.forEach(packId => params.append('emappack', packId));
    }

    // TrackmaniaExchange API endpoint for random maps
    // Using the same approach as the Random Map Challenge plugin
    const options = {
      hostname: 'trackmania.exchange',
      path: `/mapsearch2/search?${params.toString()}`,
      method: 'GET',
      headers: {
        'User-Agent': 'TrackmaniaChess/1.0'
      }
    };

    const req = https.request(options, (res) => {
      let data = '';

      res.on('data', (chunk) => {
        data += chunk;
      });

      res.on('end', () => {
        try {
          const response = JSON.parse(data);

          // Check if we got maps (TMX mapsearch2 returns {results: [...]} )
          if (response && response.results && Array.isArray(response.results) && response.results.length > 0) {
            // Filter out maps with blacklisted words in their names
            const blacklistedWords = ['kacky', 'lol', 'meme', 'troll'];
            const filteredMaps = response.results.filter(map => {
              const mapName = (map.GbxMapName || map.Name || '').toLowerCase();
              return !blacklistedWords.some(word => mapName.includes(word));
            });

            if (filteredMaps.length === 0) {
              console.log('[Chess] All maps filtered out by name blacklist, using campaign fallback');
              resolve(getFallbackMap());
              return;
            }

            // Pick a random map from the filtered results
            const randomIndex = Math.floor(Math.random() * filteredMaps.length);
            const map = filteredMaps[randomIndex];
            const mapInfo = {
              tmxId: map.TrackID,
              name: map.GbxMapName || map.Name || 'Unknown Map'
            };
            console.log(`[Chess] Selected random map from TMX (${randomIndex + 1}/${filteredMaps.length} after filtering): ${mapInfo.name} (TMX ID: ${mapInfo.tmxId})`);
            resolve(mapInfo);
          } else {
            // Fallback to Winter 2025 campaign maps if API fails
            console.log('[Chess] No maps from API, using Winter 2025 campaign fallback');
            resolve(getFallbackMap());
          }
        } catch (e) {
          console.error('[Chess] Error parsing TMX response:', e);
          resolve(getFallbackMap());
        }
      });
    });

    req.on('error', (e) => {
      console.error('[Chess] Error fetching from TMX:', e);
      resolve(getFallbackMap());
    });

    req.end();
  });
}

// Get a fallback map from the current campaign using TMX API
async function getFallbackMap() {
  return new Promise((resolve) => {
    // Fetch from the official Trackmania campaign
    // Using tags to filter for official campaign maps
    const params = new URLSearchParams({
      api: 'on',
      limit: '25', // Get all campaign maps
      mtype: 'TM_Race',
      authorlogin: 'nadeo', // Official Nadeo maps
      tags: '23', // Campaign tag
      order: 'TrackID',
      orderdir: 'DESC' // Get most recent campaign first
    });

    const options = {
      hostname: 'trackmania.exchange',
      path: `/mapsearch2/search?${params.toString()}`,
      method: 'GET',
      headers: {
        'User-Agent': 'TrackmaniaChess/1.0'
      }
    };

    console.log('[Chess] Fetching current campaign maps from TMX as fallback');

    const req = https.request(options, (res) => {
      let data = '';

      res.on('data', (chunk) => {
        data += chunk;
      });

      res.on('end', () => {
        try {
          const response = JSON.parse(data);

          if (response && response.results && Array.isArray(response.results) && response.results.length > 0) {
            // Pick a random map from the current campaign
            const randomIndex = Math.floor(Math.random() * response.results.length);
            const map = response.results[randomIndex];
            const mapInfo = {
              tmxId: map.TrackID,
              name: map.GbxMapName || map.Name || 'Campaign Map'
            };
            console.log(`[Chess] Selected campaign map as fallback: ${mapInfo.name} (TMX ID: ${mapInfo.tmxId})`);
            resolve(mapInfo);
          } else {
            // Last resort hardcoded fallback
            console.log('[Chess] Could not fetch campaign maps, using hardcoded fallback');
            resolve(getHardcodedFallback());
          }
        } catch (e) {
          console.error('[Chess] Error parsing campaign fallback response:', e);
          resolve(getHardcodedFallback());
        }
      });
    });

    req.on('error', (e) => {
      console.error('[Chess] Error fetching campaign maps:', e);
      resolve(getHardcodedFallback());
    });

    req.end();
  });
}

// Last resort hardcoded fallback (Winter 2025 campaign maps - TMX IDs)
function getHardcodedFallback() {
  const fallbackMaps = [
    { tmxId: 216544, name: 'Winter 2025 - 01' },
    { tmxId: 216545, name: 'Winter 2025 - 02' },
    { tmxId: 216546, name: 'Winter 2025 - 03' },
    { tmxId: 216547, name: 'Winter 2025 - 04' },
    { tmxId: 216548, name: 'Winter 2025 - 05' }
  ];
  console.log('[Chess] Using hardcoded Winter 2025 campaign map as last resort');
  return fallbackMaps[Math.floor(Math.random() * fallbackMaps.length)];
}

module.exports = {
  fetchRandomShortMap
};
