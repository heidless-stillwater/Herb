To guarantee a completely fresh, from-scratch release build without any reused cached artifacts, you should combine the `clean` task with flags that explicitly disable Gradle's caching mechanisms and force tasks to rerun.

Here is the most bulletproof command you can run in your terminal at the root of your project:

```bash
./gradlew clean assembleRelease --no-build-cache --rerun-tasks
```

### Why this works:
1. **`clean`**: Deletes all `build/` directories across your project, wiping out previous compilation outputs.
2. **`assembleRelease`**: Tells Gradle to build the `app-release.apk`.
3. **`--no-build-cache`**: Prevents Gradle from pulling previously compiled artifacts from the global build cache (usually located in `~/.gradle/caches`).
4. **`--rerun-tasks`**: Ignores any UP-TO-DATE checks, forcing every task in the dependency graph to execute from scratch.

### (Optional) The "Nuke It From Orbit" Approach
If you suspect there is still some weird state lingering (for instance, corrupt Gradle caches or dependency issues), you can manually wipe the caches before running the build command:

```bash
# Stop any running Gradle daemons
./gradlew --stop

# Delete the project's local gradle configuration and build folders
rm -rf .gradle
find . -name "build" -type d -prune -exec rm -rf '{}' +

# Now build
./gradlew assembleRelease --no-build-cache
```