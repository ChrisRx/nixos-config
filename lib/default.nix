{
  lib,
  inputs,
  username,
}:
{
  hostname = (builtins.replaceStrings [ "\n" ] [ "" ] (builtins.readFile /etc/hostname));
}
