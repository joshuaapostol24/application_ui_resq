import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/report_model.dart';
import '../services/mongo_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  List<ReportModel> _reports = [];
  bool _isLoading = true;
  String? _errorMessage;
  ReportModel? _selectedReport; // tapped marker

  // Category filter — null means "show all"
  String? _filterCategory;
  static const _categories = [
    'All', 'Flood', 'Fire', 'Earthquake', 'Landslide', 'Power', 'Others'
  ];

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  // ── Fetch ─────────────────────────────────────────────────────────────────
  Future<void> _fetchReports() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final reports = await MongoService.getReports();
      if (mounted) {
        setState(() {
          _reports = reports;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load reports: $e';
          _isLoading = false;
        });
      }
    }
  }

  // ── Filtered list ─────────────────────────────────────────────────────────
  List<ReportModel> get _filtered {
    if (_filterCategory == null || _filterCategory == 'All') return _reports;
    return _reports
        .where((r) =>
            r.category.toLowerCase() == _filterCategory!.toLowerCase())
        .toList();
  }

  // ── Open detail bottom sheet ──────────────────────────────────────────────
  void _showDetail(ReportModel report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReportDetailSheet(report: report),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Map ────────────────────────────────────────────────────────────
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: const MapOptions(
                initialCenter: LatLng(13.2180, 120.5960),
                initialZoom: 13,
                minZoom: 5,
                maxZoom: 18,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.joshua.resqapp',
                ),
                // ── Report markers ──
                MarkerLayer(
                  markers: filtered.map((report) {
                    return Marker(
                      point: report.latLng,
                      width: 44,
                      height: 44,
                      child: GestureDetector(
                        onTap: () => _showDetail(report),
                        child: _ReportMarker(report: report),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // ── Top bar ────────────────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Column(
              children: [
                // Live badge row
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'LIVE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.red,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Mamburao, Occ. Mindoro',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Report count badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5A623).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _isLoading
                              ? '…'
                              : '${filtered.length} Active',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFF5A623),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Refresh button
                      GestureDetector(
                        onTap: _fetchReports,
                        child: const Icon(Icons.refresh,
                            color: Colors.black45, size: 18),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Category filter chips
                SizedBox(
                  height: 34,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (context, i) {
                      final cat = _categories[i];
                      final isActive = cat == 'All'
                          ? (_filterCategory == null ||
                              _filterCategory == 'All')
                          : _filterCategory == cat;
                      return GestureDetector(
                        onTap: () => setState(() =>
                            _filterCategory = cat == 'All' ? null : cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color(0xFFF5A623)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isActive
                                  ? Colors.white
                                  : Colors.black54,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // ── Zoom + locate controls ─────────────────────────────────────────
          Positioned(
            right: 16,
            top: MediaQuery.of(context).padding.top + 115,
            child: Column(
              children: [
                _MapButton(
                  icon: Icons.add,
                  onTap: () => _mapController.move(
                    _mapController.camera.center,
                    _mapController.camera.zoom + 1,
                  ),
                ),
                const SizedBox(height: 8),
                _MapButton(
                  icon: Icons.remove,
                  onTap: () => _mapController.move(
                    _mapController.camera.center,
                    _mapController.camera.zoom - 1,
                  ),
                ),
                const SizedBox(height: 8),
                _MapButton(
                  icon: Icons.my_location,
                  color: const Color(0xFFF5A623),
                  onTap: () => _mapController.move(
                    const LatLng(13.2180, 120.5960),
                    13,
                  ),
                ),
              ],
            ),
          ),

          // ── Draggable bottom sheet ─────────────────────────────────────────
          DraggableScrollableSheet(
            initialChildSize: 0.28,
            minChildSize: 0.07,
            maxChildSize: 0.75,
            snap: true,
            snapSizes: const [0.07, 0.28, 0.75],
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 20,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 16),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // Header
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          const Text(
                            'Recent Reports',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          const Spacer(),
                          if (_isLoading)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFF5A623),
                              ),
                            )
                          else
                            GestureDetector(
                              onTap: _fetchReports,
                              child: const Icon(Icons.refresh,
                                  size: 20, color: Color(0xFFF5A623)),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _isLoading
                              ? 'Loading reports...'
                              : _errorMessage != null
                                  ? _errorMessage!
                                  : '${filtered.length} report${filtered.length == 1 ? '' : 's'} found',
                          style: TextStyle(
                            fontSize: 13,
                            color: _errorMessage != null
                                ? Colors.red
                                : Colors.black45,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // List
                    Expanded(
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFFF5A623),
                              ),
                            )
                          : _errorMessage != null
                              ? _ErrorState(
                                  message: _errorMessage!,
                                  onRetry: _fetchReports,
                                )
                              : filtered.isEmpty
                                  ? const _EmptyState()
                                  : ListView.separated(
                                      controller: scrollController,
                                      padding: const EdgeInsets.fromLTRB(
                                          20, 0, 20, 24),
                                      itemCount: filtered.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(height: 10),
                                      itemBuilder: (context, i) =>
                                          _ReportCard(
                                        report: filtered[i],
                                        onTap: () {
                                          _showDetail(filtered[i]);
                                          // Fly map to the tapped report
                                          _mapController.move(
                                            filtered[i].latLng,
                                            15,
                                          );
                                        },
                                      ),
                                    ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Report Marker ─────────────────────────────────────────────────────────────

class _ReportMarker extends StatelessWidget {
  final ReportModel report;
  const _ReportMarker({required this.report});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: report.categoryColor.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(color: report.categoryColor, width: 2),
      ),
      child: Icon(report.categoryIcon, color: report.categoryColor, size: 20),
    );
  }
}

// ── Report Card (in bottom sheet list) ───────────────────────────────────────

class _ReportCard extends StatelessWidget {
  final ReportModel report;
  final VoidCallback onTap;
  const _ReportCard({required this.report, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF0EBE3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Color bar
            Container(
              width: 3,
              height: 48,
              decoration: BoxDecoration(
                color: report.categoryColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            // Category icon
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: report.categoryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(report.categoryIcon,
                  color: report.categoryColor, size: 18),
            ),
            const SizedBox(width: 10),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        report.category,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _SeverityBadge(report: report),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    report.address.isNotEmpty
                        ? report.address
                        : '${report.latitude.toStringAsFixed(4)}, '
                            '${report.longitude.toStringAsFixed(4)}',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.black45),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (report.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      report.description,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black38),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Time
            Text(
              report.timeAgo,
              style:
                  const TextStyle(fontSize: 11, color: Colors.black38),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Report Detail Bottom Sheet ────────────────────────────────────────────────

class _ReportDetailSheet extends StatelessWidget {
  final ReportModel report;
  const _ReportDetailSheet({required this.report});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header row
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: report.categoryColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(report.categoryIcon,
                        color: report.categoryColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.category,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          report.timeAgo,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black38),
                        ),
                      ],
                    ),
                  ),
                  _SeverityBadge(report: report, large: true),
                ],
              ),
              const SizedBox(height: 20),

              // Image
              if (report.imageUrl != null && report.imageUrl!.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    report.imageUrl!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F0EB),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Icon(Icons.broken_image_outlined,
                            color: Colors.black26, size: 40),
                      ),
                    ),
                    loadingBuilder: (_, child, progress) => progress == null
                        ? child
                        : Container(
                            height: 180,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F0EB),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                  color: Color(0xFFF5A623)),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Description
              if (report.description.isNotEmpty) ...[
                _DetailRow(
                  icon: Icons.description_outlined,
                  label: 'Description',
                  value: report.description,
                ),
                const SizedBox(height: 12),
              ],

              // Location
              _DetailRow(
                icon: Icons.location_on_outlined,
                label: 'Location',
                value: report.address.isNotEmpty
                    ? report.address
                    : '${report.latitude.toStringAsFixed(5)}, '
                        '${report.longitude.toStringAsFixed(5)}',
              ),
              const SizedBox(height: 12),

              // Status
              _DetailRow(
                icon: Icons.info_outline,
                label: 'Status',
                value: report.status.toUpperCase(),
                valueColor: report.status.toLowerCase() == 'resolved'
                    ? Colors.green
                    : report.status.toLowerCase() == 'pending'
                        ? const Color(0xFFF5A623)
                        : Colors.black87,
              ),
              const SizedBox(height: 12),

              // Timestamp
              _DetailRow(
                icon: Icons.access_time_outlined,
                label: 'Reported',
                value:
                    '${report.createdAt.day}/${report.createdAt.month}/${report.createdAt.year} '
                    '${report.createdAt.hour.toString().padLeft(2, '0')}:'
                    '${report.createdAt.minute.toString().padLeft(2, '0')}',
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Detail Row ────────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F6F2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFFF5A623)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.black38,
                      letterSpacing: 0.5),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: valueColor ?? Colors.black87,
                    fontWeight: valueColor != null
                        ? FontWeight.w600
                        : FontWeight.w400,
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

// ── Severity Badge ────────────────────────────────────────────────────────────

class _SeverityBadge extends StatelessWidget {
  final ReportModel report;
  final bool large;
  const _SeverityBadge({required this.report, this.large = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: large ? 10 : 7, vertical: large ? 4 : 2),
      decoration: BoxDecoration(
        color: report.severityColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        report.severity,
        style: TextStyle(
          fontSize: large ? 12 : 10,
          fontWeight: FontWeight.w700,
          color: report.severityColor,
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F6F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8E0D8)),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_outlined,
              size: 36, color: Colors.black26),
          SizedBox(height: 10),
          Text(
            'No reports found',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black45,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Reports will appear here once submitted.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.black38),
          ),
        ],
      ),
    );
  }
}

// ── Error State ───────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_outlined,
              size: 36, color: Colors.black26),
          const SizedBox(height: 10),
          const Text(
            'Could not load reports',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style:
                const TextStyle(fontSize: 12, color: Colors.black38),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF5A623),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, color: Colors.white, size: 16),
            label: const Text('Retry',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Map Button ────────────────────────────────────────────────────────────────

class _MapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _MapButton({required this.icon, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: color ?? Colors.black87),
      ),
    );
  }
}