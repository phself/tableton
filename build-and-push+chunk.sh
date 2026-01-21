echo "---------------- Building Container Image ----------------"
podman build -f Containerfile -t quay.io/rh-ee-sayash/tableton:latest .
echo "---------- Pushing to Registry ----------"
podman push quay.io/rh-ee-sayash/tableton:latest --authfile pull-secret.json

echo "------------ Building Chunked Container Image ------------"
rpm-ostree compose build-chunked-oci --bootc --format-version=2 --from=quay.io/rh-ee-sayash/tableton:latest --output=containers-storage:quay.io/rh-ee-sayash/tableton:latest-chunked

echo "------------- Pushing Chunked Container Image -------------"
podman push quay.io/rh-ee-sayash/tableton:latest-chunked --authfile pull-secret.json
