enum PlayerVerticalPosition {
  land,
  waterLevel,
  underwater;

  PlayerVerticalPosition get below {
    switch (this) {
      case PlayerVerticalPosition.land:
        return PlayerVerticalPosition.waterLevel;
      case PlayerVerticalPosition.waterLevel:
        return PlayerVerticalPosition.underwater;
      case PlayerVerticalPosition.underwater:
        return PlayerVerticalPosition.underwater;
    }
  }

  PlayerVerticalPosition get above {
    switch (this) {
      case PlayerVerticalPosition.land:
        return PlayerVerticalPosition.land;
      case PlayerVerticalPosition.waterLevel:
        return PlayerVerticalPosition.land;
      case PlayerVerticalPosition.underwater:
        return PlayerVerticalPosition.waterLevel;
    }
  }
}
