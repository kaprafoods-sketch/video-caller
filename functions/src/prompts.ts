import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { getFirestore } from "firebase-admin/firestore";
import { unlockMatchingPrompts } from "./promptsLogic";

/**
 * When a partner seals a prompt, try to reveal it together with a matching
 * sealed prompt from the other partner. See promptsLogic for the mechanic.
 */
export const onPromptCreated = onDocumentCreated(
  "couples/{coupleId}/prompts/{promptId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const data = snap.data();
    const { coupleId, promptId } = event.params;

    await unlockMatchingPrompts(getFirestore(), coupleId, promptId, {
      authorUid: data.authorUid as string | undefined,
      pairKey: data.pairKey as string | undefined,
      unlockedAt: data.unlockedAt ?? null,
    });
  }
);
