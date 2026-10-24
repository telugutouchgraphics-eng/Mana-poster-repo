import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mana_poster/features/prehome/services/approved_creator_template_service.dart';

void main() {
  ApprovedCreatorTemplateService service(Object body, {int status = 200}) =>
      ApprovedCreatorTemplateService(
        httpClient: MockClient((request) async {
          final payload = jsonDecode(request.body) as Map<String, dynamic>;
          expect(payload['categoryPresence'], true);
          expect(payload['regionId'], 'telangana');
          return http.Response(jsonEncode(body), status);
        }),
      );
  Map<String, Object> poster(String id, String category, {int? createdAt}) => {
    'id': id,
    'categoryId': category,
    'categoryLabel': category,
    'imageUrl': 'https://example.com/poster.jpg',
    'regionId': 'telangana',
    'createdAt': createdAt ?? 1,
  };
  test(
    'complete empty response is a confirmed zero, not a load failure',
    () async {
      expect(
        await service({
          'ok': true,
          'complete': true,
          'posters': [],
        }).fetchPublishedCategoryPresence(regionId: 'telangana'),
        isEmpty,
      );
    },
  );
  test(
    'presence includes categories absent from the initial feed page',
    () async {
      final result = await service({
        'ok': true,
        'complete': true,
        'posters': [poster('older', 'anniversary')],
      }).fetchPublishedCategoryPresence(regionId: 'telangana');
      expect(result.single.categoryId, 'anniversary');
    },
  );
  test(
    'partial and failed responses are not interpreted as zero posters',
    () async {
      for (final body in [
        {'ok': true, 'posters': []},
        {'ok': true, 'complete': false, 'posters': []},
        {'ok': false, 'complete': true, 'posters': []},
      ]) {
        await expectLater(
          service(body).fetchPublishedCategoryPresence(regionId: 'telangana'),
          throwsFormatException,
        );
      }
      await expectLater(
        service({
          'ok': false,
        }, status: 500).fetchPublishedCategoryPresence(regionId: 'telangana'),
        throwsFormatException,
      );
    },
  );
  test(
    'broken media and unreleased good-night posters cannot show a category',
    () async {
      final result = await service({
        'ok': true,
        'complete': true,
        'posters': [
          {...poster('broken', 'birthday'), 'imageUrl': ''},
          poster(
            'night',
            'good_night',
            createdAt: DateTime.now().millisecondsSinceEpoch,
          ),
          poster('visible', 'good_morning'),
        ],
      }).fetchPublishedCategoryPresence(regionId: 'telangana');
      expect(result.map((item) => item.categoryId), ['good_morning']);
    },
  );
}
