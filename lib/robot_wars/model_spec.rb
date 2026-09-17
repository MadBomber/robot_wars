module RobotWars
  # A warrior's LLM designation: "<provider>/<model id>" — the pattern of
  # the `model:` front matter field in warrior templates and of the rwars
  # --model option. The first "/" splits the RubyLLM provider name from
  # the model id (which may itself contain slashes, as OpenRouter-style
  # ids do). A bare id with no "/" names no provider and leaves that
  # choice to RubyLLM's model registry.
  ModelSpec = Data.define(:provider, :model) do
    # Parse a "<provider>/<model id>" string.
    #
    # @param text [String, nil]
    # @return [ModelSpec, nil] nil when text is nil or blank
    def self.parse(text)
      text = text.to_s.strip
      return nil if text.empty?

      provider, _, model = text.partition("/")
      return new(provider: nil, model: provider) if model.empty?
      return new(provider: nil, model: model) if provider.empty?

      new(provider: provider.to_sym, model: model)
    end

    # Read a template's YAML front matter and parse its `model:` field.
    #
    # @param path [String] path to a *.md template
    # @return [ModelSpec, nil] nil when the template names no model
    def self.from_template(path)
      PromptTemplate.load(path).model_spec
    end
  end
end
