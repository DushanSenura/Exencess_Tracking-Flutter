import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth/signup_screen.dart';
import 'database/account_database_service.dart';
import 'viewmodels/finance_view_model.dart';
import 'views/financial_home_page.dart';
import 'views/login_page.dart';
import 'views/widgets/pin_pad.dart';

class FinanceTrackerApp extends StatelessWidget {
  const FinanceTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expenso',
      debugShowCheckedModeBanner: false,
      supportedLocales: const <Locale>[
        Locale('en'),
        Locale('si'),
        Locale('ta'),
      ],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F766E),
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(),
        scaffoldBackgroundColor: const Color.fromARGB(249, 255, 255, 255),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 1,
          shadowColor: Colors.black.withValues(alpha: 0.08),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        pageTransitionsTheme: PageTransitionsTheme(
          builders: <TargetPlatform, PageTransitionsBuilder>{
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  static const String _onboardingSeenKey = 'app_onboarding_seen';

  bool _isLoggedIn = false;
  bool _isLoading = true;
  bool _isUnlocked = false;
  bool _showOnboarding = false;
  bool _showSplashAfterOnboarding = false;
  bool _showCreateAccount = false;
  String? _prefilledLoginEmail;
  late final FinanceViewModel _viewModel;
  String _pinInput = '';
  int _pinShakeTick = 0;

  @override
  void initState() {
    super.initState();
    _viewModel = FinanceViewModel(
      accountDatabaseService: AccountDatabaseService(),
    );
    _init();
  }

  Future<void> _init() async {
    bool onboardingSeen = false;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      onboardingSeen = prefs.getBool(_onboardingSeenKey) ?? false;
    } catch (_) {
      onboardingSeen = false;
    }

    await Future<void>.delayed(const Duration(milliseconds: 1700));
    try {
      await _viewModel.initialize().timeout(const Duration(seconds: 2));
    } catch (_) {
      // Keep defaults and continue to login screen in case plugins are unavailable.
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoggedIn = _viewModel.rememberSession;
      _isUnlocked = !_viewModel.appLockEnabled;
      _showOnboarding = !onboardingSeen;
      _isLoading = false;
    });
  }

  Future<void> _completeOnboarding() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingSeenKey, true);
    } catch (_) {
      // Continue even if persistence is unavailable.
    }

    if (!mounted) {
      return;
    }

    if (_showSplashAfterOnboarding) {
      setState(() {
        _isLoading = true;
      });
      await Future<void>.delayed(const Duration(milliseconds: 1000));
      if (!mounted) {
        return;
      }
      setState(() {
        _showOnboarding = false;
        _showSplashAfterOnboarding = false;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _showOnboarding = false;
    });
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _unlockWithBiometric() async {
    final bool ok = await _viewModel.authenticateWithBiometrics(
      reason: 'Unlock Expenso',
    );
    if (!mounted) {
      return;
    }
    if (ok) {
      setState(() {
        _isUnlocked = true;
      });
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Biometric authentication failed.')),
    );
  }

  void _unlockWithPin() {
    final bool ok = _viewModel.validateAppPin(_pinInput);
    if (ok) {
      setState(() {
        _isUnlocked = true;
        _pinInput = '';
      });
      return;
    }
    setState(() {
      _pinInput = '';
      _pinShakeTick += 1;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Invalid PIN.')));
  }

  void _appendPinDigit(String digit) {
    if (_pinInput.length >= 4) {
      return;
    }
    bool autoSubmit = false;
    setState(() {
      _pinInput += digit;
      autoSubmit = _pinInput.length == 4;
    });
    if (autoSubmit) {
      _unlockWithPin();
    }
  }

  void _deletePinDigit() {
    if (_pinInput.isEmpty) {
      return;
    }
    setState(() {
      _pinInput = _pinInput.substring(0, _pinInput.length - 1);
    });
  }

  void _clearPin() {
    setState(() {
      _pinInput = '';
    });
  }

  Widget _buildUnlockGate() {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Image.asset(
                        'lib/assets/image/Expenso.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Welcome Back!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _viewModel.userName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 20),
                  TweenAnimationBuilder<double>(
                    key: ValueKey<int>(_pinShakeTick),
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 320),
                    builder:
                        (BuildContext context, double value, Widget? child) {
                          final double offset =
                              math.sin(value * math.pi * 4) * 10 * (1 - value);
                          return Transform.translate(
                            offset: Offset(offset, 0),
                            child: child,
                          );
                        },
                    child: PinDots(
                      label: '',
                      length: _pinInput.length,
                      maxLength: 4,
                      errorFlashTick: _pinShakeTick,
                    ),
                  ),
                  const SizedBox(height: 18),
                  PinPad(
                    onDigit: _appendPinDigit,
                    onBackspace: _deletePinDigit,
                    onClear: _clearPin,
                  ),
                  const SizedBox(height: 14),
                  if (_viewModel.biometricEnabled) ...<Widget>[
                    TextButton.icon(
                      onPressed: _unlockWithBiometric,
                      icon: const Icon(Icons.fingerprint),
                      label: const Text('Use Biometric'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const _LaunchSplashScreen();
    }

    if (_showOnboarding) {
      return _OnboardingScreen(onFinish: _completeOnboarding);
    }

    if (_isLoggedIn) {
      if (_viewModel.appLockEnabled && !_isUnlocked) {
        return _buildUnlockGate();
      }
      return FinancialHomePage(
        viewModel: _viewModel,
        onLogout: () {
          _viewModel.clearRememberSession();
          setState(() {
            _isLoggedIn = false;
            _isUnlocked = false;
            _showOnboarding = false;
            _showSplashAfterOnboarding = false;
            _showCreateAccount = false;
            _prefilledLoginEmail = null;
          });
        },
      );
    }

    if (_showCreateAccount) {
      return SignupScreen(
        onCreateAccount:
            ({
              required String name,
              required String email,
              required String password,
              required String confirmPassword,
            }) {
              return _viewModel.createAccount(
                name: name,
                email: email,
                password: password,
                confirmPassword: confirmPassword,
              );
            },
        onBackToLogin: (String? email) {
          setState(() {
            _prefilledLoginEmail = email;
            _showCreateAccount = false;
          });
        },
        onGoogleSignInSuccess: (String email) async {
          _viewModel.setRememberSession(true);
          final String syncMessage = await _viewModel.autoSyncOnLoginEmail(
            email,
          );
          if (!mounted) {
            return;
          }
          setState(() {
            _isLoggedIn = true;
            _isUnlocked = true;
            _showCreateAccount = false;
            _prefilledLoginEmail = null;
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(syncMessage)));
        },
      );
    }

    return LoginPage(
      initialEmail: _prefilledLoginEmail,
      validateCredentials: (String email, String password) {
        return _viewModel.validateLogin(email: email, password: password);
      },
      onOpenCreateAccount: () {
        setState(() {
          _showCreateAccount = true;
        });
      },
      onLoginSuccess: (bool rememberMe, String email) async {
        _viewModel.setRememberSession(true);
        final String syncMessage = await _viewModel.autoSyncOnLoginEmail(email);
        if (!mounted) {
          return;
        }
        setState(() {
          _isLoggedIn = true;
          _isUnlocked = true;
          _prefilledLoginEmail = null;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(syncMessage)));
      },
    );
  }
}

class _OnboardingScreen extends StatefulWidget {
  const _OnboardingScreen({required this.onFinish});

  final Future<void> Function() onFinish;

  @override
  State<_OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<_OnboardingScreen> {
  final PageController _pageController = PageController();
  int _pageIndex = 0;

  static const List<
    ({
      IconData icon,
      String title,
      String description,
      Color color,
      String? logoAsset,
      double? logoWidth,
    })
  >
  _pages =
      <
        ({
          IconData icon,
          String title,
          String description,
          Color color,
          String? logoAsset,
          double? logoWidth,
        })
      >[
        (
          icon: Icons.account_balance_wallet,
          title: 'Track Every Rupee',
          description:
              'Monitor income and expenses across all your accounts in one place.',
          color: Color(0xFF0E9F6E),
          logoAsset: 'lib/assets/image/Expenso.png',
          logoWidth: 170,
        ),
        (
          icon: Icons.savings,
          title: 'Grow Your Goals',
          description:
              'Create savings goals, fund them from accounts, and follow progress on Home.',
          color: Color(0xFF1E429F),
          logoAsset: null,
          logoWidth: null,
        ),
        (
          icon: Icons.insights,
          title: 'Make Better Decisions',
          description:
              'Use trends, reports, and budget health insights to improve money habits.',
          color: Color(0xFFC77B44),
          logoAsset: 'lib/assets/image/NovaCore.png',
          logoWidth: 140,
        ),
      ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _goNextOrFinish() async {
    if (_pageIndex < _pages.length - 1) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    await widget.onFinish();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isLast = _pageIndex == _pages.length - 1;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Color(0xFFF1FBF8), Color(0xFFFFFFFF)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              children: <Widget>[
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () async {
                      await widget.onFinish();
                    },
                    child: const Text('Skip'),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (int index) {
                      setState(() {
                        _pageIndex = index;
                      });
                    },
                    itemBuilder: (BuildContext context, int index) {
                      final ({
                        IconData icon,
                        String title,
                        String description,
                        Color color,
                        String? logoAsset,
                        double? logoWidth,
                      })
                      page = _pages[index];
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          if (page.logoAsset != null)
                            Image.asset(
                              page.logoAsset!,
                              width: page.logoWidth ?? 140,
                              fit: BoxFit.contain,
                            )
                          else
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: page.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(32),
                                border: Border.all(
                                  color: page.color.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Icon(
                                page.icon,
                                size: 56,
                                color: page.color,
                              ),
                            ),
                          const SizedBox(height: 28),
                          Text(
                            page.title,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              page.description,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: scheme.onSurface.withValues(
                                      alpha: 0.75,
                                    ),
                                  ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List<Widget>.generate(_pages.length, (int index) {
                    final bool active = index == _pageIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: active ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: active
                            ? scheme.primary
                            : scheme.outline.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _goNextOrFinish,
                    icon: Icon(isLast ? Icons.check : Icons.arrow_forward),
                    label: Text(isLast ? 'Get Started' : 'Next'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LaunchSplashScreen extends StatelessWidget {
  const _LaunchSplashScreen();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Color(0xFFEAF7F4), Color(0xFFF7FBFA)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 700),
                    tween: Tween<double>(begin: 0.92, end: 1),
                    curve: Curves.easeOutBack,
                    builder:
                        (BuildContext context, double value, Widget? child) {
                          return Transform.scale(
                            scale: value,
                            child: Opacity(
                              opacity: value.clamp(0, 1),
                              child: child,
                            ),
                          );
                        },
                    child: Image.asset(
                      'lib/assets/image/Expenso.png',
                      width: 190,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 26),
                  Text(
                    'Track Smart. Spend Better.',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),
                  SizedBox(
                    width: 34,
                    height: 34,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.8,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'Developed by',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Image.asset(
                    'lib/assets/image/NovaCore.png',
                    width: 120,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
