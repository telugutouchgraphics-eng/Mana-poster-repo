#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

const appRoot = path.resolve(__dirname, '..');
const webRoot = process.env.WEB_PORTAL_ROOT
  ? path.resolve(process.env.WEB_PORTAL_ROOT)
  : path.resolve(appRoot, '..', 'mana-poster-web-portal');

const dartPath = path.join(
  appRoot,
  'lib',
  'features',
  'prehome',
  'services',
  'dynamic_lunar_event_dates.dart',
);
const webPath = path.join(
  webRoot,
  'src',
  'lib',
  'server',
  'dynamic-lunar-event-dates.ts',
);

function readFile(filePath) {
  return fs.readFileSync(filePath, 'utf8');
}

function parseWebDates(source) {
  const years = {};
  const yearRegex = /(\d{4}):\s*\{([\s\S]*?)\n\s*\},/g;
  let yearMatch;
  while ((yearMatch = yearRegex.exec(source)) !== null) {
    const year = Number(yearMatch[1]);
    const body = yearMatch[2];
    years[year] = {};
    const eventRegex = /([A-Za-z0-9_]+):\s*\{([^}]*)\}/g;
    let eventMatch;
    while ((eventMatch = eventRegex.exec(body)) !== null) {
      years[year][eventMatch[1]] = parseProps(eventMatch[2]);
    }
  }
  return years;
}

function parseDartDates(source) {
  const years = {};
  const constantMatch = source.match(
    /kResolvedLunarEventDates\s*=\s*\{([\s\S]*?)\n\};/,
  );
  if (!constantMatch) {
    throw new Error('Could not find kResolvedLunarEventDates in Dart file.');
  }
  const body = constantMatch[1];
  const yearRegex =
    /(\d{4}):\s*<String,\s*DynamicResolvedEventDate>\s*\{([\s\S]*?)\n\s*\},/g;
  let yearMatch;
  while ((yearMatch = yearRegex.exec(body)) !== null) {
    const year = Number(yearMatch[1]);
    years[year] = {};
    const eventRegex =
      /'([^']+)':\s*DynamicResolvedEventDate\(([\s\S]*?)\),/g;
    let eventMatch;
    while ((eventMatch = eventRegex.exec(yearMatch[2])) !== null) {
      years[year][eventMatch[1]] = parseProps(eventMatch[2]);
    }
  }
  return years;
}

function parseProps(text) {
  const output = {};
  for (const key of ['month', 'day', 'endMonth', 'endDay', 'durationDays']) {
    const match = text.match(new RegExp(`${key}\\s*:\\s*(\\d+)`));
    if (match) {
      output[key] = Number(match[1]);
    }
  }
  return output;
}

function renderDate(value) {
  const props = [`month: ${value.month}`, `day: ${value.day}`];
  if (value.endMonth != null) props.push(`endMonth: ${value.endMonth}`);
  if (value.endDay != null) props.push(`endDay: ${value.endDay}`);
  if (value.durationDays != null && value.durationDays !== 1) {
    props.push(`durationDays: ${value.durationDays}`);
  }
  return `DynamicResolvedEventDate(${props.join(', ')})`;
}

function renderDartYearBlock(year, dates) {
  const lines = [`  ${year}: <String, DynamicResolvedEventDate>{`];
  for (const key of Object.keys(dates).sort()) {
    lines.push(`    '${key}': ${renderDate(dates[key])},`);
  }
  lines.push('  },');
  return lines.join('\n');
}

const dartSource = readFile(dartPath);
const webDates = parseWebDates(readFile(webPath));
const currentAppDates = parseDartDates(dartSource);

if (process.argv.includes('--check')) {
  const mismatches = [];
  for (const [year, dates] of Object.entries(webDates)) {
    const appYearDates = currentAppDates[Number(year)] || {};
    const keys = new Set([...Object.keys(dates), ...Object.keys(appYearDates)]);
    for (const key of Array.from(keys).sort()) {
      if (JSON.stringify(appYearDates[key]) !== JSON.stringify(dates[key])) {
        mismatches.push(`${year}.${key}`);
      }
    }
  }
  if (mismatches.length > 0) {
    console.error(
      `dynamic_lunar_event_dates.dart has ${mismatches.length} mismatch(es): ${mismatches
        .slice(0, 20)
        .join(', ')}`,
    );
    process.exit(1);
  }
  console.log('dynamic lunar event dates are synced.');
  process.exit(0);
}

let nextDart = dartSource;

for (const [year, dates] of Object.entries(webDates)) {
  const yearBlockRegex = new RegExp(
    `  ${year}:\\s*<String,\\s*DynamicResolvedEventDate>\\s*\\{[\\s\\S]*?\\n\\s*\\},`,
  );
  const nextYearBlock = renderDartYearBlock(year, dates);
  if (yearBlockRegex.test(nextDart)) {
    nextDart = nextDart.replace(yearBlockRegex, nextYearBlock);
  } else {
    nextDart = nextDart.replace(
      /\n\};/,
      `\n${nextYearBlock}\n};`,
    );
  }
}

fs.writeFileSync(dartPath, nextDart);
console.log(`synced ${Object.keys(webDates).length} year(s) from web portal dates.`);
