void Main() {
    Network::Init();
    InitializeGlobals();
}

void Update(float dt) {
    Network::Update();
}

void OnDestroyed() {
    print("[Chess] Plugin unloading - disconnecting from server");
    Network::Disconnect();
    print("[Chess] Disconnected from server");
}

void Render() {
    if (!showWindow) return;

    EnsurePieceAssetsLoaded();

    vec2 screenSize = vec2(Draw::GetWidth(), Draw::GetHeight());
    float defaultHeight = screenSize.y * 0.5f;
    float defaultWidth = defaultHeight * 1.0f;
    UI::SetNextWindowSize(int(defaultWidth), int(defaultHeight), UI::Cond::FirstUseEver);

    int windowFlags = windowResizeable ? 0 : UI::WindowFlags::NoResize;

    vec2 mainWindowPos;
    vec2 mainWindowSize;

    MainMenu();
}

void RenderMenu() {
    if (UI::MenuItem("Chess Race")) {
        showWindow = !showWindow;
    }
}

void EnsurePieceAssetsLoaded() {
    if (!gPiecesLoaded) {
        LoadPieceAssets();
        gPiecesLoaded = true;
    }
}