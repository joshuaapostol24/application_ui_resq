import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart'; // Add this dependency
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String selectedCategory = 'Flood';
  String selectedSeverity = 'High';
  File? selectedImage;
  final ImagePicker _picker = ImagePicker();

  final List<Map<String, dynamic>> categories = [
    {'label': 'Flood', 'icon': Icons.flood_outlined},
    {'label': 'Fire', 'icon': Icons.local_fire_department_outlined},
    {'label': 'Earthquake', 'icon': Icons.crisis_alert_outlined},
    {'label': 'Landslide', 'icon': Icons.landscape_outlined},
    {'label': 'Power', 'icon': Icons.bolt_outlined},
    {'label': 'Others', 'icon': Icons.more_horiz},
  ];

  // Current map position
  LatLng currentLocation = const LatLng(13.2236, 120.5960);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F0EB),
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
        title: const Text(
          'Report',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Location ──
            const _SectionHeader(
              icon: Icons.location_on_outlined,
              title: 'Location',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on, size: 16, color: Color(0xFFF5A623)),
                  SizedBox(width: 4),
                  Text(
                    'Tap map to set location',
                    style: TextStyle(
                      color: Color(0xFFF5A623),
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _InteractiveMapWidget(
              currentLocation: currentLocation,
              onLocationChanged: (latlng) {
                setState(() {
                  currentLocation = latlng;
                });
              },
            ),
            const SizedBox(height: 10),
            _AddressField(currentLocation: currentLocation),
            const SizedBox(height: 24),

            // ── Category ──
            const _SectionHeader(
              icon: Icons.category_outlined,
              title: 'Category',
            ),
            const SizedBox(height: 12),
            _CategoryGrid(
              categories: categories,
              selected: selectedCategory,
              onSelect: (val) => setState(() => selectedCategory = val),
            ),
            const SizedBox(height: 24),

            // ── Severity ──
            const _SectionHeader(
              icon: Icons.warning_amber_outlined,
              title: 'Severity',
            ),
            const SizedBox(height: 12),
            _SeveritySelector(
              levels: const ['Low', 'Medium', 'High', 'Critical'],
              selected: selectedSeverity,
              onSelect: (val) => setState(() => selectedSeverity = val),
            ),
            const SizedBox(height: 24),

            // ── Evidence ──
            _SectionHeader(
              icon: Icons.camera_alt_outlined,
              title: 'Evidence',
              trailing: Text(
                selectedImage != null ? '1 Photo' : 'No photo',
                style: TextStyle(
                  color: selectedImage != null ? Colors.green : Colors.black54,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _EvidenceUpload(
              selectedImage: selectedImage,
              onImageSelected: (image) {
                setState(() {
                  selectedImage = image;
                });
              },
              onRemoveImage: () {
                setState(() {
                  selectedImage = null;
                });
              },
            ),
            const SizedBox(height: 32),

            // ── Submit ──
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF5A623),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  _submitReport();
                },
                child: const Text(
                  'Submit Report',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _submitReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '✅ Report submitted!\n'
          'Category: $selectedCategory\n'
          'Severity: $selectedSeverity\n'
          'Location: ${currentLocation.latitude.toStringAsFixed(4)}, ${currentLocation.longitude.toStringAsFixed(4)}'
          '${selectedImage != null ? '\nPhoto: Attached' : ''}',
        ),
        backgroundColor: const Color(0xFF4CAF50),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

// ── INTERACTIVE MAP WIDGET ──
class _InteractiveMapWidget extends StatelessWidget {
  final LatLng currentLocation;
  final ValueChanged<LatLng> onLocationChanged;

  const _InteractiveMapWidget({
    required this.currentLocation,
    required this.onLocationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE8E0D8)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: currentLocation,
            initialZoom: 16.0,
            onTap: (tapPosition, point) {
              onLocationChanged(point);
            },
          ),
          children: [
            TileLayer(
              urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
              subdomains: const ['a', 'b', 'c'],
              userAgentPackageName: 'com.joshua.resqapp',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: currentLocation,
                  width: 50,
                  height: 50,
                  child: const Icon(
                    Icons.location_pin,
                    color: Color(0xFFF5A623),
                    size: 40,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── ADDRESS FIELD ──
class _AddressField extends StatelessWidget {
  final LatLng currentLocation;

  const _AddressField({required this.currentLocation});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E0D8)),
      ),
      child: Row(
        children: [
          const Icon(Icons.my_location, size: 18, color: Color(0xFFF5A623)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${currentLocation.latitude.toStringAsFixed(4)}, ${currentLocation.longitude.toStringAsFixed(4)}',
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const Text(
                  'Tap map to change location',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── SECTION HEADER ──
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;

  const _SectionHeader({
    required this.icon,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFFF5A623)),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ── CATEGORY GRID ──
class _CategoryGrid extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final String selected;
  final ValueChanged<String> onSelect;

  const _CategoryGrid({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.1,
      ),
      itemBuilder: (context, index) {
        final cat = categories[index];
        final isSelected = cat['label'] == selected;
        return GestureDetector(
          onTap: () => onSelect(cat['label']),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFFF3E0) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFF5A623)
                    : const Color(0xFFE8E0D8),
                width: isSelected ? 1.8 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  cat['icon'] as IconData,
                  size: 28,
                  color: isSelected ? const Color(0xFFF5A623) : Colors.black87,
                ),
                const SizedBox(height: 6),
                Text(
                  cat['label'],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color:
                        isSelected ? const Color(0xFFF5A623) : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── SEVERITY SELECTOR ──
class _SeveritySelector extends StatelessWidget {
  final List<String> levels;
  final String selected;
  final ValueChanged<String> onSelect;

  const _SeveritySelector({
    required this.levels,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8E0D8)),
      ),
      child: Row(
        children: levels.map((level) {
          final isSelected = level == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(level),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color:
                      isSelected ? const Color(0xFFF5A623) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    level,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w400,
                      color: isSelected ? Colors.white : Colors.black54,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── EVIDENCE UPLOAD WITH PHOTO PICKER ──
class _EvidenceUpload extends StatelessWidget {
  final File? selectedImage;
  final ValueChanged<File?> onImageSelected;
  final VoidCallback onRemoveImage;

  const _EvidenceUpload({
    this.selectedImage,
    required this.onImageSelected,
    required this.onRemoveImage,
  });

  Future<void> _pickImage() async {
    // Request permission first
    var status = await Permission.photos.request();

    if (status.isGranted) {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        onImageSelected(File(image.path));
      }
    } else {
      print("Permission denied");
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                selectedImage != null ? Colors.green : const Color(0xFFE8E0D8),
            width: selectedImage != null ? 2 : 1,
          ),
        ),
        child: selectedImage != null
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(
                      selectedImage!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: onRemoveImage,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 32,
                    color: Color(0xFFF5A623),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap to upload photo',
                    style: TextStyle(fontSize: 13, color: Colors.black45),
                  ),
                  Text(
                    'JPG, PNG up to 10MB',
                    style: TextStyle(fontSize: 11, color: Colors.black38),
                  ),
                ],
              ),
      ),
    );
  }
}
