import 'package:chat/core/theme/theme.dart';
import 'package:chat/features/tor/tor_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TorBootstrappingDialog extends ConsumerWidget {
  const TorBootstrappingDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(torProvider).value;
    final isError = status == TorStatus.error;

    return Dialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primaryBlue),
            const SizedBox(height: 20),
            Text(
              isError ? 'Tor failed to connect' : 'Connecting to Tor',
              style: Theme.of(
                context,
              ).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              isError
                  ? 'Falling back to direct connection'
                  : 'This may take up to 60 seconds while the Tor circuit is established.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: AppColors.onSecondaryBackground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
