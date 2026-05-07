import 'package:flutter/material.dart';

class AppleButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;
  final String buttonText;
  const AppleButton(
      {super.key,
      required this.isLoading,
      required this.onPressed,
      required this.buttonText});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        icon: const Icon(Icons.apple, size: 24),
        label: Text(buttonText),
        onPressed: isLoading ? null : onPressed,
      ),
    );
  }
}
