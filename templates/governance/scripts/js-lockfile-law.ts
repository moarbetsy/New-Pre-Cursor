import { existsSync } from "node:fs";
import { join } from "node:path";

type Problem = {
	file: string;
	message: string;
};

function check(): Problem[] {
	const cwd = process.cwd();
	const problems: Problem[] = [];

	const required = ["bun.lock"];
	const forbidden = [
		"package-lock.json",
		"pnpm-lock.yaml",
		"yarn.lock",
		"npm-shrinkwrap.json",
	];

	for (const file of required) {
		const fullPath = join(cwd, file);
		if (!existsSync(fullPath)) {
			problems.push({
				file,
				message:
					"Missing required lockfile. Run `bun install` (without --frozen-lockfile) once to generate it.",
			});
		}
	}

	for (const file of forbidden) {
		const fullPath = join(cwd, file);
		if (existsSync(fullPath)) {
			problems.push({
				file,
				message:
					"Forbidden lockfile present. This repo uses Bun and only allows committing `bun.lock`.",
			});
		}
	}

	return problems;
}

const problems = check();

if (problems.length > 0) {
	console.error("JS lockfile law violations:");
	for (const p of problems) {
		console.error(`- ${p.file}: ${p.message}`);
	}
	process.exit(1);
}
