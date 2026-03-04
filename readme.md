# Prospero EAP7-2291 (Add ability to update WildFly to a specific version of a manifest using wildfly-channels)

Following steps would provision a Wildfly instance containing EAP7-2291 changes in prospero & wildfly-core.

## 1. Checkout current prospero main and rebuild locally:

```
# Navigate to prospero sources, then:
git checkout main
git pull upstream main
mvn clean deploy -DskipTests -Pdist -DaltDeploymentRepository=deploy::file:maven-repo
```

Note the version of prospero that's been build.

The `maven-repo/` directory in the source directory should have been created, which contains built artifacts.

## 2. Checkout current wildfly-core main and rebuild locally:

```
# Navigate to wildfly-core sources, then:
git fetch upstream pull/6562/head:pr6562
git checkout pr6562
mvn clean deploy -DskipTests -DaltDeploymentRepository=deploy::file:maven-repo
```

Note the version of wildfly-core that's been build.

The `maven-repo/` directory in the source directory should have been created, which contains built artifacts.

## 3. Prepare the provisioning.xml file:

The provisioning.xml file is present in this repository.

```
$ cat provisioning.xml 
<?xml version="1.0" ?>
<installation xmlns="urn:jboss:galleon:provisioning:3.0">
    <feature-pack location="org.wildfly:wildfly-ee-galleon-pack::zip"/>
    <feature-pack location="org.wildfly.prospero:prospero-wildfly-galleon-pack::zip"/>
</installation>
```

## 4. Prepare manifests for wildfly-core

This file is present in this repository.

```
$ cat wildfly-core-manifest.yaml 
---
schemaVersion: "1.1.0"
id: "override-wildfly-core"
streams:
  - groupId: "org.wildfly.core"
    artifactId: "wildfly-installation-manager"
    version: "32.0.0.Beta4-SNAPSHOT"
  - groupId: "org.wildfly.installation-manager"
    artifactId: "installation-manager-api"
    version: "1.2.1.Beta2"
```

Note that the file contains version of wildfly-core that has been build. If the version needs to change,
rewrite the version in above file and run `rebuild-manifest-repo.sh` script. The script regenerates the
maven repo in the `manifest-maven-repo/` directory, which is where prospero consumes the manifest from.

## 5. Prepare channel file

This file is present in this repository: channels.yaml

This file contains some paths to local maven repositories like
`file:/home/thofman/Projects/prospero/maven-repo`, these need to be updated to reflect your layout.

## 6. Run prospero to provision a Wildfly instance:

(Update the prospero manifest version bellow to reflect what has been build in step 1.)

```
path/to/prospero-src/dist/build/target/prospero-1.4.0.Beta4-SNAPSHOT/bin/prospero.sh install \
    --dir wf --definition provisioning.xml \
    --channels channels.yaml \
    --manifest-versions wildfly-ee::39.0.0.Final,wildfly-core::1.0,prospero::1.4.0.Beta4-SNAPSHOT
```

(Optionally) Verify that component versions are as expected:

```
$ ls wf/modules/system/layers/base/org/wildfly/installation-manager/api/main/*jar
installation-manager-api-1.2.1.Beta2.jar
$ ls wf/modules/system/layers/base/org/wildfly/installation-manager/main/*jar
wildfly-installation-manager-32.0.0.Beta4-SNAPSHOT.jar
$ ls wf/modules/system/layers/base/org/jboss/prospero/main/prospero-cli*.jar
wf/modules/system/layers/base/org/jboss/prospero/main/prospero-cli-1.4.0.Beta4-SNAPSHOT.jar
```

## 7. Check the functionality

Prospero should be able to list newer Wildfly version being available.

Example:

