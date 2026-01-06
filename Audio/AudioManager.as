// ============================================================================
// AUDIO MANAGER
// ============================================================================
// Manages loading and playing sound effects for chess events
// Uses Trackmania's in-game audio system for checkpoint sounds
// ============================================================================

namespace ChessAudio {

// Sound type enum for game sounds
enum GameSound {
    CheckpointNormal,    // Regular checkpoint sound (for normal moves)
    CheckpointBetter,    // Better time checkpoint sound (for captures)
    CheckpointWorse,     // Worse time checkpoint sound (for opponent moves)
    RaceFinish,          // Race finish sound (for checkmate)
    Custom               // Custom loaded sounds
}

// Sound references for custom sounds (fallback)
Audio::Sample@ moveSound;
Audio::Sample@ captureSound;
Audio::Sample@ checkSound;
Audio::Sample@ checkmateSound;
Audio::Sample@ castleSound;

// Settings
[Setting category="Audio" name="Enable Sound Effects"]
bool enableSounds = true;

[Setting category="Audio" name="Use Game Sounds"]
bool useGameSounds = true;

[Setting category="Audio" name="Move Sound Volume" min=0.0 max=1.0]
float moveSoundVolume = 0.5f;

[Setting category="Audio" name="Capture Sound Volume" min=0.0 max=1.0]
float captureSoundVolume = 0.6f;

[Setting category="Audio" name="Check Sound Volume" min=0.0 max=1.0]
float checkSoundVolume = 0.7f;

[Setting category="Audio" name="Checkmate Sound Volume" min=0.0 max=1.0]
float checkmateSoundVolume = 0.8f;

[Setting category="Audio" name="Castle Sound Volume" min=0.0 max=1.0]
float castleSoundVolume = 0.6f;

/**
 * Loads all sound effects
 */
void LoadSounds() {
    string pluginStoragePath = IO::FromStorageFolder("");

    // Try to load custom sounds from PluginStorage folder, fallback to defaults
    @moveSound = LoadSound("move.wav", pluginStoragePath);
    @captureSound = LoadSound("capture.wav", pluginStoragePath);
    @checkSound = LoadSound("check.wav", pluginStoragePath);
    @checkmateSound = LoadSound("checkmate.wav", pluginStoragePath);
    @castleSound = LoadSound("castle.wav", pluginStoragePath);

    if (developerMode) {
        print("[Audio] Loaded chess sounds from: " + pluginStoragePath);
    }
}

/**
 * Loads a sound file, returns null if not found
 */
Audio::Sample@ LoadSound(const string &in filename, const string &in basePath) {
    string filepath = basePath + filename;

    // Check if file exists
    if (!IO::FileExists(filepath)) {
        if (developerMode) {
            print("[Audio] Sound file not found: " + filepath);
        }
        return null;
    }

    // Load the file
    IO::File file(filepath, IO::FileMode::Read);
    if (!file.IsOpen()) {
        warn("[Audio] Failed to open sound file: " + filepath);
        return null;
    }

    // Use streaming for large files (> 512KB)
    bool stream = file.Size() > 512 * 1024;
    auto sound = Audio::LoadSample(file.Read(file.Size()), stream);

    if (sound is null) {
        warn("[Audio] Failed to load sound: " + filepath);
    } else if (developerMode) {
        print("[Audio] Loaded sound: " + filename);
    }

    return sound;
}

/**
 * Plays a game sound using Trackmania's playground audio system
 * This triggers the same sounds that play during normal gameplay
 */
void PlayGameSound(GameSound soundType, float volume = 1.0f) {
    auto app = cast<CTrackMania>(GetApp());
    if (app is null) return;

    auto network = cast<CTrackManiaNetwork>(app.Network);
    if (network is null) return;

    auto playground = cast<CSmArenaClient>(network.PlaygroundClientScriptAPI);
    if (playground is null) return;

    // Try to access the game's UI system to trigger checkpoint sounds
    auto ui = playground.UI;
    if (ui is null) return;

    // Trigger different UI sounds based on the sound type
    // These correspond to the checkpoint feedback sounds
    switch (soundType) {
        case GameSound::CheckpointNormal:
            // Trigger normal checkpoint sound
            ui.SendNotice("", CGameScriptNotificationManager::ENoticeLevel::Neutral, CGameScriptNotificationManager::EAvatarVariant::Default,
                         CGameScriptNotificationManager::EUISound::Checkpoint, 0);
            break;
        case GameSound::CheckpointBetter:
            // Trigger better time sound
            ui.SendNotice("", CGameScriptNotificationManager::ENoticeLevel::Success, CGameScriptNotificationManager::EAvatarVariant::Default,
                         CGameScriptNotificationManager::EUISound::Checkpoint, 0);
            break;
        case GameSound::CheckpointWorse:
            // Trigger worse time sound
            ui.SendNotice("", CGameScriptNotificationManager::ENoticeLevel::Warning, CGameScriptNotificationManager::EAvatarVariant::Default,
                         CGameScriptNotificationManager::EUISound::Checkpoint, 0);
            break;
        case GameSound::RaceFinish:
            // Trigger finish sound
            ui.SendNotice("", CGameScriptNotificationManager::ENoticeLevel::Success, CGameScriptNotificationManager::EAvatarVariant::Default,
                         CGameScriptNotificationManager::EUISound::Finish, 0);
            break;
    }
}

/**
 * Plays a move sound effect (normal checkpoint sound)
 */
void PlayMoveSound() {
    if (!enableSounds) return;

    if (useGameSounds) {
        PlayGameSound(GameSound::CheckpointNormal, moveSoundVolume);
    } else if (moveSound !is null) {
        Audio::Play(moveSound, moveSoundVolume);
    }
}

/**
 * Plays a capture sound effect (better time checkpoint sound)
 */
void PlayCaptureSound() {
    if (!enableSounds) return;

    if (useGameSounds) {
        PlayGameSound(GameSound::CheckpointBetter, captureSoundVolume);
    } else if (captureSound !is null) {
        Audio::Play(captureSound, captureSoundVolume);
    }
}

/**
 * Plays a check sound effect (worse time checkpoint sound for tension)
 */
void PlayCheckSound() {
    if (!enableSounds) return;

    if (useGameSounds) {
        PlayGameSound(GameSound::CheckpointWorse, checkSoundVolume);
    } else if (checkSound !is null) {
        Audio::Play(checkSound, checkSoundVolume);
    }
}

/**
 * Plays a checkmate sound effect (race finish sound)
 */
void PlayCheckmateSound() {
    if (!enableSounds) return;

    if (useGameSounds) {
        PlayGameSound(GameSound::RaceFinish, checkmateSoundVolume);
    } else if (checkmateSound !is null) {
        Audio::Play(checkmateSound, checkmateSoundVolume);
    }
}

/**
 * Plays a castle sound effect (normal checkpoint)
 */
void PlayCastleSound() {
    if (!enableSounds) return;

    if (useGameSounds) {
        PlayGameSound(GameSound::CheckpointNormal, castleSoundVolume);
    } else if (castleSound !is null) {
        Audio::Play(castleSound, castleSoundVolume);
    }
}

} // namespace ChessAudio
