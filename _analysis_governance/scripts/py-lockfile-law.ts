import { existsSync } from "node:fs";
import { join } from "node:path";

type Problem = {
	file: string;
	message: string;
};

function check(): Problem[] {
	const cwd = process.cwd();
	const problems: Problem[] = [];

	const required = ["uv.lock"];

	for (const file of required) {
		const fullPath = join(cwd, file);
		if (!existsSync(fullPath)) {
			problems.push({
				file,
				message:
					"Missing required lockfile. Run `uv lock` (or `just bootstrap`) once to generate it.",
			});
		}
	}

	return problems;
}

const problems = check();

if (problems.length > 0) {
	console.error("Python lockfile law violations:");
	for (const p of problems) {
		console.error(`- ${p.file}: ${p.message}`);
	}
	process.exit(1);
}
