import 'package:flutter/material.dart';

class PickupSearchSheet extends StatelessWidget {
  final ScrollController scrollController;
  final VoidCallback onLocationSelected;

  const PickupSearchSheet({
    super.key,
    required this.scrollController,
    required this.onLocationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: ListView(
        controller: scrollController,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            decoration: InputDecoration(
              hintText: 'Search your pickup location',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 20),

          _item('My Location'),
          _item('Benin City'),
          _item('Afemai Transport Company'),
          _item('Ring Road Bus Terminal', onTap: onLocationSelected),
        ],
      ),
    );
  }

  Widget _item(String text, {VoidCallback? onTap}) {
    return ListTile(
      onTap: onTap,
      leading: const Icon(Icons.location_on_outlined),
      title: Text(text),
    );
  }
}
