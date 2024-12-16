[.enthalpy_public_key_pem as $keys | .hosts as $hosts | .enthalpy_organizations | to_entries[] as $org | {
  "public_key": $keys[$org.key],
  "organization": $org.value,
  "nodes": [$hosts | to_entries[] | select(.value.enthalpy_node_organization == $org.value) | {
    "common_name": .key,
    "endpoints": [
      {
        "serial_number": "0",
        "address_family": "ip4",
        "address": "\(.key)\(if .value.endpoints_v4 == [] then ".dyn" else "" end).rebmit.link",
        "port": 13000
      },
      {
        "serial_number": "1",
        "address_family": "ip6",
        "address": "\(.key)\(if .value.endpoints_v6 == [] then ".dyn" else "" end).rebmit.link",
        "port": 13000
      }
    ],
  }]
}]
