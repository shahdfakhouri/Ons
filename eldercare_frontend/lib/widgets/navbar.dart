import 'package:flutter/material.dart';

class Navbar extends StatelessWidget {
  const Navbar({super.key}); // <-- const constructor

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Ons Eldercare',
            style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
          ),
          Row(
            children: [
              _item('Home'),
              _item('Our Campus'),
              _item('Community'),
              _item('About'),
              _item('Contact'),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
                child: const Text('Reach Out'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _item(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: TextButton(
        onPressed: () {},
        child: Text(label,
            style: const TextStyle(color: Colors.teal, fontSize: 14)),
      ),
    );
  }
}
