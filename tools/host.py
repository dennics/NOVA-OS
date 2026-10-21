"""Local, isolated QEMU builder for NOVA. Uses only the Python standard library."""
from __future__ import annotations

import argparse
import base64
import functools
import http.server
import json
import os
from pathlib import Path
import shutil
import socket
import subprocess
import sys
import tarfile
import time

for output in (sys.stdout, sys.stderr):
    if hasattr(output, "reconfigure"):
        output.reconfigure(encoding="utf-8", errors="replace")

PROJECT = Path(__file__).resolve().parents[1]
WORKSPACE = PROJECT.parent.parent
STATE = WORKSPACE / "work"
VM = STATE / "vm"
QEMU = STATE / "tools" / "qemu"
SSH = Path(os.environ.get("WINDIR", "C:/Windows")) / "System32/OpenSSH/ssh.exe"
KEY = VM / "builder_ed25519"
SSH_OPTIONS = ["-i", str(KEY), "-p", "2222", "-o", "BatchMode=yes",
               "-o", "ConnectTimeout=8", "-o", "StrictHostKeyChecking=accept-new",
               "-o", f"UserKnownHostsFile={VM / 'known_hosts'}"]


def run(args: list[str], **kwargs):
    return subprocess.run([str(arg) for arg in args], check=True, **kwargs)


def configure():
    VM.mkdir(parents=True, exist_ok=True)
    seed = VM / "seed"
    seed.mkdir(exist_ok=True)
    if not KEY.exists():
        run([str(SSH.parent / "ssh-keygen.exe"), "-q", "-t", "ed25519", "-N", "", "-f", str(KEY)])
    public_key = KEY.with_suffix(".pub").read_text().strip()
    (seed / "meta-data").write_text("instance-id: nova-builder-01\nlocal-hostname: nova-builder\n", encoding="utf-8")
    (seed / "user-data").write_text(
        "#cloud-config\nusers:\n  - name: builder\n    groups: [wheel]\n"
        "    shell: /bin/bash\n    lock_passwd: true\n"
        "    sudo: ['ALL=(ALL) NOPASSWD:ALL']\n    ssh_authorized_keys:\n"
        f"      - {public_key}\nssh_pwauth: false\ndisable_root: true\n"
        "growpart:\n  mode: auto\n  devices: ['/']\nresize_rootfs: true\n"
        "runcmd:\n  - [systemctl, enable, --now, sshd]\n",
        encoding="utf-8")
    disk = VM / "builder.qcow2"
    if not disk.exists():
        base = STATE / "downloads/Fedora-Cloud-Base-Generic-44-1.7.x86_64.qcow2"
        run([str(QEMU / "qemu-img.exe"), "create", "-f", "qcow2", "-F", "qcow2", "-b", str(base), str(disk), "100G"])
    return disk


def serve():
    handler = functools.partial(http.server.SimpleHTTPRequestHandler, directory=str(VM / "seed"))
    server = http.server.ThreadingHTTPServer(("127.0.0.1", 8791), handler)
    server.serve_forever()


def port_open(port: int) -> bool:
    try:
        with socket.create_connection(("127.0.0.1", port), timeout=1):
            return True
    except OSError:
        return False


def machine_type(accel: str, whpx_irqchip_off: bool = False) -> str:
    if whpx_irqchip_off and accel != "whpx":
        raise SystemExit("--whpx-irqchip-off requires --accel whpx.")
    return "q35,kernel-irqchip=off" if whpx_irqchip_off else "q35"


