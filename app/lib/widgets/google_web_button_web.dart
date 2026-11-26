import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart' as gsi_web;

/// زرار "Sign in with Google" الرسمي اللي جوجل بترسمه على الويب.
/// لازم يتعرض بعد ما GoogleAuthService.ensureInitialized() تخلص.
Widget buildGoogleWebButton() => gsi_web.renderButton();
