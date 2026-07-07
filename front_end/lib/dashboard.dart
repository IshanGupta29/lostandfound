import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui'; // Needed for the frosted glass blur effect
import 'main.dart';
import 'create_report.dart';
import 'edit_report.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<dynamic> _allItems = [];
  List<dynamic> _displayedItems = [];
  bool _isLoading = false;
  
  String _filterType = 'all'; 
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchItems();
  }

  Future<void> fetchItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:5000/api/item/all'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> decodedData = jsonDecode(response.body);
        setState(() {
          _allItems = decodedData;
          _applyFiltersAndSearch();
        });
      } else {
        _showSnackBar('Failed to load items from server');
      }
    } catch (e) {
      _showSnackBar('Could not connect to server');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> updateItemStatus(String itemId, String currentStatus) async {
    final String nextStatus = currentStatus == 'active' ? 'claimed' : 'active';
    
    try {
      final response = await http.put(
        Uri.parse('http://127.0.0.1:5000/api/item/update'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'itemId': itemId,
          'status': nextStatus,
        }),
      );

      if (response.statusCode == 200) {
        _showSnackBar('Status updated!');
        fetchItems(); 
      } else {
        _showSnackBar('Failed to update status');
      }
    } catch (e) {
      _showSnackBar('Network error');
    }
  }

  void _applyFiltersAndSearch() {
    final query = _searchController.text.toLowerCase();
    
    setState(() {
      _displayedItems = _allItems.where((item) {
        final matchesFilter = _filterType == 'all' || item['type'] == _filterType;
        final title = (item['title'] ?? '').toString().toLowerCase();
        final description = (item['description'] ?? '').toString().toLowerCase();
        final matchesSearch = title.contains(query) || description.contains(query);
        
        return matchesFilter && matchesSearch;
      }).toList();
    });
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _showItemDetails(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isLost = item['type'] == 'lost';
        final isClaimed = item['status'] == 'claimed';

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Frosted glass blur
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95), // Slightly transparent bottom sheet
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
            ),
            padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Chip(
                          label: Text(item['type'].toString().toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                          backgroundColor: isLost ? Colors.red.shade100 : Colors.teal.shade100, // Teal for sea theme
                          side: BorderSide.none,
                        ),
                        const SizedBox(width: 8),
                        Chip(
                          label: Text(item['status'].toString().toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                          backgroundColor: isClaimed ? Colors.grey.shade300 : Colors.cyan.shade100, // Cyan for sea theme
                          side: BorderSide.none,
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.cyan.shade50, shape: BoxShape.circle),
                        child: Icon(Icons.edit, color: Colors.cyan.shade700, size: 20),
                      ),
                      onPressed: () async {
                        Navigator.pop(context); 
                        await Navigator.push(context, MaterialPageRoute(builder: (context) => EditReportScreen(item: item)));
                        fetchItems();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  item['title'] ?? 'No Title',
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: -0.5, color: Color(0xFF0F2027)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.cyan.shade600, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      item['location'] ?? 'Unknown location',
                      style: TextStyle(fontSize: 16, color: Colors.grey.shade800, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Divider(),
                ),
                const Text(
                  'Description',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  item['description'] ?? 'No additional details provided.',
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      updateItemStatus(item['_id'], item['status']);
                    },
                    icon: Icon(isClaimed ? Icons.lock_open : Icons.check_circle_outline),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isClaimed ? Colors.orange.shade400 : Colors.cyan.shade700, // Sea theme button
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    label: Text(
                      isClaimed ? 'Re-open as Active' : 'Mark as Claimed & Resolved',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Lets the sea background flow under the top bar
      appBar: AppBar(
        title: const Text('Campus Feed', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 24, letterSpacing: -0.5)),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent, // Transparent so the ocean shows through
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          )
        ],
      ),
      // THE SEA THEME BACKGROUND
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.cyan.shade400,   // Bright water surface at the top
              Colors.blue.shade700,   // Middle depth
              Colors.indigo.shade900, // Deep ocean at the bottom
            ],
          ),
        ),
        child: SafeArea( // Keeps content below the transparent app bar
          child: Column(
            children: [
              // The Frosted Glass Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      )
                    ]
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) => _applyFiltersAndSearch(),
                        style: const TextStyle(color: Colors.white), // White text typed by user
                        decoration: InputDecoration(
                          hintText: 'Search items...',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.2), // Glass effect
                          prefixIcon: const Icon(Icons.search, color: Colors.white),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.white70),
                                  onPressed: () {
                                    _searchController.clear();
                                    _applyFiltersAndSearch();
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Enhanced Filter Chips for Dark Background
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Row(
                  children: [
                    FilterChip(
                      label: Text('All Items', style: TextStyle(fontWeight: FontWeight.w600, color: _filterType == 'all' ? Colors.cyan.shade900 : Colors.white)),
                      selected: _filterType == 'all',
                      selectedColor: Colors.cyan.shade100,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      checkmarkColor: Colors.cyan.shade900,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide.none),
                      onSelected: (bool selected) {
                        setState(() {
                          _filterType = 'all';
                          _applyFiltersAndSearch();
                        });
                      },
                    ),
                    const SizedBox(width: 12),
                    FilterChip(
                      label: Text('Lost', style: TextStyle(fontWeight: FontWeight.w600, color: _filterType == 'lost' ? Colors.red.shade900 : Colors.white)),
                      selected: _filterType == 'lost',
                      selectedColor: Colors.red.shade100,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      checkmarkColor: Colors.red.shade900,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide.none),
                      onSelected: (bool selected) {
                        setState(() {
                          _filterType = 'lost';
                          _applyFiltersAndSearch();
                        });
                      },
                    ),
                    const SizedBox(width: 12),
                    FilterChip(
                      label: Text('Found', style: TextStyle(fontWeight: FontWeight.w600, color: _filterType == 'found' ? Colors.teal.shade900 : Colors.white)),
                      selected: _filterType == 'found',
                      selectedColor: Colors.teal.shade100, // Teal for found items in sea theme
                      backgroundColor: Colors.white.withOpacity(0.2),
                      checkmarkColor: Colors.teal.shade900,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide.none),
                      onSelected: (bool selected) {
                        setState(() {
                          _filterType = 'found';
                          _applyFiltersAndSearch();
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : _displayedItems.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.water_drop_outlined, size: 80, color: Colors.white.withOpacity(0.5)),
                                const SizedBox(height: 16),
                                Text(
                                  'The ocean is empty',
                                  style: TextStyle(fontSize: 18, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            color: Colors.cyan,
                            onRefresh: fetchItems,
                            child: ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.only(bottom: 80), 
                              itemCount: _displayedItems.length,
                              itemBuilder: (context, index) {
                                final item = _displayedItems[index];
                                final isLost = item['type'] == 'lost';
                                final isClaimed = item['status'] == 'claimed';

                                return TweenAnimationBuilder<double>(
                                  tween: Tween<double>(begin: 0.0, end: 1.0),
                                  duration: Duration(milliseconds: 500 + (index.clamp(0, 10) * 100)),
                                  curve: Curves.easeOutQuart,
                                  builder: (context, value, child) {
                                    return Transform.translate(
                                      offset: Offset(0, 40 * (1 - value)),
                                      child: Opacity(
                                        opacity: value,
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.easeOut,
                                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      // The Glassmorphism Card Background
                                      color: isClaimed ? Colors.white.withOpacity(0.6) : Colors.white.withOpacity(0.92),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.white.withOpacity(0.4), width: 1), // Glass rim
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.15),
                                          blurRadius: 15,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: IntrinsicHeight(
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            AnimatedContainer(
                                              duration: const Duration(milliseconds: 400),
                                              width: 12,
                                              color: isClaimed 
                                                  ? Colors.grey.shade400 
                                                  : (isLost ? Colors.redAccent : Colors.tealAccent.shade400),
                                            ),
                                            Expanded(
                                              child: Material(
                                                type: MaterialType.transparency,
                                                child: ListTile(
                                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                                  onTap: () => _showItemDetails(item),
                                                  leading: AnimatedContainer(
                                                    duration: const Duration(milliseconds: 400),
                                                    width: 55,
                                                    height: 55,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: isClaimed 
                                                          ? Colors.grey.shade300 
                                                          : (isLost ? Colors.red.shade50 : Colors.teal.shade50),
                                                    ),
                                                    child: Icon(
                                                      isLost ? Icons.search_rounded : Icons.check_circle_rounded,
                                                      color: isClaimed 
                                                          ? Colors.grey.shade500 
                                                          : (isLost ? Colors.red.shade400 : Colors.teal.shade500),
                                                      size: 28,
                                                    ),
                                                  ),
                                                  title: AnimatedDefaultTextStyle(
                                                    duration: const Duration(milliseconds: 400),
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 18,
                                                      letterSpacing: -0.5,
                                                      fontFamily: 'Roboto',
                                                      decoration: isClaimed ? TextDecoration.lineThrough : TextDecoration.none,
                                                      color: isClaimed ? Colors.grey.shade600 : const Color(0xFF0F2027),
                                                    ),
                                                    child: Text(item['title'] ?? 'Missing Title'),
                                                  ),
                                                  subtitle: Padding(
                                                    padding: const EdgeInsets.only(top: 6.0),
                                                    child: Row(
                                                    children: [
                                                      Icon(Icons.location_on_rounded, size: 16, color: Colors.cyan.shade700),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        item['location'] ?? 'Unknown',
                                                        style: TextStyle(color: Colors.blueGrey.shade700, fontWeight: FontWeight.w600),
                                                      ),
                                                    ],
                                                    ),
                                                  ),
                                                  trailing: AnimatedContainer(
                                                    duration: const Duration(milliseconds: 400),
                                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                                    decoration: BoxDecoration(
                                                      color: isClaimed 
                                                          ? Colors.grey.shade300 
                                                          : (isLost ? Colors.red.shade50 : Colors.teal.shade50),
                                                      borderRadius: BorderRadius.circular(20),
                                                    ),
                                                    child: Text(
                                                      isClaimed ? 'CLAIMED' : (isLost ? 'LOST' : 'FOUND'),
                                                      style: TextStyle(
                                                        color: isClaimed 
                                                            ? Colors.grey.shade600 
                                                            : (isLost ? Colors.red.shade700 : Colors.teal.shade700),
                                                        fontWeight: FontWeight.w900,
                                                        fontSize: 11,
                                                        letterSpacing: 1.0,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 800),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: child,
          );
        },
        child: FloatingActionButton.extended(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreateReportScreen()),
            );
            fetchItems();
          },
          icon: const Icon(Icons.add_rounded, size: 24, color: Colors.cyan),
          label: const Text('Report Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.cyan)),
          backgroundColor: Colors.white, // White button pops against the dark sea
          elevation: 10,
        ),
      ),
    );
  }
}