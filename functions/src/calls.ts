import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";
import { CallError, createCallFor, endCallFor } from "./callsLogic";
import { createGoogleMeetLink } from "./googleMeet";
import { MAX_INSTANCES } from "./runtimeOptions";

function mapCallError(e: unknown): never {
  if (e instanceof CallError) {
    throw new HttpsError("failed-precondition", e.message, { code: e.code });
  }
  if (e instanceof HttpsError) {
    throw e;
  }
  if (
    e instanceof Error &&
    (e.message.startsWith("calendar-api-error") || e.message.startsWith("no-meet-link"))
  ) {
    throw new HttpsError("internal", e.message, { code: "meet-link-failed" });
  }
  throw e;
}

export const createCall = onCall({ maxInstances: MAX_INSTANCES }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in.");
  }
  const coupleId = request.data?.coupleId as string;
  const accessToken = request.data?.accessToken as string;
  if (!coupleId || !accessToken) {
    throw new HttpsError("invalid-argument", "coupleId and accessToken are required.");
  }
  try {
    return await createCallFor(getFirestore(), request.auth.uid, coupleId, () =>
      createGoogleMeetLink(accessToken)
    );
  } catch (e) {
    mapCallError(e);
  }
});

export const endCall = onCall({ maxInstances: MAX_INSTANCES }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in.");
  }
  const coupleId = request.data?.coupleId as string;
  if (!coupleId) {
    throw new HttpsError("invalid-argument", "coupleId is required.");
  }
  try {
    await endCallFor(getFirestore(), request.auth.uid, coupleId);
    return { ok: true };
  } catch (e) {
    mapCallError(e);
  }
});
