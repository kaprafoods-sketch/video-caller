import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
  RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import { readFileSync } from 'fs';
import path from 'path';
import { beforeAll, afterAll, beforeEach, describe, it } from 'vitest';
import {
  getDoc,
  setDoc,
  updateDoc,
  doc,
  collection,
  addDoc,
  Timestamp,
} from 'firebase/firestore';

let testEnv: RulesTestEnvironment;

function authedDb(uid: string) {
  return testEnv.authenticatedContext(uid).firestore();
}

function unauthedDb() {
  return testEnv.unauthenticatedContext().firestore();
}

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'duet-dev',
    firestore: {
      rules: readFileSync(path.resolve(__dirname, '../../firestore.rules'), 'utf8'),
      host: '127.0.0.1',
      port: 8080,
    },
  });
});

afterAll(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();

  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();

    await setDoc(doc(db, 'couples/c1'), {
      memberUids: ['alice', 'bob'],
      createdAt: Timestamp.now(),
    });
    await setDoc(doc(db, 'users/alice'), { coupleId: 'c1' });
    await setDoc(doc(db, 'users/bob'), { coupleId: 'c1' });
    await setDoc(doc(db, 'users/carol'), { coupleId: null });

    await setDoc(doc(db, 'couples/c2'), {
      memberUids: ['dave'],
      inviteCode: 'ABC123',
      createdAt: Timestamp.now(),
    });
    await setDoc(doc(db, 'users/dave'), { coupleId: 'c2' });
  });
});

describe('couples/{coupleId}', () => {
  it('allows a member to read the couple doc', async () => {
    await assertSucceeds(getDoc(doc(authedDb('alice'), 'couples/c1')));
  });

  it('denies a non-member from reading the couple doc', async () => {
    await assertFails(getDoc(doc(authedDb('carol'), 'couples/c1')));
  });

  it('denies client writes to the couple doc even for members', async () => {
    await assertFails(
      setDoc(doc(authedDb('alice'), 'couples/c1'), {
        memberUids: ['alice', 'bob', 'eve'],
        createdAt: Timestamp.now(),
      })
    );
    await assertFails(
      updateDoc(doc(authedDb('alice'), 'couples/c1'), {
        memberUids: ['alice', 'bob', 'eve'],
      })
    );
  });
});

describe('users/{uid}', () => {
  it('denies changing coupleId via update', async () => {
    await assertFails(updateDoc(doc(authedDb('alice'), 'users/alice'), { coupleId: 'other' }));
  });

  it('allows updating other fields while leaving coupleId unchanged', async () => {
    await assertSucceeds(
      updateDoc(doc(authedDb('alice'), 'users/alice'), { displayName: 'A2' })
    );
  });
});

describe('couples/{coupleId}/moods', () => {
  it('allows a member to create a mood for themself', async () => {
    await assertSucceeds(
      addDoc(collection(authedDb('alice'), 'couples/c1/moods'), {
        uid: 'alice',
        mood: 'happy',
        note: '',
        createdAt: Timestamp.now(),
      })
    );
  });

  it('denies a non-member from creating a mood', async () => {
    await assertFails(
      addDoc(collection(authedDb('carol'), 'couples/c1/moods'), {
        uid: 'carol',
        mood: 'happy',
        note: '',
        createdAt: Timestamp.now(),
      })
    );
  });

  it('denies creating a mood with another uid', async () => {
    await assertFails(
      addDoc(collection(authedDb('alice'), 'couples/c1/moods'), {
        uid: 'bob',
        mood: 'happy',
        note: '',
        createdAt: Timestamp.now(),
      })
    );
  });
});

describe('couples/{coupleId}/calls', () => {
  it('allows a member to create a call started by themself', async () => {
    await assertSucceeds(
      addDoc(collection(authedDb('alice'), 'couples/c1/calls'), {
        meetUrl: 'x',
        startedBy: 'alice',
        startedAt: Timestamp.now(),
      })
    );
  });

  it('denies creating a call started by someone else', async () => {
    await assertFails(
      addDoc(collection(authedDb('alice'), 'couples/c1/calls'), {
        meetUrl: 'x',
        startedBy: 'bob',
        startedAt: Timestamp.now(),
      })
    );
  });

  it('denies a non-member from creating a call', async () => {
    await assertFails(
      addDoc(collection(authedDb('carol'), 'couples/c1/calls'), {
        meetUrl: 'x',
        startedBy: 'carol',
        startedAt: Timestamp.now(),
      })
    );
  });
});

