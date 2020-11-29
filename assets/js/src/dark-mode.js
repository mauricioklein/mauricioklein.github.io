const LIGHT_MODE = "light";
const DARK_MODE = "dark";
const SELECTOR = ".inner-switch";

$(function () {
  updateDarkLabel()
});

$(SELECTOR).on("click", function() {
  toggleDarkMode();
  updateDarkLabel()
})

function toggleDarkMode() {
  const mode = getCookie("mode") === DARK_MODE ? LIGHT_MODE : DARK_MODE;
  document.cookie = `mode=${mode}; path=/`;
  
  if (mode === DARK_MODE) {
    $("html").addClass("dark-mode");
  } else {
    $("html").removeClass("dark-mode");
  }
}

function updateDarkLabel() {
  if (getCookie("mode") === DARK_MODE) {
    $(SELECTOR).text("🌙");
    $("html").addClass("dark-mode");
  } else {
    $(SELECTOR).text("☀️");
    $("html").removeClass("dark-mode");
  }
}

function getCookie(cname) {
  const name = cname + "=";
  const decodedCookie = decodeURIComponent(document.cookie);
  const ca = decodedCookie.split(";");

  for (let i = 0; i < ca.length; i++) {
    var c = ca[i];

    while (c.charAt(0) == " ") {
      c = c.substring(1);
    }

    if (c.indexOf(name) == 0) {
      return c.substring(name.length, c.length);
    }
  }

  return "";
}
