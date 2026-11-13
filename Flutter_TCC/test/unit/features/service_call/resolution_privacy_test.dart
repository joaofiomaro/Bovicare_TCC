import 'package:bovicare/features/service_call/domain/entities/service_call.dart';
import 'package:bovicare/features/service_call/domain/resolution_privacy.dart';
import 'package:flutter_test/flutter_test.dart';

ServiceCall _call({
  String producerName = 'João Pedro dos Santos',
  String? vetName = 'Ângela Moreira',
  String city = 'Votuporanga',
  String? farmName = 'Fazenda Boa Esperança',
  String? animalEarTag = 'BR 0042 7781',
}) => ServiceCall(
  id: 'c1',
  producerId: 'p1',
  producerName: producerName,
  city: city,
  state: 'SP',
  title: 'Vaca com dificuldade no parto',
  description: 'Duas vacas com problema no parto',
  urgency: ServiceUrgency.high,
  status: ServiceStatus.inProgress,
  createdAt: DateTime(2026, 11, 13),
  farmName: farmName,
  animalEarTag: animalEarTag,
  vetId: 'v1',
  vetName: vetName,
);

List<String> _find(String laudo, [ServiceCall? call]) =>
    ResolutionPrivacy.findPersonalData(laudo, call ?? _call());

void main() {
  group('ResolutionPrivacy', () {
    test('laudo clínico sem dados pessoais passa', () {
      expect(
        _find(
          'Parto distócico, feto em posição posterior. Tração assistida, '
          'ocitocina 20 UI e anti-inflamatório por 3 dias. Retorno em 7 dias.',
        ),
        isEmpty,
      );
      expect(ResolutionPrivacy.message('Animal medicado.', _call()), isNull);
    });

    test('acha o nome do produtor sem diferenciar acento nem maiúscula', () {
      expect(_find('Orientei o sr. JOAO sobre o manejo.'), ['o nome "JOAO"']);
      expect(_find('Combinado com Santos o retorno.'), ['o nome "Santos"']);
    });

    test('acha o nome do veterinário', () {
      expect(_find('Atendido por Angela.'), ['o nome "Angela"']);
    });

    test('compara palavras inteiras e ignora partículas do nome', () {
      // "dos" é partícula; "Joãozinho" e "santoS…" dentro de outra palavra não contam
      expect(
        _find('Dose dos dois animais aplicada, santosal não usado.'),
        isEmpty,
      );
      expect(_find('Joãozinho é o nome do bezerro.'), isEmpty);
    });

    test('acha fazenda (sem o "Fazenda" do começo), cidade e brinco', () {
      expect(_find('Visita na Boa Esperança.'), ['o nome da fazenda']);
      expect(_find('Atendimento em votuporanga.'), ['a cidade']);
      expect(_find('Animal BR00427781 tratado.'), ['o número do brinco']);
      expect(_find('Fazenda vizinha com o mesmo problema.'), isEmpty);
    });

    test('acha contatos e registro profissional', () {
      expect(_find('Ligar no (17) 99123-4567.'), ['um telefone']);
      expect(_find('Mandar foto para vet@exemplo.com.br.'), ['um e-mail']);
      expect(_find('Nota para o CPF 123.456.789-09.'), ['um CPF']);
      expect(_find('Assinado, CRMV-SP 12345.'), ['o número do CRMV']);
    });

    test('números clínicos não são confundidos com telefone', () {
      expect(
        _find(
          'Peso 450 kg, temperatura 39,5 °C, 20 ml por 3 dias, em 13/11/2026.',
        ),
        isEmpty,
      );
    });

    test('funciona sem veterinário, fazenda e brinco', () {
      final call = _call(vetName: null, farmName: null, animalEarTag: null);
      expect(_find('Tratamento aplicado.', call), isEmpty);
      expect(_find('João acompanhou.', call), ['o nome "João"']);
    });

    test('mensagem lista todos os itens achados', () {
      final msg = ResolutionPrivacy.message(
        'João, ligar no 17 99123-4567 e passar na Boa Esperança.',
        _call(),
      );
      expect(
        msg,
        startsWith(
          'Tire do laudo o nome "João", o nome da fazenda e um telefone.',
        ),
      );
    });
  });
}
