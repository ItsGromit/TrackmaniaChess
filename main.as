void Main() {
    Init();
    InitializeGlobals();
}

void Update(float dt) {
    Update();
    DummyClient::Update();
}

void RenderMenu() {
    if (UI::MenuItem("Chess Race")) {
        showWindow = !showWindow;
    }
}

void Render() {
    if (showWindow) {
        MainMenu();
    }
}