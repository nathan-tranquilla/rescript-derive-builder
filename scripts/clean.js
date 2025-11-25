const fs = require('fs');
const glob = require('glob');

// Clean all __generated__ folders
const generatedDirs = glob.sync('**/__generated__', { ignore: 'node_modules/**' });
generatedDirs.forEach(dir => {
  try {
    fs.rmSync(dir, { recursive: true, force: true });
    console.log(`Cleaned: ${dir}`);
  } catch (err) {
    // Directory doesn't exist, ignore
  }
});

console.log('Clean completed!');
