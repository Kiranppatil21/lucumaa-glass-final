import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../providers/orders/orders_providers.dart';
import '../../providers/orders/orders_state.dart';
import '../../widgets/shimmer_list.dart';

class OrdersListScreen extends ConsumerStatefulWidget {
  const OrdersListScreen({super.key, required this.title});
  final String title;

  @override
  ConsumerState<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends ConsumerState<OrdersListScreen> {
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    final max = _controller.position.maxScrollExtent;
    final cur = _controller.position.pixels;
    if (cur >= max - 240) {
      ref.read(ordersNotifierProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final OrdersState state = ref.watch(ordersNotifierProvider);

    ref.listen<OrdersState>(ordersNotifierProvider, (prev, next) {
      final msg = next.error;
      if (msg != null && msg.isNotEmpty && msg != prev?.error) {
        ref.read(snackbarServiceProvider).showMessage(msg);
      }
    });

    if (state.isLoading && state.items.isEmpty) {
      return ShimmerList();
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(ordersNotifierProvider.notifier).refresh(),
      child: ListView.separated(
        controller: _controller,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, i) {
          if (i == state.items.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: state.isLoadingMore
                    ? const CircularProgressIndicator()
                    : Text(state.hasMore ? 'Pull to load more…' : 'No more orders'),
              ),
            );
          }

          final o = state.items[i];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.receipt_long),
              title: Text(o.code.isEmpty ? 'Order ${o.id}' : o.code),
              subtitle: Text('Status: ${o.status}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemCount: state.items.length + 1,
      ),
    );
  }
}
