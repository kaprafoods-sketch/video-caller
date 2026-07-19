import type { Firestore } from "firebase-admin/firestore";
import { FieldValue, Timestamp } from "firebase-admin/firestore";

export type PairingErrorCode =
  | "already-paired"
  | "invalid-code"
  | "code-expired"
  | "not-paired"
  | "couple-full";

export class PairingError extends Error {
  constructor(public code: PairingErrorCode, message?: string) {
    super(message ?? code);
  }
}

function generateCode(): string {
  return String(Math.floor(Math.random() * 1000000)).padStart(6, "0");
}

export async function createInviteFor(
  db: Firestore,
  uid: string
): Promise<{ coupleId: string; inviteCode: string }> {
  const userRef = db.collection("users").doc(uid);
  const userSnap = await userRef.get();
  const userData = userSnap.data();
  if (userData && userData.coupleId != null) {
    throw new PairingError("already-paired");
  }

  const couplesRef = db.collection("couples");
  let code = generateCode();
  for (let attempt = 0; attempt < 10; attempt++) {
    const existing = await couplesRef.where("inviteCode", "==", code).limit(1).get();
    if (existing.empty) {
      break;
    }
    code = generateCode();
  }

  const coupleRef = couplesRef.doc();
  const batch = db.batch();
  batch.set(coupleRef, {
    memberUids: [uid],
    createdAt: FieldValue.serverTimestamp(),
    inviteCode: code,
    inviteCodeExpiresAt: Timestamp.fromMillis(Date.now() + 24 * 60 * 60 * 1000),
  });
  batch.set(userRef, { coupleId: coupleRef.id }, { merge: true });
  await batch.commit();

  return { coupleId: coupleRef.id, inviteCode: code };
}

export async function redeemInviteFor(
  db: Firestore,
  uid: string,
  code: string
): Promise<{ coupleId: string }> {
  const couplesRef = db.collection("couples");
  const matches = await couplesRef.where("inviteCode", "==", code).limit(1).get();
  if (matches.empty) {
    throw new PairingError("invalid-code");
  }
  const coupleRef = matches.docs[0].ref;
  const userRef = db.collection("users").doc(uid);

  const result = await db.runTransaction(async (tx) => {
    const [coupleSnap, userSnap] = await Promise.all([tx.get(coupleRef), tx.get(userRef)]);

    const coupleData = coupleSnap.data();
    if (!coupleData || coupleData.inviteCode !== code) {
      throw new PairingError("invalid-code");
    }

    const expiresAt: Timestamp | undefined = coupleData.inviteCodeExpiresAt;
    if (!expiresAt || expiresAt.toMillis() <= Date.now()) {
      throw new PairingError("code-expired");
    }

    const memberUids: string[] = coupleData.memberUids ?? [];
    if (memberUids.length !== 1) {
      throw new PairingError("couple-full");
    }
    if (memberUids.includes(uid)) {
      throw new PairingError("couple-full");
    }

    const userData = userSnap.data();
    if (userData && userData.coupleId != null) {
      throw new PairingError("already-paired");
    }

    tx.update(coupleRef, {
      memberUids: [...memberUids, uid],
      inviteCode: FieldValue.delete(),
      inviteCodeExpiresAt: FieldValue.delete(),
    });
    tx.set(userRef, { coupleId: coupleRef.id }, { merge: true });

    return { coupleId: coupleRef.id };
  });

  return result;
}

export async function unpairFor(db: Firestore, uid: string): Promise<void> {
  const userRef = db.collection("users").doc(uid);
  const userSnap = await userRef.get();
  const userData = userSnap.data();
  if (!userData || userData.coupleId == null) {
    throw new PairingError("not-paired");
  }

  const coupleRef = db.collection("couples").doc(userData.coupleId as string);
  const coupleSnap = await coupleRef.get();
  const coupleData = coupleSnap.data();
  const memberUids: string[] = coupleData?.memberUids ?? [uid];

  const batch = db.batch();
  for (const memberUid of memberUids) {
    batch.set(db.collection("users").doc(memberUid), { coupleId: null }, { merge: true });
  }
  batch.delete(coupleRef);
  await batch.commit();
}
