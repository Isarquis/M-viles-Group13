import 'package:flutter/material.dart';

class ProductActionButtons extends StatelessWidget {
  final List<String> types;
  final void Function(String) onPressed;
  final String selectedType;

  const ProductActionButtons({
    Key? key,
    required this.types,
    required this.onPressed,
    required this.selectedType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String getLabel(String type) => type == 'Bidding' ? 'Place a Bid' : type;

    if (types.isEmpty) {
      return SizedBox();
    }

    if (types.length == 1) {
      return Center(
        child: ElevatedButton(
          onPressed: () => onPressed(types[0]),
          child: Text(getLabel(types[0]), style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF1F7A8C)),
        ),
      );
    }

    if (types.length == 2) {
      return Row(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: 8),
              child: ElevatedButton(
                onPressed: () => onPressed(types[0]),
                child: Text(getLabel(types[0]), style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF1F7A8C)),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: 8),
              child: ElevatedButton(
                onPressed: () => onPressed(types[1]),
                child: Text(getLabel(types[1]), style: TextStyle(color: Colors.black)),
                style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFE1E5F2)),
              ),
            ),
          ),
        ],
      );
    }

    // 3 or more types: first two in a row, third centered below
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => onPressed(types[0]),
                child: Text(getLabel(types[0]), style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF1F7A8C)),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () => onPressed(types[1]),
                child: Text(getLabel(types[1]), style: TextStyle(color: Colors.black)),
                style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFE1E5F2)),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Center(
          child: ElevatedButton(
            onPressed: () => onPressed(types[2]),
            child: Text(getLabel(types[2]), style: TextStyle(color: Colors.black)),
            style: ElevatedButton.styleFrom(backgroundColor: Color.fromRGBO(186, 208, 223, 1)),
          ),
        ),
      ],
    );
  }
}
