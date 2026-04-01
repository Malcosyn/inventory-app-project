import 'package:inventory_app_project/secrets/supabase_secret.dart';

class ProductImageUrlUseCase {
  const ProductImageUrlUseCase();

  String? resolveImageUrl(String rawValue) {
    final value = rawValue.trim();
    if (value.isEmpty) {
      return null;
    }

    final parsed = Uri.tryParse(value);
    if (parsed != null && parsed.hasScheme) {
      return value;
    }

    final base = SupabaseSecret.supabaseUrl;
    if (value.startsWith('/')) {
      final encodedPath = _encodePathSegments(value);
      return '$base/$encodedPath';
    }

    final encodedPath = _encodePathSegments(value);
    return '$base/storage/v1/object/public/$encodedPath';
  }

  String? proxyImageUrl(String? absoluteUrl) {
    if (absoluteUrl == null || absoluteUrl.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(absoluteUrl);
    if (uri == null || !uri.hasScheme) {
      return null;
    }

    if (uri.host.contains('supabase.co')) {
      return null;
    }

    final fullWithoutScheme =
        '${uri.host}${uri.path}${uri.hasQuery ? '?${uri.query}' : ''}';
    return 'https://images.weserv.nl/?url=${Uri.encodeComponent(fullWithoutScheme)}';
  }

  String _encodePathSegments(String path) {
    return path
        .split('/')
        .where((segment) => segment.isNotEmpty)
        .map((segment) {
          try {
            return Uri.encodeComponent(Uri.decodeComponent(segment));
          } catch (_) {
            return Uri.encodeComponent(segment);
          }
        })
        .join('/');
  }
}
