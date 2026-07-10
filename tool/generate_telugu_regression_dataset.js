const fs = require("fs");
const path = require("path");

const outPath = path.join(
  process.cwd(),
  "test",
  "data",
  "telugu_regression.json"
);

const cp1252 = new Map([
  [0x20ac, 0x80],
  [0x201a, 0x82],
  [0x0192, 0x83],
  [0x201e, 0x84],
  [0x2026, 0x85],
  [0x2020, 0x86],
  [0x2021, 0x87],
  [0x02c6, 0x88],
  [0x2030, 0x89],
  [0x0160, 0x8a],
  [0x2039, 0x8b],
  [0x0152, 0x8c],
  [0x017d, 0x8e],
  [0x2018, 0x91],
  [0x2019, 0x92],
  [0x201c, 0x93],
  [0x201d, 0x94],
  [0x2022, 0x95],
  [0x2013, 0x96],
  [0x2014, 0x97],
  [0x02dc, 0x98],
  [0x2122, 0x99],
  [0x0161, 0x9a],
  [0x203a, 0x9b],
  [0x0153, 0x9c],
  [0x017e, 0x9e],
  [0x0178, 0x9f],
]);

function legacyToPua(text) {
  return Array.from(text, (ch) => {
    const cp = ch.codePointAt(0);
    const byte = cp1252.get(cp) ?? cp;
    return String.fromCodePoint(0xf000 + byte);
  }).join("");
}

function hex(text) {
  return Array.from(text, (ch) =>
    ch.codePointAt(0).toString(16).toUpperCase().padStart(4, "0")
  ).join(" ");
}

function uniq(items) {
  return [...new Set(items.filter(Boolean))];
}

