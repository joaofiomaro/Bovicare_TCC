import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { after, before, beforeEach, describe, test } from 'node:test';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  doc,
  deleteDoc,
  getDoc,
  getDocs,
  query,
  setDoc,
  updateDoc,
  where,
} from 'firebase/firestore';

const __dirname = dirname(fileURLToPath(import.meta.url));

/** Documento de chamado válido (campos exigidos/checados pelas regras). */
function callDoc(overrides = {}) {
  return {
    producerId: 'prod1',
    producerName: 'Produtor 1',
    city: 'Bagé',
    state: 'RS',
    title: 'Vaca mancando',
    description: 'Pata dianteira inchada',
    urgency: 'high',
    status: 'open',
    createdAtIso: '2026-06-07T10:00:00.000Z',
    ...overrides,
  };
}

/** Perfil válido (schema exigido pelas regras). */
function profileDoc(overrides = {}) {
  return {
    name: 'Produtor Novo',
    email: 'novo@bovicare.com',
    role: 'producer',
    ...overrides,
  };
}

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'bovicare-rules-test',
    firestore: {
      rules: readFileSync(join(__dirname, '..', 'firestore.rules'), 'utf8'),
    },
  });
});

after(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
  // Semeia perfis (com role) e chamados em vários estados, ignorando as regras.
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'users/prod1'), { name: 'P1', email: 'p1@x.com', role: 'producer' });
    await setDoc(doc(db, 'users/prod2'), { name: 'P2', email: 'p2@x.com', role: 'producer' });
    await setDoc(doc(db, 'users/vet1'), { name: 'Dra. Ana', email: 'ana@x.com', role: 'vet' });
    await setDoc(doc(db, 'users/vet2'), { name: 'Dr. Bob', email: 'bob@x.com', role: 'vet' });
    await setDoc(doc(db, 'serviceCalls/call1'), callDoc());
    await setDoc(
      doc(db, 'serviceCalls/accepted1'),
      callDoc({ status: 'accepted', vetId: 'vet1', vetName: 'Dra. Ana' }),
    );
    await setDoc(
      doc(db, 'serviceCalls/inprogress1'),
      callDoc({ status: 'inProgress', vetId: 'vet1', vetName: 'Dra. Ana' }),
    );
    await setDoc(
      doc(db, 'serviceCalls/done1'),
      callDoc({
        status: 'completed',
        vetId: 'vet1',
        vetName: 'Dra. Ana',
        resolution: 'Tratado',
        completedAtIso: '2026-06-08T10:00:00.000Z',
      }),
    );
  });
});

// Atalhos para Firestore por contexto.
const asProd1 = () => testEnv.authenticatedContext('prod1').firestore();
const asProd2 = () => testEnv.authenticatedContext('prod2').firestore();
const asProd3 = () => testEnv.authenticatedContext('prod3').firestore();
const asVet1 = () => testEnv.authenticatedContext('vet1').firestore();
const asVet2 = () => testEnv.authenticatedContext('vet2').firestore();
const asAnon = () => testEnv.unauthenticatedContext().firestore();

describe('Perfil do usuário', () => {
  test('dono lê o próprio perfil', async () => {
    await assertSucceeds(getDoc(doc(asProd1(), 'users/prod1')));
  });

  test('não-dono NÃO lê perfil alheio', async () => {
    await assertFails(getDoc(doc(asProd2(), 'users/prod1')));
  });

  test('anônimo NÃO lê perfil', async () => {
    await assertFails(getDoc(doc(asAnon(), 'users/prod1')));
  });

  test('cria o próprio perfil com schema válido', async () => {
    await assertSucceeds(setDoc(doc(asProd3(), 'users/prod3'), profileDoc()));
  });

  test('NÃO cria perfil em nome de outro uid', async () => {
    await assertFails(setDoc(doc(asProd3(), 'users/outro'), profileDoc()));
  });

  test('🔒 NÃO cria perfil com papel desconhecido (ex.: admin)', async () => {
    await assertFails(
      setDoc(doc(asProd3(), 'users/prod3'), profileDoc({ role: 'admin' })),
    );
  });

  test('NÃO cria perfil com campo fora do schema', async () => {
    await assertFails(
      setDoc(doc(asProd3(), 'users/prod3'), profileDoc({ isAdmin: true })),
    );
  });

  test('NÃO cria perfil com nome vazio', async () => {
    await assertFails(
      setDoc(doc(asProd3(), 'users/prod3'), profileDoc({ name: '' })),
    );
  });

  test('dono atualiza nome (role inalterado)', async () => {
    await assertSucceeds(
      updateDoc(doc(asProd1(), 'users/prod1'), { name: 'Novo Nome' }),
    );
  });

  test('dono marca demoSeededAt (usado pelo seed do rebanho demo)', async () => {
    await assertSucceeds(
      updateDoc(doc(asProd1(), 'users/prod1'), { demoSeededAt: new Date() }),
    );
  });

  test('🔒 dono NÃO consegue se autopromover a veterinário', async () => {
    await assertFails(
      updateDoc(doc(asProd1(), 'users/prod1'), { role: 'vet' }),
    );
  });

  test('🔒 dono NÃO altera o e-mail do perfil', async () => {
    await assertFails(
      updateDoc(doc(asProd1(), 'users/prod1'), { email: 'outro@x.com' }),
    );
  });
});

