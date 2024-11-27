{ ... }:
{
  users.users.root = {
    openssh.authorizedKeys.keyFiles = [
      ./_ssh/marisa-7d76
      ./_ssh/marisa-a7s
    ];
  };
}
