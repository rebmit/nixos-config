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
    knot-dns
    netcat
    nmap
    rsync
    socat
    tcpdump
    wget
    whois
    # keep-sorted end
  ];
}
