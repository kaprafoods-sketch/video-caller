import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";
import { PairingError, createInviteFor, redeemInviteFor, unpairFor } from "./pairingLogic";

export const createInvite = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in.");
  }
  try {
    return await createInviteFor(getFirestore(), request.auth.uid);
  } catch (e) {
    if (e instanceof PairingError) {
      throw new HttpsError("failed-precondition", e.message, { code: e.code });
    }
    throw e;
  }
});

export const redeemInvite = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in.");
  }
  const code = request.data?.code as string;
  try {
    return await redeemInviteFor(getFirestore(), request.auth.uid, code);
  } catch (e) {
    if (e instanceof PairingError) {
      throw new HttpsError("failed-precondition", e.message, { code: e.code });
    }
    throw e;
  }
});

export const unpair = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in.");
  }
  try {
    await unpairFor(getFirestore(), request.auth.uid);
    return { success: true };
  } catch (e) {
    if (e instanceof PairingError) {
      throw new HttpsError("failed-precondition", e.message, { code: e.code });
    }
    throw e;
  }
});
