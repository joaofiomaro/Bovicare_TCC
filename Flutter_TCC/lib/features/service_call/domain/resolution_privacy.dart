import 'entities/service_call.dart';

/// Confere se o laudo do veterinário traz dados pessoais (LGPD).
///
/// O chamado já identifica o produtor, o veterinário, a fazenda e o animal
/// em campos próprios, e esses campos são apagados ou trocados por textos
/// fixos quando uma conta é excluída (`ServiceCallAnonymization`). O laudo é
/// texto livre e fica no chamado depois da exclusão: por isso ele não pode
/// repetir esses dados nem trazer contatos (Lei 13.709/2018, art. 6.º, III,
/// necessidade, e art. 46, segurança desde a concepção).
///
/// A checagem roda no app, antes de o laudo ser gravado. Ela compara palavras
/// inteiras, sem diferenciar maiúsculas nem acentos.
abstract final class ResolutionPrivacy {
  /// Palavras de nomes que não identificam ninguém sozinhas.
  static const Set<String> _nameParticles = {
    'dos',
    'das',
    'del',
    'der',
    'van',
    'von',
  };

  /// Começo genérico do nome de uma propriedade ("Fazenda Boa Vista").
  static final RegExp _farmPrefix = RegExp(
    r'^(fazenda|sitio|chacara|estancia|rancho|granja|haras)\s+',
  );

  static final RegExp _email = RegExp(r'[\w.+-]+@[\w-]+\.[\w.]+');
  static final RegExp _cpf = RegExp(r'(?<!\d)\d{3}\.\d{3}\.\d{3}-\d{2}(?!\d)');
  static final RegExp _phone = RegExp(
    r'(?<!\d)(\(?\d{2}\)?[\s-]?)?9?\d{4}[\s-]?\d{4}(?!\d)',
  );
  static final RegExp _crmv = RegExp(r'crmv[\s\-/:a-z]{0,6}\d');

  /// Itens de dado pessoal achados no laudo, em texto para o veterinário
  /// (por exemplo, `o nome "Leonardo"` ou `um telefone`). Vazio = laudo ok.
  static List<String> findPersonalData(String resolution, ServiceCall call) {
    final text = normalize(resolution);
    final found = <String>[];

    for (final word in _nameWords(call.producerName)) {
      if (_hasWord(text, word)) {
        found.add('o nome "${_original(resolution, word)}"');
      }
    }
    for (final word in _nameWords(call.vetName ?? '')) {
      final item = 'o nome "${_original(resolution, word)}"';
      if (_hasWord(text, word) && !found.contains(item)) found.add(item);
    }
    final farm = normalize(call.farmName ?? '').replaceFirst(_farmPrefix, '');
    if (farm.length >= 3 && _hasWord(text, farm)) {
      found.add('o nome da fazenda');
    }
    final city = normalize(call.city);
    if (city.length >= 3 && _hasWord(text, city)) found.add('a cidade');
    // brinco com ou sem espaços ("BR 0042 7781" = "BR00427781"); depois de achado,
    // sai do texto para os dígitos dele não serem lidos como telefone
    var rest = text;
    final tag = normalize(
      call.animalEarTag ?? '',
    ).replaceAll(RegExp(r'\s'), '');
    if (tag.length >= 4) {
      final tagRe = RegExp(tag.split('').map(RegExp.escape).join(r'\s*'));
      if (tagRe.hasMatch(text)) {
        found.add('o número do brinco');
        rest = text.replaceAll(tagRe, ' ');
      }
    }
    if (_email.hasMatch(rest)) found.add('um e-mail');
    if (_cpf.hasMatch(rest)) {
      found.add('um CPF');
    } else if (_phone.hasMatch(rest)) {
      found.add('um telefone');
    }
    if (_crmv.hasMatch(rest)) found.add('o número do CRMV');
    return found;
  }

  /// Mensagem para o veterinário, ou `null` se o laudo não tem dado pessoal.
  static String? message(String resolution, ServiceCall call) {
    final found = findPersonalData(resolution, call);
    if (found.isEmpty) return null;
    final list = found.length == 1
        ? found.first
        : '${found.sublist(0, found.length - 1).join(', ')} e ${found.last}';
    return 'Tire do laudo $list. O chamado já identifica o produtor, '
        'o veterinário e o animal, e o laudo fica guardado mesmo se a conta '
        'for excluída.';
  }

  /// Minúsculas e sem acentos, para comparar nomes digitados de jeitos diferentes.
  static String normalize(String s) {
    const from = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
    const to = 'aaaaaeeeeiiiiooooouuuucn';
    final lower = s.toLowerCase();
    final b = StringBuffer();
    for (final ch in lower.split('')) {
      final k = from.indexOf(ch);
      b.write(k < 0 ? ch : to[k]);
    }
    return b.toString().trim();
  }

  static Iterable<String> _nameWords(String name) => normalize(name)
      .split(RegExp(r'[\s.]+'))
      .where((w) => w.length >= 3 && !_nameParticles.contains(w))
      .toSet();

  static bool _hasWord(String text, String phrase) => RegExp(
    '(?<![a-z0-9])${RegExp.escape(phrase)}(?![a-z0-9])',
  ).hasMatch(text);

  /// A palavra como o veterinário escreveu (com acento e maiúscula), para a mensagem.
  static String _original(String resolution, String normalizedWord) {
    final words = resolution.split(RegExp(r'[^\p{L}\p{N}]+', unicode: true));
    return words.firstWhere(
      (w) => normalize(w) == normalizedWord,
      orElse: () => normalizedWord,
    );
  }
}
