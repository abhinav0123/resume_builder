import 'package:career_ai/models/sim_model.dart';
import 'package:flutter/material.dart';

import '../services/sim_service.dart';

class SimSelectionScreen extends StatefulWidget {
  const SimSelectionScreen({super.key});

  @override
  State<SimSelectionScreen> createState() => _SimSelectionScreenState();
}

class _SimSelectionScreenState extends State<SimSelectionScreen> {
  final SimService _simService = SimService();

  List<SimCard> simCards = [];

  int? selectedSubscriptionId;

  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadSimCards();
  }

  Future<void> loadSimCards() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final sims = await _simService.getSimCards();

      if (!mounted) return;

      setState(() {
        simCards = sims;
        selectedSubscriptionId =
            sims.isNotEmpty ? sims.first.subscriptionId : null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void continueWithSelectedSim() {
    final selectedSim = simCards.firstWhere(
      (sim) => sim.subscriptionId == selectedSubscriptionId,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Selected ${selectedSim.carrierName}',
        ),
      ),
    );

    // Next step:
    // Pass selectedSim.subscriptionId
    // to your SIM verification flow.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select SIM Card'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(errorMessage!),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: loadSimCards,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : simCards.isEmpty
                    ? const Center(
                        child: Text(
                          'No active SIM cards found',
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select your mobile SIM',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Choose the SIM card registered '
                            'with your bank account.',
                          ),
                          const SizedBox(height: 24),
                          Expanded(
                            child: ListView.builder(
                              itemCount: simCards.length,
                              itemBuilder: (context, index) {
                                final sim = simCards[index];

                                final isSelected = selectedSubscriptionId ==
                                    sim.subscriptionId;

                                return Card(
                                  margin: const EdgeInsets.only(
                                    bottom: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: isSelected
                                          ? Colors.blue
                                          : Colors.grey.shade300,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: RadioListTile<int>(
                                    value: sim.subscriptionId,
                                    groupValue: selectedSubscriptionId,
                                    onChanged: (value) {
                                      setState(() {
                                        selectedSubscriptionId = value;
                                      });
                                    },
                                    title: Text(
                                      sim.carrierName.isNotEmpty
                                          ? sim.carrierName
                                          : sim.displayName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'SIM ${sim.slotIndex + 1}',
                                    ),
                                    secondary: const Icon(
                                      Icons.sim_card,
                                      size: 32,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: selectedSubscriptionId == null
                                  ? null
                                  : continueWithSelectedSim,
                              child: const Text(
                                'Continue',
                                style: TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
      ),
    );
  }
}
