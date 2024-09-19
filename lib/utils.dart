

//export "./classes/state.dart";
//export "./setget.dart";

import "package:flutter/material.dart";

//export "package:flutter/material.dart";

/*
extension ColumnOf on Column {
  
  Column of(List<Widget> children) {
    return Column(children: children);
  }
  Column wide(List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
  
  
}
extension RowOf on Row {
  
  Row of(List<Widget> children) {
    return Row(children: children);
  }
  
}
*/

class Globals {
  
  static final navigatorKey = GlobalKey<NavigatorState>();
  static NavigatorState? get navigatorState => navigatorKey.currentState;
  
  

  static const routes = (
    
    auth: "auth",
    login: "login",
    register: "register",
    
    home: "/",
    pages: (
      settings: "settings",
      profile: "profile",
      match: "match",
      chat: "chat"
    ),
    
  );
  
  static const profilePhotoAspectRatio = 0.8;
  
}

typedef Builder<T> = Widget Function(BuildContext, T);

/*
class SignalBuilder<T> extends StatefulWidget {
  
  final Signal<T> signal;
  final Builder<T?> builder;
  
  final T? initialValue;
  
  const SignalBuilder({
    required this.signal,
    required this.builder,
    this.initialValue,
    super.key
  });
  
  @override createState() => SignalBuilderState<T>();
  
}
class SignalBuilderState<T> extends State<SignalBuilder<T>> {
  
  SignalBuilderState({ this.data });
  
  Signal<T> get signal => widget.signal;
  Builder<T?> get builder => widget.builder;
  
  T? data;
  
  @override build(BuildContext context) {
    return builder(context, data);
  }
  @override initState() {
    super.initState();
    data = widget.initialValue;
    signal.listen(_update);
  }
  @override dispose() {
    super.dispose();
    signal.drop(_update);
  }
  
  void _update(T newData) {
    data = newData;
  }
  
}
*/

class Signal<T> {
  
  final List<void Function(T)> _listeners = [];
  
  Signal();
  
  void emit(T data) {
    for (var listener in _listeners) {
      listener(data);
    }
  }
  
  void listen(void Function(T) listener) {
    _listeners.add(listener);
  }
  void drop(void Function(T) listener) {
    _listeners.remove(listener);
  }
  
  void Function() subscribe(void Function(T) listener) {
    listen(listener);
    return () { drop(listener); };
  }
  
}
class Observable<T> extends Signal<T> {
  
  T data;
  
  Observable(this.data);
  
  T get() => data;
  void set(T newData) {
    data = newData;
    update();
  }
  void update([ void Function(T)? callback ]) {
    if (callback != null) { callback(data); }
    emit(data);
  }
  void mutate([ T Function(T)? callback ]) {
    if (callback != null) { data = callback(data); }
    emit(data);
  }
  
}
class SignalBuilder<T> extends StatefulWidget {
  
  final Signal<T> signal;
  final Builder<T?> builder;
  
  const SignalBuilder({
    required this.signal,
    required this.builder,
    super.key
  });
  
  @override createState() => SignalBuilderState<T>();
  
}
class SignalBuilderState<T> extends State<SignalBuilder<T>> {
  
  T? data;
  
  SignalBuilderState();
  
  Signal<T> get signal => widget.signal;
  Builder<T?> get builder => widget.builder;
  
  @override build(BuildContext context) {
    return builder(context, data);
  }
  @override initState() {
    super.initState();
    signal.listen(_update);
  }
  @override dispose() {
    super.dispose();
    signal.drop(_update);
  }
  
  void _update(T newData) {
    setState(() { data = newData; });
  }
  
}
class ObservableBuilder<T> extends StatefulWidget {
  
  final Observable<T> value;
  final Builder<T> builder;
  
  const ObservableBuilder({
    required this.value,
    required this.builder,
    super.key
  });
  