def start(accel: str, whpx_irqchip_off: bool = False, memory_mib: int = 8192):
    if memory_mib < 4096 or memory_mib > 8192:
        raise SystemExit("Builder memory must be between 4096 and 8192 MiB.")
    machine = machine_type(accel, whpx_irqchip_off)
    if port_open(4445):
        raise SystemExit("Shut down the test VM first: the two 8 GB guests must run one at a time.")
    if port_open(2222):
        raise SystemExit("Port 2222 is already in use; refusing to start a second builder.")
    disk = configure()
    nvram = VM / "builder-vars.fd"
    if not nvram.exists():
        shutil.copyfile(QEMU / "share/edk2-i386-vars.fd", nvram)
    creation = subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0
    seed_log = (VM / "seed-server.log").open("ab")
    if not port_open(8791):
        seed_process = subprocess.Popen([sys.executable, str(Path(__file__).resolve()), "serve"],
                                        stdin=subprocess.DEVNULL, stdout=seed_log, stderr=seed_log,
                                        creationflags=creation)
        (VM / "seed.pid").write_text(str(seed_process.pid))
    args = [str(QEMU / "qemu-system-x86_64.exe"), "-name", "NOVA-Builder",
            "-machine", machine, "-accel", "tcg,thread=multi" if accel == "tcg" else "whpx",
            "-cpu", "max", "-smp", "4", "-m", str(memory_mib),
            "-drive", f"if=pflash,format=raw,unit=0,readonly=on,file={QEMU / 'share/edk2-x86_64-code.fd'}",
            "-drive", f"if=pflash,format=raw,unit=1,file={nvram}",
            "-drive", f"file={disk},format=qcow2,if=virtio",
            "-netdev", "user,id=network,hostfwd=tcp:127.0.0.1:2222-:22",
            "-device", "virtio-net-pci,netdev=network",
            "-smbios", "type=1,serial=ds=nocloud-net;s=http://10.0.2.2:8791/",
            "-display", "none", "-serial", f"file:{VM / 'builder-serial.log'}",
            "-qmp", "tcp:127.0.0.1:4444,server=on,wait=off"]
    log = (VM / "builder-qemu.log").open("wb")
    process = subprocess.Popen(args, stdin=subprocess.DEVNULL, stdout=log, stderr=log, creationflags=creation)
    (VM / "builder.pid").write_text(str(process.pid))
    (VM / "builder-command.json").write_text(json.dumps(args, indent=2))
    time.sleep(2)
    if process.poll() is not None:
        raise SystemExit((VM / "builder-qemu.log").read_text(errors="replace"))
    print(json.dumps({"pid": process.pid, "accelerator": accel, "memory_mib": memory_mib,
                      "whpx_irqchip_off": whpx_irqchip_off,
                      "ssh": "127.0.0.1:2222", "disk": str(disk)}))


def ssh(command: str):
    return subprocess.call([str(SSH), *SSH_OPTIONS, "builder@127.0.0.1", command])


def sync(destination="image"):
    archive = STATE / "nova-source.tar.gz"
    with tarfile.open(archive, "w:gz") as output:
        for path in sorted(PROJECT.rglob("*")):
            relative = path.relative_to(PROJECT)
            if any(part in {".git", "build", "artifacts", "__pycache__", ".local"} for part in relative.parts):
                continue
            if not path.is_file():
                continue
            info = output.gettarinfo(str(path), arcname=str(relative).replace("\\", "/"))
            info.mode = 0o755 if path.suffix == ".sh" or path.name == "nova-install" else 0o644
            with path.open("rb") as source:
                output.addfile(info, source)
    options = ["-i", str(KEY), "-P", "2222", "-o", "BatchMode=yes",
               "-o", "StrictHostKeyChecking=accept-new", "-o", f"UserKnownHostsFile={VM / 'known_hosts'}"]
    run([str(SSH.parent / "scp.exe"), *options, str(archive), "builder@127.0.0.1:/tmp/nova-source.tar.gz"])
    target = "/home/builder/nova-dev" if destination == "app" else "/home/builder/nova"
    result = ssh(f"mkdir -p {target} && tar -xzf /tmp/nova-source.tar.gz -C {target}")
    if result:
        raise SystemExit(result)
    print(f"NOVA source synchronized to {target}")


