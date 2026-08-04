const searchInput = document.querySelector("#module-search");
const statusFilter = document.querySelector("#status-filter");
const moduleCards = [...document.querySelectorAll(".module-card")];
const result = document.querySelector("#filter-result");
const noResults = document.querySelector("#no-results");

function filterModules() {
  const search = (searchInput.value || "").trim().toLowerCase();
  const status = statusFilter.value;
  let visible = 0;

  moduleCards.forEach((card) => {
    const matchesSearch = !search || card.dataset.search.includes(search);
    const matchesStatus = status === "all" || card.dataset.status === status;
    const show = matchesSearch && matchesStatus;
    card.hidden = !show;
    if (show) visible += 1;
  });

  result.textContent = search || status !== "all" ? `${visible} module${visible === 1 ? "" : "s"} shown` : "";
  noResults.hidden = visible !== 0;
}

searchInput.addEventListener("input", filterModules);
statusFilter.addEventListener("change", filterModules);
