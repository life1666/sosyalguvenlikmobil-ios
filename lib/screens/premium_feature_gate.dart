import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/premium_access_service.dart';
import '../services/premium_trial_service.dart';
import '../utils/app_design.dart';
import 'premium_ekrani.dart';

class PremiumFeatureGate extends StatefulWidget {
  const PremiumFeatureGate({
    super.key,
    required this.title,
    required this.child,
    this.embedded = false,
    this.previewBuilder,
  });

  final String title;
  final Widget child;
  final bool embedded;
  final Widget Function(BuildContext, PremiumAccessStatus?, VoidCallback)?
      previewBuilder;

  @override
  State<PremiumFeatureGate> createState() => _PremiumFeatureGateState();
}

class _PremiumFeatureGateState extends State<PremiumFeatureGate>
    with WidgetsBindingObserver {
  late Future<PremiumAccessStatus> _status;
  StreamSubscription<User?>? _authSubscription;
  Timer? _expiryTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _status = _loadStatus();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((_) {
      if (mounted) _reload();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();
    _expiryTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _reload();
  }

  Future<PremiumAccessStatus> _loadStatus() async {
    final result = await PremiumAccessService().load();
    _expiryTimer?.cancel();
    final end = result.trial.endsAt;
    if (result.trial.phase == PremiumTrialPhase.active && end != null) {
      final remaining = end.difference(DateTime.now());
      if (remaining > Duration.zero) {
        _expiryTimer = Timer(remaining, () {
          if (mounted) _reload();
        });
      }
    }
    return result;
  }

  void _reload() => setState(() => _status = _loadStatus());

  Future<void> _openPremium() async {
    await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => const PremiumEkrani(),
    ));
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<PremiumAccessStatus>(
        future: _status,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            const loading = Center(
                child: Padding(
                    padding: EdgeInsets.all(30),
                    child: CircularProgressIndicator()));
            if (widget.embedded) return loading;
            return Scaffold(
              backgroundColor: AppDesign.activeBackground,
              appBar: AppDesign.appBar(widget.title),
              body: SafeArea(child: AppContent(child: loading)),
            );
          }
          if (snapshot.data?.canUsePersonalFeatures == true) {
            return widget.child;
          }
          final status = snapshot.data;
          if (widget.previewBuilder != null) {
            return widget.previewBuilder!(context, status, _openPremium);
          }
          final expired = status?.trial.phase == PremiumTrialPhase.expired;
          final title = snapshot.hasError
              ? 'Erişim durumu kontrol edilemedi'
              : expired
                  ? 'Deneme süreniz sona erdi'
                  : status?.hasProfile == true
                      ? 'Kişisel takip Premium ile açılır'
                      : 'Kendi çalışma hayatınızı takip edin';
          final description = snapshot.hasError
              ? 'Bağlantınızı kontrol edip yeniden deneyin.'
              : expired
                  ? 'Bilgileriniz cihazınızda kalır. Abonelik kullanıma açıldığında Premium erişiminize devam edebilirsiniz.'
                  : status?.hasProfile == true
                      ? 'Bilgileriniz cihazınızda hazır. Premium ekranından 7 günlük ücretsiz denemeyi başlatabilirsiniz.'
                      : 'Bilgilerinizi cihazınıza kaydedin; ardından kart istemeden 7 gün deneyin.';
          final preview = AppSurface(
            padding: const EdgeInsets.all(18),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [
                    Icon(Icons.lock_outline_rounded,
                        color: Theme.of(context).primaryColor, size: 23),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(widget.title,
                            style: TextStyle(
                                color: AppDesign.activeInk,
                                fontWeight: FontWeight.w700,
                                fontSize: 16))),
                  ]),
                  const SizedBox(height: 14),
                  Text(title,
                      style: TextStyle(
                          color: AppDesign.activeInk,
                          fontSize: 19,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(description,
                      style:
                          TextStyle(color: AppDesign.activeMuted, height: 1.4)),
                  const SizedBox(height: 16),
                  if (!snapshot.hasError) ...[
                    Text('ÖRNEK GÖRÜNÜM',
                        style: TextStyle(
                            color: AppDesign.activeMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1)),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, runSpacing: 8, children: const [
                      Chip(label: Text('Emeklilik takibi')),
                      Chip(label: Text('Haklarım')),
                      Chip(label: Text('Maaş analizi')),
                    ]),
                    const SizedBox(height: 12),
                  ],
                  FilledButton(
                    onPressed: snapshot.hasError ? _reload : _openPremium,
                    child: Text(snapshot.hasError
                        ? 'Tekrar dene'
                        : expired || status?.hasProfile == true
                            ? 'Premium’u incele'
                            : 'Bilgilerimi gir'),
                  ),
                ]),
          );
          return widget.embedded
              ? preview
              : Scaffold(
                  backgroundColor: AppDesign.activeBackground,
                  appBar: AppDesign.appBar(widget.title),
                  body: SafeArea(
                      child: AppContent(
                          child: ListView(
                              padding: const EdgeInsets.all(20),
                              children: [preview]))),
                );
        },
      );
}