```
$ ./wf/bin/prospero.sh update list-manifest-versions --dir wf/
Checking available updates for /home/thofman/Documents/prospero-rfe-setup/wf

Found new versions of channel manifests available:
 - channel name: wildfly-ee
   current version: 39.0.0.Final
   available versions:
   - 39.0.1.Final (WildFly EE 39.0.1.Final)

To perform the update to selected version use update operation with the `--manifest-versions` parameter like:

    prospero update perform --dir /home/thofman/Documents/prospero-rfe-setup/wf --manifest-versions prospero::1.4.0.Beta4-SNAPSHOT,wildfly-core::1.0,wildfly-ee::39.0.0.Final

Operation completed in 6.65 seconds.
```

## JBoss CLI functionality

Start server:

```
$ ./wf/bin/standalone.sh
```

Start JBoss CLI:

```
$ ./wf/bin/jboss-cli.sh -c
```

In JBoss CLI:

### High level commands

List available manifest versions (The --include-downgrades is false by default):

```
[standalone@localhost:9990 /] installer list-manifest-versions --include-downgrades=true
```

Update (args are optional):

```
installer update --manifest-versions=prospero::1.4.0.Beta4-SNAPSHOT,wildfly-core::1.0,wildfly-ee::39.0.1.Final --allow-manifest-downgrades=true 
```

### Low level operations

Listing available manifest versions (you can set include-downgrades to true to get all available versions):

```
[standalone@localhost:9990 /] /core-service=installer:list-manifest-versions(include-downgrades=false)
{
    "outcome" => "success",
    "result" => [
        {
            "name" => "prospero",
            "location" => "org.wildfly.prospero:prospero-wildfly-galleon-pack",
            "current-version" => "1.4.0.Beta4-SNAPSHOT",
            "manifest-versions" => undefined
        },
        {
            "name" => "wildfly-core",
            "location" => "channels:wildfly-core",
            "current-version" => "1.0",
            "manifest-versions" => undefined
        },
        {
            "name" => "wildfly-ee",
            "location" => "org.wildfly.channels:wildfly-ee",
            "current-version" => "39.0.0.Final",
            "current-logical-version" => "WildFly EE 39.0.0.Final",
            "manifest-versions" => [{
                "version" => "39.0.1.Final",
                "logical-version" => "WildFly EE 39.0.1.Final"
            }]
        }
    ]
}
```

Listing artifacts to be upgraded (the manifest-versions arg is optional):

```
[standalone@localhost:9990 /] /core-service=installer:list-updates(manifest-versions=[{name=wildfly-ee, version=39.0.1.Final}, {name=prospero, version=1.4.0.Beta4-SNAPSHOT}, {name=wildfly-core, version=1.0}])
{
    "outcome" => "success",
    "result" => {
        "updates" => [
            {
                "status" => "updated",
                "name" => "io.undertow:undertow-core",
                "old-version" => "2.3.22.Final",
                "new-version" => "2.3.23.Final"
            },
            {
                "status" => "updated",
                "name" => "io.undertow:undertow-servlet",
                "old-version" => "2.3.22.Final",
                "new-version" => "2.3.23.Final"
            },
...
        "manifest-updates" => [{
            "name" => "wildfly-ee",
            "location" => "org.wildfly.channels:wildfly-ee",
            "old-version" => "39.0.0.Final",
            "new-version" => "39.0.1.Final",
            "old-logical-version" => "WildFly EE 39.0.0.Final",
            "new-logical-version" => "WildFly EE 39.0.1.Final",
            "is-downgrade" => false
        }]
    }
}
```

Preparing update (manifest-versions & allow-manifest-downgrades args are optional):

```
/core-service=installer:prepare-updates(manifest-versions=[{name=wildfly-ee, version=39.0.1.Final}, {name=prospero, version=1.4.0.Beta4-SNAPSHOT}, {name=wildfly-core, version=1.0}], allow-manifest-downgrades=true)
{
    "outcome" => "success",
    "result" => "/home/thofman/Documents/prospero-rfe-setup/wf/standalone/tmp/in
stallation-manager/prepared-server"
}
```

