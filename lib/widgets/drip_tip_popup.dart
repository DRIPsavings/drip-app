import 'package:flutter/material.dart';

class DripTipPopup extends StatelessWidget {
  const DripTipPopup({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Image
          Image.asset(
            'assets/drip_tip_background.png',
            fit: BoxFit.contain,
          ),

          // Buttons on top of background
          Positioned(
            bottom: 90, // You can adjust this number later if needed
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // $1 Button
                GestureDetector(
                  onTap: () {
                    // TODO: Handle $1.00 purchase
                    Navigator.pop(context);
                  },
                  child: Image.asset('assets/tip_1_dollar.png', height: 70),
                ),
                const SizedBox(height: 12),

                // $2 Button
                GestureDetector(
                  onTap: () {
                    // TODO: Handle $2.00 purchase
                    Navigator.pop(context);
                  },
                  child: Image.asset('assets/tip_2_dollar.png', height: 70),
                ),
                const SizedBox(height: 12),

                // No Thank You Button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Image.asset('assets/no_thank_you.png', height: 70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}