import 'package:flutter/material.dart';
import 'ride_flow_state.dart';

class RideFlowController extends ChangeNotifier {
  RideFlowState _state = RideFlowState.pickupCollapsed;

  RideFlowState get state => _state;

  void goTo(RideFlowState newState) {
    if (_state == newState) return;
    _state = newState;
    notifyListeners();
  }

  /// Simple linear flow (used by Continue button)
  void next() {
    switch (_state) {
      case RideFlowState.pickupCollapsed:
        goTo(RideFlowState.driverFound);
        break;

      case RideFlowState.driverFound:
        goTo(RideFlowState.arrivingCollapsed);
        break;

      case RideFlowState.arrivingCollapsed:
        goTo(RideFlowState.arrivingExpanded);
        break;

      case RideFlowState.arrivingExpanded:
        goTo(RideFlowState.chat);
        break;

      default:
        break;
    }
  }
}