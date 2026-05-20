import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/routing/app_router.dart';

final deepLinkServiceProvider = Provider<DeepLinkService>((ref) {
  final service = DeepLinkService(AppLinks());
  ref.onDispose(service.dispose);
  return service;
});

class DeepLinkService {
  DeepLinkService(this._appLinks);

  final AppLinks _appLinks;
  StreamSubscription<Uri>? _subscription;

  void start(GoRouter router) {
    if (_subscription != null) {
      return;
    }

    _subscription = _appLinks.uriLinkStream.listen(
      (uri) {
        final target = resolveIncomingAppLink(uri);
        if (target != null) {
          router.go(target);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Deep link handling failed: $error');
      },
    );
  }

  void dispose() {
    unawaited(_subscription?.cancel());
    _subscription = null;
  }
}

class DeepLinkBootstrapper extends ConsumerStatefulWidget {
  const DeepLinkBootstrapper({
    required this.router,
    required this.child,
    super.key,
  });

  final GoRouter router;
  final Widget child;

  @override
  ConsumerState<DeepLinkBootstrapper> createState() =>
      _DeepLinkBootstrapperState();
}

class _DeepLinkBootstrapperState extends ConsumerState<DeepLinkBootstrapper> {
  @override
  void initState() {
    super.initState();
    ref.read(deepLinkServiceProvider).start(widget.router);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