def fetch(destination="image"):
    target = PROJECT / "artifacts"
    target.mkdir(exist_ok=True)
    options = ["-i", str(KEY), "-P", "2222", "-o", "BatchMode=yes",
               "-o", "StrictHostKeyChecking=accept-new", "-o", f"UserKnownHostsFile={VM / 'known_hosts'}"]
    if destination == "app":
        run([str(SSH.parent / "scp.exe"), *options, "-r", "builder@127.0.0.1:/home/builder/nova-dev/artifacts/native", str(target)])
    else:
        for name in ["NOVA-OS-0.2-Preview-x86_64.iso", "NOVA-OS-0.2-Preview-x86_64.iso.sha256", "sources.lock.json", "packages.txt", "runtime-inspect.json", "build-manifest.json", "native-tests.log", "nova-live.osbuild-manifest.json"]:
            run([str(SSH.parent / "scp.exe"), *options, f"builder@127.0.0.1:/home/builder/nova/artifacts/{name}", str(target / name)])
    print(str(target))


def qmp(command: str):
    with socket.create_connection(("127.0.0.1", 4444), timeout=5) as connection:
        connection.settimeout(5)
        stream = connection.makefile("rwb")
        stream.readline()
        for request in ["qmp_capabilities", command]:
            stream.write((json.dumps({"execute": request}) + "\n").encode())
            stream.flush()
            while True:
                response = json.loads(stream.readline())
                if "return" in response or "error" in response:
                    print(json.dumps(response))
                    break


def monitor_request(port: int, command: str, arguments=None, capabilities=False):
    with socket.create_connection(("127.0.0.1", port), timeout=10) as connection:
        connection.settimeout(15)
        stream = connection.makefile("rwb")
        if capabilities:
            stream.readline()
            stream.write(b'{"execute":"qmp_capabilities"}\n')
            stream.flush()
            while "return" not in json.loads(stream.readline()):
                pass
        elif port == 4446:
            token = time.time_ns() % (1 << 53)
            sync_request = {"execute": "guest-sync-delimited", "arguments": {"id": token}}
            stream.write(b"\xff" + (json.dumps(sync_request) + "\n").encode())
            stream.flush()
            while True:
                raw = stream.readline()
                if not raw:
                    raise RuntimeError("Guest agent closed the synchronization connection")
                try:
                    response = json.loads(raw.lstrip(b"\xff"))
                except (ValueError, UnicodeDecodeError):
                    continue
                if response.get("return") == token:
                    break
        request = {"execute": command}
        if arguments is not None:
            request["arguments"] = arguments
        stream.write((json.dumps(request) + "\n").encode())
        stream.flush()
        while True:
            raw = stream.readline()
            if not raw:
                raise RuntimeError("Guest connection closed before returning a response")
            response = json.loads(raw.lstrip(b"\xff"))
            if "error" in response:
                raise RuntimeError(json.dumps(response["error"]))
            if "return" in response:
                return response["return"]


