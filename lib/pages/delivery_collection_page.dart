import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
// Note: Ensure these imports point to your actual file structure
import '../models/delivery_man_model.dart';
import '../models/delivery_task_model.dart';
import 'mark_delivered_page.dart';
import 'mark_collection_page.dart';

class DeliveryCollectionPage extends StatefulWidget {
  const DeliveryCollectionPage({super.key});

  @override
  State<DeliveryCollectionPage> createState() => _DeliveryCollectionPageState();
}

class _DeliveryCollectionPageState extends State<DeliveryCollectionPage> {
  // ... (Existing State Variables remain unchanged)
  DeliveryMan? _deliveryMan;
  List<DeliveryTask> _allTasks = [];
  List<DeliveryTask> _filteredTasks = [];
  bool _isLoading = true;

  TaskType? _taskTypeFilter;
  TaskStatus? _statusFilter;
  bool _sortByLocation = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));

    // Mock Data
    _deliveryMan = DeliveryMan(
      id: 'DM001',
      name: 'Rohit Sharma',
      phone: '+91 98765 00001',
      currentLatitude: 19.0760,
      currentLongitude: 72.8777,
      currentLocation: 'Andheri East, Mumbai',
    );

    _allTasks = _generateMockTasks();
    _filteredTasks = _allTasks;
    _sortTasks();

    setState(() => _isLoading = false);
  }

  // ... (Keep existing helper methods unchanged)
  List<DeliveryTask> _generateMockTasks() {
    return [
      DeliveryTask(
        id: 'T001',
        type: TaskType.delivery,
        status: TaskStatus.pending,
        partyName: 'ABC Medical Store',
        partyId: 'P001',
        station: 'Mumbai Central',
        area: 'Dadar West',
        latitude: 19.0176,
        longitude: 72.8561,
        billNo: 'S002010001',
        billDate: DateTime.now().subtract(const Duration(days: 1)),
        paymentType: PaymentType.credit,
        billAmount: 40040.0,
        itemCount: 30,
        distanceKm: 7.2,
      ),
      DeliveryTask(
        id: 'T002',
        type: TaskType.delivery,
        status: TaskStatus.pending,
        partyName: 'City Pharmacy',
        partyId: 'P002',
        station: 'Bandra',
        area: 'Bandra West',
        latitude: 19.0596,
        longitude: 72.8295,
        billNo: 'S002010002',
        billDate: DateTime.now().subtract(const Duration(days: 1)),
        paymentType: PaymentType.cash,
        billAmount: 25000.0,
        itemCount: 20,
        distanceKm: 8.5,
      ),
      DeliveryTask(
        id: 'T003',
        type: TaskType.collection,
        status: TaskStatus.pending,
        partyName: 'Health Plus',
        partyId: 'P003',
        station: 'Juhu',
        area: 'Juhu',
        latitude: 19.1075,
        longitude: 72.8263,
        distanceKm: 10.3,
      ),
      DeliveryTask(
        id: 'T006',
        type: TaskType.delivery,
        status: TaskStatus.done,
        partyName: 'Quick Medics',
        partyId: 'P006',
        station: 'Malad',
        area: 'Malad West',
        billNo: 'S002010004',
        billDate: DateTime.now(),
        paymentType: PaymentType.cash,
        billAmount: 18000.0,
        itemCount: 15,
        distanceKm: 5.2,
      ),
    ];
  }

  void _applyFilters() {
    setState(() {
      _filteredTasks = _allTasks.where((task) {
        if (_taskTypeFilter != null && task.type != _taskTypeFilter) return false;
        if (_statusFilter != null && task.status != _statusFilter) return false;
        return true;
      }).toList();
      _sortTasks();
    });
  }

  void _sortTasks() {
    if (_sortByLocation) {
      _filteredTasks.sort((a, b) {
        final distA = a.distanceKm ?? double.maxFinite;
        final distB = b.distanceKm ?? double.maxFinite;
        return distA.compareTo(distB);
      });
    } else {
      _filteredTasks.sort((a, b) {
        final areaCompare = a.area.compareTo(b.area);
        if (areaCompare != 0) return areaCompare;
        return a.partyName.compareTo(b.partyName);
      });
    }
  }

  Future<void> _openMapsNavigation(DeliveryTask task) async {
    if (!task.hasLocation) return;
    final lat = task.latitude!;
    final lng = task.longitude!;
    final googleMapsUrl = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    }
  }

  // --- DESIGN IMPLEMENTATION (With Theme Colors) ---

  @override
  Widget build(BuildContext context) {
    // Access the current Theme colors
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final pendingCount = _allTasks.where((t) => t.status == TaskStatus.pending).length;
    final totalValue = _allTasks.fold(0.0, (sum, t) => sum + (t.billAmount ?? 0));

    return Scaffold(
      backgroundColor: colorScheme.surface, // Uses theme background
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(pendingCount, totalValue, colorScheme),

          // Filter Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "FILTERS",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: colorScheme.onSurfaceVariant, // Theme color
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildFilterChip('All Types', _taskTypeFilter == null, () {
                          setState(() { _taskTypeFilter = null; _applyFilters(); });
                        }, colorScheme),
                        const SizedBox(width: 8),
                        _buildFilterChip('Delivery', _taskTypeFilter == TaskType.delivery, () {
                          setState(() { _taskTypeFilter = TaskType.delivery; _applyFilters(); });
                        }, colorScheme),
                        const SizedBox(width: 8),
                        _buildFilterChip('Collection', _taskTypeFilter == TaskType.collection, () {
                          setState(() { _taskTypeFilter = TaskType.collection; _applyFilters(); });
                        }, colorScheme),
                        const VerticalDivider(width: 20),
                        _buildFilterChip('Pending', _statusFilter == TaskStatus.pending, () {
                          setState(() { _statusFilter = TaskStatus.pending; _applyFilters(); });
                        }, colorScheme),
                        const SizedBox(width: 8),
                        _buildFilterChip('Completed', _statusFilter == TaskStatus.done, () {
                          setState(() { _statusFilter = TaskStatus.done; _applyFilters(); });
                        }, colorScheme),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Task List
          _filteredTasks.isEmpty
              ? SliverFillRemaining(child: _buildEmptyState(colorScheme))
              : SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildModernTaskCard(_filteredTasks[index], index + 1, colorScheme),
                childCount: _filteredTasks.length,
              ),
            ),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          setState(() {
            _sortByLocation = !_sortByLocation;
            _sortTasks();
          });
        },
        backgroundColor: colorScheme.primary, // Theme primary
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        icon: Icon(_sortByLocation ? Icons.location_on : Icons.sort_by_alpha),
        label: Text(_sortByLocation ? "Sorted by Dist" : "Sorted by Area"),
      ),
    );
  }

  Widget _buildSliverAppBar(int count, double value, ColorScheme colorScheme) {
    return SliverAppBar(
      expandedHeight: 220.0,
      floating: false,
      pinned: true,
      backgroundColor: colorScheme.primary, // Theme Primary
      iconTheme: IconThemeData(color: colorScheme.onPrimary),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary,
                colorScheme.primaryContainer, // Gradient using theme colors
              ],
            ),
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                top: -50, right: -50,
                child: Container(
                  width: 200, height: 200,
                  decoration: BoxDecoration(
                    color: colorScheme.onPrimary.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: colorScheme.secondaryContainer,
                          child: Text(
                            _deliveryMan?.name.substring(0, 1) ?? "U",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSecondaryContainer,
                              fontSize: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Hello,", style: TextStyle(color: colorScheme.onPrimary.withOpacity(0.7), fontSize: 14)),
                            Text(
                              _deliveryMan?.name ?? "Driver",
                              style: TextStyle(color: colorScheme.onPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    // Glassmorphic Stats Container
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: colorScheme.onPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colorScheme.onPrimary.withOpacity(0.1)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatItem("Pending", "$count Tasks", Icons.assignment_late, Colors.orangeAccent, colorScheme),
                          Container(width: 1, height: 30, color: colorScheme.onPrimary.withOpacity(0.2)),
                          _buildStatItem("Total Value", "₹${(value/1000).toStringAsFixed(1)}k", Icons.currency_rupee, Colors.greenAccent, colorScheme),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      title: Text("Dashboard", style: TextStyle(color: colorScheme.onPrimary, fontWeight: FontWeight.w600)),
      centerTitle: true,
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color iconColor, ColorScheme colorScheme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: iconColor.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: colorScheme.onPrimary.withOpacity(0.7), fontSize: 11)),
            Text(value, style: TextStyle(color: colorScheme.onPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        )
      ],
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : colorScheme.surface, // Theme Primary or Surface
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
          ),
          boxShadow: isSelected ? [BoxShadow(color: colorScheme.primary.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))] : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface, // Theme text colors
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildModernTaskCard(DeliveryTask task, int index, ColorScheme colorScheme) {
    final bool isDelivery = task.type == TaskType.delivery;
    final bool isDone = task.status == TaskStatus.done;

    // Status Logic
    Color statusColor;
    String statusText;
    if (task.status == TaskStatus.done) {
      statusColor = Colors.green;
      statusText = "COMPLETED";
    } else if (task.status == TaskStatus.returnTask) {
      statusColor = Colors.red;
      statusText = "RETURN";
    } else {
      statusColor = Colors.amber.shade700;
      statusText = "PENDING";
    }

    // Task Type Color Logic (kept semantic)
    final typeColor = isDelivery ? Colors.blue : Colors.purple;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest, // Card background
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: colorScheme.shadow.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            // 1. Card Header (Type & Status)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.05),
                border: Border(bottom: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.3))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                            color: typeColor.withOpacity(0.1),
                            shape: BoxShape.circle
                        ),
                        child: Icon(
                          isDelivery ? Icons.local_shipping : Icons.inventory_2,
                          size: 16,
                          color: typeColor.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isDelivery ? "DELIVERY #$index" : "COLLECTION #$index",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: typeColor.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                  )
                ],
              ),
            ),

            // 2. Main Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Party Name
                  Text(
                    task.partyName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface, // Theme text
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Location Row
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 16, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${task.area} • ${task.station}',
                          style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant, height: 1.4),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (task.distanceKm != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(4)),
                          child: Text(
                            '${task.distanceKm} km',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.onSurfaceVariant),
                          ),
                        ),
                    ],
                  ),

                  // Bill Details Grid (If Delivery)
                  if (isDelivery) ...[
                    Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: colorScheme.outlineVariant.withOpacity(0.5))),
                    Row(
                      children: [
                        _buildDetailColumn("BILL NO", task.billNo ?? "-", colorScheme),
                        const Spacer(),
                        _buildDetailColumn("AMOUNT", "₹${task.billAmount?.toStringAsFixed(0) ?? "0"}", colorScheme, isHighlight: true),
                        const Spacer(),
                        _buildDetailColumn("ITEMS", "${task.itemCount ?? 0}", colorScheme),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // 3. Actions Footer
            if (!isDone)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: () => _openMapsNavigation(task),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: BorderSide(color: colorScheme.outlineVariant),
                          foregroundColor: colorScheme.onSurface, // Theme Icon Color
                        ),
                        child: const Icon(Icons.near_me, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: ElevatedButton(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => isDelivery
                                  ? MarkDeliveredPage(task: task)
                                  : MarkCollectionPage(task: task),
                            ),
                          );
                          if (result == true) _loadData();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary, // Theme Primary
                          foregroundColor: colorScheme.onPrimary, // Theme OnPrimary
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          isDelivery ? "Mark Delivered" : "Mark Collected",
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
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

  Widget _buildDetailColumn(String label, String value, ColorScheme colorScheme, {bool isHighlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant, letterSpacing: 0.5),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isHighlight ? colorScheme.primary : colorScheme.onSurface, // Theme Highlight
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.filter_none, size: 60, color: colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text("No tasks found", style: TextStyle(fontSize: 16, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}