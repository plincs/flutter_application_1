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
  bool _isMounted = true;

  @override
  void dispose() {
    _isMounted = false;
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
          _errorMessage = 'Error picking image: ${e.toString()}';
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

      // IMPORTANT: Check if user is already logged in
      if (authService.isAuthenticated) {
        await authService.signOut(); // Log out any existing session
      }

      // Step 1: Create user in Supabase Auth
      print('📝 Step 1: Creating user in Supabase Auth...');
      await authService.signUp(
        email: _emailController.text,
        password: _passwordController.text,
        displayName: _displayNameController.text,
      );

      // Check if user was created successfully
      final currentUser = authService.currentUser;
      if (currentUser == null) {
        throw Exception('User registration failed - no user created');
      }

      print('✅ Step 1 complete: User ${currentUser.id} created');

      // Step 2: Upload profile image (optional)
      String? profilePhotoUrl;
      if (_selectedImage != null) {
        print('📸 Step 2: Uploading profile image...');
        profilePhotoUrl = await _storageService.uploadImage(
          bucket: 'profile-images',
          imageFile: _selectedImage!,
        );
        print('✅ Profile image uploaded: $profilePhotoUrl');
      }

      // Step 3: Update user profile with additional info
      print('👤 Step 3: Creating user profile...');
      await _userService.updateUserProfile(
        displayName: _displayNameController.text,
        bio: null, // Bio is now removed
        profilePhotoUrl: profilePhotoUrl,
      );

      // Step 4: Force reload of user data
      print('🔄 Step 4: Reloading user data...');
      await authService.loadCurrentUser();

      // Verify user is properly authenticated
      if (!authService.isAuthenticated) {
        throw Exception('User authentication failed after registration');
      }

      print('🎉 Registration complete! Navigating to home...');

      // Success - navigate to home
      if (_isMounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/home', (route) => false);
      }
    } catch (e) {
      print('❌ Registration error: $e');

      // CRITICAL: If registration fails, make sure to sign out
      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        if (authService.isAuthenticated) {
          print(
            '⚠️ Registration failed but user is authenticated. Signing out...',
          );
          await authService.signOut();
        }
      } catch (signOutError) {
        print('⚠️ Error during sign out: $signOutError');
      }

      String errorMessage;

      if (e.toString().contains('already registered') ||
          e.toString().contains('User already registered') ||
          e.toString().contains('duplicate key')) {
        errorMessage =
            'This email is already registered. Please use a different email or login.';
      } else if (e.toString().contains('password') ||
          e.toString().contains('weak')) {
        errorMessage =
            'Password is too weak. Use at least 6 characters with letters and numbers.';
      } else if (e.toString().contains('email') ||
          e.toString().contains('invalid')) {
        errorMessage = 'Please enter a valid email address.';
      } else if (e.toString().contains('network') ||
          e.toString().contains('timeout')) {
        errorMessage =
            'Network error. Please check your internet connection and try again.';
      } else {
        errorMessage = 'Registration failed: ${e.toString().split('\n').first}';
      }

      if (_isMounted) {
        setState(() {
          _errorMessage = errorMessage;
          _isLoading = false;
        });
      }

      // Show error snackbar
      if (_isMounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    } finally {
      if (_isMounted && _isLoading) {
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
              'Tap to add profile photo (Optional)',
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
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
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
