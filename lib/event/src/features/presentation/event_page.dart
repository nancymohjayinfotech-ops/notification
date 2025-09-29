import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'event_detail_page.dart';

class EventPage extends StatefulWidget {
  final List<Map<String, dynamic>>? events;
  final String? eventType;

  const EventPage({super.key, this.events, this.eventType});

  @override
  State<EventPage> createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredEvents = [];
  List<Map<String, dynamic>> _allEvents = [];

  // Filter state
  DateTime? _selectedStartDate;
  RangeValues _priceRange = const RangeValues(0, 10000);
  double _maxPrice = 10000;

  @override
  void initState() {
    super.initState();
    _allEvents = _fixEventImages(widget.events ?? []);
    _filteredEvents = _allEvents;
    _calculateMaxPrice();
    _searchController.addListener(_onSearchChanged);
  }

  // Add this method to fix image URLs
  List<Map<String, dynamic>> _fixEventImages(
    List<Map<String, dynamic>> events,
  ) {
    const String baseUrl = 'http://54.82.53.11:5001';

    return events.map((event) {
      // Fix single image
      final dynamic image = event['image'];
      String? fixedImage;

      if (image is String && image.isNotEmpty) {
        if (image.startsWith('http')) {
          fixedImage = image;
        } else if (image.startsWith('/')) {
          fixedImage = baseUrl + image;
        } else {
          fixedImage = baseUrl + '/' + image;
        }
      }

      // Fix images array
      final dynamic images = event['images'];
      List<String> fixedImages = [];

      if (images is List<dynamic>) {
        fixedImages = images.map((img) {
          if (img is String && img.isNotEmpty) {
            if (img.startsWith('http')) {
              return img;
            } else if (img.startsWith('/')) {
              return baseUrl + img;
            } else {
              return baseUrl + '/' + img;
            }
          }
          return 'https://images.unsplash.com/photo-1540039155733-5bb30b53aa14?w=400';
        }).toList();
      }

      // Return event with fixed images
      return {
        ...event,
        'image':
            fixedImage ??
            'https://images.unsplash.com/photo-1540039155733-5bb30b53aa14?w=600',
        'images': fixedImages.isNotEmpty
            ? fixedImages
            : ['https://images.unsplash.com/photo-1540039155733-5bb30b53aa14?w=400'],
      };
    }).toList();
  }

