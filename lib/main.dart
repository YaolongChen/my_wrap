import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<int> _data = List.generate(4, (index) => index);
  bool _expandable = false;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _data.removeLast();
                    });
                  },
                  icon: const Icon(Icons.remove),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _data = List.generate(4, (index) => index);
                    });
                  },
                  child: Text('Reset'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _data = List.generate(60, (index) => index);
                    });
                  },
                  child: Text('SetMuch'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _data.clear();
                    });
                  },
                  child: Text('Clear'),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _data.add(_data.length);
                    });
                  },
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            MyWrap(
              ids: _data,
              xSpacing: 8,
              ySpacing: 6,
              expanded: _expanded,
              lineHeight: 50,
              onExpandableChanged: (expandable) {
                setState(() {
                  if (_expandable != expandable) {
                    setState(() {
                      _expandable = expandable;
                      if (!expandable) {
                        _expanded = false;
                      }
                    });
                  }
                });
              },
              overflowWidget: InkWell(
                onTap: () {
                  setState(() {
                    _data.clear();
                  });
                },
                child: const Text('ClearAll'),
              ),
              children: _data
                  .map((e) =>
                  LayoutId(
                    id: e,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      height: 50,
                      color: Colors.primaries[e % Colors.primaries.length],
                      child: Text((e % 10).toString()),
                    ),
                  ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            _expandable
                ? InkWell(
              onTap: () {
                setState(() {
                  _expanded = !_expanded;
                });
              },
              child: Ink(
                color: Colors.yellow,
                child: Text(_expanded ? 'Hide' : 'More'),
              ),
            )
                : const SizedBox()
          ],
        ),
      ),
    );
  }
}

class MyWrap extends StatefulWidget {
  const MyWrap({
    super.key,
    required this.children,
    required this.ids,
    required this.overflowWidget,
    required this.xSpacing,
    required this.ySpacing,
    required this.expanded,
    required this.lineHeight,
    required this.onExpandableChanged,
  });

  /// 被[LayoutId]包裹的子项
  final List<LayoutId> children;

  /// [children]对应的id
  final List<Object> ids;

  /// 始终在末尾的Widget
  final Widget overflowWidget;

  /// x轴间隔
  final double xSpacing;

  /// y轴间隔
  final double ySpacing;

  /// 是否展开，不展开时如果[children]超过3行，则不显示超过部分
  final bool expanded;

  /// 每行的高度
  final double lineHeight;

  /// 能否展开状态回调
  final void Function(bool expandable) onExpandableChanged;

  @override
  State<MyWrap> createState() => _MyWrapState();
}

class _MyWrapState extends State<MyWrap> {
  /// 默认超过3行折叠
  final _collapseLine = 3;

  /// [MyWrap.overflowWidget]对应的[LayoutId]
  final _overflowId = 'overflow';

  late int _rowNumber;

  @override
  void initState() {
    _rowNumber = _collapseLine;
    super.initState();
  }

  /// 组件的高度约束
  double get maxHeightConstrain {
    if (_rowNumber == 0) {
      return 0;
    } else if (!widget.expanded && _rowNumber > _collapseLine) {
      return _collapseLine * widget.lineHeight +
          (_collapseLine - 1) * widget.ySpacing;
    } else {
      return _rowNumber * widget.lineHeight +
          (_rowNumber - 1) * widget.ySpacing;
    }
  }

