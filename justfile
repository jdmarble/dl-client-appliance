project := "dl-client-appliance"
repo := "ghcr.io/jdmarble"

container:
    podman build --tag={{repo}}/{{project}}:latest .

push: container
    podman push {{repo}}/{{project}}:latest

_tempdirs:
    mkdir -p output
    mkdir -p cache/rpmmd

image type: container _tempdirs
    podman save {{repo}}/{{project}}:latest > "output/{{project}}-image.tar"
    sudo podman load < "output/{{project}}-image.tar"
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
        -v $(pwd)/cache/store:/store \
        -v $(pwd)/cache/rpmmd:/rpmmd \
        -v /var/lib/containers/storage:/var/lib/containers/storage \
        quay.io/centos-bootc/bootc-image-builder:latest \
        {{repo}}/{{project}}:latest \
        --type {{type}} \
        --rootfs xfs \
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
