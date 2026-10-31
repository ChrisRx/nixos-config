{ pkgs, ... }: {
  # Renders images through the kitty graphics protocol (ghostty speaks it):
  # `:e foo.png` shows the image, and markdown images preview inline. Inside
  # tmux this needs allow-passthrough (see ../../home/programs/tmux.nix).
  # snacks itself is enabled in ./claude.nix.
  plugins.snacks.settings.image.enabled = true;

  # snacks only decodes PNG itself; ImageMagick converts JPG, GIF, WebP, PDF etc.
  extraPackages = [ pkgs.imagemagick ];

  autoCmd = [
    {
      # An image buffer leaving its last window makes snacks hide the placement,
      # and nothing un-hides it for a whole-buffer image (only the markdown and
      # inline paths call show()), so switching back left it blank. Still the
      # case on snacks main as of 2026-10-31. Re-attaching builds a fresh
      # placement; the converted image is cached, so this is cheap.
      event = [
        "BufWinLeave"
        "BufWinEnter"
      ];
      desc = "Redraw snacks images when their buffer is shown again";
      callback.__raw = ''
        function(ev)
          if vim.bo[ev.buf].filetype ~= "image" then
            return
          end
          if ev.event == "BufWinLeave" then
            vim.b[ev.buf].snacks_image_left = true
          elseif vim.b[ev.buf].snacks_image_left then
            vim.b[ev.buf].snacks_image_left = nil
            vim.schedule(function()
              Snacks.image.buf.attach(ev.buf)
            end)
          end
        end
      '';
    }
    {
      # snacks makes image buffers non-modifiable, but that does not stop the
      # 'modified' flag itself being set, which then blocks :q. The buffer is
      # never written back to the image anyway, so clear it.
      event = [ "BufModifiedSet" ];
      desc = "Keep snacks image buffers unmodified";
      callback.__raw = ''
        function(ev)
          if vim.bo[ev.buf].filetype == "image" and vim.bo[ev.buf].modified then
            vim.bo[ev.buf].modified = false
          end
        end
      '';
    }
  ];
}
