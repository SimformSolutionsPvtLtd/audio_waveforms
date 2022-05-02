///This class is to identify each current duration position which is
///associated to which player.
class CurrentDurationIndentifier {
  ///Unique key associated with any [player].
  String playerKey;

  ///current duration associated with that [key].
  int duration;

  CurrentDurationIndentifier(this.playerKey, this.duration);
}
