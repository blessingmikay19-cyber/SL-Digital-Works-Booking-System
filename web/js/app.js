(() => {
  const menu = document.getElementById("menu");
  const nav = document.getElementById("nav");
  if (menu && nav) {
    menu.addEventListener("click", () => {
      const open = nav.classList.toggle("open");
      menu.setAttribute("aria-expanded", String(open));
      menu.setAttribute("aria-label", open ? "Close navigation" : "Open navigation");
    });
    nav.querySelectorAll("a").forEach(link => link.addEventListener("click", () => {
      nav.classList.remove("open");
      menu.setAttribute("aria-expanded", "false");
      menu.setAttribute("aria-label", "Open navigation");
    }));
  }

  const money = value => Number(value) > 0
    ? new Intl.NumberFormat("en-ZA", { style: "currency", currency: "ZAR", maximumFractionDigits: 0 }).format(Number(value))
    : "Free";
  const escapeHTML = value => String(value ?? "").replace(/[&<>"]/g, ch => ({
    "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;"
  }[ch]));

  async function loadServiceCards() {
    const targets = document.querySelectorAll(".svc-list");
    if (!targets.length) return;
    try {
      const services = await window.SLApi("services?select=id,name,description,duration_minutes,price&active=eq.true&order=duration_minutes.asc");
      const markup = services.length ? services.map((service, index) => `
        <article class="card">
          <div class="eyebrow card-number">0${index + 1}</div>
          <h3>${escapeHTML(service.name)}</h3>
          <p class="small">${escapeHTML(service.description || "")}</p>
          <div class="meta"><span class="small">${Number(service.duration_minutes) || 0} min</span><span class="price">${money(service.price)}</span></div>
          <a class="btn sec" href="${location.pathname.includes("/pages/") ? "booking.html" : "pages/booking.html"}">Book this ↗</a>
        </article>`).join("") : '<p class="small">No services are currently available. Please contact us for assistance.</p>';
      targets.forEach(target => target.innerHTML = markup);
    } catch (error) {
      targets.forEach(target => target.innerHTML = '<p class="small">Services could not be loaded right now. Please try again later or contact us directly.</p>');
    }
  }
  loadServiceCards();
})();
