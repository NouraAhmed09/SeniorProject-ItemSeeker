import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:seeker_app/screens/ItemDetailScreen.dart';
import 'package:seeker_app/screens/MessagesScreen.dart';
import 'package:seeker_app/screens/NotificationScreen.dart';
import 'dart:convert';
import 'package:seeker_app/screens/login_screen.dart';
import 'package:seeker_app/screens/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String? _fullName;
  List<Map<String, dynamic>> _allItems = [];
  List<Map<String, dynamic>> _searchResults = [];
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _normalSearchController = TextEditingController();
  bool _isLoading = false;
  String _filterType = 'all_lost';

  @override
  void initState() {
    super.initState();
    _fetchUserFullName();
    _fetchAllItems();
  }

  Future<void> _fetchUserFullName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        setState(() {
          _fullName = userDoc['fullName'] ?? 'User';
        });
      } catch (e) {
        print("Error fetching user name: $e");
        setState(() {
          _fullName = "User";
        });
      }
    }
  }

  Future<void> _fetchAllItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      Query query;
      final user = FirebaseAuth.instance.currentUser;

      if (_filterType == 'all_lost') {
        query = FirebaseFirestore.instance
            .collection('lost_items')
            .orderBy('created_at', descending: true);
      } else if (_filterType == 'all_found') {
        query = FirebaseFirestore.instance
            .collection('found_items')
            .orderBy('created_at', descending: true);
      } else if (_filterType == 'my_lost' && user != null) {
        query = FirebaseFirestore.instance
            .collection('lost_items')
            .where('user_id', isEqualTo: user.uid)
            .orderBy('created_at', descending: true);
      } else if (_filterType == 'my_found' && user != null) {
        query = FirebaseFirestore.instance
            .collection('found_items')
            .where('user_id', isEqualTo: user.uid)
            .orderBy('created_at', descending: true);
      } else {
        query = FirebaseFirestore.instance
            .collection('lost_items')
            .orderBy('created_at', descending: true);
      }

      var snapshot = await query.get();

      List<Map<String, dynamic>> allItems = snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>?;

        return {
          'itemId': doc.id,
          'description': data != null
              ? data['description'] ?? 'No description'
              : 'No description',
          'color': data != null ? data['color'] ?? 'N/A' : 'N/A',
          'location': data != null ? data['location'] ?? 'Unknown' : 'Unknown',
          'date_time':
              data != null ? data['date_time'] ?? 'Unknown' : 'Unknown',
          'image_url': data != null ? data['image_url'] ?? '' : '',
          'show_name': data != null ? data['show_name'] ?? false : false,
          'show_phone': data != null ? data['show_phone'] ?? false : false,
          'user_id': data != null ? data['user_id'] ?? '' : '',
          'isSeeker': data != null ? data['isSeeker'] ?? false : false,
        };
      }).toList();

      setState(() {
        _allItems = allItems;
        _searchResults = allItems;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching items: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _searchItems(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = _allItems;
      });
    } else {
      setState(() {
        _searchResults = _allItems.where((item) {
          final description = item['description'] ?? '';
          return description.toLowerCase().contains(query.toLowerCase());
        }).toList();
      });
    }
  }

  Future<void> _searchLostItem(String query, {bool isAI = true}) async {
    if (query.isEmpty) {
      _searchItems('');
      return;
    }

    if (isAI) {
      setState(() {
        _isLoading = true;
      });

      const String apiUrl = 'http://192.168.0.100:4000/search';
      try {
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'query': query,
            'collection':
                _filterType.contains('found') ? 'found_items' : 'lost_items',
          }),
        );

        if (response.statusCode == 200) {
          final List<dynamic> responseData = jsonDecode(response.body);

          List<Map<String, dynamic>> tempResults = [];

          for (var doc in responseData) {
            final userId = doc['user_id'] ?? '';
            final description = doc['description'] ?? '';

            var querySnapshot = await FirebaseFirestore.instance
                .collection(
                    _filterType.contains('lost') ? 'lost_items' : 'found_items')
                .where('user_id', isEqualTo: userId)
                .where('description', isEqualTo: description)
                .get();

            if (querySnapshot.docs.isNotEmpty) {
              var document = querySnapshot.docs.first;
              tempResults.add({
                'itemId': document.id,
                ...doc,
              });
            } else {
              tempResults.add({
                'itemId': '',
                ...doc,
              });
            }
          }

          setState(() {
            _searchResults = tempResults;
            _isLoading = false;
          });
        } else {
          print("Failed to fetch search results");
          setState(() {
            _isLoading = false;
          });
        }
      } catch (e) {
        print("Error: $e");
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      _searchItems(query);
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const RegisterFoundItemPage()),
      );
    } else if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MessagesScreen()),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const NotificationScreen()),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      );
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Home Page"),
        backgroundColor: Colors.amber[900],
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
            tooltip: "Logout",
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome, ${_fullName ?? 'User'}",
              key: const Key('welcomeText'), // المفتاح المضاف
              style: TextStyle(fontSize: 24),
            ),

            SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: "Search using AI ...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onSubmitted: (query) => _searchLostItem(query, isAI: true),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _normalSearchController,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: "Search normally ...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: _searchItems,
            ),
            SizedBox(height: 16),
            DropdownButton<String>(
              value: _filterType,
              onChanged: (String? newValue) {
                setState(() {
                  _filterType = newValue!;
                  _fetchAllItems();
                });
              },
              items: <String>['all_lost', 'all_found', 'my_lost', 'my_found']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value == 'all_lost'
                        ? 'All Lost Items'
                        : value == 'all_found'
                            ? 'All Found Items'
                            : value == 'my_lost'
                                ? 'My Lost Items'
                                : 'My Found Items',
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 16),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : Expanded(
                    child: ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final result = _searchResults[index];
                        final String itemId = result['itemId'] ?? '';
                        final String description =
                            result['description'] ?? 'No description';
                        final String color = result['color'] ?? 'N/A';
                        final String location = result['location'] ?? 'Unknown';
                        final double similarity = (result['similarity'] is int
                                ? (result['similarity'] as int).toDouble()
                                : result['similarity'] as double? ?? 0.0) *
                            100;

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ItemDetailScreen(
                                  description: description,
                                  color: color,
                                  location: location,
                                  dateTime: result['date_time'] ?? 'Unknown',
                                  imageUrl: result['image_url'] ?? '',
                                  showName: result['show_name'] ?? false,
                                  showPhone: result['show_phone'] ?? false,
                                  userId: result['user_id'] ?? '',
                                  itemId: itemId,
                                  collectionName: _filterType.contains('lost')
                                      ? 'lost_items'
                                      : 'found_items',
                                  isSeeker: result['isSeeker'] ?? false,
                                ),
                              ),
                            );
                          },
                          child: Card(
                            child: ListTile(
                              leading: result['image_url'] != null
                                  ? Image.network(result['image_url'],
                                      width: 50, height: 50, fit: BoxFit.cover)
                                  : Icon(Icons.image),
                              title: Text(description),
                              subtitle: Text(
                                "Location: ${result['location'] ?? 'Unknown'}\n"
                                "Color: ${result['color'] ?? 'N/A'}\n"
                                "Similarity: ${similarity.toStringAsFixed(2)}%",
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[900],
        unselectedItemColor: Colors.black,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Register an Item',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Chats',
          ),
        ],
      ),
    );
  }
}

