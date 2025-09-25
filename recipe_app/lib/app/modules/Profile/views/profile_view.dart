import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';
import 'package:video_player/video_player.dart';

import 'gallery_view.dart';
import 'location_view.dart';

class ProfileView extends StatefulWidget {
  @override
  _ProfileViewState createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final LocalAuthentication _localAuth = LocalAuthentication();
  File? _profileImage;

  bool _isEditing = false;
  late TabController _tabController;
  late VideoPlayerController _videoPlayerController;
  bool _isVideoPlaying = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeUserData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _addressController.dispose();
    _dobController.dispose();
    _bioController.dispose();
    _tabController.dispose();
    if (_isVideoPlaying) {
      _videoPlayerController.dispose();
    }
    super.dispose();
  }

  Future<void> _updateField(String field, dynamic value) async {
    final User? user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).update({field: value});
        _showUpdateNotification('$field successfully updated');
      } catch (e) {
        print('Error updating $field: $e');
      }
    }
  }

  Future<void> _pickImage() async {
  final picker = ImagePicker();
  // Menampilkan dialog pilihan sumber gambar
  final source = await showDialog<ImageSource>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Choose Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera),
              title: Text('Camera'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo),
              title: Text('Gallery'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      );
    },
  );

  if (source != null) {
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      final shouldSave = await _showConfirmationDialog();
      if (shouldSave == true) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
        await _saveImageToFirestore();
      }
    }
  }
}

  Future<bool?> _showConfirmationDialog() {
    return showDialog<bool>(context: context, builder: (context) {
      return AlertDialog(
        title: Text('Confirm Save'),
        content: Text('Do you want to save this profile picture?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('No', style: TextStyle(color: Colors.white)),
            style: TextButton.styleFrom(backgroundColor: Colors.red),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Yes', style: TextStyle(color: Colors.white)),
            style: TextButton.styleFrom(backgroundColor: Colors.green),
          ),
        ],
      );
    });
  }

  Future<void> _saveImageToFirestore() async {
    final User? user = _auth.currentUser;
    if (user != null && _profileImage != null) {
      try {
        String fileName = 'profileImages/${user.uid}.jpg';
        UploadTask uploadTask = _storage.ref(fileName).putFile(_profileImage!);
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();
        
        await _updateField('profileImage', downloadUrl);
      } catch (e) {
        print('Error saving profile image: $e');
      }
    }
  }

  void _showUpdateNotification(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Future<void> _clearProfileData() async {
    _usernameController.clear();
    _addressController.clear();
    _dobController.clear();
    _bioController.clear();

    final User? user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'username': '',
          'address': '',
          'dob': '',
          'bio': '',
          'profileImage': 'null',
          'fingerprintRegistered': false,
        });
        _showUpdateNotification('Profile data cleared successfully');
      } catch (e) {
        print('Error clearing profile data: $e');
      }
    }
  }

  Future<void> _deleteProfileField(String field) async {
    final User? user = _auth.currentUser;
    if (user != null) {
      try {
        // Delete the field value from Firestore
        await _firestore.collection('users').doc(user.uid).update({field: ''});
        
        // Clear the corresponding controller text
        if (field == 'username') {
          _usernameController.clear();
        } else if (field == 'address') {
          _addressController.clear();
        } else if (field == 'dob') {
          _dobController.clear();
        } else if (field == 'bio') {
          _bioController.clear();
        }
        
        _showUpdateNotification('$field deleted successfully');
      } catch (e) {
        print('Error deleting $field: $e');
      }
    }
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(context: context, builder: (context) {
      return AlertDialog(
        title: Text('Confirm Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('No', style: TextStyle(color: Colors.white)),
            style: TextButton.styleFrom(backgroundColor: Colors.green),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Yes', style: TextStyle(color: Colors.white)),
            style: TextButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      );
    });

    if (shouldLogout == true) {
      await _auth.signOut();
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  Future<void> _saveProfileChanges() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'username': _usernameController.text,
          'address': _addressController.text,
          'dob': _dobController.text,
          'bio': _bioController.text,
        });
        _showUpdateNotification('Profile updated successfully');

        // Set _isEditing to false after saving changes
        setState(() {
          _isEditing = false;
        });
      } catch (e) {
        print('Error updating profile: $e');
      }
    }
  }

  Future<void> _initializeUserData() async {
  final User? user = _auth.currentUser;
  if (user != null) {
    final userDoc = _firestore.collection('users').doc(user.uid);

    try {
      final docSnapshot = await userDoc.get();
      if (!docSnapshot.exists || !docSnapshot.data()!.containsKey('fingerprintRegistered')) {
        // Jika dokumen tidak ada atau field belum ada, tambahkan field fingerprintRegistered
        await userDoc.set({
          'fingerprintRegistered': false,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print("Error initializing user data: $e");
    }
  }
}

  Future<void> _registerFingerprint() async {
  try {
    // Cek apakah perangkat mendukung biometrik
    bool canCheckBiometrics = await _localAuth.canCheckBiometrics;

    if (!canCheckBiometrics) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Perangkat ini tidak mendukung biometrik')),
      );
      return;
    }

    // Autentikasi sidik jari pengguna
    bool isAuthenticated = await _localAuth.authenticate(
      localizedReason: 'Daftarkan fingerprint untuk autentikasi',
      options: AuthenticationOptions(
        useErrorDialogs: true,
        stickyAuth: true,
      ),
    );

    if (isAuthenticated) {
      // Simpan status fingerprint di Firestore
      final User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'fingerprintRegistered': true,
        });

        // Perbarui UI setelah fingerprint berhasil didaftarkan
        setState(() {
          // Status fingerprint sudah terdaftar
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fingerprint berhasil didaftarkan')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Autentikasi fingerprint dibatalkan')),
      );
    }
  } on PlatformException catch (e) {
    print("Error registering fingerprint: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Terjadi kesalahan saat mendaftarkan fingerprint: ${e.message}')),
    );
  }
}


Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Layanan lokasi tidak aktif');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Izin lokasi ditolak');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Izin lokasi ditolak secara permanen');
    }

    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
  }

  // Fungsi untuk mendapatkan lokasi dan alamat dari latitude dan longitude
  Future<String> getLocationAddress() async {
    try {
      // Mendapatkan lokasi terkini
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      // Mendapatkan alamat berdasarkan latitude dan longitude
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      Placemark place = placemarks[0];

      // Mengembalikan alamat lengkap
      return '${place.locality}, ${place.country}';
    } catch (e) {
      return 'Gagal mendapatkan alamat';
    }
  }


  @override
  Widget build(BuildContext context) {
    final User? user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile and Gallery'),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Profile'),
            Tab(text: 'Gallery'),
          ],
        ),
      ),
      body: user == null
          ? Center(child: Text('No user logged in'))
          : TabBarView(
              controller: _tabController,
              children: [
                // Profile View
                SingleChildScrollView(
                  padding: EdgeInsets.all(16.0),
                  child: FutureBuilder<DocumentSnapshot>(
                    future: _firestore.collection('users').doc(user.uid).get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return const Center(child: Text('User data not found'));
                      }

                      final userData = snapshot.data!;
                      final String? profileImageUrl = (userData.data() as Map<String, dynamic>?)?['profileImage'] as String?;
                      final String username = (userData.data() as Map<String, dynamic>?)?['username'] ?? '';
                      final String address = (userData.data() as Map<String, dynamic>?)?['address'] ?? '';
                      final String dob = (userData.data() as Map<String, dynamic>?)?['dob'] ?? '';
                      final String bio = (userData.data() as Map<String, dynamic>?)?['bio'] ?? '';
                      final String email = (userData.data() as Map<String, dynamic>?)?['email'] ?? '';
                      final String name = (userData.data() as Map<String, dynamic>?)?['name'] ?? '';

                      // Populate text controllers with user data
                      _usernameController.text = username;
                      _addressController.text = address;
                      _dobController.text = dob;
                      _bioController.text = bio;

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center, // Center vertically
                        crossAxisAlignment: CrossAxisAlignment.center, // Center horizontally
                        children: [
                          Center(
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: CircleAvatar(
                                radius: 80,
                                backgroundImage: _profileImage != null
                                    ? FileImage(_profileImage!) // Use the selected image
                                    : (profileImageUrl != null && profileImageUrl.isNotEmpty)
                                        ? NetworkImage(profileImageUrl) // Use Firebase URL if available
                                        : const AssetImage('assets/images/default_profile.png') as ImageProvider, // Default avatar
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          // Menampilkan nama dan email pengguna di bawah foto profil, dengan Center untuk menengah
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  "$name",
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 8), // Memberi jarak sedikit antara nama dan email
                                Text(
                                  "$email",
                                  style: TextStyle(fontSize: 16, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          Card(
                            elevation: 5,
                            child: ListTile(
                              title: Text('Username'),
                              subtitle: _isEditing
                                  ? TextField(
                                      controller: _usernameController,
                                      decoration: InputDecoration(hintText: 'Enter username'),
                                    )
                                  : Text(username),
                              trailing: _isEditing
                                  ? IconButton(
                                      icon: Icon(Icons.delete),
                                      onPressed: () {
                                        _deleteProfileField('username');
                                      },
                                    )
                                  : null,
                            ),
                          ),
                          Card(
                            elevation: 5,
                            child: ListTile(
                              title: Text('Address'),
                              subtitle: _isEditing
                                  ? TextField(
                                      controller: _addressController,
                                      decoration: InputDecoration(hintText: 'Enter address'),
                                    )
                                  : Text(address),
                              trailing: _isEditing
                                  ? IconButton(
                                      icon: Icon(Icons.delete),
                                      onPressed: () {
                                        _deleteProfileField('address');
                                      },
                                    )
                                  : null,
                            ),
                          ),
                          Card(
                            elevation: 5,
                            child: ListTile(
                              title: Text('Date of Birth'),
                              subtitle: _isEditing
                                  ? TextField(
                                      controller: _dobController,
                                      decoration: InputDecoration(hintText: 'Enter date of birth'),
                                    )
                                  : Text(dob),
                              trailing: _isEditing
                                  ? IconButton(
                                      icon: Icon(Icons.delete),
                                      onPressed: () {
                                        _deleteProfileField('dob');
                                      },
                                    )
                                  : null,
                            ),
                          ),
                          Card(
                            elevation: 5,
                            child: ListTile(
                              title: Text('Bio'),
                              subtitle: _isEditing
                                  ? TextField(
                                      controller: _bioController,
                                      decoration: InputDecoration(hintText: 'Enter bio'),
                                    )
                                  : Text(bio),
                              trailing: _isEditing
                                  ? IconButton(
                                      icon: Icon(Icons.delete),
                                      onPressed: () {
                                        _deleteProfileField('bio');
                                      },
                                    )
                                  : null,
                            ),
                          ),
                          Card(
                            elevation: 5,
                            child: ListTile(
                              title: Text('Location'),
                              subtitle: FutureBuilder<String>(
                                future: getLocationAddress(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return Text('Memeriksa lokasi...');
                                  }

                                  if (snapshot.hasError) {
                                    return Text('Gagal mendapatkan alamat');
                                  }

                                  if (snapshot.hasData) {
                                    return Text(snapshot.data ?? 'Alamat tidak ditemukan');
                                  }

                                  return Text('Tidak dapat mengambil lokasi');
                                },
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.location_on),
                                onPressed: () {
                                  // Navigate to LocationView when the button is pressed
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => LocationView()),
                                  );
                                },
                              ),
                            ),
                          ),
                          Card(
                            elevation: 5,
                            child: ListTile(
                              title: Text('Fingerprint'),
                              subtitle: FutureBuilder<DocumentSnapshot>(
                                future: _firestore.collection('users').doc(user.uid).get(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return Text('Memeriksa status...');
                                  }

                                  if (snapshot.hasError || !snapshot.hasData) {
                                    return Text('Gagal memuat status fingerprint');
                                  }

                                  bool isRegistered = snapshot.data!['fingerprintRegistered'] ?? false;
                                  return Text(isRegistered
                                      ? 'Fingerprint terdaftar'
                                      : 'Fingerprint belum terdaftar');
                                },
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.fingerprint),
                                onPressed: _registerFingerprint,
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          if (_isEditing)
                            ElevatedButton(
                              onPressed: _saveProfileChanges,
                              child: Text('Save Changes'),
                            ),
                          if (!_isEditing)
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _isEditing = true;
                                });
                              },
                              child: Text('Edit Profile'),
                            ),
                        ],
                      );
                    },
                  ),
                ),

                // Activity View
                ActivityView(),
              ],
            ),
    );
  }
}
