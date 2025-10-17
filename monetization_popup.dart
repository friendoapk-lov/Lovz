import 'package:flutter/material.dart';
import 'package:lovz/helpers/monetization_helper.dart';
import 'package:lovz/screens/diamond_store_screen.dart'; // Store screen ko import kiya

// Yeh ek global function hai jise hum kisi bhi screen se call kar sakte hain.
Future<MonetizationAction?> showMonetizationPopup({
  required BuildContext context,
  required String title,
  required List<MonetizationOption> options,
  required int currentUserDiamondBalance,
}) {
  return showModalBottomSheet<MonetizationAction>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
    ),
    builder: (BuildContext context) {
      return MonetizationPopup(
        title: title,
        options: options,
        currentUserDiamondBalance: currentUserDiamondBalance,
      );
    },
  );
}


class MonetizationPopup extends StatelessWidget {
  final String title;
  final List<MonetizationOption> options;
  final int currentUserDiamondBalance;

  const MonetizationPopup({
    super.key,
    required this.title,
    required this.options,
    required this.currentUserDiamondBalance,
  });

  @override
  Widget build(BuildContext context) {
    // ASLI FIX: Humne Column ko SingleChildScrollView se wrap kar diya hai
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // Saare options ko yahan list mein dikhayenge
            ...options.map((option) => _buildOptionTile(context, option)).toList(),
            const SizedBox(height: 20),
            _buildDiamondBalanceRow(context),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
  Widget _buildOptionTile(BuildContext context, MonetizationOption option) {
    // Check karo ki kya user ke paas sufficient diamonds hain
    final bool hasEnoughDiamonds = option.diamondCost == null || currentUserDiamondBalance >= option.diamondCost!;
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Icon(option.icon, color: option.color, size: 30),
        title: Text(option.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(option.subtitle),
        trailing: option.diamondCost != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    option.diamondCost.toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: hasEnoughDiamonds ? Colors.black : Colors.red,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.diamond_outlined, color: Colors.blueAccent, size: 20),
                ],
              )
            : null,
        onTap: () {
          // Agar option hi disabled hai, toh kuch mat karo
          if (!option.isEnabled) return;

          // Agar diamond wala option hai aur paise kam hain, toh kuch mat karo
          if (option.diamondCost != null && !hasEnoughDiamonds) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("You don't have enough diamonds!"),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
          // Agar sab theek hai, toh popup ko band karo aur action waapis bhejo
          Navigator.pop(context, option.action);
        },
        // NAYA LOGIC: Tile ko disable karo agar option.isEnabled false hai, 
        // ya agar diamonds kam hain.
        enabled: option.isEnabled && (option.diamondCost == null ? true : hasEnoughDiamonds),
      ),
    );
  }

  Widget _buildDiamondBalanceRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Your Balance: ", style: TextStyle(fontSize: 16)),
        Text(
          currentUserDiamondBalance.toString(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.diamond_outlined, color: Colors.blueAccent, size: 20),
        const Spacer(),
        TextButton.icon(
          icon: const Icon(Icons.add_shopping_cart),
          label: const Text("Get More"),
          onPressed: () {
            Navigator.pop(context); // Pehle is popup ko band karo
            // Phir Store screen par jao
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DiamondStoreScreen()),
            );
          },
        ),
      ],
    );
  }
}