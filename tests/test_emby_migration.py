"""Exercise container removal and deployment failures without a live server."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


HELPER = Path(__file__).resolve().parents[1] / "scripts/lib/emby-migration.sh"
HARNESS = r'''
set -Eeuo pipefail
docker() {
  printf '%s\n' "$*" >> "$ROOT_DIR/actions"
  case "$*" in
    'ps -aq '*) [[ "$SCENARIO" == absent ]] || echo legacy-id ;;
    *'com.docker.compose.project'*)
      if [[ "$SCENARIO" == foreign ]]; then echo other-stack; else echo media-server; fi ;;
    *'.Mounts'*)
      if [[ "$SCENARIO" == wrong_path ]]; then echo /wrong/config; else echo "$CONFIG_ROOT/jellyfin"; fi ;;
    'compose pull '*) [[ "$SCENARIO" != fail_pull ]] ;;
    'compose up -d') [[ "$SCENARIO" != fail_start ]] ;;
    'rm legacy-id') [[ "$SCENARIO" != fail_remove ]] ;;
  esac
}
curl() {
  printf '%s\n' "$*" >> "$ROOT_DIR/http"
  [[ "$SCENARIO" != fail_http ]]
}
sleep() { :; }
source "$HELPER"
prepare_emby_migration
docker compose up -d
wait_for_emby
finish_emby_migration
'''


class MigrationTests(unittest.TestCase):
    def run_migration(self, scenario):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        root = Path(temp.name)
        config = root / "config with spaces"
        (config / "jellyfin").mkdir(parents=True)
        (config / "jellyfin/users.db").write_text("original data")
        env = dict(os.environ, ROOT_DIR=str(root), CONFIG_ROOT=str(config),
                   PROJECT_NAME="media-server", EMBY_PORT="18096",
                   HELPER=str(HELPER), SCENARIO=scenario)
        result = subprocess.run(["bash", "-c", HARNESS], env=env,
                                capture_output=True, text=True)
        actions = (root / "actions").read_text().splitlines()
        self.assertEqual((config / "jellyfin/users.db").read_text(), "original data")
        self.assertNotIn("start legacy-id", actions)
        return result, actions, root

    def test_download_stop_remove_and_deploy_order(self):
        result, actions, root = self.run_migration("success")
        self.assertEqual(result.returncode, 0, result.stderr)
        sequence = ["compose pull emby homepage", "stop legacy-id", "rm legacy-id", "compose up -d"]
        positions = [actions.index(action) for action in sequence]
        self.assertEqual(positions, sorted(positions))
        self.assertIn("127.0.0.1:18096/web/index.html", (root / "http").read_text())

    def test_download_failure_keeps_jellyfin_running(self):
        result, actions, _ = self.run_migration("fail_pull")
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("stop legacy-id", actions)
        self.assertNotIn("rm legacy-id", actions)

    def test_failure_is_reported_without_restarting_jellyfin(self):
        for scenario in ("fail_start", "fail_http", "fail_remove"):
            with self.subTest(scenario=scenario):
                result, _, _ = self.run_migration(scenario)
                self.assertNotEqual(result.returncode, 0)
                self.assertNotIn("Emby iniciado", result.stdout)

    def test_fresh_install_and_retries_still_check_emby(self):
        result, actions, root = self.run_migration("absent")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn("stop legacy-id", actions)
        self.assertNotIn("rm legacy-id", actions)
        self.assertTrue((root / "http").exists())

    def test_foreign_project_or_mismatched_storage_is_not_removed(self):
        for scenario in ("foreign", "wrong_path"):
            with self.subTest(scenario=scenario):
                result, actions, _ = self.run_migration(scenario)
                self.assertNotEqual(result.returncode, 0)
                self.assertNotIn("stop legacy-id", actions)
                self.assertNotIn("rm legacy-id", actions)


if __name__ == "__main__":
    unittest.main()
