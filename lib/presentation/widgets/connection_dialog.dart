import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:notify/data/firebase/firebase_connect.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notify/data/local_storage/shared_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserConnectionModal extends ConsumerStatefulWidget {
  const UserConnectionModal({
    Key? key,
    required this.fetch,        
  }) : super(key: key);

  final VoidCallback fetch;      

  @override
  ConsumerState<UserConnectionModal> createState() =>
      _UserConnectionModalState();
}


class _UserConnectionModalState extends ConsumerState<UserConnectionModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _activeTab = 0;
  final TextEditingController _codeController = TextEditingController();
  // late String _generatedCode;
  bool _isSecureConnection = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _activeTab = _tabController.index;
        });
        if (_activeTab == 1 && _generatedCode == '--- ---') {
          _refreshCode();
        }
      }
    });

    if (_activeTab == 1) {
      _refreshCode();
    }

    // Start listening to connection status changes
    _startConnectionListener();
  }

  StreamSubscription? _connectionListener;

  void _startConnectionListener() {
    _connectionListener?.cancel(); 

    final codeToListen =
        _activeTab == 1
            ? _generatedCode
            : _codeController.text.replaceAll(RegExp(r'[^0-9]'), '');

    print('Starting connection listener for code: $codeToListen');

    if (codeToListen != '--- ---' && codeToListen.isNotEmpty) {
      _connectionListener = FirebaseConnect.listenToConnectionStatus(
        codeToListen,
      ).listen((isConnected) async {
        print('Connection status changed: $isConnected');
        if (isConnected && mounted) {
          // Cancel the listener immediately to prevent multiple triggers
          _connectionListener?.cancel();
          
          try {
            // Show success message and update state
            ref.read(setGeneratedCodeProvider(generatedCode: codeToListen));
            ref.read(setConnectedStatusProvider(status: true));
            
            final isMainUser = _activeTab == 1;
            
            if (isMainUser) {
              // Update timestamp only once for main user
              await FirebaseConnect.usersCollection.doc(codeToListen).update({
                "main_last_timestamp": Timestamp.now(),
              });
            }

            ref.read(
              setTypeUserProvider(
                typeUser: isMainUser ? 'main' : 'secondary',
              ),
            );
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Connection successful!'),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  margin: const EdgeInsets.all(16),
                ),
              );
              widget.fetch();
              Navigator.of(context).pop(); // Close the dialog
            }
          } catch (e, stackTrace) {
            print('Error in connection listener: $e');
            print('Stack trace: $stackTrace');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error updating connection: ${e.toString()}'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  margin: const EdgeInsets.all(16),
                ),
              );
            }
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _connectionListener?.cancel();
    _countdownTimer?.cancel();
    _tabController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mediaQuery = MediaQuery.of(context);
    final viewInsets = mediaQuery.viewInsets;
    final isKeyboardOpen = viewInsets.bottom > 0;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: isKeyboardOpen 
                ? mediaQuery.size.height - viewInsets.bottom - 100 // Give some breathing room
                : 740,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Connect with Partner',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.help_outline,
                            color: colorScheme.onSurface,
                          ),
                          onPressed: () => _showHelpDialog(context),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: colorScheme.onSurface),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Tab bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _activeTab = 0;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color:
                                _activeTab == 0
                                    ? colorScheme.surface
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow:
                                _activeTab == 0
                                    ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                    : [],
                          ),
                          child: Center(
                            child: Text(
                              'Enter Code',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color:
                                    _activeTab == 0
                                        ? colorScheme.primary
                                        : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _activeTab = 1;
                          });
                          // Generate new code when switching to Share Code tab
                          if (_generatedCode == '--- ---') {
                            _refreshCode();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color:
                                _activeTab == 1
                                    ? colorScheme.surface
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow:
                                _activeTab == 1
                                    ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                    : [],
                          ),
                          child: Center(
                            child: Text(
                              'Share Code',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color:
                                    _activeTab == 1
                                        ? colorScheme.primary
                                        : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Dynamic content
              Flexible(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: _activeTab == 0
                      ? _buildEnterCodeTab(colorScheme)
                      : _buildShareCodeTab(colorScheme),
                ),
              ),

              // Bottom actions
              Container(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 16,
                  bottom: 16,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed:
                            (_isLoading || _shareLoading)
                                ? null
                                : () {
                                  if (_activeTab == 0) {
                                    _connectWithPartner();
                                  } else {
                                    // Allow generating new code if expired or no code exists
                                    if (_timeLeft.isNegative ||
                                        _generatedCode == '--- ---') {
                                      _refreshCode();
                                    }
                                  }
                                },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _activeTab == 0
                                  ? colorScheme.primary
                                  : (_timeLeft.isNegative ||
                                          _generatedCode == '--- ---'
                                      ? colorScheme.primary
                                      : Colors.grey),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                          // Disable button only when loading or when code is active (not expired)
                          disabledBackgroundColor:
                              _activeTab == 1 &&
                                      !_timeLeft.isNegative &&
                                      _generatedCode != '--- ---'
                                  ? colorScheme.primary.withOpacity(0.6)
                                  : colorScheme.surfaceVariant,
                        ),
                        child:
                            _isLoading || _shareLoading
                                ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : Text(
                                  _activeTab == 0
                                      ? 'Connect'
                                      : (_timeLeft.isNegative ||
                                              _generatedCode == '--- ---'
                                          ? 'Generate New Code'
                                          : 'Code Active'),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Having trouble?',
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () {
                            _showTroubleshootingDialog(context);
                          },
                          child: Text(
                            'Get help',
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnterCodeTab(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter Partner Code',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ask your partner to share their connection code with you',
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // Code input field
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: TextField(
                controller: _codeController,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Enter 6-digit code',
                  hintStyle: TextStyle(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.paste, color: colorScheme.primary),
                    onPressed: () async {
                      final data = await Clipboard.getData(
                        Clipboard.kTextPlain,
                      );
                      if (data != null && data.text != null) {
                        final digits = data.text!.replaceAll(
                          RegExp(r'[^0-9]'),
                          '',
                        );
                        _codeController.text =
                            digits.length > 6 ? digits.substring(0, 6) : digits;
                      }
                    },
                  ),
                ),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                  letterSpacing: 1.2,
                ),
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                onChanged: (value) {
                  if (value.length == 6) {
                    _connectWithPartner();
                  }
                },
              ),
            ),

            const SizedBox(height: 24),

            // Instructions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: colorScheme.primary),
                      const SizedBox(width: 12),
                      Text(
                        'How to connect',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInstructionStep(
                    number: 1,
                    text: 'Ask your partner to go to the "Share Code" tab',
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 12),
                  _buildInstructionStep(
                    number: 2,
                    text: 'Have them share their unique code with you',
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 12),
                  _buildInstructionStep(
                    number: 3,
                    text: 'Enter their code above and tap "Connect"',
                    colorScheme: colorScheme,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionStep({
    required int number,
    required String text,
    required ColorScheme colorScheme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number.toString(),
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
          ),
        ),
      ],
    );
  }

  // state
  String _generatedCode = '--- ---';
  bool _shareLoading = false;
  DateTime? _expiresAt; // null = no active code
  Timer? _countdownTimer;
  Duration get _timeLeft =>
      _expiresAt == null
          ? Duration.zero
          : _expiresAt!.difference(DateTime.now());

  // call this from the UI
  Future<void> _refreshCode() async {
    if (_shareLoading) return;

    try {
      final myTokenId = ref.read(getMainTokenIdProvider);
      print('Current token ID for code generation: $myTokenId');

      if (myTokenId.isEmpty) {
        // Try to get the token from SharedPreferences directly
        final prefs = await SharedPreferences.getInstance();
        final storedToken = prefs.getString('mainTokenId');
        print('Stored token from SharedPreferences: $storedToken');

        if (storedToken != null && storedToken.isNotEmpty) {
          // Update the provider with the stored token
          ref.read(setMainTokenIdProvider(tokenId: storedToken));
          print('Updated provider with stored token');
          
          // Now try to generate the code with the stored token
          await _refreshShareCode();
        } else {
          // No token available, show error
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Unable to generate code. Please check your internet connection and try again.'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: const EdgeInsets.all(16),
              ),
            );
          }
        }
      } else {
        // Token exists in provider, proceed with code generation
        await _refreshShareCode();
      }
    } catch (e, stackTrace) {
      print('Error in _refreshCode: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate code: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> _refreshShareCode() async {
    final myTokenId = ref.read(getMainTokenIdProvider);
    print('Attempting to generate code with token: $myTokenId');
    
    if (myTokenId.isEmpty) {
      throw Exception('No token ID available - Firebase Messaging not initialized');
    }

    setState(() => _shareLoading = true);

    try {
      final newCode = await FirebaseConnect.createShareCode(
        mainTokenId: myTokenId,
      );
      print('Generated new code: $newCode');

      // start 10‑minute expiry
      _countdownTimer?.cancel();
      _expiresAt = DateTime.now().add(const Duration(minutes: 10));
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        if (_timeLeft.isNegative) {
          _countdownTimer?.cancel();
          setState(() {
            _generatedCode = '--- ---';
            _expiresAt = null;
            _shareLoading = false;
          });
        } else {
          setState(() {});
        }
      });

      setState(() {
        _generatedCode = newCode;
        _shareLoading = false;
      });

      // Start listening for connection status after generating the code
      _startConnectionListener();
    } catch (e, stackTrace) {
      print('Error generating code: $e');
      print('Stack trace: $stackTrace');
      if (!mounted) return;
      setState(() {
        _shareLoading = false;
      });
      rethrow;
    }
  }

  Widget _buildShareCodeTab(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Share Your Code',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Share this code with your partner to connect',
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),

            // Code display
            Center(
              child: Container(
                width: 280,
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Connection code
                    Text(
                      'Your Connection Code',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _generatedCode,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(
                              ClipboardData(text: _generatedCode),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Code copied to clipboard'),
                                duration: const Duration(seconds: 2),
                                backgroundColor: colorScheme.primary,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                margin: const EdgeInsets.all(16),
                              ),
                            );
                          },
                          child: Icon(
                            Icons.copy,
                            size: 20,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Share options
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.center,
                    //   children: [
                    //     _buildShareOption(Icons.message, 'SMS', colorScheme),
                    //     const SizedBox(width: 16),
                    //     _buildShareOption(Icons.email, 'Email', colorScheme),
                    //     const SizedBox(width: 16),
                    //     _buildShareOption(Icons.more_horiz, 'More', colorScheme),
                    //   ],
                    // ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Security options
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.security, color: colorScheme.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Secure Connection',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Add additional verification',
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isSecureConnection,
                    activeColor: colorScheme.primary,
                    onChanged: (value) {
                      setState(() {
                        _isSecureConnection = value;
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Expiration notice
            if (_expiresAt != null)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color:
                      _timeLeft.isNegative
                          ? colorScheme.errorContainer
                          : colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _timeLeft.isNegative ? Icons.error_outline : Icons.timer,
                      size: 20,
                      color:
                          _timeLeft.isNegative
                              ? colorScheme.error
                              : colorScheme.secondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _timeLeft.isNegative
                          ? 'Code Expired - Generate New Code'
                          : 'Code expires in ${_timeLeft.inMinutes.remainder(60).toString().padLeft(2, '0')}:'
                              '${_timeLeft.inSeconds.remainder(60).toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color:
                            _timeLeft.isNegative
                                ? colorScheme.error
                                : colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _connectWithPartner() async {
    final code = _codeController.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a connection code'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    final myTokenId = ref.read(getMainTokenIdProvider);

    try {
      final isOwnCode = await FirebaseConnect.isOwnCode(code, myTokenId);
      if (isOwnCode) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Cannot connect to your own code. Ask your partner to share their code instead.',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        _codeController.clear();
        return;
      }

      setState(() {
        _isLoading = true;
      });

      // Call the function to update secondary presence only if offline
      final updated = await FirebaseConnect.updateSecondaryPresenceIfOffline(
        partnerCode: code,
        tokenId: myTokenId,
      );

      if (!mounted) return;

      if (updated) {
        // Start listening for connection status after updating presence
        _startConnectionListener();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Presence was already online or update failed.',
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connection failed: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _showHelpDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'How to Connect',
              style: TextStyle(color: colorScheme.primary),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHelpStep(
                  1,
                  'One user generates a code in the "Share Code" tab',
                  colorScheme,
                ),
                const SizedBox(height: 12),
                _buildHelpStep(
                  2,
                  'Share this code with your partner via any method',
                  colorScheme,
                ),
                const SizedBox(height: 12),
                _buildHelpStep(
                  3,
                  'Your partner enters this code in their "Enter Code" tab',
                  colorScheme,
                ),
                const SizedBox(height: 12),
                _buildHelpStep(
                  4,
                  'Once connected, you can start sharing messages!',
                  colorScheme,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Got it',
                  style: TextStyle(color: colorScheme.primary),
                ),
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
    );
  }

  Widget _buildHelpStep(int number, String text, ColorScheme colorScheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number.toString(),
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
          ),
        ),
      ],
    );
  }

  void _showTroubleshootingDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Troubleshooting',
              style: TextStyle(color: colorScheme.primary),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTroubleshootingItem(
                  'Make sure both users have an active internet connection',
                  colorScheme,
                ),
                const SizedBox(height: 12),
                _buildTroubleshootingItem(
                  'Verify you\'re entering the exact code including dashes',
                  colorScheme,
                ),
                const SizedBox(height: 12),
                _buildTroubleshootingItem(
                  'Try generating a new code if the current one doesn\'t work',
                  colorScheme,
                ),
                const SizedBox(height: 12),
                _buildTroubleshootingItem(
                  'Check that the code hasn\'t expired (10-minute limit)',
                  colorScheme,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Close',
                  style: TextStyle(color: colorScheme.primary),
                ),
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
    );
  }

  Widget _buildTroubleshootingItem(String text, ColorScheme colorScheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.check_circle, color: colorScheme.primary, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildShareOption(
    IconData icon,
    String label,
    ColorScheme colorScheme,
  ) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(icon, color: colorScheme.primary),
            onPressed: () {
              // Handle share action
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
