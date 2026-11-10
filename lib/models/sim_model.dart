class SimCard {
  final int subscriptionId;
  final int slotIndex;
  final String displayName;
  final String carrierName;
  final String countryIso;
  final bool isEmbedded;

  SimCard({
    required this.subscriptionId,
    required this.slotIndex,
    required this.displayName,
    required this.carrierName,
    required this.countryIso,
    required this.isEmbedded,
  });

  factory SimCard.fromMap(Map<dynamic, dynamic> map) {
    return SimCard(
      subscriptionId: map['subscriptionId'] as int,
      slotIndex: map['slotIndex'] as int,
      displayName: map['displayName'] ?? '',
      carrierName: map['carrierName'] ?? '',
      countryIso: map['countryIso'] ?? '',
      isEmbedded: map['isEmbedded'] ?? false,
    );
  }
}
