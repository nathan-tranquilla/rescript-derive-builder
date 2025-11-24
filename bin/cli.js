#!/usr/bin/env node
import('../lib/es6/src/Codegen.res.mjs')
  .catch(err => {
    console.error('Failed to run rescript-derive-builder:', err.message);
    process.exit(1);
  });