echo "---------------- Building Container Image ----------------"
podman build -f Containerfile -t quay.io/rh-ee-sayash/tableton:latest .

echo "------------ Building Chunked Container Image ------------"
rpm-ostree compose image \
  --bootc \
  --format=chunked-oci \
  --format-version=2 \
  --from=quay.io/rh-ee-sayash/tableton:latest \
  containers-storage:quay.io/rh-ee-sayash/tableton:latest-chunked

echo "---------- Pushing to Registry ----------"
podman push quay.io/rh-ee-sayash/tableton:latest --authfile pull-secret.json

echo "------------- Pushing Chunked Container Image -------------"
podman push quay.io/rh-ee-sayash/tableton:latest-chunked --authfile pull-secret.json
