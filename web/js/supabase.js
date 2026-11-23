(() => {
  const cfg = window.SL_CONFIG || {};
  const root = String(cfg.supabaseUrl || "").replace(/\/$/, "");
  const key = cfg.supabasePublishableKey || "";
  window.SLApi = async function (path, body, prefer) {
    if (!root || !key) throw new Error("Supabase is not configured.");
    const headers = { apikey: key, Authorization: "Bearer " + key, "Content-Type": "application/json" };
    if (prefer) headers.Prefer = prefer;
    const response = await fetch(root + "/rest/v1/" + path, {
      method: body === undefined ? "GET" : "POST",
      headers,
      body: body === undefined ? undefined : JSON.stringify(body)
    });
    const data = await response.json().catch(() => null);
    if (!response.ok) {
      const err = new Error(data && (data.message || data.error_description) || "Supabase request failed.");
      err.code = data && data.code;
      err.details = data && data.details;
      throw err;
    }
    return data;
  };
})();
