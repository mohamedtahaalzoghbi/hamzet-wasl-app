import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'Colors.dart';
import 'auth_widgets.dart';


TextStyle vText({
  double size = 17,
  FontWeight weight = FontWeight.w500,
  Color color = AppColors.PremaryText,
  double? height,

}) {
  return GoogleFonts.inter(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
  );
}

// ───────────────────────── Scaffold ─────────────────────────

class VolunteerScaffold extends StatelessWidget {
  const VolunteerScaffold({
    super.key,
    this.title,
    required this.body,
    this.bottom,
    this.scrollable = true,
  });

  final String? title;
  final Widget body;
  final Widget? bottom;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: body,
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              if (title != null) _VHeader(title: title!),
              Expanded(
                child: scrollable
                    ? SingleChildScrollView(child: content)
                    : content,
              ),
              if (bottom != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: bottom,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VHeader extends StatelessWidget {
  final String title;

  const _VHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 15.0),
      child: Container(
        width: 371,
        height: 44,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(
              color: Color(0xFFEAEAEA),
              width: 0.7,
            ),
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.TextPremaryLight,
                ),
              ),
            ),

            Positioned(
              left: 8,
              top: 5,
              child: InkWell(
                onTap: () => Navigator.maybePop(context),
                child: SizedBox(
                  width: 36,
                  height: 44,
                  child: Center(
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      textDirection: TextDirection.ltr,
                      size: 18,
                      color: AppColors.IconColor_back,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── Button ─────────────────────────

class VButton extends StatelessWidget {
  const VButton({
    super.key,
    required this.title,
    required this.onPressed,
    this.color,
    this.icon,
  });

  final String title;
  final VoidCallback? onPressed;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? AppColors.primary_button,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.disabledButton,
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              title,
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── Text field ─────────────────────────

class VField extends StatelessWidget {
  const VField({
    super.key,
    required this.label,
    required this.hint,
    this.controller,
    this.maxLines = 1,
    this.icon,
    this.suffix,
    this.keyboardType,
    this.error = false,
    this.errorText,
    this.ltr = false,
    this.readOnly = false,
    this.enabled = true,
    this.onTap,
    this.onChanged,
  });

  final String label;
  final String hint;
  final TextEditingController? controller;
  final int maxLines;
  final IconData? icon;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final bool error;
  final String? errorText;
  final bool ltr;
  final bool readOnly;
  final bool enabled;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: vText(size: 18, weight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          readOnly: readOnly,
          enabled: enabled,
          onTap: onTap,
          onChanged: onChanged,
          style: vText(size: 13),

          decoration: authInputDecoration(hint: hint, error: error).copyWith(
            hintStyle: vText(size: 12, color: authHintColor),
            suffixIcon: icon == null
                ? null
                : Icon(icon, size: 18, color: AppColors.TextSecondaryLight),

            filled: !enabled,
            fillColor: AppColors.surfaceBeige,
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 16,
            ),
          ),
        ),
        if (error && errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              errorText!,
              style: vText(size: 10, color: AppColors.errorColor),
            ),
          ),
      ],
    );
  }
}

// ───────────────────────── Steps bar ─────────────────────────

class VStepsBar extends StatelessWidget {
  const VStepsBar({super.key, required this.current, required this.total});
  final int current;
  final int total;

  Widget _dot(int i) {
    final done = i < current;
    final active = i == current;
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: (done || active) ? AppColors.primary_button : AppColors.uploadFill,
      ),
      child: done
          ? const Icon(Icons.check, size: 16, color: Colors.white)
          : Text(
        '$i',
        style: vText(
          size: 12,
          weight: FontWeight.w600,
          color: active ? Colors.white : AppColors.TextSecondaryDart,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 1; i <= total; i++) ...[
          _dot(i),
          if (i < total)
            Expanded(
              child: Container(
                height: 2,
                color: i < current ? AppColors.primary_button : AppColors.border,
              ),
            ),
        ],
      ],
    );
  }
}

// ───────────────────────── Illustration ─────────────────────────

/// بيعرض صورة من الـ assets، ولو الصورة لسه مش موجودة بيعرض أيقونة بدالها.
class AssetOrIcon extends StatelessWidget {
  const AssetOrIcon({
    super.key,
    required this.asset,
    required this.fallback,
    this.size = 190,
  });

  final String asset;
  final IconData fallback;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: AppColors.softGreen,
          shape: BoxShape.circle,
        ),
        child: Icon(fallback, size: size * 0.45, color: AppColors.primary_button),
      ),
    );
  }
}

// ───────────────────────── Dashed border ─────────────────────────

class DashedBorder extends StatelessWidget {
  const DashedBorder({
    super.key,
    required this.child,
    this.color = AppColors.terracotta,
    this.radius = 12,
    this.circle = false,
  });

  final Widget child;
  final Color color;
  final double radius;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedPainter(color: color, radius: radius, circle: circle),
      child: child,
    );
  }
}

class _DashedPainter extends CustomPainter {
  _DashedPainter({
    required this.color,
    required this.radius,
    required this.circle,
  });

  final Color color;
  final double radius;
  final bool circle;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final rect = Offset.zero & size;
    final path = Path();
    if (circle) {
      path.addOval(rect);
    } else {
      path.addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    }

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 5), paint);
        distance += 9;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedPainter old) =>
      old.color != color || old.radius != radius || old.circle != circle;
}

// ───────────────────────── Bottom sheets ─────────────────────────

Future<T?> showVSheet<T>(
    BuildContext context, {
      required WidgetBuilder builder,
    }) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: builder(ctx),
    ),
  );
}

class VSheetHandle extends StatelessWidget {
  const VSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(top: 10, bottom: 6),
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

class VCloseButton extends StatelessWidget {
  const VCloseButton({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pop(context),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.close, size: 16, color: AppColors.PremaryText),
      ),
    );
  }
}

class VSheetTitle extends StatelessWidget {
  const VSheetTitle({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: SizedBox(
        height: 36,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(title, style: vText(size: 16, weight: FontWeight.w700)),
            const Align(
              alignment: Alignment.centerLeft,
              child: VCloseButton(),
            ),
          ],
        ),
      ),
    );
  }
}

