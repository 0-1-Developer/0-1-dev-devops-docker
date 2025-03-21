const fs = require("fs");
const path = require("path");

const baseDir = path.resolve(__dirname, ".."); // Go up from scripts/
const folders = fs.readdirSync(baseDir).filter((f) =>
  fs.statSync(path.join(baseDir, f)).isDirectory()
);

folders.forEach((folder) => {
  const folderPath = path.join(baseDir, folder);
  const files = fs
    .readdirSync(folderPath)
    .filter((file) => /^part\d+\.md$/.test(file))
    .sort((a, b) => {
      const aNum = parseInt(a.match(/\d+/)[0], 10);
      const bNum = parseInt(b.match(/\d+/)[0], 10);
      return aNum - bNum;
    });

  if (files.length === 0) return;

  let readmeContent = `# ${folder} – Documentation Index\n\n`;

  files.forEach((file) => {
    const filePath = path.join(folderPath, file);
    const content = fs.readFileSync(filePath, "utf8");
    const firstLine = content.split("\n")[0].replace(/^#\s*/, "").trim();
    readmeContent += `- [${firstLine}](${file})\n`;
  });

  fs.writeFileSync(path.join(folderPath, "README.md"), readmeContent);
  console.log(`✅ README.md generated in ${folder}`);
});
