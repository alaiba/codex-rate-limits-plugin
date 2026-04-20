# Contributing

Run the documented quality gates before opening a pull request:

```bash
make quality
```

Run the broader repo-fit smoke checks when you change plugin packaging, marketplace wiring, or runtime error handling:

```bash
make quality-full
```

If you change the skill instructions, helper output, or routing behavior, also run the live authenticated validation steps in [docs/TESTING.md](docs/TESTING.md).
