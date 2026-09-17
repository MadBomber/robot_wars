require "test_helper"
require "tmpdir"

class RobotWars::ModelSpecTest < Minitest::Test
  def test_parses_provider_and_model_split_on_the_first_slash
    spec = RobotWars::ModelSpec.parse("apfel/apple-foundationmodel")

    assert_equal :apfel, spec.provider
    assert_equal "apple-foundationmodel", spec.model
  end

  def test_keeps_further_slashes_inside_the_model_id
    spec = RobotWars::ModelSpec.parse("openrouter/meta-llama/llama-3-70b")

    assert_equal :openrouter, spec.provider
    assert_equal "meta-llama/llama-3-70b", spec.model
  end

  def test_a_bare_id_names_no_provider
    spec = RobotWars::ModelSpec.parse("apple-foundationmodel")

    assert_nil spec.provider
    assert_equal "apple-foundationmodel", spec.model
  end

  def test_strips_surrounding_whitespace
    spec = RobotWars::ModelSpec.parse("  ollama/llama3  ")

    assert_equal :ollama, spec.provider
    assert_equal "llama3", spec.model
  end

  def test_nil_and_blank_parse_to_nil
    assert_nil RobotWars::ModelSpec.parse(nil)
    assert_nil RobotWars::ModelSpec.parse("")
    assert_nil RobotWars::ModelSpec.parse("   ")
  end

  def test_degenerate_slash_placement_falls_back_to_a_bare_model
    assert_equal RobotWars::ModelSpec.new(provider: nil, model: "apfel"),
                 RobotWars::ModelSpec.parse("apfel/")
    assert_equal RobotWars::ModelSpec.new(provider: nil, model: "llama3"),
                 RobotWars::ModelSpec.parse("/llama3")
  end

  def test_from_template_reads_the_front_matter_model_field
    with_template(<<~MD) do |path|
      ---
      description: a warrior
      model: apfel/apple-foundationmodel
      temperature: 0.4
      ---
      You are a warrior.
    MD
      spec = RobotWars::ModelSpec.from_template(path)

      assert_equal :apfel, spec.provider
      assert_equal "apple-foundationmodel", spec.model
    end
  end

  def test_from_template_returns_nil_when_front_matter_names_no_model
    with_template(<<~MD) do |path|
      ---
      description: modelless
      ---
      Body.
    MD
      assert_nil RobotWars::ModelSpec.from_template(path)
    end
  end

  def test_from_template_returns_nil_when_front_matter_is_not_a_mapping
    with_template(<<~MD) do |path|
      ---
      just a scalar, not key/value pairs
      ---
      Body.
    MD
      assert_nil RobotWars::ModelSpec.from_template(path)
    end
  end

  def test_from_template_returns_nil_when_there_is_no_front_matter
    with_template("Just a body, no front matter.\n") do |path|
      assert_nil RobotWars::ModelSpec.from_template(path)
    end
  end

  private

  def with_template(content)
    Dir.mktmpdir do |dir|
      path = File.join(dir, "warrior.md")
      File.write(path, content)
      yield path
    end
  end
end
