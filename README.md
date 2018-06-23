# nixos-configs

My Config Files For Various NixOS Deployments

## Pull bootstrap.sh & Run Script

```bash
curl -OLk https://gitlab.com/Wolfereign/nixos-configs/-/archive/master/nixos-configs-master.tar.gz
tar -zxvf nixos-configs-master.tar.gz
bash nixos-configs-master/bootstrap.sh
```

or 

```bash
curl -Lk nixos-configs-tarball.wolfereign.com -o taball.tar.gz
tar -zxvf tarball.tar.gz
bash nixos-configs-master/bootstrap.sh
```

## To-Do

- Finish Home Workstation (Zaku) Configuration
- Finish Home Server (Portland) Configuration
- Finish Firewall/Router (Shuttle DS81) Configuration
- Figure Out Better Generic User Dotfile Management
