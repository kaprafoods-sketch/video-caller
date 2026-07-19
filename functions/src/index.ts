import { initializeApp } from "firebase-admin/app";

initializeApp();

export { createInvite, redeemInvite, unpair } from "./pairing";
