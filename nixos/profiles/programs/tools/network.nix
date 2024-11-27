{ pkgs, ... }:
{
  programs = {
    mtr.enable = true;
  };

  environment.systemPackages = with pkgs; [
    # keep-sorted start
    aria2
    curl
    dnsutils
    ethtool
    ipcalc
    iperf3
    nmap
    rsync
    socat
    tcpdump
    wget
    # keep-sorted end
  ];
}
