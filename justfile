container:
    sudo podman build --tag=ghcr.io/jdmarble/dl-client-appliance:latest .

push: container
    sudo podman push ghcr.io/jdmarble/dl-client-appliance:latest

_tempdirs:
    mkdir -p output
    mkdir -p cache/rpmmd

image type: container _tempdirs
    sudo podman run \
        --rm \
        --name bootc-image-builder \
        --interactive \
        --tty \
        --privileged \
        --pull=newer \
        --security-opt label=type:unconfined_t \
        -v $(pwd)/config.toml:/config.toml \
        -v $(pwd)/output:/output \
        -v $(pwd)/cache/rpmmd:/rpmmd \
        -v /var/lib/containers/storage:/var/lib/containers/storage \
        quay.io/centos-bootc/bootc-image-builder:sha256-e53a3916cfc416f00a54a93757d7a48beb1af7fce3a3a329d07a0eea2e2b0737 \
        ghcr.io/jdmarble/dl-client-appliance:latest \
        --local \
        --type {{type}} \
        --target-arch amd64

anaconda-iso: (image "anaconda-iso")
raw: (image "raw")
qcow2: (image "qcow2")

qemu-test: qcow2
    qemu-system-x86_64 \
        -M accel=kvm \
        -cpu host \
        -smp 2 \
        -m 2048 \
        -device e1000,netdev=net0 \
        -netdev user,id=net0,hostfwd=tcp::9091-:9091,hostname=vm \
        -nographic \
        -snapshot output/qcow2/disk.qcow2
