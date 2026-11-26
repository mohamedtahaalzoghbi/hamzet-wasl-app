enum AccountKind { company, interested, organization, volunteer }

enum NeedCategory { mobility, visual, hearing }

/// بيانات مؤقتة بنحتفظ بيها أثناء خطوات التسجيل.
/// لما نربط الباك إند هنستبدلها بـ State Management (Provider / Bloc ...).
class UserSession {
  UserSession._();

  static AccountKind? accountKind;
  static bool isOffline = false;
  static String? email;
  static String? phone;
  static String? governorate;
  static String? area;
  static int radiusKm = 20;
  static final Map<String, String> socialLinks = {};

  static String about = '';
  static String interestAreas = '';
  static String helpSkills = '';
  static NeedCategory? needCategory;

  /// اختيارات متربطة بالباك (ids من /meta/skills و /meta/interests).
  static Set<int> skillIds = {};
  static Set<int> interestIds = {};

  /// بيانات ملف المتطوع بتتبعت مع اختيار نوع المساعدة (PUT /me/volunteer-profile).
  static String volunteerSkillLevel = 'beginner';
  static int volunteerWeeklyHours = 3;
  static String volunteerExperience = '';

  /// تذكرة التسجيل الراجعة من POST /auth/register (الخطوة 1).
  /// بتتحتاج في register/complete مع كود الـ OTP.
  static String? registrationTicket;
  static DateTime? registrationTicketExpiresAt;

  static void reset() {
    accountKind = null;
    isOffline = false;
    email = null;
    phone = null;
    governorate = null;
    area = null;
    radiusKm = 20;
    socialLinks.clear();
    about = '';
    interestAreas = '';
    helpSkills = '';
    needCategory = null;
    skillIds = {};
    interestIds = {};
    volunteerSkillLevel = 'beginner';
    volunteerWeeklyHours = 3;
    volunteerExperience = '';
    registrationTicket = null;
    registrationTicketExpiresAt = null;
  }
}

