# Migration Log with Narrative: Moving bitcoind-testnet to External 128 GB Drive

We needed to move the testnet node from the NVMe SSD (/dev/nvme0n1p2) to a smaller external USB drive (/dev/sda1, 128GB). 
The NVMe was running low on space (~12-13% free), and both mainnet and testnet data were competing for capacity. 
This caused bitcoind to shut down when it detected insufficient disk space. The goal was to migrate testnet to USB while 
keeping mainnet on NVMe.

---

## 1. Partition and Format the USB Drive
We wiped the USB stick, created a new GPT partition table, and formatted it as ext4.

```
sudo parted -s /dev/sda mklabel gpt
sudo parted -s -a optimal /dev/sda mkpart primary ext4 1MiB 100%
sudo partprobe /dev/sda
sudo udevadm settle
sudo mkfs.ext4 -L TESTNETDISK /dev/sda1
sudo mkdir -p /mnt/testnetdisk
sudo mount -o noatime /dev/sda1 /mnt/testnetdisk
df -h /mnt/testnetdisk
```

- `mklabel gpt` and `mkpart` created a single full-disk partition.  
- `mkfs.ext4` created the filesystem with a label `TESTNETDISK`.  
- `noatime` prevents excessive write amplification on flash media.  
- Verified ~113 GB available on `/mnt/testnetdisk`.

---

## 2. Stop the Testnet Service
We needed to stop the systemd unit before moving data.

```
sudo systemctl stop bitcoind-testnet
```

---

## 3. Move Testnet Data
The real datadir was `/srv/bitcoin-testnet`.  
We moved it to the USB stick with rsync, using `--remove-source-files` to avoid duplicating and filling up NVMe.

```
sudo mkdir -p /mnt/testnetdisk/bitcoin-testnet
sudo rsync -aHAX --info=progress2 --remove-source-files /srv/bitcoin-testnet/ /mnt/testnetdisk/bitcoin-testnet/
sudo find /srv/bitcoin-testnet -type d -empty -delete
sudo chown -R bitcoin:bitcoin /mnt/testnetdisk/bitcoin-testnet
```

- `-aHAX` preserved permissions, symlinks, extended attributes.  
- `--remove-source-files` ensured files were deleted from NVMe as they were copied, freeing space incrementally.  
- Final ownership reset for the `bitcoin` user.  

---

## 4. Update systemd Service to Point to USB
We edited the systemd unit so `bitcoind-testnet` uses the new path.

```
sudo sed -i 's#/srv/bitcoin-testnet#/mnt/testnetdisk/bitcoin-testnet#g' /etc/systemd/system/bitcoind-testnet.service
sudo systemctl daemon-reload
sudo systemctl start bitcoind-testnet
sudo systemctl status bitcoind-testnet
```

- Verified the process was running and using `/mnt/testnetdisk/bitcoin-testnet` as datadir.

---

## 5. Verify
```
journalctl -u bitcoind-testnet -n 50 | grep "Using data directory"
df -h /mnt/testnetdisk
df -h /
```

- Confirmed the service logs referenced the USB-mounted datadir.  
- `df -h` showed ~6 GB used on USB and ~118 GB free on NVMe.  

---

## 6. Make Mount Persistent
We needed the USB to mount automatically on reboot.

```
blkid /dev/sda1
sudo nano /etc/fstab
# Add line:
# UUID=<your-uuid-here>  /mnt/testnetdisk  ext4  defaults,noatime  0  2
sudo umount /mnt/testnetdisk
sudo mount -a
df -h /mnt/testnetdisk
```

- Used UUID for stability instead of /dev/sda1, which can change between boots.  
- Tested by unmounting and remounting with `mount -a`.  

---

## 7. Clean Old Testnet Data
Finally, removed the old directory from NVMe to reclaim space.

```
sudo du -sh /srv/bitcoin-testnet
sudo rm -rf /srv/bitcoin-testnet
df -h /
```

---

## Challenges and Lessons Learned
1. **Disk space constraints**: With only ~13% free, Bitcoin Core shut down to protect from corruption.  
2. **Corrupted settings.json**: Low disk space caused a partial write, leaving invalid JSON that prevented startup. Deleting it resolved the issue.  
3. **Identifying correct datadir**: Testnet was not under `~/.bitcoin/testnet4`, but at `/srv/bitcoin-testnet`. Finding it required searching systemd unit definitions.  
4. **Copy without duplication**: Using rsync with `--remove-source-files` avoided temporarily needing double storage.  
5. **Persistence**: Ensuring `/etc/fstab` uses UUID prevents issues after reboot when device names may change.  

---

## Outcome
- Testnet now runs from the 128 GB USB drive.  
- NVMe SSD has more headroom (~118 GB free).  
- Mainnet continues on NVMe, stable.  
- Setup is resilient to reboots with persistent mount.  
