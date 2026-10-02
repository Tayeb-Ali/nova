// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get searchEmpty => 'Sin resultados';

  @override
  String get searchPrompt => 'Busca en el proyecto activo arriba';

  @override
  String get commandPaletteEmpty => 'Sin resultados';

  @override
  String get navProjects => 'Proyectos';

  @override
  String get navEditor => 'Editor';

  @override
  String get navPackagesSdk => 'SDK';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get actionOpen => 'Abrir';

  @override
  String get actionSave => 'Guardar';

  @override
  String get actionCancel => 'Cancelar';

  @override
  String get actionDelete => 'Eliminar';

  @override
  String get actionCreate => 'Crear';

  @override
  String get actionRetry => 'Reintentar';

  @override
  String get actionExit => 'Exit';

  @override
  String get appExitTitle => 'Exit Nova?';

  @override
  String get appExitBody => 'Press Exit to close the app.';

  @override
  String get actionClose => 'Cerrar';

  @override
  String get actionRestore => 'Restaurar';

  @override
  String get actionDiscard => 'Descartar';

  @override
  String get actionSearch => 'Buscar';

  @override
  String get actionImport => 'Importar';

  @override
  String get actionExport => 'Exportar';

  @override
  String get actionCopy => 'Copiar';

  @override
  String get actionShare => 'Compartir';

  @override
  String get projectsWorkspaceStats => 'Estadísticas del espacio de trabajo';

  @override
  String get projectsOpenFolder => 'Abrir carpeta';

  @override
  String get projectsOpenFile => 'Abrir archivo';

  @override
  String get projectsCloneGit => 'Clonar repositorio git';

  @override
  String get projectsNewProject => 'Nuevo proyecto';

  @override
  String get projectsRecentProjects => 'Proyectos recientes';

  @override
  String get projectsRecentFiles => 'Archivos recientes';

  @override
  String get projectsTipsTitle => 'Consejos';

  @override
  String get projectsTipOrganize =>
      'Mantén una carpeta por proyecto para cambiar más rápido.';

  @override
  String get settingsAppearance => 'Apariencia';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsEditor => 'Editor';

  @override
  String settingsFontSize(String size) {
    return 'Tamaño de fuente: $size';
  }

  @override
  String get settingsAi => 'IA';

  @override
  String get settingsTimeout => 'Tiempo de espera';

  @override
  String get themeNovaDark => 'Nova oscuro';

  @override
  String get themeNovaLight => 'Nova claro';

  @override
  String get actionRun => 'Ejecutar';

  @override
  String get actionStop => 'Detener';

  @override
  String get actionRefresh => 'Actualizar';

  @override
  String get actionRename => 'Renombrar';

  @override
  String get actionInstall => 'Instalar';

  @override
  String get actionUpdate => 'Actualizar';

  @override
  String get actionUninstall => 'Desinstalar';

  @override
  String commonError(String error) {
    return 'Error: $error';
  }

  @override
  String commonCreateFailed(String error) {
    return 'No se pudo crear: $error';
  }

  @override
  String commonDeleteFailed(String error) {
    return 'No se pudo eliminar: $error';
  }

  @override
  String commonRenameFailed(String error) {
    return 'No se pudo renombrar: $error';
  }

  @override
  String get projectsProjectNameHint => 'Nombre del proyecto';

  @override
  String get projectsDeleteTitle => '¿Eliminar proyecto?';

  @override
  String projectsDeleteMessage(String name) {
    return '¿Eliminar \'$name\' y todos sus archivos?';
  }

  @override
  String get projectsSearchHint => 'Buscar proyectos...';

  @override
  String get projectsStatusUnavailable => 'Estado del entorno no disponible';

  @override
  String get projectsSetupNeeded => 'El entorno necesita configuración';

  @override
  String get projectsRuntimeReady => 'Entorno listo';

  @override
  String get projectsOpenEditor => 'Abrir editor';

  @override
  String get projectsDeleteProject => 'Eliminar proyecto';

  @override
  String get projectsEmptyTitle => 'Aún no hay proyectos';

  @override
  String get projectsTipsBody =>
      'Toca un proyecto para abrirlo en el editor. Usa la pestaña SDK para instalar entornos antes de crear proyectos de Node o Python.';

  @override
  String get editorEmptyHint => 'Abre un archivo desde el explorador';

  @override
  String editorSaveFailed(String error) {
    return 'No se pudo guardar: $error';
  }

  @override
  String editorSaved(String name) {
    return '$name guardado';
  }

  @override
  String editorOpenFailed(String error) {
    return 'No se pudo abrir el archivo: $error';
  }

  @override
  String get explorerNewFile => 'Nuevo archivo';

  @override
  String get explorerNewNameHint => 'Nuevo nombre';

  @override
  String get explorerDeleteTitle => '¿Eliminar?';

  @override
  String explorerDeleteMessage(String name) {
    return '¿Eliminar $name?';
  }

  @override
  String get explorerSelectProject => 'Selecciona un proyecto';

  @override
  String get explorerEmptyFolder => 'Carpeta vacía';

  @override
  String runStartFailed(String error) {
    return 'No se pudo iniciar la tarea: $error';
  }

  @override
  String get runNoTasks => 'No se detectaron tareas';

  @override
  String get runHideConsole => 'Ocultar consola';

  @override
  String get runShowConsole => 'Mostrar consola';

  @override
  String get runEmptyHint =>
      'Pulsa Ejecutar para correr la tarea seleccionada. La salida aparece aquí.';

  @override
  String get gitTitle => 'Git';

  @override
  String get gitCommit => 'Commit';

  @override
  String get gitCommitMessage => 'Mensaje del commit';

  @override
  String get gitCommitted => 'Commit realizado';

  @override
  String gitCommitFailed(String error) {
    return 'Falló el commit: $error';
  }

  @override
  String get gitStageAll => 'Añadir todo';

  @override
  String get gitStagedAll => 'Cambios añadidos';

  @override
  String gitStageFailed(String error) {
    return 'No se pudo añadir: $error';
  }

  @override
  String get gitStage => 'Añadir';

  @override
  String gitStagedFile(String file) {
    return '$file añadido';
  }

  @override
  String get gitBranches => 'Ramas';

  @override
  String get gitCheckout => 'Cambiar a';

  @override
  String get gitCreateBranch => 'Nueva rama';

  @override
  String get gitBranchNameHint => 'Nombre de la rama';

  @override
  String gitDeleteBranchConfirm(String name) {
    return '¿Eliminar la rama \'$name\'?';
  }

  @override
  String gitBranchActionFailed(String error) {
    return 'Falló la acción de rama: $error';
  }

  @override
  String get gitNoBranches => '(sin ramas)';

  @override
  String get gitStash => 'Stash';

  @override
  String get gitStashSave => 'Guardar cambios en stash';

  @override
  String get gitStashMessage => 'Mensaje del stash';

  @override
  String get gitStashed => 'Cambios guardados en stash';

  @override
  String gitStashActionFailed(String error) {
    return 'Falló la acción de stash: $error';
  }

  @override
  String get gitRemote => 'Remoto (SSH)';

  @override
  String get gitClone => 'Clonar';

  @override
  String get gitCloneUrl => 'URL del repositorio (SSH)';

  @override
  String get gitCloneDir => 'Directorio de destino';

  @override
  String get gitCloned => 'Clonado correctamente';

  @override
  String get gitFetch => 'Fetch';

  @override
  String get gitFetched => 'Fetch completado';

  @override
  String get gitPull => 'Pull';

  @override
  String get gitPulled => 'Pull completado';

  @override
  String get gitPush => 'Push';

  @override
  String get gitPushed => 'Push completado';

  @override
  String gitRemoteFailed(String error) {
    return 'Falló la operación remota: $error';
  }

  @override
  String get gitSshKey => 'Clave pública SSH de la app';

  @override
  String get gitSshNoKey =>
      'Aún no hay clave: genera una y añádela a tu cuenta de hosting.';

  @override
  String get gitSshGenerate => 'Generar clave';

  @override
  String get gitSshCopy => 'Copiar';

  @override
  String get gitSshCopied =>
      'Clave pública copiada: añádela en las claves SSH de tu cuenta';

  @override
  String get gitStashEmpty => '(sin cambios en stash)';

  @override
  String get gitStashPop => 'Aplicar';

  @override
  String get gitStashDrop => 'Descartar';

  @override
  String get terminalTitle => 'Terminal';

  @override
  String get terminalNewSession => 'Nueva sesión';

  @override
  String get terminalStartFailed => 'No se pudo iniciar la sesión de terminal';

  @override
  String get processTitle => 'Procesos';

  @override
  String get processRunHint => 'Ejecutar comando… p. ej. npm run dev';

  @override
  String get processEmpty =>
      'No hay procesos en ejecución.\nInicia una tarea para verla aquí.';

  @override
  String get runtimeTitle => 'Entorno';

  @override
  String get runtimeBootstrap => 'Bootstrap';

  @override
  String get runtimeStartSetup => 'Iniciar configuración';

  @override
  String get runtimeInstalled => 'Instalado';

  @override
  String get runtimeAvailable => 'Disponible';

  @override
  String runtimeUninstallConfirm(String name) {
    return '¿Desinstalar $name?';
  }

  @override
  String get runtimeEmpty => 'No hay entornos disponibles.';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get themeFollowSystem => 'Según el sistema';

  @override
  String get toolsShow => 'Mostrar herramientas';

  @override
  String get toolsHide => 'Ocultar herramientas';

  @override
  String get toolbarShow => 'Mostrar barra';

  @override
  String get toolbarHide => 'Ocultar barra';

  @override
  String get explorerShow => 'Mostrar explorador';

  @override
  String get explorerHide => 'Ocultar explorador';

  @override
  String get projectNew => 'Nuevo proyecto';

  @override
  String get projectNameHint => 'Nombre del proyecto';

  @override
  String get projectDelete => 'Eliminar proyecto';

  @override
  String get projectDeleteTitle => '¿Eliminar proyecto?';

  @override
  String projectDeleteBody(String name) {
    return '¿Eliminar \'$name\' y todos sus archivos?';
  }

  @override
  String get workspaceEmpty => 'Aún no hay proyectos';

  @override
  String get workspaceTitle => 'Espacio de trabajo';

  @override
  String get toolTerminal => 'Terminal';

  @override
  String get toolGit => 'Git';

  @override
  String get toolProcesses => 'Procesos';

  @override
  String get projectSelect => 'Seleccionar proyecto';

  @override
  String get projectsHintTemplate => 'Empezar desde una plantilla';

  @override
  String get projectsHintContinue => 'Seguir trabajando';

  @override
  String get projectsHintReload => 'Recargar lista de proyectos';

  @override
  String get projectsHintRemoveActive => 'Quitar proyecto activo';

  @override
  String projectsFilterAll(int count) {
    return 'Todos ($count)';
  }

  @override
  String projectsCount(int count) {
    return '$count proyectos';
  }

  @override
  String get editorEdit => 'Editar';

  @override
  String get editorPreview => 'Vista previa';

  @override
  String get editorTabActions => 'Acciones de pestaña';

  @override
  String get editorReloadConfirmTitle => '¿Recargar archivo?';

  @override
  String get editorReloadConfirmBody =>
      '¿Descartar los cambios sin guardar y recargar desde el disco?';

  @override
  String editorReloaded(String name) {
    return '$name recargado';
  }

  @override
  String get editorRecoverTitle => 'Cambios sin guardar encontrados';

  @override
  String editorRecoverBody(String name) {
    return '¿Restaurar los cambios sin guardar de $name?';
  }

  @override
  String get editorCloseDirtyTitle => '¿Cerrar sin guardar?';

  @override
  String editorCloseDirtyBody(String name) {
    return '¿Descartar los cambios sin guardar de $name?';
  }

  @override
  String get editorFocusEnter => 'Modo enfoque';

  @override
  String get editorFocusExit => 'Salir del modo enfoque';

  @override
  String get explorerTitle => 'EXPLORADOR';

  @override
  String get explorerGoUp => 'Subir';

  @override
  String get runClearOutput => 'Limpiar salida';

  @override
  String get runStartingProcess => 'Iniciando proceso…';

  @override
  String get gitProject => 'Proyecto';

  @override
  String get gitOpenProject => 'Abrir proyecto';

  @override
  String get gitSelectProject => 'Seleccionar proyecto';

  @override
  String get gitProjectPath => 'Ruta del proyecto';

  @override
  String get gitStatus => 'Estado';

  @override
  String get gitDiff => 'Diff';

  @override
  String get gitUnavailable => 'Git no disponible';

  @override
  String gitBranch(String branch) {
    return 'Rama: $branch';
  }

  @override
  String get gitModified => 'Modificados';

  @override
  String get gitAdded => 'Añadidos';

  @override
  String get gitDeleted => 'Eliminados';

  @override
  String get gitUntracked => 'Sin seguimiento';

  @override
  String get gitEmptyDiff => '(diff vacío)';

  @override
  String get terminalPaste => 'Pegar';

  @override
  String terminalSessionExited(int code) {
    return 'Sesión terminada (código $code)';
  }

  @override
  String get terminalKeyTab => 'Tab';

  @override
  String get terminalKeyEsc => 'Esc';

  @override
  String get terminalKeyUp => 'Arriba';

  @override
  String get terminalKeyDown => 'Abajo';

  @override
  String get terminalKeyLeft => 'Izq.';

  @override
  String get terminalKeyRight => 'Der.';

  @override
  String processStarted(String pid, String command) {
    return 'Iniciado $pid · $command';
  }

  @override
  String get processStartedByNova => 'Iniciado por Nova';

  @override
  String get runtimeReady => 'Listo';

  @override
  String get runtimeBootstrapReady =>
      'Bootstrap está listo. Puedes instalar entornos abajo.';

  @override
  String get bootstrapRequired => 'Entorno requerido';

  @override
  String get bootstrapRequiredBody =>
      'El entorno Linux no está instalado. ¿Descargarlo ahora para usar la terminal y los entornos de lenguaje?';

  @override
  String get actionDownload => 'Descargar';

  @override
  String get actionLater => 'Más tarde';

  @override
  String get runtimeBootstrapUnavailable =>
      'Estado de bootstrap no disponible.';

  @override
  String get runtimeBootstrapNotInstalled => 'Bootstrap aún no está instalado.';

  @override
  String runtimeVersion(String version) {
    return 'Versión: $version';
  }

  @override
  String get runtimeSetupFailed => 'Falló la configuración';

  @override
  String get aiTitle => 'Acciones de IA';

  @override
  String get aiKeySaved => 'Clave guardada';

  @override
  String get aiEnterKeyFirst => 'Ingresa primero una clave API';

  @override
  String get aiNoCode => 'Sin código seleccionado';

  @override
  String get aiExplainCode => 'Explicar código';

  @override
  String get aiFixError => 'Corregir error';

  @override
  String get aiCompleteCode => 'Completar código';

  @override
  String get aiStop => 'Detener';

  @override
  String get aiInsert => 'Insertar en el editor';

  @override
  String aiPromptExplain(String code) {
    return 'Explica el siguiente código:\n$code';
  }

  @override
  String aiPromptFix(String code) {
    return 'Corrige el error en el siguiente código:\n$code';
  }

  @override
  String aiPromptComplete(String code) {
    return 'Completa el siguiente código:\n$code';
  }

  @override
  String get settingsSystem => 'Sistema';

  @override
  String settingsRunTimeout(int ms) {
    return 'Tiempo de ejecución: $ms ms';
  }

  @override
  String get settingsTimeoutLabel => 'Tiempo de espera (ms, 1000-120000)';

  @override
  String get settingsAutocomplete => 'Autocompletado';

  @override
  String get settingsAutocompleteSub =>
      'Sugerencias de palabras clave, fragmentos y palabras al escribir';

  @override
  String get settingsAiCompletion => 'Autocompletado con IA';

  @override
  String get settingsAiCompletionSub =>
      'Sugerencias del modelo en el menú de autocompletado';

  @override
  String get settingsMatchTheme => 'Igualar app al tema del editor';

  @override
  String get settingsMatchThemeSub =>
      'Toda la app sigue los colores del tema del editor';

  @override
  String get settingsWordWrap => 'Ajuste de línea';

  @override
  String get settingsWordWrapSub =>
      'Ajustar líneas largas en vez de desplazar lateralmente';

  @override
  String get settingsAutoSave => 'Guardado automático';

  @override
  String get settingsAutoSaveSub => 'Guarda 1,5 s después de dejar de escribir';

  @override
  String get settingsEditorFont => 'Fuente del editor';

  @override
  String get settingsFontInstalled => 'Fuente instalada';

  @override
  String get settingsFontUpdated => 'Fuente del editor actualizada';

  @override
  String get settingsDownloadFailed => 'Falló la descarga: revisa la conexión';

  @override
  String get settingsLivePreview => 'Vista previa en vivo';

  @override
  String get settingsProvider => 'Proveedor';

  @override
  String get settingsCustomProvider => 'Personalizado (compatible con OpenAI)';

  @override
  String get settingsBaseUrl => 'URL base (compatible con OpenAI)';

  @override
  String get settingsModel => 'Modelo';

  @override
  String get settingsApiKey => 'Clave API';

  @override
  String get settingsApiKeySaved => 'Guardada en almacenamiento seguro';

  @override
  String get settingsApiKeyHint => 'Pega tu clave';

  @override
  String get settingsKeySecureNote =>
      'La clave se guarda en almacenamiento seguro cifrado, nunca en ajustes sin cifrar.';

  @override
  String get settingsTestConnection => 'Probar conexión';

  @override
  String get settingsTesting => 'Probando…';

  @override
  String get settingsSaved => 'Ajustes guardados';

  @override
  String settingsConnected(String reply) {
    return 'Conectado: $reply';
  }

  @override
  String settingsConnectionFailed(String error) {
    return 'Falló la conexión: $error';
  }

  @override
  String settingsThemeImported(String name) {
    return 'Tema \"$name\" importado';
  }

  @override
  String settingsImportFailed(String error) {
    return 'Falló la importación: $error';
  }

  @override
  String settingsThemeCopied(String name) {
    return 'JSON del tema \"$name\" copiado';
  }

  @override
  String settingsThemeExported(String name) {
    return 'Tema \"$name\" exportado al portapapeles';
  }

  @override
  String get settingsImportTheme => 'Importar JSON de tema';

  @override
  String get settingsCopyTheme => 'Copiar JSON de tema';

  @override
  String get settingsExportTheme => 'Exportar tema';

  @override
  String get settingsDeleteTheme => 'Eliminar tema';

  @override
  String get searchTitle => 'Buscar en el proyecto';

  @override
  String get searchHint => 'Buscar texto o patrón…';

  @override
  String get searchReplaceHint => 'Reemplazar con…';

  @override
  String get searchMatchCase => 'Distinguir mayúsculas';

  @override
  String get searchUseRegex => 'Usar expresión regular';

  @override
  String get searchButton => 'Buscar';

  @override
  String searchButtonCount(int hits) {
    return 'Buscar ($hits)';
  }

  @override
  String get searchReplaceAll => 'Reemplazar todo';

  @override
  String get searchNoProject => 'Ningún proyecto abierto';

  @override
  String get searchTypeSomething => 'Escribe algo para buscar';

  @override
  String get searchInvalidRegex => 'Expresión regular no válida';

  @override
  String searchFailed(String error) {
    return 'Falló la búsqueda: $error';
  }

  @override
  String get searchEmptyHint => 'Busca en el proyecto activo arriba';

  @override
  String get searchNoMatches => 'Sin resultados';

  @override
  String get searchTruncated =>
      'Mostrando solo los primeros resultados (límites alcanzados)';

  @override
  String searchReplaceCount(int count) {
    return 'Reemplazar ($count)';
  }

  @override
  String get searchUnsavedTitle => 'Cambios sin guardar';

  @override
  String searchUnsavedBody(String names) {
    return 'Estas pestañas abiertas tienen ediciones sin guardar que el reemplazo sobrescribiría: $names. ¿Reemplazar de todos modos?';
  }

  @override
  String get searchReplaceAnyway => 'Reemplazar de todos modos';

  @override
  String get searchNoMatchesReplace => 'Sin resultados para reemplazar';

  @override
  String searchReplaced(int total, int files) {
    return 'Reemplazados $total en $files archivos. Reabre las pestañas afectadas para recargar.';
  }

  @override
  String searchReplaceFailed(String error) {
    return 'Falló el reemplazo: $error';
  }

  @override
  String searchNoMatchesIn(String name) {
    return 'Sin resultados en $name';
  }

  @override
  String searchReplacedIn(int count, String name) {
    return 'Reemplazados $count en $name. Reabre la pestaña para recargar.';
  }

  @override
  String get editorFindInFile => 'Buscar en el archivo';

  @override
  String get editorGoToDefinition => 'Ir a la definición';

  @override
  String get editorNoSymbolAtCaret =>
      'Coloca primero el cursor sobre un símbolo';

  @override
  String editorDefinitionNotFound(String name) {
    return 'No se encontró definición para \'$name\'';
  }

  @override
  String get editorFindHint => 'Buscar';

  @override
  String get editorPrevMatch => 'Resultado anterior';

  @override
  String get editorNextMatch => 'Resultado siguiente';

  @override
  String get editorMatchCase => 'Distinguir mayúsculas';

  @override
  String get editorUseRegex => 'Usar expresión regular';

  @override
  String get editorCloseFind => 'Cerrar barra de búsqueda';

  @override
  String explorerStorageError(String error) {
    return 'Almacenamiento no escribible aquí: $error';
  }

  @override
  String get explorerNewFileHint => 'p. ej. main.py';

  @override
  String get explorerNoFolder => 'Ninguna carpeta seleccionada';

  @override
  String get mdUndo => 'Deshacer';

  @override
  String get mdRedo => 'Rehacer';

  @override
  String get mdBold => 'Negrita';

  @override
  String get mdItalic => 'Cursiva';

  @override
  String get mdUnderline => 'Subrayado';

  @override
  String get mdStrike => 'Tachado';

  @override
  String get mdInlineCode => 'Código en línea';

  @override
  String get mdH1 => 'Título 1';

  @override
  String get mdH2 => 'Título 2';

  @override
  String get mdH3 => 'Título 3';

  @override
  String get mdBulleted => 'Lista con viñetas';

  @override
  String get mdNumbered => 'Lista numerada';

  @override
  String get mdQuote => 'Cita';

  @override
  String get mdCodeBlock => 'Bloque de código';

  @override
  String get terminalMaxTabs => 'Máximo de 5 pestañas de terminal alcanzado';

  @override
  String get paletteHint => 'Escribe un comando o nombre de archivo…';

  @override
  String get paletteNoMatches => 'Sin resultados';

  @override
  String get paletteToggleRun => 'Mostrar/ocultar panel Ejecutar';

  @override
  String get paletteToggleTerminal => 'Mostrar/ocultar Terminal';

  @override
  String get paletteToggleGit => 'Mostrar/ocultar panel Git';

  @override
  String get paletteToggleProcesses => 'Mostrar/ocultar panel Procesos';

  @override
  String get paletteSwitchTheme => 'Cambiar tema del editor';

  @override
  String get paletteSearchInProject => 'Buscar en el proyecto';

  @override
  String get paletteOpenSettings => 'Abrir ajustes';

  @override
  String get paletteTitle => 'Paleta de comandos';

  @override
  String get projectGeneral => 'General';

  @override
  String get projectGeneralSub =>
      'Sin entorno predefinido: idioma detectado automáticamente';

  @override
  String runtimeInstalledOk(String name) {
    return '$name instalado correctamente';
  }

  @override
  String runtimeInstallFailed(String name, String error) {
    return 'No se pudo instalar $name: $error';
  }

  @override
  String runtimeStartInstall(String name) {
    return 'Iniciando instalación de $name…';
  }

  @override
  String runtimeStartInstallFailed(String error) {
    return 'No se pudo iniciar la instalación: $error';
  }

  @override
  String runtimeStartUpdate(String name) {
    return 'Iniciando actualización de $name…';
  }

  @override
  String runtimeStartUpdateFailed(String error) {
    return 'No se pudo iniciar la actualización: $error';
  }

  @override
  String runtimeRemoving(String name) {
    return 'Eliminando $name…';
  }

  @override
  String runtimeRemoveFailed(String error) {
    return 'Falló la eliminación: $error';
  }

  @override
  String get runtimeChooseVariant =>
      'Elige una imagen del sistema Linux (se descarga una vez desde internet):';

  @override
  String get runtimeVariantSlim => 'Ligera ~70 MB (recomendada)';

  @override
  String get runtimeVariantSlimSub =>
      'Núcleo + apt: los lenguajes se instalan a pedido';

  @override
  String get runtimeVariantFull => 'Completa ~283 MB';

  @override
  String get runtimeVariantFullSub =>
      'Node, Python, PHP y Git preinstalados: funciona sin conexión';

  @override
  String get runtimeNoResults => 'Sin resultados coincidentes';

  @override
  String get runtimeSearchHint => 'Busca un lenguaje o herramienta…';

  @override
  String get runtimeClear => 'Limpiar';

  @override
  String get runtimeUnsupported => 'No compatible con este dispositivo';

  @override
  String runtimeInstalledSection(int count) {
    return 'Instalados ($count)';
  }

  @override
  String runtimePacksSection(int count) {
    return 'Packs listos ($count)';
  }

  @override
  String runtimeLanguagesSection(int count) {
    return 'Lenguajes ($count)';
  }

  @override
  String runtimeToolsSection(int count) {
    return 'Herramientas ($count)';
  }

  @override
  String runtimeWorking(String name) {
    return 'En curso: $name';
  }

  @override
  String runtimeLastOp(String name) {
    return 'Última operación: $name';
  }

  @override
  String get runtimeLogTitle => 'Registro de operaciones';

  @override
  String runtimeLines(int count) {
    return '$count líneas';
  }

  @override
  String get runtimeDone => 'Listo';

  @override
  String get runtimeStatusUpdating => 'Actualizando listas de paquetes…';

  @override
  String get runtimeStatusInstalling => 'Iniciando instalación…';

  @override
  String get runtimeStatusReading => 'Leyendo listas de paquetes…';

  @override
  String get runtimeStatusDeps => 'Construyendo árbol de dependencias…';

  @override
  String get runtimeStatusUnpacking => 'Desempaquetando paquetes…';

  @override
  String get runtimeStatusSettingUp => 'Configurando paquetes…';

  @override
  String runtimeWorkingOn(String name) {
    return 'Trabajando en $name…';
  }

  @override
  String get setupSlimTitle => 'Ligera ~80 MB (predeterminada)';

  @override
  String get setupSlimSub => 'Núcleo + apt: los lenguajes se instalan a pedido';

  @override
  String get setupFullTitle => 'Completa ~283 MB (sin conexión)';

  @override
  String get setupFullSub => 'Node, Python, PHP y Git preinstalados';

  @override
  String get setupResumeNote =>
      'Reintentar reutiliza la descarga verificada (continúa).';

  @override
  String get setupSources => 'Fuentes de descarga:';

  @override
  String get setupSourceOk => 'accesible';

  @override
  String get setupSourceDown => 'inaccesible: revisa la conexión';

  @override
  String get webPreviewTitle => 'Vista web';

  @override
  String get runtimeDescPhp => 'Lenguaje web: Laravel y WordPress';

  @override
  String get runtimeDescNode => 'JavaScript y TypeScript, con npm incluido';

  @override
  String get runtimeDescPython => 'Scripts y datos, con pip incluido';

  @override
  String get runtimeDescGo => 'Go compilado: rápido y ligero';

  @override
  String get runtimeDescRust => 'Rust: seguridad de memoria y rendimiento';

  @override
  String get runtimeDescRuby => 'Ruby para scripts y web';

  @override
  String get runtimeDescJava => 'Java 25: plataforma JVM completa';

  @override
  String get runtimeDescKotlin => 'Kotlin: corre en JVM (necesita Java)';

  @override
  String get runtimeDescDart => 'Dart: apps y herramientas CLI';

  @override
  String get runtimeDescC => 'C y C++: compilador Clang rápido';

  @override
  String get runtimeDescGit => 'Control de versiones y repositorios';

  @override
  String get runtimeDescComposer => 'Gestor de paquetes de PHP';

  @override
  String get runtimeDescNovaWeb =>
      'PHP + Composer + Ruby + Node.js: desarrollo web';

  @override
  String get runtimeDescNovaSystems =>
      'Rust + Go + make + cmake: lenguajes de sistemas';

  @override
  String get runtimeDescNovaJvm => 'Java 25 + Kotlin: plataforma JVM';

  @override
  String get runtimeDescNovaPython => 'Python + pip: scripts y datos';

  @override
  String get runtimeDescNovaDart => 'Dart: herramientas CLI';

  @override
  String get splashTagline => 'Tu entorno de desarrollo en el bolsillo';

  @override
  String get splashStatusEngine => 'Iniciando motor…';

  @override
  String get splashStatusSettings => 'Cargando ajustes…';

  @override
  String get splashStatusRuntime => 'Revisando entorno…';

  @override
  String get splashStatusWorkspace => 'Preparando espacio de trabajo…';

  @override
  String splashVersionFooter(String version, String build) {
    return 'Nova • v$version (build $build)';
  }

  @override
  String get settingsAbout => 'Acerca de';

  @override
  String appVersionBuild(String version, String build) {
    return 'v$version (build $build)';
  }

  @override
  String get aboutTitle => 'Acerca de y contacto';

  @override
  String get aboutTagline => 'Tu entorno de desarrollo en el bolsillo';

  @override
  String get aboutSectionAbout => 'Acerca de Nova';

  @override
  String get aboutDescription =>
      'Nova es un editor de código que corre en tu teléfono Android y ejecuta código directamente en el dispositivo: Python, JavaScript, PHP, Go, Rust, Ruby, Java, Kotlin, Dart, C/C++, con terminal real, Git y vista web. Sin servidor externo ni emulación: escribe, pulsa Ejecutar y mira el resultado.';

  @override
  String get aboutSectionDownload => 'Descarga';

  @override
  String get aboutPlayTitle => 'Google Play';

  @override
  String get aboutPlaySub =>
      'La instalación fácil para la mayoría, actualizada vía Play Store';

  @override
  String get aboutGithubTitle => 'Releases de GitHub';

  @override
  String get aboutGithubSub =>
      'APK directos desde la página de releases del proyecto';

  @override
  String get aboutVersionsTitle => '¿Qué versión debería usar?';

  @override
  String get aboutVersionsBody =>
      'La build de GitHub apunta a Android API 28 con ejecución directa: la ruta actual donde el entorno Linux integrado corre a plena potencia. La build de Play apunta a API 36 y ejecuta vía linker, para cumplir las políticas actuales de Play Store. Mismo editor y funciones; solo cambia la ruta de lanzamiento del entorno.';

  @override
  String get aboutSectionProject => 'Proyecto';

  @override
  String get aboutSourceCode => 'Código fuente';

  @override
  String get aboutReleases => 'Releases';

  @override
  String get aboutPackageRepo => 'Repositorio de paquetes';

  @override
  String get aboutLicense => 'Licencia: Waqf General Public License v1';

  @override
  String get aboutLicenseSub =>
      'Un waqf por Allah: libre de usar, compartir y modificar';

  @override
  String get aboutSectionContact => 'Contáctanos';

  @override
  String get aboutEmailUs => 'Escríbenos';

  @override
  String get aboutEmailHint =>
      'Para preguntas, comentarios y reportes de errores';

  @override
  String get aboutCopied => 'Copiado';

  @override
  String get aboutOpenFailed => 'No se pudo abrir el enlace';

  @override
  String get authAccount => 'Cuenta';

  @override
  String get authContinueAsGuest => 'Continuar como invitado';

  @override
  String get authDelete => 'Eliminar cuenta';

  @override
  String get authDeleteBody =>
      'Esto elimina tu cuenta permanentemente. ¿Continuar?';

  @override
  String get authDeleteTitle => '¿Eliminar cuenta?';

  @override
  String get authEmail => 'Correo electrónico';

  @override
  String get authForgot => '¿Olvidaste tu contraseña?';

  @override
  String get authForgotHint => 'Te enviaremos un enlace de restablecimiento.';

  @override
  String get authForgotTitle => 'Restablecer contraseña';

  @override
  String get authGithub => 'Continuar con GitHub';

  @override
  String get authGoogle => 'Continuar con Google';

  @override
  String get authGuestNote =>
      'Modo invitado: nada está bloqueado. Iniciar sesión es opcional.';

  @override
  String get authInvalidEmail => 'Ingresa un correo válido';

  @override
  String get authLogin => 'Iniciar sesión';

  @override
  String get authLogout => 'Cerrar sesión';

  @override
  String get authPassword => 'Contraseña';

  @override
  String get authPasswordTooShort =>
      'La contraseña debe tener al menos 6 caracteres';

  @override
  String get authResend => 'Reenviar';

  @override
  String get authResent => 'Correo de verificación enviado';

  @override
  String get authSend => 'Enviar';

  @override
  String get authSent => 'Correo de restablecimiento enviado';

  @override
  String get authSignup => 'Registrarse';

  @override
  String get authSignedOut => 'Sesión cerrada';

  @override
  String get authTitle => 'Iniciar sesión';

  @override
  String get authVerifyBanner =>
      'Correo sin verificar. Verifícalo para proteger tu cuenta.';

  @override
  String get authX => 'Continuar con X';

  @override
  String get notifCopyToken => 'Copiar token push';

  @override
  String get notifDelete => 'Eliminar';

  @override
  String get notifEmpty => 'Aún no hay notificaciones';

  @override
  String get notifMarkAllRead => 'Marcar todo como leído';

  @override
  String get notifTitle => 'Notificaciones';

  @override
  String get notifTokenCopied => 'Token push copiado';

  @override
  String get langTitle => 'Elige tu idioma';

  @override
  String get langSubtitle => 'Puedes cambiarlo cuando quieras desde Ajustes';

  @override
  String get langContinue => 'Continuar';

  @override
  String get onboardSkip => 'Omitir';

  @override
  String get onboardNext => 'Siguiente';

  @override
  String get onboardStart => 'Empezar';

  @override
  String get onboard1Title => 'Un editor de código real';

  @override
  String get onboard1Body =>
      'Resaltado de sintaxis, autocompletado inteligente y temas para cada lenguaje.';

  @override
  String get onboard2Title => 'Terminal Linux en tu teléfono';

  @override
  String get onboard2Body =>
      'Node.js, Python y Git corren nativamente dentro de la app, sin root.';

  @override
  String get onboard3Title => 'Programación en pareja con IA';

  @override
  String get onboard3Body =>
      'Explica código, corrige errores y genera fragmentos con cualquier proveedor.';

  @override
  String get onboard4Title => 'Proyectos y Git';

  @override
  String get onboard4Body =>
      'Abre carpetas, explora archivos y haz commit desde donde sea.';
}
