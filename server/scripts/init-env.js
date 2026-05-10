import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const serverRoot = path.resolve(__dirname, "..");
const envPath = path.join(serverRoot, ".env");
const examplePath = path.join(serverRoot, ".env.example");

process.chdir(serverRoot);

let stat;
try {
  stat = fs.existsSync(envPath) ? fs.statSync(envPath) : null;
} catch {
  stat = null;
}

if (stat?.isDirectory()) {
  console.error(
    "Found `.env` as a DIRECTORY — remove it first:\n" +
      "  rm -rf .env\n" +
      "Then run: npm run init-env\n",
  );
  process.exit(1);
}

if (stat?.isFile()) {
  console.log(".env already exists — not overwriting.");
  process.exit(0);
}

if (!fs.existsSync(examplePath)) {
  console.error("Missing .env.example in server/. Cannot bootstrap.");
  process.exit(1);
}

fs.copyFileSync(examplePath, envPath);
console.log(
  "Created .env from .env.example in this folder.\n" +
    "Edit .env and set at least MONGODB_URI and GEMINI_API_KEY.",
);
