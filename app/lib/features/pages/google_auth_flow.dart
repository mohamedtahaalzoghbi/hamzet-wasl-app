import 'package:flutter/material.dart';

import '../../core/api/api_exception.dart';
import '../../core/api/auth_api.dart';
import '../../core/api/auth_models.dart';
import '../../core/auth/token_store.dart';
import '../../core/usersection.dart';
import '../../widgets/volunteerwidgets.dart';
import 'Otp_screen.dart';
import 'home_screen.dart';

/// تحويل دور الباك لنوع الحساب في الشاشات.
AccountKind? accountKindFromRole(String role) {
  switch (role) {
    case 'volunteer':
      return AccountKind.volunteer;
    case 'company':
      return AccountKind.company;
    case 'association':
      return AccountKind.organization;
    case 'disabled_user':
      return AccountKind.interested;
  }
  return null;
}

/// اسم نوع الحساب بالعربي.
String accountRoleLabel(String role) {
  switch (role) {
    case 'volunteer':
      return 'متطوع';
    case 'company':
      return 'شركة';
    case 'association':
      return 'جمعية / مؤسسة';
    case 'disabled_user':
      return 'فرد مهتم';
  }
  return role;
}

void _showGoogleError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: vText(size: 13, color: Colors.white)),
    ),
  );
}

/// الخطوة المشتركة بعد ما يوصلنا ID token من جوجل:
/// يا دخول مباشر (حساب موجود)، يا إكمال بيانات (نوع حساب + موبايل) ثم OTP.
Future<void> handleGoogleIdToken(
  BuildContext context,
  String idToken, {
  String? preselectedRole,
}) async {
  final authApi = AuthApi.instance;

  GoogleAuthResult result;
  try {
    result = await authApi.googleAuth(idToken: idToken);
  } on ApiException catch (e) {
    if (context.mounted) _showGoogleError(context, e.message);
    return;
  } catch (_) {
    if (context.mounted) {
      _showGoogleError(context, 'مشكلة في الاتصال بالسيرفر. حاول تاني.');
    }
    return;
  }

  final auth = result.auth;
  if (auth != null) {
    await TokenStore.instance.save(auth);
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (_) => false,
    );
    return;
  }

  final required = result.registrationRequired;
  if (required != null) {
    if (!context.mounted) return;
    final draft = await showVSheet<GoogleRegistrationDraft>(
      context,
      builder: (_) => GoogleRegistrationSheet(
        email: required.email,
        roles: required.availableRoles,
        preselectedRole: preselectedRole,
      ),
    );
    if (draft == null || !context.mounted) return;

    GoogleAuthResult second;
    try {
      second = await authApi.googleAuth(
        idToken: idToken,
        role: draft.role,
        phone: draft.phone,
        termsAccepted: true,
        registrationTicket: required.registrationTicket,
      );
    } on ApiException catch (e) {
      if (context.mounted) {
        _showGoogleError(
          context,
          e.fieldError('phone') ?? e.fieldError('role') ?? e.message,
        );
      }
      return;
    } catch (_) {
      if (context.mounted) {
        _showGoogleError(context, 'مشكلة في الاتصال بالسيرفر. حاول تاني.');
      }
      return;
    }

    final secondAuth = second.auth;
    if (secondAuth != null) {
      await TokenStore.instance.save(secondAuth);
      if (!context.mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
      return;
    }

    final pending = second.phoneVerificationRequired;
    if (pending != null) {
      UserSession.accountKind = accountKindFromRole(draft.role);
      UserSession.email = required.email;
      UserSession.phone = draft.phone;
      UserSession.registrationTicket = pending.registrationTicket;
      UserSession.registrationTicketExpiresAt = pending.expiresAt;
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpScreen(
            isPhone: true,
            target: pending.phone ?? draft.phone,
            verifyCode: (code) async {
              try {
                final done = await authApi.completeRegistration(
                  registrationTicket: pending.registrationTicket,
                  code: code,
                );
                await TokenStore.instance.save(done);
                return null;
              } on ApiException catch (e) {
                return e.message;
              }
            },
            resendCode: () async {
              try {
                await authApi.resendRegistrationCode(
                  pending.registrationTicket,
                );
                return null;
              } on ApiException catch (e) {
                return e.message;
              }
            },
          ),
        ),
      );
      return;
    }
  }

  if (context.mounted) {
    _showGoogleError(context, 'رد غير متوقع من السيرفر. حاول تاني.');
  }
}

/// بيانات إكمال التسجيل بحساب جوجل (نوع الحساب + رقم الموبايل).
class GoogleRegistrationDraft {
  GoogleRegistrationDraft({required this.role, required this.phone});

  final String role;
  final String phone;
}

/// شيت إكمال بيانات التسجيل لأول مرة بحساب جوجل.
class GoogleRegistrationSheet extends StatefulWidget {
  const GoogleRegistrationSheet({
    super.key,
    required this.email,
    required this.roles,
    this.preselectedRole,
  });

  final String email;
  final List<String> roles;
  final String? preselectedRole;

  @override
  State<GoogleRegistrationSheet> createState() =>
      _GoogleRegistrationSheetState();
}

class _GoogleRegistrationSheetState extends State<GoogleRegistrationSheet> {
  final _phoneCtrl = TextEditingController();
  String? _role;
  bool _agreeTerms = false;
  bool _showErrors = false;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedRole != null &&
        widget.roles.contains(widget.preselectedRole)) {
      _role = widget.preselectedRole;
    }
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _showErrors = true);
    final phone = _phoneCtrl.text.trim();
    if (_role == null || phone.isEmpty || !_agreeTerms) return;
    Navigator.pop(context, GoogleRegistrationDraft(role: _role!, phone: phone));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const VSheetHandle(),
            const VSheetTitle(title: 'إكمال التسجيل بحساب جوجل'),
            Text(
              'هيكمل التسجيل بالإيميل: ${widget.email}',
              style: vText(size: 12, color: const Color(0xFF8A8A8A)),
            ),
            const SizedBox(height: 16),

            Text('نوع الحساب', style: vText(size: 18, weight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final role in widget.roles)
                  ChoiceChip(
                    label: Text(
                      accountRoleLabel(role),
                      style: vText(
                        size: 13,
                        weight: _role == role
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    selected: _role == role,
                    onSelected: (_) => setState(() => _role = role),
                  ),
              ],
            ),
            if (_showErrors && _role == null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'اختار نوع الحساب',
                  style: vText(size: 10, color: const Color(0xFFD32F2F)),
                ),
              ),

            const SizedBox(height: 16),

            VField(
              label: 'رقم التليفون',
              hint: '01xxxxxxxxx',
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              error: _showErrors && _phoneCtrl.text.trim().isEmpty,
              errorText: 'ادخل رقم الموبايل',
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Checkbox(
                  value: _agreeTerms,
                  onChanged: (v) => setState(() => _agreeTerms = v ?? false),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _agreeTerms = !_agreeTerms),
                    child: Text(
                      'أوافق على الشروط والأحكام',
                      style: vText(size: 13),
                    ),
                  ),
                ),
              ],
            ),
            if (_showErrors && !_agreeTerms)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'لازم توافق على الشروط والأحكام',
                  style: vText(size: 10, color: const Color(0xFFD32F2F)),
                ),
              ),

            const SizedBox(height: 16),

            VButton(title: 'متابعة', onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
