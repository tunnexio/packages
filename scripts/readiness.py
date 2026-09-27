#!/usr/bin/env python3
"""Wait for release artifacts; never substitute for provenance verification."""
import os
import re
from upstream import api, resolve, REPO

REQUIRED = {'Tunnex-release-source.json', 'Tunnex-CLI-SHA256SUMS',
            'tnx-linux-amd64', 'tnx-linux-arm64'}

def missing_assets(release):
    if not isinstance(release, dict):
        raise ValueError('Malformed release response')
    if type(release['draft']) is not bool or type(release['prerelease']) is not bool:
        raise ValueError('Malformed release flags')
    if not isinstance(release['tag_name'], str) or not isinstance(release['assets'], list):
        raise ValueError('Malformed release tag or assets')
    if any(not isinstance(a, dict) or not isinstance(a.get('name'), str) for a in release['assets']):
        raise ValueError('Malformed release asset')
    if release['draft'] or release['prerelease'] or not re.fullmatch(r'v\d+\.\d+\.\d+', release['tag_name']):
        raise ValueError('Only public stable semantic releases are eligible')
    return REQUIRED - {a['name'] for a in release['assets']}

def main():
    release = api(f'repos/{REPO}/releases/latest')
    missing = missing_assets(release)
    # A present marker must remain valid even while other assets are uploading.
    if 'Tunnex-release-source.json' not in missing:
        if resolve()['tag'] != release['tag_name']:
            raise ValueError('Latest release changed during readiness verification; retry')
    ready = not missing
    message = ('Upstream release artifacts ready; provenance verification still required.' if ready
               else 'Waiting for upstream release artifacts: ' + ', '.join(sorted(missing)))
    message = release['tag_name'] + ': ' + message
    print(message)
    with open(os.environ['GITHUB_OUTPUT'], 'a') as out:
        out.write('ready=' + str(ready).lower() + '\n')
    if os.environ.get('GITHUB_STEP_SUMMARY'):
        with open(os.environ['GITHUB_STEP_SUMMARY'], 'a') as out:
            out.write(message + '\n')

if __name__ == '__main__':
    main()
