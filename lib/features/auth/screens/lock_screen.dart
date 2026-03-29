import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/glass_card.dart';
import '../providers/auth_provider.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  bool _authenticating = false;
  bool _deviceSupported = true;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _attemptBiometricUnlock();
    });
  }

  @override
  void dispose() {
    ref.read(authRepositoryProvider).stopAuthentication();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.surfaceDim, AppColors.background],
                ),
              ),
            ),
          ),
          Positioned(
            top: -120,
            right: -80,
            child: _GlowOrb(
              color: AppColors.teal.withValues(alpha: 0.06),
              size: 240,
            ),
          ),
          Positioned(
            bottom: -140,
            left: -90,
            child: _GlowOrb(
              color: AppColors.purple.withValues(alpha: 0.05),
              size: 280,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                children: [
                  const _LockTopBar(),
                  const SizedBox(height: 28),
                  Expanded(
                    child: Column(
                      children: [
                        const Spacer(flex: 2),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 360),
                          child: GlassCard(
                            glowColor: AppColors.teal,
                            radius: 32,
                            padding: const EdgeInsets.fromLTRB(24, 30, 24, 28),
                            opacity: 0.74,
                            child: Column(
                              children: [
                                GestureDetector(
                                  onTap: _authenticating
                                      ? null
                                      : _attemptBiometricUnlock,
                                  child: _FingerprintHero(
                                    active: _authenticating,
                                    dimmed: !_deviceSupported,
                                  ),
                                ),
                                const SizedBox(height: 28),
                                Text(
                                  'BIOMETRIC AUTHENTICATION',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _headlineText,
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(height: 1.22),
                                  textAlign: TextAlign.center,
                                ),
                                if (_statusMessage != null) ...[
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    _statusMessage!,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                                const SizedBox(height: 30),
                                Container(
                                  height: 1,
                                  color: AppColors.outlineVariant.withValues(
                                    alpha: 0.14,
                                  ),
                                ),
                                const SizedBox(height: 28),
                                const _PatternGrid(),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(flex: 2),
                        if (!_deviceSupported || !_authenticating) ...[
                          FilledButton.icon(
                            onPressed: _authenticating
                                ? null
                                : () => _authenticate(biometricOnly: false),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.teal,
                              foregroundColor: AppColors.onPrimary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                            ),
                            icon: const Icon(LucideIcons.fingerprint, size: 18),
                            label: Text(
                              _deviceSupported
                                  ? 'Try Fingerprint Again'
                                  : 'Unlock With Device Credentials',
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                        TextButton.icon(
                          onPressed: _authenticating
                              ? null
                              : () => _authenticate(biometricOnly: false),
                          icon: const Icon(
                            LucideIcons.grid,
                            size: 16,
                            color: AppColors.teal,
                          ),
                          label: Text(
                            'Use Pattern',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppColors.teal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  String get _headlineText {
    if (_authenticating) {
      return 'Confirm your fingerprint to unlock';
    }

    if (!_deviceSupported) {
      return 'Use your pattern or PIN to unlock';
    }

    return 'Scan your fingerprint to unlock';
  }

  Future<void> _attemptBiometricUnlock() async {
    await _authenticate(biometricOnly: true);
  }

  Future<void> _authenticate({required bool biometricOnly}) async {
    if (_authenticating) {
      return;
    }

    setState(() {
      _authenticating = true;
      _statusMessage = null;
    });

    final authRepository = ref.read(authRepositoryProvider);
    final isAvailable = await authRepository.isAvailable();

    if (!mounted) {
      return;
    }

    if (!isAvailable) {
      setState(() {
        _authenticating = false;
        _deviceSupported = false;
        _statusMessage =
            'Biometric unlock is unavailable on this device. Use your device credentials instead.';
      });
      return;
    }

    final success = await authRepository.authenticate(
      reason: biometricOnly
          ? 'Authenticate to unlock SpendSplit'
          : 'Use your device credentials to unlock SpendSplit',
      biometricOnly: biometricOnly,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      ref.read(appSessionUnlockedProvider.notifier).unlock();
      context.go(AppRoute.dashboard.path);
      return;
    }

    setState(() {
      _authenticating = false;
      _deviceSupported = true;
      _statusMessage = biometricOnly
          ? 'Fingerprint verification was not completed. You can retry or use your device pattern/PIN.'
          : 'Device verification was not completed.';
    });
  }
}

class _LockTopBar extends StatelessWidget {
  const _LockTopBar();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          const SizedBox(width: 28),
          Expanded(
            child: Center(
              child: Text(
                'SPENDSPLIT',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.teal,
                  fontWeight: FontWeight.w800,
                  shadows: [
                    Shadow(
                      color: AppColors.teal.withValues(alpha: 0.3),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Icon(LucideIcons.lock, color: AppColors.teal, size: 20),
        ],
      ),
    );
  }
}

class _FingerprintHero extends StatelessWidget {
  const _FingerprintHero({required this.active, required this.dimmed});

  final bool active;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final iconColor = dimmed ? AppColors.textSecondary : AppColors.teal;

    return SizedBox(
      width: 132,
      height: 132,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _PulseRing(
            size: 132,
            color: iconColor.withValues(alpha: active ? 0.28 : 0.18),
            delay: 0.ms,
          ),
          _PulseRing(
            size: 132,
            color: iconColor.withValues(alpha: active ? 0.18 : 0.1),
            delay: 700.ms,
          ),
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: iconColor.withValues(alpha: dimmed ? 0.18 : 0.32),
                width: 1.4,
              ),
              color: AppColors.surfaceLight.withValues(alpha: 0.26),
            ),
            child: Icon(
              LucideIcons.fingerprint,
              color: iconColor,
              size: 46,
              shadows: [
                Shadow(
                  color: iconColor.withValues(alpha: 0.32),
                  blurRadius: 12,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseRing extends StatelessWidget {
  const _PulseRing({
    required this.size,
    required this.color,
    required this.delay,
  });

  final double size;
  final Color color;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.2),
          ),
        )
        .animate(onPlay: (controller) => controller.repeat())
        .scaleXY(
          begin: 0.76,
          end: 1.1,
          duration: 1800.ms,
          delay: delay,
          curve: Curves.easeOutCubic,
        )
        .fadeOut(begin: 0.95, duration: 1800.ms, delay: delay);
  }
}

class _PatternGrid extends StatelessWidget {
  const _PatternGrid();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 28,
        runSpacing: 18,
        children: List.generate(
          9,
          (_) => Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withValues(alpha: 0.28),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: color, blurRadius: 120, spreadRadius: 30),
          ],
        ),
      ),
    );
  }
}
