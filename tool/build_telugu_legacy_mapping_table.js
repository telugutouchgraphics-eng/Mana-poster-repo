const fs = require("fs");
const path = require("path");

const datasetPath = path.join(
  process.cwd(),
  "test",
  "data",
  "telugu_regression.json"
);
const outPath = path.join(
  process.cwd(),
  "test",
  "data",
  "telugu_legacy_mapping_table.json"
);

function main() {
  const dataset = JSON.parse(fs.readFileSync(datasetPath, "utf8"));
  const mappings = dataset
    .map((entry) => ({
      unicode: entry.unicode,
      legacy: entry.legacy,
      legacyHex: entry.legacyHex,
      group: entry.group,
      description: entry.description,
    }))
    .sort((a, b) => a.unicode.localeCompare(b.unicode, "te"));

  fs.writeFileSync(
    outPath,
    JSON.stringify(
      {
        source: "AndhraCode development reference",
        runtimeDependency: "none",
        count: mappings.length,
        mappings,
      },
      null,
      2
    ) + "\n",
    "utf8"
  );
  console.log(`Wrote ${mappings.length} mappings to ${outPath}`);
}

main();
