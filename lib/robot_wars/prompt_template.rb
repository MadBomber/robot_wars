require "yaml"

module RobotWars
  # A RobotLab-style prompt template as a file: optional YAML front
  # matter between "---" fences, then the prompt body. This is the
  # subset the rwars CLI reads for itself — the announcer's brain file
  # (which may live anywhere, so it can't go through prompt_manager's
  # single template directory) and warrior `model:` fields.
  PromptTemplate = Data.define(:front_matter, :body) do
    # @param path [String] path to a *.md template
    # @return [PromptTemplate]
    def self.load(path) = parse(File.read(path))

    # @param text [String] raw template text
    # @return [PromptTemplate] front_matter is {} when the text has no
    #   front matter (or it isn't a YAML mapping); body is the text
    #   after the closing fence, or all of it
    def self.parse(text)
      matched = text.match(/\A---\s*\n(.*?)\n---\s*(\n|\z)/m)
      return new(front_matter: {}, body: text) unless matched

      metadata = YAML.safe_load(matched[1])
      new(front_matter: metadata.is_a?(Hash) ? metadata : {}, body: matched.post_match)
    end

    # @return [ModelSpec, nil] the front matter's `model:` field parsed
    #   as "<provider>/<model id>", nil when it names none
    def model_spec = ModelSpec.parse(front_matter["model"])

    # @return [Numeric, nil] the front matter's `temperature:` field
    def temperature = front_matter["temperature"]
  end
end
