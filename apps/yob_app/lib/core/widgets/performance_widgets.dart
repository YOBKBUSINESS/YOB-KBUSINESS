import 'package:flutter/material.dart';

/// Performance-optimized list builder that uses pagination
/// and keeps alive only visible items.
///
/// Wraps a [ListView.builder] with:
/// - Automatic pagination trigger near the end of the list
/// - Item extent for faster scrolling
/// - AddAutomaticKeepAlives disabled for memory efficiency
class PaginatedListView<T> extends StatefulWidget {
  const PaginatedListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.onLoadMore,
    this.hasMore = true,
    this.isLoading = false,
    this.emptyWidget,
    this.itemExtent,
    this.padding,
    this.loadMoreThreshold = 3,
    this.separatorBuilder,
  });

  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final VoidCallback onLoadMore;
  final bool hasMore;
  final bool isLoading;
  final Widget? emptyWidget;
  final double? itemExtent;
  final EdgeInsetsGeometry? padding;
  final int loadMoreThreshold;
  final Widget Function(BuildContext context, int index)? separatorBuilder;

  @override
  State<PaginatedListView<T>> createState() => _PaginatedListViewState<T>();
}

class _PaginatedListViewState<T> extends State<PaginatedListView<T>> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!widget.hasMore || widget.isLoading) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    // Trigger load when within threshold items from the bottom
    final threshold = (widget.itemExtent ?? 80) * widget.loadMoreThreshold;

    if (maxScroll - currentScroll <= threshold) {
      widget.onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty && !widget.isLoading) {
      return widget.emptyWidget ??
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Aucune donnée disponible',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
    }

    final itemCount = widget.items.length + (widget.hasMore ? 1 : 0);

    if (widget.separatorBuilder != null) {
      return ListView.separated(
        controller: _scrollController,
        padding: widget.padding,
        itemCount: itemCount,
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: true,
        separatorBuilder: widget.separatorBuilder!,
        itemBuilder: (context, index) {
          if (index >= widget.items.length) {
            return _buildLoader();
          }
          return widget.itemBuilder(context, widget.items[index], index);
        },
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: widget.padding,
      itemCount: itemCount,
      itemExtent: widget.itemExtent,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      itemBuilder: (context, index) {
        if (index >= widget.items.length) {
          return _buildLoader();
        }
        return widget.itemBuilder(context, widget.items[index], index);
      },
    );
  }

  Widget _buildLoader() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

/// Debounced search text field — reduces API calls while typing.
class DebouncedSearchField extends StatefulWidget {
  const DebouncedSearchField({
    super.key,
    required this.onChanged,
    this.hintText = 'Rechercher...',
    this.debounceDuration = const Duration(milliseconds: 400),
    this.controller,
  });

  final ValueChanged<String> onChanged;
  final String hintText;
  final Duration debounceDuration;
  final TextEditingController? controller;

  @override
  State<DebouncedSearchField> createState() => _DebouncedSearchFieldState();
}

class _DebouncedSearchFieldState extends State<DebouncedSearchField> {
  late final TextEditingController _controller;
  // No need to import dart:async for this simple debounce
  DateTime _lastChange = DateTime.now();

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _lastChange = DateTime.now();
    final changeTime = _lastChange;

    Future.delayed(widget.debounceDuration, () {
      if (_lastChange == changeTime && mounted) {
        widget.onChanged(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: _onChanged,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: _controller,
          builder: (_, value, __) {
            if (value.text.isEmpty) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _controller.clear();
                widget.onChanged('');
              },
            );
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }
}
