
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:graduation_project/widgets/Colors.dart';

import '../../core/usersection.dart';
import 'complete_profile_screen.dart';
import 'home_screen.dart';
import 'organization_setup_screen.dart';

class AccountSuccessScreen extends StatelessWidget {
  const AccountSuccessScreen({super.key});



  static const Color borderGreen = Color(0xFFD8E9E2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [

            // Decorative shapes
            Positioned(

              top: 70,
              left: 50,
              child: Transform.rotate(
                angle: 90,
                child: Container(
                  width: 48,
                  height: 13,
                  decoration: BoxDecoration(
                    color: Color(0xFFFBF0DC),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),

            Positioned(
              top: 137,
              right: 41,
              child: Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  color: Color(0xFFE5EFED),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            Positioned(
              top: 271,
              left: 46.8,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Color(0xFFB6734A),

                    width: 6.4,
                  ),
                ),
              ),
            ),

            Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row
                    (
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                          (_) => false,
                        ),
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          size: 17,
                          color:AppColors.IconColor_back,
                        ),
                      ),

                      TextButton(
                        onPressed: () => Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                          (_) => false,
                        ),
                        child: Text(
                          'تخطي',
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color:AppColors.IconColor_back,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 70),

                // Success icon
                Container(
                  width: 123,
                  height: 123,
                  decoration: BoxDecoration(
                    color: Color(0xFFE7F2ED),
                    borderRadius: BorderRadius.circular(52.8),
                    border: Border.all(
                      color: borderGreen,
                      width: 8,
                    ),
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 39,
                    color: Color(0xFF43856C),
                  ),
                ),

                const SizedBox(height: 45),

                // Title
                Text(
                  'حسابك اتعمل',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 27,
                    fontWeight: FontWeight.w600,
                    color: AppColors.PremaryText,
                  ),
                ),

                const SizedBox(height: 8),

                // Description
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'فاضل خطوات بسيطة عشان نخصص التجربة المناسبة ليك.',
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.PremaryText,
                    ),
                  ),
                ),

                const SizedBox(height: 27),

                // Continue button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 9),
                  child: SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                (UserSession.accountKind == AccountKind.company ||
                                        UserSession.accountKind == AccountKind.organization)
                                    ? const OrganizationSetupScreen()
                                    : const CompleteProfileScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:AppColors.primary_button,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'كمل إعداد الحساب',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

