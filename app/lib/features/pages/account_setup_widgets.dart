import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/Colors.dart';

class AccountSetupHeader extends StatelessWidget {
  const AccountSetupHeader({
    super.key,
    this.title,
    this.showBack = false,
    this.onSkip,
  });

  final String? title;
  final bool showBack;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              child: showBack
                  ? IconButton(
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(
                        Icons.arrow_back,
                        size: 22,
                        color: AppColors.IconColor_back,
                      ),
                    )
                  : null,
            ),
            Expanded(
              child: title == null
                  ? const SizedBox.shrink()
                  : Text(
                      title!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.PremaryText,
                      ),
                    ),
            ),
            TextButton(
              onPressed: onSkip,
              child: Text(
                'تخطى',
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.PremaryText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SetupContinueButton extends StatelessWidget {
  const SetupContinueButton({
    super.key,
    required this.title,
    required this.onPressed,
  });

  final String title;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary_button,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          title,
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

