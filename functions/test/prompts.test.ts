process.env.FIRESTORE_EMULATOR_HOST ??= "127.0.0.1:8080";

import { initializeApp, getApps } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { describe, it, expect } from "vitest";
import { unlockMatchingPrompts } from "../src/promptsLogic";

if (getApps().length === 0) {
  initializeApp({ projectId: "duet-dev" });
}
const db = getFirestore();

async function seedCouple(coupleId: string, memberUids: string[]): Promise<void> {
  await db.collection("couples").doc(coupleId).set({
    memberUids,
    createdAt: FieldValue.serverTimestamp(),
  });
}

async function sealPrompt(
  coupleId: string,
  authorUid: string,
  pairKey: string,
  content: string
): Promise<string> {
  const ref = db.collection("couples").doc(coupleId).collection("prompts").doc();
  await ref.set({
    authorUid,
    pairKey,
    type: pairKey === "confession" ? "confession" : "question",
    content,
    createdAt: FieldValue.serverTimestamp(),
    unlockedAt: null,
  });
  return ref.id;
}

async function unlockedAtOf(coupleId: string, id: string): Promise<unknown> {
  const snap = await db
    .collection("couples")
    .doc(coupleId)
    .collection("prompts")
    .doc(id)
    .get();
  return snap.data()?.unlockedAt;
}

describe("unlockMatchingPrompts", () => {
  it(
    "leaves a prompt sealed when the partner has no match yet",
    async () => {
      await seedCouple("pc1", ["A", "B"]);
      const aId = await sealPrompt("pc1", "A", "q1", "A answer");

      const res = await unlockMatchingPrompts(db, "pc1", aId, {
        authorUid: "A",
        pairKey: "q1",
        unlockedAt: null,
      });

      expect(res.unlocked).toBe(false);
      expect(await unlockedAtOf("pc1", aId)).toBeNull();
    },
    10000
  );

  it(
    "reveals both prompts when partners share a question pairKey",
    async () => {
      await seedCouple("pc2", ["A", "B"]);
      const aId = await sealPrompt("pc2", "A", "q1", "A answer");
      const bId = await sealPrompt("pc2", "B", "q1", "B answer");

      const res = await unlockMatchingPrompts(db, "pc2", bId, {
        authorUid: "B",
        pairKey: "q1",
        unlockedAt: null,
      });

      expect(res.unlocked).toBe(true);
      expect(res.partnerPromptId).toBe(aId);
      expect(await unlockedAtOf("pc2", aId)).not.toBeNull();
      expect(await unlockedAtOf("pc2", bId)).not.toBeNull();
    },
    10000
  );

  it(
    "does not match across different pairKeys",
    async () => {
      await seedCouple("pc3", ["A", "B"]);
      await sealPrompt("pc3", "A", "q1", "A answer");
      const bId = await sealPrompt("pc3", "B", "q2", "B answer");

      const res = await unlockMatchingPrompts(db, "pc3", bId, {
        authorUid: "B",
        pairKey: "q2",
        unlockedAt: null,
      });

      expect(res.unlocked).toBe(false);
      expect(await unlockedAtOf("pc3", bId)).toBeNull();
    },
    10000
  );

  it(
    "pairs confessions FIFO with the partner's oldest sealed confession",
    async () => {
      await seedCouple("pc4", ["A", "B"]);
      const a1 = await sealPrompt("pc4", "A", "confession", "A first");
      await new Promise((r) => setTimeout(r, 50));
      const a2 = await sealPrompt("pc4", "A", "confession", "A second");
      const bId = await sealPrompt("pc4", "B", "confession", "B confesses");

      const res = await unlockMatchingPrompts(db, "pc4", bId, {
        authorUid: "B",
        pairKey: "confession",
        unlockedAt: null,
      });

      expect(res.unlocked).toBe(true);
      expect(res.partnerPromptId).toBe(a1);
      expect(await unlockedAtOf("pc4", a1)).not.toBeNull();
      expect(await unlockedAtOf("pc4", a2)).toBeNull();
      expect(await unlockedAtOf("pc4", bId)).not.toBeNull();
    },
    10000
  );

  it(
    "does not unlock while the couple is still pending",
    async () => {
      await seedCouple("pc5", ["A"]);
      const aId = await sealPrompt("pc5", "A", "q1", "A answer");

      const res = await unlockMatchingPrompts(db, "pc5", aId, {
        authorUid: "A",
        pairKey: "q1",
        unlockedAt: null,
      });

      expect(res.unlocked).toBe(false);
    },
    10000
  );

  it(
    "is a no-op for an already-unlocked prompt",
    async () => {
      await seedCouple("pc6", ["A", "B"]);
      await sealPrompt("pc6", "B", "q1", "B answer");
      const aId = await sealPrompt("pc6", "A", "q1", "A answer");

      const res = await unlockMatchingPrompts(db, "pc6", aId, {
        authorUid: "A",
        pairKey: "q1",
        unlockedAt: FieldValue.serverTimestamp(),
      });

      expect(res.unlocked).toBe(false);
    },
    10000
  );
});