describe('couples/{coupleId}/movieNights', () => {
  it('allows a member to create a movie night', async () => {
    await assertSucceeds(
      addDoc(collection(authedDb('alice'), 'couples/c1/movieNights'), {
        title: 'Movie',
      })
    );
  });

  it('denies a non-member from creating a movie night', async () => {
    await assertFails(
      addDoc(collection(authedDb('carol'), 'couples/c1/movieNights'), {
        title: 'Movie',
      })
    );
  });
});

describe('pending couple subcollections', () => {
  it('denies subcollection writes when the couple is not full', async () => {
    await assertFails(
      addDoc(collection(authedDb('dave'), 'couples/c2/moods'), {
        uid: 'dave',
        mood: 'happy',
        note: '',
        createdAt: Timestamp.now(),
      })
    );
  });
});

describe('couples/{coupleId}/prompts visibility', () => {
  beforeEach(async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await setDoc(doc(db, 'couples/c1/prompts/p1'), {
        type: 'question',
        authorUid: 'alice',
        content: 'secret',
        unlockedAt: null,
      });
      await setDoc(doc(db, 'couples/c1/prompts/p2'), {
        type: 'question',
        authorUid: 'alice',
        content: 'shown',
        unlockedAt: Timestamp.now(),
      });
    });
  });

  it('allows the author to read their own locked prompt', async () => {
    await assertSucceeds(getDoc(doc(authedDb('alice'), 'couples/c1/prompts/p1')));
  });

  it('denies a non-author member from reading a locked prompt', async () => {
    await assertFails(getDoc(doc(authedDb('bob'), 'couples/c1/prompts/p1')));
  });

  it('allows a non-author member to read an unlocked prompt', async () => {
    await assertSucceeds(getDoc(doc(authedDb('bob'), 'couples/c1/prompts/p2')));
  });

  it('denies a non-member from reading an unlocked prompt', async () => {
    await assertFails(getDoc(doc(authedDb('carol'), 'couples/c1/prompts/p2')));
  });
});

describe('couples/{coupleId}/prompts create', () => {
  it('allows a member to create a prompt authored by themself, locked', async () => {
    await assertSucceeds(
      addDoc(collection(authedDb('alice'), 'couples/c1/prompts'), {
        type: 'question',
        authorUid: 'alice',
        content: 'x',
        unlockedAt: null,
      })
    );
  });

  it('denies creating a prompt authored by someone else', async () => {
    await assertFails(
      addDoc(collection(authedDb('alice'), 'couples/c1/prompts'), {
        type: 'question',
        authorUid: 'bob',
        content: 'x',
        unlockedAt: null,
      })
    );
  });

  it('denies creating a prompt that is already unlocked', async () => {
    await assertFails(
      addDoc(collection(authedDb('alice'), 'couples/c1/prompts'), {
        type: 'question',
        authorUid: 'alice',
        content: 'x',
        unlockedAt: Timestamp.now(),
      })
    );
  });

  it('denies creating a prompt with an invalid type', async () => {
    await assertFails(
      addDoc(collection(authedDb('alice'), 'couples/c1/prompts'), {
        type: 'invalid',
        authorUid: 'alice',
        content: 'x',
        unlockedAt: null,
      })
    );
  });
});

describe('couples/{coupleId}/prompts update', () => {
  beforeEach(async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await setDoc(doc(db, 'couples/c1/prompts/p1'), {
        type: 'question',
        authorUid: 'alice',
        content: 'secret',
        unlockedAt: null,
      });
    });
  });

  it('denies unlocking a prompt via client update, for author or member', async () => {
    await assertFails(
      updateDoc(doc(authedDb('bob'), 'couples/c1/prompts/p1'), { unlockedAt: Timestamp.now() })
    );
    await assertFails(
      updateDoc(doc(authedDb('alice'), 'couples/c1/prompts/p1'), { unlockedAt: Timestamp.now() })
    );
  });
});
