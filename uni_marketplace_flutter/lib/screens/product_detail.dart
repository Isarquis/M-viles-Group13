import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uni_marketplace_flutter/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uni_marketplace_flutter/models/product_model.dart';
import 'package:uni_marketplace_flutter/widgets/product_action_buttons.dart';
import 'package:uni_marketplace_flutter/widgets/place_bid.dart';
import '../widgets/show_bidders.dart';
import '../widgets/place_rent_offer.dart';
import '../viewmodels/product_detail_viewmodel.dart';

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
  bool showPlaceRentOffer = false;
  List<Map<String, dynamic>> users = [];
  TextEditingController bidController = TextEditingController();
  String? bidError;

  @override
  void initState() {
    super.initState();
    FirestoreService().logFeatureUsage('screen_product_detail');
  }

  int getMinimumBid(ProductDetailViewModel viewModel) {
    int base = viewModel.highestBid;
    return (base * 1.05).ceil();
  }

  void handleAction(String type) {
    FirestoreService().logFeatureUsage('button_$type');
    if (type == 'Bidding') {
      setState(() {
        showPlaceBid = true;
        showPlaceRentOffer = false;
        showBidders = false;
      });
    } else if (type == 'Rent') {
      setState(() {
        showPlaceRentOffer = true;
        showPlaceBid = false;
        showBidders = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProductDetailViewModel(widget.productId),
      child: Consumer<ProductDetailViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.product == null) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          final typesList = List<String>.from(viewModel.product?['type'] ?? []);
          final order = ['Buy', 'Rent', 'Bidding'];
          typesList.sort((a, b) {
            int indexA = order.indexOf(a);
            int indexB = order.indexOf(b);
            return indexA.compareTo(indexB);
          });
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
                                (viewModel.product?['imageUrl']?.toString().startsWith('http') ?? false)
                                ? Image.network(
                                  viewModel.product?['imageUrl'],
                                  fit: BoxFit.contain,
                                )
                                : Image.asset(
                                  viewModel.product?['imageUrl'],
                                  fit: BoxFit.contain,
                                ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      viewModel.product?['name'],
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    SizedBox(height: 8),
                    Center(
                      child: Text(
                        '\$${viewModel.product?['price']}',
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
                    Text(viewModel.product?['description']),
                    SizedBox(height: 16),

                    ProductActionButtons(
                      types: typesList,
                      selectedType: typesList.isNotEmpty ? typesList.first : '',
                      onPressed: handleAction,
                    ),
                    if (showPlaceRentOffer) ...[
                      PlaceRentOfferSection(
                        product: viewModel.product ?? fallbackProduct,
                        daysController: TextEditingController(),
                        priceController: TextEditingController(),
                        productId: widget.productId,
                        loadProduct: viewModel.loadProduct,
                        loadOffers: viewModel.loadRentOffers,
                        setShowRentOffer: (val) => setState(() => showPlaceRentOffer = val),
                        context: context,
                      ),
                    ] else if (showPlaceBid) ...[
                      PlaceBidSection(
                        product: viewModel.product ?? fallbackProduct,
                        bidController: bidController,
                        bidError: bidError,
                        getMinimumBid: () => getMinimumBid(viewModel),
                        highestBid: viewModel.highestBid,
                        productId: widget.productId,
                        loadProduct: viewModel.loadProduct,
                        loadBids: viewModel.loadBids,
                        context: context,
                        setShowPlaceBid: (val) => setState(() => showPlaceBid = val),
                        setShowBidders: (val) => setState(() => showBidders = val),
                      ),
                    ] else if (showBidders) ...[
                      BiddersWidget(
                        bidWithUser: viewModel.bidsWithUsers,
                        onClose: () => setState(() => showBidders = false),
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
                      if (viewModel.product?['type']?.contains('Bidding') ?? false) ...[
                        ListTile(
                          title: Text(
                            'Bidding for this item',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            'Starts at \$${getMinimumBid(viewModel) ?? 'N/A'}',
                            style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                          ),
                          trailing: Icon(Icons.arrow_forward),
                          onTap: () {
                            FirestoreService().logFeatureUsage('button_view_bidders');
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
        },
      ),
    );
  }
}
