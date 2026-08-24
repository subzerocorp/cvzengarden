/**
 * Calculation: grow a JSON Resume to a target size by repeating its `work`
 * entries, renamed `Job 1 … Job N` (Devon's 2 000-job résumé).
 */

const MIB = 1024 * 1024;

function utf8Bytes(text) {
  return Buffer.byteLength(text, "utf8");
}

function job(entry, index) {
  return { ...entry, name: `Job ${index + 1}` };
}

function withJobs(resume, count) {
  const base = resume.work;
  return { ...resume, work: Array.from({ length: count }, (_, i) => job(base[i % base.length], i)) };
}

// Smallest job count whose JSON text is at least `minBytes`, found from the
// size of one representative entry, then verified by growing if short.
export function largeResume(resume, minBytes) {
  const perJob = utf8Bytes(JSON.stringify(withJobs(resume, 2))) - utf8Bytes(JSON.stringify(withJobs(resume, 1)));
  let count = Math.max(1, Math.ceil((minBytes - utf8Bytes(JSON.stringify(withJobs(resume, 0)))) / perJob));
  let text = JSON.stringify(withJobs(resume, count));
  while (utf8Bytes(text) < minBytes) {
    count += 1;
    text = JSON.stringify(withJobs(resume, count));
  }
  return { text, bytes: utf8Bytes(text), jobs: count, lastName: `Job ${count}` };
}

export function mebibytes(bytes) {
  return (bytes / MIB).toFixed(2);
}