  void _onLayoutWillCompleted(int rowNumber) {
    if (rowNumber != _rowNumber) {
      WidgetsBinding.instance.addPostFrameCallback((duration) {
        final oldExpandable = _rowNumber > _collapseLine;
        setState(() {
          _rowNumber = rowNumber;
        });
        final expandable = rowNumber > _collapseLine;
        if (expandable != oldExpandable) {
          widget.onExpandableChanged(_rowNumber > _collapseLine);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(),
      constraints: BoxConstraints(
        maxHeight: maxHeightConstrain,
      ),
      child: CustomMultiChildLayout(
        delegate: MyDelegate(
          ids: widget.ids,
          xSpacing: widget.xSpacing,
          ySpacing: widget.ySpacing,
          collapseLine: _collapseLine,
          overflowId: _overflowId,
          expanded: widget.expanded,
          lineHeight: widget.lineHeight,
          onLayoutWillCompleted: _onLayoutWillCompleted,
        ),
        children: [
          ...widget.children,
          LayoutId(id: _overflowId, child: widget.overflowWidget),
        ],
      ),
    );
  }
}

class MyDelegate extends MultiChildLayoutDelegate {
  final List<Object> ids;
  final double xSpacing;
  final double ySpacing;
  final int collapseLine;
  final String overflowId;
  final bool expanded;
  final double lineHeight;
  final void Function(int rowNumber) onLayoutWillCompleted;

  MyDelegate({
    super.relayout,
    required this.ids,
    required this.xSpacing,
    required this.ySpacing,
    required this.collapseLine,
    required this.overflowId,
    required this.expanded,
    required this.lineHeight,
    required this.onLayoutWillCompleted,
  });

  /// child的布局约束
  BoxConstraints _getChildConstrains(double widthLimit) =>
      BoxConstraints(maxWidth: widthLimit, maxHeight: lineHeight);

  /// child在当前行的偏移量
  double _getChildLineYOffset(double childHeight) =>
      (lineHeight - childHeight) / 2;

  @override
  void performLayout(Size size) {
    if (ids.isEmpty) {
      layoutChild(overflowId, BoxConstraints.tight(Size.zero));
      onLayoutWillCompleted(0);
      return;
    }

    final widthLimit = size.width;

    double xOffset = 0;
    double yOffset = 0;

    int rowNumber = 1; // 行数
    int overflowChildIndex = -1; // 使到达最大行child的下标

    final overflowSize =
    layoutChild(overflowId, _getChildConstrains(widthLimit));
    xOffset += (overflowSize.width);
    final overflowLineYOffset = _getChildLineYOffset(overflowSize.height);

    for (var i = 0; i < ids.length; ++i) {
      final childId = ids[i];
      final childSize = layoutChild(childId, _getChildConstrains(widthLimit));
      if (xOffset + xSpacing + childSize.width <= widthLimit) {
        // 当前行能布置得下该child和overflow
        positionChild(
            childId,
            Offset(xOffset - overflowSize.width,
                yOffset + _getChildLineYOffset(childSize.height)));
        xOffset += (childSize.width + xSpacing - overflowSize.width);
        positionChild(
            overflowId, Offset(xOffset, yOffset + overflowLineYOffset));
        xOffset += overflowSize.width;
      } else {
        // 换行
        rowNumber++;
        // 如果已到达最大行则布置到下一行并终中断循环
        if (!expanded && rowNumber > collapseLine) {
          yOffset += (lineHeight + ySpacing);
          positionChild(childId,
              Offset(0, yOffset + _getChildLineYOffset(childSize.height)));
          xOffset = childSize.width;
          overflowChildIndex = i;
          break;
        } else {
          if (xOffset - overflowSize.width + childSize.width <= widthLimit) {
            // 上一行能布置的下该child，则把overflow换到这一行
            positionChild(
                childId,
                Offset(xOffset - overflowSize.width,
                    yOffset + _getChildLineYOffset(childSize.height)));
            yOffset += (lineHeight + ySpacing);
            positionChild(overflowId, Offset(0, yOffset + overflowLineYOffset));
            xOffset = overflowSize.width;
          } else if (childSize.width + xSpacing + overflowSize.width <=
              widthLimit) {
            // 上一行放不下child，但这一行能放的下overflow和child
            yOffset += (lineHeight + ySpacing);
            positionChild(childId,
                Offset(0, yOffset + _getChildLineYOffset(childSize.height)));
            positionChild(
                overflowId,
                Offset(
                    childSize.width + xSpacing, yOffset + overflowLineYOffset));
            xOffset = childSize.width + xSpacing + overflowSize.width;
          } else if (rowNumber + 1 == collapseLine && !expanded) {
            // 这一行无法同时放overflow和child并到达最大行，则这一行放overflow, 下一行放child
            yOffset += (lineHeight + ySpacing);
            positionChild(overflowId, Offset(0, yOffset + overflowLineYOffset));
            yOffset += (lineHeight + ySpacing);
            positionChild(childId,
                Offset(0, yOffset + _getChildLineYOffset(childSize.height)));
            xOffset = childSize.width;
            yOffset += (lineHeight + ySpacing);
            overflowChildIndex = i;
            rowNumber++;
            break;
          } else {
            // 这一行放child，下一行放overflow
            yOffset += (lineHeight + ySpacing);
            positionChild(childId,
                Offset(0, yOffset + _getChildLineYOffset(childSize.height)));
            yOffset += (lineHeight + ySpacing);
            positionChild(overflowId, Offset(0, yOffset + overflowLineYOffset));
            xOffset = overflowSize.width;
            rowNumber++;
          }
        }
      }
    }
    if (!overflowChildIndex.isNegative) {
      for (var i = overflowChildIndex + 1; i < ids.length; ++i) {
        final childId = ids[i];
        final childSize = layoutChild(childId, _getChildConstrains(widthLimit));
        if (xOffset + xSpacing + childSize.width <= widthLimit) {
          xOffset += xSpacing;
          // 当前行能布置得下该child
          positionChild(
              childId,
              Offset(
                  xOffset, yOffset + _getChildLineYOffset(childSize.height)));
          xOffset += (childSize.width);
        } else {
          // 换行
          rowNumber++;
          yOffset += (lineHeight + ySpacing);
          positionChild(childId,
              Offset(0, yOffset + _getChildLineYOffset(childSize.height)));
          xOffset = childSize.width;
        }
      }
    }
    onLayoutWillCompleted(rowNumber);
  }

  @override
  bool shouldRelayout(MyDelegate oldDelegate) {
    return !listEquals(oldDelegate.ids, ids) ||
        oldDelegate.expanded != expanded ||
        oldDelegate.collapseLine != collapseLine ||
        oldDelegate.xSpacing != xSpacing ||
        oldDelegate.ySpacing != ySpacing ||
        oldDelegate.lineHeight != lineHeight ||
        oldDelegate.overflowId != overflowId;
  }
}