class RegisterFoundItemPage extends StatefulWidget {
  const RegisterFoundItemPage({super.key});

  @override
  _RegisterFoundItemPageState createState() => _RegisterFoundItemPageState();
}

class _RegisterFoundItemPageState extends State<RegisterFoundItemPage> {
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _dateTimeController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _showName = false;
  bool _showPhoneNumber = false;
  File? _image;
  String _itemType = 'found';
  final ImagePicker _picker = ImagePicker();
  final String _clientID = 'c376c37138c30d8';

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImageToImgur(File imageFile) async {
    final uri = Uri.parse('https://api.imgur.com/3/image');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Client-ID $_clientID';

    final file = await http.MultipartFile.fromPath('image', imageFile.path);
    request.files.add(file);

    final response = await request.send();
    final responseData = await response.stream.bytesToString();
    final jsonResponse = jsonDecode(responseData);

    if (response.statusCode == 200) {
      return jsonResponse['data']['link'];
    } else {
      return null;
    }
  }

  Future<String?> _classifyImage(File imageFile) async {
    final uri = Uri.parse('http://192.168.0.100:5000/classify');
    final request = http.MultipartRequest('POST', uri);
    request.files
        .add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();
    final responseData = await response.stream.bytesToString();

    if (response.statusCode == 204) {
      return null;
    }

    try {
      final jsonResponse = jsonDecode(responseData);
      return jsonResponse["predicted_class"];
    } catch (e) {
      return responseData.trim();
    }
  }

