process.env.FIRESTORE_EMULATOR_HOST ??= "127.0.0.1:8080";

import { initializeApp, getApps } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { describe, it, expect } from "vitest";
import { createCallFor, endCallFor, CallError } from "../src/callsLogic";

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

const fakeMeet = async (): Promise<string> => "https://meet.google.com/abc-defg-hij";

async function expectCallError(promise: Promise<unknown>, code: string): Promise<void> {
  await expect(promise).rejects.toThrow();
  try {
    await promise;
    throw new Error("expected promise to reject");
  } catch (err) {
    expect(err).toBeInstanceOf(CallError);
    expect((err as CallError).code).toBe(code);
  }
}

describe("callsLogic", () => {
  it(
    "createCallFor happy path",
    async () => {
      await seedCouple("cc1", ["A", "B"]);
      const res = await createCallFor(db, "A", "cc1", fakeMeet);

      expect(res.meetUrl).toBe("https://meet.google.com/abc-defg-hij");
      expect(typeof res.callId).toBe("string");
      expect(res.callId.length).toBeGreaterThan(0);

      const callSnap = await db
        .collection("couples")
        .doc("cc1")
        .collection("calls")
        .doc(res.callId)
        .get();
      const callData = callSnap.data();
      expect(callData?.meetUrl).toBe(res.meetUrl);
      expect(callData?.startedBy).toBe("A");
      expect(callData?.endedAt).toBeNull();
      expect(callData?.startedAt).not.toBeNull();
      expect(callData?.startedAt).toBeDefined();
    },
    10000
  );

  it(
    "createCallFor uses the injected meet link provider exactly once",
    async () => {
      await seedCouple("cc1b", ["A", "B"]);
      let calls = 0;
      const spyMeet = async (): Promise<string> => {
        calls += 1;
        return "https://meet.google.com/spy-link";
      };

      const res = await createCallFor(db, "A", "cc1b", spyMeet);
      expect(calls).toBe(1);
      expect(res.meetUrl).toBe("https://meet.google.com/spy-link");
    },
    10000
  );

  it(
    "createCallFor rejects non-member with not-a-member",
    async () => {
      await seedCouple("cc2", ["A", "B"]);
      await expectCallError(createCallFor(db, "C", "cc2", fakeMeet), "not-a-member");
    },
    10000
  );

  it(
    "createCallFor rejects when couple is not full with couple-not-full",
    async () => {
      await seedCouple("cc3", ["A"]);
      await expectCallError(createCallFor(db, "A", "cc3", fakeMeet), "couple-not-full");
    },
    10000
  );

  it(
    "createCallFor rejects missing couple with not-paired",
    async () => {
      await expectCallError(createCallFor(db, "A", "nope-couple", fakeMeet), "not-paired");
    },
    10000
  );

  it(
    "endCallFor sets endedAt on the active call",
    async () => {
      await seedCouple("cc4", ["A", "B"]);
      const created = await createCallFor(db, "A", "cc4", fakeMeet);

      await endCallFor(db, "A", "cc4");

      const callSnap = await db
        .collection("couples")
        .doc("cc4")
        .collection("calls")
        .doc(created.callId)
        .get();
      expect(callSnap.data()?.endedAt).not.toBeNull();
    },
    10000
  );

  it(
    "endCallFor with no active call is a no-op",
    async () => {
      await seedCouple("cc5", ["A", "B"]);
      await expect(endCallFor(db, "A", "cc5")).resolves.toBeUndefined();
    },
    10000
  );

  it(
    "endCallFor rejects non-member with not-a-member",
    async () => {
      await seedCouple("cc6", ["A", "B"]);
      await expectCallError(endCallFor(db, "C", "cc6"), "not-a-member");
    },
    10000
  );
});
