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
  // Semeia perfis (com role) e um chamado aberto, ignorando as regras.
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'users/prod1'), { name: 'P1', role: 'producer' });
    await setDoc(doc(db, 'users/prod2'), { name: 'P2', role: 'producer' });
    await setDoc(doc(db, 'users/vet1'), { name: 'Dra. Ana', role: 'vet' });
    await setDoc(doc(db, 'users/vet2'), { name: 'Dr. Bob', role: 'vet' });
    await setDoc(doc(db, 'serviceCalls/call1'), callDoc());
    await setDoc(
      doc(db, 'serviceCalls/accepted1'),
      callDoc({ status: 'accepted', vetId: 'vet1', vetName: 'Dra. Ana' }),
    );
  });
});

// Atalhos para Firestore por contexto.
const asProd1 = () => testEnv.authenticatedContext('prod1').firestore();
const asProd2 = () => testEnv.authenticatedContext('prod2').firestore();
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

  test('dono atualiza nome (role inalterado)', async () => {
    await assertSucceeds(
      updateDoc(doc(asProd1(), 'users/prod1'), { name: 'Novo Nome' }),
    );
  });

  test('🔒 dono NÃO consegue se autopromover a veterinário', async () => {
    await assertFails(
      updateDoc(doc(asProd1(), 'users/prod1'), { role: 'vet' }),
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

  test('vet atribuído evolui o atendimento', async () => {
    await assertSucceeds(
      updateDoc(doc(asVet1(), 'serviceCalls/accepted1'), {
        status: 'inProgress',
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

  test('produtor cancela o próprio chamado aberto', async () => {
    await assertSucceeds(
      updateDoc(doc(asProd1(), 'serviceCalls/call1'), {
        status: 'cancelled',
      }),
    );
  });

  test('🔒 nenhum chamado pode ser deletado', async () => {
    await assertFails(deleteDoc(doc(asProd1(), 'serviceCalls/call1')));
  });
});
