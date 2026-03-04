# Prospero EAP7-2291 (Add ability to update WildFly to a specific version of a manifest using wildfly-channels)

Following steps would provision a Wildfly instance containing EAP7-2291 changes in prospero & wildfly-core.

## 1. Checkout current prospero main and rebuild locally:

```
cd prospero-src/
git checkout main
git pull upstream main
mvn clean deploy -DskipTests -Pdist -DaltDeploymentRepository=deploy::file:maven-repo
```

Note the version of prospero that's been build.

## 2. Checkout current wildfly-core main and rebuild locally:

```
cd wildfly-core-src/
git fetch upstream pull/6562/head:pr6562
git checkout pr6562
mvn clean deploy -DskipTests -DaltDeploymentRepository=deploy::file:maven-repo
```

Note the version of wildfly-core that's been build.

## 3. Prepare the provisioning.xml file:

(Present in the repo.)

```
$ cat provisioning.xml 
<?xml version="1.0" ?>
<installation xmlns="urn:jboss:galleon:provisioning:3.0">
    <feature-pack location="org.wildfly:wildfly-ee-galleon-pack::zip"/>
    <feature-pack location="org.wildfly.prospero:prospero-wildfly-galleon-pack::zip"/>
</installation>
```

## 4. Prepare channel file

(The wildfly-prospero-channels.yaml present in the repo.)

## 5. Run prospero to provision a Wildfly instance:

(Update the manifest versions bellow to reflect what has been build in previous steps.)

```
path/to/prospero-src/dist/build/target/prospero-1.4.0.Beta4-SNAPSHOT/bin/prospero.sh install \
    --dir wf --definition provisioning.xml \
    --channels wildfly-prospero-channels.yaml \
    --manifest-versions wildfly-ee::39.0.0.Final,wildfly-core::32.0.0.Beta4-SNAPSHOT,prospero::1.4.0.Beta4-SNAPSHOT
```

Verify that versions of wildfly-core manifest and prospero manifest are the ones that were built in above steps:

```
cat wf/.installation/manifest-versions.yaml
```

