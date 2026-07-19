process.env.FIRESTORE_EMULATOR_HOST ??= "127.0.0.1:8080";

import { initializeApp, getApps } from "firebase-admin/app";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { describe, it, expect, beforeEach } from "vitest";
import {
  createInviteFor,
  redeemInviteFor,
  unpairFor,
  PairingError,
} from "../src/pairingLogic";

if (getApps().length === 0) {
  initializeApp({ projectId: "duet-dev" });
}
const db = getFirestore();

async function seedUser(uid: string, coupleId: string | null = null): Promise<void> {
  await db.collection("users").doc(uid).set({
    displayName: "U",
    photoUrl: null,
    genrePreferences: [],
    coupleId,
  });
}

async function clearCollection(name: string): Promise<void> {
  const snap = await db.collection(name).get();
  const batch = db.batch();
  snap.docs.forEach((doc) => batch.delete(doc.ref));
  await batch.commit();
}

beforeEach(async () => {
  await clearCollection("couples");
  await clearCollection("users");
});

async function expectPairingError(promise: Promise<unknown>, code: string): Promise<void> {
  await expect(promise).rejects.toThrow();
  try {
    await promise;
    throw new Error("expected promise to reject");
  } catch (err) {
    expect(err).toBeInstanceOf(PairingError);
    expect((err as PairingError).code).toBe(code);
  }
}

describe("pairingLogic", () => {
  it(
    "happy path: create invite then redeem",
    async () => {
      await seedUser("A", null);
      const created = await createInviteFor(db, "A");
      expect(created.coupleId).toBeTruthy();
      expect(created.inviteCode).toMatch(/^\d{6}$/);

      await seedUser("B", null);
      const redeemed = await redeemInviteFor(db, "B", created.inviteCode);
      expect(redeemed.coupleId).toBe(created.coupleId);

      const coupleSnap = await db.collection("couples").doc(created.coupleId).get();
      const coupleData = coupleSnap.data();
      expect(coupleData?.memberUids).toEqual(["A", "B"]);
      expect(coupleData?.inviteCode).toBeUndefined();
      expect(coupleData?.inviteCodeExpiresAt).toBeUndefined();

      const userASnap = await db.collection("users").doc("A").get();
      const userBSnap = await db.collection("users").doc("B").get();
      expect(userASnap.data()?.coupleId).toBe(created.coupleId);
      expect(userBSnap.data()?.coupleId).toBe(created.coupleId);
    },
    10000
  );

  it(
    "wrong code: redeem rejects with invalid-code",
    async () => {
      await seedUser("A", null);
      const created = await createInviteFor(db, "A");
      const wrongCode = created.inviteCode === "000000" ? "111111" : "000000";

      await seedUser("B", null);
      await expectPairingError(redeemInviteFor(db, "B", wrongCode), "invalid-code");
    },
    10000
  );

  it(
    "expired code: redeem rejects with code-expired",
    async () => {
      await seedUser("A", null);
      const created = await createInviteFor(db, "A");

      await db.collection("couples").doc(created.coupleId).update({
        inviteCodeExpiresAt: Timestamp.fromMillis(Date.now() - 1000),
      });

      await seedUser("B", null);
      await expectPairingError(
        redeemInviteFor(db, "B", created.inviteCode),
        "code-expired"
      );
    },
    10000
  );

  it(
    "already-paired creator: createInviteFor rejects",
    async () => {
      await seedUser("A", "some-existing-couple");
      await expectPairingError(createInviteFor(db, "A"), "already-paired");
    },
    10000
  );

  it(
    "already-paired redeemer: redeemInviteFor rejects",
    async () => {
      await seedUser("A", null);
      const created = await createInviteFor(db, "A");

      await seedUser("B", "some-existing-couple");
      await expectPairingError(
        redeemInviteFor(db, "B", created.inviteCode),
        "already-paired"
      );
    },
    10000
  );

  it(
    "couple full: redeem rejects with couple-full",
    async () => {
      await seedUser("A", null);
      const created = await createInviteFor(db, "A");

      await seedUser("B", null);
      await redeemInviteFor(db, "B", created.inviteCode);

      await db.collection("couples").doc(created.coupleId).update({
        inviteCode: created.inviteCode,
        inviteCodeExpiresAt: Timestamp.fromMillis(Date.now() + 24 * 60 * 60 * 1000),
      });

      await seedUser("C", null);
      await expectPairingError(
        redeemInviteFor(db, "C", created.inviteCode),
        "couple-full"
      );
    },
    10000
  );

  it(
    "unpair: removes couple doc and clears coupleId on both users",
    async () => {
      await seedUser("A", null);
      const created = await createInviteFor(db, "A");
      await seedUser("B", null);
      await redeemInviteFor(db, "B", created.inviteCode);

      await unpairFor(db, "A");

      const coupleSnap = await db.collection("couples").doc(created.coupleId).get();
      expect(coupleSnap.exists).toBe(false);

      const userASnap = await db.collection("users").doc("A").get();
      const userBSnap = await db.collection("users").doc("B").get();
      expect(userASnap.data()?.coupleId).toBeNull();
      expect(userBSnap.data()?.coupleId).toBeNull();

      await expectPairingError(unpairFor(db, "A"), "not-paired");
    },
    10000
  );
});
