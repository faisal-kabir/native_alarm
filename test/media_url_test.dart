import 'package:eala/core/constants/app_constant.dart';
import 'package:eala/core/network/media_url.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a path gets the base URL in front, with exactly one slash between', () {
    final base = AppConstant.baseUrl.replaceAll(RegExp(r'/+$'), '');
    expect(mediaUrl('icons/health.svg'), '$base/icons/health.svg');
    expect(mediaUrl('/icons/health.svg'), '$base/icons/health.svg');
    expect(mediaUrl('  icons/health.svg '), '$base/icons/health.svg');
  });

  test('a full URL is left alone', () {
    expect(
      mediaUrl('https://cdn.example.com/a.svg'),
      'https://cdn.example.com/a.svg',
    );
    expect(mediaUrl('http://example.com/a.svg'), 'http://example.com/a.svg');
  });

  test('the base URL points at Supabase Storage', () {
    expect(AppConstant.baseUrl, startsWith(AppConstant.SUPABASE_URL));
  });
}
