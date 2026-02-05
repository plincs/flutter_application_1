import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../services/user_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _storageService = StorageService();
  final _userService = UserService();
  XFile? _selectedImage;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isMounted = true; // Add this flag

  @override
  void dispose() {
    _isMounted = false; // Set to false when widget is disposed
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final image = await _storageService.pickImageFromGallery();
      if (_isMounted && image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      if (_isMounted) {
        setState(() {
          _errorMessage = 'Error picking image';
        });
      }
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      if (_isMounted) {
        setState(() {
          _errorMessage = 'Passwords do not match';
        });
      }
      return;
    }

    if (_isMounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      // Call signUp without userId parameter
      await authService.signUp(
        email: _emailController.text,
        password: _passwordController.text,
        displayName: _displayNameController.text,
      );

      // Get the current user after signup
      final currentUser = authService.currentUser;
      if (currentUser == null) {
        throw Exception('User registration failed - no user returned');
      }

      // Upload profile image if selected
      String? profilePhotoUrl;
      if (_selectedImage != null) {
        profilePhotoUrl = await _storageService.uploadImage(
          bucket: 'profile-images',
          imageFile: _selectedImage!,
        );
      }

      // Update user profile with additional info (REMOVED BIO)
      await _userService.updateUserProfile(
        displayName: _displayNameController.text,
        profilePhotoUrl: profilePhotoUrl,
        // Bio removed from here
      );

      // Wait a moment to ensure profile is loaded
      await Future.delayed(const Duration(milliseconds: 500));

      // Check if widget is still mounted before navigating
      if (_isMounted) {
        // Navigate to home screen
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/home', (route) => false);
      }
    } catch (e) {
      print('Registration error: $e');

      if (_isMounted) {
        setState(() {
          _errorMessage =
              e.toString().contains('User already registered') ||
                  e.toString().contains('already registered') ||
                  e.toString().contains('duplicate key')
              ? 'Email already registered. Please use a different email.'
              : 'Registration failed. Please try again.';
        });
      }
    } finally {
      if (_isMounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Join Aniblog',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Create your account to start sharing knowledge',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // Profile Picture
            GestureDetector(
              onTap: _pickImage,
              child: Center(
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[200],
                        border: Border.all(color: Colors.grey[300]!, width: 2),
                      ),
                      child: _selectedImage != null
                          ? ClipOval(
                              child: FutureBuilder(
                                future: _selectedImage!.readAsBytes(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    return Image.memory(
                                      snapshot.data!,
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    );
                                  }
                                  return Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.blue[400],
                                    ),
                                  );
                                },
                              ),
                            )
                          : const Icon(
                              Icons.person_add,
                              size: 40,
                              color: Colors.grey,
                            ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Tap to add profile photo',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 30),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _displayNameController,
                    decoration: const InputDecoration(
                      labelText: 'Display Name',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                      hintText: 'What should we call you?',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a display name';
                      }
                      if (value.length < 2) {
                        return 'Name must be at least 2 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@') || !value.contains('.')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      return null;
                    },
                  ),
                  // BIO FIELD REMOVED FROM HERE
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),

            ElevatedButton(
              onPressed: _isLoading ? null : _register,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Text(
                      'Create Account',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Already have an account?'),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                  child: const Text('Sign In'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
