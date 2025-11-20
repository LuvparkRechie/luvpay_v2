import 'package:flutter/material.dart';

class CustomExpandableItem extends StatefulWidget {
  final String title;
  final Widget? leading;
  final IconData? trailingIcon;
  final Function? trailTap;
  final List<Widget> children;

  const CustomExpandableItem(
      {required this.title,
      required this.children,
      this.leading,
      this.trailingIcon,
      this.trailTap});

  @override
  _CustomExpandableItemState createState() => _CustomExpandableItemState();
}

class _CustomExpandableItemState extends State<CustomExpandableItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: widget.leading != null
              ? null
              : () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
          child: ListTile(
            leading: widget.leading != null
                ? GestureDetector(
                    onTap: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    child: Icon(
                      _isExpanded
                          ? Icons.check_circle_outline
                          : Icons.circle_outlined,
                      color: _isExpanded ? Colors.green : Colors.grey,
                      size: 20,
                    ),
                  )
                : null,
            title: Text(widget.title),
            trailing: widget.trailingIcon != null
                ? _isExpanded
                    ? InkWell(
                        onTap: () {
                          widget.trailTap!();
                        },
                        child: Icon(widget.trailingIcon))
                    : Icon(
                        Icons.arrow_drop_down,
                      )
                : Icon(
                    _isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  ),
          ),
        ),
        AnimatedSize(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: _isExpanded
              ? Column(children: widget.children)
              : SizedBox.shrink(), // Empty widget when collapsed
        ),
      ],
    );
  }
}
