import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  AdminDashboardState createState() => AdminDashboardState();
}

class AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;

  static const List<_NavItem> _navItems = [
    _NavItem(
      label: 'All Requests',
      icon: Icons.list_alt_outlined,
      activeIcon: Icons.list_alt_rounded,
    ),
    _NavItem(
      label: 'All Users',
      icon: Icons.people_outline_rounded,
      activeIcon: Icons.people_rounded,
    ),
    _NavItem(
      label: 'Categories',
      icon: Icons.category_outlined,
      activeIcon: Icons.category_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _AdminRequestsPage(),
          _AdminUsersPage(),
          _AdminCategoriesPage(),
        ],
      ),
      bottomNavigationBar: _AdminBottomBar(
        currentIndex: _currentIndex,
        items: _navItems,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}

class _AdminBottomBar extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final Function(int) onTap;

  const _AdminBottomBar({
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selectedColor = isDark ? AppTheme.primaryDark : AppTheme.primaryLight;
    final unselectedColor = isDark
        ? AppTheme.textMediumEmphasisDark
        : AppTheme.textMediumEmphasisLight;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        border: Border(
          top: BorderSide(
            color: isDark ? AppTheme.dividerDark : AppTheme.borderLight,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? AppTheme.shadowDark : AppTheme.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = currentIndex == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(index),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isSelected ? item.activeIcon : item.icon,
                        color: isSelected ? selectedColor : unselectedColor,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected ? selectedColor : unselectedColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        height: 3,
                        width: isSelected ? 20 : 0,
                        decoration: BoxDecoration(
                          color: selectedColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─── Admin: All Requests ───────────────────────────────────────────────────
class _AdminRequestsPage extends StatefulWidget {
  const _AdminRequestsPage();

  @override
  State<_AdminRequestsPage> createState() => _AdminRequestsPageState();
}

class _AdminRequestsPageState extends State<_AdminRequestsPage> {
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final response = await Supabase.instance.client
          .from('requests')
          .select('id, title, status, created_at, categories(name)')
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _requests = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load requests.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'All Requests',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 2.h),
              Expanded(child: _buildBody(theme)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: theme.textTheme.bodyMedium),
            SizedBox(height: 2.h),
            ElevatedButton(
              onPressed: _fetchRequests,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_requests.isEmpty) {
      return Center(
        child: Text('No requests found.', style: theme.textTheme.bodyMedium),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchRequests,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _requests.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final req = _requests[index];
          final category = req['categories'] as Map<String, dynamic>?;
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              child: CustomIconWidget(
                iconName: 'assignment',
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ),
            title: Text(
              req['title'] as String? ?? 'Untitled',
              style: theme.textTheme.titleSmall,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              category?['name'] as String? ?? 'General',
              style: theme.textTheme.bodySmall,
            ),
            trailing: _StatusChip(
              status: req['status'] as String? ?? 'pending',
            ),
          );
        },
      ),
    );
  }
}

// ─── Admin: All Users ──────────────────────────────────────────────────────
class _AdminUsersPage extends StatefulWidget {
  const _AdminUsersPage();

  @override
  State<_AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<_AdminUsersPage> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final response = await Supabase.instance.client
          .from('users')
          .select('id, name, phone, role, created_at')
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _users = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load users.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'All Users',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 2.h),
              Expanded(child: _buildBody(theme)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: theme.textTheme.bodyMedium),
            SizedBox(height: 2.h),
            ElevatedButton(onPressed: _fetchUsers, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_users.isEmpty) {
      return Center(
        child: Text('No users found.', style: theme.textTheme.bodyMedium),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchUsers,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _users.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final user = _users[index];
          final role = user['role'] as String? ?? 'client';
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              child: CustomIconWidget(
                iconName: 'person',
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ),
            title: Text(
              user['name'] as String? ?? 'Unknown',
              style: theme.textTheme.titleSmall,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              user['phone'] as String? ?? '',
              style: theme.textTheme.bodySmall,
            ),
            trailing: _RoleChip(role: role),
          );
        },
      ),
    );
  }
}

// ─── Admin: Categories ─────────────────────────────────────────────────────
class _AdminCategoriesPage extends StatefulWidget {
  const _AdminCategoriesPage();

  @override
  State<_AdminCategoriesPage> createState() => _AdminCategoriesPageState();
}

class _AdminCategoriesPageState extends State<_AdminCategoriesPage> {
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final response = await Supabase.instance.client
          .from('categories')
          .select('id, name, price_range_text')
          .order('name');
      if (mounted) {
        setState(() {
          _categories = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load categories.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Categories',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 2.h),
              Expanded(child: _buildBody(theme)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: theme.textTheme.bodyMedium),
            SizedBox(height: 2.h),
            ElevatedButton(
              onPressed: _fetchCategories,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_categories.isEmpty) {
      return Center(
        child: Text('No categories found.', style: theme.textTheme.bodyMedium),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchCategories,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              child: CustomIconWidget(
                iconName: 'category',
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ),
            title: Text(
              cat['name'] as String? ?? 'Unknown',
              style: theme.textTheme.titleSmall,
            ),
            subtitle: cat['price_range_text'] != null
                ? Text(
                    cat['price_range_text'] as String,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  )
                : null,
          );
        },
      ),
    );
  }
}

// ─── Shared Chips ──────────────────────────────────────────────────────────
class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color color;
    switch (status.toLowerCase()) {
      case 'completed':
        color = AppTheme.successLight;
        break;
      case 'active':
      case 'in_progress':
        color = AppTheme.primaryLight;
        break;
      default:
        color = theme.colorScheme.onSurfaceVariant;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String role;
  const _RoleChip({required this.role});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color color;
    switch (role.toLowerCase()) {
      case 'admin':
        color = AppTheme.errorLight;
        break;
      case 'master':
        color = AppTheme.accentColor;
        break;
      default:
        color = AppTheme.primaryLight;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        role,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
