const { cpSync, existsSync, stat, rmSync } = require("node:fs");
const path = require("node:path");
const { exit } = require("node:process");
const process = require("process");
const chokidar = require("chokidar");

const args = process.argv.slice(2);

if (args.length < 2) {
    console.log("Usage: watch.js <inDir> <outDir>");
    exit(1);
}

/**
 * Validates the given argument to make sure it is a real directory on the machine.
 * @param {string} arg 
 * @returns A valid absolute path as a string
 */
function validateDir(arg) {
    const dir = path.resolve(arg);
    if (!existsSync(dir)) {
        console.log(`Invalid Directory: ${arg}`);
        exit(1);
    }
    stat(dir, (err, stats) => {
        if (!stats.isDirectory()) {
            console.log(`Invalid Directory: ${dir}`);
            exit(1);
        }
    })
    return dir;
}

const inDir = validateDir(args[0]);
console.log(`> Watching: ${inDir}`);

const outDir = validateDir(args[1]);
console.log(`> Target: ${outDir}`);

console.log("> Ctrl+C to exit");

const watcher = chokidar.watch(inDir, { persistent: true, ignoreInitial: true });

function migrateFile(path) {
    console.log(`Migrating file: ${path}`);
    const target = path.replace(inDir, outDir)
    cpSync(path, target);
}

function removeFile(path) {
    console.log(`Removing file: ${path}`);
    const target = path.replace(inDir, outDir);
    rmSync(target, { force: true });
}

watcher.on("add", (path) => migrateFile(path))
    .on("change", (path) => migrateFile(path))
    .on("unlink", (path) => removeFile(path))
    .on("error", (path) => console.error("Error", error));