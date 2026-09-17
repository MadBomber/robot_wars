require "test_helper"
require "tempfile"

class RobotWars::PromptTemplateTest < Minitest::Test
  FENCED = <<~TEXT.freeze
    ---
    description: Test brain
    model: lms/openai/gpt-oss-20b
    temperature: 0.9
    ---
    You are the booth.
  TEXT

  def test_parse_splits_front_matter_from_body
    template = RobotWars::PromptTemplate.parse(FENCED)

    assert_equal "Test brain", template.front_matter["description"]
    assert_equal "You are the booth.\n", template.body
  end

  def test_parse_without_front_matter_keeps_the_whole_text_as_body
    template = RobotWars::PromptTemplate.parse("Just a persona.\n")

    assert_empty template.front_matter
    assert_equal "Just a persona.\n", template.body
  end

  def test_parse_treats_non_mapping_front_matter_as_none
    template = RobotWars::PromptTemplate.parse("---\njust a string\n---\nBody.\n")

    assert_empty template.front_matter
    assert_equal "Body.\n", template.body
  end

  def test_model_spec_parses_the_model_field
    spec = RobotWars::PromptTemplate.parse(FENCED).model_spec

    assert_equal :lms, spec.provider
    assert_equal "openai/gpt-oss-20b", spec.model
  end

  def test_model_spec_is_nil_when_no_model_is_named
    assert_nil RobotWars::PromptTemplate.parse("---\ndescription: x\n---\nBody.\n").model_spec
  end

  def test_temperature_reads_the_front_matter_field
    assert_in_delta 0.9, RobotWars::PromptTemplate.parse(FENCED).temperature
  end

  def test_temperature_is_nil_when_absent
    assert_nil RobotWars::PromptTemplate.parse("Body only.").temperature
  end

  def test_load_reads_a_template_file
    Tempfile.create(["brain", ".md"]) do |file|
      file.write(FENCED)
      file.flush

      template = RobotWars::PromptTemplate.load(file.path)

      assert_equal "You are the booth.\n", template.body
    end
  end
end
