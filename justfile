project := "dl-client-appliance"
repo := "ghcr.io/jdmarble"

container:
    podman build --tag={{repo}}/{{project}}:latest .

push: container
    podman push {{repo}}/{{project}}:latest

_tempdirs:
    mkdir -p output
    mkdir -p cache/rpmmd
    mkdir -p cache/store

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
        -v $(pwd)/config.toml:/config.toml:ro,z \
        -v $(pwd)/output:/output:z \
        -v $(pwd)/cache/store:/store:z \
        -v $(pwd)/cache/rpmmd:/rpmmd:z \
        -v /var/lib/containers/storage:/var/lib/containers/storage:z \
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
        -netdev user,id=net0,hostfwd=tcp::9090-:9090,hostname=vm \
        -nographic \
        -snapshot output/qcow2/disk.qcow2
