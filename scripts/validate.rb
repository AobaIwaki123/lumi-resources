#!/usr/bin/env ruby

require "uri"
require "yaml"

def http_url?(value)
  uri = URI.parse(value.to_s)
  %w[http https].include?(uri.scheme) && !uri.host.nil?
rescue URI::InvalidURIError
  false
end

path = ARGV.fetch(0, File.expand_path("../resources.yaml", __dir__))
document = YAML.safe_load(File.read(path), aliases: false)
errors = []

unless document.is_a?(Hash)
  errors << "document must be a mapping"
end

if document.is_a?(Hash)
  errors << "version must be 1" unless document["version"] == 1
  errors << "updated_at must be YYYY-MM-DD" unless document["updated_at"].to_s.match?(/\A\d{4}-\d{2}-\d{2}\z/)
  resources = document["resources"]
  errors << "resources must be a non-empty array" unless resources.is_a?(Array) && !resources.empty?

  if resources.is_a?(Array)
    ids = resources.filter_map { |resource| resource.is_a?(Hash) ? resource["id"] : nil }
    errors << "resource ids must be unique" unless ids.uniq.length == ids.length

    resources.each_with_index do |resource, index|
      prefix = "resources[#{index}]"
      unless resource.is_a?(Hash)
        errors << "#{prefix} must be a mapping"
        next
      end

      errors << "#{prefix}.id is required" unless resource["id"].is_a?(String) && resource["id"].match?(/\A[a-z0-9]+(?:-[a-z0-9]+)*\z/)
      errors << "#{prefix}.display_name is required" unless resource["display_name"].is_a?(String) && !resource["display_name"].empty?
      errors << "#{prefix}.aliases must be a non-empty array" unless resource["aliases"].is_a?(Array) && !resource["aliases"].empty?
      errors << "#{prefix}.source_bindings must be a non-empty array" unless resource["source_bindings"].is_a?(Array) && !resource["source_bindings"].empty?
      errors << "#{prefix}.evidence must be a non-empty array" unless resource["evidence"].is_a?(Array) && !resource["evidence"].empty?

      bindings = resource["source_bindings"]
      if bindings.is_a?(Array)
        binding_keys = []
        bindings.each_with_index do |binding, binding_index|
          binding_prefix = "#{prefix}.source_bindings[#{binding_index}]"
          unless binding.is_a?(Hash)
            errors << "#{binding_prefix} must be a mapping"
            next
          end

          service = binding["service"]
          errors << "#{binding_prefix}.service is unsupported" unless %w[lumitlink lumitree lumidive].include?(service)
          %w[kind locator_type locator scope url status checked_at].each do |field|
            errors << "#{binding_prefix}.#{field} is required" if binding[field].to_s.empty?
          end
          errors << "#{binding_prefix}.scope is unsupported" unless %w[group group-calendar member-proxy related].include?(binding["scope"])
          errors << "#{binding_prefix}.status is unsupported" unless %w[verified candidate stale].include?(binding["status"])
          errors << "#{binding_prefix}.checked_at must be YYYY-MM-DD" unless binding["checked_at"].to_s.match?(/\A\d{4}-\d{2}-\d{2}\z/)
          errors << "#{binding_prefix}.url must be HTTP(S)" unless http_url?(binding["url"])

          cli = binding["cli"]
          unless cli.is_a?(Hash) && cli["binary"].is_a?(String) && cli["args"].is_a?(Array) && cli["args"].all? { |arg| arg.is_a?(String) }
            errors << "#{binding_prefix}.cli must contain a binary and string args"
          end

          key = [service, binding["kind"], binding["locator"]]
          errors << "#{binding_prefix} duplicates another binding" if binding_keys.include?(key)
          binding_keys << key
        end
      end

      evidence = resource["evidence"]
      if evidence.is_a?(Array)
        evidence.each_with_index do |item, evidence_index|
          evidence_prefix = "#{prefix}.evidence[#{evidence_index}]"
          unless item.is_a?(Hash) && item["kind"].is_a?(String) && item["note"].is_a?(String)
            errors << "#{evidence_prefix} must contain kind and note"
            next
          end
          errors << "#{evidence_prefix}.url must be HTTP(S)" unless http_url?(item["url"])
          errors << "#{evidence_prefix}.checked_at must be YYYY-MM-DD" unless item["checked_at"].to_s.match?(/\A\d{4}-\d{2}-\d{2}\z/)
        end
      end
    end
  end
end

if errors.empty?
  puts "#{path}: valid"
  exit 0
end

warn errors.map { |error| "error: #{error}" }
exit 1

