let
  data = builtins.fromJSON (builtins.readFile ./data.json);
  inherit (data.nameservers) primary;
in
{
  TTL = 300;
  SOA = {
    nameServer = "${primary}.rebmit.link.";
    adminEmail = "noc@rebmit.moe";
    serial = 0;
    refresh = 14400;
    retry = 3600;
    expire = 604800;
    minimum = 300;
  };
  NS = [
    "reisen.any.rebmit.link."
    "ns1.he.net."
    "ns2.he.net."
    "ns3.he.net."
    "ns4.he.net."
    "suwako-vie1.rebmit.link."
  ];
  DKIM = [
    {
      selector = "20241219";
      k = "rsa";
      p = "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAtLyv0K6sJv2aybXJAtmHyEEGdbTl58iTODDBAePKo10WI4B342QgfS0GWz7PmX/R/v0SK3fnpbG+VS9ZX8YTIEa0CZvnn9F7TcaIb8B6UkiELW9RAlDc8oNTk32EeTw/DZNATDXU1uin7Thea80YgXbbmB2X2HXZVw589YWbSfa9buHCEvxzx/ilIaQO2kf7/V9E9jcC/Ey0qQ7HF8Iyd3w9jKPaY0larzOrarkHGEmSxFPWBvZNlHOHa0cFW3HLT3cg5EzDwHrdcnqQmgHGbZWMMp1krEwPgTpbwYIQYuhADoNJSH6CktAc45wjFrzHQBAUY52YTR+ZjppWroTPcQIDAQAB";
      s = [ "email" ];
    }
  ];
  DMARC = [
    {
      p = "reject";
      sp = "reject";
      pct = 100;
      adkim = "strict";
      aspf = "strict";
      fo = [ "1" ];
      ri = 604800;
    }
  ];
  CAA = [
    {
      issuerCritical = false;
      tag = "issue";
      value = "letsencrypt.org";
    }
  ];

  hosts = data.hosts;
}
