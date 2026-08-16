import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Subscription tier for the app.
enum SubscriptionTier { free, monthlyPremium, yearlyPremium }

/// Represents the user's current subscription state.
class SubscriptionState {
  const SubscriptionState({
    this.tier = SubscriptionTier.free,
    this.isPremium = false,
    this.isTrial = false,
    this.expirationDate,
    this.entitlementId,
    this.isLoading = false,
    this.error,
  });

  final SubscriptionTier tier;
  final bool isPremium;
  final bool isTrial;
  final DateTime? expirationDate;
  final String? entitlementId;
  final bool isLoading;
  final String? error;

  SubscriptionState copyWith({
    SubscriptionTier? tier,
    bool? isPremium,
    bool? isTrial,
    DateTime? expirationDate,
    String? entitlementId,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return SubscriptionState(
      tier: tier ?? this.tier,
      isPremium: isPremium ?? this.isPremium,
      isTrial: isTrial ?? this.isTrial,
      expirationDate: expirationDate ?? this.expirationDate,
      entitlementId: entitlementId ?? this.entitlementId,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Manages all subscription logic via RevenueCat.
///
/// The user is authenticated with Firebase BEFORE any subscription access.
/// RevenueCat is identified using the authenticated Firebase UID — never
/// the email, and never an anonymous customer.
class SubscriptionService {
  SubscriptionService({String? apiKey}) : _apiKey = apiKey;

  final String? _apiKey;
  static const _premiumEntitlementId = 'premium';

  bool _initialized = false;
  bool _identifying = false;

  /// Initializes RevenueCat. Must be called after Firebase auth is available.
  Future<void> initialize({required String firebaseUid}) async {
    if (_initialized) {
      // Re-identify if the UID changed (e.g. different user logged in).
      await _identify(firebaseUid);
      return;
    }

    final apiKey =
        _apiKey ?? const String.fromEnvironment('REVENUECAT_API_KEY');
    if (apiKey.isEmpty) {
      debugPrint(
        '[Subscriptions] RevenueCat API key not configured. '
        'Premium will be unavailable.',
      );
      return;
    }

    try {
      await Purchases.configure(
        PurchasesConfiguration(apiKey)..appUserID = firebaseUid,
      );
      _initialized = true;
    } catch (e) {
      debugPrint('[Subscriptions] RevenueCat init failed: $e');
    }
  }

  Future<void> _identify(String firebaseUid) async {
    if (_identifying) return;
    _identifying = true;
    try {
      await Purchases.logIn(firebaseUid);
    } catch (e) {
      debugPrint('[Subscriptions] RevenueCat identify failed: $e');
    } finally {
      _identifying = false;
    }
  }

  /// Loads the current customer info and returns the subscription state.
  Future<SubscriptionState> loadSubscriptionState() async {
    if (!_initialized) {
      return const SubscriptionState();
    }

    try {
      final info = await Purchases.getCustomerInfo();
      return _stateFromCustomerInfo(info);
    } catch (e) {
      return SubscriptionState(error: 'Could not load subscription status: $e');
    }
  }

  /// Purchases a package. Returns the updated subscription state.
  Future<SubscriptionState> purchase(Package package) async {
    if (!_initialized) {
      throw SubscriptionException(
        'RevenueCat is not initialized. Please try again.',
      );
    }

    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));
      return _stateFromCustomerInfo(result.customerInfo);
    } on PlatformException catch (e) {
      if (e.code == '1') {
        // User cancelled the purchase.
        throw SubscriptionException('Purchase was cancelled.');
      }
      throw SubscriptionException('Purchase failed: ${e.message}');
    } catch (e) {
      throw SubscriptionException('Purchase failed: $e');
    }
  }

  /// Restores previous purchases. Returns the updated subscription state.
  Future<SubscriptionState> restorePurchases() async {
    if (!_initialized) {
      throw SubscriptionException(
        'RevenueCat is not initialized. Please try again.',
      );
    }

    try {
      final info = await Purchases.restorePurchases();
      return _stateFromCustomerInfo(info);
    } catch (e) {
      throw SubscriptionException('Restore failed: $e');
    }
  }

  /// Returns the available offering packages (monthly + yearly).
  Future<List<Package>> getPackages() async {
    if (!_initialized) return const [];

    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      if (current == null) return const [];
      return current.availablePackages;
    } catch (e) {
      debugPrint('[Subscriptions] Could not load offerings: $e');
      return const [];
    }
  }

  SubscriptionState _stateFromCustomerInfo(CustomerInfo info) {
    final entitlement = info.entitlements.active[_premiumEntitlementId];
    if (entitlement == null) {
      return const SubscriptionState();
    }

    final isTrial =
        entitlement.isSandbox == true ||
        (entitlement.periodType == PeriodType.intro ||
            entitlement.periodType == PeriodType.trial);

    // Determine tier from the product identifier.
    final productId = entitlement.productIdentifier.toLowerCase();
    final tier = productId.contains('yearly')
        ? SubscriptionTier.yearlyPremium
        : SubscriptionTier.monthlyPremium;

    // expirationDate is a String? in RevenueCat v10 — parse it.
    DateTime? expiration;
    final rawExpiration = entitlement.expirationDate;
    if (rawExpiration != null && rawExpiration.isNotEmpty) {
      expiration = DateTime.tryParse(rawExpiration);
    }

    return SubscriptionState(
      tier: tier,
      isPremium: true,
      isTrial: isTrial,
      expirationDate: expiration,
      entitlementId: entitlement.identifier,
    );
  }

  /// Logs out of RevenueCat. Called during the app logout flow.
  Future<void> logOut() async {
    if (!_initialized) return;
    try {
      await Purchases.logOut();
    } catch (e) {
      debugPrint('[Subscriptions] RevenueCat logout failed: $e');
    }
  }
}

/// A user-friendly subscription error.
class SubscriptionException implements Exception {
  const SubscriptionException(this.message);

  final String message;

  @override
  String toString() => message;
}
