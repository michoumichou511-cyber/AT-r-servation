import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../utils/status_utils.dart';

// ═══════════════════════════════════════════════════════════════
// DESIGN SYSTEM — AT Réservations
// ═══════════════════════════════════════════════════════════════

class DS {
  DS._();

  // ── Couleurs ──────────────────────────────────────────────────
  static const primary        = Color(0xFF00A650);
  static const secondary      = Color(0xFF003DA5);
  static const primaryDark    = Color(0xFF007A3D);
  static const secondaryDark  = Color(0xFF002B7A);
  static const background     = Color(0xFFF8FAFC);
  static const surface        = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF1F5F9);
  static const border         = Color(0xFFE2E8F0);
  static const textPrimary    = Color(0xFF0F172A);
  static const textSecondary  = Color(0xFF334155);
  static const textMuted      = Color(0xFF64748B);
  static const textPlaceholder= Color(0xFF94A3B8);
  static const error          = Color(0xFFEF4444);
  static const warning        = Color(0xFFF59E0B);
  static const success        = Color(0xFF10B981);
  static const info           = Color(0xFF3B82F6);

  // ── Gradients ─────────────────────────────────────────────────
  static const gradientPrimary = LinearGradient(
    colors: [secondary, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gradientBlue = LinearGradient(
    colors: [secondary, Color(0xFF0052CC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gradientDeepBlue = LinearGradient(
    colors: [secondary, secondaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gradientGreen = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gradientLogin = LinearGradient(
    colors: [secondary, Color(0xFF001F6B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Ombres ────────────────────────────────────────────────────
  static const shadowSm = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))
  ];
  static const shadowMd = [
    BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 4))
  ];
  static const shadowLg = [
    BoxShadow(color: Color(0x1F000000), blurRadius: 24, offset: Offset(0, 8))
  ];
  static const shadowGreen = [
    BoxShadow(color: Color(0x66009A4A), blurRadius: 20, offset: Offset(0, 8))
  ];
  static const shadowBlue = [
    BoxShadow(color: Color(0x55003DA5), blurRadius: 20, offset: Offset(0, 8))
  ];

  // ── Rayons ────────────────────────────────────────────────────
  static BorderRadius radiusSm  = BorderRadius.circular(8);
  static BorderRadius radiusMd  = BorderRadius.circular(16);
  static BorderRadius radiusLg  = BorderRadius.circular(24);
  static BorderRadius radiusXl  = BorderRadius.circular(32);
  static BorderRadius radiusXxl = BorderRadius.circular(40);

  // ── Typographie ───────────────────────────────────────────────
  static TextStyle h1 = GoogleFonts.inter(
    fontSize: 28, fontWeight: FontWeight.w800, color: textPrimary,
    letterSpacing: -0.5,
  );
  static TextStyle h2 = GoogleFonts.inter(
    fontSize: 22, fontWeight: FontWeight.w700, color: textPrimary,
    letterSpacing: -0.3,
  );
  static TextStyle h3 = GoogleFonts.inter(
    fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary,
  );
  static TextStyle h4 = GoogleFonts.inter(
    fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary,
  );
  static TextStyle body = GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.w400, color: textSecondary,
  );
  static TextStyle bodyMd = GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.w500, color: textSecondary,
  );
  static TextStyle caption = GoogleFonts.inter(
    fontSize: 12, fontWeight: FontWeight.w400, color: textMuted,
  );
  static TextStyle label = GoogleFonts.inter(
    fontSize: 11, fontWeight: FontWeight.w600, color: textPlaceholder,
    letterSpacing: 0.8,
  );
  static TextStyle numBig = GoogleFonts.inter(
    fontSize: 32, fontWeight: FontWeight.w800, color: textPrimary,
    letterSpacing: -1,
  );

  // ── Couleur par rôle ─────────────────────────────────────────
  static Color colorForRole(String role) {
    switch (role) {
      case 'admin':      return const Color(0xFF7C3AED);
      case 'directeur':  return secondary;
      case 'assistante': return const Color(0xFF0891B2);
      case 'agent_dml':  return warning;
      default:           return primary;
    }
  }

  // ── Couleur par statut — délègue à status_utils.dart ─────────
  static Color colorForStatut(String statut) => statusColor(statut);

  // ── Label statut — délègue à status_utils.dart ───────────────
  static String labelForStatut(String s) => statusLabel(s);
}

// ═══════════════════════════════════════════════════════════════
// WIDGETS RÉUTILISABLES
// ═══════════════════════════════════════════════════════════════

// ── ATButton ──────────────────────────────────────────────────
enum ATButtonVariant { primary, secondary, danger, outline }

class ATButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final ATButtonVariant variant;
  final IconData? icon;
  final bool loading;
  final double height;
  final double? width;

  const ATButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = ATButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.height = 52,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final isOutline = variant == ATButtonVariant.outline;
    final gradient = variant == ATButtonVariant.danger
        ? const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)])
        : variant == ATButtonVariant.secondary
            ? DS.gradientBlue
            : DS.gradientGreen;

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: isOutline
          ? OutlinedButton.icon(
              onPressed: loading ? null : onPressed,
              icon: icon != null ? Icon(icon, size: 18) : const SizedBox.shrink(),
              label: Text(label, style: GoogleFonts.inter(
                fontWeight: FontWeight.w600, fontSize: 14, color: DS.secondary)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: DS.secondary, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: DS.radiusMd),
              ),
            )
          : DecoratedBox(
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: DS.radiusMd,
                boxShadow: variant == ATButtonVariant.danger
                    ? const [BoxShadow(color: Color(0x55EF4444), blurRadius: 12, offset: Offset(0, 4))]
                    : DS.shadowGreen,
              ),
              child: ElevatedButton(
                onPressed: loading ? null : onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: DS.radiusMd),
                ),
                child: loading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (icon != null) ...[
                            Icon(icon, size: 18, color: Colors.white),
                            const SizedBox(width: 8),
                          ],
                          Text(label, style: GoogleFonts.inter(
                            fontSize: 15, fontWeight: FontWeight.w700,
                            color: Colors.white)),
                        ],
                      ),
              ),
            ),
    );
  }
}