const groups = {
  "క్ష": ["క్షమ", "క్షణం", "క్షీణం", "క్షేత్రం", "భిక్ష", "అక్షరం", "రాక్షసుడు", "సాక్ష్యం", "రక్షణ", "పరీక్ష"],
  "క్ష్మ": ["లక్ష్మి", "లక్ష్మీ", "సూక్ష్మం", "సూక్ష్మ", "లక్ష్మణుడు", "లక్ష్మీపతి"],
  "క్ష్య": ["లక్ష్యం", "సాక్ష్యం", "ప్రత్యక్ష్యం", "ఆక్షేపణ", "లక్ష్యంగా"],
  "క్ష్ణ": ["తీక్ష్ణం", "తీక్ష్ణ", "క్ష్ణ", "తీక్ష్ణత", "తీక్ష్ణమైన"],
  "జ్ఞ": ["జ్ఞానం", "జ్ఞాపకం", "విజ్ఞానం", "ప్రజ్ఞ", "ప్రజ్ఞా", "సంజ్ఞ", "అజ్ఞాతం", "ఆజ్ఞా", "కృతజ్ఞతలు", "కృతజ్ఞతాభివందనం"],
  "జ్ఞ్య": ["జ్ఞ్య", "ప్రజ్ఞ్యం", "విజ్ఞ్యం", "సంజ్ఞ్యం", "ఆజ్ఞ్యం"],
  "శ్ర": ["శ్రీ", "శ్రద్ధ", "శ్రమ", "శ్రేయస్సు", "శ్రావణం", "శ్రేణి", "విశ్రాంతి", "ఆశ్రయం", "శ్రీవారు", "శ్రద్ధాంజలి"],
  "స్త్ర": ["స్త్రీ", "స్త్రోత్రం", "శాస్త్రం", "ఆయుధాస్త్రం", "వస్త్రం", "స్త్రీలు", "స్త్రీవాదం", "శాస్త్రవేత్త", "అస్త్రాలు"],
  "త్ర": ["త్రయం", "త్రివేణి", "పాత్ర", "యాత్ర", "మిత్రుడు", "చిత్రం", "నేత్రం", "క్షేత్రం", "త్రాణం", "తత్ర"],
  "ద్ర": ["ద్రవ్యం", "ద్రాక్ష", "రుద్రుడు", "సముద్రం", "చంద్రుడు", "నిద్ర", "ద్రావకం", "ద్రవ్యోల్బణం"],
  "ద్వ": ["ద్వారం", "ద్వితీయం", "ద్వీపం", "ద్వేషం", "అద్వైతం", "ద్వంద్వం", "ద్వారక", "ద్వారా"],
  "ధ్య": ["ధ్యానం", "మాధ్యమం", "విద్యాధ్యయనం", "అధ్యక్షుడు", "అధ్యాయం", "సాధ్యం", "ఆధ్యాత్మికం", "ధ్యేయం"],
  "ద్య": ["విద్య", "విద్యార్థి", "వైద్యం", "హృద్యం", "ఆద్యంతం", "పద్యము", "గద్యము", "ఉద్యోగం"],
  "న్య": ["న్యాయం", "అన్యాయం", "ధన్యవాదాలు", "కన్య", "పుణ్యం", "సన్యాసి", "న్యాయస్థానం", "ధన్యుడు"],
  "వ్య": ["వ్యక్తి", "వ్యవసాయం", "వ్యాపారం", "వ్యాసం", "వ్యాధి", "వ్యవహారం", "దివ్య", "భవ్య"],
  "ర్య": ["సూర్యుడు", "ఆర్య", "కార్యం", "శౌర్యం", "ధైర్యం", "వీర్యం", "సౌర్య", "మర్యాద"],
  "ల్య": ["కళ్యాణం", "మాల్యము", "విల్యం", "సుల్యం", "లాల్య", "పాల్యం", "శైల్యం", "అల్యము"],
  "శ్య": ["శ్యామల", "దృశ్యం", "పశ్యంతి", "అవశ్యం", "దృశ్యాలు", "ఆశ్చర్యం", "వశ్యం", "కశ్యపుడు"],
  "క్త": ["భక్తి", "శక్తి", "ముక్తి", "వ్యక్తి", "ఉక్తి", "రక్తం", "సక్తి", "భక్తుడు"],
  "గ్ధ": ["ముగ్ధ", "దిగ్ధ", "గ్ధము", "ముగ్ధత", "దుగ్ధం", "సుగ్ధ", "ముగ్ధురాలు"],
  "ద్భ": ["అద్భుతం", "సద్భావం", "ఉద్భవం", "పద్మోద్భవుడు", "సద్భక్తి", "అద్భుతమైన"],
  "ప్త": ["గుప్త", "సప్త", "తప్త", "ఆప్తుడు", "లిప్తం", "దీప్తి", "సుప్తం", "ప్రాప్తి"],
  "బ్ధ": ["లబ్ధి", "అబ్ధి", "బుధ్ధి", "లబ్ధప్రతిష్ఠ", "సుబ్ధం", "అబ్ధం"],
  "మ్ప": ["సంపద", "కంపనం", "శంపా", "సంప్రదాయం", "సంపూర్ణం", "కంపెనీ", "పంపకం", "సంపాదన"],
  "మ్బ": ["అంబరం", "సంబంధం", "కంబళి", "అంబేద్కర్", "సంబరం", "తంబూరా", "అంబిక", "సంబోధన"],
  "మ్మ": ["అమ్మ", "బొమ్మ", "మమ్మల్ని", "సమ్మతి", "నమ్మకం", "సమ్మానం", "కమ్మటి", "ఇమ్మడి"],
  "బ్ర": ["బ్రహ్మం", "బ్రతుకు", "బ్రహ్మాండం", "సుబ్రహ్మణ్యం", "బ్రాహ్మణుడు", "బ్రతుకమ్మ", "బ్రహ్మోత్సవం"],
  "గ్ర": ["గ్రామం", "గ్రహం", "అగ్రహారం", "గ్రంథం", "గ్రహణం", "సంగ్రహం", "ప్రగ్రతి", "గ్రామీణం"],
  "క్ర": ["క్రాంతి", "క్రమం", "చక్రం", "విక్రమ్", "క్రియ", "క్రింద", "క్రోధం", "క్రయము"],
  "ప్ర": ["ప్రజలు", "ప్రేమ", "ప్రభుత్వం", "ప్రకాశం", "ప్రాణం", "ప్రార్థన", "ప్రయాణం", "ప్రసాదం"],
  "ఫ్ర": ["ఫ్రెంచ్", "ఫ్రంట్", "ఫ్రేమ్", "ఫ్రాక్", "ఫ్రిజ్", "ఫ్రీ", "ఫ్రై", "ఫ్రూట్"],
  "క్ల": ["క్లాస్", "క్లబ్", "క్లిష్టం", "క్లుప్తం", "క్లేశం", "శుక్లం", "క్లారిటీ", "క్లర్క్"],
  "గ్ల": ["గ్లాసు", "గ్లూకోజ్", "గ్లోబల్", "గ్లాని", "గ్లామర్", "గ్లైడ్", "గ్లాసులు"],
  "హ్న": ["అహ్నికం", "మధ్యాహ్నం", "అపరాహ్నం", "పూర్వాహ్నం", "సాయాహ్నం", "హ్నానం"],
  "హ్మ": ["బ్రహ్మ", "బ్రహ్మం", "బ్రహ్మణ్యం", "బ్రహ్మోత్సవం", "హ్మ్", "బ్రహ్మాండం"],
  "హ్య": ["సాహ్యం", "బాహ్యం", "హ్యాండ్", "హైదరాబాదు", "హ్యాపీ", "అహ్యము", "హ్యాస్యం"],
  "ప్ణ": ["స్వప్ణం", "ప్ణము", "సుప్ణం", "దర్ప్ణం", "ప్ణి", "ప్ణం"],
  "చ్ఛ": ["స్వచ్ఛం", "ఇచ్చాడు", "విచ్ఛిన్నం", "ఆచ్ఛాదనం", "చ్ఛత్రం", "స్వచ్ఛత"],
  "జ్ఝ": ["జ్ఝరి", "జ్ఝానం", "జ్ఝుమ్ము", "జ్ఝలక్", "జ్ఝరి", "జ్ఝం"],
  "ట్ట": ["పట్టణం", "చిట్టి", "పుట్టినరోజు", "మెట్ట", "బుట్ట", "గుట్ట", "పట్టుదల", "కట్టడం"],
  "డ్డ": ["గడ్డం", "అడ్డం", "బిడ్డ", "దొడ్డ", "గుడ్డు", "వడ్డీ", "అడ్డంకి", "గడ్డిపరక"],
  "త్త": ["సత్తా", "చిత్తం", "మత్తు", "పత్తి", "సత్యం", "మొత్తం", "వత్తిడి", "చెత్త"],
  "ద్ద": ["పద్దతి", "అద్దం", "ముద్దు", "బుద్ధుడు", "పెద్ద", "సిద్ధం", "యుద్ధం", "శుద్ధి"],
  "న్న": ["అన్నం", "చిన్న", "పున్నమి", "సన్నని", "కన్ను", "మన్నన", "వెన్నెల", "పన్ను"],
  "ల్ల": ["పల్లె", "తెల్ల", "మల్లె", "బల్ల", "చల్లని", "అల్లం", "పిల్ల", "వెల్లడి"],
  "ర్ర": ["బుర్ర", "కర్ర", "గుర్రం", "మర్రి", "ఎర్ర", "చర్రు", "పర్ర", "తర్ర"],
};

