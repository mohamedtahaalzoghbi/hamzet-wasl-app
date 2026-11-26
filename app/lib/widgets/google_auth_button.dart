import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/auth/google_auth_service.dart';
import 'auth_widgets.dart';
import 'google_web_button.dart';
import 'volunteerwidgets.dart';

/// زرار الدخول بجوجل:
/// - موبايل: زرارنا المخصص وبننده authenticate().
/// - ويب: جوجل بترسم الزرار بنفسها (GIS)، والنتيجة بتوصل من stream.
class GoogleAuthButton extends StatefulWidget {
  const GoogleAuthButton({super.key, required this.onIdToken});

  /// بتتنادى بعد تسجيل دخول ناجح مع الـ ID token الجاهز يتبعت للباك.
  final Future<void> Function(String idToken) onIdToken;

  @override
  State<GoogleAuthButton> createState() => _GoogleAuthButtonState();
}

class _GoogleAuthButtonState extends State<GoogleAuthButton> {
  final _google = GoogleAuthService.instance;
  StreamSubscription<GoogleSignInAccount?>? _sub;
  bool _ready = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await _google.ensureInitialized();
    } catch (_) {
      // التهيئة فشلت؛ هنظهر رسالة عند الضغط.
    }
    _sub = _google.signInEvents.listen((account) {
      final token = account?.authentication.idToken;
      if (account != null && token != null && token.isNotEmpty) {
        widget.onIdToken(token);
      }
    });
    if (mounted) setState(() => _ready = true);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _tap() async {
    if (_busy) return;
    if (!_google.isConfigured) {
      _showMessage('دخول جوجل مش متظبط لسه. جرب تسجل بالإيميل.');
      return;
    }
    setState(() => _busy = true);
    try {
      final idToken = await _google.signInAndGetIdToken();
      await widget.onIdToken(idToken);
    } on GoogleSignInException catch (e) {
      if (e.code != GoogleSignInExceptionCode.canceled) {
        _showMessage('مقدرناش نسجل بجوجل. حاول تاني.');
      }
    } catch (_) {
      _showMessage('مقدرناش نسجل بجوجل. حاول تاني.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: vText(size: 13, color: Colors.white)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // على الويب جوجل لازم ترسم الزرار بنفسها بعد التهيئة.
    if (_ready && _google.isConfigured && !_google.supportsCustomButton) {
      return Center(child: buildGoogleWebButton());
    }
    return Stack(
      alignment: Alignment.center,
      children: [
        Opacity(
          opacity: _busy ? 0.6 : 1,
          child: authGoogleButton(onPressed: _busy ? null : _tap),
        ),
        if (_busy)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
      ],
    );
  }
}