def start_test(iso_path: str | None, disk_name: str, display: str, resolution: str, accel: str,
               data_iso_path: str | None = None, whpx_irqchip_off: bool = False, vcpus: int = 4,
               memory_mib: int = 8192):
    if vcpus not in {1, 2, 4}:
        raise SystemExit("Test VM --vcpus must be 1, 2, or 4.")
    if memory_mib < 4096 or memory_mib > 8192:
        raise SystemExit("Test VM memory must be between 4096 and 8192 MiB.")
    machine = machine_type(accel, whpx_irqchip_off)
    if port_open(4444):
        raise SystemExit("Shut down the builder first: the two 8 GB guests must run one at a time.")
    if port_open(4445):
        raise SystemExit("A test VM is already running.")
    iso_files = []
    for option, path in [("--iso", iso_path), ("--data-iso", data_iso_path)]:
        if path is None:
            iso_files.append(None)
            continue
        try:
            iso_file = Path(path).resolve(strict=True)
        except (OSError, RuntimeError) as error:
            raise SystemExit(f"{option} requires an existing .iso file: {path}") from error
        if not iso_file.is_file() or iso_file.suffix.lower() != ".iso":
            raise SystemExit(f"{option} requires an existing .iso file: {path}")
        iso_files.append(iso_file)
    iso, data_iso = iso_files
    disk = VM / f"{disk_name}.qcow2"
    if not disk.exists():
        if not iso_path:
            raise SystemExit("No installed test disk exists. Start with an ISO first.")
        run([str(QEMU / "qemu-img.exe"), "create", "-f", "qcow2", str(disk), "48G"])
    nvram = VM / f"{disk_name}-vars.fd"
    if not nvram.exists():
        shutil.copyfile(QEMU / "share/edk2-i386-vars.fd", nvram)
    width, height = resolution.split("x")
    args = [str(QEMU / "qemu-system-x86_64.exe"), "-name", "NOVA-Test",
            "-machine", machine, "-accel", "tcg,thread=multi" if accel == "tcg" else "whpx",
            "-cpu", "max", "-smp", str(vcpus), "-m", str(memory_mib),
            "-drive", f"if=pflash,format=raw,unit=0,readonly=on,file={QEMU / 'share/edk2-x86_64-code.fd'}",
            "-drive", f"if=pflash,format=raw,unit=1,file={nvram}",
            "-drive", f"file={disk},format=qcow2,if=virtio", "-nic", "none",
            "-vga", "none", "-device", f"virtio-vga,xres={width},yres={height}", "-display", display,
            "-device", "qemu-xhci", "-device", "usb-tablet",
            "-device", "virtio-serial-pci", "-chardev", "socket,id=qga,host=127.0.0.1,port=4446,server=on,wait=off",
            "-device", "virtserialport,chardev=qga,name=org.qemu.guest_agent.0",
            "-serial", f"file:{VM / 'test-serial.log'}",
            "-qmp", "tcp:127.0.0.1:4445,server=on,wait=off"]
    if iso:
        args += ["-cdrom", str(iso), "-boot", "once=d"]
    if data_iso:
        filename = str(data_iso).replace(",", ",,")
        args += ["-drive", f"file={filename},if=none,id=nova-data,format=raw,media=cdrom,readonly=on",
                 "-device", "virtio-scsi-pci,id=nova-data-scsi",
                 "-device", "scsi-cd,drive=nova-data,bus=nova-data-scsi.0,bootindex=-1"]
    creation = subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0
    with (VM / "test-qemu.log").open("wb") as log:
        process = subprocess.Popen(args, stdin=subprocess.DEVNULL, stdout=log, stderr=log, creationflags=creation)
    (VM / "test.pid").write_text(str(process.pid))
    (VM / "test-command.json").write_text(json.dumps(args, indent=2))
    time.sleep(2)
    if process.poll() is not None:
        raise SystemExit((VM / "test-qemu.log").read_text(errors="replace"))
    print(json.dumps({"pid": process.pid, "accelerator": accel, "memory_mib": memory_mib,
                      "whpx_irqchip_off": whpx_irqchip_off,
                      "vcpus": vcpus, "offline": True, "iso": iso_path,
                      "data_iso": data_iso_path, "disk": str(disk)}))


def guest_exec(command: str):
    result = monitor_request(4446, "guest-exec", {"path": "/bin/bash", "arg": ["-lc", command], "capture-output": True})
    pid = result["pid"]
    deadline = time.monotonic() + 15
    while time.monotonic() < deadline:
        status = monitor_request(4446, "guest-exec-status", {"pid": pid})
        if status.get("exited"):
            for name, output in [("out-data", sys.stdout), ("err-data", sys.stderr)]:
                if status.get(name):
                    output.write(base64.b64decode(status[name]).decode("utf-8", errors="replace"))
            raise SystemExit(status.get("exitcode", 1))
        time.sleep(0.5)
    print(json.dumps({"pid": pid, "state": "running", "note": "Query guest-exec-status using this PID"}))


