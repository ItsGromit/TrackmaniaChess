void LoadPieceAssets() {
    gPieces.Load();
}
UI::Texture@ GetPieceTexture(const Piece &in p) {
    return gPieces.GetTexture(p);
}