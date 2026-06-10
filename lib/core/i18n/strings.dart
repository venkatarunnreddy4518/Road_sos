// lib/core/i18n/strings.dart
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight, scalable localization: add a language by adding a column here.
/// Keys are referenced via `context.tr('key')`.
class AppStrings {
  static const supported = ['en', 'hi', 'te', 'ta'];

  static const languageNames = {
    'en': 'English',
    'hi': 'हिन्दी',
    'te': 'తెలుగు',
    'ta': 'தமிழ்',
  };

  static const Map<String, Map<String, String>> _values = {
    'app_title': {'en': 'Roadside Help', 'hi': 'रोडसाइड हेल्प', 'te': 'రోడ్‌సైడ్ హెల్ప్', 'ta': 'ரோடுசைடு உதவி'},
    'welcome_tagline': {
      'en': 'Help on the way, in a tap.',
      'hi': 'एक टैप में मदद, रास्ते में।',
      'te': 'ఒక్క ట్యాప్‌లో సహాయం.',
      'ta': 'ஒரு தட்டில் உதவி.'
    },
    'continue_email': {'en': 'Continue with Email', 'hi': 'ईमेल से जारी रखें', 'te': 'ఇమెయిల్‌తో కొనసాగండి', 'ta': 'மின்னஞ்சல் மூலம் தொடரவும்'},
    'continue_phone': {'en': 'Continue with Phone', 'hi': 'फ़ोन से जारी रखें', 'te': 'ఫోన్‌తో కొనసాగండి', 'ta': 'தொலைபேசி மூலம் தொடரவும்'},
    'continue_google': {'en': 'Continue with Google', 'hi': 'Google से जारी रखें', 'te': 'Googleతో కొనసాగండి', 'ta': 'Google மூலம் தொடரவும்'},
    'continue_guest': {'en': 'Continue as guest', 'hi': 'अतिथि के रूप में जारी रखें', 'te': 'అతిథిగా కొనసాగండి', 'ta': 'விருந்தினராக தொடரவும்'},
    'login': {'en': 'Log in', 'hi': 'लॉग इन', 'te': 'లాగిన్', 'ta': 'உள்நுழைய'},
    'signup': {'en': 'Sign up', 'hi': 'साइन अप', 'te': 'సైన్ అప్', 'ta': 'பதிவு செய்க'},
    'email': {'en': 'Email', 'hi': 'ईमेल', 'te': 'ఇమెయిల్', 'ta': 'மின்னஞ்சல்'},
    'password': {'en': 'Password', 'hi': 'पासवर्ड', 'te': 'పాస్‌వర్డ్', 'ta': 'கடவுச்சொல்'},
    'name': {'en': 'Name', 'hi': 'नाम', 'te': 'పేరు', 'ta': 'பெயர்'},
    'phone': {'en': 'Phone number', 'hi': 'फ़ोन नंबर', 'te': 'ఫోన్ నంబర్', 'ta': 'தொலைபேசி எண்'},
    'send_code': {'en': 'Send code', 'hi': 'कोड भेजें', 'te': 'కోడ్ పంపండి', 'ta': 'குறியீட்டை அனுப்பு'},
    'verify': {'en': 'Verify', 'hi': 'सत्यापित करें', 'te': 'ధృవీకరించండి', 'ta': 'சரிபார்'},
    'enter_code': {'en': 'Enter the 6-digit code', 'hi': '6 अंकों का कोड दर्ज करें', 'te': '6 అంకెల కోడ్ నమోదు చేయండి', 'ta': '6 இலக்கக் குறியீட்டை உள்ளிடவும்'},
    'whats_problem': {'en': 'What do you need help with?', 'hi': 'आपको किसमें मदद चाहिए?', 'te': 'మీకు దేనిలో సహాయం కావాలి?', 'ta': 'உங்களுக்கு எதில் உதவி வேண்டும்?'},
    'search_hint': {'en': 'Search helpers or services', 'hi': 'सहायक या सेवाएँ खोजें', 'te': 'సహాయకులు లేదా సేవలను శోధించండి', 'ta': 'உதவியாளர்கள் அல்லது சேவைகளைத் தேடு'},
    'nearby_helpers': {'en': 'Nearby helpers', 'hi': 'आस-पास के सहायक', 'te': 'సమీప సహాయకులు', 'ta': 'அருகிலுள்ள உதவியாளர்கள்'},
    'call': {'en': 'Call', 'hi': 'कॉल', 'te': 'కాల్', 'ta': 'அழை'},
    'sms': {'en': 'SMS', 'hi': 'एसएमएस', 'te': 'ఎస్ఎంఎస్', 'ta': 'எஸ்எம்எஸ்'},
    'directions': {'en': 'Directions', 'hi': 'दिशा-निर्देश', 'te': 'దిశలు', 'ta': 'வழிகள்'},
    'request_help': {'en': 'Request help', 'hi': 'मदद का अनुरोध करें', 'te': 'సహాయం అభ్యర్థించండి', 'ta': 'உதவி கோரு'},
    'far_away': {'en': 'Far away', 'hi': 'दूर', 'te': 'దూరంగా', 'ta': 'தொலைவில்'},
    'open_now': {'en': 'Open now', 'hi': 'अभी खुला', 'te': 'ఇప్పుడు తెరిచి ఉంది', 'ta': 'இப்போது திறந்துள்ளது'},
    'closed': {'en': 'Closed', 'hi': 'बंद', 'te': 'మూసివేయబడింది', 'ta': 'மூடப்பட்டது'},
    'hours_unknown': {'en': 'Hours unknown', 'hi': 'समय अज्ञात', 'te': 'సమయం తెలియదు', 'ta': 'நேரம் தெரியவில்லை'},
    'profile': {'en': 'Profile', 'hi': 'प्रोफ़ाइल', 'te': 'ప్రొఫైల్', 'ta': 'சுயவிவரம்'},
    'history': {'en': 'History', 'hi': 'इतिहास', 'te': 'చరిత్ర', 'ta': 'வரலாறு'},
    'settings': {'en': 'Settings', 'hi': 'सेटिंग्स', 'te': 'సెట్టింగ్‌లు', 'ta': 'அமைப்புகள்'},
    'language': {'en': 'Language', 'hi': 'भाषा', 'te': 'భాష', 'ta': 'மொழி'},
    'logout': {'en': 'Log out', 'hi': 'लॉग आउट', 'te': 'లాగౌట్', 'ta': 'வெளியேறு'},
    'provider_mode': {'en': 'Provider mode', 'hi': 'प्रदाता मोड', 'te': 'ప్రొవైడర్ మోడ్', 'ta': 'வழங்குநர் முறை'},
    'incoming_requests': {'en': 'Incoming requests', 'hi': 'आने वाले अनुरोध', 'te': 'వచ్చే అభ్యర్థనలు', 'ta': 'வரும் கோரிக்கைகள்'},
    'accept': {'en': 'Accept', 'hi': 'स्वीकारें', 'te': 'అంగీకరించు', 'ta': 'ஏற்க'},
    'decline': {'en': 'Decline', 'hi': 'अस्वीकारें', 'te': 'తిరస్కరించు', 'ta': 'நிராகரி'},
    'cancel': {'en': 'Cancel', 'hi': 'रद्द करें', 'te': 'రద్దు చేయి', 'ta': 'ரத்து'},
    'rate_helper': {'en': 'Rate your helper', 'hi': 'अपने सहायक को रेट करें', 'te': 'మీ సహాయకుడిని రేట్ చేయండి', 'ta': 'உங்கள் உதவியாளரை மதிப்பிடு'},
    'submit': {'en': 'Submit', 'hi': 'जमा करें', 'te': 'సమర్పించు', 'ta': 'சமர்ப்பி'},
    'offline_banner': {'en': 'Offline — showing cached helpers', 'hi': 'ऑफ़लाइन — कैश किए गए सहायक', 'te': 'ఆఫ్‌లైన్ — కాష్ సహాయకులు', 'ta': 'ஆஃப்லைன் — சேமித்த உதவியாளர்கள்'},
    'needs_connection': {'en': 'This needs an internet connection', 'hi': 'इसके लिए इंटरनेट चाहिए', 'te': 'దీనికి ఇంటర్నెట్ అవసరం', 'ta': 'இதற்கு இணைய இணைப்பு தேவை'},
    'last_updated': {'en': 'updated', 'hi': 'अपडेट', 'te': 'నవీకరించబడింది', 'ta': 'புதுப்பிக்கப்பட்டது'},
    'no_results': {'en': 'No helpers found', 'hi': 'कोई सहायक नहीं मिला', 'te': 'సహాయకులు ఎవరూ కనుగొనబడలేదు', 'ta': 'உதவியாளர்கள் இல்லை'},
    'retry': {'en': 'Retry', 'hi': 'पुनः प्रयास करें', 'te': 'మళ్లీ ప్రయత్నించండి', 'ta': 'மீண்டும் முயற்சி'},
    'edit_profile': {'en': 'Edit profile', 'hi': 'प्रोफ़ाइल संपादित करें', 'te': 'ప్రొఫైల్ సవరించండి', 'ta': 'சுயவிவரத்தைத் திருத்து'},
    'as_seeker': {'en': 'As seeker', 'hi': 'खोजकर्ता के रूप में', 'te': 'అన్వేషకుడిగా', 'ta': 'தேடுபவராக'},
    'as_helper': {'en': 'As helper', 'hi': 'सहायक के रूप में', 'te': 'సహాయకుడిగా', 'ta': 'உதவியாளராக'},
    'no_requests': {'en': 'No requests yet', 'hi': 'अभी तक कोई अनुरोध नहीं', 'te': 'ఇంకా అభ్యర్థనలు లేవు', 'ta': 'இன்னும் கோரிக்கைகள் இல்லை'},
    'become_helper': {'en': 'Become a helper', 'hi': 'सहायक बनें', 'te': 'సహాయకుడిగా మారండి', 'ta': 'உதவியாளராகுங்கள்'},
    'register_go_online': {'en': 'Register & go online', 'hi': 'पंजीकरण करें और ऑनलाइन हों', 'te': 'నమోదు చేసి ఆన్‌లైన్‌లోకి వెళ్లండి', 'ta': 'பதிவு செய்து ஆன்லைனில் வாருங்கள்'},
    'active_job': {'en': 'Active job', 'hi': 'सक्रिय कार्य', 'te': 'క్రియాశీల పని', 'ta': 'செயலில் உள்ள வேலை'},
    'vehicle_hint': {'en': 'Vehicle (e.g. Honda Activa)', 'hi': 'वाहन (जैसे Honda Activa)', 'te': 'వాహనం (ఉదా. Honda Activa)', 'ta': 'வாகனம் (எ.கா. Honda Activa)'},
    'sign_in_profile_prompt': {'en': 'Sign in to manage your profile and history', 'hi': 'अपनी प्रोफ़ाइल और इतिहास प्रबंधित करने के लिए साइन इन करें', 'te': 'మీ ప్రొఫైల్ మరియు చరిత్రను నిర్వహించడానికి సైన్ ఇన్ చేయండి', 'ta': 'உங்கள் சுயவிவரம் மற்றும் வரலாற்றை நிர்வகிக்க உள்நுழையவும்'},
  };

  static String of(String code, String key) {
    final entry = _values[key];
    if (entry == null) return key;
    return entry[code] ?? entry['en'] ?? key;
  }
}

/// Holds the active locale, persisted across launches (FR-029).
class LocaleController extends ChangeNotifier {
  Locale _locale = const Locale('en');
  Locale get locale => _locale;
  String get code => _locale.languageCode;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('language');
    if (saved != null && AppStrings.supported.contains(saved)) {
      _locale = Locale(saved);
      notifyListeners();
    }
  }

  Future<void> setLanguage(String code) async {
    if (!AppStrings.supported.contains(code)) return;
    _locale = Locale(code);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', code);
  }

  String tr(String key) => AppStrings.of(code, key);
}
