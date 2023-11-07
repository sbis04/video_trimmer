import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color.fromARGB(255, 239, 234, 244);
  static const Color backgroundLighter = Colors.white;
  static const Color postRecorderBackground = background;
  static const Color accent = Color(0xFFFF10AA);
  static const Color mediumAccent = Color(0xFF9E1F63);
  static const Color emphasisTextColor = Color(0xFF9E1F63);
  static const Color darkAccent = Color(0xFF662D91);
  static const Color darLight = Color(0xFFEFE9F4);
  static const Color textColor = Color(0xFF252525);
  static const Color textColorLight = Color(0xFFFFFFFF);
  static const Color textColorLighter = Color(0xFF6E6E70);
  static const Color borderColor = Color(0xFFBEBEBE);
  static const Color dividerColor = Color(0xFFF1F1F1);
  static const Color hintTextColor = Color(0xFFA1A1A1);

  static const Color followButtonColor = Color(0xFFEFEAF4);
  static const Color followButtonBorder = Color(0xFF662D91);

  static const Color unfollowButtonGradientStart = Color(0xDD662D91);
  static const Color unfollowButtonGradientCenter = Color(0xCC9E1F63);
  static const Color unfollowButtonGradientEnd = Color(0xCCFF10AA);

  static const Color verifiedBadge = Color(0xFF00B0FF);
  static const Color profileIconColor = Color(0xFF707070);

  static const Color errorBannerColor = background;

  static const Color textIconPostColor = Color.fromRGBO(37, 37, 37, 1.0);
  static const Color recordSplash = Color.fromRGBO(158, 31, 99, 0.15);
  static const Color audioRecordItem = Color(0xAAEEF0EB);
  static const Color postTextItem = Color(0xAAEEEAF4);
  static const Color inquiryVotedBackground = Color(0xffEEF0EB);
  static const Color discountColor = Color(0xff009541);
  static const Color creditCardColor = Color(0xFF662D91);

  static Color colorByAmount(double amount) {
    switch (amount) {
      case < 5.0:
        return Colors.indigo;
      case < 10.0:
        return Colors.green;
      case < 20.0:
        return Colors.brown;
      case < 50.0:
        return Colors.blueGrey;
      case >= 50.0:
        return Colors.amber.shade600;
    }
    return AppColors.mediumAccent;
  }
}

class Shapes {
  static const BorderRadius bannerBorder = BorderRadius.only(
    bottomLeft: Radius.circular(15),
    bottomRight: Radius.circular(15),
  );
}

class TextStyles {
  static const titleStyle = TextStyle(
    fontWeight: FontWeight.w900,
    fontSize: 19,
    height: 1.21,
    color: AppColors.textColor,
  );

  static const titleStyleNoHeight = TextStyle(
    fontWeight: FontWeight.w900,
    fontSize: 19,
    color: AppColors.textColor,
  );

  static const normalStyle = TextStyle(
    fontSize: 15,
    height: 1.21,
    color: AppColors.textColor,
  );

  static const normalStyleLight = TextStyle(
    fontSize: 15,
    height: 1.21,
    color: AppColors.textColorLight,
  );

  static const normalErrorStyle = TextStyle(
    fontSize: 15,
    height: 1.21,
    color: AppColors.mediumAccent,
  );
  static const normalUncoloredStyle = TextStyle(
    fontSize: 15,
    height: 1.21,
  );

  static const hintTextStyle = TextStyle(
    fontSize: 16,
    height: 1.21,
    color: AppColors.hintTextColor,
  );

  static const hintRegularTextStyle = TextStyle(
    fontSize: 15,
    color: AppColors.hintTextColor,
  );

  static const labelTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.textColor,
  );

  static const emphasisText = TextStyle(
    fontWeight: FontWeight.w900,
    fontSize: 15,
    height: 1.21,
    letterSpacing: 1,
    color: AppColors.emphasisTextColor,
  );

  static const emphasisTextHigh = TextStyle(
    fontWeight: FontWeight.w900,
    fontSize: 24,
    height: 1.21,
    letterSpacing: 1,
    color: AppColors.emphasisTextColor,
  );

  static const mediumRegularText = TextStyle(
    fontWeight: FontWeight.w500,
    fontSize: 15,
    height: 1.21,
    letterSpacing: 1,
    color: AppColors.textColor,
  );

  static const smallRegularText = TextStyle(
    fontWeight: FontWeight.w500,
    fontSize: 13,
    color: AppColors.textColor,
  );

  static const accentRegularText = TextStyle(
    fontWeight: FontWeight.w500,
    fontSize: 15,
    height: 1.21,
    letterSpacing: 1,
    color: AppColors.accent,
  );

  static const emphasisTextMedium = TextStyle(
    fontSize: 15,
    color: AppColors.emphasisTextColor,
  );

  static const emphasisTextSmall = TextStyle(
    fontSize: 11,
    color: AppColors.emphasisTextColor,
  );

  static const emphasisTextDark = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.textColor,
  );

  static const emphasisTextLight = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textColorLight,
  );

  static const helperTextStyle = TextStyle(
    fontSize: 12,
    height: 1.21,
    letterSpacing: 0,
    color: AppColors.textColor,
  );

  static const spotlightHeader = TextStyle(
    fontSize: 20,
    height: 1.21,
    letterSpacing: 0,
    fontWeight: FontWeight.w900,
    color: AppColors.textColorLight,
  );

  static final spotlightBody = normalStyle.copyWith(
    color: AppColors.textColorLight,
    fontStyle: FontStyle.italic,
  );

  static final spotlightButton = normalStyle.copyWith(
    color: AppColors.textColorLight,
    fontWeight: FontWeight.w900,
  );

  static const searchLabel = TextStyle(
    fontSize: 18,
    height: 1.15,
    fontWeight: FontWeight.w900,
  );

  static const profileName = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: AppColors.textColor,
  );

  static const profileNickName = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textColor,
  );

  static const normalTitleStyle = TextStyle(
    fontWeight: FontWeight.w500,
    fontSize: 17,
    color: AppColors.textColor,
  );

  static const regularTitleStyle = TextStyle(
    fontWeight: FontWeight.w500,
    fontSize: 15,
    color: AppColors.textColor,
  );

  static const titlePost = TextStyle(
    fontWeight: FontWeight.w500,
    fontSize: 19,
    color: AppColors.textIconPostColor,
  );

  static const smallPercentStyle = TextStyle(
    fontSize: 11,
    color: AppColors.discountColor,
  );

  static const liveTagsText = TextStyle(
    fontWeight: FontWeight.w500,
    fontSize: 17,
    color: AppColors.textColorLight,
  );
}
