export function validateFiles(files, { maxFiles, maxBytes, accept }) {
  let acceptedCount = 0;
  const selections = files.map((file) => {
    const rejection = fileRejection(file, { maxBytes, accept });
    if (rejection) return rejection;

    if (acceptedCount >= maxFiles) {
      return { file, reason: maxFilesMessage(maxFiles) };
    }

    acceptedCount += 1;
    return { file, reason: null };
  });

  return {
    accepted: selections
      .filter(({ reason }) => !reason)
      .map(({ file }) => file),
    rejected: selections.filter(({ reason }) => reason),
  };
}

export function rejectionMessage(rejected) {
  return Array.from(new Set(rejected.map(({ reason }) => reason))).join(" ");
}

export function formatBytes(bytes) {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}

function fileRejection(file, { maxBytes, accept }) {
  if (maxBytes && file.size > maxBytes) {
    return {
      file,
      reason: `${file.name} is larger than ${formatBytes(maxBytes)}.`,
    };
  }
  if (accept && !accepts(file, accept)) {
    return { file, reason: `${file.name} is not an accepted file type.` };
  }

  return null;
}

function accepts(file, accept) {
  return accept.split(",").some((rawRule) => {
    const rule = rawRule.trim().toLowerCase();
    const type = file.type.toLowerCase();
    const name = file.name.toLowerCase();

    if (rule.startsWith(".")) return name.endsWith(rule);
    if (rule.endsWith("/*")) return type.startsWith(rule.slice(0, -1));
    return type === rule;
  });
}

function maxFilesMessage(maxFiles) {
  return `Choose no more than ${maxFiles} ${maxFiles === 1 ? "file" : "files"}.`;
}
