import 'package:flutter/material.dart';

class ShowRentOfferers extends StatelessWidget {
  final List<Map<String, dynamic>> offers;
  final VoidCallback onClose;

  const ShowRentOfferers({super.key, required this.offers, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RentOfferersWidget(offers: offers, onClose: onClose),
      ],
    );
  }
}

class RentOfferersWidget extends StatelessWidget {
  final List<Map<String, dynamic>> offers;
  final VoidCallback onClose;

  const RentOfferersWidget({super.key, required this.offers, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Rent Offers',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: onClose,
            ),
          ],
        ),
        const SizedBox(height: 10),
        offers.isEmpty
            ? const Center(child: Text('No hay ofertas'))
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: offers.length,
                itemBuilder: (context, index) {
                  final offer = offers[index]['offer'];
                  final user = offers[index]['user'];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Row(
                      children: [
                        Column(
                          children: [
                            CircleAvatar(
                              backgroundImage: NetworkImage(user?['image'] ?? ''),
                              radius: 30,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user != null ? user['name'] ?? 'Unknown' : 'User not found',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  style: const TextStyle(color: Colors.black),
                                  children: [
                                    const TextSpan(
                                      text: 'Time: ',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    TextSpan(text: '${offer['createdAt'] ?? ''}'),
                                  ],
                                ),
                              ),
                              RichText(
                                text: TextSpan(
                                  style: const TextStyle(color: Colors.black),
                                  children: [
                                    const TextSpan(
                                      text: 'Days: ',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    TextSpan(text: '${offer['days'] ?? ''}'),
                                  ],
                                ),
                              ),
                              RichText(
                                text: TextSpan(
                                  style: const TextStyle(color: Colors.black),
                                  children: [
                                    const TextSpan(
                                      text: 'Amount: ',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    TextSpan(text: '\$${offer['amount'] ?? ''}'),
                                  ],
                                ),
                              ),
                              Text('+57 ${user?['phone'] ?? ''}'),
                              Text(
                                user?['email'] ?? '',
                                style: const TextStyle(decoration: TextDecoration.underline),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ],
    );
  }
}
