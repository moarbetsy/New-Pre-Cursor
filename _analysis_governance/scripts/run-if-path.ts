import { existsSync } from "node:fs";

function usage(): never {
	console.error(
		[
			"Usage:",
			"  bun ./scripts/run-if-path.ts <path> -- <command> [args...]",
			"",
			"Examples:",
			"  bun ./scripts/run-if-path.ts Cargo.toml -- cargo test",
			"  bun ./scripts/run-if-path.ts tests -- uv run pytest -q",
		].join("\n"),
	);
	process.exit(2);
}

const argv = Bun.argv.slice(2);
const pathToCheck = argv[0];
if (!pathToCheck) usage();

const sep = argv.indexOf("--");
if (sep === -1) usage();

const cmd = argv.slice(sep + 1);
if (cmd.length === 0) usage();

if (!existsSync(pathToCheck)) {
	console.log(`Skipping: missing \`${pathToCheck}\``);
	process.exit(0);
}

const proc = Bun.spawn(cmd, {
	stdin: "inherit",
	stdout: "inherit",
	stderr: "inherit",
});

process.exit(await proc.exited);
