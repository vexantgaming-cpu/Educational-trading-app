/// App-wide constants.
library;

/// Must match `version:` in pubspec.yaml (checked by a test).
const appVersion = '1.0.0';

/// The app's public contact address: where "Leave feedback" in Account
/// sends messages (through the user's own email app), and the address shown
/// in the privacy policy (`site/privacy/`) and the Play Store listing. A
/// test keeps the three in step.
const feedbackEmail = 'upwiqapp@gmail.com';

/// The public website (the `site/` folder, published with GitHub Pages).
const websiteUrl =
    'https://vexantgaming-cpu.github.io/Educational-trading-app/';

/// The privacy policy: linked from Account and from the Play Store listing.
/// The page is `site/privacy/index.html`.
const privacyPolicyUrl = '${websiteUrl}privacy/';
