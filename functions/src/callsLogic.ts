import type { Firestore } from "firebase-admin/firestore";
import { FieldValue } from "firebase-admin/firestore";

export type CallErrorCode = "not-paired" | "not-a-member" | "couple-not-full";

export class CallError extends Error {
  constructor(public code: CallErrorCode, message?: string) {
    super(message ?? code);
  }
}

export async function createCallFor(
  db: Firestore,
  uid: string,
  coupleId: string,
  getMeetLink: () => Promise<string>
): Promise<{ callId: string; meetUrl: string }> {
  const coupleRef = db.collection("couples").doc(coupleId);
  const coupleSnap = await coupleRef.get();
  const coupleData = coupleSnap.data();
  if (!coupleData) {
    throw new CallError("not-paired");
  }

  const memberUids: string[] = coupleData.memberUids ?? [];
  if (memberUids.length !== 2) {
    throw new CallError("couple-not-full");
  }
  if (!memberUids.includes(uid)) {
    throw new CallError("not-a-member");
  }

  const meetUrl = await getMeetLink();

  const callRef = coupleRef.collection("calls").doc();
  await callRef.set({
    meetUrl,
    startedBy: uid,
    startedAt: FieldValue.serverTimestamp(),
    endedAt: null,
  });

  return { callId: callRef.id, meetUrl };
}

export async function endCallFor(db: Firestore, uid: string, coupleId: string): Promise<void> {
  const coupleRef = db.collection("couples").doc(coupleId);
  const coupleSnap = await coupleRef.get();
  const coupleData = coupleSnap.data();
  if (!coupleData) {
    throw new CallError("not-paired");
  }

  const memberUids: string[] = coupleData.memberUids ?? [];
  if (!memberUids.includes(uid)) {
    throw new CallError("not-a-member");
  }

  const activeCalls = await coupleRef
    .collection("calls")
    .where("endedAt", "==", null)
    .orderBy("startedAt", "desc")
    .limit(1)
    .get();

  if (activeCalls.empty) {
    return;
  }

  await activeCalls.docs[0].ref.update({ endedAt: FieldValue.serverTimestamp() });
}
