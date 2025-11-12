#!/usr/bin/env bash
#
# fetch_latest_report.sh — Find latest analysis report, print it for copying.
#

REPO_ROOT="${HOME}/etherverse"
REPORT_FILE=$(ls -1t "${REPO_ROOT}/analysis_report_"*.txt 2>/dev/null | head -n1)

if [ -z "$REPORT_FILE" ]; then
  echo "No analysis report found in ${REPO_ROOT}."
  exit 1
fi

echo "=== Latest Report: $REPORT_FILE ==="
echo ""
cat "$REPORT_FILE"
echo ""
echo "=== End of Report ==="
