[.hosts as $hosts | .enthalpy | to_entries[] as $org | {
  "public_key": $org.value.public_key_pem,
  "organization": $org.key,
  "nodes": [$org.value.nodes | to_entries[] | {
    "common_name": .value,
    "endpoints": [
      {
        "serial_number": "0",
        "address_family": "ip4",
        "address": "\(.value)\(if $hosts[.value].endpoints == [] then ".dyn" else "" end).rebmit.link",
        "port": 14000
      },
      {
        "serial_number": "1",
        "address_family": "ip6",
        "address": "\(.value)\(if $hosts[.value].endpoints == [] then ".dyn" else "" end).rebmit.link",
        "port": 14000
      }
    ],
  }]
}]
