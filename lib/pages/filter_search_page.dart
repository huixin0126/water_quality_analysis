import 'package:flutter/material.dart';
import 'package:water_quality_analysis/main.dart';

class FilterSearchPage extends StatefulWidget {
  const FilterSearchPage({Key? key}) : super(key: key);

  @override
  State<FilterSearchPage> createState() => _FilterSearchPageState();
}

class _FilterSearchPageState extends State<FilterSearchPage> {
  String selectedFilter = 'All';
  final List<String> filterOptions = ['All', 'Carbon', 'Reverse Osmosis', 'UV', 'Ceramic'];
  final List<FilterProduct> products = [
    FilterProduct(
      title: 'Premium Carbon Filter',
      image: 'assets/images/filter1.png',
      soldCount: 587,
      price: 29.99,
      rating: 4.7,
    ),
    FilterProduct(
      title: 'Ultra Pure RO System',
      image: 'assets/images/filter2.png',
      soldCount: 532,
      price: 149.99,
      rating: 4.8,
    ),
    FilterProduct(
      title: 'Multi-Stage Water Filter',
      image: 'assets/images/filter3.png',
      soldCount: 421,
      price: 79.99,
      rating: 4.5,
    ),
    FilterProduct(
      title: 'Ceramic Filter Cartridge',
      image: 'assets/images/filter4.png',
      soldCount: 348,
      price: 45.99,
      rating: 4.3,
    ),
  ];
  
  List<FilterProduct> filteredProducts = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredProducts = List.from(products);
    _searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty && selectedFilter == 'All') {
        filteredProducts = List.from(products);
      } else {
        filteredProducts = products.where((product) {
          final matchesQuery = product.title.toLowerCase().contains(query);
          final matchesFilter = selectedFilter == 'All' || 
              product.title.toLowerCase().contains(selectedFilter.toLowerCase());
          return matchesQuery && matchesFilter;
        }).toList();
      }
    });
  }

  void _applyFilter(String filter) {
    setState(() {
      selectedFilter = filter;
      _filterProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Filter Search & Recommendation'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.mic),
                        onPressed: () {
                          // Voice search functionality
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.search, color: Colors.white),
                    onPressed: () {
                      // Search action
                    },
                  ),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Text(
                  'Filter: ',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedFilter,
                      items: filterOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          _applyFilter(newValue);
                        }
                      },
                      icon: const Icon(Icons.keyboard_arrow_down),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Products Grid
          Expanded(
            child: filteredProducts.isEmpty
                ? const Center(
                    child: Text('No products found'),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      return _buildProductCard(product);
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildProductCard(FilterProduct product) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: const Center(
                child: Icon(
                  Icons.image,
                  size: 48,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
          
          // Product Details
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        product.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        // Toggle favorite
                      },
                      child: const Icon(
                        Icons.favorite_border,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${product.soldCount}+ items sold',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      product.rating.toString(),
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${product.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF6366F1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FilterProduct {
  final String title;
  final String image;
  final int soldCount;
  final double price;
  final double rating;

  FilterProduct({
    required this.title,
    required this.image,
    required this.soldCount,
    required this.price,
    required this.rating,
  });
}