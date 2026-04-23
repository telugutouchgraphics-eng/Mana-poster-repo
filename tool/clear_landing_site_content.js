#!/usr/bin/env node

const {execFileSync} = require("child_process");

const project = "mana-poster-ap";
const bucket = "gs://mana-poster-ap.firebasestorage.app";
const firebaseBin = process.platform === "win32" ? "firebase.cmd" : "firebase";
const gsutilBin = process.platform === "win32" ? "gsutil.cmd" : "gsutil";

function run(command, args) {
  execFileSync(command, args, {
    stdio: "inherit",
  });
}

function deleteFirestore(path, extraArgs = []) {
  run(firebaseBin, [
    "firestore:delete",
    path,
    "--project",
    project,
    "--force",
    ...extraArgs,
  ]);
}

function deleteStoragePrefix(prefix) {
  const target = `${bucket}/${prefix}/**`;
  try {
    execFileSync(gsutilBin, ["ls", "-r", target], {
      stdio: "ignore",
    });
  } catch (_) {
    console.log(`No Storage files found under ${prefix}/.`);
    return;
  }
  run(gsutilBin, ["-m", "rm", target]);
}

deleteFirestore("landingSite/main");
deleteFirestore("websitePosters", ["--recursive"]);
deleteStoragePrefix("landing-site");
deleteStoragePrefix("website/posters");

console.log("Landing page sample content cleared.");
