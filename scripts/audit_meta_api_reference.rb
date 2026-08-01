#!/usr/bin/env ruby

require "json"
require "yaml"

ROOT = File.expand_path("..", __dir__)
REFERENCE_PATH = ARGV.fetch(0) do
  abort "Usage: ruby scripts/audit_meta_api_reference.rb /path/to/meta-api-reference.md"
end

SPEC_PATHS = {
  "en" => File.join(ROOT, "api-reference/meta/openapi.yaml"),
  "es" => File.join(ROOT, "es/api-reference/meta/openapi.json"),
  "pt" => File.join(ROOT, "pt/api-reference/meta/openapi.json"),
  "tr" => File.join(ROOT, "tr/api-reference/meta/openapi.json")
}.freeze

HTTP_METHODS = %w[get post put patch delete options head trace].freeze

def normalize_operation(method, path)
  normalized_path = path.split("?").first.gsub(/\{[^}]+\}/, "{}")
  "#{method.upcase} #{normalized_path}"
end

def inferred_schema(value)
  case value
  when Hash
    {
      "type" => "object",
      "required" => value.keys,
      "properties" => value.transform_values { |child| inferred_schema(child) }
    }
  when Array
    {
      "type" => "array",
      "items" => value.empty? ? {} : inferred_schema(value.first)
    }
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

def response_json(section)
  block = section.match(
    /\*\*Response[^\n]*\*\*\s*```json\s*(.*?)```/m
  )
  raise "Missing response JSON" unless block

  JSON.parse(block[1])
end

def request_example(section)
  block = section.match(/\*\*Request\*\*\s*```(\w+)\n(.*?)```/m)
  raise "Missing request block" unless block

  language = block[1]
  source = block[2].strip

  if language == "json"
    json_start = source.index("{")
    raise "JSON request block does not contain an object" unless json_start

    return {
      "type" => "json",
      "example" => JSON.parse(source[json_start..])
    }
  end

  if language == "bash" && source.match?(/\s-[Ff]\s/)
    return {
      "type" => "multipart",
      "source" => source
    }
  end

  data = source.match(/(?:^|\s)(?:-d|--data(?:-raw)?)\s+'(\{.*?\})'/m)
  if language == "bash" && data
    return {
      "type" => "json",
      "example" => JSON.parse(data[1])
    }
  end

  { "type" => "none" }
end

def status_rows(section)
  response = section.match(
    /\*\*Response[^\n]*\*\*\s*```json\s*.*?```/m
  )
  raise "Missing response block before table" unless response

  lines = section[response.end(0)..].lines
  header = lines.index do |line|
    line.match?(/^\|\s*Status\s*\|\s*Meaning\s*\|\s*Action\s*\|/)
  end
  raise "Missing Status/Meaning/Action table" unless header

  rows = []
  lines[(header + 2)..].each do |line|
    break unless line.start_with?("|")

    cells = line.strip.sub(/^\|/, "").sub(/\|$/, "").split("|").map(&:strip)
    raise "Malformed status row: #{line}" unless cells.length == 3

    rows << cells
  end
  raise "Empty status table" if rows.empty?

  rows
end

def success_row?(row)
  codes = row.first.scan(/\d{3}/).map(&:to_i)
  codes.length == 1 && codes.first.between?(200, 299)
end

def expected_description(rows)
  successes = rows.select { |row| success_row?(row) }
  failures = rows.reject { |row| success_row?(row) }
  raise "Expected exactly one success row, found #{successes.length}" unless successes.length == 1
  raise "Expected at least one failure row" if failures.empty?

  lines = [
    successes.first[1],
    "",
    "**Failure responses**",
    "",
    "| **Status** | **Meaning** | **Action** |",
    "| --- | --- | --- |"
  ]
  failures.each do |status, meaning, action|
    lines << "| #{status} | #{meaning} | #{action} |"
  end
  lines.join("\n")
end

def load_spec(path)
  path.end_with?(".yaml") ? YAML.safe_load(File.read(path), aliases: true) : JSON.parse(File.read(path))
