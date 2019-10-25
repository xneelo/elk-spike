require "spec_helper"

require "http"
require "json"
require "logstash-logger"
require "securerandom"

describe "Logstash event loss" do

  let(:quiet_time) { (ENV["QUIET_TIME"] || "300").to_i }
  let(:flush_time) { (ENV["FLUSH_TIME"] || "10").to_i }
  let(:uri) { ENV["LOGSTASH_URI"] || "tcp://localhost:16700" }
  let(:tag) { SecureRandom.hex(4) }
  let(:search) { ENV["SEARCH_URI"] || "http://localhost:9200/_search" }
  let(:logger) {
    LogStashLogger.new(
      type: :multi_delegator,
      outputs: [
        { type: :stdout, formatter: ::Logger::Formatter},
        { uri: uri },
      ],
      buffer_logger: Logger.new(STDERR),
    )
  }
  let(:sent) { [] }
  let(:send_event) {
    -> {
      sent << SecureRandom.hex(4)
      p sent
      logger.info(message: sent.last, tag: tag)
    }
  }
  let(:received) {
    body = HTTP.get(search + "?q=tag:#{tag}").to_s
    JSON.parse(body)["hits"]["hits"].
      map { |hit| hit["_source"] }.
      sort { |a, b| a["@timestamp"] <=> b["@timestamp"] }.
      map { |source| source["message"] }
  }

  it "does not occur after a quiet time" do
    send_event.call
    sleep(quiet_time)
    send_event.call
    sleep(quiet_time)
    send_event.call
    sleep(flush_time)
    send_event.call

    sleep(flush_time)
    expect(received).to eql sent
  end

end
