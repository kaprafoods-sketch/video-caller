/**
 * Cap concurrent instances for every function. This is a cost-safety guard,
 * not a scaling target: a two-person couples app never needs more than a
 * couple of instances, and the cap ensures a bug or abuse can't fan out into
 * a surprise bill on the Blaze free tier.
 */
export const MAX_INSTANCES = 3;
