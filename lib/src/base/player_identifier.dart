/// This class is to identify player associated with any generic type.
class PlayerIdentifier<T> {
  PlayerIdentifier(this.playerKey, this.type);

  /// An unique key associated with player.
  String playerKey;

  /// A generic type which is associated to player
  T type;
}
