# LockerScan — W10

## Qué hay de nuevo respecto a W9

| Fichero | Cambio |
|---------|--------|
| `lib/app.dart` | `home:` ahora apunta a `MainScreen()` en vez de `HomeScreen()` |
| `lib/screens/main_screen.dart` | **NUEVO** — `BottomNavigationBar` con 4 tabs |
| `lib/screens/home_screen.dart` | `StatelessWidget` → `StatefulWidget` con ciclo de vida completo |
| Resto de pantallas | Añadido `Logger` y ciclo de vida (`initState`, `dispose`) |

## Cómo actualizar en Android Studio

1. Reemplaza **toda la carpeta `lib/`** con la de este ZIP
2. Reemplaza `pubspec.yaml` (sin cambios esta semana, pero por si acaso)
3. Terminal → `flutter pub get`
4. ▶ Run

## Estructura completa

```
lib/
├── main.dart                 # igual que W9
├── app.dart                  # ← apunta a MainScreen
├── core/
│   └── constants.dart        # igual que W9
├── models/
│   └── scan_record.dart      # igual que W9
└── screens/
    ├── main_screen.dart      # ← NUEVO: BottomNav + IndexedStack
    ├── home_screen.dart      # ← StatefulWidget + ciclo de vida
    ├── collection_screen.dart
    ├── map_screen.dart
    └── settings_screen.dart
```

## Conceptos del snippet W10 aplicados

- **BottomNavigationBar** con `type: fixed` (obligatorio con 4+ tabs)
- **IndexedStack** en lugar de `elementAt()`: mantiene el estado de
  cada pantalla al cambiar de tab (el scroll no se resetea)
- **StatefulWidget** completo con `initState`, `didChangeDependencies`,
  `didUpdateWidget` y `dispose`
- **Logger** activo en todas las pantallas para ver el ciclo de vida
  en el panel de debug de Android Studio

## Próxima semana (W11)

Descomenta en `pubspec.yaml`:
```yaml
shared_preferences: ^2.2.2
geolocator: ^11.0.0
path_provider: ^2.0.9
fluttertoast: ^8.0.8
```
Y ejecuta `flutter pub get`.