describe('Subcoleções privadas (animals/vaccinations/sales/weighings)', () => {
  test('dono escreve nas próprias vendas (M2)', async () => {
    await assertSucceeds(
      setDoc(doc(asProd1(), 'users/prod1/sales/s1'), {
        totalValue: 9000,
        headCount: 2,
      }),
    );
  });

  test('dono escreve nas próprias pesagens (M3)', async () => {
    await assertSucceeds(
      setDoc(doc(asProd1(), 'users/prod1/weighings/w1'), {
        animalId: 'a1',
        weightKg: 350,
      }),
    );
  });

  test('dono escreve nos próprios animais', async () => {
    await assertSucceeds(
      setDoc(doc(asProd1(), 'users/prod1/animals/a1'), { earTag: '001' }),
    );
  });

  test('NÃO escreve em subcoleção alheia', async () => {
    await assertFails(
      setDoc(doc(asProd2(), 'users/prod1/sales/s1'), { totalValue: 1 }),
    );
  });

  test('NÃO escreve em subcoleção desconhecida pelo app', async () => {
    await assertFails(
      setDoc(doc(asProd1(), 'users/prod1/secrets/x'), { any: 1 }),
    );
  });

  test('dono registra eventos de manejo (healthEvents)', async () => {
    await assertSucceeds(
      setDoc(doc(asProd1(), 'users/prod1/healthEvents/h1'), {
        animalId: 'a1',
        type: 'deworming',
        title: 'Ivermectina',
        withdrawalDays: 35,
      }),
    );
  });

  test('NÃO lê manejos de outro produtor', async () => {
    await assertFails(getDoc(doc(asProd2(), 'users/prod1/healthEvents/h1')));
  });

  test('dono salva configurações de alertas e consentimentos', async () => {
    await assertSucceeds(
      setDoc(doc(asProd1(), 'users/prod1/settings/alerts'), { leadDays: 15 }),
    );
    await assertSucceeds(
      setDoc(doc(asProd1(), 'users/prod1/settings/consents'), {
        location: { granted: false },
      }),
    );
  });

  test('NÃO cria documento de configuração desconhecido', async () => {
    await assertFails(
      setDoc(doc(asProd1(), 'users/prod1/settings/admin'), { x: 1 }),
    );
  });
});

/** Perfil profissional público válido. */
function vetProfile(overrides = {}) {
  return {
    name: 'Dra. Ana',
    crmv: 'CRMV-SP 12345',
    specialties: ['Reprodução'],
    phone: '+5519999990000',
    city: 'Rio Claro',
    state: 'SP',
    lat: -22.41,
    lng: -47.56,
    isAvailable: true,
    coverageRadiusKm: 50,
    ...overrides,
  };
}

describe('Diretório de veterinários (vets)', () => {
  test('vet publica o próprio perfil', async () => {
    await assertSucceeds(setDoc(doc(asVet1(), 'vets/vet1'), vetProfile()));
  });

  test('🔒 produtor NÃO publica perfil de veterinário', async () => {
    await assertFails(setDoc(doc(asProd1(), 'vets/prod1'), vetProfile()));
  });

  test('🔒 vet NÃO publica perfil em nome de outro vet', async () => {
    await assertFails(setDoc(doc(asVet1(), 'vets/vet2'), vetProfile()));
  });

  test('NÃO publica perfil com campos inválidos', async () => {
    await assertFails(
      setDoc(doc(asVet1(), 'vets/vet1'), vetProfile({ specialties: [] })),
    );
    await assertFails(
      setDoc(doc(asVet1(), 'vets/vet1'), vetProfile({ coverageRadiusKm: 9999 })),
    );
    await assertFails(
      setDoc(doc(asVet1(), 'vets/vet1'), vetProfile({ verified: true })),
    );
  });

  test('qualquer usuário logado consulta o diretório; anônimo não', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'vets/vet1'), vetProfile());
    });
    await assertSucceeds(getDoc(doc(asProd1(), 'vets/vet1')));
    await assertFails(getDoc(doc(asAnon(), 'vets/vet1')));
  });

  test('vet retira o próprio perfil; outro usuário não', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'vets/vet1'), vetProfile());
    });
    await assertFails(deleteDoc(doc(asVet2(), 'vets/vet1')));
    await assertSucceeds(deleteDoc(doc(asVet1(), 'vets/vet1')));
  });
});

