// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get searchEmpty => 'Aucun résultat';

  @override
  String get searchPrompt => 'Rechercher dans le projet actif ci-dessus';

  @override
  String get commandPaletteEmpty => 'Aucun résultat';

  @override
  String get navProjects => 'Projets';

  @override
  String get navEditor => 'Éditeur';

  @override
  String get navPackagesSdk => 'SDK';

  @override
  String get navSettings => 'Paramètres';

  @override
  String get actionOpen => 'Ouvrir';

  @override
  String get actionSave => 'Enregistrer';

  @override
  String get actionCancel => 'Annuler';

  @override
  String get actionDelete => 'Supprimer';

  @override
  String get actionCreate => 'Créer';

  @override
  String get actionRetry => 'Réessayer';

  @override
  String get actionExit => 'Exit';

  @override
  String get appExitTitle => 'Exit Nova?';

  @override
  String get appExitBody => 'Press Exit to close the app.';

  @override
  String get actionClose => 'Fermer';

  @override
  String get actionRestore => 'Restaurer';

  @override
  String get actionDiscard => 'Abandonner';

  @override
  String get actionSearch => 'Rechercher';

  @override
  String get actionImport => 'Importer';

  @override
  String get actionExport => 'Exporter';

  @override
  String get actionCopy => 'Copier';

  @override
  String get actionShare => 'Partager';

  @override
  String get projectsWorkspaceStats => 'Statistiques de l’espace de travail';

  @override
  String get projectsOpenFolder => 'Ouvrir un dossier';

  @override
  String get projectsOpenFile => 'Ouvrir un fichier';

  @override
  String get projectsCloneGit => 'Cloner un dépôt Git';

  @override
  String get projectsNewProject => 'Nouveau projet';

  @override
  String get projectsRecentProjects => 'Projets récents';

  @override
  String get projectsRecentFiles => 'Fichiers récents';

  @override
  String get projectsTipsTitle => 'Astuces';

  @override
  String get projectsTipOrganize =>
      'Garde un dossier par projet pour changer plus vite.';

  @override
  String get settingsAppearance => 'Apparence';

  @override
  String get settingsTheme => 'Thème';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsEditor => 'Éditeur';

  @override
  String settingsFontSize(String size) {
    return 'Taille de police : $size';
  }

  @override
  String get settingsAi => 'IA';

  @override
  String get settingsTimeout => 'Délai d’expiration';

  @override
  String get themeNovaDark => 'Nova sombre';

  @override
  String get themeNovaLight => 'Nova clair';

  @override
  String get actionRun => 'Exécuter';

  @override
  String get actionStop => 'Arrêter';

  @override
  String get actionRefresh => 'Actualiser';

  @override
  String get actionRename => 'Renommer';

  @override
  String get actionInstall => 'Installer';

  @override
  String get actionUpdate => 'Mettre à jour';

  @override
  String get actionUninstall => 'Désinstaller';

  @override
  String commonError(String error) {
    return 'Erreur : $error';
  }

  @override
  String commonCreateFailed(String error) {
    return 'Échec de la création : $error';
  }

  @override
  String commonDeleteFailed(String error) {
    return 'Échec de la suppression : $error';
  }

  @override
  String commonRenameFailed(String error) {
    return 'Échec du renommage : $error';
  }

  @override
  String get projectsProjectNameHint => 'Nom du projet';

  @override
  String get projectsDeleteTitle => 'Supprimer le projet ?';

  @override
  String projectsDeleteMessage(String name) {
    return 'Supprimer « $name » et tous ses fichiers ?';
  }

  @override
  String get projectsSearchHint => 'Rechercher des projets…';

  @override
  String get projectsStatusUnavailable => 'Statut du runtime indisponible';

  @override
  String get projectsSetupNeeded => 'Configuration du runtime requise';

  @override
  String get projectsRuntimeReady => 'Runtime prêt';

  @override
  String get projectsOpenEditor => 'Ouvrir l’éditeur';

  @override
  String get projectsDeleteProject => 'Supprimer le projet';

  @override
  String get projectsEmptyTitle => 'Aucun projet pour le moment';

  @override
  String get projectsTipsBody =>
      'Touche un projet pour l’ouvrir dans l’éditeur. Utilise l’onglet Packages pour installer les runtimes avant de créer des projets Node ou Python.';

  @override
  String get editorEmptyHint => 'Ouvre un fichier depuis l’explorateur';

  @override
  String editorSaveFailed(String error) {
    return 'Échec de l’enregistrement : $error';
  }

  @override
  String editorSaved(String name) {
    return '$name enregistré';
  }

  @override
  String editorOpenFailed(String error) {
    return 'Impossible d’ouvrir le fichier : $error';
  }

  @override
  String get explorerNewFile => 'Nouveau fichier';

  @override
  String get explorerNewNameHint => 'Nouveau nom';

  @override
  String get explorerDeleteTitle => 'Supprimer ?';

  @override
  String explorerDeleteMessage(String name) {
    return 'Supprimer $name ?';
  }

  @override
  String get explorerSelectProject => 'Sélectionne un projet';

  @override
  String get explorerEmptyFolder => 'Dossier vide';

  @override
  String runStartFailed(String error) {
    return 'Échec du démarrage de la tâche : $error';
  }

  @override
  String get runNoTasks => 'Aucune tâche détectée';

  @override
  String get runHideConsole => 'Masquer la console';

  @override
  String get runShowConsole => 'Afficher la console';

  @override
  String get runEmptyHint =>
      'Appuie sur Exécuter pour lancer la tâche sélectionnée. La sortie apparaîtra ici.';

  @override
  String get gitTitle => 'Git';

  @override
  String get gitCommit => 'Commit';

  @override
  String get gitCommitMessage => 'Message de commit';

  @override
  String get gitCommitted => 'Commit effectué';

  @override
  String gitCommitFailed(String error) {
    return 'Échec du commit : $error';
  }

  @override
  String get gitStageAll => 'Indexer tout';

  @override
  String get gitStagedAll => 'Toutes les modifications indexées';

  @override
  String gitStageFailed(String error) {
    return 'Échec de l’indexation : $error';
  }

  @override
  String get gitStage => 'Indexer';

  @override
  String gitStagedFile(String file) {
    return '$file indexé';
  }

  @override
  String get gitBranches => 'Branches';

  @override
  String get gitCheckout => 'Basculer';

  @override
  String get gitCreateBranch => 'Nouvelle branche';

  @override
  String get gitBranchNameHint => 'Nom de la branche';

  @override
  String gitDeleteBranchConfirm(String name) {
    return 'Supprimer la branche « $name » ?';
  }

  @override
  String gitBranchActionFailed(String error) {
    return 'Échec de l’action sur la branche : $error';
  }

  @override
  String get gitNoBranches => '(aucune branche)';

  @override
  String get gitStash => 'Stash';

  @override
  String get gitStashSave => 'Mettre en stash';

  @override
  String get gitStashMessage => 'Message du stash';

  @override
  String get gitStashed => 'Modifications mises en stash';

  @override
  String gitStashActionFailed(String error) {
    return 'Échec de l’action de stash : $error';
  }

  @override
  String get gitRemote => 'Distant (SSH)';

  @override
  String get gitClone => 'Cloner';

  @override
  String get gitCloneUrl => 'URL du dépôt (SSH)';

  @override
  String get gitCloneDir => 'Répertoire de destination';

  @override
  String get gitCloned => 'Clonage réussi';

  @override
  String get gitFetch => 'Fetch';

  @override
  String get gitFetched => 'Fetch effectué';

  @override
  String get gitPull => 'Pull';

  @override
  String get gitPulled => 'Pull effectué';

  @override
  String get gitPush => 'Push';

  @override
  String get gitPushed => 'Push effectué';

  @override
  String gitRemoteFailed(String error) {
    return 'Échec de l’opération distante : $error';
  }

  @override
  String get gitSshKey => 'Clé publique SSH de l’application';

  @override
  String get gitSshNoKey =>
      'Pas encore de clé — génères-en une, puis ajoute-la à ton compte d’hébergement.';

  @override
  String get gitSshGenerate => 'Générer une clé';

  @override
  String get gitSshCopy => 'Copier';

  @override
  String get gitSshCopied =>
      'Clé publique copiée — ajoute-la dans les clés SSH de ton compte';

  @override
  String get gitStashEmpty => '(aucun stash)';

  @override
  String get gitStashPop => 'Restaurer';

  @override
  String get gitStashDrop => 'Supprimer';

  @override
  String get terminalTitle => 'Terminal';

  @override
  String get terminalNewSession => 'Nouvelle session';

  @override
  String get terminalStartFailed =>
      'Échec du démarrage de la session de terminal';

  @override
  String get processTitle => 'Processus';

  @override
  String get processRunHint => 'Commande à exécuter… ex. npm run dev';

  @override
  String get processEmpty =>
      'Aucun processus en cours.\nLance une tâche pour la voir ici.';

  @override
  String get runtimeTitle => 'Runtime';

  @override
  String get runtimeBootstrap => 'Bootstrap';

  @override
  String get runtimeStartSetup => 'Démarrer la configuration';

  @override
  String get runtimeInstalled => 'Installé';

  @override
  String get runtimeAvailable => 'Disponible';

  @override
  String runtimeUninstallConfirm(String name) {
    return 'Désinstaller $name ?';
  }

  @override
  String get runtimeEmpty => 'Aucun runtime disponible.';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get themeFollowSystem => 'Suivre le système';

  @override
  String get toolsShow => 'Afficher les outils';

  @override
  String get toolsHide => 'Masquer les outils';

  @override
  String get toolbarShow => 'Afficher la barre d’outils';

  @override
  String get toolbarHide => 'Masquer la barre d’outils';

  @override
  String get explorerShow => 'Afficher l’explorateur';

  @override
  String get explorerHide => 'Masquer l’explorateur';

  @override
  String get projectNew => 'Nouveau projet';

  @override
  String get projectNameHint => 'Nom du projet';

  @override
  String get projectDelete => 'Supprimer le projet';

  @override
  String get projectDeleteTitle => 'Supprimer le projet ?';

  @override
  String projectDeleteBody(String name) {
    return 'Supprimer « $name » et tous ses fichiers ?';
  }

  @override
  String get workspaceEmpty => 'Aucun projet pour le moment';

  @override
  String get workspaceTitle => 'Espace de travail';

  @override
  String get toolTerminal => 'Terminal';

  @override
  String get toolGit => 'Git';

  @override
  String get toolProcesses => 'Processus';

  @override
  String get projectSelect => 'Sélectionner un projet';

  @override
  String get projectsHintTemplate => 'Commencer depuis un modèle';

  @override
  String get projectsHintContinue => 'Continuer à travailler';

  @override
  String get projectsHintReload => 'Recharger la liste des projets';

  @override
  String get projectsHintRemoveActive => 'Supprimer le projet actif';

  @override
  String projectsFilterAll(int count) {
    return 'Tous ($count)';
  }

  @override
  String projectsCount(int count) {
    return '$count projets';
  }

  @override
  String get editorEdit => 'Modifier';

  @override
  String get editorPreview => 'Aperçu';

  @override
  String get editorTabActions => 'Actions de l’onglet';

  @override
  String get editorReloadConfirmTitle => 'Recharger le fichier ?';

  @override
  String get editorReloadConfirmBody =>
      'Abandonner les modifications non enregistrées et recharger depuis le disque ?';

  @override
  String editorReloaded(String name) {
    return '$name rechargé';
  }

  @override
  String get editorRecoverTitle => 'Modifications non enregistrées trouvées';

  @override
  String editorRecoverBody(String name) {
    return 'Restaurer les modifications non enregistrées de $name ?';
  }

  @override
  String get editorCloseDirtyTitle => 'Fermer sans enregistrer ?';

  @override
  String editorCloseDirtyBody(String name) {
    return 'Abandonner les modifications non enregistrées de $name ?';
  }

  @override
  String get editorFocusEnter => 'Mode concentration';

  @override
  String get editorFocusExit => 'Quitter le mode concentration';

  @override
  String get explorerTitle => 'EXPLORATEUR';

  @override
  String get explorerGoUp => 'Remonter';

  @override
  String get runClearOutput => 'Effacer la sortie';

  @override
  String get runStartingProcess => 'Démarrage du processus…';

  @override
  String get gitProject => 'Projet';

  @override
  String get gitOpenProject => 'Ouvrir le projet';

  @override
  String get gitSelectProject => 'Sélectionner un projet';

  @override
  String get gitProjectPath => 'Chemin du projet';

  @override
  String get gitStatus => 'Statut';

  @override
  String get gitDiff => 'Diff';

  @override
  String get gitUnavailable => 'Git indisponible';

  @override
  String gitBranch(String branch) {
    return 'Branche : $branch';
  }

  @override
  String get gitModified => 'Modifiés';

  @override
  String get gitAdded => 'Ajoutés';

  @override
  String get gitDeleted => 'Supprimés';

  @override
  String get gitUntracked => 'Non suivis';

  @override
  String get gitEmptyDiff => '(diff vide)';

  @override
  String get terminalPaste => 'Coller';

  @override
  String terminalSessionExited(int code) {
    return 'Session terminée (code $code)';
  }

  @override
  String get terminalKeyTab => 'Tab';

  @override
  String get terminalKeyEsc => 'Échap';

  @override
  String get terminalKeyUp => 'Haut';

  @override
  String get terminalKeyDown => 'Bas';

  @override
  String get terminalKeyLeft => 'Gauche';

  @override
  String get terminalKeyRight => 'Droite';

  @override
  String processStarted(String pid, String command) {
    return 'Démarré $pid · $command';
  }

  @override
  String get processStartedByNova => 'Démarré par Nova';

  @override
  String get runtimeReady => 'Prêt';

  @override
  String get runtimeBootstrapReady =>
      'Le bootstrap est prêt. Tu peux installer les runtimes ci-dessous.';

  @override
  String get bootstrapRequired => 'Runtime requis';

  @override
  String get bootstrapRequiredBody =>
      'Le runtime Linux n’est pas installé. Le télécharger maintenant pour utiliser le terminal et les runtimes de langages ?';

  @override
  String get actionDownload => 'Télécharger';

  @override
  String get actionLater => 'Plus tard';

  @override
  String get runtimeBootstrapUnavailable => 'État du bootstrap indisponible.';

  @override
  String get runtimeBootstrapNotInstalled =>
      'Le bootstrap n’est pas encore installé.';

  @override
  String runtimeVersion(String version) {
    return 'Version : $version';
  }

  @override
  String get runtimeSetupFailed => 'Échec de la configuration';

  @override
  String get aiTitle => 'Actions IA';

  @override
  String get aiKeySaved => 'Clé enregistrée';

  @override
  String get aiEnterKeyFirst => 'Saisis d’abord une clé API';

  @override
  String get aiNoCode => 'Aucun code sélectionné';

  @override
  String get aiExplainCode => 'Expliquer le code';

  @override
  String get aiFixError => 'Corriger l’erreur';

  @override
  String get aiCompleteCode => 'Compléter le code';

  @override
  String get aiStop => 'Arrêter';

  @override
  String get aiInsert => 'Insérer dans l’éditeur';

  @override
  String aiPromptExplain(String code) {
    return 'Explique le code suivant :\n$code';
  }

  @override
  String aiPromptFix(String code) {
    return 'Corrige l’erreur dans le code suivant :\n$code';
  }

  @override
  String aiPromptComplete(String code) {
    return 'Complète le code suivant :\n$code';
  }

  @override
  String get settingsSystem => 'Système';

  @override
  String settingsRunTimeout(int ms) {
    return 'Délai d’exécution : $ms ms';
  }

  @override
  String get settingsTimeoutLabel => 'Délai (ms, 1000-120000)';

  @override
  String get settingsAutocomplete => 'Autocomplétion';

  @override
  String get settingsAutocompleteSub =>
      'Suggestions de mots-clés, d’extraits et de mots pendant la frappe';

  @override
  String get settingsAiCompletion => 'Complétion IA';

  @override
  String get settingsAiCompletionSub =>
      'Suggestions du modèle dans la fenêtre d’autocomplétion';

  @override
  String get settingsMatchTheme =>
      'Harmoniser l’application avec le thème de l’éditeur';

  @override
  String get settingsMatchThemeSub =>
      'Toute l’application suit les couleurs du thème de l’éditeur';

  @override
  String get settingsWordWrap => 'Retour à la ligne';

  @override
  String get settingsWordWrapSub =>
      'Renvoyer les longues lignes à la ligne au lieu de défiler horizontalement';

  @override
  String get settingsAutoSave => 'Enregistrement automatique';

  @override
  String get settingsAutoSaveSub =>
      'Enregistre 1,5 s après que tu arrêtes de taper';

  @override
  String get settingsEditorFont => 'Police de l’éditeur';

  @override
  String get settingsFontInstalled => 'Police installée';

  @override
  String get settingsFontUpdated => 'Police de l’éditeur mise à jour';

  @override
  String get settingsDownloadFailed =>
      'Échec du téléchargement : vérifie ta connexion';

  @override
  String get settingsLivePreview => 'Aperçu en direct';

  @override
  String get settingsProvider => 'Fournisseur';

  @override
  String get settingsCustomProvider => 'Personnalisé (compatible OpenAI)';

  @override
  String get settingsBaseUrl => 'URL de base (compatible OpenAI)';

  @override
  String get settingsModel => 'Modèle';

  @override
  String get settingsApiKey => 'Clé API';

  @override
  String get settingsApiKeySaved => 'Enregistrée dans le stockage sécurisé';

  @override
  String get settingsApiKeyHint => 'Colle ta clé';

  @override
  String get settingsKeySecureNote =>
      'La clé est stockée dans un stockage sécurisé chiffré, jamais en clair dans les paramètres.';

  @override
  String get settingsTestConnection => 'Tester la connexion';

  @override
  String get settingsTesting => 'Test en cours…';

  @override
  String get settingsSaved => 'Paramètres enregistrés';

  @override
  String settingsConnected(String reply) {
    return 'Connecté : $reply';
  }

  @override
  String settingsConnectionFailed(String error) {
    return 'Échec de la connexion : $error';
  }

  @override
  String settingsThemeImported(String name) {
    return 'Thème « $name » importé';
  }

  @override
  String settingsImportFailed(String error) {
    return 'Échec de l’importation : $error';
  }

  @override
  String settingsThemeCopied(String name) {
    return 'JSON du thème « $name » copié';
  }

  @override
  String settingsThemeExported(String name) {
    return 'Thème « $name » exporté dans le presse-papiers';
  }

  @override
  String get settingsImportTheme => 'Importer un thème JSON';

  @override
  String get settingsCopyTheme => 'Copier le JSON du thème';

  @override
  String get settingsExportTheme => 'Exporter le thème';

  @override
  String get settingsDeleteTheme => 'Supprimer le thème';

  @override
  String get searchTitle => 'Rechercher dans le projet';

  @override
  String get searchHint => 'Rechercher du texte ou un motif…';

  @override
  String get searchReplaceHint => 'Remplacer par…';

  @override
  String get searchMatchCase => 'Respecter la casse';

  @override
  String get searchUseRegex => 'Utiliser une expression régulière';

  @override
  String get searchButton => 'Rechercher';

  @override
  String searchButtonCount(int hits) {
    return 'Rechercher ($hits)';
  }

  @override
  String get searchReplaceAll => 'Tout remplacer';

  @override
  String get searchNoProject => 'Aucun projet ouvert';

  @override
  String get searchTypeSomething => 'Saisis quelque chose à rechercher';

  @override
  String get searchInvalidRegex => 'Expression régulière invalide';

  @override
  String searchFailed(String error) {
    return 'Échec de la recherche : $error';
  }

  @override
  String get searchEmptyHint => 'Rechercher dans le projet actif ci-dessus';

  @override
  String get searchNoMatches => 'Aucun résultat';

  @override
  String get searchTruncated =>
      'Seuls les premiers résultats sont affichés (limites atteintes)';

  @override
  String searchReplaceCount(int count) {
    return 'Remplacer ($count)';
  }

  @override
  String get searchUnsavedTitle => 'Modifications non enregistrées';

  @override
  String searchUnsavedBody(String names) {
    return 'Ces onglets ouverts contiennent des modifications non enregistrées qui seraient écrasées par le remplacement : $names. Remplacer quand même ?';
  }

  @override
  String get searchReplaceAnyway => 'Remplacer quand même';

  @override
  String get searchNoMatchesReplace => 'Aucun résultat à remplacer';

  @override
  String searchReplaced(int total, int files) {
    return '$total occurrences remplacées dans $files fichiers. Rouvre les onglets concernés pour recharger.';
  }

  @override
  String searchReplaceFailed(String error) {
    return 'Échec du remplacement : $error';
  }

  @override
  String searchNoMatchesIn(String name) {
    return 'Aucun résultat dans $name';
  }

  @override
  String searchReplacedIn(int count, String name) {
    return '$count occurrences remplacées dans $name. Rouvre l’onglet pour recharger.';
  }

  @override
  String get editorFindInFile => 'Rechercher dans le fichier';

  @override
  String get editorGoToDefinition => 'Aller à la définition';

  @override
  String get editorNoSymbolAtCaret => 'Place d’abord le curseur sur un symbole';

  @override
  String editorDefinitionNotFound(String name) {
    return 'Aucune définition trouvée pour « $name »';
  }

  @override
  String get editorFindHint => 'Rechercher';

  @override
  String get editorPrevMatch => 'Résultat précédent';

  @override
  String get editorNextMatch => 'Résultat suivant';

  @override
  String get editorMatchCase => 'Respecter la casse';

  @override
  String get editorUseRegex => 'Utiliser une expression régulière';

  @override
  String get editorCloseFind => 'Fermer la barre de recherche';

  @override
  String explorerStorageError(String error) {
    return 'Stockage non accessible en écriture ici : $error';
  }

  @override
  String get explorerNewFileHint => 'ex. main.py';

  @override
  String get explorerNoFolder => 'Aucun dossier sélectionné';

  @override
  String get mdUndo => 'Annuler';

  @override
  String get mdRedo => 'Rétablir';

  @override
  String get mdBold => 'Gras';

  @override
  String get mdItalic => 'Italique';

  @override
  String get mdUnderline => 'Souligné';

  @override
  String get mdStrike => 'Barré';

  @override
  String get mdInlineCode => 'Code en ligne';

  @override
  String get mdH1 => 'Titre 1';

  @override
  String get mdH2 => 'Titre 2';

  @override
  String get mdH3 => 'Titre 3';

  @override
  String get mdBulleted => 'Liste à puces';

  @override
  String get mdNumbered => 'Liste numérotée';

  @override
  String get mdQuote => 'Citation';

  @override
  String get mdCodeBlock => 'Bloc de code';

  @override
  String get terminalMaxTabs => 'Maximum de 5 onglets de terminal atteint';

  @override
  String get paletteHint => 'Saisis une commande ou un nom de fichier…';

  @override
  String get paletteNoMatches => 'Aucun résultat';

  @override
  String get paletteToggleRun => 'Basculer le panneau Exécuter';

  @override
  String get paletteToggleTerminal => 'Basculer le terminal';

  @override
  String get paletteToggleGit => 'Basculer le panneau Git';

  @override
  String get paletteToggleProcesses => 'Basculer le panneau des processus';

  @override
  String get paletteSwitchTheme => 'Changer le thème de l’éditeur';

  @override
  String get paletteSearchInProject => 'Rechercher dans le projet';

  @override
  String get paletteOpenSettings => 'Ouvrir les paramètres';

  @override
  String get paletteTitle => 'Palette de commandes';

  @override
  String get projectGeneral => 'Général';

  @override
  String get projectGeneralSub =>
      'Aucun runtime présupposé — langage détecté automatiquement';

  @override
  String runtimeInstalledOk(String name) {
    return '$name installé avec succès';
  }

  @override
  String runtimeInstallFailed(String name, String error) {
    return 'Échec de l’installation de $name : $error';
  }

  @override
  String runtimeStartInstall(String name) {
    return 'Démarrage de l’installation de $name…';
  }

  @override
  String runtimeStartInstallFailed(String error) {
    return 'Échec du démarrage de l’installation : $error';
  }

  @override
  String runtimeStartUpdate(String name) {
    return 'Démarrage de la mise à jour de $name…';
  }

  @override
  String runtimeStartUpdateFailed(String error) {
    return 'Échec du démarrage de la mise à jour : $error';
  }

  @override
  String runtimeRemoving(String name) {
    return 'Suppression de $name…';
  }

  @override
  String runtimeRemoveFailed(String error) {
    return 'Échec de la suppression : $error';
  }

  @override
  String get runtimeChooseVariant =>
      'Choisis une image système Linux (téléchargée une fois depuis Internet) :';

  @override
  String get runtimeVariantSlim => 'Légère ~70 Mo (recommandée)';

  @override
  String get runtimeVariantSlimSub =>
      'Noyau + apt — langages installés à la demande';

  @override
  String get runtimeVariantFull => 'Complète ~283 Mo';

  @override
  String get runtimeVariantFullSub =>
      'Node, Python, PHP et Git préinstallés — fonctionne hors ligne';

  @override
  String get runtimeNoResults => 'Aucun résultat correspondant';

  @override
  String get runtimeSearchHint => 'Rechercher un langage ou un outil…';

  @override
  String get runtimeClear => 'Effacer';

  @override
  String get runtimeUnsupported => 'Non pris en charge sur cet appareil';

  @override
  String runtimeInstalledSection(int count) {
    return 'Installés ($count)';
  }

  @override
  String runtimePacksSection(int count) {
    return 'Packs prêts ($count)';
  }

  @override
  String runtimeLanguagesSection(int count) {
    return 'Langages ($count)';
  }

  @override
  String runtimeToolsSection(int count) {
    return 'Outils ($count)';
  }

  @override
  String runtimeWorking(String name) {
    return 'En cours : $name';
  }

  @override
  String runtimeLastOp(String name) {
    return 'Dernière opération : $name';
  }

  @override
  String get runtimeLogTitle => 'Journal des opérations';

  @override
  String runtimeLines(int count) {
    return '$count lignes';
  }

  @override
  String get runtimeDone => 'Terminé';

  @override
  String get runtimeStatusUpdating => 'Mise à jour des listes de paquets…';

  @override
  String get runtimeStatusInstalling => 'Démarrage de l’installation…';

  @override
  String get runtimeStatusReading => 'Lecture des listes de paquets…';

  @override
  String get runtimeStatusDeps => 'Construction de l’arbre des dépendances…';

  @override
  String get runtimeStatusUnpacking => 'Décompression des paquets…';

  @override
  String get runtimeStatusSettingUp => 'Configuration des paquets…';

  @override
  String runtimeWorkingOn(String name) {
    return 'Traitement de $name…';
  }

  @override
  String get setupSlimTitle => 'Légère ~80 Mo (par défaut)';

  @override
  String get setupSlimSub => 'Noyau + apt — langages installés à la demande';

  @override
  String get setupFullTitle => 'Complète ~283 Mo (hors ligne)';

  @override
  String get setupFullSub => 'Node, Python, PHP et Git préinstallés';

  @override
  String get setupResumeNote =>
      'En cas de nouvel essai, le téléchargement vérifié est réutilisé (reprise).';

  @override
  String get setupSources => 'Sources de téléchargement :';

  @override
  String get setupSourceOk => 'accessible';

  @override
  String get setupSourceDown => 'inaccessible — vérifie ta connexion';

  @override
  String get webPreviewTitle => 'Aperçu Web';

  @override
  String get runtimeDescPhp => 'Langage Web — Laravel et WordPress';

  @override
  String get runtimeDescNode => 'JavaScript et TypeScript — npm inclus';

  @override
  String get runtimeDescPython => 'Scripts et données — pip inclus';

  @override
  String get runtimeDescGo => 'Go compilé — rapide et léger';

  @override
  String get runtimeDescRust => 'Rust — sécurité mémoire et performance';

  @override
  String get runtimeDescRuby => 'Ruby pour les scripts et le Web';

  @override
  String get runtimeDescJava => 'Java 25 — plateforme JVM complète';

  @override
  String get runtimeDescKotlin =>
      'Kotlin — fonctionne sur la JVM (nécessite Java)';

  @override
  String get runtimeDescDart => 'Dart — applis et outils CLI';

  @override
  String get runtimeDescC => 'C et C++ — compilateur Clang rapide';

  @override
  String get runtimeDescGit => 'Gestion de versions et dépôts';

  @override
  String get runtimeDescComposer => 'Gestionnaire de paquets PHP';

  @override
  String get runtimeDescNovaWeb =>
      'PHP + Composer + Ruby + Node.js — développement Web';

  @override
  String get runtimeDescNovaSystems =>
      'Rust + Go + make + cmake — langages système';

  @override
  String get runtimeDescNovaJvm => 'Java 25 + Kotlin — plateforme JVM';

  @override
  String get runtimeDescNovaPython => 'Python + pip — scripts et données';

  @override
  String get runtimeDescNovaDart => 'Dart — outils CLI';

  @override
  String get splashTagline => 'Ton environnement de dev dans ta poche';

  @override
  String get splashStatusEngine => 'Initialisation du moteur…';

  @override
  String get splashStatusSettings => 'Chargement des paramètres…';

  @override
  String get splashStatusRuntime => 'Vérification du runtime…';

  @override
  String get splashStatusWorkspace => 'Préparation de l’espace de travail…';

  @override
  String splashVersionFooter(String version, String build) {
    return 'Nova • v$version (build $build)';
  }

  @override
  String get settingsAbout => 'À propos';

  @override
  String appVersionBuild(String version, String build) {
    return 'v$version (build $build)';
  }

  @override
  String get aboutTitle => 'À propos et contact';

  @override
  String get aboutTagline => 'Ton environnement de dev dans ta poche';

  @override
  String get aboutSectionAbout => 'À propos de Nova';

  @override
  String get aboutDescription =>
      'Nova est un éditeur de code qui fonctionne sur ton téléphone Android et exécute le code directement sur l’appareil — Python, JavaScript, PHP, Go, Rust, Ruby, Java, Kotlin, Dart, C/C++ — avec un vrai terminal, Git et un aperçu Web. Aucun serveur externe, aucune émulation : écris, appuie sur Exécuter, et vois le résultat.';

  @override
  String get aboutSectionDownload => 'Téléchargement';

  @override
  String get aboutPlayTitle => 'Google Play';

  @override
  String get aboutPlaySub =>
      'L’installation facile pour la plupart des utilisateurs, mise à jour via le Play Store';

  @override
  String get aboutGithubTitle => 'Versions GitHub';

  @override
  String get aboutGithubSub =>
      'APK directs depuis la page des versions du projet';

  @override
  String get aboutVersionsTitle => 'Quelle version dois-je utiliser ?';

  @override
  String get aboutVersionsBody =>
      'La version GitHub cible Android API 28 avec exécution directe — le chemin actuel où le runtime Linux intégré fonctionne à pleine puissance. La version Play cible l’API 36 et s’exécute via l’éditeur de liens, pour se conformer aux règles actuelles du Play Store. Même éditeur, mêmes fonctionnalités ; seul le chemin de lancement du runtime diffère.';

  @override
  String get aboutSectionProject => 'Projet';

  @override
  String get aboutSourceCode => 'Code source';

  @override
  String get aboutReleases => 'Versions';

  @override
  String get aboutPackageRepo => 'Dépôt de paquets';

  @override
  String get aboutLicense => 'Licence : Waqf General Public License v1';

  @override
  String get aboutLicenseSub =>
      'Un waqf pour Allah — libre d’utilisation, de partage et de modification';

  @override
  String get aboutSectionContact => 'Nous contacter';

  @override
  String get aboutEmailUs => 'Écris-nous';

  @override
  String get aboutEmailHint =>
      'Pour les questions, les retours et les rapports de bogues';

  @override
  String get aboutCopied => 'Copié';

  @override
  String get aboutOpenFailed => 'Impossible d’ouvrir le lien';

  @override
  String get authAccount => 'Compte';

  @override
  String get authContinueAsGuest => 'Continuer en invité';

  @override
  String get authDelete => 'Supprimer le compte';

  @override
  String get authDeleteBody =>
      'Cette action supprime définitivement ton compte. Continuer ?';

  @override
  String get authDeleteTitle => 'Supprimer le compte ?';

  @override
  String get authEmail => 'E-mail';

  @override
  String get authForgot => 'Mot de passe oublié ?';

  @override
  String get authForgotHint =>
      'Nous t’enverrons un lien de réinitialisation par e-mail.';

  @override
  String get authForgotTitle => 'Réinitialiser le mot de passe';

  @override
  String get authGithub => 'Continuer avec GitHub';

  @override
  String get authGoogle => 'Continuer avec Google';

  @override
  String get authGuestNote =>
      'Mode invité : rien n’est verrouillé. La connexion est facultative.';

  @override
  String get authInvalidEmail => 'Saisis un e-mail valide';

  @override
  String get authLogin => 'Connexion';

  @override
  String get authLogout => 'Se déconnecter';

  @override
  String get authPassword => 'Mot de passe';

  @override
  String get authPasswordTooShort =>
      'Le mot de passe doit comporter au moins 6 caractères';

  @override
  String get authResend => 'Renvoyer';

  @override
  String get authResent => 'E-mail de vérification envoyé';

  @override
  String get authSend => 'Envoyer';

  @override
  String get authSent => 'E-mail de réinitialisation envoyé';

  @override
  String get authSignup => 'Inscription';

  @override
  String get authSignedOut => 'Déconnecté';

  @override
  String get authTitle => 'Se connecter';

  @override
  String get authVerifyBanner =>
      'E-mail non vérifié. Vérifie-le pour sécuriser ton compte.';

  @override
  String get authX => 'Continuer avec X';

  @override
  String get notifCopyToken => 'Copier le jeton push';

  @override
  String get notifDelete => 'Supprimer';

  @override
  String get notifEmpty => 'Aucune notification pour le moment';

  @override
  String get notifMarkAllRead => 'Tout marquer comme lu';

  @override
  String get notifTitle => 'Notifications';

  @override
  String get notifTokenCopied => 'Jeton push copié';

  @override
  String get langTitle => 'Choisis ta langue';

  @override
  String get langSubtitle =>
      'Tu pourras la changer à tout moment depuis les Paramètres';

  @override
  String get langContinue => 'Continuer';

  @override
  String get onboardSkip => 'Passer';

  @override
  String get onboardNext => 'Suivant';

  @override
  String get onboardStart => 'Commencer';

  @override
  String get onboard1Title => 'Un vrai éditeur de code';

  @override
  String get onboard1Body =>
      'Coloration syntaxique, autocomplétion intelligente et thèmes pour chaque langage.';

  @override
  String get onboard2Title => 'Un terminal Linux sur ton téléphone';

  @override
  String get onboard2Body =>
      'Node.js, Python et Git fonctionnent nativement dans l’application — sans root.';

  @override
  String get onboard3Title => 'Un binôme programmeur IA';

  @override
  String get onboard3Body =>
      'Explique le code, corrige les erreurs et génère des extraits avec n’importe quel fournisseur.';

  @override
  String get onboard4Title => 'Projets et Git';

  @override
  String get onboard4Body =>
      'Ouvre des dossiers, parcours les fichiers et fais des commits depuis n’importe où.';
}
