const { execFileSync } = require('child_process');
let output;
try {
  output = execFileSync('npm', ['audit', '--json'], { encoding: 'utf8' });
} catch (error) {
  output = error.stdout.toString();
}
const audit = JSON.parse(output);
for (const [key, val] of Object.entries(audit.vulnerabilities)) {
  const hasAdvisory = val.via && val.via.some(v => v.url && v.url.includes('GHSA-52cp-r559-cp3m'));
  if (hasAdvisory) {
    console.log('Vulnerable package:', key);
    console.log('Severity:', val.severity);
    console.log('Range:', val.range);
    if (val.via) {
      val.via.forEach(v => {
        if (v.url && v.url.includes('GHSA-52cp-r559-cp3m')) {
          console.log('Advisory title:', v.title);
          console.log('Advisory CVSS:', v.cvss?.score);
        }
      });
    }
  }
}
