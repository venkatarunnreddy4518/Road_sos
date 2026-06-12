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
    'continue_apple': {'en': 'Continue with Apple', 'hi': 'Apple से जारी रखें', 'te': 'Appleతో కొనసాగండి', 'ta': 'Apple மூலம் தொடரவும்'},
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
    'submit': {'en': 'Submit', 'hi': 'जमा करें', 'te': 'సమర్పించు', 'ta': 'சமर్ப்పி'},
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
    'sign_in_profile_prompt': {'en': 'Sign in to manage your profile and history', 'hi': 'अपनी प्रोफ़ाइल और इतिहास प्रबंधित करने के लिए साइन इन करें', 'te': 'మీ ప్రొఫైల్ మరియు చరిత్రను నిర్వహించడానికి సైన్ ఇన్ చేయండి', 'ta': 'உங்கள் சுயவிவரம் மற்றும் வரலாற்றை நிர్வகிக்க உள்நுழையவும்'},
    'theme': {'en': 'Theme', 'hi': 'थीम', 'te': 'థీమ్', 'ta': 'தீம்'},
    'theme_system': {'en': 'System default', 'hi': 'सिस्टम डिफ़ॉल्ट', 'te': 'సిస్టమ్ డిఫాల్ట్', 'ta': 'முறைமை இயல்புநிலை'},
    'theme_light': {'en': 'Light', 'hi': 'लाइट', 'te': 'లైట్', 'ta': 'ஒளி'},
    'theme_dark': {'en': 'Dark', 'hi': 'डार्क', 'te': 'డార్క్', 'ta': 'இருள்'},
    'sign_in': {'en': 'Sign in', 'hi': 'साइन इन', 'te': 'సైన్ ఇన్', 'ta': 'உள்நுழைய'},
    'sign_in_subtitle': {'en': 'Help is one tap away.\nEnter your details to continue.', 'hi': 'एक टैप में मदद।\nजारी रखने के लिए अपनी जानकारी दर्ज करें।', 'te': 'సహాయం ఒక ట్యాప్ దూరంలో ఉంది.\nక్రమం చేయడానికి మీ వివరాలను నమోదు చేయండి.', 'ta': 'உதவி ஒரு தட்டு தూரத்தில் உள்ளது.\nத்தொடர్ச్சி செய்ய உங்கள் விவரங்களை உள்ளிடவும்.'},
    'email_tab': {'en': 'Email', 'hi': 'ईमेल', 'te': 'ఇమెయిల్', 'ta': 'மின்னஞ்சல்'},
    'protected_otp': {'en': 'Protected by one-time verification.', 'hi': 'एकबारी सत्यापन द्वारा सुरक्षित।', 'te': 'ఒకసారి ధృవీకరణ ద్వారా సురక్షితమైనది.', 'ta': 'ஒரு முறை சரிபார்ப்பு மூலம் பாதுகாக்கப்பட்டுள்ளது.'},
    'terms_of_service': {'en': 'Terms of Service', 'hi': 'सेवा की शर्तें', 'te': 'సేవా నిబంధనలు', 'ta': 'சேவை நிபंधனలు'},
    'privacy_policy': {'en': 'Privacy Policy', 'hi': 'गोपनीयता नीति', 'te': 'గోపనీయతా విధానం', 'ta': 'தனியுரிமை நीति'},
    'help': {'en': 'Help', 'hi': 'मदद', 'te': 'సహాయం', 'ta': 'உதவி'},
    'continue': {'en': 'Continue', 'hi': 'जारी रखें', 'te': 'కొనసాగండి', 'ta': 'தொடரவும்'},
    'new_to_roadside': {'en': 'New to Roadside SOS?', 'hi': 'Roadside SOS के लिए नए हैं?', 'te': 'Roadside SOSకు క్రొత్తది?', 'ta': 'Roadside SOS में नया?'},
    'create_account': {'en': 'Create account', 'hi': 'खाता बनाएं', 'te': 'ఖాతా సృష్టించండి', 'ta': 'खाता बनाएँ'},
    'verify_code_hint': {'en': "We'll text a one-time code to verify it's you.", 'hi': "हम आपको एक बार की कोड भेजेंगे।", 'te': "మేము ఒక సారి కోడ్ మీకు పంపుతాము.", 'ta': "நாம் உங்களை சரிபார்க்க ஒரு முறை குறியீட்டை அனுப்புவோம்."},
    'verify_email_hint': {'en': "We'll send a secure sign-in link to your inbox.", 'hi': "हम आपके इनबॉक्स में एक सुरक्षित साइन-इन लिंक भेजेंगे।", 'te': "మేము మీ ఇన్‌బాక్స్‌కు సురక్షిత సైన్-ఇన్ లింక్ పంపుతాము.", 'ta': "நாம் உங்கள் இனबாக்சுக்கு ஒரு பாதுகாப்பான உள்நுழைப்பு இணைப்பை அனுப்புவோம்."},
    'ai_assistant': {'en': 'AI Assistant', 'hi': 'एआई सहायक', 'te': 'AI అసిస్టెంట్', 'ta': 'AI உதவி'},
    'ai_settings': {'en': 'AI Settings', 'hi': 'एआई सेटिंग्स', 'te': 'AI సెట్టింగ్‌లు', 'ta': 'AI அமைப்புகள்'},
    'ai_enabled': {'en': 'Enable AI Assistant', 'hi': 'एआई सहायक सक्षम करें', 'te': 'AI అసిస్టెంట్‌ని ప్రారంభించు', 'ta': 'AI உதவியை இயக்கு'},
    'ai_provider': {'en': 'AI Provider', 'hi': 'एआई प्रदाता', 'te': 'AI ప్రొవైడర్', 'ta': 'AI வழங்குநர்'},
    'ai_model': {'en': 'Model Name', 'hi': 'मॉडल का नाम', 'te': 'మోడల్ పేరు', 'ta': 'மாதிரி பெயர்'},
    'ai_endpoint': {'en': 'Endpoint URL', 'hi': 'एंडपॉइंट URL', 'te': 'ఎండ్ పాయింట్ URL', 'ta': 'எண்ட்பாயிண்ட் URL'},
    'ai_api_key': {'en': 'API Key', 'hi': 'एपीआई कुंजी', 'te': 'API కీ', 'ta': 'API விசை'},

    // ── Categories (names shown on home cards) ──
    'cat_puncture': {'en': 'Puncture Fix', 'hi': 'पंचर ठीक करें', 'te': 'పంక్చర్ ఫిక్స్', 'ta': 'பஞ்சர் சரி'},
    'cat_fuel': {'en': 'Out of Fuel', 'hi': 'ईंधन खत्म', 'te': 'ఇంధనం అయిపోయింది', 'ta': 'எரிபொருள் தீர்ந்தது'},
    'cat_battery': {'en': 'Jump Start', 'hi': 'जंप स्टार्ट', 'te': 'జంప్ స్టార్ట్', 'ta': 'ஜம்ப் ஸ்டார்ட்'},
    'cat_breakdown': {'en': 'Mechanic / Breakdown', 'hi': 'मैकेनिक / खराबी', 'te': 'మెకానిక్ / బ్రేక్‌డౌన్', 'ta': 'மெக்கானிக் / பழுது'},
    'cat_towing': {'en': 'Towing Service', 'hi': 'टोइंग सेवा', 'te': 'టోయింగ్ సేవ', 'ta': 'இழுவை சேவை'},
    'lbl_roadside': {'en': 'ROADSIDE', 'hi': 'रोडसाइड', 'te': 'రోడ్‌సైడ్', 'ta': 'சாலையோரம்'},
    'lbl_emergency': {'en': 'EMERGENCY', 'hi': 'आपातकाल', 'te': 'అత్యవసరం', 'ta': 'அவசரம்'},
    'lbl_battery': {'en': 'BATTERY', 'hi': 'बैटरी', 'te': 'బ్యాటరీ', 'ta': 'பேட்டரி'},
    'badge_onsite': {'en': '⚙️ On-site repair', 'hi': '⚙️ मौके पर मरम्मत', 'te': '⚙️ ఆన్-సైట్ మరమ్మతు', 'ta': '⚙️ இடத்திலேயே பழுதுபார்ப்பு'},
    'towing_sub': {'en': 'Tow to a workshop or your destination', 'hi': 'वर्कशॉप या अपने गंतव्य तक टो करें', 'te': 'వర్క్‌షాప్ లేదా మీ గమ్యస్థానానికి టో చేయండి', 'ta': 'பட்டறை அல்லது உங்கள் இலக்குக்கு இழுக்கவும்'},
    'fast': {'en': 'FAST', 'hi': 'तेज़', 'te': 'ఫాస్ట్', 'ta': 'வேகம்'},

    // ── Home screen ──
    'app_subtitle': {'en': 'Highway Assistance Marketplace', 'hi': 'हाईवे सहायता मार्केटप्लेस', 'te': 'హైవే అసిస్టెన్స్ మార్కెట్‌ప్లేస్', 'ta': 'நெடுஞ்சாலை உதவி சந்தை'},
    'where_help': {'en': 'Where do you need help?', 'hi': 'आपको कहाँ मदद चाहिए?', 'te': 'మీకు ఎక్కడ సహాయం కావాలి?', 'ta': 'உங்களுக்கு எங்கே உதவி வேண்டும்?'},
    'promo_title': {'en': 'More verified helpers online now', 'hi': 'अब और अधिक सत्यापित सहायक ऑनलाइन', 'te': 'ఇప్పుడు మరిన్ని ధృవీకరించబడిన సహాయకులు ఆన్‌లైన్‌లో', 'ta': 'இப்போது மேலும் சரிபார்க்கப்பட்ட உதவியாளர்கள் ஆன்லைனில்'},
    'promo_sub': {'en': 'All helpers are background checked.', 'hi': 'सभी सहायकों की पृष्ठभूमि जाँची गई है।', 'te': 'అందరు సహాయకుల నేపథ్యం తనిఖీ చేయబడింది.', 'ta': 'அனைத்து உதவியாளர்களும் பின்னணி சரிபார்க்கப்பட்டவர்கள்.'},
    'ai_mechanic_title': {'en': 'AI Roadside Mechanic', 'hi': 'एआई रोडसाइड मैकेनिक', 'te': 'AI రోడ్‌సైడ్ మెకానిక్', 'ta': 'AI சாலையோர மெக்கானிக்'},
    'ai_mechanic_sub': {'en': 'Troubleshoot issues and find nearest help instantly!', 'hi': 'समस्याएँ हल करें और तुरंत निकटतम मदद पाएँ!', 'te': 'సమస్యలను పరిష్కరించి సమీప సహాయాన్ని వెంటనే కనుగొనండి!', 'ta': 'சிக்கல்களைத் தீர்த்து அருகிலுள்ள உதவியை உடனே கண்டறியவும்!'},
    'emergency_services': {'en': 'EMERGENCY SERVICES', 'hi': 'आपातकालीन सेवाएँ', 'te': 'అత్యవసర సేవలు', 'ta': 'அவசர சேவைகள்'},
    'open_near_you': {'en': 'OPEN NEAR YOU', 'hi': 'आपके पास खुले', 'te': 'మీ దగ్గర తెరిచి ఉన్నవి', 'ta': 'உங்கள் அருகில் திறந்தவை'},
    'safety_advice': {'en': 'SAFETY ADVICE', 'hi': 'सुरक्षा सलाह', 'te': 'భద్రతా సలహా', 'ta': 'பாதுகாப்பு அறிவுரை'},
    'no_helpers_nearby': {'en': 'No helpers nearby', 'hi': 'आस-पास कोई सहायक नहीं', 'te': 'సమీపంలో సహాయకులు లేరు', 'ta': 'அருகில் உதவியாளர்கள் இல்லை'},
    'helpers_nearby_suffix': {'en': 'helpers nearby', 'hi': 'सहायक पास में', 'te': 'సహాయకులు దగ్గరలో', 'ta': 'உதவியாளர்கள் அருகில்'},
    'pickup_point': {'en': 'Pickup Point', 'hi': 'पिकअप पॉइंट', 'te': 'పికప్ పాయింట్', 'ta': 'பிக்அப் இடம்'},
    'new_badge': {'en': 'NEW', 'hi': 'नया', 'te': 'కొత్త', 'ta': 'புதிது'},
    'nav_home': {'en': 'Home', 'hi': 'होम', 'te': 'హోమ్', 'ta': 'முகப்பு'},
    'nav_nearby': {'en': 'Nearby', 'hi': 'आस-पास', 'te': 'సమీపం', 'ta': 'அருகில்'},
    'nav_travel': {'en': 'Travel', 'hi': 'यात्रा', 'te': 'ప్రయాణం', 'ta': 'பயணம்'},
    'location_off': {'en': 'Location is off', 'hi': 'लोकेशन बंद है', 'te': 'లొకేషన్ ఆఫ్ ఉంది', 'ta': 'இருப்பிடம் அணைக்கப்பட்டுள்ளது'},
    'location_off_sub': {'en': 'Tap to enable for accurate help', 'hi': 'सटीक मदद के लिए टैप करें', 'te': 'ఖచ్చితమైన సహాయం కోసం నొక్కండి', 'ta': 'துல்லியமான உதவிக்கு தட்டவும்'},
    'locating': {'en': 'Locating you…', 'hi': 'आपको ढूँढ रहे हैं…', 'te': 'మిమ్మల్ని కనుగొంటోంది…', 'ta': 'உங்களைக் கண்டறிகிறது…'},
    'enable': {'en': 'Enable', 'hi': 'सक्षम करें', 'te': 'ప్రారంభించు', 'ta': 'இயக்கு'},
    'gps': {'en': 'GPS', 'hi': 'जीपीएस', 'te': 'GPS', 'ta': 'GPS'},
    'safety1_title': {'en': 'Turn on Hazards', 'hi': 'हैज़र्ड लाइट चालू करें', 'te': 'హజార్డ్ లైట్లు ఆన్ చేయండి', 'ta': 'அபாய விளக்குகளை இயக்கவும்'},
    'safety1_desc': {'en': 'Switch on hazard lights immediately to warn passing traffic.', 'hi': 'गुजरती गाड़ियों को सचेत करने के लिए तुरंत हैज़र्ड लाइट चालू करें।', 'te': 'వెళ్తున్న ట్రాఫిక్‌ను హెచ్చరించడానికి వెంటనే హజార్డ్ లైట్లు ఆన్ చేయండి.', 'ta': 'கடந்து செல்லும் வாகனங்களை எச்சரிக்க உடனே அபாய விளக்குகளை இயக்கவும்.'},
    'safety2_title': {'en': 'Move Off Road', 'hi': 'सड़क से हटें', 'te': 'రోడ్డు పక్కకు వెళ్లండి', 'ta': 'சாலையை விட்டு விலகவும்'},
    'safety2_desc': {'en': 'Pull safely onto the shoulder or a safe spot away from lanes.', 'hi': 'सुरक्षित रूप से किनारे या लेन से दूर सुरक्षित जगह पर रुकें।', 'te': 'సురక్షితంగా పక్కకు లేదా లేన్ల నుండి దూరంగా సురక్షిత ప్రదేశానికి వెళ్లండి.', 'ta': 'பாதையில் இருந்து விலகி பாதுகாப்பான இடத்தில் நிறுத்தவும்.'},
    'safety3_title': {'en': 'Share Location', 'hi': 'लोकेशन शेयर करें', 'te': 'లొకేషన్ షేర్ చేయండి', 'ta': 'இருப்பிடத்தைப் பகிரவும்'},
    'safety3_desc': {'en': 'Send your GPS coordinates to family or emergency contacts.', 'hi': 'अपने जीपीएस निर्देशांक परिवार या आपातकालीन संपर्कों को भेजें।', 'te': 'మీ GPS కోఆర్డినేట్లను కుటుంబం లేదా అత్యవసర పరిచయాలకు పంపండి.', 'ta': 'உங்கள் GPS ஆயங்களை குடும்பம் அல்லது அவசர தொடர்புகளுக்கு அனுப்பவும்.'},

    // ── Profile screen ──
    'help_support': {'en': 'Help & support', 'hi': 'सहायता और समर्थन', 'te': 'సహాయం & మద్దతు', 'ta': 'உதவி & ஆதரவு'},
    'saved_vehicles': {'en': 'Saved vehicles', 'hi': 'सहेजे गए वाहन', 'te': 'సేవ్ చేసిన వాహనాలు', 'ta': 'சேமித்த வாகனங்கள்'},
    'vehicles_suffix': {'en': 'vehicles', 'hi': 'वाहन', 'te': 'వాహనాలు', 'ta': 'வாகனங்கள்'},
    'payments': {'en': 'Payments', 'hi': 'भुगतान', 'te': 'చెల్లింపులు', 'ta': 'கட்டணங்கள்'},
    'my_sos': {'en': 'My SOS requests', 'hi': 'मेरे SOS अनुरोध', 'te': 'నా SOS అభ్యర్థనలు', 'ta': 'எனது SOS கோரிக்கைகள்'},
    'safety': {'en': 'Safety', 'hi': 'सुरक्षा', 'te': 'భద్రత', 'ta': 'பாதுகாப்பு'},
    'emergency_contacts': {'en': 'Emergency contacts', 'hi': 'आपातकालीन संपर्क', 'te': 'అత్యవసర పరిచయాలు', 'ta': 'அவசர தொடர்புகள்'},
    'added_suffix': {'en': 'added', 'hi': 'जोड़े गए', 'te': 'జోడించబడింది', 'ta': 'சேர்க்கப்பட்டது'},
    'refer_earn': {'en': 'Refer and earn', 'hi': 'रेफर करें और कमाएँ', 'te': 'రెఫర్ చేసి సంపాదించండి', 'ta': 'பரிந்துரைத்து சம்பாதிக்கவும்'},
    'get_50': {'en': 'Get ₹50', 'hi': '₹50 पाएँ', 'te': '₹50 పొందండి', 'ta': '₹50 பெறுங்கள்'},
    'my_rewards': {'en': 'My rewards', 'hi': 'मेरे रिवॉर्ड', 'te': 'నా రివార్డ్‌లు', 'ta': 'எனது வெகுமதிகள்'},
    'app_language': {'en': 'App language', 'hi': 'ऐप भाषा', 'te': 'యాప్ భాష', 'ta': 'ஆப் மொழி'},
    'sign_out': {'en': 'Sign out', 'hi': 'साइन आउट', 'te': 'సైన్ అవుట్', 'ta': 'வெளியேறு'},
    'my_rating': {'en': 'My Rating', 'hi': 'मेरी रेटिंग', 'te': 'నా రేటింగ్', 'ta': 'எனது மதிப்பீடு'},
    'provider_sub': {'en': 'Receive roadside requests', 'hi': 'रोडसाइड अनुरोध प्राप्त करें', 'te': 'రోడ్‌సైడ్ అభ్యర్థనలు స్వీకరించండి', 'ta': 'சாலையோர கோரிக்கைகளைப் பெறுங்கள்'},
    'sign_in_continue': {'en': 'Sign in to continue', 'hi': 'जारी रखने के लिए साइन इन करें', 'te': 'కొనసాగించడానికి సైన్ ఇన్ చేయండి', 'ta': 'தொடர உள்நுழையவும்'},

    // ── Results screen (filters + broadcast) ──
    'filter_nearest': {'en': 'Nearest', 'hi': 'निकटतम', 'te': 'సమీపం', 'ta': 'அருகில்'},
    'filter_top_rated': {'en': 'Top Rated', 'hi': 'टॉप रेटेड', 'te': 'టాప్ రేటెడ్', 'ta': 'சிறந்த மதிப்பீடு'},
    'filter_open_now': {'en': 'Open Now', 'hi': 'अभी खुला', 'te': 'ఇప్పుడు తెరిచి ఉంది', 'ta': 'இப்போது திறந்துள்ளது'},
    'filter_with_sms': {'en': 'With SMS', 'hi': 'एसएमएस के साथ', 'te': 'SMS తో', 'ta': 'SMS உடன்'},
    'request_help_now': {'en': 'Request help now', 'hi': 'अभी मदद माँगें', 'te': 'ఇప్పుడే సహాయం అడగండి', 'ta': 'இப்போது உதவி கோரு'},
    'alerts_nearby': {'en': 'Alerts nearby helpers on your route', 'hi': 'आपके रास्ते के पास के सहायकों को सूचित करता है', 'te': 'మీ మార్గంలోని సమీప సహాయకులను అలర్ట్ చేస్తుంది', 'ta': 'உங்கள் வழியில் உள்ள உதவியாளர்களை எச்சரிக்கிறது'},
    'all': {'en': 'All', 'hi': 'सभी', 'te': 'అన్నీ', 'ta': 'அனைத்தும்'},
    'within': {'en': 'within', 'hi': 'के भीतर', 'te': 'లోపల', 'ta': 'உள்ளே'},
    'helpers_available_nearby': {'en': 'helpers available nearby', 'hi': 'सहायक पास में उपलब्ध', 'te': 'సహాయకులు దగ్గరలో అందుబాటులో', 'ta': 'உதவியாளர்கள் அருகில் கிடைக்கின்றனர்'},
    'locating_helpers': {'en': 'Locating verified helpers...', 'hi': 'सत्यापित सहायक ढूँढ रहे हैं...', 'te': 'ధృవీకరించబడిన సహాయకులను కనుగొంటోంది...', 'ta': 'சரிபார்க்கப்பட்ட உதவியாளர்களைக் கண்டறிகிறது...'},
    'need_help_prefix': {'en': 'Need help', 'hi': 'मदद चाहिए', 'te': 'సహాయం కావాలి', 'ta': 'உதவி வேண்டும்'},
    'needs_your_help': {'en': 'needs your help', 'hi': 'को आपकी मदद चाहिए', 'te': 'మీ సహాయం కావాలి', 'ta': 'உங்கள் உதவி தேவை'},
    'navigate': {'en': 'Navigate', 'hi': 'दिशा-निर्देश', 'te': 'నావిగేట్', 'ta': 'வழிசெலுத்து'},
    'directions_to_seeker': {'en': 'Directions to seeker', 'hi': 'जरूरतमंद तक दिशा-निर्देश', 'te': 'అభ్యర్థి వద్దకు దిశలు', 'ta': 'கோரியவருக்கு வழிகள்'},
    'someone_nearby': {'en': 'Someone nearby', 'hi': 'पास में कोई', 'te': 'దగ్గరలో ఎవరో', 'ta': 'அருகில் ஒருவர்'},
    'km_away_suffix': {'en': 'km away', 'hi': 'किमी दूर', 'te': 'కిమీ దూరం', 'ta': 'கி.மீ தொலைவில்'},
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