  Future<void> _saveFoundItem() async {
    if (_locationController.text.isEmpty ||
        _dateTimeController.text.isEmpty ||
        _colorController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please fill in all fields and select an image.")),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not logged in")),
        );
        return;
      }

      String? imageUrl;
      if (_image != null) {
        imageUrl = await _uploadImageToImgur(_image!);
        if (imageUrl == null)
          throw Exception("Failed to upload image to Imgur.");

        final predictedClass = await _classifyImage(_image!);

        if (predictedClass != null) {
          switch (predictedClass) {
            case 'phones':
              _descriptionController.text +=
                  " This item includes features related to mobile phones such as screen, charger, etc.";
              break;
            case 'keys':
              _descriptionController.text +=
                  " This item is likely a set of keys, potentially car or house keys.";
              break;
            case 'glasses':
              _descriptionController.text +=
                  " These seem to be glasses, possibly reading or sunglasses.";
              break;
          }
        }
      }

      final data = {
        'location': _locationController.text,
        'date_time': _dateTimeController.text,
        'color': _colorController.text,
        'description': _descriptionController.text,
        'show_name': _showName,
        'show_phone': _showPhoneNumber,
        'created_at': Timestamp.now(),
        'image_url': imageUrl,
        'item_type': _itemType,
        'user_id': user.uid,
        'isSeeker': false,
      };

      if (_itemType == 'found') {
        await FirebaseFirestore.instance.collection('found_items').add(data);
      } else {
        await FirebaseFirestore.instance.collection('lost_items').add(data);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Item successfully registered!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to register item: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Register an item"),
        backgroundColor: Colors.amber[900],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                color: Colors.grey.shade200,
                child: Center(
                  child: _image == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt,
                              size: 50,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Tap to upload image",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        )
                      : Image.file(_image!, fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: "Location"),
            ),
            TextField(
              controller: _dateTimeController,
              decoration: const InputDecoration(labelText: "Date & Time"),
            ),
            TextField(
              controller: _colorController,
              decoration: const InputDecoration(labelText: "Color"),
            ),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: "Description"),
            ),
            Row(
              children: [
                Checkbox(
                  value: _showName,
                  onChanged: (value) {
                    setState(() {
                      _showName = value!;
                    });
                  },
                ),
                const Text("Show my name"),
              ],
            ),
            Row(
              children: [
                Checkbox(
                  value: _showPhoneNumber,
                  onChanged: (value) {
                    setState(() {
                      _showPhoneNumber = value!;
                    });
                  },
                ),
                const Text("Show my phone number"),
              ],
            ),
            DropdownButton<String>(
              value: _itemType,
              onChanged: (String? newValue) {
                setState(() {
                  _itemType = newValue!;
                });
              },
              items: <String>['found', 'lost']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value[0].toUpperCase() + value.substring(1)),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveFoundItem,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[900],
              ),
              child: const Text("Register Item"),
            ),
          ],
        ),
      ),
    );
  }
}
