#!/usr/bin/env node
"use strict";

const path = require("path");
const { main } = require("../src/cli");

const code = main(process.argv, path.dirname(__filename));
if (typeof code === "number" && code !== 0) {
  process.exit(code);
}
