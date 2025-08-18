import 'package:flutter/material.dart';
import 'package:water_quality_analysis/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io' show Platform;
import 'package:flutter/services.dart';
import 'package:water_quality_analysis/pages/filter_product_details_page.dart';

class FilterSearchPage extends StatefulWidget {
  const FilterSearchPage({Key? key}) : super(key: key);

  @override
  State<FilterSearchPage> createState() => _FilterSearchPageState();
}

class _FilterSearchPageState extends State<FilterSearchPage> {
  String selectedFilter = 'All';
  final List<String> filterOptions = [
    'All',
    'Carbon',
    'Reverse Osmosis',
    'Nanofiltration',
    'Alkaline'
  ];
  List<FilterProduct> products = [];
  List<FilterProduct> filteredProducts = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterProducts);
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('filters')
          .get();

      setState(() {
        products = snapshot.docs
            .map((doc) => FilterProduct.fromFirestore(doc))
            .toList();
        filteredProducts = List.from(products);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load products: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _launchProductLink(String url) async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        final uri = Uri.parse(url);
        await SystemChannels.platform.invokeMethod('SystemNavigator.route', url);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Platform not supported')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening link: ${e.toString()}')),
        );
      }
    }
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty && selectedFilter == 'All') {
        filteredProducts = List.from(products);
      } else {
        filteredProducts = products.where((product) {
          final matchesQuery = query.isEmpty || 
              product.title.toLowerCase().contains(query) ||
              product.features.toLowerCase().contains(query) ||
              product.purificationMethod.toLowerCase().contains(query);
          
          final matchesFilter = selectedFilter == 'All' || 
              product.purificationMethod.toLowerCase().contains(selectedFilter.toLowerCase());
          
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
        title: const Text('Water Filter Products'),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : Column(
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
                                // suffixIcon: IconButton(
                                //   icon: const Icon(Icons.mic),
                                //   onPressed: () {
                                //     // Voice search functionality
                                //   },
                                // ),
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
                                _filterProducts();
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
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FilterProductDetailsPage(
              title: product.title,
              image: product.image,
              link: product.link,
              price: product.price,
              dimension: product.dimension,
              features: product.features,
              purificationMethod: product.purificationMethod,
              volumeCapacity: product.volumeCapacity,
              weight: product.weight,
            ),
          ),
        );
      },
      child: Card(
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
                child: product.image.isNotEmpty
                    ? Image.network(
                        product.image,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.image_not_supported,
                              size: 48,
                              color: Colors.grey,
                            ),
                          );
                        },
                      )
                    : const Center(
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
                  Text(
                    product.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.price,
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
      ),
    );
  }
}

class FilterProduct {
  final String title;
  final String image;
  final String link;
  final String price;
  final String dimension;
  final String features;
  final String purificationMethod;
  final String volumeCapacity;
  final String weight;

  FilterProduct({
    required this.title,
    required this.image,
    required this.link,
    required this.price,
    required this.dimension,
    required this.features,
    required this.purificationMethod,
    required this.volumeCapacity,
    required this.weight,
  });

  factory FilterProduct.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return FilterProduct(
      title: data['name'] ?? '',
      image: data['image_url'] ?? '',
      link: data['link'] ?? '',
      price: data['price'] ?? '',
      dimension: data['dimension'] ?? '',
      features: data['features'] ?? '',
      purificationMethod: data['purification_method'] ?? '',
      volumeCapacity: data['volume_capacity'] ?? '',
      weight: data['weight'] ?? '',
    );
  }
}