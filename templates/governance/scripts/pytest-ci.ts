const cmd = ["uv", "run", "--frozen", "pytest", "-q", ...Bun.argv.slice(2)];

const proc = Bun.spawnSync(cmd, {
	stdin: "inherit",
	stdout: "inherit",
	stderr: "inherit",
});

// pytest exit code 5 == "no tests collected"
if (proc.exitCode === 5) {
	process.exit(0);
}

process.exit(proc.exitCode ?? 1);
