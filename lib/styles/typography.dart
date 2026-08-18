import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTypography {

  static TextStyle get displayLarge => GoogleFonts.plusJakartaSans(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.darkNavy,
    letterSpacing: -0.5,
  );

  static TextStyle get titleMedium => GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.darkNavy,
    letterSpacing: -0.3,
  );
  static TextStyle get titleLarge => GoogleFonts.plusJakartaSans(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.darkNavy,
    letterSpacing: -0.3,
  );

  static TextStyle get bodyLarge => GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.deepBlue,
  );

  static TextStyle get bodyMedium => GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.lightBlue,
  );
  static TextStyle get bodySmall => GoogleFonts.plusJakartaSans(
    fontSize: 10,
    fontWeight: FontWeight.w300,
    color: AppColors.lightBlue,
  );

  static TextStyle get buttonText => GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.white,
    letterSpacing: 0.5,
  );
}