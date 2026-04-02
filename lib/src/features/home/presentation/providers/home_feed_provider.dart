import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mana_poster/src/features/home/domain/models/home_banner.dart';
import 'package:mana_poster/src/features/home/domain/models/home_category.dart';
import 'package:mana_poster/src/features/home/domain/models/home_feed.dart';
import 'package:mana_poster/src/features/home/domain/models/home_template.dart';

final homeFeedProvider = Provider<HomeFeed>((ref) {
  return const HomeFeed(
    banners: <HomeBanner>[
      HomeBanner(
        id: 'banner_1',
        title: 'Festival Highlights',
        imageUrl: '',
      ),
      HomeBanner(
        id: 'banner_2',
        title: 'Today Special',
        imageUrl: '',
      ),
    ],
    categories: <HomeCategory>[
      HomeCategory(
        id: 'all',
        labels: <String, String>{'en': 'All', 'te': 'అన్నీ', 'hi': 'सभी'},
      ),
      HomeCategory(
        id: 'good_morning',
        labels: <String, String>{
          'en': 'Good Morning',
          'te': 'శుభోదయం',
          'hi': 'शुभ प्रभात',
        },
      ),
      HomeCategory(
        id: 'devotional',
        labels: <String, String>{'en': 'Devotional', 'te': 'భక్తి', 'hi': 'भक्ति'},
      ),
    ],
    templates: <HomeTemplate>[
      HomeTemplate(
        id: 'template_1',
        title: 'Morning Blessings',
        isPremium: false,
      ),
      HomeTemplate(
        id: 'template_2',
        title: 'Festival Premium',
        isPremium: true,
        priceLabel: '₹29',
      ),
    ],
  );
});
