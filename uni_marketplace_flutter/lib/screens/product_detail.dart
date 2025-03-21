import 'package:flutter/material.dart';
import 'package:uni_marketplace_flutter/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Map<String, dynamic> fallbackProduct = {
  'name': 'Cargando...',
  'price': 'Cargando...',
  'description': 'Cargando...',
  'imageUrl': 'assets/images/ProbabilidadYEstadistica.jpg',
};

List<Map<String, dynamic>> fallbackBids = [
  {
    'bidderName': 'Juan Herrera',
    'time': '1 Day - 14/10/25',
    'price': '5.000',
    'contact': '+57 323 122 3511',
    'email': 'j.herrera@uniandes.edu.co',
  },
];

class ProductDetail extends StatefulWidget {
  final String productId;
  const ProductDetail({required this.productId, super.key});

  @override
  _ProductDetailState createState() => _ProductDetailState();
}

class _ProductDetailState extends State<ProductDetail> {
  bool showBidders = false;
  bool showPlaceBid = false;
  List<Map<String, dynamic>> users = [];
  Map<String, dynamic> product = fallbackProduct;
  List<Map<String, dynamic>> bids = [];

  @override
  void initState() {
    super.initState();
    loadProduct();
    loadBids();
  }

  Future<void> loadProduct() async {
    var productData = await FirestoreService().getProductById(widget.productId);
    if (productData != null) {
      setState(() {
        product = {
          'name': productData['title'] ?? 'No Name',
          'price': productData['price'].toString(),
          'description': productData['description'] ?? 'No description',
          'imageUrl':
              productData['image'] ??
              'assets/images/ProbabilidadYEstadistica.jpg',
          'baseBid': productData['baseBid'] ?? '50.000',
        };
      });
    }
  }

  List<Map<String, dynamic>> bidWithUser = [];

  Future<void> loadBids() async {
    var combined = await FirestoreService().getBidsWithUsersByProduct(
      widget.productId,
    );

    for (var item in combined) {
      var bid = item['bid'];
      if (bid['createdAt'] is Timestamp) {
        var ts = bid['createdAt'] as Timestamp;
        var date = ts.toDate();
        bid['createdAt'] =
            '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
      }
    }

    setState(() {
      bidWithUser = combined;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: BackButton(), elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                  ),
                  child: product['imageUrl'].toString().startsWith('http')
                      ? Image.network(product['imageUrl'], fit: BoxFit.contain)
                      : Image.asset(product['imageUrl'], fit: BoxFit.contain),
                ),
              ),
              SizedBox(height: 16),
              Text(
                product['name'],
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              SizedBox(height: 8),
              Center(
                child: Text(
                  '\$${product['price']}',
                  style: TextStyle(
                    color: Color(0xFF2B7B35),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Description',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(product['description']),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      child: Text(
                        'Rent',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF1F7A8C),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      child: Text(
                        'Buy Now',
                        style: TextStyle(color: Colors.black),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFE1E5F2),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      showPlaceBid = true;
                      showBidders = false;
                    });
                  },
                  child: Text(
                    'Place a Bid',
                    style: TextStyle(color: Colors.black),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromRGBO(186, 208, 223, 1),
                  ),
                ),
              ),
              SizedBox(height: 16),
              if (showPlaceBid) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              showPlaceBid = false;
                            });
                          },
                        ),
                      ],
                    ),
                    Text(
                      'Make a Bid',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        product['imageUrl'].toString().startsWith('http')
                            ? Image.network(product['imageUrl'], width: 100)
                            : Image.asset(product['imageUrl'], width: 100),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  style: TextStyle(color: Colors.black),
                                  children: [
                                    TextSpan(
                                      text: 'Minimum bidding price:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' ${product['baseBid'] ?? ''} COP',
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Set your Price:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 8),
                              TextField(
                                decoration: InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  hintText: 'ej. 35.000',
                                  hintStyle: TextStyle(color: Colors.blueGrey),
                                  filled: true,
                                  fillColor: Color(0xFFE1E5F2),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {},
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        child: Text(
                          'Make Bid',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF1F7A8C),
                      ),
                    ),
                  ],
                ),
              ] else if (showBidders) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Bidders',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          showBidders = false;
                        });
                      },
                    ),
                  ],
                ),
                SizedBox(height: 10),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
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
                                backgroundImage: AssetImage(
                                  'assets/images/bidder${index + 1}.jpg',
                                ),
                                radius: 30,
                              ),
                              SizedBox(height: 4),
                              Text(
                                user != null
                                    ? user['name'] ?? 'Unknown'
                                    : 'User not found',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    style: TextStyle(color: Colors.black),
                                    children: [
                                      TextSpan(
                                        text: 'Time: ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      TextSpan(
                                        text: '${bid['createdAt'] ?? ''}',
                                      ),
                                    ],
                                  ),
                                ),
                                RichText(
                                  text: TextSpan(
                                    style: TextStyle(color: Colors.black),
                                    children: [
                                      TextSpan(
                                        text: 'Amount: ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      TextSpan(
                                        text: '${bid['amount'] ?? ''} COP',
                                      ),
                                    ],
                                  ),
                                ),
                                Text('+57 ${user?['phone'] ?? ''}'),
                                Text(
                                  user?['email'] ?? '',
                                  style: TextStyle(
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ] else ...[
                Divider(),
                ListTile(
                  title: Text(
                    'Similar items',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Text(
                    'See more',
                    style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                  ),
                  trailing: Icon(Icons.arrow_forward),
                  onTap: () {},
                ),
                ListTile(
                  title: Text(
                    'Bidding for this item',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Text(
                    'Starts at \$20',
                    style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                  ),
                  trailing: Icon(Icons.arrow_forward),
                  onTap: () {
                    setState(() {
                      showBidders = true;
                    });
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}