import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class LockScreen extends StatelessWidget {
  const LockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
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
                  const SizedBox(height: 20),
                  Expanded(
                    child: Column(
                      children: [
                        const Spacer(flex: 2),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 360),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainer.withValues(
                                alpha: 0.4,
                              ),
                              borderRadius: BorderRadius.circular(32),
                              border: Border.all(
                                color: AppColors.outlineVariant.withValues(
                                  alpha: 0.16,
                                ),
                              ),
                            ),
                            child: Column(
                              children: [
                                const _FingerprintHero(),
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
                                  'Scan your fingerprint to unlock',
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(height: 1.22),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 34),
                                Container(
                                  height: 1,
                                  color: AppColors.outlineVariant.withValues(
                                    alpha: 0.14,
                                  ),
                                ),
                                const SizedBox(height: 30),
                                const _PatternGrid(),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(flex: 3),
                        TextButton.icon(
                          onPressed: () {},
                          icon: const Icon(
                            Icons.grid_4x4_rounded,
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
    );
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
          const Icon(Icons.lock_rounded, color: AppColors.teal, size: 20),
        ],
      ),
    );
  }
}

class _FingerprintHero extends StatelessWidget {
  const _FingerprintHero();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 124,
          height: 124,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.teal.withValues(alpha: 0.05),
          ),
        ),
        Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.teal.withValues(alpha: 0.32),
              width: 1.4,
            ),
            color: AppColors.surfaceLight.withValues(alpha: 0.26),
          ),
          child: Icon(
            Icons.fingerprint_rounded,
            color: AppColors.teal,
            size: 46,
            shadows: [
              Shadow(
                color: AppColors.teal.withValues(alpha: 0.32),
                blurRadius: 12,
              ),
            ],
          ),
        ),
      ],
    );
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
