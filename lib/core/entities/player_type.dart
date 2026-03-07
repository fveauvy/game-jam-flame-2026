enum PlayerType {
  land,
  middle,
  water;


  PlayerType get bellow {
    switch (this) {
      case PlayerType.land:
        return PlayerType.middle;
      case PlayerType.middle:
        return PlayerType.water;
      case PlayerType.water:
        return PlayerType.water; // water is the lowest, so it returns itself
    }
  }

  PlayerType get above {
    switch (this) {
      case PlayerType.land:
        return PlayerType.land; // land is the highest, so it returns itself
      case PlayerType.middle:
        return PlayerType.land;
      case PlayerType.water:
        return PlayerType.middle;
    }
  }
}