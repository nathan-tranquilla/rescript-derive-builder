#!/usr/bin/env node

// Set NODE_PATH to help with module resolution
if (process.env.NODE_PATH) {
  process.env.NODE_PATH = process.env.NODE_PATH + ':' + __dirname + '/../node_modules';
} else {
  process.env.NODE_PATH = __dirname + '/../node_modules';
}

console.log('rescript-derive-builder starting...');

import('../lib/es6/src/Codegen.res.mjs')
  .then(() => {
    console.log('rescript-derive-builder completed successfully');
  })
  .catch(err => {
    console.error('Failed to run rescript-derive-builder:');
    console.error('Error message:', err.message);
    console.error('Stack trace:', err.stack);
    console.error('Current directory:', process.cwd());
    console.error('NODE_PATH:', process.env.NODE_PATH);
    process.exit(1);
  });