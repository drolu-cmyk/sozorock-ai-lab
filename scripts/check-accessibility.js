#!/usr/bin/env node
const fs=require('fs'); const path=require('path');
const root=path.resolve(__dirname,'..'); const failures=[];
const files=[];
(function walk(dir){for(const e of fs.readdirSync(dir,{withFileTypes:true})){const p=path.join(dir,e.name);if(e.isDirectory())walk(p);else if(e.name.endsWith('.html'))files.push(p);}})(path.join(root,'site'));
for(const file of files){
  const html=fs.readFileSync(file,'utf8'); const rel=path.relative(root,file);
  if(!/<html[^>]+lang="en-US"/i.test(html)) failures.push(`${rel}: missing language`);
  if(!/<meta name="viewport"/i.test(html)) failures.push(`${rel}: missing viewport`);
  if(!/class="skip-link"[^>]+href="#main"/i.test(html) && !rel.endsWith('404.html')) failures.push(`${rel}: missing skip link`);
  if(!/id="main"/i.test(html)) failures.push(`${rel}: missing main target`);
  for(const img of html.matchAll(/<img\b([^>]*)>/gi)) if(!/\balt="[^"]*"/i.test(img[1])) failures.push(`${rel}: image without alt`);
  if(/tabindex="[1-9]/i.test(html)) failures.push(`${rel}: positive tabindex`);
  if(/<a[^>]+href="#"/i.test(html)) failures.push(`${rel}: empty hash link`);
  if((html.match(/<h1[\s>]/gi)||[]).length!==1) failures.push(`${rel}: must have one h1`);
  for(const button of html.matchAll(/<button\b([^>]*)>([\s\S]*?)<\/button>/gi)){
    const name=button[2].replace(/<[^>]+>/g,'').trim();
    if(!name && !/aria-label="[^"]+"/i.test(button[1])) failures.push(`${rel}: unnamed button`);
  }
  for(const anchor of html.matchAll(/<a\b([^>]*)>/gi)){
    const attrs=anchor[1];
    if(/target="_blank"/i.test(attrs) && !/rel="[^"]*noopener[^"]*"/i.test(attrs)) failures.push(`${rel}: target=_blank link missing noopener`);
  }
  if(/role="img"[^>]*>[\s\S]*?<a\b/i.test(html)) failures.push(`${rel}: interactive link nested inside role=img`);
}
const baseCss=fs.readFileSync(path.join(root,'site/assets/css/option-3.css'),'utf8');
for(const rule of [':focus-visible','prefers-reduced-motion','min-height: 48px']) if(!baseCss.includes(rule)) failures.push(`option-3.css: missing ${rule}`);
const campaignCss=fs.readFileSync(path.join(root,'site/assets/css/campaign.css'),'utf8');
for(const rule of ['min-height: 44px','scroll-margin-top','@media (max-width: 720px)']) if(!campaignCss.includes(rule)) failures.push(`campaign.css: missing ${rule}`);
const homepage=fs.readFileSync(path.join(root,'site/index.html'),'utf8');
for(const name of ['firstName','lastName','email','build','consent']){
  const rx=new RegExp(`<label[^>]*>[\\s\\S]*?name="${name}"[\\s\\S]*?<\\/label>`,'i');
  if(!rx.test(homepage)) failures.push(`homepage: ${name} is not wrapped by a label`);
}
if(!homepage.includes('aria-hidden="true"')) failures.push('homepage: decorative participant image should be hidden from assistive technology.');
if(failures.length){console.error(`Accessibility checks failed (${failures.length}):\n- ${failures.join('\n- ')}`);process.exit(1);}
console.log(`Accessibility checks passed for ${files.length} pages, campaign target sizing, external-link safety, and the application form.`);
