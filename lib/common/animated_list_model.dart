import 'package:flutter/material.dart';

typedef AnimatedListRemovedItemBuilder =
    Widget Function(BuildContext context, Animation<double> animation);

class ListModel<E> {
  ListModel({
    required this.listKey,
    required Iterable<E> initialItems,
    required this.removeItemBuilder,
  }) : _items = List<E>.from(initialItems);

  final GlobalKey<AnimatedListState> listKey;
  final AnimatedListRemovedItemBuilder removeItemBuilder;
  final List<E> _items;

  List<E> get items => _items;

  int get length => _items.length;

  E operator [](int index) => _items[index];

  int indexOf(E item) => _items.indexOf(item);

  void insert(int index, E item) {
    _items.insert(index, item);
    listKey.currentState?.insertItem(
      index,
      duration: const Duration(milliseconds: 300),
    );
  }

  void removeAt(int index) {
    _items.removeAt(index);
    listKey.currentState?.removeItem(
      index,
      (context, animation) => removeItemBuilder(context, animation),
      duration: const Duration(milliseconds: 250),
    );
  }

  void removeWhere(bool Function(E element) test) {
    for (var i = _items.length - 1; i >= 0; i--) {
      if (test(_items[i])) {
        removeAt(i);
      }
    }
  }

  void updateItem(int index, E newItem) {
    _items[index] = newItem;
  }

  void replaceAll(Iterable<E> items) {
    _items.clear();
    _items.addAll(items);
  }
}
