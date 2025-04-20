import 'package:flutter/material.dart';

class BiddersWidget extends StatelessWidget {
  final List<Map<String, dynamic>> bidWithUser;
  final VoidCallback onClose;

  const BiddersWidget({super.key, required this.bidWithUser, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Bidders',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: onClose,
            ),
          ],
        ),
        const SizedBox(height: 10),
        bidWithUser.isEmpty
            ? const Center(child: Text('No hay bids'))
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: bidWithUser.length,
                itemBuilder: (context, index) {
                  final bid = bidWithUser[index]['bid'];
                  final user = bidWithUser[index]['user'];
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
                                    TextSpan(text: '${bid['createdAt'] ?? ''}'),
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
                                    TextSpan(text: '${bid['amount'] ?? ''} COP'),
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