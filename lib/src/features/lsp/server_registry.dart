/// Install hints shown by the Runtime UI — commands the user can paste into
/// the embedded terminal to install an LSP server for a runtime.
const Map<String, String> lspInstallHints = <String, String>{
  'php': 'composer require phpactor/phpactor',
  'node': 'npm i -g typescript-language-server typescript',
  'python': 'pip install pyright',
  'go': 'apt install gopls',
};

/// The command that would be used to launch the LSP server for [language],
/// or `null` when no server is registered for that language.
String? serverCommandFor(String language) {
  switch (language) {
    case 'php':
      return 'phpactor language-server';
    case 'node':
      return 'typescript-language-server --stdio';
    case 'python':
      return 'pyright-langserver --stdio';
    case 'go':
      return 'gopls serve';
    default:
      return null;
  }
}

/// Spawn argv for [language] (command + fixed args), or `null` when the
/// language has no stdio-capable server wired through [ProcessTransport].
List<String>? serverArgvFor(String language) {
  switch (language) {
    case 'go':
      return const ['gopls', 'serve'];
    default:
      return null;
  }
}