describe('Chamados — criação', () => {
  test('produtor cria o próprio chamado aberto', async () => {
    await assertSucceeds(
      setDoc(doc(asProd1(), 'serviceCalls/new1'), callDoc()),
    );
  });

  test('NÃO cria chamado em nome de outro produtor', async () => {
    await assertFails(
      setDoc(
        doc(asProd1(), 'serviceCalls/new2'),
        callDoc({ producerId: 'prod2' }),
      ),
    );
  });

  test('NÃO cria chamado já com vet pré-atribuído', async () => {
    await assertFails(
      setDoc(
        doc(asProd1(), 'serviceCalls/new3'),
        callDoc({ vetId: 'vet1' }),
      ),
    );
  });

  test('NÃO cria chamado com status diferente de open', async () => {
    await assertFails(
      setDoc(
        doc(asProd1(), 'serviceCalls/new4'),
        callDoc({ status: 'accepted' }),
      ),
    );
  });

  test('NÃO cria chamado com urgência fora do enum', async () => {
    await assertFails(
      setDoc(
        doc(asProd1(), 'serviceCalls/new5'),
        callDoc({ urgency: 'critical' }),
      ),
    );
  });

  test('NÃO cria chamado com campo fora do schema', async () => {
    await assertFails(
      setDoc(
        doc(asProd1(), 'serviceCalls/new6'),
        callDoc({ priorityOverride: 999 }),
      ),
    );
  });

  test('NÃO cria chamado com título vazio', async () => {
    await assertFails(
      setDoc(doc(asProd1(), 'serviceCalls/new7'), callDoc({ title: '' })),
    );
  });

  test('NÃO cria chamado com UF inválida', async () => {
    await assertFails(
      setDoc(
        doc(asProd1(), 'serviceCalls/new8'),
        callDoc({ state: 'Rio Grande do Sul' }),
      ),
    );
  });

  test('NÃO cria chamado já com laudo (resolution)', async () => {
    await assertFails(
      setDoc(
        doc(asProd1(), 'serviceCalls/new9'),
        callDoc({ resolution: 'x' }),
      ),
    );
  });
});

describe('Chamados — leitura', () => {
  test('produtor lê o próprio chamado', async () => {
    await assertSucceeds(getDoc(doc(asProd1(), 'serviceCalls/call1')));
  });

  test('🔒 produtor NÃO lê chamado de outro produtor', async () => {
    await assertFails(getDoc(doc(asProd2(), 'serviceCalls/call1')));
  });

  test('vet lê chamado aberto do pool', async () => {
    await assertSucceeds(getDoc(doc(asVet1(), 'serviceCalls/call1')));
  });

  test('vet atribuído lê o próprio chamado encerrado', async () => {
    await assertSucceeds(getDoc(doc(asVet1(), 'serviceCalls/done1')));
  });

  test('🔒 vet de fora NÃO lê chamado atribuído a outro vet', async () => {
    await assertFails(getDoc(doc(asVet2(), 'serviceCalls/accepted1')));
  });

  test('vet faz query do pool aberto', async () => {
    await assertSucceeds(
      getDocs(
        query(
          collection(asVet1(), 'serviceCalls'),
          where('status', '==', 'open'),
        ),
      ),
    );
  });

  test('produtor faz query dos próprios chamados', async () => {
    await assertSucceeds(
      getDocs(
        query(
          collection(asProd1(), 'serviceCalls'),
          where('producerId', '==', 'prod1'),
        ),
      ),
    );
  });

  test('produtor NÃO faz query de chamados alheios', async () => {
    await assertFails(
      getDocs(
        query(
          collection(asProd1(), 'serviceCalls'),
          where('producerId', '==', 'prod2'),
        ),
      ),
    );
  });
});

