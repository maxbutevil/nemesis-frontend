

import "package:flutter/material.dart";

class Tag extends StatefulWidget {
  
  final String content;
  final bool initialSelected;
  final bool initialToggleable;
  final Function(bool)? onToggle;
  
  const Tag(this.content, {
    this.initialSelected = false,
    this.initialToggleable = false,
    this.onToggle,
    super.key
  });
  
  static Widget list(Iterable<Tag> tags) {
    return Text.rich(
      TextSpan(
        children: tags.map((tag) => WidgetSpan(
          child: tag
        )).toList()
      )
    );
  }
  
  @override createState() => TagState();
  
}
  

class TagState extends State<Tag> {
  
  late bool selected;
  late bool toggleable;
  //late bool canSelect;
  //late bool canDeselect;
  
  
  static const highlightDuration = Duration(milliseconds: 60);
  static const highlightedTextColor = null;
  
  @override initState() {
    super.initState();
    selected = widget.initialSelected;
    toggleable = widget.initialToggleable;
  }
  
  void _toggle() {
    
    if (toggleable) {
      
      setState(() {
        
        selected = !selected;
        
        if (widget.onToggle != null) {
          widget.onToggle!(selected);
        }
        
      });
      
    }
    
  }
  
  @override build(BuildContext context) {
    
    return GestureDetector(
      
      onTap: _toggle,
      
      child: AnimatedContainer(
        
        duration: highlightDuration,
        decoration: BoxDecoration(
          color: selected ? 
            Colors.red[400] :
            Colors.black45,
          borderRadius: const BorderRadius.all(Radius.circular(5.0))
        ),
        
        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
        margin: const EdgeInsets.fromLTRB(0.0, 2.0, 4.0, 2.0),
        
        child: Text(widget.content)
        
      )
      
    );
    
  }
  
}


