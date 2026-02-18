import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DeliveryDetailPage extends StatelessWidget {
  final Map<String, dynamic> deliveryData;

  const DeliveryDetailPage({super.key, required this.deliveryData});

  String _getString(String key, [String defaultValue = 'N/A']) {
    final val = deliveryData[key];
    if (val == null) return defaultValue;
    final str = val.toString().trim();
    if (str.isEmpty || str.toLowerCase() == 'null') return defaultValue;
    return str;
  }

  double _getDouble(String key) {
    final val = deliveryData[key];
    if (val == null) return 0.0;
    return double.tryParse(val.toString()) ?? 0.0;
  }

  int _getInt(String key) {
    final val = deliveryData[key];
    if (val == null) return 0;
    if (val is int) return val;
    if (val is double) return val.toInt();
    return int.tryParse(val.toString()) ?? 0;
  }

  Future<void> _openMapsNavigation(BuildContext context) async {
    try {
      // Try using coordinates first
      final lat = _getString('latitude');
      final lng = _getString('longitude');

      if (lat != 'N/A' && lng != 'N/A') {
        final googleMapsUrl = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
        return;
      }

      // Fallback to address-based navigation
      final queryParts = <String>[];
      final station = _getString('station');
      final area = _getString('area');

      if (station != 'N/A') queryParts.add(station);
      if (area != 'N/A') queryParts.add(area);

      if (queryParts.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location not available for this delivery'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      final query = Uri.encodeComponent(queryParts.join(', '));
      final googleMapsUrl = Uri.parse('google.navigation:q=$query&mode=d');
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open Google Maps. Please make sure it is installed.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: const Color(0xFF1976D2),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFE65100),
                      Color(0xFFFF6F00),
                      Color(0xFF1976D2),
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          _getString('acname', 'Delivery Details'),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Bill No: ${_getString('billno')}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // Bill Information Card
                _buildSectionCard(
                  'Bill Information',
                  [
                    _buildInfoRow('Bill Number', _getString('billno')),
                    _buildInfoRow('Bill Date', _getString('billdate')),
                    _buildInfoRow('Bill Amount', '₹${_getDouble('billamt').toStringAsFixed(2)}'),
                    _buildInfoRow('Items', _getInt('item').toString()),
                    _buildInfoRow('Quantity', _getDouble('qty').toStringAsFixed(2)),
                  ],
                  colorScheme,
                ),
                const SizedBox(height: 16),

                // Account Details Card
                _buildSectionCard(
                  'Account Details',
                  [
                    _buildInfoRow('Account No', _getString('acno')),
                    _buildInfoRow('Account Name', _getString('acname')),
                    _buildInfoRow('Mobile', _getString('mobile')),
                  ],
                  colorScheme,
                ),
                const SizedBox(height: 16),

                // Address Card
                _buildSectionCard(
                  'Address',
                  [
                    _buildInfoRow('Address Line 1', _getString('address1')),
                    _buildInfoRow('Address Line 2', _getString('address2')),
                    _buildInfoRow('Address Line 3', _getString('address3')),
                    _buildInfoRow('Station', _getString('station')),
                    _buildInfoRow('Area', _getString('area')),
                    _buildInfoRow('Route', _getString('route')),
                  ],
                  colorScheme,
                ),
                const SizedBox(height: 16),

                // Location Card
                if (_getString('latitude') != 'N/A' && _getString('longitude') != 'N/A')
                  _buildSectionCard(
                    'Location',
                    [
                      _buildInfoRow('Latitude', _getString('latitude')),
                      _buildInfoRow('Longitude', _getString('longitude')),
                      _buildInfoRow('Google Address', _getString('googleaddress')),
                    ],
                    colorScheme,
                  ),
                if (_getString('latitude') != 'N/A' && _getString('longitude') != 'N/A')
                  const SizedBox(height: 16),

                // Delivery Status Card
                _buildSectionCard(
                  'Delivery Status',
                  [
                    _buildInfoRow('Status', _getString('status') == '1' ? 'Completed' : 'Pending'),
                    _buildInfoRow('Remark', _getString('remark')),
                    _buildInfoRow('Status Name', _getString('stausname')),
                  ],
                  colorScheme,
                ),
                const SizedBox(height: 16),

                // Images Section
                if (_getString('imageurl') != 'N/A' || _getString('image1url') != 'N/A')
                  _buildImagesSection(colorScheme),
                if (_getString('imageurl') != 'N/A' || _getString('image1url') != 'N/A')
                  const SizedBox(height: 16),

                // Navigation Button
                if (_getString('latitude') != 'N/A' && _getString('longitude') != 'N/A')
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () => _openMapsNavigation(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      icon: const Icon(Icons.navigation, size: 24),
                      label: const Text(
                        'Navigate to Location',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSectionCard(String title, List<Widget> children, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagesSection(ColorScheme colorScheme) {
    final imageUrl = _getString('imageurl');
    final image1Url = _getString('image1url');

    final images = <String>[];
    if (imageUrl != 'N/A') images.add(imageUrl);
    if (image1Url != 'N/A') images.add(image1Url);

    if (images.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Delivery Images',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: images.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _showImageDialog(context, images[index]),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: images[index],
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  placeholder: (context, url) => const CircularProgressIndicator(),
                  errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white, size: 48),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

