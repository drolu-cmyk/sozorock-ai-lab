(() => {
  'use strict';

  const header = document.querySelector('[data-header]');
  const menuButton = document.querySelector('[data-menu-button]');
  const nav = document.querySelector('[data-primary-nav]');

  if (header && menuButton && nav) {
    const setMenu = (open) => {
      header.dataset.open = String(open);
      menuButton.setAttribute('aria-expanded', String(open));
      menuButton.setAttribute('aria-label', open ? 'Close navigation' : 'Open navigation');
    };
    menuButton.addEventListener('click', () => setMenu(header.dataset.open !== 'true'));
    nav.addEventListener('click', (event) => {
      if (event.target instanceof HTMLAnchorElement) setMenu(false);
    });
    document.addEventListener('keydown', (event) => {
      if (event.key === 'Escape') setMenu(false);
    });
  }

  const formStartedAt = new Date().toISOString();
  const form = document.querySelector('[data-application-form]');
  const status = document.querySelector('[data-form-status]');
  const submit = document.querySelector('[data-submit]');

  if (form instanceof HTMLFormElement && status && submit instanceof HTMLButtonElement) {
    form.addEventListener('submit', async (event) => {
      event.preventDefault();
      status.textContent = '';
      submit.disabled = true;
      submit.textContent = 'Submitting…';

      const payload = Object.fromEntries(new FormData(form).entries());
      if (payload.website) {
        submit.disabled = false;
        submit.textContent = 'Apply to the Lab';
        return;
      }

      payload.consent = payload.consent === 'on';
      payload.source = 'sozorock-ai-lab-website';
      payload.applicationType = 'rolling-interest';
      payload.cohort = 'rolling-intake';
      payload.formStartedAt = formStartedAt;
      payload.submittedAt = new Date().toISOString();

      try {
        const response = await fetch('/api/applications/start', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(payload),
          credentials: 'same-origin',
          cache: 'no-store',
          redirect: 'error',
          referrerPolicy: 'same-origin'
        });
        const result = await response.json().catch(() => ({}));
        if (!response.ok || result.ok !== true) throw new Error('Submission failed');
        form.reset();
        status.textContent = 'Your interest form was received. We will email next steps after review.';
      } catch (error) {
        status.textContent = 'The form could not be submitted. Please try again or email contact@sozorockfoundation.org.';
      } finally {
        submit.disabled = false;
        submit.textContent = 'Apply to the Lab';
      }
    });
  }
})();
