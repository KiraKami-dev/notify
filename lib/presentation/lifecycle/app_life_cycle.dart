import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notify/data/local_storage/shared_auth.dart';

class AppLifecycleHandler extends ConsumerStatefulWidget {
  const AppLifecycleHandler({required this.child, Key? key}) : super(key: key);
  final Widget child;

  @override
  ConsumerState<AppLifecycleHandler> createState() =>
      _AppLifecycleHandlerState();
}

class _AppLifecycleHandlerState extends ConsumerState<AppLifecycleHandler>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // mark online at launch
    _writePresence(online: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:          
        _writePresence(online: true);
        break;

      case AppLifecycleState.inactive:         
      case AppLifecycleState.paused:           
      case AppLifecycleState.detached:         
      case AppLifecycleState.hidden:           
        _writePresence(online: false);
        break;
    }
  }

  

  void _writePresence({required bool online}) {
    final code     = ref.read(getGeneratedCodeProvider); 
    final typeUser = ref.read(getTypeUserProvider);      
    if (code.isEmpty || typeUser.isEmpty) return;

    final fieldPrefix = typeUser == 'main' ? 'main' : 'secondary';
    FirebaseFirestore.instance
        .collection('users')
        .doc(code)
        .update({
          '${fieldPrefix}_online_status'  : online,
          '${fieldPrefix}_last_timestamp' : DateTime.now().toIso8601String(),
        })
        .catchError((_) {/* ignore if doc missing */});
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