  @override createState() => ObservableBuilderState<T>();
  
}
class ObservableBuilderState<T> extends State<ObservableBuilder<T>> {
  
  ObservableBuilderState();
  
  Observable<T> get value => widget.value;
  Builder<T> get builder => widget.builder;
  
  @override build(BuildContext context) {
    return builder(context, value.get());
  }
  @override initState() {
    super.initState();
    value.listen(_update);
  }
  @override dispose() {
    super.dispose();
    value.drop(_update);
  }
  
  void _update(T data) {
    setState(() {});
  }
  
}



/*
class Signal<T> {
  
  static const disconnect = -1;
  
  List<Function(T)> callbacks;
  
  Signal();
  
  
  
  
}
*/


extension ToStringList on List {
  
  List<String> toStringList() {
    return map((value) => value.toString()).toList();
  }
  
}


T extract<T>(Object? value) {
  return value is T ? value : throw Exception("Extraction error");
}
T extractOr<T>(Object? value, T fallback) {
  return value is T ? value : fallback;
}
T? extractOrNull<T>(Object? value) {
  return value is T ? value : null;
}
Iterable<T> extractAll<T>(Object? value) {
  
  if (value is! List) {
    throw Exception("List extraction error");
  } else {
    return value.map(extract<T>);
  }
  
}
Iterable<T> extractAllOrNull<T>(Object? value) {
  
  if (value is! List) {
    return const Iterable.empty();
  } else {
    return value.map(extractOrNull<T>).whereType<T>();
    // for unknowable reasons, nonNulls has forsaken me, so whereType<T> it is
  }
  
}
/*
T extractCustomOrNull<T>() {
  
}
*/
Iterable<T> extractAllCustom<T>(Object? value, T Function(Object?) method) {
  
  if (value is! List) {
    throw Exception("Custom list extraction error");
  } else {
    return value.map(method);
  }
  
}


/*
List<String> toStringList(dynamic list) {
  
}

*/


/*
extension ListWithoutNulls<T> on List<T?> {
  
  List<T> withoutNulls() {
    return 
  }
  
}
*/
extension StripNulls<K, V> on Map<K, V?> {
  
  Map<K, V> withoutNulls() {
    
    Map<K, V> filtered = {};
    
    for (var MapEntry(:key, :value) in entries) {
      if (value != null) {
        filtered[key] = value;
      }
    }
    
    return filtered;
    
  }
  
}

extension At<T> on List<T> {
  
  bool containsIndex(int i) => (i >= 0 && i < length);
  T? atOrNull(int i) => containsIndex(i) ? this[i] : null;
  
}

/*
extension on Map<String, Object> {
  
  Map<String, Object> delta(Map<String, Object> old) {
    
    
    
  }
  
}
*/

/*
extension FutureExtension on Future {
  
  Future<List<T>> waitOrdered<T>(List<Future<T>> futures) async {
    
    List<T> output = [];
    int remaining = futures.length;
    
    final future = Future<List<T>>();
    
    Futures.wait
    
    return output;
    
    for (int i = 0; i < futures.length; i++) {
      
      () async {
        output[i] = (await futures[i]);
      }();
      
    }
    
    
  }
  
  
}
*/
 
/*
Map<K, V> stripNulls<K, V>(Map<K, V?> map) {
  
  Map<K, V> newMap = {};
  
  for (var MapEntry(:key, :value) in map.entries) {
    if (value != null) {
      newMap[key] = value;
    }
  }
  
  return newMap;
  
}
*/

/*
R use<T, R>(T? value, Function(T) callback) {
  
}
*/

Route<dynamic>? Function(RouteSettings) useRouteMap(Map<String, Function(BuildContext, dynamic)> map) {
  

  
  return (RouteSettings settings) {
    
    if (map.containsKey(settings.name)) {
      return MaterialPageRoute(builder: (ctx) {
        return map[settings.name]!(ctx, settings.arguments);
      });
    }
    
    return null;
    
  };
  
}

