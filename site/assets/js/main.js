const header = document.querySelector('[data-header]');
const toggle = document.querySelector('[data-nav-toggle]');
if (toggle && header) {
  toggle.addEventListener('click', () => header.classList.toggle('open'));
}

const reveals = document.querySelectorAll('.reveal');
const revealObserver = new IntersectionObserver((entries) => {
  entries.forEach((entry) => {
    if (entry.isIntersecting) {
      entry.target.classList.add('visible');
      revealObserver.unobserve(entry.target);
    }
  });
}, { threshold: 0.14 });
reveals.forEach((node) => revealObserver.observe(node));

const navLinks = [...document.querySelectorAll('.main-nav a')];
const sectionByNav = navLinks.map((link) => document.querySelector(link.getAttribute('href'))).filter(Boolean);
const navObserver = new IntersectionObserver((entries) => {
  entries.forEach((entry) => {
    if (!entry.isIntersecting) return;
    navLinks.forEach((link) => {
      const active = link.getAttribute('href') === `#${entry.target.id}`;
      link.classList.toggle('active', active);
    });
  });
}, { rootMargin: '-45% 0px -45% 0px', threshold: 0.01 });
sectionByNav.forEach((section) => navObserver.observe(section));

document.querySelectorAll('a[href^="#"]').forEach((anchor) => {
  anchor.addEventListener('click', () => header?.classList.remove('open'));
});
