{ unstable, ... }: {
  programs.claude-code = {
    enable = true;
    package = unstable.claude-code;
    settings = {
      theme = "dark";
      model = "opus";
      spinnerVerbs = {
        mode = "replace";
        verbs = [
          "Burning down old-growth forest"
          "10x-ing carbon emissions"
          "Searching through stolen intellectual property database"
          "Wasting millions of gallons of fresh water"
          "Destroying the local economy of vulnerable rural towns"
          "Harvesting the hard work of others"
          "I have no mouth and I must scream"
        ];
      };
      sandbox = {
        filesystem = {
          disabled = true;
        };
      };
      enabledPlugins = {
        "gopls-lsp@claude-plugins-official" = true;
      };
      permissions = {
        disableAutoMode = "disable";
        allow = [
          "Bash(git diff:*)"
        ];
        deny = [
          "WebFetch"
          "Read(./.env)"
        ];
      };
      hooks = {
        PostToolUse = [
          {
            hooks = [
              {
                command = "[ -n \"$NVIM\" ] && nvim --server $NVIM --remote-expr 'execute(\"checktime\")'";
                type = "command";
              }
            ];
            matcher = "Edit|MultiEdit|Write";
          }
        ];
      };
    };
  };
}
