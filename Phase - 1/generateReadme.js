const fs = require("fs");
const path = require("path");

const dir = __dirname;
const files = fs.readdirSync(dir).filter(file => /^part\d+\.md$/.test(file));

let readmeContent = "# Documentation Index\n\n";

files.sort((a, b) => {
  const aNum = parseInt(a.match(/\d+/)[0], 10);
  const bNum = parseInt(b.match(/\d+/)[0], 10);
  return aNum - bNum;
});

for (const file of files) {
  const content = fs.readFileSync(path.join(dir, file), "utf8");
  const firstLine = content.split("\n")[0].replace(/^#\s*/, "").trim(); // Remove markdown header symbol
  readmeContent += `- [${firstLine}](${file})\n`;
}

fs.writeFileSync("README.md", readmeContent);
console.log("README.md generated!");