  void _calculateMaxPrice() {
    if (_allEvents.isEmpty) return;
    double max = 0;
    for (var event in _allEvents) {
      double price = (event['price'] ?? 0).toDouble();
      if (price > max) max = price;
    }
    _maxPrice = max > 0 ? max : 10000;
    _priceRange = RangeValues(0, _maxPrice);
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  void _applyFilters() {
    setState(() {
      _filteredEvents = _allEvents.where((event) {
        // Search filter
        final searchQuery = _searchController.text.toLowerCase();
        final title = (event['title'] ?? '').toString().toLowerCase();
        final location = (event['location'] ?? '').toString().toLowerCase();
        final eventType =
            (event['eventType'] ??
                    event['event_type'] ??
                    event['category'] ??
                    '')
                .toString()
                .toLowerCase();

        bool matchesSearch =
            searchQuery.isEmpty ||
            title.contains(searchQuery) ||
            location.contains(searchQuery) ||
            eventType.contains(searchQuery);

        if (!matchesSearch) return false;

        // Price filter
        double eventPrice = (event['price'] ?? 0).toDouble();
        bool matchesPrice =
            eventPrice >= _priceRange.start && eventPrice <= _priceRange.end;

        if (!matchesPrice) return false;

        // Date filter (start date only)
        if (_selectedStartDate != null) {
          DateTime? eventDate;
          if (event['startDate'] != null && event['startDate'] is DateTime) {
            eventDate = event['startDate'];
          } else if (event['date'] != null && event['date'] is DateTime) {
            eventDate = event['date'];
          }

          if (eventDate != null) {
            // Check if event date is on or after the selected start date
            bool matchesDate = eventDate.isAfter(
              _selectedStartDate!.subtract(const Duration(days: 1)),
            );
            if (!matchesDate) return false;
          }
        }

        return true;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : const Color(0xFFF8FAFF),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 220.0,
              floating: false,
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [Colors.grey[900]!, Colors.grey[800]!]
                          : [
                              Theme.of(context).primaryColor,
                              Theme.of(context).primaryColor.withOpacity(0.8),
                            ],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: Icon(
                                  Icons.arrow_back,
                                  color: isDark ? Colors.white : Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '${widget.eventType ?? 'All'} Events',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize:
                                        MediaQuery.of(context).size.width < 360
                                        ? 18
                                        : 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Padding(
                            padding: const EdgeInsets.only(left: 54),
                            child: Text(
                              'Browse all ${widget.eventType?.toLowerCase() ?? 'available'} events',
                              style: GoogleFonts.poppins(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildSearchBar(isDark),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ];
        },
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                '${widget.eventType ?? 'All'} Events (${widget.events?.length ?? 0})',
                isDark,
              ),
              const SizedBox(height: 15),
              ..._buildEventList(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.black : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.8,
      height: 50,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => _applyFilters(),
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: isDark ? Colors.black : Colors.white,
        ),
        decoration: InputDecoration(
          hintText: 'Search events, categories, or locations...',
          hintStyle: GoogleFonts.poppins(
            color: isDark ? Colors.grey[400] : Colors.grey[400],
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: isDark ? Colors.grey[400] : Colors.grey,
            size: 22,
          ),
          suffixIcon: Container(
            margin: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.filter_list,
                color: Colors.white,
                size: 20,
              ),
              onPressed: _showFilterModal,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildEventList(bool isDark) {
    if (_filteredEvents.isEmpty) {
      return [
        Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 50),
            child: Column(
              children: [
                Icon(
                  Icons.event_busy_outlined,
                  size: 60,
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                ),
                const SizedBox(height: 15),
                Text(
                  'No events found',
                  style: GoogleFonts.poppins(
                    color: isDark ? Colors.grey[400] : Colors.grey[500],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    return _filteredEvents.map((event) {
      // Format date properly
      String formatDate(DateTime? date) {
        if (date == null) return 'Date TBD';
        return '${date.day}/${date.month}/${date.year}';
      }

      // Format time properly
      String formatTime(String? time) {
        if (time == null || time.isEmpty) return 'TBD';
        try {
          final parts = time.split(':');
          if (parts.length >= 2) {
            final hour = int.parse(parts[0]);
            final minute = int.parse(parts[1]);
            final period = hour >= 12 ? 'PM' : 'AM';
            final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
            return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
          }
        } catch (e) {
          return time;
        }
        return time;
      }

      // Get formatted date from startDate or fallback
      String getFormattedDate() {
        if (event['startDate'] != null) {
          return formatDate(event['startDate']);
        }
        if (event['date'] != null && event['date'] is DateTime) {
          return formatDate(event['date']);
        }
        if (event['date'] != null &&
            event['date'] is String &&
            event['date'] != 'Date TBD') {
          return event['date'];
        }
        return 'Date TBD';
      }

      return _buildEventCard(
        title: event['title'] ?? 'Event Title',
        date: getFormattedDate(),
        startTime: formatTime(event['startTime'] ?? event['start_time']),
        endTime: formatTime(event['endTime'] ?? event['end_time']),
        location: event['location'] ?? 'Location TBD',
        eventType:
            event['eventType'] ??
            event['event_type'] ??
            event['category'] ??
            'General',
        slug: event['slug'] ?? event['id']?.toString() ?? '',
        imageUrl:
            event['image'] ??
            'https://images.unsplash.com/photo-1540039155733-5bb30b53aa14?w=600',
        price: (event['price'] ?? 0).toDouble(),
        isDark: isDark,
      );
    }).toList();
  }

  Widget _buildEventCard({
    required String title,
    required String date,
    required String startTime,
    required String endTime,
    required String location,
    required String eventType,
    required String slug,
    required String imageUrl,
    required double price,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () {
        if (slug.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailPage(slug: slug),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with gradient overlay
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  child: Image.network(
                    imageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 200,
                        color: isDark ? Colors.grey[700] : Colors.grey[100],
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isDark ? Colors.white70 : Colors.blue,
                            ),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 180,
                      color: isDark ? Colors.grey[700] : Colors.grey[200],
                      child: Icon(
                        Icons.error_outline,
                        color: isDark ? Colors.grey[400] : Colors.grey,
                      ),
                    ),
                  ),
                ),
                // Gradient overlay
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.6),
                      ],
                    ),
                  ),
                ),
                // Event date badge
                Positioned(
                  top: 15,
                  left: 15,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[900] : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      date.split(',')[0],
                      style: GoogleFonts.poppins(
                        color: Theme.of(context).primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                // Event type badge
                Positioned(
                  top: 55,
                  left: 15,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      eventType,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                // Price or Free badge
                Positioned(
                  top: 15,
                  right: 15,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: price > 0
                          ? (isDark ? Colors.grey[900] : Colors.white)
                          : const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.2 : 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Text(
                      price > 0 ? '₹${price.toInt()}' : 'FREE',
                      style: GoogleFonts.poppins(
                        color: price > 0
                            ? Theme.of(context).primaryColor
                            : Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                // Event title overlay
                Positioned(
                  left: 15,
                  right: 15,
                  bottom: 15,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '$startTime - $endTime',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              location,
                              style: GoogleFonts.poppins(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFilterModal(),
    );
  }

  Widget _buildFilterModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter Events',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setModalState(() {
                          _selectedStartDate = null;
                          _priceRange = RangeValues(0, _maxPrice);
                        });
                        setState(() {
                          _selectedStartDate = null;
                          _priceRange = RangeValues(0, _maxPrice);
                        });
                        _applyFilters();
                      },
                      child: Text(
                        'Clear All',
                        style: GoogleFonts.poppins(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: isDark ? Colors.grey[700] : Colors.grey[300]),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Start Date Filter
                      Text(
                        'Start Date',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isDark
                                ? Colors.grey[700]!
                                : Colors.grey[300]!,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: isDark ? Colors.grey[800] : null,
                        ),
                        child: InkWell(
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedStartDate ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: Theme.of(context).colorScheme
                                        .copyWith(
                                          primary: Theme.of(
                                            context,
                                          ).primaryColor,
                                        ),
                                    dialogBackgroundColor: isDark
                                        ? Colors.grey[900]
                                        : Colors.white,
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setModalState(() {
                                _selectedStartDate = picked;
                              });
                              setState(() {
                                _selectedStartDate = picked;
                              });
                              _applyFilters();
                            }
                          },
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: Theme.of(context).primaryColor,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _selectedStartDate == null
                                      ? 'Select start date'
                                      : '${_selectedStartDate!.day}/${_selectedStartDate!.month}/${_selectedStartDate!.year}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: _selectedStartDate == null
                                        ? (isDark ? Colors.grey[400] : Colors.grey[600])
                                        : (isDark ? Colors.white : Colors.black87),
                                  ),
                                ),
                              ),
                              if (_selectedStartDate != null)
                                IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    size: 18,
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                  onPressed: () {
                                    setModalState(() {
                                      _selectedStartDate = null;
                                    });
                                    setState(() {
                                      _selectedStartDate = null;
                                    });
                                    _applyFilters();
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      // Price Range Filter
                      Text(
                        'Price Range',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isDark
                                ? Colors.grey[700]!
                                : Colors.grey[300]!,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: isDark ? Colors.grey[800] : null,
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '₹${_priceRange.start.round()}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                                Text(
                                  '₹${_priceRange.end.round()}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            RangeSlider(
                              values: _priceRange,
                              min: 0,
                              max: _maxPrice,
                              divisions: 100,
                              activeColor: Theme.of(context).primaryColor,
                              inactiveColor: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.3),
                              onChanged: (RangeValues values) {
                                setModalState(() {
                                  _priceRange = values;
                                });
                                setState(() {
                                  _priceRange = values;
                                });
                                _applyFilters();
                              },
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Free',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  '₹${_maxPrice.round()}+',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 25),
                      // Results count
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).primaryColor.withOpacity(isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.event_available,
                              color: Theme.of(context).primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${_filteredEvents.length} events found',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Apply button
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Apply Filters',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }
}