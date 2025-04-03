{ pkgs, ... }:
{
  programs = {
    mtr.enable = true;
  };

  environment.systemPackages = with pkgs; [
    # keep-sorted start
    aria2
    curlHTTP3
    dnsutils
    ethtool
    ipcalc
    iperf3
    knot-dns
    nmap
    rsync
    socat
    tcpdump
    wget
    whois
    # keep-sorted end
  ];
}
