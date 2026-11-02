import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_colors.dart';
import '../routes/route_names.dart';
import '../../features/auth/presentation/viewmodels/auth_cubit.dart';

/// Route guard ensuring protected patient screens require a valid authenticated session.
/// Unauthenticated users are redirected to login with their intended destination preserved.
class AuthRequiredRoute extends StatefulWidget {
  final Widget child;
  final String routePath;

  const AuthRequiredRoute({
    super.key,
    required this.child,
    required this.routePath,
  });

  @override
  State<AuthRequiredRoute> createState() => _AuthRequiredRouteState();
}

class _AuthRequiredRouteState extends State<AuthRequiredRoute> {
  bool _redirectScheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkAuth();
  }

  void _checkAuth() {
    final authState = context.read<AuthCubit?>()?.state;
    final isAuthenticated = authState?.isAuthenticated == true;

    if (!isAuthenticated && !_redirectScheduled) {
      _redirectScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final currentAuth = context.read<AuthCubit?>()?.state;
        if (currentAuth?.isAuthenticated == true) {
          _redirectScheduled = false;
          return;
        }
        final target = widget.routePath;
        final redirectUri = Uri.encodeComponent(target);
        context.go('${RouteNames.signin}?redirect=$redirectUri');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit?>()?.state;
    if (authState?.isAuthenticated == true) {
      return widget.child;
    }
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

