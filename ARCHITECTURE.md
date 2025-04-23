# Arquitectura de OxiCloud Desktop Client

## Visión General

OxiCloud Desktop Client es una aplicación multiplataforma desarrollada con Flutter que sigue una arquitectura hexagonal (también conocida como arquitectura de puertos y adaptadores). Esta arquitectura permite una separación clara entre la lógica de negocio y las dependencias externas, facilitando el desarrollo, pruebas y mantenimiento.

## Principios Arquitectónicos

1. **Separación de Responsabilidades**: Cada capa tiene una responsabilidad específica y bien definida.
2. **Dependencias hacia el centro**: Las dependencias siempre apuntan hacia el centro (dominio).
3. **Aislamiento del dominio**: La lógica de negocio no depende de frameworks o tecnologías externas.
4. **Inversión de dependencias**: Las interfaces definen cómo interactúan las capas.
5. **Testabilidad**: Cada componente puede ser probado de forma aislada.

## Capas de la Arquitectura

### 1. Capa de Dominio (Núcleo)

El centro de la aplicación, contiene:

- **Entidades**: Representan los objetos del dominio y encapsulan los datos y comportamientos esenciales.
  - `File`, `Folder`, `User`, `Share`, etc.

- **Repositorios (interfaces)**: Definen cómo se accede y persisten las entidades.
  - `FileRepository`, `AuthRepository`, etc.

- **Servicios de dominio**: Contienen lógica de negocio que opera sobre múltiples entidades.
  - `PathService`, `SyncLogicService`, etc.

### 2. Capa de Aplicación

Orquesta el flujo de datos entre la capa de presentación y la capa de dominio:

- **Casos de uso**: Implementan operaciones específicas que la aplicación puede realizar.
  - `UploadFileUseCase`, `ListFolderContentsUseCase`, etc.

- **DTOs (Data Transfer Objects)**: Objetos que transportan datos entre capas.
  - `FileDTO`, `FolderDTO`, etc.

- **Puertos (interfaces)**: Definen cómo la capa de aplicación interactúa con el exterior.
  - Puertos de entrada: Permiten a la capa de presentación interactuar con la aplicación.
  - Puertos de salida: Definen cómo la aplicación interactúa con servicios externos.

### 3. Capa de Infraestructura

Proporciona implementaciones concretas para los puertos definidos en la capa de aplicación:

- **Adaptadores**: Implementan puertos para interactuar con servicios externos.
  - `WebDAVAdapter`, `RestApiAdapter`, etc.

- **Repositorios (implementaciones)**: Implementan las interfaces de repositorio definidas en el dominio.
  - `WebDAVFileRepository`, `SQLiteContactRepository`, etc.

- **Servicios técnicos**: Proporcionan funcionalidades técnicas específicas.
  - `NetworkService`, `StorageService`, `EncryptionService`, etc.

### 4. Capa de Presentación

Gestiona la interacción con el usuario:

- **Vistas (Pages/Screens)**: Interfaces de usuario completas.
  - `FileBrowserPage`, `SettingsPage`, etc.

- **Widgets**: Componentes de UI reutilizables.
  - `FileListItem`, `UploadProgressIndicator`, etc.

- **Gestores de estado**: Coordinan el estado de la aplicación y la UI.
  - `FileListProvider`, `AuthProvider`, etc.

## Flujo de Datos

1. **Solicitud de UI**: La capa de presentación solicita una acción a través de un caso de uso.
2. **Procesamiento**: La capa de aplicación procesa la solicitud utilizando la lógica de dominio.
3. **Acceso a datos**: Si es necesario, la capa de aplicación accede a los datos a través de puertos.
4. **Respuesta**: Los datos fluyen de vuelta a través de la capa de aplicación hacia la presentación.

## Gestión de Estado

- **Estado global**: Utilizando Provider/Riverpod para estado compartido entre pantallas.
- **Estado local**: Utilizando StatefulWidget/ValueNotifier para estado específico de cada widget.
- **Estado de sincronización**: Utilizando clases específicas para gestionar el estado de sincronización.

## Manejo de Errores

1. **Errores de dominio**: Definidos en la capa de dominio, representan errores de lógica de negocio.
2. **Errores de infraestructura**: Convertidos a errores de dominio en los adaptadores.
3. **Presentación de errores**: Traducidos a mensajes amigables en la capa de presentación.

## Optimización de Recursos

1. **Lazy loading**: Carga diferida de datos y recursos.
2. **Caché inteligente**: Estrategias de caché para reducir el uso de red y mejorar la velocidad.
3. **Liberación proactiva**: Liberación de recursos cuando no están en uso activo.
4. **Compresión**: Miniminización del uso de almacenamiento y red.

## Seguridad

1. **Almacenamiento seguro**: Credenciales y tokens almacenados de forma segura.
2. **Comunicación cifrada**: Toda la comunicación con el servidor mediante HTTPS.
3. **Autenticación robusta**: Implementación correcta de OAuth2/JWT.
4. **Validación de datos**: Validación en todas las capas para prevenir inyecciones y otros ataques.