#!/usr/bin/env ruby

require "json"
require "yaml"

ROOT = File.expand_path("..", __dir__)
OPENAPI_PATH = File.join(ROOT, "api-reference/meta/openapi.yaml")
REFERENCE_PATH = ARGV.fetch(0) do
  abort "Usage: ruby scripts/sync_meta_api_reference.rb /path/to/meta-api-reference.md"
end

HTTP_METHODS = %w[get post put patch delete options head trace].freeze

def normalized_operation_key(method, path)
  normalized_path = path.split("?").first.gsub(/\{[^}]+\}/, "{}")
  "#{method.upcase} #{normalized_path}"
end

def schema_for(value)
  case value
  when Hash
    {
      "type" => "object",
      "required" => value.keys,
      "properties" => value.transform_values { |child| schema_for(child) }
    }
  when Array
    schema = { "type" => "array" }
    schema["items"] = value.empty? ? {} : schema_for(value.first)
    schema
  when String
    { "type" => "string" }
  when Integer
    { "type" => "integer" }
  when Float
    { "type" => "number" }
  when TrueClass, FalseClass
    { "type" => "boolean" }
  when NilClass
    { "nullable" => true }
  else
    raise "Unsupported example value: #{value.inspect}"
  end
end

def parse_json_block(section, label)
  match = section.match(
    /\*\*#{Regexp.escape(label)}[^\n]*\*\*\s*```json\s*(.*?)```/m
  )
  raise "Missing #{label} JSON block" unless match

  JSON.parse(match[1])
end

def parse_request(section)
  match = section.match(/\*\*Request\*\*\s*```(\w+)\n(.*?)```/m)
  raise "Missing request example" unless match

  language = match[1]
  source = match[2].strip

  if language == "json"
    json_start = source.index("{")
    raise "Request JSON block does not contain an object" unless json_start

    return {
      type: :json,
      example: JSON.parse(source[json_start..])
    }
  end

  if language == "bash" && source.match?(/\s-[Ff]\s/)
    return {
      type: :form,
      source: source
    }
  end

  if language == "bash" && (data_match = source.match(/-d\s+'(\{.*?\})'/m))
    return {
      type: :json,
      example: JSON.parse(data_match[1])
    }
  end

  { type: :none }
end

def parse_status_rows(section)
  response = section.match(
    /\*\*Response[^\n]*\*\*\s*```json\s*.*?```/m
  )
  raise "Missing response block before status table" unless response

  tail = section[response.end(0)..]
  lines = tail.lines
  header_index = lines.index do |line|
    line.match?(/^\|\s*Status\s*\|\s*Meaning\s*\|\s*Action\s*\|/)
  end
  raise "Missing response status table" unless header_index

  rows = []
  lines[(header_index + 2)..].each do |line|
    break unless line.start_with?("|")

    cells = line.strip.sub(/^\|/, "").sub(/\|$/, "").split("|").map(&:strip)
    raise "Unexpected response table row: #{line}" unless cells.length == 3

    rows << cells
  end

  raise "Response status table has no rows" if rows.empty?
  rows
end

def success_status?(status)
  numbers = status.scan(/\d{3}/).map(&:to_i)
  numbers.length == 1 && numbers.first.between?(200, 299)
end

def response_description(rows)
  success = rows.find { |status, _meaning, _action| success_status?(status) }
  failures = rows.reject { |status, _meaning, _action| success_status?(status) }
  raise "Response table does not contain a success row" unless success
  raise "Response table does not contain failure rows" if failures.empty?

  table = [
    "**Failure responses**",
    "",
    "| **Status** | **Meaning** | **Action** |",
    "| --- | --- | --- |"
  ]
  failures.each do |status, meaning, action|
    table << "| #{status} | #{meaning} | #{action} |"
  end

  [success[1], table.join("\n")].join("\n\n")
end

def json_request_body(example)
  schema = schema_for(example)
  schema["description"] = <<~MARKDOWN.strip
    ```json
    #{JSON.pretty_generate(example)}
    ```
  MARKDOWN

  {
    "required" => true,
    "content" => {
      "application/json" => {
        "schema" => schema,
        "example" => example
      }
    }
  }
end

def form_request_body(existing, source)
  raise "Multipart operation is missing an OpenAPI request body" unless existing

  media_type = existing.fetch("content").keys.find do |name|
    name.start_with?("multipart/form-data")
  end
  raise "Multipart operation has no multipart/form-data content" unless media_type

  schema = existing.dig("content", media_type, "schema")
  raise "Multipart operation has no request schema" unless schema.is_a?(Hash)

  schema["description"] = <<~MARKDOWN.strip
    ```bash
    #{source}
    ```
  MARKDOWN
  existing
end

reference = File.read(REFERENCE_PATH)
sections = reference.scan(
  /^## (\d+\.\d+) (.+?)\n(.*?)(?=^## \d+\.\d+ |^# Appendix|\z)/m
)
raise "Expected 59 endpoint sections, found #{sections.length}" unless sections.length == 59

spec = YAML.safe_load(File.read(OPENAPI_PATH), aliases: true)
operations = {}

spec.fetch("paths").each do |path, path_item|
  HTTP_METHODS.each do |method|
    operation = path_item[method]
    next unless operation.is_a?(Hash) && operation["operationId"]

    key = normalized_operation_key(method, path)
    raise "Duplicate OpenAPI operation key: #{key}" if operations.key?(key)

    operations[key] = operation
  end
end

raise "Expected 59 OpenAPI operations, found #{operations.length}" unless operations.length == 59

matched = []
json_bodies = 0
form_bodies = 0
bodyless = 0

sections.each do |number, title, section|
  route = section.match(/^`(GET|POST|DELETE|PUT|PATCH) ([^`]+)`/)
  raise "#{number} #{title}: missing method and route" unless route

  key = normalized_operation_key(route[1], route[2])
  operation = operations.fetch(key) do
    raise "#{number} #{title}: no matching OpenAPI operation for #{key}"
  end
  matched << key

  response_example = parse_json_block(section, "Response")
  status_rows = parse_status_rows(section)
  operation["responses"] = {
    "200" => {
      "description" => response_description(status_rows),
      "content" => {
        "application/json" => {
          "schema" => schema_for(response_example),
          "example" => response_example
        }
      }
    }
  }

  request = parse_request(section)
  case request[:type]
  when :json
    raise "#{number} #{title}: JSON request body must be an object" unless request[:example].is_a?(Hash)

    operation["requestBody"] = json_request_body(request[:example])
    json_bodies += 1
  when :form
    operation["requestBody"] = form_request_body(
      operation["requestBody"],
      request[:source]
    )
    form_bodies += 1
  when :none
    operation.delete("requestBody")
    bodyless += 1
  else
    raise "#{number} #{title}: unsupported request type #{request[:type]}"
  end
end

unless matched.uniq.length == 59 && matched.sort == operations.keys.sort
  raise "Reference sections did not map one-to-one to the OpenAPI operations"
end

File.write(OPENAPI_PATH, YAML.dump(spec))
puts "Synchronized 59 operations from #{REFERENCE_PATH}"
puts "Request bodies: #{json_bodies} JSON, #{form_bodies} multipart, #{bodyless} none"
