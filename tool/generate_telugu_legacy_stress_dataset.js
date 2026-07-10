const fs = require("fs");
const path = require("path");

const outPath = path.join(
  process.cwd(),
  "test",
  "data",
  "telugu_legacy_stress_dataset.json"
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

const words = [
  "లక్ష్మి",
  "లక్ష్మీ",
  "లక్ష్యం",
  "లక్ష్యాలు",
  "సూక్ష్మం",
  "సూక్ష్మదర్శిని",
  "క్షీణత",
  "క్షేత్రం",
  "క్షౌరం",
  "అక్షరం",
  "అక్షరాస్యత",
  "సాక్ష్యం",
  "భిక్ష",
  "రాక్షసుడు",
  "కృతజ్ఞత",
  "కృతజ్ఞతలు",
  "కృతజ్ఞతాభివందనం",
  "విజ్ఞానం",
  "విజ్ఞప్తి",
  "ప్రజ్ఞ",
  "ప్రజ్ఞావంతుడు",
  "సంజ్ఞ",
  "జ్ఞానం",
  "జ్ఞాపకం",
  "అజ్ఞానం",
  "అజ్ఞాత",
  "ఆజ్ఞ",
  "ఆజ్ఞాపించు",
  "స్త్రీ",
  "స్త్రీత్వం",
  "స్తోత్రం",
  "అస్త్రం",
  "శాస్త్రం",
  "శస్త్రం",
  "మహారాష్ట్ర",
  "రాష్ట్రం",
  "రాష్ట్రపతి",
  "రాష్ట్రీయ",
  "ఇండస్ట్రీ",
  "మినిస్ట్రీ",
  "కెమిస్ట్రీ",
  "స్ట్రీట్",
  "స్ట్రక్చర్",
  "స్ట్రెస్",
  "స్క్రిప్ట్",
  "స్క్రీన్",
  "స్క్రోల్",
  "స్రవంతి",
  "స్రష్ట",
  "స్రవణం",
  "టెక్స్ట్",
  "కాంటెక్స్ట్",
  "నెక్స్ట్",
  "టెస్ట్",
  "పోస్ట్",
  "వెబ్‌సైట్",
  "బాక్స్",
  "ఫిక్స్",
  "ల్యాబ్",
  "సాఫ్ట్‌వేర్",
  "హార్డ్‌వేర్",
  "దుఃఖం",
  "నమః",
  "ఓం నమః శివాయ",
  "అంతఃపురం",
  "ప్రాతఃకాలం",
  "శ్రీ",
  "శ్రద్ధ",
  "శ్రేయస్సు",
  "వ్యాఖ్య",
  "వ్యాసం",
  "ధ్యానం",
  "దృష్టి",
  "ద్రవ్యము",
  "పద్మ",
  "బ్రహ్మ",
  "చిహ్నం",
  "పుణ్యం",
  "వృద్ధి",
  "స్వాతంత్ర్యం",
  "సాంప్రదాయం",
  "సంప్రదాయం",
  "సంపూర్ణం",
  "నిర్మాణం",
  "సమగ్రం",
  "అత్యవసరం",
  "మృత్యుంజయుడు",
  "శృంగారం",
  "దృఢత్వం",
  "పృథ్వి",
  "గృహప్రవేశం",
  "స్వర్ణోత్సవం",
  "అంతర్జాతీయ",
  "అభ్యుదయం",
  "అత్యుత్తమం",
  "దైవజ్ఞుడు",
  "నిష్కర్ష",
  "సంప్రాప్తి",
  "సంప్రేక్షణ",
  "ఉద్ఘాటన",
  "అధ్యక్షుడు",
  "సద్గురు",
  "సద్భావన",
  "ఉత్కృష్టం",
  "౦౧౨౩౪౫౬౭౮౯",
  "0123456789",
  "77 వ సంవత్సరంలో",
  ".,:;!?()[]{}+-*/&@#$%^_",
  "ం ః ఁ",
];

function legacyToPua(text) {
  return Array.from(text, (ch) => {
    const code = ch.codePointAt(0);
    const byte = cp1252.get(code) ?? code;
    return String.fromCodePoint(0xf000 + byte);
  }).join("");
}

function hex(text) {
  return Array.from(text, (ch) =>
    ch.codePointAt(0).toString(16).toUpperCase().padStart(4, "0")
  ).join(" ");
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

function groupFor(input) {
  if (/^[0-9]+$/.test(input)) return "english-digits";
  if (/^[౦-౯]+$/.test(input)) return "telugu-digits";
  if (/^[.,:;!?()[\]{}+\-*/&@#$%^_]+$/.test(input)) return "symbols";
  if (input === "ం ః ఁ") return "telugu-signs";
  if (input.includes("క్ష్మ")) return "క్ష్మ";
  if (input.includes("క్ష్య")) return "క్ష్య";
  if (input.includes("క్ష")) return "క్ష";
  if (input.includes("జ్ఞ")) return "జ్ఞ";
  if (input.includes("స్త్ర")) return "స్త్ర";
  if (input.includes("స్ట్ర")) return "స్ట్ర";
  if (input.includes("ష్ట్ర")) return "ష్ట్ర";
  if (input.includes("స్క్ర")) return "స్క్ర";
  if (input.includes("స్ర")) return "స్ర";
  if (input.includes("శ్ర")) return "శ్ర";
  if (input.includes("వ్య")) return "వ్య";
  if (input.includes("ధ్య")) return "ధ్య";
  if (input.includes("ద్ర")) return "ద్ర";
  if (input.includes("బ్ర") || input.includes("హ్మ")) return "బ్ర/హ్మ";
  return "stress";
}

async function main() {
  fs.mkdirSync(path.dirname(outPath), {recursive: true});
  const dataset = [];
  for (let index = 0; index < words.length; index += 1) {
    const unicode = words[index];
    const legacy = await convertWithAndhraCode(unicode);
    dataset.push({
      unicode,
      legacy,
      legacyHex: hex(legacy),
      group: groupFor(unicode),
      description: `stress regression: ${unicode}`,
    });
    console.log(`Generated ${index + 1}/${words.length}`);
  }
  fs.writeFileSync(outPath, JSON.stringify(dataset, null, 2) + "\n", "utf8");
  console.log(`Wrote ${dataset.length} entries to ${outPath}`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
