module RobotWars
  # Opens a URL in the user's default web browser through the platform's
  # own launcher: `open` on macOS, `start` on Windows, `xdg-open` on
  # Linux and everything else.
  #
  # Everything platform-touching is injectable so tests never open a
  # window: `platform` is an OS name string (RbConfig's host_os by
  # default) and `runner` answers `#call(*argv)` with `Kernel#system`
  # semantics.
  class BrowserOpener
    # :reek:ControlParameter -- `runner || method(:system)` is an injectable-collaborator fallback, not behavior selection.
    def initialize(platform: RbConfig::CONFIG["host_os"], runner: nil)
      @platform = platform
      @runner = runner || method(:system)
    end

    # Launch the browser at the given URL.
    #
    # @param url [String] the address to open
    # @return [Boolean, nil] whether the launcher command succeeded; nil
    #   when the launcher itself is missing
    def call(url)
      @runner.call(*command(url))
    end

    # The argv this platform opens URLs with.
    #
    # @param url [String] the address to open
    # @return [Array<String>]
    def command(url)
      case @platform
      # `start` is a cmd.exe built-in whose first quoted argument is a
      # window title, so the empty string keeps the URL out of that slot.
      when /darwin|mac/i then ["open", url]
      when /mswin|mingw|cygwin|windows/i then ["cmd", "/c", "start", "", url]
      else ["xdg-open", url]
      end
    end
  end
end
