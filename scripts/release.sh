#!/usr/bin/env bash -e

. gradle.properties
. $HOME/.gradle/gradle.properties

function nextVersion() {
    target=$1
    ver=$2
    case "$target" in
        "major")
            baseVer=${ver%*.*-*}
            majorVer=${baseVer%*.*}
            nextMajor=$(($majorVer + 1))
            nextVer="${nextMajor}.0.0-1-SNAPSHOT"
            echo $nextVer
        ;;

        "minor")
            baseVer=${ver%*.*-*}
            minorVer=${baseVer##*.}
            nextMinor=$(($minorVer + 1))
            nextVer="${baseVer%*.*}.${nextMinor}.0-1-SNAPSHOT"
            echo $nextVer
        ;;

        "build")
            baseVer=${ver%*-*}
            baseVer=${baseVer%*-*}
            buildVer=${baseVer##*.}
            nextBuild=$(($buildVer + 1))
            nextVer="${baseVer%*.*}.${nextBuild}-1-SNAPSHOT"
            echo $nextVer
        ;;

        *)
            baseVer=${ver%*-}
            patchVer=${baseVer##*-}
            nextPatch=$(($patchVer + 1))
            nextVer="${baseVer%*-*}-${nextPatch}-SNAPSHOT"
            echo $nextVer
        ;;
    esac
}

version=${VERSION_NAME%*-SNAPSHOT}
nextVersion=$(nextVersion "$1" "$version")

echo "Starting release for logback-android-${version} ..."

fail() {
    echo "error: $1" >&2
    exit 1
}

# Run Git integrity checks early (gradle-release-plugin does this
# after we update the readme) to avoid premature push of new readme
[[ "$(git rev-parse master)" != "$(git rev-parse origin/master)" ]] && fail "branches out of sync"
[[ -n "$(git status -u -s)" ]] && fail "found unstaged changes"

./gradlew   -Prelease.useAutomaticVersion=true  \
            -Prelease.releaseVersion=${version} \
            -Prelease.newVersion=${nextVersion} \
            -Pversion=${version}                \
            -PVERSION_NAME=${version}           \
            -Ppush                              \
            -x test                             \
            clean                               \
            readme                              \
            release                             \
            artifactoryPublish

# To deploy archives without git transactions (tagging, etc.),
# replace the `release` task above with `assembleRelease`.

echo -e "\n\n"

# FIXME: In test repo, this can't checkout 'gh-pages' -- no error provided
#./gradlew   uploadDocs
echo TODO: upload javadocs to gh-pages with:
echo scripts/deploydocs.sh ${version}

# FIXME: hub is no longer able to find tagged releases for some reason.
#hub release edit -m '' v_${version} -a build/logback-android-${version}.jar
echo TODO: attach uber jar to release at:
echo https://github.com/tony19/logback-android/releases/tag/v_${version}
