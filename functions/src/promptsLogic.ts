import type { Firestore } from "firebase-admin/firestore";
import { FieldValue } from "firebase-admin/firestore";

export interface NewPromptData {
  authorUid?: string;
  pairKey?: string;
  unlockedAt?: unknown;
}

export interface UnlockResult {
  unlocked: boolean;
  partnerPromptId?: string;
}

/**
 * Reveals a sealed prompt and its partner counterpart at the same instant.
 *
 * A prompt stays private to its author (`unlockedAt == null`) until the
 * partner has also written a sealed prompt sharing the same `pairKey`
 * (a question's id, or the constant "confession" for free confessions).
 * When that pair exists, both docs get `unlockedAt` set together — so neither
 * partner ever sees the other's words before committing their own. Clients can
 * never set `unlockedAt` (Firestore rules deny prompt updates); only this
 * Admin-SDK path can, which is why the whole reveal lives server-side.
 */
export async function unlockMatchingPrompts(
  db: Firestore,
  coupleId: string,
  newPromptId: string,
  newData: NewPromptData
): Promise<UnlockResult> {
  const { authorUid, pairKey } = newData;
  if (!authorUid || !pairKey || newData.unlockedAt) {
    return { unlocked: false };
  }

  const coupleRef = db.collection("couples").doc(coupleId);
  const coupleData = (await coupleRef.get()).data();
  const memberUids: string[] = coupleData?.memberUids ?? [];
  if (memberUids.length !== 2) {
    return { unlocked: false };
  }
  const partnerUid = memberUids.find((u) => u !== authorUid);
  if (!partnerUid) {
    return { unlocked: false };
  }

  const promptsRef = coupleRef.collection("prompts");
  const partnerSealed = await promptsRef
    .where("authorUid", "==", partnerUid)
    .where("pairKey", "==", pairKey)
    .where("unlockedAt", "==", null)
    .get();
  if (partnerSealed.empty) {
    return { unlocked: false };
  }

  // Pair with the partner's oldest sealed prompt so reveals stay FIFO.
  const partnerDoc = partnerSealed.docs.reduce((a, b) => {
    const at = a.data().createdAt?.toMillis?.() ?? 0;
    const bt = b.data().createdAt?.toMillis?.() ?? 0;
    return at <= bt ? a : b;
  });

  const now = FieldValue.serverTimestamp();
  const batch = db.batch();
  batch.update(promptsRef.doc(newPromptId), { unlockedAt: now });
  batch.update(partnerDoc.ref, { unlockedAt: now });
  await batch.commit();

  return { unlocked: true, partnerPromptId: partnerDoc.id };
}
