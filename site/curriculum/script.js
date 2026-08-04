const searchInput = document.querySelector("#module-search");
const availabilityFilter = document.querySelector("#availability-filter");
const moduleCards = [...document.querySelectorAll(".module-card")];
const result = document.querySelector("#filter-result");
const noResults = document.querySelector("#no-results");

function normalizeSearchText(value) {
  return String(value || "").toLowerCase().replace(/[^a-z0-9]+/g, " ").trim();
}

function filterModules() {
  const search = normalizeSearchText(searchInput.value);
  const availability = availabilityFilter.value;
  let visible = 0;

  moduleCards.forEach((card) => {
    const visibleCardText = [...card.children].map((field) => field.textContent).join(" ");
    const searchableText = normalizeSearchText(`${card.dataset.search} ${visibleCardText}`);
    const matchesSearch = !search || searchableText.includes(search);
    const matchesAvailability = availability === "all" || card.dataset.availability === availability;
    const show = matchesSearch && matchesAvailability;
    card.hidden = !show;
    if (show) visible += 1;
  });

  result.textContent = search || availability !== "all" ? `${visible} module${visible === 1 ? "" : "s"} shown` : "";
  noResults.hidden = visible !== 0;
}

searchInput.addEventListener("input", filterModules);
availabilityFilter.addEventListener("change", filterModules);