end

def operations_from(spec)
  operations = {}
  spec.fetch("paths").each do |path, path_item|
    HTTP_METHODS.each do |method|
      operation = path_item[method]
      next unless operation.is_a?(Hash) && operation["operationId"]

      key = normalize_operation(method, path)
      raise "Duplicate operation #{key}" if operations.key?(key)

      operations[key] = operation
    end
  end
  operations
end

def find_openapi_group(value, marker)
  case value
  when Hash
    return value if value["openapi"] == marker

    value.each_value do |child|
      found = find_openapi_group(child, marker)
      return found if found
    end
  when Array
    value.each do |child|
      found = find_openapi_group(child, marker)
      return found if found
    end
  end
  nil
end

def nested_strings(value)
  case value
  when String
    [value]
  when Hash
    value.values.flat_map { |child| nested_strings(child) }
  when Array
    value.flat_map { |child| nested_strings(child) }
  else
    []
  end
end

reference = File.read(REFERENCE_PATH)
raw_sections = reference.scan(
  /^## (\d+\.\d+) (.+?)\n(.*?)(?=^## \d+\.\d+ |^# Appendix|\z)/m
)
abort "Expected 59 source sections, found #{raw_sections.length}" unless raw_sections.length == 59

expected = {}
raw_sections.each do |number, title, section|
  route = section.match(/^`(GET|POST|DELETE|PUT|PATCH) ([^`]+)`/)
  raise "#{number} #{title}: missing route" unless route

  key = normalize_operation(route[1], route[2])
  raise "Duplicate source operation #{key}" if expected.key?(key)

  rows = status_rows(section)
  expected[key] = {
    "number" => number,
    "title" => title,
    "response" => response_json(section),
    "response_schema" => inferred_schema(response_json(section)),
    "response_description" => expected_description(rows),
    "failure_count" => rows.count { |row| !success_row?(row) },
    "request" => request_example(section)
  }
end

failures = []
request_counts = Hash.new(0)
expected.each_value { |entry| request_counts[entry.dig("request", "type")] += 1 }
failure_rows = expected.values.sum { |entry| entry["failure_count"] }
docs_config = JSON.parse(File.read(File.join(ROOT, "docs.json")))
supported_languages = docs_config.dig("navigation", "languages").map { |entry| entry.fetch("language") }
unless supported_languages == SPEC_PATHS.keys
  failures << "Configured languages #{supported_languages.inspect} do not match audited locales #{SPEC_PATHS.keys.inspect}"
end

SPEC_PATHS.each do |locale, path|
  spec = load_spec(path)
  operations = operations_from(spec)
  routes = []
  spec.fetch("paths").each do |route_path, path_item|
    HTTP_METHODS.each do |method|
      operation = path_item[method]
      next unless operation.is_a?(Hash) && operation["operationId"]

      routes << [method.upcase, route_path, operation]
    end
  end

  if operations.keys.sort != expected.keys.sort
    missing = expected.keys - operations.keys
    extra = operations.keys - expected.keys
    failures << "#{locale}: operation mapping differs (missing: #{missing.inspect}; extra: #{extra.inspect})"
    next
  end

  server_urls = Array(spec["servers"]).map { |server| server["url"] }
  unless server_urls == ["https://cerberus.eazybe.com/prod/api/v2"]
    failures << "#{locale}: unexpected server URLs #{server_urls.inspect}"
  end

  marker = locale == "en" ? "/api-reference/meta/openapi.yaml" : "/#{locale}/api-reference/meta/openapi.json"
  navigation_group = find_openapi_group(docs_config, marker)
  unless navigation_group
    failures << "#{locale}: no docs.json navigation group for #{marker}"
  else
    navigation_strings = nested_strings(navigation_group.fetch("pages"))
    if locale == "en"
      expected_routes = routes.map { |method, route_path, _operation| "#{method} #{route_path}" }
      actual_routes = navigation_strings.grep(/\A(?:GET|POST|PUT|PATCH|DELETE|OPTIONS|HEAD|TRACE) /)
      unless actual_routes.sort == expected_routes.sort
        failures << "#{locale}: navigation operation list differs from the OpenAPI paths"
      end
    else
      expected_pages = routes.map do |method, route_path, operation|
        href = operation.dig("x-mint", "href")
        unless href&.start_with?("/#{locale}/api-reference/meta/operations/")
          failures << "#{locale}: #{method} #{route_path} has an invalid x-mint href #{href.inspect}"
          next
        end

        page = href.delete_prefix("/")
        page_file = File.join(ROOT, "#{page}.mdx")
        unless File.file?(page_file)
          failures << "#{locale}: missing generated page #{page}.mdx"
          next page
        end

        expected_reference = "/#{locale}/api-reference/meta/openapi.json #{method} #{route_path}"
        expected_line = "openapi: #{JSON.generate(expected_reference)}"
        unless File.readlines(page_file, chomp: true).include?(expected_line)
          failures << "#{locale}: #{page}.mdx references the wrong operation"
        end
        page
      end.compact

      actual_pages = navigation_strings.grep(%r{\A#{locale}/api-reference/meta/operations/})
      unless actual_pages.sort == expected_pages.sort
        failures << "#{locale}: generated operation-page navigation differs from the OpenAPI paths"
      end
    end
  end

  expected.each do |key, source|
    operation = operations.fetch(key)
    label = "#{locale} #{source["number"]} #{source["title"]}"
    responses = operation["responses"]

    unless responses.is_a?(Hash) && responses.keys == ["200"]
      failures << "#{label}: response keys are #{responses&.keys.inspect}, expected [\"200\"]"
      next
    end

    response = responses["200"]
    media = response.dig("content", "application/json")
    failures << "#{label}: missing application/json response content" unless media
    next unless media

    failures << "#{label}: success JSON differs from source" unless media["example"] == source["response"]
    failures << "#{label}: response schema differs from success JSON" unless media["schema"] == source["response_schema"]
    failures << "#{label}: response table differs from source" unless response["description"] == source["response_description"]

    request = source["request"]
    request_body = operation["requestBody"]
    case request["type"]
    when "none"
      failures << "#{label}: unexpected request body" if request_body
    when "json"
      media = request_body&.dig("content", "application/json")
      unless request_body&.fetch("required", false) && media
        failures << "#{label}: missing required application/json request body"
        next
      end

      expected_body_schema = inferred_schema(request["example"])
      actual_body_schema = Marshal.load(Marshal.dump(media["schema"]))
      description = actual_body_schema.delete("description")
      expected_code = "```json\n#{JSON.pretty_generate(request["example"])}\n```"

      failures << "#{label}: request JSON differs from source cURL/body" unless media["example"] == request["example"]
      failures << "#{label}: request schema differs from request JSON" unless actual_body_schema == expected_body_schema
      failures << "#{label}: Body code block differs from request JSON" unless description == expected_code
    when "multipart"
      media_type = request_body&.dig("content")&.keys&.find { |name| name.start_with?("multipart/form-data") }
      schema = media_type && request_body.dig("content", media_type, "schema")
      expected_code = "```bash\n#{request["source"]}\n```"

      failures << "#{label}: missing multipart request body" unless schema
      failures << "#{label}: multipart cURL body differs from source" if schema && schema["description"] != expected_code
    else
      failures << "#{label}: unsupported expected request type #{request["type"].inspect}"
    end
  end
end

if failures.any?
  warn "Meta API reference audit failed with #{failures.length} issue(s):"
  failures.each { |failure| warn "- #{failure}" }
  exit 1
end

puts "Meta API reference audit passed"
puts "Source operations: #{expected.length}"
puts "Locales checked: #{SPEC_PATHS.keys.join(", ")}"
puts "Success JSON examples checked: #{expected.length * SPEC_PATHS.length}"
puts "Endpoint-specific failure rows checked: #{failure_rows * SPEC_PATHS.length}"
puts "Request bodies per locale: #{request_counts["json"]} JSON, #{request_counts["multipart"]} multipart, #{request_counts["none"]} none"
