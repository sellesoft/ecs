---
instance-of: tool
---

`loggen` is less of a 'tool' and more of an isolated build step. This is used to generate headers used throughout most of [[main_source_tree|src/]] for logging things at runtime. Its isolated so that its easier to build before anything in src/.