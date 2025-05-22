import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/trip.dart';

class TripProvider with ChangeNotifier {
  late Box<Trip> _tripBox;
  List<Trip> _trips = [];

  List<Trip> get trips => _trips;
  List<Trip> get activeTrips =>
      _trips.where((trip) => trip.endDate.isAfter(DateTime.now())).toList();
  List<Trip> get pastTrips =>
      _trips.where((trip) => trip.endDate.isBefore(DateTime.now())).toList();

  Future<void> init() async {
    try {
      _tripBox = await Hive.openBox<Trip>('trips');
      _loadTrips();
    } catch (e) {
      debugPrint('Error initializing TripProvider: $e');
    }
  }

  void _loadTrips() {
    try {
      _trips = _tripBox.values.toList();
      _trips.sort((a, b) => b.startDate.compareTo(a.startDate));
      debugPrint('_loadTrips: Loaded ${_trips.length} trips');
      for (final trip in _trips) {
        debugPrint(
          '_loadTrips: tripId=${trip.id}, expenseIds=${trip.expenseIds}',
        );
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading trips: $e');
    }
  }

  Future<void> addTrip(Trip trip) async {
    try {
      await _tripBox.put(trip.id, trip);
      _loadTrips();
      debugPrint('Trip added successfully: ${trip.name}');
    } catch (e) {
      debugPrint('Error adding trip: $e');
    }
  }

  Future<void> updateTrip(Trip trip) async {
    try {
      await _tripBox.put(trip.id, trip);
      _loadTrips();
      debugPrint('Trip updated successfully: ${trip.name}');
    } catch (e) {
      debugPrint('Error updating trip: $e');
    }
  }

  Future<void> deleteTrip(String id) async {
    try {
      await _tripBox.delete(id);
      _loadTrips();
      debugPrint('Trip deleted successfully: $id');
    } catch (e) {
      debugPrint('Error deleting trip: $e');
    }
  }

  Trip? getTripById(String id) {
    try {
      return _trips.firstWhere((trip) => trip.id == id);
    } catch (e) {
      debugPrint('Error getting trip by id: $e');
      return null;
    }
  }

  Future<void> addParticipant(String tripId, String participant) async {
    try {
      final trip = getTripById(tripId);
      if (trip != null) {
        trip.participants.add(participant);
        await updateTrip(trip);
        debugPrint('Participant added successfully: $participant');
      }
    } catch (e) {
      debugPrint('Error adding participant: $e');
    }
  }

  Future<void> removeParticipant(String tripId, String participant) async {
    try {
      final trip = getTripById(tripId);
      if (trip != null) {
        trip.participants.remove(participant);
        await updateTrip(trip);
        debugPrint('Participant removed successfully: $participant');
      }
    } catch (e) {
      debugPrint('Error removing participant: $e');
    }
  }

  Future<void> addExpenseToTrip(String tripId, String expenseId) async {
    try {
      final trip = getTripById(tripId);
      if (trip != null) {
        trip.expenseIds.add(expenseId);
        await updateTrip(trip);
        debugPrint(
          'addExpenseToTrip: Added expenseId=$expenseId to tripId=$tripId. Now expenseIds: ${trip.expenseIds}',
        );
      }
    } catch (e) {
      debugPrint('Error adding expense to trip: $e');
    }
  }

  Future<void> removeExpenseFromTrip(String tripId, String expenseId) async {
    try {
      final trip = getTripById(tripId);
      if (trip != null) {
        trip.expenseIds.remove(expenseId);
        await updateTrip(trip);
        debugPrint('Expense removed from trip successfully: $expenseId');
      }
    } catch (e) {
      debugPrint('Error removing expense from trip: $e');
    }
  }

  Future<void> addManualSettlement(
    String tripId,
    ManualSettlement settlement,
  ) async {
    final trip = getTripById(tripId);
    if (trip != null) {
      trip.settlements.add(settlement);
      await updateTrip(trip);
      notifyListeners();
    }
  }

  Future<void> removeManualSettlement(
    String tripId,
    ManualSettlement settlement,
  ) async {
    final trip = getTripById(tripId);
    if (trip != null) {
      trip.settlements.remove(settlement);
      await updateTrip(trip);
      notifyListeners();
    }
  }
}
