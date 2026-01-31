const fs = require("node:fs");
const content = fs.readFileSync(
	"governance-system-template_DOCUMENTATION.md",
	"utf8",
);
// Match the heading with any characters including emoji
const pattern =
	/## 8\) "Lockfile law" and what's missing in this archive[^\n]*/g;
const updated = content.replace(
	pattern,
	'## 8) "Lockfile law" and lockfile status',
);
fs.writeFileSync(
	"governance-system-template_DOCUMENTATION.md",
	updated,
	"utf8",
);
console.log("Heading updated successfully");
