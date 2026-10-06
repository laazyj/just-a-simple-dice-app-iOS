# Pins the actionlint image CI runs (see the "Lint workflows" job).
# Kept as a Dockerfile so Dependabot's docker ecosystem can update it;
# Dependabot doesn't track docker:// references inside workflows.
FROM rhysd/actionlint:1.7.12@sha256:b1934ee5f1c509618f2508e6eb47ee0d3520686341fec936f3b79331f9315667
