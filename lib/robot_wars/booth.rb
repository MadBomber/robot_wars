module RobotWars
  # Runs an announcer on its own thread so the match never waits for
  # the booth: #announce enqueues and returns at once, while a single
  # worker drains the queue — one announcer call at a time, so
  # commentary never talks over itself and the announcer's chat history
  # stays in order.
  #
  # When the booth falls behind the action, it catches up the way a
  # real announcer does: on finishing a call it takes EVERYTHING queued
  # since as one batch, letting the persona summarize several turns in
  # a single breath instead of narrating ever-older history.
  #
  # A failed announcement (a hiccuping LLM or speaker) is warned about
  # and dropped — the booth going quiet must never end the match.
  class Booth
    def initialize(announcer:)
      @announcer = announcer
      @pending = []
      @closed = false
      @enqueued = 0
      @delivered = 0
      @mutex = Mutex.new
      @ready = ConditionVariable.new
      @idle = ConditionVariable.new
      @worker = Thread.new { work }
    end

    # Queue one announcement and return immediately.
    def announce(text)
      @mutex.synchronize do
        raise Error, "the booth is closed" if @closed

        @pending << text
        @enqueued += 1
        @ready.signal
      end
      self
    end

    # Blocks until everything announced SO FAR has been fully delivered
    # (LLM call and speech included) — how the match holds the opening
    # whistle until the booth finishes its introduction. The booth
    # stays open; a failed announcement counts as delivered.
    def drain
      @mutex.synchronize do
        @idle.wait(@mutex) while @delivered < @enqueued
      end
      self
    end

    # Lets the booth finish everything queued (as one final catch-up
    # batch, if several), then returns. Idempotent.
    def close
      @mutex.synchronize do
        @closed = true
        @ready.signal
      end
      @worker.join
      self
    end

    private

    def work
      while (batch = next_batch)
        deliver(batch)
        @mutex.synchronize do
          @delivered += batch.size
          @idle.broadcast
        end
      end
    end

    # Everything queued so far, in order — or nil once the booth is
    # closed and drained, ending the worker.
    def next_batch
      @mutex.synchronize do
        @ready.wait(@mutex) while @pending.empty? && !@closed
        return nil if @pending.empty?

        batch = @pending
        @pending = []
        batch
      end
    end

    def deliver(batch)
      @announcer.announce(batch.join("\n\n"))
    rescue StandardError => e
      warn "announcer failed: #{e.class}: #{e.message}"
    end
  end
end
