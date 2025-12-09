// mapService.js - Map fetching service

const https = require('https');
const { BLACKLISTED_AUTHORS, BLACKLISTED_MAPPACKS } = require('./config');

// Fetch a random short map from TrackmaniaExchange API (like Random Map Challenge plugin)
async function fetchRandomShortMap(filters = {}) {
  return new Promise((resolve) => {
    // Build query parameters based on filters
    // Use a random page offset to get different maps each time
    const randomPage = Math.floor(Math.random() * 50); // Random page from 0-49
    const params = new URLSearchParams({
      api: 'on',
      limit: '100', // Fetch 100 maps to choose from
      mtype: 'TM_Race', // Only race maps
      page: randomPage.toString() // Random page for variety
    });

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

    // Exclude tags
    if (filters.excludeTags && filters.excludeTags.length > 0) {
      filters.excludeTags.forEach(tag => params.append('etags', tag));
    }

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
            // Pick a random map from the results for better randomization
            const randomIndex = Math.floor(Math.random() * response.results.length);
            const map = response.results[randomIndex];
            const mapInfo = {
              uid: map.TrackUID,
              name: map.GbxMapName || map.Name || 'Unknown Map'
            };
            console.log(`[Chess] Selected random map from TMX (${randomIndex + 1}/${response.results.length}): ${mapInfo.name} (${mapInfo.uid})`);
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

// Get a fallback map from Winter 2025 campaign
function getFallbackMap() {
  const fallbackMaps = [
    { uid: 'J3RyKSumRDcpqxza1y8PzvRitLl', name: 'Winter 2025 - 01' },
    { uid: 'OzeeWxmRNIeCiHEPQHiHaffNjEj', name: 'Winter 2025 - 02' },
    { uid: 'shPSqDL3bQ6nU6QmpHxJ_dVsI6k', name: 'Winter 2025 - 03' },
    { uid: 'YPRoZqXOe_fTPJpNKNFOd1IlRel', name: 'Winter 2025 - 04' },
    { uid: 'J0PHqGv4XovUkVOt5gTzzZQAk7d', name: 'Winter 2025 - 05' }
  ];
  return fallbackMaps[Math.floor(Math.random() * fallbackMaps.length)];
}

module.exports = {
  fetchRandomShortMap
};
