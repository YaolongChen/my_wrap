import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final data = List.generate(5, (index) => index);
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(),
        body: SingleChildScrollView(
          child: Column(
            children: [
              MyWrap(
                ids: data,
                overflow: const Text('ClearAll'),
                children: data
                    .map((e) => LayoutId(
                          id: e,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            height: 50,
                            color:
                                Colors.primaries[e % Colors.primaries.length],
                            child: Text(e.toString()),
                          ),
                        ))
                    .toList(),
              ),
              Container(
                color: Colors.red,
                height: 100,
              )
            ],
          ),
        ),
      ),
    );
  }
}

const overflowId = 'overflow';

class MyWrap extends StatelessWidget {
  const MyWrap({
    super.key,
    required this.children,
    required this.ids,
    required this.overflow,
  });

  final List<LayoutId> children;
  final List<Object> ids;
  final Widget overflow;
  final int maxLine = 3;
  final double childHeight = 50;
  final double spacing = 8;
  final double runSpacing = 6;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox();
    }

    return Container(
      decoration: const BoxDecoration(),
      constraints: BoxConstraints(
        maxHeight: maxLine * childHeight + (maxLine - 1) * runSpacing,
      ),
      child: CustomMultiChildLayout(
        delegate: MyDelegate(
          ids: ids,
          spacing: spacing,
          runSpacing: runSpacing,
          maxLine: maxLine,
        ),
        children: [
          ...children,
          LayoutId(id: overflowId, child: overflow),
        ],
      ),
    );
  }
}

class MyDelegate extends MultiChildLayoutDelegate {
  final List<Object> ids;
  final double spacing;
  final double runSpacing;
  final int maxLine;

  MyDelegate({
    super.relayout,
    required this.ids,
    required this.spacing,
    required this.runSpacing,
    required this.maxLine,
  });

  @override
  void performLayout(Size size) {
    final widthLimit = size.width;
    final heightLimit = size.height;

    double curRowMaxChildHeight = 0; // 当前行最大高度
    double xOffset = 0;
    double yOffset = 0;

    int rowNumber = 1;
    int overflowChildIndex = -1; // 使到达最大行child的下标

    final overflowSize = layoutChild(overflowId,
        BoxConstraints(maxWidth: size.width, maxHeight: size.height));
    xOffset += (overflowSize.width);
    curRowMaxChildHeight = overflowSize.height;

    for (var i = 0; i < ids.length; ++i) {
      final childId = ids[i];
      final childSize = layoutChild(childId,
          BoxConstraints(maxWidth: size.width, maxHeight: size.height));
      if (xOffset + spacing + childSize.width <= widthLimit) {
        // 一行能布置得下该child和overflow
        xOffset = xOffset - overflowSize.width;
        positionChild(childId, Offset(xOffset, yOffset));
        xOffset += (childSize.width + spacing);
        positionChild(overflowId, Offset(xOffset, yOffset));
        xOffset += overflowSize.width;
        curRowMaxChildHeight = max(childSize.height, curRowMaxChildHeight);
      } else {
        // 换行
        // 如果已到达最大行则布置到下一行并终中断循环
        if (rowNumber == maxLine) {
          positionChild(
              childId, Offset(0, yOffset + curRowMaxChildHeight + runSpacing));
          overflowChildIndex = i;
          rowNumber++;
          break;
        } else {
          rowNumber++;
          if (xOffset - overflowSize.width + runSpacing + childSize.width <= widthLimit) {
            // 上一行能布置的下该child，则把overflow换到这一行
            positionChild(
                childId, Offset(xOffset - overflowSize.width, yOffset));
            curRowMaxChildHeight = max(childSize.height, curRowMaxChildHeight);
            yOffset += (curRowMaxChildHeight + runSpacing);
            positionChild(overflowId, Offset(0, yOffset));
            xOffset = overflowSize.width;
            curRowMaxChildHeight = overflowSize.height;
          } else if (childSize.width + spacing + overflowSize.width <=
              widthLimit) {
            // 上一行放不下child，但这一行能放的下overflow和child
            yOffset += (curRowMaxChildHeight + runSpacing);
            positionChild(childId, Offset(0, yOffset));
            positionChild(
                overflowId, Offset(childSize.width + spacing, yOffset));
            xOffset = childSize.width + spacing + overflowSize.width;
            curRowMaxChildHeight = max(childSize.height, overflowSize.height);
          } else if (rowNumber == maxLine) {
            // 这一行无法同时放overflow和child并到达最大行，则这一行放overflow, 下一行放child
            yOffset += (curRowMaxChildHeight + runSpacing);
            positionChild(overflowId, Offset(0, yOffset));
            yOffset += (overflowSize.height + runSpacing);
            positionChild(childId, Offset(0, yOffset));
            xOffset = childSize.width;
            yOffset += (childSize.height + runSpacing);
            overflowChildIndex = i;
            rowNumber++;
            break;
          } else {
            // 这一行放child，下一行放overflow
            yOffset += (curRowMaxChildHeight + runSpacing);
            positionChild(childId, Offset(0, yOffset));
            yOffset += (childSize.height + runSpacing);
            positionChild(overflowId, Offset(0, yOffset));
            xOffset = overflowSize.width;
            curRowMaxChildHeight = overflowSize.height;
            rowNumber++;
          }
        }
      }
    }
    if (!overflowChildIndex.isNegative) {
      for (var i = overflowChildIndex + 1; i < ids.length; ++i) {
        final childId = ids[i];
        layoutChild(childId, BoxConstraints.tight(Size.zero));
        positionChild(childId, Offset(xOffset, yOffset));
      }
    }
  }

  @override
  bool shouldRelayout(MyDelegate oldDelegate) {
    return !listEquals(ids, oldDelegate.ids);
  }
}
