double clampDeltaTime(double dt, double maxDt) {
  if (dt < 0) {
    return 0;
  }
  if (dt > maxDt) {
    return maxDt;
  }
  return dt;
}
