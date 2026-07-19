export async function createGoogleMeetLink(accessToken: string): Promise<string> {
  const now = new Date();
  const end = new Date(now.getTime() + 60 * 60 * 1000);
  const requestId = `${Date.now()}-${Math.random().toString(36).slice(2)}`;

  const res = await fetch(
    "https://www.googleapis.com/calendar/v3/calendars/primary/events?conferenceDataVersion=1",
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        summary: "Duet call",
        start: { dateTime: now.toISOString(), timeZone: "UTC" },
        end: { dateTime: end.toISOString(), timeZone: "UTC" },
        conferenceData: {
          createRequest: {
            requestId,
            conferenceSolutionKey: { type: "hangoutsMeet" },
          },
        },
      }),
    }
  );

  if (!res.ok) {
    throw new Error(`calendar-api-error: ${res.status}`);
  }

  const data = (await res.json()) as {
    hangoutLink?: string;
    conferenceData?: {
      entryPoints?: Array<{ entryPointType?: string; uri?: string }>;
    };
  };

  if (data.hangoutLink) {
    return data.hangoutLink;
  }

  const entryPoint = data.conferenceData?.entryPoints?.find(
    (ep) => ep.entryPointType === "video"
  );
  if (entryPoint?.uri) {
    return entryPoint.uri;
  }

  throw new Error("no-meet-link");
}
