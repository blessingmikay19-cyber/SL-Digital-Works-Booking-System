(() => {
  const form = document.getElementById("contact-form");
  if (!form) return;
  const $ = id => document.getElementById(id);
  const digitsOnly = value => String(value || "").replace(/\D/g, "");
  const emailOK = value => /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(value);
  form.addEventListener("submit", event => {
    event.preventDefault();
    ["cn-error", "ce-error", "cp-error", "cm-error"].forEach(id => $(id).textContent = "");
    $("contact-status").textContent = "";
    const name = $("cn").value.trim();
    const email = $("ce").value.trim();
    const phone = $("cp").value.trim();
    const message = $("cm").value.trim();
    let valid = true;
    if (name.length < 2) { $("cn-error").textContent = "Please enter your name."; valid = false; }
    if (!emailOK(email)) { $("ce-error").textContent = "Enter a valid email address."; valid = false; }
    if (phone && (digitsOnly(phone).length < 7 || digitsOnly(phone).length > 15)) {
      $("cp-error").textContent = "Phone number must contain 7–15 digits."; valid = false;
    }
    if (message.length < 3) { $("cm-error").textContent = "Please enter a short message."; valid = false; }
    if (!valid) return;
    const subject = "Enquiry from " + name;
    const body = message + "\n\nName: " + name + "\nEmail: " + email + "\nPhone: " + (phone || "Not provided");
    const mailto = "mailto:blessingmikay005@gmail.com?subject=" + encodeURIComponent(subject) + "&body=" + encodeURIComponent(body);
    $("contact-status").textContent = "Opening your email application…";
    window.location.href = mailto;
  });
})();