// ── ATCard ────────────────────────────────────────────────────
class ATCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final List<BoxShadow>? shadow;
  final BorderRadius? radius;
  final Color? color;
  final Border? border;

  const ATCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.shadow,
    this.radius,
    this.color,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? DS.surface,
        borderRadius: radius ?? DS.radiusMd,
        boxShadow: shadow ?? DS.shadowSm,
        border: border,
      ),
      child: ClipRRect(
        borderRadius: radius ?? DS.radiusMd,
        child: onTap != null
            ? InkWell(
                onTap: onTap,
                borderRadius: radius ?? DS.radiusMd,
                child: Padding(
                  padding: padding ?? const EdgeInsets.all(16),
                  child: child,
                ),
              )
            : Padding(
                padding: padding ?? const EdgeInsets.all(16),
                child: child,
              ),
      ),
    );
  }
}

// ── ATTextField ───────────────────────────────────────────────
class ATTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool obscure;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSubmitted;
  final bool readOnly;
  final VoidCallback? onTap;
  final int? maxLines;
  final String? hint;

  const ATTextField({
    super.key,
    this.controller,
    required this.label,
    this.prefixIcon,
    this.suffix,
    this.obscure = false,
    this.keyboardType,
    this.validator,
    this.onSubmitted,
    this.readOnly = false,
    this.onTap,
    this.maxLines = 1,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      onFieldSubmitted: onSubmitted,
      readOnly: readOnly,
      onTap: onTap,
      maxLines: maxLines,
      style: DS.body.copyWith(color: DS.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: DS.caption.copyWith(color: DS.textMuted),
        hintStyle: DS.caption.copyWith(color: DS.textPlaceholder),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: DS.textMuted, size: 20)
            : null,
        suffixIcon: suffix,
        filled: true,
        fillColor: DS.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: DS.radiusMd,
          borderSide: const BorderSide(color: DS.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: DS.radiusMd,
          borderSide: const BorderSide(color: DS.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: DS.radiusMd,
          borderSide: const BorderSide(color: DS.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: DS.radiusMd,
          borderSide: const BorderSide(color: DS.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

// ── ATBadge ───────────────────────────────────────────────────
class ATBadge extends StatelessWidget {
  final String label;
  final Color? color;
  final bool small;

  const ATBadge({super.key, required this.label, this.color, this.small = false});

  @override
  Widget build(BuildContext context) {
    final c = color ?? DS.primary;
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: small ? 8 : 10, vertical: small ? 3 : 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: small ? 10 : 11,
          fontWeight: FontWeight.w600,
          color: c,
        ),
      ),
    );
  }
}

// ── ATStatutBadge ────────────────────────────────────────────
class ATStatutBadge extends StatelessWidget {
  final String statut;
  const ATStatutBadge({super.key, required this.statut});

  @override
  Widget build(BuildContext context) {
    return ATBadge(
      label: DS.labelForStatut(statut),
      color: DS.colorForStatut(statut),
      small: true,
    );
  }
}

// ── ATAvatar ──────────────────────────────────────────────────
class ATAvatar extends StatelessWidget {
  final String initials;
  final String? role;
  final double size;
  final bool withRing;

  const ATAvatar({
    super.key,
    required this.initials,
    this.role,
    this.size = 44,
    this.withRing = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = role != null ? DS.colorForRole(role!) : DS.secondary;
    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Center(
        child: Text(
          initials.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: size * 0.35,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );

    if (!withRing) return avatar;

    return Container(
      width: size + 6,
      height: size + 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: DS.primary, width: 3),
      ),
      padding: const EdgeInsets.all(2),
      child: avatar,
    );
  }
}

// ── ATSectionTitle ────────────────────────────────────────────
class ATSectionTitle extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const ATSectionTitle({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        children: [
          Text(title, style: DS.h4),
          const Spacer(),
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionLabel!,
                style: DS.caption.copyWith(
                  color: DS.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── ATEmptyState ─────────────────────────────────────────────
class ATEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? buttonLabel;
  final VoidCallback? onButton;

  const ATEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.buttonLabel,
    this.onButton,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: DS.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: DS.primary, size: 36),
            ),
            const SizedBox(height: 20),
            Text(title, style: DS.h3, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(description, style: DS.body, textAlign: TextAlign.center),
            if (buttonLabel != null) ...[
              const SizedBox(height: 24),
              ATButton(
                label: buttonLabel!,
                onPressed: onButton,
                width: 180,
                height: 44,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── ATShimmerCard ─────────────────────────────────────────────
class ATShimmerCard extends StatelessWidget {
  final double height;
  const ATShimmerCard({super.key, this.height = 90});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE2E8F0),
      highlightColor: const Color(0xFFF8FAFC),
      child: Container(
        height: height,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: DS.radiusMd,
        ),
      ),
    );
  }
}

// ── ATGradientHeader ──────────────────────────────────────────
class ATGradientHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final LinearGradient? gradient;
  final double height;

  const ATGradientHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.gradient,
    this.height = 100,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        gradient: gradient ?? DS.gradientDeepBlue,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: DS.shadowBlue,
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: DS.h2.copyWith(color: Colors.white),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: DS.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

// ── ATStatCard ────────────────────────────────────────────────
class ATStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const ATStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ATCard(
      padding: const EdgeInsets.all(14),
      shadow: DS.shadowMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: DS.radiusSm,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const Spacer(),
          Text(value, style: DS.h2.copyWith(color: color)),
          const SizedBox(height: 2),
          Text(label, style: DS.caption),
        ],
      ),
    );
  }
}

// ── ATDivider ─────────────────────────────────────────────────
class ATDivider extends StatelessWidget {
  const ATDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Divider(color: Color(0xFFF1F5F9), thickness: 1, height: 1);
  }
}

// ── ATInfoRow ─────────────────────────────────────────────────
class ATInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;

  const ATInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor ?? DS.textMuted),
          const SizedBox(width: 12),
          Text(label, style: DS.body),
          const Spacer(),
          Text(value,
              style: DS.bodyMd.copyWith(color: DS.textPrimary),
              textAlign: TextAlign.end),
        ],
      ),
    );
  }
}
