///This class is to identify player associated with any type.
class PlayerIdentifier<T> {
  ///An unique key associated with player.
  String playerKey;

  ///A generic type which is associated to player
  T type;

  PlayerIdentifier(this.playerKey, this.type);
}
