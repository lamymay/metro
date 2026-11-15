/// 把 `PlayerEngine` 的符号透出给 `import Player` 的调用方。
///
/// 拆层之后 `SongItem` / `ABRepeatMode` / `PlaybackCoordinator` 等搬到了 PlayerEngine，
/// 若不重导出，所有现有 `import Player` 的代码都要额外加一行 import。
/// 这里让 `Player` 作为完整音乐 App 的伞形模块，对外维持原有 API 面不变。
///
/// 注意方向：只是「上层把下层透出」，下层仍然看不见上层 —— 分层约束没有被削弱。
@_exported import PlayerEngine
