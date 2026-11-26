
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'Colors.dart';

const Color authPrimaryColor = Color(0xFF174F50);
const Color authTextColor = Color(0xFF202B35);
const Color authBorderColor = Color(0xFF9AA5A8);
const Color authErrorColor = Color(0xFFE65B58);
const Color authHintColor = Color(0xFF92999F);


Widget authLabel(String title) {
  return Text(
    title,
    textAlign: TextAlign.right,
    style: const TextStyle(
      fontFamily: 'Inter',
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: authTextColor,
    ),
  );
}

// Input Decoration
InputDecoration authInputDecoration({
  required String hint,
  bool error = false,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(
      fontSize: 11,
      color: authHintColor,
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 14,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: const BorderSide(
        color: authBorderColor,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: BorderSide(
        color: error ? authErrorColor : authBorderColor,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: const BorderSide(
        color: authPrimaryColor,
        width: 1.2,
      ),
    ),
    suffixIcon: suffixIcon,
  );
}

// Text Field
Widget authField({
  required TextEditingController controller,
  required String hint,
  IconData? icon,
  TextInputType keyboardType = TextInputType.text,
  bool error = false,
}) {
  return SizedBox(
    width: 362,
    height: 64,
    child: TextField(
      controller: controller,
      keyboardType: keyboardType,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.right,
      decoration: authInputDecoration(
        hint: hint,
        error: error,
      ).copyWith(
        hintStyle: GoogleFonts.cairo(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: authHintColor,
        ),
        prefixIcon: Icon(
          icon ?? Icons.person_outline,
          size: 17,
          color: AppColors.TextSecondaryLight,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 20,
        ),
      ),
    ),
  );
}

// Primary Button
Widget authPrimaryButton({
  required String title,
  required VoidCallback onPressed,
}) {
  return SizedBox(
    height: 50,
    width: double.infinity,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: authPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ),
  );
}

// OR Divider
Widget authOrDivider() {
  return Row(
    children: [
      const Expanded(
        child: Divider(
          color: authBorderColor,
        ),
      ),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 15),
        child: Text(
          'or',
          style: TextStyle(
            fontSize: 11,
            color: authTextColor,
          ),
        ),
      ),
      const Expanded(
        child: Divider(
          color: authBorderColor,
        ),
      ),
    ],
  );
}

// Google Button
Widget authGoogleButton({VoidCallback? onPressed}) {
  return SizedBox(
    height: 45,
    width: double.infinity,
    child: OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: authTextColor,
        side: const BorderSide(
          color: authBorderColor,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          const Text(
            'سجل باستخدام جوجل',
            style: TextStyle(
              fontFamily: 'SemiBold',
              fontSize: 15,
              color: authTextColor,
              fontWeight: FontWeight.w600
            ),


          ),
  const SizedBox(width: 10,),
      Image.asset('assets/GoogleIcon.png'),
        ],
      ),
    ),
  );
}