const suffixes = ["", "ం", "ము", "లు", "ని", "కు", "కి", "తో", "లో", "పై", "గా", "మైన", "త్వం", "తనం"];
const vowelWords = [
  "రామా", "కవి", "దీక్ష", "గురు", "పూజ", "వేణు", "దేవుడు", "కౌశలం", "కృతి", "మృదు", "సౌందర్యం", "శౌర్యం",
];

const entriesByGroup = new Map();
for (const [group, stems] of Object.entries(groups)) {
  const groupEntries = [];
  for (const stem of stems) {
    for (const suffix of suffixes) {
      groupEntries.push({
        unicode: stem + suffix,
        group,
        description: `${group} conjunct regression: ${stem}${suffix}`,
      });
    }
  }
  entriesByGroup.set(group, groupEntries);
}
const vowelEntries = [];
for (const word of vowelWords) {
  vowelEntries.push({
    unicode: word,
    group: "vowels",
    description: `Dependent vowel regression: ${word}`,
  });
}
entriesByGroup.set("vowels", vowelEntries);

const seen = new Set();
const selected = [];
let offset = 0;
const orderedGroups = [...entriesByGroup.keys()];
while (selected.length < 520) {
  let addedThisRound = false;
  for (const group of orderedGroups) {
    const entries = entriesByGroup.get(group);
    const entry = entries[offset];
    if (!entry || seen.has(entry.unicode)) continue;
    seen.add(entry.unicode);
    selected.push(entry);
    addedThisRound = true;
    if (selected.length >= 520) break;
  }
  if (!addedThisRound) break;
  offset += 1;
}

async function convertWithAndhraCode(input) {
  const modernBody = new URLSearchParams({
    input,
    replaceSpaces: "false",
    mapping: "mappingA.json",
    commentOutLines: "false",
    commentOutLineList: "",
  });
  const modernResponse = await fetch("https://www.andhracode.com/api/convert", {
    method: "POST",
    headers: {"content-type": "application/x-www-form-urlencoded"},
    body: modernBody,
  });
  if (!modernResponse.ok) {
    throw new Error(`AndhraCode /api/convert failed: ${modernResponse.status}`);
  }
  const modern = await modernResponse.text();
  const legacyResponse = await fetch(
    "https://www.andhracode.com/api/legacy-convert",
    {
      method: "POST",
      headers: {"content-type": "application/x-www-form-urlencoded"},
      body: new URLSearchParams({input: modern}),
    }
  );
  if (!legacyResponse.ok) {
    throw new Error(
      `AndhraCode /api/legacy-convert failed: ${legacyResponse.status}`
    );
  }
  return legacyToPua(await legacyResponse.text());
}

async function main() {
  fs.mkdirSync(path.dirname(outPath), {recursive: true});
  const dataset = new Array(selected.length);
  let nextIndex = 0;
  async function worker() {
    while (nextIndex < selected.length) {
      const index = nextIndex;
      nextIndex += 1;
    const entry = selected[index];
    const legacy = await convertWithAndhraCode(entry.unicode);
      dataset[index] = {
      unicode: entry.unicode,
      legacy,
      legacyHex: hex(legacy),
      description: entry.description,
      group: entry.group,
      };
    if ((index + 1) % 25 === 0) {
      console.log(`Generated ${index + 1}/${selected.length}`);
    }
  }
  }
  await Promise.all(Array.from({length: 8}, () => worker()));
  fs.writeFileSync(outPath, JSON.stringify(dataset, null, 2) + "\n", "utf8");
  console.log(`Wrote ${dataset.length} entries to ${outPath}`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
