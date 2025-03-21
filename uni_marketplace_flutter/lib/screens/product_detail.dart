import 'package:flutter/material.dart';
import 'package:uni_marketplace_flutter/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Map<String, dynamic> fallbackProduct = {
  'name': 'Cargando...',
  'price': 'Cargando...',
  'description': 'Cargando...',
  'imageUrl': 'assets/images/loading.gif',
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
  const ProductDetail({required this.productId, Key? key}) : super(key: key);

  @override
  _ProductDetailState createState() => _ProductDetailState();
}

class _ProductDetailState extends State<ProductDetail> {
  bool showBidders = false;
  bool showPlaceBid = false;
  List<Map<String, dynamic>> users = [];
  Map<String, dynamic> product = fallbackProduct;
  List<Map<String, dynamic>> bids = [];
  TextEditingController bidController = TextEditingController();
  String? bidError;
  int? highestBid;

  @override
  void initState() {
    super.initState();
    loadProduct();
    loadBids();
  }

  int getMinimumBid() {
    int base =
        highestBid ??
        int.tryParse(product['baseBid'].toString().replaceAll('.', '')) ??
        0;
    return (base * 1.05).ceil();
  }

  Widget buildButtons() {
    List<String> types = List<String>.from(product['type'] ?? []);
    // Reordenar los tipos: siempre 'Sale', 'Rent', 'Bidding'
    List<String> order = ['Buy', 'Rent', 'Bidding'];
    types.sort((a, b) {
      int indexA = order.indexOf(a);
      int indexB = order.indexOf(b);
      return indexA.compareTo(indexB);
    });

    // Función para obtener el label correcto
    String getLabel(String type) {
      return type == 'Bidding' ? 'Place a Bid' : type;
    }

    if (types.length == 1) {
      return Center(
        child: ElevatedButton(
          onPressed: () => handleAction(types[0]),
          child: Text(
            getLabel(types[0]),
            style: TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF1F7A8C)),
        ),
      );
    } else if (types.length == 2) {
      return Row(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: 8),
              child: ElevatedButton(
                onPressed: () => handleAction(types[0]),
                child: Text(
                  getLabel(types[0]),
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1F7A8C),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: 8),
              child: ElevatedButton(
                onPressed: () => handleAction(types[1]),
                child: Text(
                  getLabel(types[1]),
                  style: TextStyle(color: Colors.black),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFE1E5F2),
                ),
              ),
            ),
          ),
        ],
      );
    } else if (types.length == 3) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => handleAction(types[0]),
                  child: Text(
                    getLabel(types[0]),
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
                  onPressed: () => handleAction(types[1]),
                  child: Text(
                    getLabel(types[1]),
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
              onPressed: () => handleAction(types[2]),
              child: Text(
                getLabel(types[2]),
                style: TextStyle(color: Colors.black),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromRGBO(186, 208, 223, 1),
              ),
            ),
          ),
        ],
      );
    }
    return SizedBox();
  }

  void handleAction(String type) {
    if (type == 'Bidding') {
      setState(() {
        showPlaceBid = true;
        showBidders = false;
      });
    }
  }

  Future<void> loadProduct() async {
    var productData = await FirestoreService().getProductById(widget.productId);
    if (productData != null) {
      setState(() {
        product = {
          'name': productData['title'] ?? 'No Name',
          'price': productData['price'].toString(),
          'description': productData['description'] ?? 'No description',
          'imageUrl': productData['image'] ?? 'assets/images/loading.gif',
          'baseBid': productData['baseBid'] ?? '50.000',
          'type': productData["type"] ?? [],
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

    int maxBid =
        int.tryParse(product['baseBid'].toString().replaceAll('.', '')) ?? 0;
    for (var item in combined) {
      int bidAmount = item['bid']['amount'] ?? 0;
      if (bidAmount > maxBid) {
        maxBid = bidAmount;
      }
    }
    highestBid = maxBid;

    setState(() {
      bidWithUser = combined;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                  child:
                      product['imageUrl'].toString().startsWith('http')
                          ? Image.network(
                            product['imageUrl'],
                            fit: BoxFit.contain,
                          )
                          : Image.asset(
                            product['imageUrl'],
                            fit: BoxFit.contain,
                          ),
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

              buildButtons(),
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
                                    TextSpan(text: ' ${getMinimumBid()} COP'),
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
                                controller: bidController,
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
                              if (bidError != null) ...[
                                SizedBox(height: 4),
                                Text(
                                  bidError!,
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        final bidValue =
                            int.tryParse(
                              bidController.text.replaceAll('.', ''),
                            ) ??
                            0;
                        final baseBid =
                            highestBid ??
                            int.tryParse(
                              product['baseBid'].toString().replaceAll('.', ''),
                            ) ??
                            0;
                        if (bidValue < baseBid) {
                          setState(() {
                            bidError = 'El valor debe ser mayor al mínimo';
                          });
                        } else {
                          setState(() {
                            bidError = null;
                          });
                          final bidData = {
                            'amount': bidValue,
                            'bidder': '202113407',
                            'productId': widget.productId,
                            'createdAt': Timestamp.now(),
                          };
                          FirestoreService().placeBid(bidData);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Bid placed successfully')),
                          );
                          bidController.clear();
                          await loadProduct();
                          await loadBids();
                          setState(() {
                            showPlaceBid = false;
                            showBidders = true;
                          });
                        }
                      },
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
                bidWithUser.isEmpty
                    ? Center(child: Text('No hay bids'))
                    : ListView.builder(
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
                                    backgroundImage: NetworkImage(user?['image'] ?? ''),
                                    radius: 30,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    user != null
                                        ? user['name'] ?? 'Unknown'
                                        : 'User not found',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
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
                if (product['type']?.contains('Bidding') ?? false) ...[
                  ListTile(
                    title: Text(
                      'Bidding for this item',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      'Starts at \$${getMinimumBid() ?? 'N/A'}',
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
            ],
          ),
        ),
      ),
    );
  }
}
