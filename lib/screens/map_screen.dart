import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// ── MAP SCREEN WITH DRAGGABLE RECENT ALERTS ──────────────────────────────────

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  // -----------------------------------------------------------------------
  // TODO: ALERTS INTEGRATION
  // Replace this empty list with your real data source when ready.
  // Example (Firestore):
  //   Stream<List<Map<String, dynamic>>> get _alertsStream =>
  //       FirebaseFirestore.instance.collection('alerts').snapshots()
  //         .map((s) => s.docs.map((d) => d.data()).toList());
  // Then wrap the body with a StreamBuilder and pass the list down.
  // -----------------------------------------------------------------------
  final List<Map<String, dynamic>> _alerts = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Full-screen interactive map ──
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
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  userAgentPackageName: 'com.joshua.resqapp',
                ),

                // -----------------------------------------------------------
                // TODO: ALERT MARKERS INTEGRATION
                // When alerts are loaded from the backend, map them to
                // Markers here. Example:
                //
                //   MarkerLayer(
                //     markers: _alerts.map((alert) => Marker(
                //       point: alert['point'] as LatLng,
                //       width: 36,
                //       height: 36,
                //       child: Container(
                //         decoration: BoxDecoration(
                //           color: (alert['color'] as Color).withOpacity(0.15),
                //           shape: BoxShape.circle,
                //           border: Border.all(color: alert['color'] as Color, width: 2),
                //         ),
                //         child: Icon(Icons.warning_amber_rounded,
                //             color: alert['color'] as Color, size: 18),
                //       ),
                //     )).toList(),
                //   ),
                // -----------------------------------------------------------
                const MarkerLayer(markers: []),
              ],
            ),
          ),

          // ── LIVE badge (top) ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                  // -----------------------------------------------------------
                  // TODO: ALERT COUNT BADGE
                  // Replace _alerts.length with your live count when integrated.
                  // -----------------------------------------------------------
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5A623).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_alerts.length} Ac',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFF5A623),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.keyboard_arrow_down,
                      color: Colors.black45, size: 18),
                ],
              ),
            ),
          ),

          // ── Zoom controls ──
          Positioned(
            right: 16,
            top: MediaQuery.of(context).padding.top + 80,
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

          // ── Draggable Recent Alerts bottom sheet ──
          DraggableScrollableSheet(
            initialChildSize: 0.32,
            minChildSize: 0.07, // Nearly hidden — just the handle peeking
            maxChildSize: 0.75,
            snap: true,
            snapSizes: const [0.07, 0.32, 0.75],
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
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.zero,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        margin:
                        const EdgeInsets.only(top: 12, bottom: 16),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Header
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recent Alerts',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Based on your current location',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // -----------------------------------------------------------
                    // TODO: ALERT CARDS INTEGRATION
                    // Once connected to Firebase/backend, replace the placeholder
                    // below with the real alert cards. Example:
                    //
                    //   if (_alerts.isEmpty)
                    //     const _AlertsPlaceholder()
                    //   else
                    //     ..._alerts.map((alert) => _AlertCard(alert: alert)),
                    //
                    // See the commented-out _AlertCard class at the bottom
                    // of this file for the ready-made card widget.
                    // -----------------------------------------------------------
                    const _AlertsPlaceholder(),

                    const SizedBox(height: 24),
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

// ── Alerts Placeholder ───────────────────────────────────────────────────────

class _AlertsPlaceholder extends StatelessWidget {
  const _AlertsPlaceholder();

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
            'No alerts yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black45,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Alerts published by the admin\nwill appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.black38),
          ),
        ],
      ),
    );
  }
}

// ── Map Control Button ───────────────────────────────────────────────────────

class _MapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _MapButton({
    required this.icon,
    required this.onTap,
    this.color,
  });

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

// ── Alert Card (ready to use when integration is added) ──────────────────────
// TODO: Uncomment this widget when alerts are integrated with the backend.
//
// class _AlertCard extends StatelessWidget {
//   final Map<String, dynamic> alert;
//   const _AlertCard({required this.alert});
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: const Color(0xFFF0EBE3)),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.04),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 3,
//             height: 44,
//             decoration: BoxDecoration(
//               color: alert['color'] as Color,
//               borderRadius: BorderRadius.circular(2),
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(alert['title'] as String,
//                     style: const TextStyle(
//                         fontSize: 15, fontWeight: FontWeight.w700,
//                         color: Colors.black87)),
//                 const SizedBox(height: 4),
//                 Row(
//                   children: [
//                     const Icon(Icons.location_on_outlined,
//                         size: 13, color: Colors.black38),
//                     const SizedBox(width: 3),
//                     Text(alert['location'] as String,
//                         style: const TextStyle(
//                             fontSize: 12, color: Colors.black45)),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.end,
//             children: [
//               Text(alert['time'] as String,
//                   style: const TextStyle(fontSize: 11, color: Colors.black38)),
//               const SizedBox(height: 8),
//               const Icon(Icons.chevron_right, size: 18, color: Colors.black26),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }