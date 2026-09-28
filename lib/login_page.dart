import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'forgot_password_page.dart';

import 'home_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  static const Color primaryColor = Color(0xFF5B4FE9);
  static const Color darkText = Color(0xFF1F2937);
  static const Color secondaryText = Color(0xFF6B7280);
  static const Color backgroundColor = Color(0xFFF7F7FC);

  // ------------------------------------------------------------
  // GOOGLE SIGN IN
  // ------------------------------------------------------------

  Future<void> _signInWithGoogle() async {
    FocusScope.of(context).unfocus();

    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;

      await googleSignIn.initialize();

      final GoogleSignInAccount googleUser =
      await googleSignIn.authenticate();

      final GoogleSignInAuthentication googleAuth =
          googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomePage(),
        ),
      );
    } on GoogleSignInException catch (e) {
      if (!mounted) return;

      if (e.code == GoogleSignInExceptionCode.canceled) {
        _showErrorMessage('Google sign-in was cancelled.');
      } else {
        _showErrorMessage(
          'Google sign-in failed. Please try again.',
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      _showErrorMessage(
        e.message ?? 'Google sign-in failed.',
      );
    } catch (e) {
      if (!mounted) return;

      _showErrorMessage(
        'Something went wrong with Google sign-in.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ------------------------------------------------------------
  // EMAIL LOGIN
  // ------------------------------------------------------------

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    if (_isLoading) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      final UserCredential userCredential =
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user == null) {
        throw Exception('Firebase did not return a user.');
      }

      await user.reload();

      user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('Unable to load Firebase user.');
      }

      // Google users don't need email verification here.
      final isGoogleUser = user.providerData.any(
            (provider) => provider.providerId == 'google.com',
      );

      if (!isGoogleUser && !user.emailVerified) {
        if (!mounted) return;

        await _showEmailVerificationDialog(user);
        return;
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomePage(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message;

      switch (e.code) {
        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;

        case 'user-not-found':
          message = 'No account found with this email.';
          break;

        case 'wrong-password':
          message = 'Incorrect password.';
          break;

        case 'invalid-credential':
          message = 'Incorrect email or password.';
          break;

        case 'user-disabled':
          message = 'This account has been disabled.';
          break;

        case 'too-many-requests':
          message =
          'Too many login attempts. Please try again later.';
          break;

        case 'network-request-failed':
          message =
          'Network error. Please check your internet connection.';
          break;

        case 'operation-not-allowed':
          message =
          'Email/Password authentication is not enabled in Firebase.';
          break;

        default:
          message =
          'Unable to login. Please check your details and try again.';
      }

      _showErrorMessage(message);
    } catch (e) {
      if (!mounted) return;

      _showErrorMessage(
        'Something went wrong. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ------------------------------------------------------------
  // EMAIL VERIFICATION
  // ------------------------------------------------------------

  Future<void> _showEmailVerificationDialog(User user) async {
    bool resendLoading = false;
    bool checkingVerification = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              titlePadding: const EdgeInsets.fromLTRB(
                24,
                24,
                24,
                8,
              ),
              contentPadding: const EdgeInsets.fromLTRB(
                24,
                8,
                24,
                8,
              ),
              actionsPadding: const EdgeInsets.fromLTRB(
                16,
                8,
                16,
                16,
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mark_email_unread_outlined,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Verify Your Email',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  const Text(
                    'Your email address has not been verified yet.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 20,
                          color: primaryColor,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            user.email ?? 'your email address',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: darkText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Check your inbox and click the verification link. '
                        'Also check your spam or junk folder.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: secondaryText,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed:
                  resendLoading || checkingVerification
                      ? null
                      : () async {
                    setDialogState(() {
                      resendLoading = true;
                    });

                    try {
                      await user.sendEmailVerification();

                      if (!dialogContext.mounted) return;

                      ScaffoldMessenger.of(dialogContext)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Verification email sent. '
                                'Please check your inbox.',
                          ),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 4),
                        ),
                      );
                    } on FirebaseAuthException catch (e) {
                      if (!dialogContext.mounted) return;

                      ScaffoldMessenger.of(dialogContext)
                          .showSnackBar(
                        SnackBar(
                          content: Text(
                            e.message ??
                                'Could not send verification email.',
                          ),
                          duration:
                          const Duration(seconds: 5),
                        ),
                      );
                    } finally {
                      if (dialogContext.mounted) {
                        setDialogState(() {
                          resendLoading = false;
                        });
                      }
                    }
                  },
                  child: resendLoading
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                      : const Text('Resend Email'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed:
                  resendLoading || checkingVerification
                      ? null
                      : () async {
                    setDialogState(() {
                      checkingVerification = true;
                    });

                    try {
                      await user.reload();

                      final refreshedUser =
                          FirebaseAuth.instance.currentUser;

                      if (!dialogContext.mounted) return;

                      if (refreshedUser != null &&
                          refreshedUser.emailVerified) {
                        Navigator.pop(dialogContext);

                        if (!mounted) return;

                        _showSuccessMessage(
                          'Email verified successfully!',
                        );

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HomePage(),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(dialogContext)
                            .showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Email is still not verified. '
                                  'Please verify it first.',
                            ),
                            duration:
                            Duration(seconds: 4),
                          ),
                        );
                      }
                    } catch (e) {
                      if (!dialogContext.mounted) return;

                      ScaffoldMessenger.of(dialogContext)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Could not check verification status.',
                          ),
                        ),
                      );
                    } finally {
                      if (dialogContext.mounted) {
                        setDialogState(() {
                          checkingVerification = false;
                        });
                      }
                    }
                  },
                  child: checkingVerification
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text("I've Verified"),
                ),
                TextButton(
                  onPressed:
                  resendLoading || checkingVerification
                      ? null
                      : () async {
                    await FirebaseAuth.instance.signOut();

                    if (!dialogContext.mounted) return;

                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ------------------------------------------------------------
  // FORGOT PASSWORD
  // ------------------------------------------------------------
  void _forgotPassword() {
    if (_isLoading) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ForgotPasswordPage(),
      ),
    );
  }
  // ------------------------------------------------------------
  // ERROR / SUCCESS MESSAGES
  // ------------------------------------------------------------

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFD92D20),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // REGISTER NAVIGATION
  // ------------------------------------------------------------

  void _openRegisterPage() {
    if (_isLoading) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RegisterPage(),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // INPUT DECORATION
  // ------------------------------------------------------------

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(
        icon,
        color: primaryColor,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 18,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: primaryColor,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Colors.red,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.5,
        ),
      ),
      labelStyle: const TextStyle(
        color: secondaryText,
      ),
      hintStyle: TextStyle(
        color: Colors.grey.shade400,
      ),
    );
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 28,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 500,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: size.height < 700 ? 10 : 25,
                      ),

                      // App logo
                      Container(
                        width: 78,
                        height: 78,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF6D5DFB),
                              Color(0xFF4A3FD3),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color:
                              primaryColor.withValues(alpha: 0.25),
                              blurRadius: 22,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.lock_person_rounded,
                          color: Colors.white,
                          size: 38,
                        ),
                      ),

                      const SizedBox(height: 26),

                      const Text(
                        'Welcome back',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: darkText,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Sign in to continue to your account',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: secondaryText,
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(height: 34),

                      // Login card
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color:
                              Colors.black.withValues(alpha: 0.06),
                              blurRadius: 30,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Email address',
                              style: TextStyle(
                                color: darkText,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 8),

                            TextFormField(
                              controller: _emailController,
                              keyboardType:
                              TextInputType.emailAddress,
                              textInputAction:
                              TextInputAction.next,
                              autofillHints: const [
                                AutofillHints.email,
                              ],
                              decoration: _inputDecoration(
                                label: 'Email',
                                hint: 'you@example.com',
                                icon: Icons.email_outlined,
                              ),
                              validator: (value) {
                                if (value == null ||
                                    value.trim().isEmpty) {
                                  return 'Please enter your email';
                                }

                                final emailRegex = RegExp(
                                  r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                );

                                if (!emailRegex
                                    .hasMatch(value.trim())) {
                                  return 'Please enter a valid email';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 20),

                            const Text(
                              'Password',
                              style: TextStyle(
                                color: darkText,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 8),

                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction:
                              TextInputAction.done,
                              autofillHints: const [
                                AutofillHints.password,
                              ],
                              onFieldSubmitted: (_) {
                                if (!_isLoading) {
                                  _login();
                                }
                              },
                              decoration: _inputDecoration(
                                label: 'Password',
                                hint: 'Enter your password',
                                icon: Icons.lock_outline,
                                suffixIcon: IconButton(
                                  tooltip: _obscurePassword
                                      ? 'Show password'
                                      : 'Hide password',
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: secondaryText,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword =
                                      !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null ||
                                    value.isEmpty) {
                                  return 'Please enter your password';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 10),

                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _isLoading
                                    ? null
                                    : _forgotPassword,
                                child: const Text(
                                  'Forgot password?',
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),

                            SizedBox(
                              height: 56,
                              child: FilledButton(
                                onPressed:
                                _isLoading ? null : _login,
                                style: FilledButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor:
                                  primaryColor.withValues(
                                    alpha: 0.55,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: AnimatedSwitcher(
                                  duration: const Duration(
                                    milliseconds: 200,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                    key: ValueKey('loading'),
                                    width: 24,
                                    height: 24,
                                    child:
                                    CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                      : const Row(
                                    key: ValueKey('login'),
                                    mainAxisAlignment:
                                    MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Login',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight:
                                          FontWeight.w700,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(
                                        Icons
                                            .arrow_forward_rounded,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // OR divider
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                Padding(
                                  padding:
                                  const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Text(
                                    'OR',
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Google Sign-In button
                            SizedBox(
                              height: 54,
                              child: OutlinedButton(
                                onPressed: _isLoading
                                    ? null
                                    : _signInWithGoogle,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: darkText,
                                  backgroundColor: Colors.white,
                                  side: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(16),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: [
                                    Image.network(
                                      'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                                      width: 22,
                                      height: 22,
                                      errorBuilder:
                                          (_, _, _) {
                                        return const Icon(
                                          Icons
                                              .account_circle_outlined,
                                          size: 22,
                                          color: primaryColor,
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      'Continue with Google',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 26),

                      // Create account
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don't have an account? ",
                            style: TextStyle(
                              color: secondaryText,
                              fontSize: 14,
                            ),
                          ),
                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : _openRegisterPage,
                            child: const Text(
                              'Create account',
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.security_rounded,
                            size: 16,
                            color: secondaryText,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Secure Firebase authentication',
                            style: TextStyle(
                              color: secondaryText,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}