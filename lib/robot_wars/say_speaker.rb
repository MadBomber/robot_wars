module RobotWars
  # Speaks text aloud through a command-line text-to-speech program —
  # macOS's `say` by default. The command runs to completion before
  # returning, so consecutive announcements never talk over each other.
  # `runner` is anything answering `#call(*argv)` with `Kernel#system`
  # semantics; injectable so tests never make a sound.
  class SaySpeaker
    def initialize(command: "say", runner: nil)
      @command = command
      @runner = runner || ->(*argv) { system(*argv) }
    end

    # Speak the given text and wait for it to finish.
    #
    # @param text [String] the words to speak
    # @return [Boolean] whether the speech command succeeded
    def call(text)
      @runner.call(@command, text)
    end
  end
end
