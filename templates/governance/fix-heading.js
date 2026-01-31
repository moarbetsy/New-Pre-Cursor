const fs = require("node:fs");
const content = fs.readFileSync(
	"governance-system-template_DOCUMENTATION.md",
	"utf8",
);
const updated = content.replace(
	/## 8\) "Lockfile law" and what's missing in this archive ⚠️/g,
	'## 8) "Lockfile law" and lockfile status',
);
fs.writeFileSync(
	"governance-system-template_DOCUMENTATION.md",
	updated,
	"utf8",
);
console.log("Heading updated");
