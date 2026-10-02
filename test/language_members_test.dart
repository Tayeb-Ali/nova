import 'dart:convert';
import 'dart:io';

import 'package:nova/src/features/editor/autocomplete/language_members.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:re_editor/re_editor.dart';

/// JSON maintenance contract: tables are data (`assets/autocomplete/`),
/// so tests seed the registry directly instead of touching assets.
const _sampleJson = {
  "receivers": {
    "console": {
      "methods": {"log": "void", "error": "void"},
      "fields": {},
    },
    "Math": {
      "methods": {"random": "number"},
      "fields": {"PI": "number"},
    },
    "broken": "not-a-map",
  },
};

void main() {
  setUpAll(() => MemberRegistry.debugFill('javascript', _sampleJson));

  group('memberPrompts', () {
    test('console members unfiltered on empty partial', () {
      final prompts = memberPrompts('javascript', 'console', '')!;
      final words = prompts.map((p) => p.word).toSet();
      expect(words, containsAll(['log', 'error']));
    });

    test('filters by partial prefix', () {
      final prompts = memberPrompts('javascript', 'console', 'e')!;
      final words = prompts.map((p) => p.word).toSet();
      expect(words, contains('error'));
      expect(words, isNot(contains('log')));
    });

    test('exact word is excluded like other prompts', () {
      expect(memberPrompts('javascript', 'console', 'log'), isNull);
    });

    test('unknown receiver or language falls through', () {
      expect(memberPrompts('javascript', 'frobnicate', ''), isNull);
      expect(memberPrompts('php', 'console', ''), isNull);
      expect(memberPrompts(null, 'console', ''), isNull);
    });

    test('methods carry function prompts with return types', () {
      final prompts = memberPrompts('javascript', 'console', 'err')!;
      final prompt = prompts.single as CodeFunctionPrompt;
      expect(prompt.word, 'error');
      expect(prompt.type, 'void');
    });

    test('fields parse as field prompts', () {
      final prompts = memberPrompts('javascript', 'Math', 'P')!;
      final prompt = prompts.single as CodeFieldPrompt;
      expect(prompt.word, 'PI');
      expect(prompt.type, 'number');
    });

    test('malformed receiver entries are skipped', () {
      expect(memberPrompts('javascript', 'broken', ''), isNull);
    });
  });

  group('shipped JSON tables', () {
    Map<String, dynamic> loadTable(String language) {
      final raw = File('assets/autocomplete/$language.json')
          .readAsStringSync();
      return jsonDecode(raw) as Map<String, dynamic>;
    }

    test('javascript table has console and Math', () {
      final table =
          MemberRegistry.parseReceivers(loadTable('javascript'));
      expect(table['console']!.map((p) => p.word), contains('log'));
      expect(
        table['console']!.map((p) => p.word),
        containsAll(['error', 'info', 'warn', 'debug']),
      );
      expect(table['Math']!.map((p) => p.word), contains('random'));
    });

    test('python table has os and sys', () {
      final table = MemberRegistry.parseReceivers(loadTable('python'));
      expect(table['os']!.map((p) => p.word), contains('getcwd'));
      expect(table['sys']!.map((p) => p.word), contains('exit'));
    });

    test('python table covers stdlib and data stack', () {
      final table = MemberRegistry.parseReceivers(loadTable('python'));
      expect(table['itertools']!.map((p) => p.word), contains('chain'));
      expect(table['functools']!.map((p) => p.word), contains('lru_cache'));
      expect(table['pathlib']!.map((p) => p.word), contains('Path'));
      expect(table['asyncio']!.map((p) => p.word), contains('gather'));
      expect(table['logging']!.map((p) => p.word), contains('getLogger'));
      expect(table['np']!.map((p) => p.word), contains('array'));
      expect(table['pd']!.map((p) => p.word), contains('DataFrame'));
      expect(table['plt']!.map((p) => p.word), contains('plot'));
      expect(table['pytest']!.map((p) => p.word), contains('raises'));
    });

    test('dart table has DateTime and Future', () {
      final table = MemberRegistry.parseReceivers(loadTable('dart'));
      expect(table['DateTime']!.map((p) => p.word), contains('now'));
      expect(table['Future']!.map((p) => p.word), contains('delayed'));
    });

    test('typescript mirrors javascript receivers', () {
      final table =
          MemberRegistry.parseReceivers(loadTable('typescript'));
      expect(table['console']!.map((p) => p.word), contains('log'));
      expect(table['fs']!.map((p) => p.word), contains('readFile'));
    });

    test('javascript table covers node, express and react', () {
      final table =
          MemberRegistry.parseReceivers(loadTable('javascript'));
      expect(table['fs']!.map((p) => p.word), contains('readFile'));
      expect(table['path']!.map((p) => p.word), contains('join'));
      expect(table['os']!.map((p) => p.word), contains('homedir'));
      expect(table['http']!.map((p) => p.word), contains('createServer'));
      expect(table['crypto']!.map((p) => p.word), contains('randomUUID'));
      expect(table['Buffer']!.map((p) => p.word), contains('from'));
      expect(table['require']!.map((p) => p.word), contains('resolve'));
      expect(table['express']!.map((p) => p.word), contains('json'));
      expect(table['res']!.map((p) => p.word), contains('json'));
      expect(table['req']!.map((p) => p.word), contains('params'));
      expect(table['React']!.map((p) => p.word), contains('useState'));
      expect(table['URLSearchParams']!.map((p) => p.word), contains('append'));
    });

    test('javascript table covers web platform additions', () {
      final table =
          MemberRegistry.parseReceivers(loadTable('javascript'));
      expect(table['Date']!.map((p) => p.word), contains('now'));
      expect(table['Headers']!.map((p) => p.word), contains('append'));
      expect(table['FormData']!.map((p) => p.word), contains('append'));
      expect(table['history']!.map((p) => p.word), contains('pushState'));
      expect(table['TextEncoder']!.map((p) => p.word), contains('encode'));
    });

    test('rust table covers std and ecosystem', () {
      final table = MemberRegistry.parseReceivers(loadTable('rust'));
      expect(table['Option']!.map((p) => p.word), contains('unwrap'));
      expect(table['Vec']!.map((p) => p.word), contains('push'));
      expect(table['HashMap']!.map((p) => p.word), contains('entry'));
      expect(table['str']!.map((p) => p.word), contains('split'));
      expect(table['fs']!.map((p) => p.word), contains('read_to_string'));
      expect(table['env']!.map((p) => p.word), contains('var'));
      expect(table['serde_json']!.map((p) => p.word), contains('from_str'));
    });

    test('go table covers stdlib and web frameworks', () {
      final table = MemberRegistry.parseReceivers(loadTable('go'));
      expect(table['fmt']!.map((p) => p.word), contains('Println'));
      expect(table['strings']!.map((p) => p.word), contains('Contains'));
      expect(table['strconv']!.map((p) => p.word), contains('Itoa'));
      expect(table['os']!.map((p) => p.word), contains('ReadFile'));
      expect(table['http']!.map((p) => p.word), contains('Get'));
      expect(table['json']!.map((p) => p.word), contains('Marshal'));
      expect(table['time']!.map((p) => p.word), contains('Now'));
      expect(table['sync']!.map((p) => p.word), contains('WaitGroup'));
      expect(table['gin']!.map((p) => p.word), contains('Default'));
      expect(table['slices']!.map((p) => p.word), contains('Contains'));
    });

    test('java table covers the JDK core', () {
      final java = MemberRegistry.parseReceivers(loadTable('java'));
      expect(java['String']!.map((p) => p.word), contains('substring'));
      expect(java['ArrayList']!.map((p) => p.word), contains('add'));
      expect(java['HashMap']!.map((p) => p.word), contains('put'));
      expect(java['Arrays']!.map((p) => p.word), contains('sort'));
      expect(java['Collections']!.map((p) => p.word), contains('sort'));
      expect(java['Math']!.map((p) => p.word), contains('random'));
      expect(java['Optional']!.map((p) => p.word), contains('orElse'));
      expect(java['Files']!.map((p) => p.word), contains('readString'));
      expect(java['Collectors']!.map((p) => p.word), contains('toList'));
      expect(java['LocalDate']!.map((p) => p.word), contains('now'));
      expect(java['Assertions']!.map((p) => p.word), contains('assertEquals'));
      expect(java['Mockito']!.map((p) => p.word), contains('mock'));
    });

    test('php table covers laravel and core', () {
      final table = MemberRegistry.parseReceivers(loadTable('php'));
      expect(table['Auth']!.map((p) => p.word), contains('user'));
      expect(table['DB']!.map((p) => p.word), contains('table'));
      expect(table['Schema']!.map((p) => p.word), contains('create'));
      expect(table['Cache']!.map((p) => p.word), contains('get'));
      expect(table['Route']!.map((p) => p.word), contains('get'));
      expect(table['Validator']!.map((p) => p.word), contains('make'));
      expect(table['Model']!.map((p) => p.word), contains('findOrFail'));
      expect(table['request']!.map((p) => p.word), contains('validate'));
      expect(table['pdo']!.map((p) => p.word), contains('prepare'));
      expect(table['Carbon']!.map((p) => p.word), contains('now'));
      expect(table['Assert']!.map((p) => p.word), contains('assertEquals'));
    });
    test('kotlin table covers stdlib, android and compose', () {
      final table = MemberRegistry.parseReceivers(loadTable('kotlin'));
      expect(table['String']!.map((p) => p.word), contains('substring'));
      expect(table['list']!.map((p) => p.word), contains('map'));
      expect(table['Dispatchers']!.map((p) => p.word), contains('Main'));
      expect(table['Flow']!.map((p) => p.word), contains('collect'));
      expect(table['Result']!.map((p) => p.word), contains('getOrNull'));
      expect(table['Log']!.map((p) => p.word), contains('d'));
      expect(table['intent']!.map((p) => p.word), contains('putExtra'));
      expect(table['Modifier']!.map((p) => p.word), contains('fillMaxSize'));
      expect(table['MaterialTheme']!.map((p) => p.word), contains('colorScheme'));
      expect(table['navController']!.map((p) => p.word), contains('navigate'));
      expect(table['Json']!.map((p) => p.word), contains('decodeFromString'));
    });
    test('new tables parse: kotlin, rust, php, c, cpp, swift', () {
      final kotlin = MemberRegistry.parseReceivers(loadTable('kotlin'));
      expect(kotlin['String']!.map((p) => p.word), contains('substring'));
      final rust = MemberRegistry.parseReceivers(loadTable('rust'));
      expect(rust['Option']!.map((p) => p.word), contains('unwrap'));
      final php = MemberRegistry.parseReceivers(loadTable('php'));
      expect(php['Auth']!.map((p) => p.word), contains('user'));
      final c = MemberRegistry.parseReceivers(loadTable('c'));
      expect(c['stdlib']!.map((p) => p.word), contains('malloc'));
      final cpp = MemberRegistry.parseReceivers(loadTable('cpp'));
      expect(cpp['std']!.map((p) => p.word), contains('cout'));
      final swift = MemberRegistry.parseReceivers(loadTable('swift'));
      expect(swift['Array']!.map((p) => p.word), contains('append'));
    });

    test('dart table has Flutter essentials', () {
      final table = MemberRegistry.parseReceivers(loadTable('dart'));
      expect(table['Navigator']!.map((p) => p.word), contains('push'));
      expect(table['ref']!.map((p) => p.word), contains('watch'));
    });

    test('dart table covers framework enums and helpers', () {
      final table = MemberRegistry.parseReceivers(loadTable('dart'));
      expect(table['Colors']!.map((p) => p.word), contains('transparent'));
      expect(table['Icons']!.map((p) => p.word), contains('menu'));
      expect(table['MainAxisAlignment']!.map((p) => p.word), contains('spaceBetween'));
      expect(table['FontWeight']!.map((p) => p.word), contains('bold'));
      expect(table['EdgeInsets']!.map((p) => p.word), contains('all'));
      expect(table['BorderRadius']!.map((p) => p.word), contains('circular'));
      expect(table['ListView']!.map((p) => p.word), contains('builder'));
      expect(table['Image']!.map((p) => p.word), contains('network'));
      expect(table['Platform']!.map((p) => p.word), contains('operatingSystem'));
      expect(table['json']!.map((p) => p.word), contains('decode'));
      expect(table['utf8']!.map((p) => p.word), contains('decode'));
      expect(table['snapshot']!.map((p) => p.word), contains('hasData'));
      expect(table['prefs']!.map((p) => p.word), contains('getString'));
      expect(table['Color']!.map((p) => p.word), contains('fromARGB'));
      expect(table['ThemeData']!.map((p) => p.word), contains('light'));
      expect(table['HapticFeedback']!.map((p) => p.word), contains('lightImpact'));
    });

    test('c table covers headers and struct fields', () {
      final table = MemberRegistry.parseReceivers(loadTable('c'));
      expect(table['stdio']!.map((p) => p.word), contains('fgets'));
      expect(table['string']!.map((p) => p.word), contains('memcpy'));
      expect(table['stdlib']!.map((p) => p.word), contains('bsearch'));
      expect(table['ctype']!.map((p) => p.word), contains('isalpha'));
      expect(table['time']!.map((p) => p.word), contains('strftime'));
      expect(table['tm']!.map((p) => p.word), contains('tm_year'));
      expect(table['limits']!.map((p) => p.word), contains('INT_MAX'));
      expect(table['errno']!.map((p) => p.word), contains('EINVAL'));
    });

    test('cpp table covers the STL', () {
      final table = MemberRegistry.parseReceivers(loadTable('cpp'));
      expect(table['std']!.map((p) => p.word), contains('for_each'));
      expect(table['vector']!.map((p) => p.word), contains('emplace_back'));
      expect(table['string']!.map((p) => p.word), contains('c_str'));
      expect(table['map']!.map((p) => p.word), contains('try_emplace'));
      expect(table['unordered_map']!.map((p) => p.word), contains('reserve'));
      expect(table['set']!.map((p) => p.word), contains('contains'));
      expect(table['deque']!.map((p) => p.word), contains('push_front'));
      expect(table['queue']!.map((p) => p.word), contains('front'));
      expect(table['stack']!.map((p) => p.word), contains('top'));
      expect(table['array']!.map((p) => p.word), contains('fill'));
      expect(table['pair']!.map((p) => p.word), contains('first'));
      expect(table['shared_ptr']!.map((p) => p.word), contains('use_count'));
    });
  });
}
