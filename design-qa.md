# Design QA — Option 3 homepage

## Comparison setup

- Source visual truth: `C:\Users\biyia\.codex\generated_images\019fe935-92d3-7800-ab27-5a404339a477\exec-f97c2115-a5af-48fe-90a5-51c01c614fb0.png`
- Final desktop implementation: `C:\Users\biyia\.codex\visualizations\2026\08\10\019fe935-92d3-7800-ab27-5a404339a477\sozorock-ai-lab-option-3-implementation\14-desktop-design-qa-exact.jpg`
- Final mobile implementation: `C:\Users\biyia\.codex\visualizations\2026\08\10\019fe935-92d3-7800-ab27-5a404339a477\sozorock-ai-lab-option-3-implementation\07-mobile-final-candidate.jpg`
- Source pixels: 1487 × 1058.
- Desktop capture pixels: 1487 × 1038. CSS viewport: 1502 × 1100. Device pixel ratio: 1. The in-app browser capture removes a browser-owned inset; the comparison used an aligned top crop at the same 1487-pixel content width.
- Mobile capture pixels: 375 × 812. CSS viewport: 390 × 844. Device pixel ratio: 1. The browser-owned scrollbar/inset accounts for the pixel difference.
- State: homepage loaded, optional form details collapsed, no dialogs or validation messages visible.

## Full-view comparison evidence

The source and final desktop capture were opened together in one comparison input. The implementation preserves the source's defining composition: stacked wordmark and restrained navigation, a compact human-proof case column, a dominant real project image, paired primary/secondary actions, and a quiet horizontal method strip. The mockup's invented status claim and generic case-study labels were intentionally replaced with approved factual language. The Capital Property Care image is the real captured project, not a recreated or generated substitute.

## Focused region evidence

- Desktop first screen: `06-desktop-final-candidate.jpg` and `14-desktop-design-qa-exact.jpg`.
- Desktop proof/action: `10-desktop-proof-action.jpg`.
- Desktop application form: `11-desktop-form.jpg`.
- Mobile first screen: `07-mobile-final-candidate.jpg`.
- Mobile proof/action: `08-mobile-proof-action.jpg`.
- Mobile application form: `09-mobile-form.jpg`.

Focused views were required because the full-view comparison could not make form labels, mobile wrapping, tap targets, and lower-page section rhythm readable.

## Required fidelity surfaces

- Fonts and typography: system Inter stack, weight hierarchy, line height, and tracking closely match the selected visual. The headline retains the source's two-part scale and two-line teal statement on desktop; mobile wraps without clipping or overlap.
- Spacing and layout rhythm: desktop uses the selected wide case-study proportions and aligned page edges. Mobile collapses to one column with 15-pixel side insets, full-width 48-pixel actions, and no horizontal overflow.
- Colors and tokens: dark navy, restrained teal, white, light stone, and pale mint match the source balance. Contrast and focus treatment remain visible.
- Image quality and asset fidelity: the 1404 × 891 Capital Property Care capture renders at its native aspect ratio with no stretching, fake device frame, decorative replacement, or low-resolution participant video.
- Copy and content: visible claims are limited to approved program positioning and verifiable project facts. No quote, impact claim, testimonial, status claim, or fabricated participant media was introduced.
- Icons: decorative method icons in the generated mockup were omitted rather than approximated with CSS, symbols, or custom SVG. The method remains legible through type and dividers.
- States and accessibility: links and buttons have keyboard focus styles; the optional form section is collapsed by default; required-field validation focuses `firstName`; semantic headings, labels, alt text, skip link, and live status region remain intact.

## Comparison history

### Pass 1

- [P2] Desktop content frame was too narrow, pushing the teal headline to three lines and making the real project image feel secondary.
- Fix: expanded the page frame to the selected wide proportions and aligned the image to the top of the case-study composition.
- Post-fix evidence: `05-desktop-refined.jpg`.

### Pass 2

- [P2] The teal headline was still too large relative to the source, and an extra method sentence created a clipped visual tail at the bottom of the target viewport.
- Fix: gave the teal statement its own optical scale and removed the redundant method sentence.
- Post-fix evidence: `14-desktop-design-qa-exact.jpg`.

### Pass 3

- No actionable P0, P1, or P2 differences remain. The remaining deviations are intentional truth and product constraints: factual navigation wording, removal of the unverified status row, no invented impact language, and no decorative icon substitutes.

## Interaction and browser checks

- Hero Apply link navigated to `#apply`.
- Empty form submission focused the first required field and left the live status region empty.
- Optional details remained collapsed.
- External project links include `noopener noreferrer`.
- Video elements: 0. Google Drive links: 0. Numbered UI labels: 0.
- Real project image natural size: 1404 × 891.
- Desktop horizontal overflow: none. Mobile horizontal overflow: none.
- Browser console errors and warnings: none.

## Implementation checklist

- [x] Match the selected case-study composition.
- [x] Use only real Edward project evidence.
- [x] Keep copy factual and concise.
- [x] Preserve the practical method without numbered UI.
- [x] Validate desktop, mobile, form behavior, and browser diagnostics.

## Follow-up polish

No blocking follow-up polish remains. The selected mockup's decorative method icons were deliberately not reproduced because the implementation has no approved matching icon set and placeholder or custom-drawn substitutes would reduce quality.

final result: passed
