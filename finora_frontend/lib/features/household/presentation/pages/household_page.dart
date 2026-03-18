import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/services/currency_service.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../domain/entities/household_entity.dart';
import '../../domain/entities/household_member_entity.dart';
import '../../domain/entities/shared_transaction_entity.dart';
import '../../domain/entities/balance_entity.dart';
import '../bloc/household_bloc.dart';
import '../bloc/household_event.dart';
import '../bloc/household_state.dart';
import 'create_household_page.dart';
import 'invite_member_page.dart';
import 'add_shared_expense_page.dart';

class HouseholdPage extends StatefulWidget {
  const HouseholdPage({super.key});

  @override
  State<HouseholdPage> createState() => _HouseholdPageState();
}

class _HouseholdPageState extends State<HouseholdPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  HouseholdEntity? _household;
  List<HouseholdMemberEntity> _members = [];
  List<SharedTransactionEntity> _transactions = [];
  List<BalanceEntity> _balances = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return BlocProvider(
      create: (ctx) => di.sl<HouseholdBloc>()..add(const LoadHousehold()),
      child: BlocConsumer<HouseholdBloc, HouseholdState>(
        listener: (ctx, state) {
          if (state is HouseholdLoaded) {
            setState(() {
              _household = state.household;
              _loading = false;
            });
            if (state.household != null) {
              ctx.read<HouseholdBloc>().add(const LoadMembers());
            }
          } else if (state is HouseholdCreated) {
            setState(() => _household = state.household);
            ctx.read<HouseholdBloc>().add(const LoadMembers());
          } else if (state is MembersLoaded) {
            setState(() {
              _members = state.members;
              _loading = false;
            });
          } else if (state is TransactionsLoaded) {
            setState(() {
              _transactions = state.transactions;
              _loading = false;
            });
          } else if (state is BalancesLoaded) {
            setState(() {
              _balances = state.balances;
              _loading = false;
            });
          } else if (state is MemberInvited) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(s.memberInvited),
                backgroundColor: AppColors.success,
              ),
            );
            ctx.read<HouseholdBloc>().add(const LoadMembers());
          } else if (state is BalanceSettled) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(s.balanceSettled),
                backgroundColor: AppColors.success,
              ),
            );
            ctx.read<HouseholdBloc>().add(const LoadBalances());
          } else if (state is HouseholdLoading) {
            setState(() => _loading = true);
          } else if (state is HouseholdError) {
            setState(() {
              _loading = false;
            });
          }
        },
        builder: (ctx, state) {
          return Scaffold(
            backgroundColor: AppColors.backgroundLight,
            appBar: AppBar(
              backgroundColor: AppColors.surfaceLight,
              elevation: 0,
              title: Text(
                _household?.name ?? s.householdTitle,
                style: AppTypography.titleMedium(),
              ),
              leading: const BackButton(),
              bottom: _household != null
                  ? TabBar(
                      controller: _tabs,
                      labelColor: AppColors.primary,
                      indicatorColor: AppColors.primary,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      tabs: [
                        Tab(text: s.overviewTab),
                        Tab(text: s.membersTab),
                        Tab(text: s.sharedTab),
                        Tab(text: s.balancesTab),
                      ],
                      onTap: (i) {
                        if (i == 2 && _transactions.isEmpty) {
                          ctx.read<HouseholdBloc>().add(
                            const LoadSharedTransactions(),
                          );
                        }
                        if (i == 3 && _balances.isEmpty) {
                          ctx.read<HouseholdBloc>().add(const LoadBalances());
                        }
                      },
                    )
                  : null,
              actions: [
                if (_household != null)
                  IconButton(
                    icon: const Icon(Icons.person_add_outlined),
                    onPressed: () => _openInvitePage(ctx),
                  ),
              ],
            ),
            floatingActionButton: (_household != null && !_loading)
                ? FloatingActionButton.extended(
                    onPressed: () => _openAddExpensePage(ctx),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(s.addSharedExpense),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  )
                : null,
            body: _loading
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: SkeletonListLoader(count: 4, cardHeight: 80),
                  )
                : _household == null
                ? _buildNoHousehold(ctx, s)
                : TabBarView(
                    controller: _tabs,
                    children: [
                      _buildOverview(ctx, s),
                      _buildMembers(ctx, s),
                      _buildTransactions(ctx, s),
                      _buildBalances(ctx, s),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _buildNoHousehold(BuildContext ctx, dynamic s) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.home_outlined, color: AppColors.gray400, size: 64),
            const SizedBox(height: 16),
            Text(
              s.noHousehold,
              style: AppTypography.bodyMedium(color: AppColors.gray500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _openCreateHousehold(ctx, s),
              icon: const Icon(Icons.add_rounded),
              label: Text(s.createHousehold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverview(BuildContext ctx, dynamic s) {
    final fmt = CurrencyService().format;
    final totalShared = _transactions.fold(0.0, (sum, t) => sum + t.amount);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.gray200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.householdOverview, style: AppTypography.titleSmall()),
              const SizedBox(height: 12),
              _infoRow(s.membersTab, '${_members.length}'),
              const SizedBox(height: 8),
              _infoRow(s.sharedTab, fmt(totalShared)),
              const SizedBox(height: 8),
              if (_household!.inviteCode != null)
                _infoRow(s.inviteCode, _household!.inviteCode!),
            ],
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => _openInvitePage(ctx),
          icon: const Icon(Icons.person_add_outlined),
          label: Text(s.inviteMember),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodyMedium(color: AppColors.gray600)),
        Text(value, style: AppTypography.titleSmall()),
      ],
    );
  }

  Widget _buildMembers(BuildContext ctx, dynamic s) {
    if (_members.isEmpty) {
      return Center(
        child: Text(
          s.membersTab,
          style: AppTypography.bodyMedium(color: AppColors.gray500),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _members.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final m = _members[i];
        return ListTile(
          tileColor: AppColors.surfaceLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: AppColors.gray200),
          ),
          leading: CircleAvatar(
            backgroundColor: AppColors.primarySoft,
            child: Text(
              (m.name?.isNotEmpty == true ? m.name![0] : '?').toUpperCase(),
              style: AppTypography.titleSmall(color: AppColors.primary),
            ),
          ),
          title: Text(m.name ?? m.email ?? '?'),
          subtitle: Text(m.isOwner ? s.ownerRole : s.memberRole),
          trailing: m.isOwner
              ? null
              : IconButton(
                  icon: Icon(
                    Icons.remove_circle_outline_rounded,
                    color: AppColors.error,
                  ),
                  onPressed: () =>
                      ctx.read<HouseholdBloc>().add(RemoveMember(m.userId)),
                ),
        );
      },
    );
  }

  Widget _buildTransactions(BuildContext ctx, dynamic s) {
    final fmt = CurrencyService().format;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // How-to info card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.lightbulb_outline_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    s.householdExpenseHowTitle,
                    style: AppTypography.titleSmall(color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                s.householdExpenseHowBody,
                style: AppTypography.bodySmall(color: AppColors.gray700),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_transactions.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    color: AppColors.gray400,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    s.noData,
                    style: AppTypography.bodyMedium(color: AppColors.gray500),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () => _openAddExpensePage(ctx),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(s.addSharedExpense),
                  ),
                ],
              ),
            ),
          )
        else
          ...List.generate(_transactions.length, (i) {
            final t = _transactions[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                tileColor: AppColors.surfaceLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: AppColors.gray200),
                ),
                title: Text(t.description),
                subtitle: Text(t.createdByName),
                trailing: Text(
                  fmt(t.amount),
                  style: AppTypography.titleSmall(color: AppColors.primary),
                ),
              ),
            );
          }),
        const SizedBox(height: 80), // FAB space
      ],
    );
  }

  Widget _buildBalances(BuildContext ctx, dynamic s) {
    final fmt = CurrencyService().format;
    if (_balances.isEmpty) {
      return Center(
        child: Text(
          s.noData,
          style: AppTypography.bodyMedium(color: AppColors.gray500),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _balances.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final b = _balances[i];
        HouseholdMemberEntity? foundMember;
        for (final m in _members) {
          if (m.userId == b.owerId) {
            foundMember = m;
            break;
          }
        }
        final memberName =
            (foundMember ?? (_members.isNotEmpty ? _members.first : null))
                ?.name ??
            b.owerId;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.gray200),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(memberName, style: AppTypography.titleSmall()),
                    Text(
                      s.owesYou,
                      style: AppTypography.bodySmall(color: AppColors.gray500),
                    ),
                  ],
                ),
              ),
              Text(
                fmt(b.amount),
                style: AppTypography.titleSmall(color: AppColors.success),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () =>
                    ctx.read<HouseholdBloc>().add(SettleBalance(b.owerId)),
                child: Text(s.settleBalance),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openInvitePage(BuildContext ctx) async {
    final email = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const InviteMemberPage()),
    );
    if (email != null && email.isNotEmpty && ctx.mounted) {
      ctx.read<HouseholdBloc>().add(InviteMember(email));
    }
  }

  void _openAddExpensePage(BuildContext ctx) async {
    final data = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => AddSharedExpensePage(members: _members),
      ),
    );
    if (data != null && ctx.mounted) {
      ctx.read<HouseholdBloc>().add(CreateSharedTransaction(data));
      // Reload transactions and balances
      ctx.read<HouseholdBloc>().add(const LoadSharedTransactions());
      ctx.read<HouseholdBloc>().add(const LoadBalances());
    }
  }

  void _openCreateHousehold(BuildContext ctx, dynamic s) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const CreateHouseholdPage()),
    );
    if (result != null && ctx.mounted) {
      ctx.read<HouseholdBloc>().add(CreateHousehold(result));
    }
  }
}
