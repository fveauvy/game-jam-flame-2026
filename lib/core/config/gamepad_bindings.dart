import 'dart:io';

import 'package:flutter/foundation.dart';

enum GamepadButton {
  leftStickXAxis,
  leftStickYAxis,
  rightStickXAxis,
  rightStickYAxis,
  dpadYAxis,
  dpadXAxis,
  dpadUp,
  dpadDown,
  dpadLeft,
  dpadRight,
  northButton, //using "north" because americans and japanese 🙄 am I right ?
  eastButton,
  southButton,
  westButton,
  startButton,
  selectButton,
  shareButton,
  homeButton,
  leftTrigger,
  rightTrigger,
  leftBumper,
  rightBumper,
  leftStickClick,
  rightStickClick,
  touchPadXAxis,
  touchPadYAxis;

  static GamepadButton? getFromString(String buttonName) {
    if (kIsWeb || kIsWasm) {
      return GamepadBindings.controllerChrome[buttonName];
    }
    if (Platform.isMacOS) {
      // Try DS5 mapping first, then Pro Controller mapping
      return GamepadBindings.dS5controllerMacOs[buttonName] ??
          GamepadBindings.proControllerMacOs[buttonName];
    }

    final testMapping =
        GamepadBindings.controllerChrome[buttonName] ??
        GamepadBindings.dS5controllerMacOs[buttonName] ??
        GamepadBindings.proControllerMacOs[buttonName];
    if (testMapping != null) {
      debugPrint('Unhandled gamepad input: $buttonName');
    }
    return testMapping;
  }
}

abstract final class GamepadBindings {
  /// Mapping for Controller on MacOs
  static const Map<String, GamepadButton> dS5controllerMacOs = {
    "l.joystick - xAxis": GamepadButton.leftStickXAxis,
    "l.joystick - yAxis": GamepadButton.leftStickYAxis,

    "r.joystick - xAxis": GamepadButton.rightStickXAxis,
    "r.joystick - yAxis": GamepadButton.rightStickYAxis,

    "dpad - xAxis": GamepadButton.dpadXAxis,
    "dpad - yAxis": GamepadButton.dpadYAxis,

    "xmark.circle": GamepadButton.southButton, // X on DS5
    "circle.circle": GamepadButton.eastButton, // O on DS5
    "square.circle": GamepadButton.westButton, // □ on DS5
    "triangle.circle": GamepadButton.northButton, // △ on DS5

    "l1.rectangle.roundedbottom": GamepadButton.leftTrigger,
    "r1.rectangle.roundedbottom": GamepadButton.rightTrigger,
    //fun fact L2 and R2 are analog, but we will treat it as a button for simplicity
    "l2.rectangle.roundedtop": GamepadButton.leftBumper,
    "r2.rectangle.roundedtop": GamepadButton.rightBumper,

    "plus.rectangle": GamepadButton.selectButton, // on Pad
    "capsule.portrait": GamepadButton.startButton, // option on ds5

    "l.joystick.down": GamepadButton.leftStickClick,
    "r.joystick.down": GamepadButton.rightStickClick,

    "hand.draw - xAxis": GamepadButton.touchPadXAxis,
    "hand.draw - yAxis": GamepadButton.touchPadYAxis,
  };

  static const Map<String, GamepadButton> proControllerMacOs = {
    "l.joystick - xAxis": GamepadButton.leftStickXAxis,
    "l.joystick - yAxis": GamepadButton.leftStickYAxis,

    "r.joystick - xAxis": GamepadButton.rightStickXAxis,
    "r.joystick - yAxis": GamepadButton.rightStickYAxis,

    "dpad - xAxis": GamepadButton.dpadXAxis,
    "dpad - yAxis": GamepadButton.dpadYAxis,

    "b.circle": GamepadButton.southButton, // B on Pro Controller
    "a.circle": GamepadButton.eastButton, // A on Pro Controller
    "y.circle": GamepadButton.westButton, // Y on Pro Controller
    "x.circle": GamepadButton.northButton, // X on Pro Controller

    "l.rectangle.roundedbottom": GamepadButton.leftTrigger,
    "r.rectangle.roundedbottom": GamepadButton.rightTrigger,
    //fun fact L2 and R2 are analog, but we will treat it as a button for simplicity
    "zl.rectangle.roundedtop": GamepadButton.leftBumper,
    "zr.rectangle.roundedtop": GamepadButton.rightBumper,

    "minus.circle": GamepadButton.selectButton, // on Pad
    "plus.circle": GamepadButton.startButton, // option on ds5
    "square.and.arrow.up":
        GamepadButton.shareButton, // screenshot on Pro Controller

    "l.joystick.down": GamepadButton.leftStickClick,
    "r.joystick.press.down": GamepadButton.rightStickClick,
  };

  /// Mapping for Nintendo Switch Pro Controller on Chrome. (also work for DS5)
  static const Map<String, GamepadButton> controllerChrome = {
    "analog 0": GamepadButton.leftStickXAxis,
    "analog 1": GamepadButton.leftStickYAxis,

    "analog 2": GamepadButton.rightStickXAxis,
    "analog 3": GamepadButton.rightStickYAxis,

    "button 0": GamepadButton.southButton, // B on Pro Controller
    "button 1": GamepadButton.eastButton, // A on Pro Controller
    "button 2": GamepadButton.westButton, // Y on Pro Controller
    "button 3": GamepadButton.northButton, // X on Pro Controller

    "button 4": GamepadButton.leftTrigger,
    "button 5": GamepadButton.rightTrigger,
    "button 6": GamepadButton.leftBumper,
    "button 7": GamepadButton.rightBumper,

    "button 8": GamepadButton.selectButton, // - on Pro Controller
    "button 9": GamepadButton.startButton, // + on Pro Controller

    "button 10": GamepadButton.leftStickClick,
    "button 11": GamepadButton.rightStickClick,

    "button 12": GamepadButton.dpadUp,
    "button 13": GamepadButton.dpadDown,
    "button 14": GamepadButton.dpadLeft,
    "button 15": GamepadButton.dpadRight,

    "button 16": GamepadButton.homeButton, // home on Pro Controller
    "button 17": GamepadButton.shareButton, // screenshot on Pro Controller
  };
}
