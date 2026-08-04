#!/usr/bin/env node
const fs = require('fs');
const path = require('path');
const root = path.resolve(__dirname, '..');
const slugs = ['privacy','terms','cookies','acceptable-use','responsible-ai','accessibility','nondiscrimination','data-rights','security','copyright','media-consent','grievances'];
const header = "<header class=\"site-header\"><div class=\"header-inner\"><a class=\"capability-brand\" href=\"/\" aria-label=\"SozoRock AI Capability Lab home\"><span>SOZOROCK</span><span>AI CAPABILITY LAB</span></a><nav class=\"legal-nav\" aria-label=\"Primary navigation\"><a href=\"/\">Home</a><a href=\"/curriculum/\">Curriculum</a><a href=\"/#apply\">Apply</a><a href=\"https://www.sozorockfoundation.org/\" rel=\"noopener\">Foundation</a></nav></div></header>";
const footer = "<footer class=\"site-footer\"><div class=\"footer-grid\"><div class=\"footer-brand\"><a class=\"capability-brand footer-capability-brand\" href=\"/\" aria-label=\"SozoRock AI Capability Lab home\"><span>SOZOROCK</span><span>AI CAPABILITY LAB</span></a><p>A free learning program of The SozoRock Foundation, Inc., a 501(c)(3) nonprofit organization based in Albany, New York.</p><p><a href=\"https://www.sozorockfoundation.org/\" rel=\"noopener\">Visit the Foundation website</a></p></div><nav class=\"footer-col\" aria-label=\"Explore\"><h2>Explore</h2><a href=\"/#practice\">The lab</a><a href=\"/curriculum/\">Curriculum</a><a href=\"/#apply\">Apply</a><a href=\"/curriculum/#learner-resources\">For learners</a><a href=\"/curriculum/#trainer-resources\">For trainers</a><a href=\"mailto:contact@sozorockfoundation.org?subject=AI%20Capability%20Lab%20organization%20inquiry\">For organizations</a></nav><nav class=\"footer-col\" aria-label=\"Legal\"><h2>Legal</h2><a href=\"/privacy/\">Privacy</a><a href=\"/terms/\">Terms</a><a href=\"/cookies/\">Cookies</a><a href=\"/acceptable-use/\">Acceptable use</a><a href=\"/responsible-ai/\">Responsible AI</a></nav><nav class=\"footer-col\" aria-label=\"Access and rights\"><h2>Access &amp; rights</h2><a href=\"/accessibility/\">Accessibility</a><a href=\"/nondiscrimination/\">Nondiscrimination</a><a href=\"/data-rights/\">Data rights</a><a href=\"/media-consent/\">Media consent</a></nav><nav class=\"footer-col\" aria-label=\"Report or contact\"><h2>Report or contact</h2><a href=\"/security/\">Security or AI incident</a><a href=\"/grievances/\">Complaint or grievance</a><a href=\"/copyright/\">Copyright</a><a href=\"mailto:contact@sozorockfoundation.org\">Contact</a></nav></div><div class=\"footer-bottom\"><p>© 2026 The SozoRock Foundation, Inc. All rights reserved.</p><div><p>Educational content is available under <a href=\"https://creativecommons.org/licenses/by/4.0/\" rel=\"license noopener\">CC BY 4.0</a> where noted.</p><p>SozoRock AI Capability Lab is an independent program of The SozoRock Foundation and is not sponsored by or affiliated with OpenAI.</p></div></div></footer>";
const internalNote = '<p class="legal-note">This public policy is operational guidance, not legal advice. The Foundation may revise it after legal, security, accessibility, or program review.</p>';
for (const slug of slugs) {
  const file = path.join(root, 'site', slug, 'index.html');
  let source = fs.readFileSync(file, 'utf8');
  source = source.replace(/<header class="site-header">[\s\S]*?<\/header>/, header);
  source = source.replace(/<footer class="site-footer">[\s\S]*?<\/footer>/, footer);
  source = source.replace(internalNote, '');
  source = source.replaceAll('SozoRock AI Lab', 'SozoRock AI Capability Lab');
  source = source.replaceAll('July 15, 2026', 'August 4, 2026');
  source = source.replaceAll('2026-07-15', '2026-08-04');
  source = source.replace(/<title>([^<]+) \| SozoRock AI Capability Lab<\/title>/, '<title>$1 | SozoRock</title>');
  fs.writeFileSync(file, source);
}
