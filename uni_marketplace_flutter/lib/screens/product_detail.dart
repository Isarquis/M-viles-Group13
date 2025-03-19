import 'package:flutter/material.dart';

class ProductDetail extends StatelessWidget {
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
                child: Image.asset(
                  'assets/images/ProbabilidadYEstadistica.jpg',
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Probabilidad y estadística para ingeniería y ciencias',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              SizedBox(height: 8),
              Center(
                child: Text(
                  '\$35.000',
                  style: TextStyle(
                    color: Colors.red,
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
              Text(
                'Probabilidad y Estadística para Ingeniería y Ciencias ofrece un enfoque moderno y aplicado a las matemáticas, adoptado en todo el mundo.',
              ),
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
                  onPressed: () {},
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
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
