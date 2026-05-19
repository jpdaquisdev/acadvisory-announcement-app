import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'announcement_setter_page.dart';
import 'announcement_calendar_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp1());
}

class MyApp1 extends StatelessWidget {
  const MyApp1({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Announcements',
      home: const AuthGate(),
    );
  }
}


class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData) {
          return const ViewPostsPage();
        }

        return const AuthPage();
      },
    );
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isLoginView = true;
  bool showPanel = true;
  bool liftLogo = false;
  bool isSwitching = false;
  bool isAuthLoading = false;
  String? authMessage;

  final TextEditingController loginEmailController = TextEditingController();
  final TextEditingController loginPasswordController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController signUpEmailController = TextEditingController();
  final TextEditingController signUpPasswordController = TextEditingController();

  static const Color accentColor = Color(0xffFFD24C);
  static const Color softYellow = Color(0xffFFF1C8);
  static const Color softGray = Color(0xffEFEFEF);

  @override
  void dispose() {
    loginEmailController.dispose();
    loginPasswordController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    usernameController.dispose();
    signUpEmailController.dispose();
    signUpPasswordController.dispose();
    super.dispose();
  }

  void setAuthMessage(String? message) {
    if (!mounted) {
      return;
    }

    setState(() {
      authMessage = message;
    });
  }

  String getFirebaseAuthMessage(FirebaseAuthException error) {
    if (error.code == 'invalid-email') {
      return 'Please enter a valid email address.';
    }

    if (error.code == 'user-disabled') {
      return 'This account has been disabled.';
    }

    if (error.code == 'user-not-found' ||
        error.code == 'wrong-password' ||
        error.code == 'invalid-credential') {
      return 'Incorrect email or password.';
    }

    if (error.code == 'email-already-in-use') {
      return 'This email already has an account.';
    }

    if (error.code == 'weak-password') {
      return 'Password must be at least 6 characters.';
    }

    if (error.code == 'network-request-failed') {
      return 'Please check your internet connection.';
    }

    return error.message ?? 'Something went wrong. Please try again.';
  }

  Future<void> signIn() async {
    final email = loginEmailController.text.trim();
    final password = loginPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setAuthMessage('Please enter your email and password.');
      return;
    }

    setState(() {
      isAuthLoading = true;
      authMessage = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      setAuthMessage(getFirebaseAuthMessage(error));
    } catch (_) {
      setAuthMessage('Something went wrong. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          isAuthLoading = false;
        });
      }
    }
  }

  Future<void> signUp() async {
    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final username = usernameController.text.trim();
    final email = signUpEmailController.text.trim();
    final password = signUpPasswordController.text.trim();

    if (firstName.isEmpty ||
        lastName.isEmpty ||
        username.isEmpty ||
        email.isEmpty ||
        password.isEmpty) {
      setAuthMessage('Please complete all sign up fields.');
      return;
    }

    if (password.length < 6) {
      setAuthMessage('Password must be at least 6 characters.');
      return;
    }

    setState(() {
      isAuthLoading = true;
      authMessage = null;
    });

    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      final fullName = '$firstName $lastName'.trim();

      if (user != null) {
        await user.updateDisplayName(fullName);

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'firstName': firstName,
          'lastName': lastName,
          'username': username,
          'email': email,
          'role': 'Student',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } on FirebaseAuthException catch (error) {
      setAuthMessage(getFirebaseAuthMessage(error));
    } catch (_) {
      setAuthMessage('Something went wrong. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          isAuthLoading = false;
        });
      }
    }
  }

  Future<void> switchAuthView(bool openLogin) async {
    if (isLoginView == openLogin || isSwitching || isAuthLoading) {
      return;
    }

    setState(() {
      isSwitching = true;
      showPanel = false;
      liftLogo = true;
      authMessage = null;
    });

    await Future.delayed(const Duration(milliseconds: 320));

    if (!mounted) {
      return;
    }

    setState(() {
      isLoginView = openLogin;
    });

    await Future.delayed(const Duration(milliseconds: 90));

    if (!mounted) {
      return;
    }

    setState(() {
      showPanel = true;
      liftLogo = false;
      isSwitching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final panelHeight = size.height * 0.73;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeInOut,
        color: isLoginView ? accentColor : Colors.white,
        child: SafeArea(
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeInOut,
                left: 36,
                right: 24,
                top: liftLogo ? 34 : 58,
                child: const _AcadvisoryLogo(),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: AnimatedSlide(
                  offset: showPanel ? Offset.zero : const Offset(0, 1.15),
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeInOut,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 360),
                    curve: Curves.easeInOut,
                    height: panelHeight,
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(30, 34, 30, 22),
                    decoration: BoxDecoration(
                      color: isLoginView ? Colors.white : accentColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(82),
                        topRight: Radius.circular(82),
                      ),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: isLoginView
                          ? _LoginPanel(
                              key: const ValueKey('login-panel'),
                              emailController: loginEmailController,
                              passwordController: loginPasswordController,
                              authMessage: authMessage,
                              isLoading: isAuthLoading,
                              onSignIn: signIn,
                              onOpenSignUp: () {
                                switchAuthView(false);
                              },
                            )
                          : _SignUpPanel(
                              key: const ValueKey('signup-panel'),
                              firstNameController: firstNameController,
                              lastNameController: lastNameController,
                              usernameController: usernameController,
                              emailController: signUpEmailController,
                              passwordController: signUpPasswordController,
                              authMessage: authMessage,
                              isLoading: isAuthLoading,
                              onSignUp: signUp,
                              onOpenLogin: () {
                                switchAuthView(true);
                              },
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AcadvisoryLogo extends StatelessWidget {
  const _AcadvisoryLogo();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'the',
          style: TextStyle(
            fontSize: 42,
            height: 0.85,
            fontWeight: FontWeight.w300,
            letterSpacing: 2,
            color: Colors.black,
          ),
        ),
        Text(
          'ACADvisory',
          style: TextStyle(
            fontSize: 44,
            height: 0.95,
            fontWeight: FontWeight.w900,
            letterSpacing: -2,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Stay updated with the latest announcements.',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xff6F6F6F),
          ),
        ),
      ],
    );
  }
}

class _LoginPanel extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final String? authMessage;
  final bool isLoading;
  final VoidCallback onSignIn;
  final VoidCallback onOpenSignUp;

  const _LoginPanel({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.authMessage,
    required this.isLoading,
    required this.onSignIn,
    required this.onOpenSignUp,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 22),
          const Text(
            'LOGIN',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 42),
          _AuthTextField(
            controller: emailController,
            hintText: 'EMAIL',
            fillColor: _AuthPageState.softGray,
            obscureText: false,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            enabled: !isLoading,
          ),
          const SizedBox(height: 18),
          _AuthTextField(
            controller: passwordController,
            hintText: 'PASSWORD',
            fillColor: _AuthPageState.softGray,
            obscureText: true,
            textInputAction: TextInputAction.done,
            enabled: !isLoading,
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: isLoading ? null : () {},
              style: TextButton.styleFrom(
                foregroundColor: Colors.black,
                padding: EdgeInsets.zero,
              ),
              child: const Text(
                'Forgot Password?',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ),
          if (authMessage != null) ...[
            const SizedBox(height: 8),
            _AuthMessage(text: authMessage!),
          ],
          const SizedBox(height: 26),
          _AuthRoundedButton(
            label: isLoading ? 'Signing In...' : 'Sign In',
            backgroundColor: _AuthPageState.accentColor,
            textColor: Colors.black,
            onTap: isLoading ? null : onSignIn,
          ),
          const SizedBox(height: 28),
          _AuthSwitchText(
            normalText: "Don't have an account yet? ",
            actionText: 'SIGN UP',
            onTap: isLoading ? () {} : onOpenSignUp,
          ),
        ],
      ),
    );
  }
}

