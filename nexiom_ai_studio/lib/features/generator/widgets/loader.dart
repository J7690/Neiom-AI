import 'package:flutter/material.dart';

class Loader extends StatelessWidget {
  final String? message;

  const Loader({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 48,
          height: 48,
          child: CircularProgressIndicator(),
        ),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ],
    );
  }
}