def guest_status(pid: int):
    status = monitor_request(4446, "guest-exec-status", {"pid": pid})
    if not status.get("exited"):
        print(json.dumps({"pid": pid, "state": "running"}))
        return
    for name, output in [("out-data", sys.stdout), ("err-data", sys.stderr)]:
        if status.get(name):
            output.write(base64.b64decode(status[name]).decode("utf-8", errors="replace"))
    raise SystemExit(status.get("exitcode", 1))


def screenshot():
    destination = PROJECT / "artifacts/screenshots"
    destination.mkdir(parents=True, exist_ok=True)
    ppm = destination / f"nova-{int(time.time())}.ppm"
    monitor_request(4445, "screendump", {"filename": str(ppm)}, capabilities=True)
    try:
        from PIL import Image
        png = ppm.with_suffix(".png")
        with Image.open(ppm) as capture:
            capture.save(png)
        ppm.unlink()
        print(str(png))
    except ImportError:
        print(str(ppm))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("action", choices=["start", "serve", "ssh", "sync", "fetch", "status", "poweroff", "stop", "start-test", "guest", "guest-status", "screenshot", "test-poweroff", "test-monitor"])
    parser.add_argument("--accel", choices=["whpx", "tcg"], default="whpx")
    parser.add_argument("--whpx-irqchip-off", action="store_true",
                        help="Optional WHPX reset diagnostic: disable in-kernel IRQ chip for start/start-test")
    parser.add_argument("--memory-mib", type=int, default=8192,
                        help="Builder or test VM RAM in MiB (4096-8192; default: 8192)")
    parser.add_argument("--command", default="uname -a")
    parser.add_argument("--iso")
    parser.add_argument("--data-iso", help="Additional read-only data ISO for offline update testing")
    parser.add_argument("--display", choices=["none", "sdl"], default="none")
    parser.add_argument("--disk-name", choices=["test", "test-encrypted", "baseline"], default="test")
    parser.add_argument("--resolution", choices=["1280x720", "1920x1080"], default="1280x720")
    parser.add_argument("--vcpus", type=int, choices=[1, 2, 4], default=4,
                        help="Virtual CPU count for start-test only (default: 4; builder always uses 4)")
    parser.add_argument("--request", help="JSON QMP request file for the local test VM")
    parser.add_argument("--pid", type=int, help="Process ID returned by the guest agent")
    parser.add_argument("--destination", choices=["image", "app"], default="image")
    args = parser.parse_args()
    if args.whpx_irqchip_off and (args.accel != "whpx" or args.action not in {"start", "start-test"}):
        parser.error("--whpx-irqchip-off requires start/start-test with --accel whpx")
    if args.action == "start":
        start(args.accel, args.whpx_irqchip_off, args.memory_mib)
    elif args.action == "serve":
        serve()
    elif args.action == "ssh":
        raise SystemExit(ssh(args.command))
    elif args.action == "sync":
        sync(args.destination)
    elif args.action == "fetch":
        fetch(args.destination)
    elif args.action == "start-test":
        start_test(args.iso, args.disk_name, args.display, args.resolution, args.accel,
                   args.data_iso, args.whpx_irqchip_off, args.vcpus, args.memory_mib)
    elif args.action == "test-monitor":
        if not args.request:
            parser.error("test-monitor requires --request")
        request = json.loads(Path(args.request).read_text())
        print(json.dumps(monitor_request(4445, request["execute"], request.get("arguments"), capabilities=True)))
    elif args.action == "guest":
        guest_exec(args.command)
    elif args.action == "guest-status":
        if args.pid is None:
            parser.error("guest-status requires --pid")
        guest_status(args.pid)
    elif args.action == "screenshot":
        screenshot()
    elif args.action == "test-poweroff":
        print(json.dumps(monitor_request(4445, "system_powerdown", capabilities=True)))
    elif args.action == "status":
        print(json.dumps({"ssh_port_open": port_open(2222), "qmp_port_open": port_open(4444), "seed_server": port_open(8791)}))
    elif args.action == "poweroff":
        qmp("system_powerdown")
    elif args.action == "stop":
        qmp("quit")


if __name__ == "__main__":
    main()