class _SignUpPanel extends StatelessWidget {
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController usernameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final String? authMessage;
  final bool isLoading;
  final VoidCallback onSignUp;
  final VoidCallback onOpenLogin;

  const _SignUpPanel({
    super.key,
    required this.firstNameController,
    required this.lastNameController,
    required this.usernameController,
    required this.emailController,
    required this.passwordController,
    required this.authMessage,
    required this.isLoading,
    required this.onSignUp,
    required this.onOpenLogin,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const Text(
            'SIGN UP',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 22),
          _AuthTextField(
            controller: firstNameController,
            hintText: 'FIRST NAME',
            fillColor: Colors.white,
            obscureText: false,
            showShadow: true,
            textInputAction: TextInputAction.next,
            enabled: !isLoading,
          ),
          const SizedBox(height: 16),
          _AuthTextField(
            controller: lastNameController,
            hintText: 'LAST NAME',
            fillColor: Colors.white,
            obscureText: false,
            showShadow: true,
            textInputAction: TextInputAction.next,
            enabled: !isLoading,
          ),
          const SizedBox(height: 16),
          _AuthTextField(
            controller: usernameController,
            hintText: 'USERNAME',
            fillColor: Colors.white,
            obscureText: false,
            showShadow: true,
            textInputAction: TextInputAction.next,
            enabled: !isLoading,
          ),
          const SizedBox(height: 16),
          _AuthTextField(
            controller: emailController,
            hintText: 'EMAIL',
            fillColor: Colors.white,
            obscureText: false,
            showShadow: true,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            enabled: !isLoading,
          ),
          const SizedBox(height: 16),
          _AuthTextField(
            controller: passwordController,
            hintText: 'PASSWORD',
            fillColor: Colors.white,
            obscureText: true,
            showShadow: true,
            textInputAction: TextInputAction.done,
            enabled: !isLoading,
          ),
          if (authMessage != null) ...[
            const SizedBox(height: 14),
            _AuthMessage(text: authMessage!),
          ],
          const SizedBox(height: 28),
          _AuthRoundedButton(
            label: isLoading ? 'Signing Up...' : 'Sign Up',
            backgroundColor: Colors.black,
            textColor: Colors.white,
            onTap: isLoading ? null : onSignUp,
          ),
          const SizedBox(height: 22),
          _AuthSwitchText(
            normalText: 'Already have an account? ',
            actionText: 'LOGIN',
            onTap: isLoading ? () {} : onOpenLogin,
          ),
        ],
      ),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final Color fillColor;
  final bool obscureText;
  final bool showShadow;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final bool enabled;

