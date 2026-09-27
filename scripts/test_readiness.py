import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch
from readiness import main, missing_assets, REQUIRED

class ReadinessTests(unittest.TestCase):
    def release(self, assets):
        return {'draft': False, 'prerelease': False, 'tag_name': 'v1.2.3',
                'assets': [{'name': n} for n in assets]}
    def test_empty_release_waits(self):
        self.assertEqual(missing_assets(self.release([])), REQUIRED)
    def test_partial_release_waits(self):
        missing = next(iter(REQUIRED))
        self.assertEqual(missing_assets(self.release(REQUIRED - {missing})), {missing})
    def test_complete_release_proceeds(self):
        self.assertEqual(missing_assets(self.release(REQUIRED)), set())
    def test_invalid_release_fails(self):
        for key, value in [('draft', True), ('prerelease', True), ('tag_name', 'invalid')]:
            r=self.release(REQUIRED); r[key]=value
            with self.assertRaises(ValueError): missing_assets(r)
    def test_malformed_response_fails(self):
        with self.assertRaises(KeyError): missing_assets({})

    def test_invalid_schema_fails(self):
        for key, value in [('draft', None), ('prerelease', 0), ('assets', {}),
                           ('assets', [{'name': None}]), ('tag_name', None)]:
            with self.subTest(key=key, value=value):
                release = self.release(REQUIRED)
                release[key] = value
                with self.assertRaises(ValueError):
                    missing_assets(release)

    def run_main(self, release, error=None):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / 'output'
            summary = Path(directory) / 'summary'
            with patch.dict(os.environ, GITHUB_OUTPUT=str(output), GITHUB_STEP_SUMMARY=str(summary)), \
                 patch('readiness.api', return_value=release), \
                 patch('readiness.resolve', return_value={'tag': 'v1.2.3'}, side_effect=error):
                if error:
                    with self.assertRaises(type(error)):
                        main()
                    self.assertFalse(output.exists())
                else:
                    main()
                    return output.read_text(), summary.read_text()

    def test_missing_assets_reports_wait(self):
        output, summary = self.run_main(self.release([]))
        self.assertEqual(output, 'ready=false\n')
        self.assertIn('v1.2.3: Waiting', summary)
        for name in REQUIRED:
            self.assertIn(name, summary)

    def test_complete_validated_release_reports_ready(self):
        output, summary = self.run_main(self.release(REQUIRED))
        self.assertEqual(output, 'ready=true\n')
        self.assertIn('provenance verification still required', summary)

    def test_present_invalid_marker_fails_even_if_other_assets_missing(self):
        self.run_main(self.release({'Tunnex-release-source.json'}), ValueError('Invalid source marker'))

    def test_api_failure_propagates(self):
        with patch('readiness.api', side_effect=subprocess.CalledProcessError(1, 'gh')):
            with self.assertRaises(subprocess.CalledProcessError):
                main()

    def test_changed_latest_release_fails(self):
        with patch('readiness.api', return_value=self.release(REQUIRED)), \
             patch('readiness.resolve', return_value={'tag': 'v1.2.4'}):
            with self.assertRaisesRegex(ValueError, 'Latest release changed'):
                main()
