import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import '../auth_service.dart';
import '../models/account_model.dart';

class LocationPickerSheet extends StatefulWidget {
  final Account account;
  final Function(Account)? onLocationAdded;

  const LocationPickerSheet({
    super.key,
    required this.account,
    this.onLocationAdded,
  });

  @override
  State<LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<LocationPickerSheet> {
  late MapController _mapController;
  LatLng? _selectedLocation;
  String _addressText = '';
  final TextEditingController _addressController = TextEditingController();
  bool _isLoadingLocation = false;
  bool _isUpdatingLocation = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selectedLocation = LatLng(28.6139, 77.2090); // Default to Delhi
    _addressText = widget.account.address ?? '';
    _addressController.text = _addressText;
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _errorMessage = null;
    });

    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );

        if (mounted) {
          setState(() {
            _selectedLocation = LatLng(position.latitude, position.longitude);
          });
          _mapController.move(_selectedLocation!, 15.0);
          _getAddressFromCoordinates(position.latitude, position.longitude);
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Location permission denied';
          });
        }
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to get current location';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      final placemarks = await geocoding.placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final parts = [placemark.name, placemark.street, placemark.locality, placemark.postalCode, placemark.country]
            .whereType<String>()
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        final address = parts.join(', ');
        if (mounted) {
          setState(() {
            _addressController.text = address;
            _addressText = address;
          });
        }
      }
    } catch (e) {
      debugPrint('Error getting address: $e');
    }
  }

  Future<void> _updateLocation() async {
    if (_selectedLocation == null || _addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select location and enter address'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() {
      _isUpdatingLocation = true;
      _errorMessage = null;
    });

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      if (auth.currentUser == null) throw 'User not logged in';

      final payload = {
        'latitude': _selectedLocation!.latitude.toString(),
        'longitude': _selectedLocation!.longitude.toString(),
        'googleAddress': _addressController.text.trim(),
        'acIdCol': widget.account.acIdCol,
      };

      final dio = Dio(BaseOptions(
        baseUrl: 'http://mobileappsandbox.reckonsales.com:8080/reckon-biz/api/reckonpwsorder',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ));

      final response = await dio.post(
        '/UpdateLocation',
        data: payload,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'package_name': auth.packageNameHeader,
            if (auth.getAuthHeader() != null) 'Authorization': auth.getAuthHeader(),
          },
        ),
      );

      final responseData = response.data is Map ? response.data : {'success': false};
      final success = responseData['success'] ?? false;

      if (mounted) {
        if (success) {
          // Update account with new location
          final updatedAccount = Account(
            id: widget.account.id,
            name: widget.account.name,
            type: widget.account.type,
            phone: widget.account.phone,
            email: widget.account.email,
            balance: widget.account.balance,
            address: _addressController.text.trim(),
            latitude: _selectedLocation!.latitude,
            longitude: _selectedLocation!.longitude,
            code: widget.account.code,
            gstNumber: widget.account.gstNumber,
            address2: widget.account.address2,
            address3: widget.account.address3,
            rcount: widget.account.rcount,
            acIdCol: widget.account.acIdCol,
            opBal: widget.account.opBal,
            closBal: widget.account.closBal,
            accountCreditDays: widget.account.accountCreditDays,
            accountCreditLimit: widget.account.accountCreditLimit,
            accountCreditBills: widget.account.accountCreditBills,
          );

          widget.onLocationAdded?.call(updatedAccount);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location updated successfully'), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        } else {
          setState(() {
            _errorMessage = responseData['message'] ?? 'Failed to update location';
          });
        }
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.response?.data is Map
              ? (e.response?.data['message'] ?? e.message ?? 'Network error')
              : (e.message ?? 'Network error');
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingLocation = false;
        });
      }
    }
  }

  void _onMapTap(LatLng point) {
    setState(() {
      _selectedLocation = point;
    });
    _getAddressFromCoordinates(point.latitude, point.longitude);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Location',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.primary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.account.name,
                          style: TextStyle(fontSize: 12, color: cs.onPrimaryContainer),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Error message
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(fontSize: 13, color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              ),

            // Map and Address fields
            Expanded(
              child: ListView(
                controller: controller,
                children: [
                  // Map
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 250,
                        child: _selectedLocation == null
                            ? Center(
                                child: _isLoadingLocation
                                    ? CircularProgressIndicator(color: cs.primary)
                                    : const Text('Loading map...'),
                              )
                            : FlutterMap(
                                mapController: _mapController,
                                options: MapOptions(
                                  initialCenter: _selectedLocation!,
                                  initialZoom: 15.0,
                                  onTap: (_, point) => _onMapTap(point),
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName: 'com.reckon.reckonbiz',
                                  ),
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: _selectedLocation!,
                                        width: 80,
                                        height: 80,
                                        child: Icon(Icons.location_on, color: cs.error, size: 40),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),

                  // Latitude/Longitude display
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text('Latitude', style: TextStyle(fontSize: 11, color: Colors.grey[700])),
                              const SizedBox(height: 4),
                              Text(
                                _selectedLocation?.latitude.toStringAsFixed(6) ?? 'N/A',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Container(width: 1, height: 40, color: Colors.grey[300]),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text('Longitude', style: TextStyle(fontSize: 11, color: Colors.grey[700])),
                              const SizedBox(height: 4),
                              Text(
                                _selectedLocation?.longitude.toStringAsFixed(6) ?? 'N/A',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Container(width: 1, height: 40, color: Colors.grey[300]),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text('Current', style: TextStyle(fontSize: 11, color: Colors.grey[700])),
                                const SizedBox(height: 4),
                                ElevatedButton.icon(
                                  onPressed: _getCurrentLocation,
                                  icon: const Icon(Icons.my_location, size: 16),
                                  label: const Text('Get', style: TextStyle(fontSize: 11)),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Address input
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Address',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.primary),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _addressController,
                          minLines: 3,
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText: 'Enter or modify address',
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: cs.primary),
                            ),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                          onChanged: (value) {
                            _addressText = value;
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Action buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isUpdatingLocation ? null : () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                            label: const Text('Cancel'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(color: cs.outline),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _isUpdatingLocation ? null : _updateLocation,
                            icon: _isUpdatingLocation ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white))) : const Icon(Icons.check),
                            label: Text(_isUpdatingLocation ? 'Updating...' : 'Save Location'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: cs.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