  const _AuthTextField({
    this.controller,
    required this.hintText,
    required this.fillColor,
    required this.obscureText,
    this.showShadow = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: showShadow
            ? const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        enabled: enabled,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            fontSize: 12,
            color: Color(0xff8D8D8D),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 19),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class _AuthMessage extends StatelessWidget {
  final String text;

  const _AuthMessage({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.red,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AuthRoundedButton extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback? onTap;

  const _AuthRoundedButton({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.7 : 1,
        child: Container(
          height: 60,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthSwitchText extends StatelessWidget {
  final String normalText;
  final String actionText;
  final VoidCallback onTap;

  const _AuthSwitchText({
    required this.normalText,
    required this.actionText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 13,
          ),
          children: [
            TextSpan(text: normalText),
            TextSpan(
              text: actionText,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  void openCalendarPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AnnouncementCalendarPage(),
      ),
    );
  }

  void openSetterPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AnnouncementSetterPage(),
      ),
    );
  }

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    if (!context.mounted) {
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const AuthGate(),
      ),
      (route) => false,
    );
  }

  String getFullName(Map<String, dynamic>? userData, User? user) {
    final firstName = (userData?['firstName'] ?? '').toString().trim();
    final lastName = (userData?['lastName'] ?? '').toString().trim();
    final fullName = '$firstName $lastName'.trim();

    if (fullName.isNotEmpty) {
      return fullName.toUpperCase();
    }

    if ((user?.displayName ?? '').trim().isNotEmpty) {
      return user!.displayName!.trim().toUpperCase();
    }

    return (user?.email ?? 'USER').toUpperCase();
  }

  String getRole(Map<String, dynamic>? userData) {
    return (userData?['role'] ?? 'Student').toString().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: currentUser == null
              ? null
              : FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser.uid)
                  .snapshots(),
          builder: (context, snapshot) {
            final userData = snapshot.data?.data();
            final fullName = getFullName(userData, currentUser);
            final role = getRole(userData);

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xffBDBDBD)),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              color: Color(0xff6A6A6A),
                            ),
                          ),
                        ),
                        const SizedBox(height: 26),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            _ProfilePill(
                              text: 'PROFILE',
                              color: _AuthPageState.accentColor,
                            ),
                            _ProfilePill(
                              text: 'EDIT PROFILE',
                              color: _AuthPageState.softYellow,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
                          decoration: BoxDecoration(
                            color: const Color(0xffE5E5E5),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Column(
                            children: [
                              const CircleAvatar(
                                radius: 78,
                                backgroundColor: Color(0xffB8B8B8),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                fullName,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                role,
                                style: const TextStyle(
                                  fontSize: 17,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        const _ProfileMenuItem(text: 'Language'),
                        const SizedBox(height: 6),
                        const _ProfileMenuItem(text: 'Notification'),
                        const SizedBox(height: 6),
                        const _ProfileMenuItem(text: 'Change Password'),
                        const SizedBox(height: 28),
                        const _ProfileMenuItem(text: 'Help'),
                        const SizedBox(height: 6),
                        const _ProfileMenuItem(text: 'Change User'),
                        const SizedBox(height: 6),
                        _ProfileMenuItem(
                          text: 'Logout',
                          onTap: () {
                            logout(context);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                _ProfileBottomBar(
                  onHomeTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ViewPostsPage(),
                      ),
                    );
                  },
                  onCalendarTap: () {
                    openCalendarPage(context);
                  },
                  onSetterTap: () {
                    openSetterPage(context);
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProfilePill extends StatelessWidget {
  final String text;
  final Color color;

  const _ProfilePill({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;

  const _ProfileMenuItem({
    required this.text,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: const Color(0xffE5E5E5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xff6A6A6A),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileBottomBar extends StatelessWidget {
  final VoidCallback onHomeTap;
  final VoidCallback onCalendarTap;
  final VoidCallback onSetterTap;

  const _ProfileBottomBar({
    required this.onHomeTap,
    required this.onCalendarTap,
    required this.onSetterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(35),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ProfileBottomIcon(
            icon: Icons.home_outlined,
            selected: false,
            onTap: onHomeTap,
          ),
          _ProfileBottomIcon(
            icon: Icons.calendar_month,
            selected: false,
            onTap: onCalendarTap,
          ),
          _ProfileBottomIcon(
            icon: Icons.chat_bubble_outline,
            selected: false,
            onTap: onSetterTap,
          ),
          const _ProfileBottomIcon(
            icon: Icons.person_outline,
            selected: true,
          ),
        ],
      ),
    );
  }
}

class _ProfileBottomIcon extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  const _ProfileBottomIcon({
    required this.icon,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.black,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: selected ? Colors.black : Colors.white,
        ),
      ),
    );
  }
}

class ViewPostsPage extends StatefulWidget {
  const ViewPostsPage({super.key});

  @override
  State<ViewPostsPage> createState() => _ViewPostsPageState();
}

class _ViewPostsPageState extends State<ViewPostsPage> {
  String? selectedCategoryFilter;
  String searchText = '';

  late final Stream<QuerySnapshot> announcementsStream;
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();

  final List<String> categories = [
    "Academics",
    "Events",
    "Urgent",
    "Organization",
    "Campus Updates",
  ];

  @override
  void initState() {
    super.initState();
    announcementsStream = FirebaseFirestore.instance
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  bool matchesSearch(QueryDocumentSnapshot announcement) {
    final query = searchText.trim().toLowerCase();

    if (query.isEmpty) {
      return true;
    }

    final data = announcement.data() as Map<String, dynamic>;
    final title = (data['title'] ?? '').toString().toLowerCase();
    final details = (data['details'] ?? '').toString().toLowerCase();
    final category = (data['category'] ?? data['type'] ?? '').toString().toLowerCase();

    return title.contains(query) ||
        details.contains(query) ||
        category.contains(query);
  }

  String formatDate(dynamic timestamp) {
    if (timestamp == null) {
      return 'Just now';
    }

    DateTime dateTime;

    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else {
      return 'Just now';
    }

    List<String> months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    int hour = dateTime.hour;
    String minute = dateTime.minute.toString().padLeft(2, '0');
    String amPm = hour >= 12 ? 'PM' : 'AM';

    if (hour > 12) {
      hour = hour - 12;
    }

    if (hour == 0) {
      hour = 12;
    }

    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}   $hour:$minute $amPm';
  }

  String limitText(String text) {
    if (text.length <= 34) {
      return text;
    }

    return '${text.substring(0, 34).trimRight()}...';
  }

  String getAnnouncementCategory(QueryDocumentSnapshot announcement) {
    final data = announcement.data() as Map<String, dynamic>;
    return data['category'] ?? data['type'] ?? 'Events';
  }

  void openAnnouncementCalendar(
    BuildContext context,
    QueryDocumentSnapshot announcement,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnnouncementCalendarPage(
          initialAnnouncementId: announcement.id,
        ),
      ),
    );
  }

  void openCalendarPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AnnouncementCalendarPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: announcementsStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('Error loading announcements'),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final announcements = snapshot.data!.docs;

                  final filteredAnnouncements = announcements.where((announcement) {
                    final matchesCategory = selectedCategoryFilter == null ||
                        getAnnouncementCategory(announcement) == selectedCategoryFilter;

                    return matchesCategory && matchesSearch(announcement);
                  }).toList();

                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            const CircleAvatar(
                              backgroundColor: Colors.white,
                              child: Icon(Icons.notifications_none, color: Colors.black),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        const Text(
                          "HELLO,",
                          style: TextStyle(fontSize: 18),
                        ),
                        const Text(
                          "JOHN LORENZ",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          "Stay updated with the latest announcements.",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),

                        const SizedBox(height: 18),

                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: TextField(
                            controller: searchController,
                            focusNode: searchFocusNode,
                            onChanged: (value) {
                              setState(() {
                                searchText = value;
                              });
                            },
                            decoration: const InputDecoration(
                              icon: Icon(Icons.search, color: Colors.grey),
                              hintText: "Search announcements",
                              hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                              border: InputBorder.none,
                            ),
                          ),
                        ),

                        const SizedBox(height: 25),

                        const Text(
                          "Featured Update",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),

                        const SizedBox(height: 8),

                        if (announcements.isNotEmpty)
                          featuredUpdateCard(context, announcements.first)
                        else
                          emptyFeaturedCard(),

                        const SizedBox(height: 25),

                        const Text(
                          "Browse",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),

                        const SizedBox(height: 10),

                        SizedBox(
                          height: 42,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: categories.length,
                            separatorBuilder: (context, index) {
                              return const SizedBox(width: 8);
                            },
                            itemBuilder: (context, index) {
                              final category = categories[index];

                              return categoryButton(
                                getIcon(category),
                                category,
                                getColor(category),
                                selectedCategoryFilter == category,
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Recent Updates",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (selectedCategoryFilter != null)
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedCategoryFilter = null;
                                  });
                                },
                                child: const Text(
                                  "Clear Filter",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        Expanded(
                          child: buildRecentUpdatesList(
                            context,
                            announcements,
                            filteredAnnouncements,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            Container(
              margin: const EdgeInsets.all(15),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(35),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  bottomIcon(Icons.home, true),
                  bottomIcon(
                    Icons.calendar_month,
                    false,
                    onTap: () {
                      openCalendarPage(context);
                    },
                  ),
                  bottomIcon(
                    Icons.chat_bubble_outline,
                    false,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AnnouncementSetterPage(),
                        ),
                      );
                    },
                  ),
                  bottomIcon(
                    Icons.person_outline,
                    false,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfilePage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildRecentUpdatesList(
    BuildContext context,
    List<QueryDocumentSnapshot> announcements,
    List<QueryDocumentSnapshot> filteredAnnouncements,
  ) {
    if (announcements.isEmpty) {
      return const Center(
        child: Text(
          "No announcements yet.",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    if (filteredAnnouncements.isEmpty) {
      final hasSearchText = searchText.trim().isNotEmpty;
      final message = hasSearchText
          ? "No announcements found."
          : "No $selectedCategoryFilter announcements.";

      return Center(
        child: Text(
          message,
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: filteredAnnouncements.length,
      itemBuilder: (context, index) {
        return updateCardFromFirebase(context, filteredAnnouncements[index]);
      },
    );
  }

  Widget featuredUpdateCard(
    BuildContext context,
    QueryDocumentSnapshot announcement,
  ) {
    final data = announcement.data() as Map<String, dynamic>;

    final title = data['title'] ?? 'No title';
    final details = data['details'] ?? 'No details';
    final category = data['category'] ?? data['type'] ?? 'Events';
    final date = formatDate(data['createdAt']);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xffFFD96A),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: getCategoryBadgeColor(category),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    category.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                smallBlackLabel(date),
                const SizedBox(height: 8),
                Text(
                  limitText(details),
                  style: const TextStyle(fontSize: 10),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    openAnnouncementCalendar(context, announcement);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "Read more",
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.campaign,
            size: 70,
            color: Colors.deepPurple,
          ),
        ],
      ),
    );
  }

  Widget emptyFeaturedCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xffFFD96A),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Text(
        "No featured announcement yet.",
        style: TextStyle(fontSize: 13),
      ),
    );
  }

  Widget updateCardFromFirebase(
    BuildContext context,
    QueryDocumentSnapshot announcement,
  ) {
    final data = announcement.data() as Map<String, dynamic>;

    final title = data['title'] ?? 'No title';
    final details = data['details'] ?? 'No details';
    final category = data['category'] ?? data['type'] ?? 'Events';
    final date = formatDate(data['createdAt']);

    return updateCard(
      getIcon(category),
      title,
      date,
      details,
      getColor(category),
      onTap: () {
        openAnnouncementCalendar(context, announcement);
      },
    );
  }

  Widget smallBlackLabel(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 9),
      ),
    );
  }

  Widget categoryButton(
    IconData icon,
    String text,
    Color color,
    bool selected,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (selectedCategoryFilter == text) {
            selectedCategoryFilter = null;
          } else {
            selectedCategoryFilter = text;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? Colors.black : Colors.transparent,
            width: 1.3,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15),
            const SizedBox(width: 5),
            Text(
              text,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget updateCard(
    IconData icon,
    String title,
    String date,
    String details,
    Color color, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 30),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    date,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                  ),
                  Text(
                    limitText(details),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 18),
          ],
        ),
      ),
    );
  }

  Widget bottomIcon(IconData icon, bool selected, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.black,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: selected ? Colors.black : Colors.white,
        ),
      ),
    );
  }

  IconData getIcon(String type) {
    if (type == "Academics") {
      return Icons.school;
    } else if (type == "Organization") {
      return Icons.groups;
    } else if (type == "Urgent") {
      return Icons.warning;
    } else if (type == "Campus Updates") {
      return Icons.campaign;
    } else {
      return Icons.event;
    }
  }

  Color getColor(String type) {
    if (type == "Academics") {
      return Colors.blue.shade100;
    } else if (type == "Organization") {
      return Colors.orange.shade100;
    } else if (type == "Urgent") {
      return Colors.red.shade100;
    } else if (type == "Campus Updates") {
      return Colors.green.shade100;
    } else {
      return Colors.purple.shade100;
    }
  }

  Color getCategoryBadgeColor(String type) {
    if (type == "Academics") {
      return Colors.blue;
    } else if (type == "Organization") {
      return Colors.orange;
    } else if (type == "Urgent") {
      return Colors.red;
    } else if (type == "Campus Updates") {
      return Colors.green;
    } else {
      return Colors.purple;
    }
  }
}
