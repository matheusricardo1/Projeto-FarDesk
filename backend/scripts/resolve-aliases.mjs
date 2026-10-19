// Pós-build: o tsc não reescreve os aliases de `paths`, e o Node (ESM) não
// sabe resolvê-los. Troca cada `@shared/...`, `@modules/...`, `@tests/...` e
// `@app.module` no `dist` pelo caminho relativo real, com extensão `.js`.
import fs from 'node:fs';
import path from 'node:path';

const distRoot = path.resolve('dist');
const ALIAS = /((?:from|import)\s*\(?\s*)(['"])@(app\.module|(?:shared|modules|tests)\/[^'"]+)\2/g;

function walk(dir) {
  return fs.readdirSync(dir, { withFileTypes: true }).flatMap((entry) => {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) return walk(full);
    return /\.(js|d\.ts)$/.test(entry.name) ? [full] : [];
  });
}

function relativeSpecifier(fromFile, aliasTarget) {
  const target = path.join(distRoot, `${aliasTarget}.js`);
  if (!fs.existsSync(target)) throw new Error(`Alias sem arquivo correspondente: @${aliasTarget} (em ${fromFile})`);
  let relative = path.relative(path.dirname(fromFile), target).split(path.sep).join('/');
  if (!relative.startsWith('.')) relative = `./${relative}`;
  return relative;
}

let rewritten = 0;
for (const file of walk(distRoot)) {
  const original = fs.readFileSync(file, 'utf8');
  const updated = original.replace(ALIAS, (_, prefix, quote, aliasTarget) => {
    rewritten++;
    return `${prefix}${quote}${relativeSpecifier(file, aliasTarget)}${quote}`;
  });
  if (updated !== original) fs.writeFileSync(file, updated);
}

console.log(`resolve-aliases: ${rewritten} imports reescritos em dist/`);
