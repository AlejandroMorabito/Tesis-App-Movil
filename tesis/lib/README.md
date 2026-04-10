# SISMO - Dashboard de Alarmas (Flutter)

Aplicación móvil Flutter equivalente a la página web del Dashboard de Alarmas, con las mismas funcionalidades y diseño.

## Estructura del Proyecto

```
lib/
├── main.dart                    # Entrada principal + AuthWrapper
├── services/
│   ├── auth_service.dart        # Login, logout, reset password, registro
│   └── database_service.dart    # Listeners en tiempo real, permisos, comandos, webhook
└── screens/
    ├── login_screen.dart        # Pantalla de login con gradiente púrpura
    ├── main_screen.dart         # Scaffold con sidebar + top bar + navegación
    ├── dashboard_screen.dart    # Resumen dispositivos, stat cards, estado detallado, eventos
    ├── valores_screen.dart      # Tarjetas en vivo por dispositivo con sensores
    ├── admin_screen.dart        # Panel admin: tabla usuarios, webhook, editar usuario
    ├── control_modal.dart       # Modal control de cercos, armar/desarmar, toggle sensores
    └── profile_screen.dart      # Perfil editable con cambio de contraseña
```

## Funcionalidades Implementadas

### Autenticación
- ✅ Login con Firebase Auth (email/password)
- ✅ Toggle visibilidad de contraseña (👁️/🙈)
- ✅ Recuperar contraseña por email
- ✅ Crear/actualizar usuario en Realtime Database al hacer login
- ✅ Verificación de estado de autenticación (AuthWrapper)

### Dashboard
- ✅ Resumen de dispositivos (stat cards): dispositivos, alarmas, sistemas, cercos
- ✅ Estado detallado por dispositivo con indicadores de conexión y cercos
- ✅ Vista diferente para admin (eventos del sistema) vs usuario normal
- ✅ Clic en dispositivo abre modal de control

### Valores en Vivo
- ✅ Grid de tarjetas por dispositivo con estado visual
- ✅ Indicadores de sensores C1-C5 con colores
- ✅ Calidad de señal WiFi
- ✅ Estado: ALARMA / INTRUSIÓN / ARMADO / DESARMADO
- ✅ Solo muestra dispositivos con acceso autorizado

### Control de Dispositivo (Modal)
- ✅ Toggle de cercos C1-C5
- ✅ Botón Activar/Desactivar Alarma
- ✅ Botón Armar/Desarmar Sistema
- ✅ Info de conexión: IP, MAC, señal, última conexión

### Panel de Administración (solo admin)
- ✅ Estadísticas: usuarios, admins, dispositivos, permisos
- ✅ Configuración de Webhook (Make/Wasend)
- ✅ Búsqueda de usuarios
- ✅ Tabla de usuarios con rol, estado, chips autorizados
- ✅ Editar usuario: nombre, teléfono, rol, estado, permisos de chips

### Perfil de Usuario
- ✅ Ver perfil con avatar, nombre, email, rol
- ✅ Editar nombre y teléfono
- ✅ Cambiar contraseña con validaciones
- ✅ Diseño oscuro (como el modal web original)

### Tiempo Real
- ✅ Listeners de Firebase para permisos, dispositivos, eventos
- ✅ Notificaciones push internas (SnackBars + badge)
- ✅ Auto-refresh cada 15 segundos
- ✅ Webhook de notificaciones a Make (WhatsApp/Email)

### Diseño
- ✅ Gradientes púrpura/índigo del diseño web original
- ✅ Sidebar fija en tablets, Drawer en móviles
- ✅ Top bar con avatar, nombre, email, botón logout
- ✅ Colores de estado: rojo (alarma), naranja (intrusión), verde (armado), gris (desarmado)
- ✅ Responsive: se adapta a distintos tamaños de pantalla

## Configuración

### 1. Crear proyecto Flutter
```bash
flutter create sismo_app
```

### 2. Copiar archivos
Reemplaza el contenido de `lib/` con los archivos de este proyecto.

### 3. Agregar dependencias
Copia el contenido de `pubspec.yaml` y ejecuta:
```bash
flutter pub get
```

### 4. Configurar Firebase
La configuración de Firebase ya está incluida en `main.dart`. Para Android/iOS nativos necesitas:

**Android:**
- Descarga `google-services.json` desde Firebase Console
- Colócalo en `android/app/`
- Agrega el plugin en `android/build.gradle` y `android/app/build.gradle`

**iOS:**
- Descarga `GoogleService-Info.plist` desde Firebase Console
- Agrégalo al proyecto Xcode

### 5. Ejecutar
```bash
flutter run
```

## Firebase Config (ya incluida)
```
apiKey: AIzaSyDpjVvSG1YqWCPpi7MG3vIHA70pIeQI6yQ
authDomain: tesis-270d3.firebaseapp.com
databaseURL: https://tesis-270d3-default-rtdb.firebaseio.com
projectId: tesis-270d3
```

## Notas
- La app usa el mismo backend Firebase que la versión web
- Los webhooks de Make funcionan igual que en la web
- Los permisos se gestionan desde el panel de administración
- Compatible con Android, iOS y Web (Flutter multiplataforma)
