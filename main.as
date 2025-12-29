void Main() {
    Init();
    InitializeGlobals();
}

void Update(float dt) {
    Update();
    DummyClient::Update();
}