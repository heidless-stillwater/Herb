import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class StillwaterSyncModal extends StatefulWidget {
  final AppState state;

  const StillwaterSyncModal({
    super.key,
    required this.state,
  });

  @override
  State<StillwaterSyncModal> createState() => _StillwaterSyncModalState();
}

class _StillwaterSyncModalState extends State<StillwaterSyncModal> {
  final TextEditingController _emailController = TextEditingController(text: 'heidlessemail18@gmail.com');
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _statusMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter both email and password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _statusMessage = 'Connecting to Stillwater Suite (stillwater-sovereign-04)...';
    });

    try {
      await widget.state.authService.signInWithEmail(email, password);
      final user = widget.state.authService.currentUser;
      if (user != null) {
        setState(() => _statusMessage = 'Syncing inventory with herb-db-0...');
        await widget.state.syncWithCloud();
        setState(() {
          _statusMessage = '✓ Connected to herb-db-0!';
          _isLoading = false;
        });
        if (mounted) {
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) Navigator.pop(context);
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Authentication failed: $e';
        _statusMessage = null;
      });
    }
  }

  Future<void> _handleSignOut() async {
    setState(() => _isLoading = true);
    await widget.state.authService.signOut();
    widget.state.setBypassAuth(false);
    setState(() => _isLoading = false);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _handleManualSync() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Syncing stash with herb-db-0...';
    });
    await widget.state.syncWithCloud();
    setState(() {
      _isLoading = false;
      _statusMessage = '✓ Stash synchronized successfully!';
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = widget.state.authService;
    final isAuth = auth.isAuthenticated;
    final isSU = auth.isStillwaterSuperUser;

    return Dialog(
      backgroundColor: AppColors.surfaceElevation2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGlow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.castle_rounded, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Stillwater Suite',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'herb-db-0 · sovereign-04',
                              style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontFamily: 'monospace'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              if (isAuth) ...[
                // Authenticated State
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevation1,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Connected Account', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          if (isSU)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.amber, width: 0.8),
                              ),
                              child: const Text('SUPER USER', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.amber)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        auth.email ?? 'Authenticated',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'UID: ${auth.uid ?? "N/A"}',
                        style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (_statusMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _statusMessage!,
                      style: const TextStyle(fontSize: 12, color: AppColors.primaryLight),
                    ),
                  ),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: _isLoading
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.sync_rounded, size: 16),
                        label: const Text('Sync Stash Now', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _isLoading ? null : _handleManualSync,
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _isLoading ? null : _handleSignOut,
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              ] else ...[
                // Guest / Unauthenticated State
                const Text(
                  'Operating in local guest mode. Sign in with your Stillwater Suite account to sync products with cloud database herb-db-0.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _emailController,
                  style: const TextStyle(fontSize: 13, color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Stillwater Suite Email',
                    labelStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.surfaceElevation1,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary, size: 18),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(fontSize: 13, color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.surfaceElevation1,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 18),
                  ),
                ),
                const SizedBox(height: 14),

                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(fontSize: 12, color: AppColors.error),
                    ),
                  ),

                if (_statusMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _statusMessage!,
                      style: const TextStyle(fontSize: 12, color: AppColors.primaryLight),
                    ),
                  ),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _isLoading ? null : _handleSignIn,
                    child: _isLoading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Connect Suite Account', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
