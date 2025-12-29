void TestRerollMap() {
    print("[Chess] Developer: Re-rolling to new map");
    // Fetch a random map from the current campaign
    // Start a coroutine to fetch from TMX
    startnew(FetchDevRandomMap);
}