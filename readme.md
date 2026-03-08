# DevConsole Portable

[Español](#devconsole-portable-español)

DevConsole Portable is a complete, isolated, and 100% portable development environment for Windows. It is designed to carry your favorite programming tools on a USB drive or external disk, without leaving a trace on the host operating system or cluttering its environment variables.

## Included Tools

I have selected and integrated my favorite development tools to cover almost any modern programming need:

* **Git:** Complete version control (includes Git Bash, Git CMD, and Git GUI).
* **Node.js:** JavaScript runtime environment (LTS version) with interactive `npm`.
* **Python (via uv):** Ultra-fast Python management using `uv` (written in Rust), allowing you to execute an interactive REPL instantly.
* **PHP:** Direct download of the latest stable version (Thread Safe x64) with interactive mode enabled.
* **Antigravity:** Our star code editor, perfectly integrated into the portable environment.

## How Antigravity works in portable mode

Unlike console tools that are downloaded as `.zip` files, Antigravity is installed unattended via `winget`. 

**Important note:** Although `winget` leaves a registry entry in Windows indicating that the application was processed, **Antigravity is installed and executed strictly from the portable directories** (`App` or `CommonFiles`). All its configuration, extensions, and user preferences are stored in an isolated way inside the `Data` folder of DevConsole. This guarantees that you can take your configured editor to any PC without losing absolutely anything.

## The Manager: InstallOrUpdate

The heart of this project is its interactive manager script. When executed, it presents a console menu that automates the maintenance of your entire ecosystem:

1. **Smart Installation:** Downloads tools directly from their official sources (GitHub APIs, NodeJS, PHP.net).
2. **Environment Selection (Scopes):** Allows you to decide exactly where each tool will live:
   * **App Portable:** Inside the application folder (ideal for standalone installations).
   * **Common Portable:** In the `CommonFiles` folder (ideal for sharing tools among multiple PortableApps applications).
   * **Use Current Installation (System):** Does not download anything, just creates smart `.exe` launchers that act as a bridge to the programs you already have installed on your local PC.
3. **Safe Updates:** Compares local versions with the latest internet versions. When updating complex tools like Antigravity, **it makes an automatic backup of your `Data` folder**, updates the core program, and restores your configurations so you don't lose a single comma.
4. **Clean Uninstall:** Tracks portable directories and allows you to remove any tool with a single number, keeping your environment free of junk.

## Advantages of using DevConsole Portable

* **Zero host OS clutter:** Forget about version conflicts. The `PATH` and variables like `HOME`, `APPDATA`, or `USERPROFILE` are injected at runtime in an isolated way. When you close the console, the host PC remains untouched.
* **Smart Master Launchers:** In the root folder, you will find clean executables (`GitBash.exe`, `NodeJS.exe`, `Antigravity.exe`). When you double-click them, an internal script automatically searches for where you installed the tool (in `App`, `CommonFiles`, or if you are using the System one) and runs it instantly.
* **Plug & Play:** Plug in your drive, open your console, and all your commands (`node`, `git`, `uv`, `php`) will work immediately without requiring prior installations or administrator permissions.

## How to start

1. Open the update manager (`Update.cmd` or `InstallOrUpdate`).
2. Go to the menu **1. Install / Setup Tools**.
3. Select the tools you want and the destination (App or Common).
4. Go back to the root of your folder, double-click the newly generated launchers, and start programming!

---

# DevConsole Portable (Español)

[English](#devconsole-portable)

DevConsole Portable es un entorno de desarrollo completo, aislado y 100% portable para Windows. Está diseñado para llevar tus herramientas de programación favoritas en una memoria USB o disco externo, sin dejar rastro en el sistema operativo anfitrión ni ensuciar sus variables de entorno.

## Herramientas Incluidas

He seleccionado e integrado mis herramientas de desarrollo favoritas para cubrir casi cualquier necesidad de programación moderna:

* **Git:** Control de versiones completo (incluye Git Bash, Git CMD y Git GUI).
* **Node.js:** Entorno de ejecución de JavaScript (versión LTS) con `npm` interactivo.
* **Python (vía uv):** Gestión ultra-rápida de Python usando `uv` (escrito en Rust), permitiendo ejecutar REPL interactivo al instante.
* **PHP:** Descarga directa de la última versión estable (Thread Safe x64) con modo interactivo habilitado.
* **Antigravity:** Nuestro editor de código estrella, integrado perfectamente en el entorno portable.

## Cómo funciona Antigravity en modo portable

A diferencia de las herramientas de consola que se descargan en formato `.zip`, la instalación de Antigravity se realiza de forma desatendida a través de `winget`. 

**Nota importante:** Aunque `winget` deja un registro en Windows de que la aplicación fue procesada, **Antigravity se instala y ejecuta estrictamente desde los directorios portables** (`App` o `CommonFiles`). Toda su configuración, extensiones y preferencias de usuario se guardan de forma aislada en la carpeta `Data` de DevConsole. Esto garantiza que puedas llevar tu editor configurado a cualquier PC sin perder absolutamente nada.

## El Gestor: InstallOrUpdate

El corazón de este proyecto es su script gestor interactivo. Al ejecutarlo, te presentará un menú en consola que automatiza el mantenimiento de todo tu ecosistema:

1. **Instalación Inteligente:** Descarga las herramientas directamente desde sus fuentes oficiales (APIs de GitHub, NodeJS, PHP.net).
2. **Selección de Entorno (Scopes):** Te permite decidir exactamente dónde vivirá cada herramienta:
   * **App Portable:** Dentro de la carpeta de la aplicación (ideal para instalaciones únicas).
   * **Common Portable:** En la carpeta `CommonFiles` (ideal para compartir herramientas entre múltiples aplicaciones de PortableApps).
   * **Usar Instalación Actual (Sistema):** No descarga nada, solo crea lanzadores `.exe` inteligentes que funcionan como puente hacia los programas que ya tengas instalados en tu PC local.
3. **Actualizaciones Seguras:** Compara las versiones locales con las últimas versiones de internet. Al actualizar herramientas complejas como Antigravity, **realiza un backup automático de tu carpeta `Data`**, actualiza el núcleo del programa y restaura tus configuraciones para que no pierdas ni una coma.
4. **Desinstalación Limpia:** Rastrea los directorios portables y te permite eliminar cualquier herramienta con un solo número, manteniendo tu entorno libre de basura.

## Ventajas de usar DevConsole Portable

* **Cero basura en el OS Anfitrión:** Olvídate de conflictos de versiones. El `PATH` y variables como `HOME`, `APPDATA` o `USERPROFILE` son inyectadas en tiempo de ejecución de forma aislada. Cuando cierras la consola, el PC anfitrión queda intacto.
* **Lanzadores Maestros Inteligentes:** En la raíz encontrarás ejecutables limpios (`GitBash.exe`, `NodeJS.exe`, `Antigravity.exe`). Al darles doble clic, un script interno busca automáticamente dónde instalaste la herramienta (en `App`, `CommonFiles` o si estás usando la del Sistema) y la ejecuta al instante.
* **Plug & Play:** Conecta tu disco, abre tu consola, y todos tus comandos (`node`, `git`, `uv`, `php`) funcionarán de inmediato sin requerir instalaciones previas ni permisos de administrador.

## Cómo empezar

1. Abre el gestor de actualizaciones (`Update.cmd` o `InstallOrUpdate`).
2. Ve al menú **1. Install / Setup Tools**.
3. Selecciona las herramientas que deseas y el destino (App o Common).
4. Vuelve a la raíz de tu carpeta, haz doble clic en los nuevos lanzadores generados y ¡comienza a programar!