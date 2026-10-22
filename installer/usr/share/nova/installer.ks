# The payload is embedded by image-builder. No network source is used for installation.
bootc --source-imgref containers-storage:localhost/nova:@VERSION@ --target-imgref ghcr.io/dennics/nova-os:0.2.1-preview
rootpw --lock
firstboot --disable

