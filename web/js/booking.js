(() => {
  const $ = selector => document.querySelector(selector);
  const cfg = window.SL_CONFIG || {};
  const TZ = cfg.timezone || "Africa/Johannesburg";
  const state = { services: [], service: null, date: null, slot: null, slots: null, step: 1, error: "", email: "" };
  const esc = value => String(value ?? "").replace(/[&<>"]/g, ch => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[ch]));
  const money = value => Number(value) > 0 ? new Intl.NumberFormat("en-ZA", { style: "currency", currency: "ZAR", maximumFractionDigits: 0 }).format(Number(value)) : "Free";
  const time = value => new Date(value).toLocaleTimeString("en-GB", { hour: "2-digit", minute: "2-digit", hour12: false, timeZone: TZ });
  const longDate = ymd => new Date(ymd + "T12:00:00Z").toLocaleDateString("en-ZA", { weekday: "long", day: "numeric", month: "long", year: "numeric", timeZone: "UTC" });
  const today = () => new Intl.DateTimeFormat("en-CA", { timeZone: TZ, year: "numeric", month: "2-digit", day: "2-digit" }).format(new Date());
  function days() {
    const [year, month, day] = today().split("-").map(Number);
    return Array.from({ length: 14 }, (_, i) => {
      const date = new Date(Date.UTC(year, month - 1, day + i));
      return { ymd: date.toISOString().slice(0, 10), dow: date.getUTCDay(), wd: date.toLocaleDateString("en-ZA", { weekday: "short", timeZone: "UTC" }).toUpperCase(), n: date.getUTCDate() };
    });
  }
  function showError(message) { state.error = message; render(); }
  async function loadServices() {
    try { state.services = await window.SLApi("services?select=id,name,description,duration_minutes,price&active=eq.true&order=duration_minutes.asc"); }
    catch (error) { state.services = []; state.error = "We couldn’t load services. Please refresh or contact us."; }
    render();
  }
  function render() {
    const labels = ["Service", "Date & time", "Your details", "Confirmation"];
    $("#stepper").innerHTML = labels.map((label, i) => `<div class="${i + 1 < state.step ? "done" : i + 1 === state.step ? "cur" : ""}">${i + 1 < state.step ? "✓" : i + 1} <span class="lb">${label}</span></div>`).join("");
    $("#glance").innerHTML = state.service
      ? `<h3 class="session-name">${esc(state.service.name)}</h3><p class="small">${state.service.duration_minutes} minutes · Online · ${money(state.service.price)}</p>${state.date && state.slot ? `<p class="small">${longDate(state.date)}<br>${time(state.slot.slot_start)}–${time(state.slot.slot_end)} SAST</p>` : '<p class="small">Choose a date and time to continue.</p>'}`
      : '<p class="small">Choose a service to begin.</p>';
    const box = $("#bk");
    if (state.step === 1) {
      box.innerHTML = `<h2 class="form-heading">Choose your service</h2><p class="small mb-16">Choose the conversation that fits your idea.</p>
      ${state.services.length ? state.services.map(service => `<button type="button" class="opt ${state.service && state.service.id === service.id ? "sel" : ""}" data-pick="${esc(service.id)}"><span class="t">${esc(service.name)} <span>${state.service && state.service.id === service.id ? "✓" : "○"}</span></span><span class="small">${esc(service.description || "")}</span><span class="small block mt-8">${service.duration_minutes} min · ${money(service.price)}</span></button>`).join("") : '<div class="alert">Services are unavailable right now. Please refresh or contact us.</div>'}
      ${state.error ? `<div class="alert">${esc(state.error)}</div>` : ""}
      <div class="row"><span class="small">${state.service ? "" : "Select a service to continue."}</span><button class="btn" id="next" ${state.service ? "" : "disabled"}>Continue →</button></div>`;
      box.querySelectorAll("[data-pick]").forEach(button => button.addEventListener("click", () => {
        state.service = state.services.find(service => String(service.id) === button.dataset.pick);
        state.date = null; state.slot = null; state.slots = null; state.error = ""; render();
      }));
      $("#next")?.addEventListener("click", () => { state.step = 2; state.error = ""; render(); });
    } else if (state.step === 2) {
      const dateList = days();
      if (!state.date) state.date = (dateList.find(date => date.dow !== 0) || dateList[0]).ymd;
      box.innerHTML = `<h2 class="form-heading">Find your moment</h2>
      <div class="row compact"><span class="small primary-text">${esc(state.service.name)} · ${state.service.duration_minutes} min · ${money(state.service.price)}</span><button class="link" id="change-service">Change</button></div>
      <div class="dates">${dateList.map(date => `<button type="button" class="dc ${date.ymd === state.date ? "sel" : ""}" data-date="${date.ymd}" ${date.dow === 0 ? "disabled" : ""}>${date.wd}<small>${date.n}</small></button>`).join("")}</div>
      <h3 class="date-heading">${longDate(state.date)}</h3>${state.error ? `<div class="alert">${esc(state.error)}</div>` : ""}<div id="slots" class="slot-area"></div>
      <p class="small mt-12">Times shown in South Africa time (SAST, UTC+2).</p>
      <div class="row"><button class="link" id="back">← Back</button><button class="btn" id="next" ${state.slot ? "" : "disabled"}>Continue →</button></div>`;
      $("#change-service").addEventListener("click", () => { state.step = 1; state.error = ""; render(); });
      $("#back").addEventListener("click", () => { state.step = 1; state.error = ""; render(); });
      box.querySelectorAll("[data-date]").forEach(button => button.addEventListener("click", () => {
        state.date = button.dataset.date; state.slot = null; state.slots = null; state.error = ""; render();
      }));
      $("#next").addEventListener("click", () => { state.step = 3; state.error = ""; render(); });
      drawSlots();
    } else if (state.step === 3) {
      box.innerHTML = `<h2 class="form-heading">A few details, then you’re set.</h2>
      <form id="booking-form" novalidate>
        <label for="full-name">Full name</label><input id="full-name" autocomplete="name" maxlength="100" required placeholder="Your full name"><div class="err" id="name-error"></div>
        <label for="email">Email address</label><input id="email" type="email" autocomplete="email" maxlength="254" required placeholder="you@example.com"><div class="err" id="email-error"></div>
        <label for="phone">Phone number (optional)</label><input id="phone" type="tel" inputmode="tel" autocomplete="tel" maxlength="20" placeholder="+27 60 123 4567"><div class="err" id="phone-error"></div>
        <label for="notes">Notes (optional)</label><textarea id="notes" rows="3" maxlength="2000" placeholder="Anything you’d like me to know?"></textarea>
        <p class="small mt-12">I’ll only use these details to arrange your session.</p>
        ${state.error ? `<div class="alert">${esc(state.error)}</div>` : ""}
        <div class="row"><button type="button" class="link" id="back">← Back</button><button class="btn" id="confirm" type="submit">Confirm booking ↗</button></div>
      </form>`;
      $("#back").addEventListener("click", () => { state.step = 2; state.error = ""; render(); });
      $("#booking-form").addEventListener("submit", confirmBooking);
    } else {
      box.innerHTML = `<span class="ok">✓ Confirmed</span><h2 class="success-title">You’re booked. Let’s make progress.</h2>
      <p class="lead">Your ${esc(state.service.name.toLowerCase())} is confirmed. We’ll use <b>${esc(state.email)}</b> to contact you.</p>
      <div class="note"><b>${esc(state.service.name)}</b><br>${longDate(state.date)}<br>${time(state.slot.slot_start)}–${time(state.slot.slot_end)} · SAST (UTC+2)<br>Online session · ${money(state.service.price)}</div>
      <h3 class="mt-24">What happens next</h3><p class="small">1. Look out for follow-up details by email.<br>2. Bring your idea and any questions.<br>3. Payment, if any, is arranged after booking.</p>
      <p class="mt-24"><a class="btn" href="../index.html">Back to home ↗</a></p>`;
    }
  }
  async function drawSlots() {
    const slotBox = $("#slots");
    if (!slotBox || !state.service) return;
    slotBox.innerHTML = '<div class="slots">' + '<div class="skel"></div>'.repeat(6) + '</div><p class="small mt-8">Loading available times…</p>';
    const requestedKey = String(state.service.id) + state.date;
    try {
      const result = await window.SLApi("rpc/get_available_slots", { p_service_id: state.service.id, p_date: state.date });
      if (requestedKey !== String(state.service.id) + state.date || $("#slots") !== slotBox) return;
      state.slots = result || [];
      if (!state.slots.length) { slotBox.innerHTML = '<div class="note">No times available on this date. Try another day.</div>'; return; }
      slotBox.innerHTML = '<div class="slots">' + state.slots.map((slot, index) => `<button type="button" class="slot ${state.slot && state.slot.slot_start === slot.slot_start ? "sel" : ""}" data-slot="${index}">${time(slot.slot_start)}</button>`).join("") + '</div>';
      slotBox.querySelectorAll("[data-slot]").forEach(button => button.addEventListener("click", () => {
        state.slot = state.slots[Number(button.dataset.slot)]; render();
      }));
    } catch (error) {
      slotBox.innerHTML = '<div class="alert">We couldn’t load available times. Please try again. <button class="link" id="retry">Retry ↻</button></div>';
      $("#retry").addEventListener("click", drawSlots);
    }
  }
  async function confirmBooking(event) {
    event.preventDefault();
    const name = $("#full-name").value.trim(), email = $("#email").value.trim(), phone = $("#phone").value.trim();
    const digits = phone.replace(/\D/g, "");
    let valid = true;
    $("#name-error").textContent = $("#email-error").textContent = $("#phone-error").textContent = "";
    if (name.length < 2) { $("#name-error").textContent = "Please enter your name."; valid = false; }
    if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) { $("#email-error").textContent = "Enter a valid email address."; valid = false; }
    if (phone && (digits.length < 7 || digits.length > 15)) { $("#phone-error").textContent = "Phone number must contain 7–15 digits."; valid = false; }
    if (!valid) return;
    const button = $("#confirm"); button.disabled = true; button.textContent = "Confirming…";
    try {
      await window.SLApi("rpc/create_booking", {
        p_service_id: state.service.id, p_start_time: state.slot.slot_start, p_full_name: name,
        p_email: email, p_phone: phone || null, p_notes: $("#notes").value.trim() || null
      });
      state.email = email; state.step = 4; state.error = ""; render();
    } catch (error) {
      if (error.code === "slot_unavailable") { state.step = 2; state.slot = null; state.slots = null; state.error = "Sorry, that time was just booked. Please pick another time."; }
      else if (error.code === "invalid_email") state.error = "Enter a valid email address.";
      else if (error.code === "invalid_name") state.error = "Please enter your name.";
      else state.error = "Something went wrong. Please try again.";
      render();
    }
  }
  loadServices();
})();