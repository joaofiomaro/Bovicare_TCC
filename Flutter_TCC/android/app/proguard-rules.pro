# flutter_blue_plus: sem esta regra o R8 do build release remove campos
# usados pelo plugin e o scan falha (PlatformException ... not found).
-keep class com.lib.flutter_blue_plus.* { *; }
