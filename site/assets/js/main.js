(() => {
  'use strict';

  const dialog = document.querySelector('[data-video-dialog]');
  const openVideo = document.querySelector('[data-video-open]');
  const closeVideo = document.querySelector('[data-video-close]');
  const edwardVideo = document.querySelector('[data-edward-video]');

  if (dialog instanceof HTMLDialogElement && openVideo instanceof HTMLButtonElement) {
    openVideo.addEventListener('click', () => {
      dialog.showModal();
      if (edwardVideo instanceof HTMLVideoElement) edwardVideo.play().catch(() => {});
    });
    const close = () => {
      if (edwardVideo instanceof HTMLVideoElement) edwardVideo.pause();
      dialog.close();
    };
    if (closeVideo instanceof HTMLButtonElement) closeVideo.addEventListener('click', close);
    dialog.addEventListener('click', event => { if (event.target === dialog) close(); });
  }

  const formStartedAt = new Date().toISOString();
  const forms = document.querySelectorAll('[data-application-form]');
  for (const form of forms) {
    if (!(form instanceof HTMLFormElement)) continue;
    const status = form.querySelector('[data-form-status]');
    const submit = form.querySelector('[data-submit]');
    if (!(status instanceof HTMLElement) || !(submit instanceof HTMLButtonElement)) continue;
    const submitLabel = submit.textContent.trim();
    const applicationType = form.dataset.applicationType || 'participant-interest';
    const successMessage = form.dataset.successMessage || 'Your form was received. We will review it and contact you with next steps.';
    form.addEventListener('submit', async event => {
      event.preventDefault();
      status.textContent = '';
      if (!form.reportValidity()) return;
      submit.disabled = true;
      submit.textContent = 'Submitting…';
      const payload = Object.fromEntries(new FormData(form).entries());
      if (payload.website) { submit.disabled = false; submit.textContent = submitLabel; return; }
      payload.consent = payload.consent === 'on';
      payload.source = 'sozorock-ai-lab-website';
      payload.applicationType = applicationType;
      payload.cohort = 'rolling-intake';
      payload.formStartedAt = formStartedAt;
      payload.submittedAt = new Date().toISOString();
      try {
        const response = await fetch('/api/applications/start', {method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(payload),credentials:'same-origin',cache:'no-store',redirect:'error',referrerPolicy:'same-origin'});
        const result = await response.json().catch(() => ({}));
        if (!response.ok || result.ok !== true) throw new Error('Submission failed');
        form.reset();
        status.textContent = successMessage;
      } catch (error) {
        status.textContent = 'The form could not be submitted. Please try again later.';
      } finally {
        submit.disabled = false;
        submit.textContent = submitLabel;
      }
    });
  }
})();