describe('Chamados — aceitar / evoluir / cancelar', () => {
  test('vet aceita um chamado aberto (open → accepted)', async () => {
    await assertSucceeds(
      updateDoc(doc(asVet1(), 'serviceCalls/call1'), {
        status: 'accepted',
        vetId: 'vet1',
        vetName: 'Dra. Ana',
      }),
    );
  });

  test('🔒 vet NÃO aceita chamado já aceito por outro', async () => {
    await assertFails(
      updateDoc(doc(asVet2(), 'serviceCalls/accepted1'), {
        status: 'accepted',
        vetId: 'vet2',
        vetName: 'Dr. Bob',
      }),
    );
  });

  test('🔒 vet NÃO aceita em nome de outro vetId', async () => {
    await assertFails(
      updateDoc(doc(asVet1(), 'serviceCalls/call1'), {
        status: 'accepted',
        vetId: 'vet2',
        vetName: 'Dr. Bob',
      }),
    );
  });

  test('vet NÃO altera a descrição ao aceitar', async () => {
    await assertFails(
      updateDoc(doc(asVet1(), 'serviceCalls/call1'), {
        status: 'accepted',
        vetId: 'vet1',
        vetName: 'Dra. Ana',
        description: 'Adulterada',
      }),
    );
  });

  test('vet atribuído evolui o atendimento', async () => {
    await assertSucceeds(
      updateDoc(doc(asVet1(), 'serviceCalls/accepted1'), {
        status: 'inProgress',
      }),
    );
  });

  test('vet atribuído agenda a visita', async () => {
    await assertSucceeds(
      updateDoc(doc(asVet1(), 'serviceCalls/accepted1'), {
        status: 'inProgress',
        scheduledDateIso: '2026-06-10T09:00:00.000Z',
      }),
    );
  });

  test('vet atribuído conclui com laudo', async () => {
    await assertSucceeds(
      updateDoc(doc(asVet1(), 'serviceCalls/inprogress1'), {
        status: 'completed',
        resolution: 'Animal tratado, retorno em 7 dias.',
        completedAtIso: '2026-06-09T10:00:00.000Z',
      }),
    );
  });

  test('vet atribuído NÃO conclui sem laudo', async () => {
    await assertFails(
      updateDoc(doc(asVet1(), 'serviceCalls/inprogress1'), {
        status: 'completed',
        completedAtIso: '2026-06-09T10:00:00.000Z',
      }),
    );
  });

  test('🔒 vet de fora NÃO evolui chamado de terceiro', async () => {
    await assertFails(
      updateDoc(doc(asVet2(), 'serviceCalls/accepted1'), {
        status: 'inProgress',
      }),
    );
  });

  test('vet atribuído NÃO altera dados de origem do produtor', async () => {
    await assertFails(
      updateDoc(doc(asVet1(), 'serviceCalls/accepted1'), {
        producerName: 'Adulterado',
      }),
    );
  });

  test('🔒 vet atribuído NÃO transfere o chamado para outro vet', async () => {
    await assertFails(
      updateDoc(doc(asVet1(), 'serviceCalls/accepted1'), {
        vetId: 'vet2',
        vetName: 'Dr. Bob',
      }),
    );
  });

  test('🔒 chamado concluído é imutável (não reabre)', async () => {
    await assertFails(
      updateDoc(doc(asVet1(), 'serviceCalls/done1'), {
        status: 'inProgress',
      }),
    );
  });

  test('produtor cancela o próprio chamado aberto', async () => {
    await assertSucceeds(
      updateDoc(doc(asProd1(), 'serviceCalls/call1'), {
        status: 'cancelled',
      }),
    );
  });

  test('produtor NÃO cancela chamado já aceito', async () => {
    await assertFails(
      updateDoc(doc(asProd1(), 'serviceCalls/accepted1'), {
        status: 'cancelled',
      }),
    );
  });

  test('produtor NÃO edita o chamado ao cancelar', async () => {
    await assertFails(
      updateDoc(doc(asProd1(), 'serviceCalls/call1'), {
        status: 'cancelled',
        title: 'Editado',
      }),
    );
  });

  test('🔒 produtor NÃO se auto-atribui como vet', async () => {
    await assertFails(
      updateDoc(doc(asProd1(), 'serviceCalls/call1'), {
        status: 'accepted',
        vetId: 'prod1',
        vetName: 'P1',
      }),
    );
  });

  test('🔒 nenhum chamado pode ser deletado', async () => {
    await assertFails(deleteDoc(doc(asProd1(), 'serviceCalls/call1')));
  });
});
