
rm -fr maven-repo/
mkdir maven-repo/

mvn deploy:deploy-file -Durl=file:maven-repo -DrepositoryId=custom -Dfile=wildfly-core-manifest.yaml -DgroupId=channels -DartifactId=wildfly-core -Dversion=1.0 -Dclassifier=manifest

