import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Reusable Riforni logo widget — polished monogram 'R'.
class RifornoLogo extends StatelessWidget {
  final double size;
  const RifornoLogo({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: size * 0.18,
            offset: Offset(0, size * 0.06),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.22),
        child: Image.asset(
          'assets/images/logo_icon.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Center(
            child: Text(
              'R',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF1A73E8),
                fontSize: size * 0.55,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Hero version used on splash/onboarding screens.
class RifornoLogoHero extends StatelessWidget {
  final double size;
  const RifornoLogoHero({super.key, this.size = 110});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RifornoLogo(size: size),
        const SizedBox(height: 18),
        Text(
          'Riforni',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF202124),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Gestione ordini fornitore',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF5F6368),
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }
}
