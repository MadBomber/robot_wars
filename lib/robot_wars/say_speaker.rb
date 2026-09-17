module RobotWars
  # Speaks text aloud through the platform's command-line text-to-speech:
  # `say` on macOS, PowerShell's System.Speech synthesizer on Windows,
  # and the first available of spd-say / espeak-ng / espeak on Linux and
  # everything else. The command runs to completion before returning, so
  # consecutive announcements never talk over each other.
  #
  # Everything platform-touching is injectable so tests never make a
  # sound: `platform` is an OS name string (RbConfig's host_os by
  # default), `runner` answers `#call(*argv)` with `Kernel#system`
  # semantics, and `finder` answers `#call(command)` truthy when that
  # command is installed.
  class SaySpeaker
    LINUX_ENGINES = %w[spd-say espeak-ng espeak].freeze

    def initialize(platform: RbConfig::CONFIG["host_os"], engines: LINUX_ENGINES, runner: nil, finder: nil)
      @platform = platform
      @engines = engines
      @runner = runner || ->(*argv) { system(*argv) }
      @finder = finder || ->(command) { system("which", command, out: File::NULL, err: File::NULL) }
    end

    # Speak the given text and wait for it to finish.
    #
    # @param text [String] the words to speak
    # @return [Boolean] whether the speech command succeeded; false when
    #   the platform has no text-to-speech engine installed
    def call(text)
      argv = command(text)
      return false unless argv

      @runner.call(*argv)
    end

    # The argv this platform speaks with.
    #
    # @param text [String] the words to speak
    # @return [Array<String>, nil] nil when no engine is available
    def command(text)
      case @platform
      when /darwin|mac/i then ["say", text]
      when /mswin|mingw|cygwin|windows/i then windows_command(text)
      else linux_command(text)
      end
    end

    private

    # System.Speech ships with Windows PowerShell; the text rides inside
    # a single-quoted PowerShell string, where doubling is the only
    # escape needed.
    def windows_command(text)
      script = "Add-Type -AssemblyName System.Speech; " \
               "(New-Object System.Speech.Synthesis.SpeechSynthesizer).Speak('#{text.gsub("'", "''")}')"
      ["powershell", "-NoProfile", "-Command", script]
    end

    def linux_command(text)
      engine = linux_engine
      engine && [engine, text]
    end

    # Which engine to use is decided once per speaker, not per line —
    # `which` is a process spawn, and a match's worth of announcements
    # all use the same engine anyway.
    def linux_engine
      return @linux_engine if defined?(@linux_engine)

      @linux_engine = @engines.find { |command| @finder.call(command) }
      warn "SaySpeaker: no text-to-speech engine found (tried #{@engines.join(', ')})" unless @linux_engine
      @linux_engine
    end
  end
end
