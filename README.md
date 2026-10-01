# GitHub Action: Create new DevOps Deploy component version

This GitHub Action automates the process of triggering the creation of a new DevOps Deploy component version based on the provided inputs.
This action optionally allows for a version link to be created, files to be uploaded to the version and properties to be set on the version.
This action uses the DevOps Deploy udclient cli to communicate with the DevOps Deploy server and execute the implemented actions.

## Inputs

* `component` (required): The name or ID of the component in DevOps Deploy.
* `versionname` (required): The name of the new component version in DevOps Deploy.
* `description` (optional): Description of the new version.
* `linkName` (optional): The name of the link to add to the component version. Only used when `link` is specified.
* `link` (optional): URL to add to the component version.
* `base` (optional): Local base directory containing files to upload if file upload is required.
* `offset` (optional): Target path offset (the directory in the version files to which the uploaded files should be added).
* `include` (optional): Include file pattern(s) for selecting files to add. Separate multiple patterns with new lines.
* `exclude` (optional): Exclude file pattern(s) for excluding files. Separate multiple patterns with new lines. Overrides includes.
* `saveExecuteBits` (optional): `true` or `false`. Whether or not to save execute bits for files.
* `versionProperties` (optional): Properties to set on the component version.  Each property must be in the following format: \
                                  name:value:secure, where secure is `true` or `false`.  The value may contain `:` characters. \
                                  If you have multiple properties, then they should be separated by a new-line character.
* `serverUrl` (optional): Full URL of the DevOps Deploy server, including `https://` (or `http://`), e.g. `https://deploy.example.com:8443`. Overrides `urlType`, `hostname` and `port`.
* `urlType` (optional): URL protocol to use to connect to DevOps Deploy hostname.  Default is "https:".
* `hostname` (required unless `serverUrl` is specified): Hostname or IP of the DevOps Deploy server.
* `port` (optional): Port number of the DevOps Deploy server. Defaults to 8443.
* `username` (username:password or authToken is required): Username used to authenticate with the DevOps Deploy server.
* `password` (username:password or authToken is required): Password used to authenticate with the DevOps Deploy server.
* `authToken` (username:password or authToken is required): Authentication token used to authenticate with the DevOps Deploy server.  This will override the username:password if specified.
* `javaVersion` (optional): Java version to install for running the udclient (IBM Semeru Runtime). Defaults to 21.
* `udclientSource` (optional): `server` (default) downloads the udclient from the DevOps Deploy server (`/tools/udclient.zip`) so it matches \
                               the server version, falling back to the copy bundled with this action if the download fails. \
                               `bundled` always uses the bundled copy.

Always pass `password` and `authToken` from [encrypted secrets](https://docs.github.com/actions/security-guides/using-secrets-in-github-actions).

## Outputs

* `version-id`: ID of the created component version.
* `udclient-source`: Where the udclient came from: `server` or `bundled`.

## Notes

* The action installs Java 21 (IBM Semeru) with `actions/setup-java` to run the udclient; use `javaVersion` to change it.
  It restores your job's `JAVA_HOME` afterwards, but `setup-java` also adds its Java to the job's `PATH`, so later steps
  calling `java` directly will use that version.
  `actions/setup-java@v5` requires GitHub Actions runner v2.327.1 or later on self-hosted runners.
* By default the udclient is downloaded from your DevOps Deploy server. The download uses the same TLS setting as the udclient
  (`UC_TLS_VERIFY_CERTS`). If it fails, a warning is shown and the bundled udclient is used instead.
* The udclient is installed in the runner temp directory, so nothing is written to your workspace and the action can be used
  more than once in a job.
* If adding the link, files or properties fails, the version is still marked as finished importing and the job fails.
* Optional global udclient flags can be set with environment variables before the action runs, e.g.
  `UC_TLS_VERIFY_CERTS=false` to skip TLS certificate verification for servers with self-signed certificates.

## Example Usage

```yaml
name: Create DevOps Deploy Component Version

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest
    name: A job to create a DevOps Deploy component version with a version link, version files and version properties
    steps:
      - name: Create artifacts to add to component
        id: create-artifacts
        run: mkdir /tmp/artifacts && date > /tmp/artifacts/date.txt
      - name: Set short_commit_id
        id: vars
        run: echo "short_commit_id=$(echo ${{ github.event.head_commit.id }} | cut -c1-7)" >> "$GITHUB_ENV"
      - name: Set optional global flags for udclient command
        id: set-optional-global-flags
        run: echo "UC_TLS_VERIFY_CERTS=false" >> "$GITHUB_ENV"
      - uses: HCL-TECH-SOFTWARE/devops-deploy-createcomponentversion-action@v3
        id: create-version
        with:
          component: 'MyComp'
          versionname: '${{ env.short_commit_id }}:${{ github.event.head_commit.message }}'
          description: 'Commit ID: ${{ github.event.head_commit.id }} Repository URL: ${{ github.repositoryUrl }}'
          linkName: 'Git Commit'
          link: '${{ github.server_url }}/${{ github.repository }}/commit/${{ github.event.head_commit.id }}'
          base: /tmp/artifacts
          offset: demo/files
          versionProperties: |-
            TestProperty1:DemoValue1:false
            TestProperty2:DemoValue2:false
            TestProperty3:DemoValue3:true
          hostname: 'DevOps_Deploy_Server_hostname'
          port: '8443'
          authToken: '${{ secrets.DEVOPS_DEPLOY_AUTHTOKEN }}'
      - name: Show new version ID
        run: echo "Created version ${{ steps.create-version.outputs.version-id }}"
```

Referencing `@v3` picks up fixes within the v3 major version. To guarantee the exact code that runs, pin to a full commit SHA instead.
