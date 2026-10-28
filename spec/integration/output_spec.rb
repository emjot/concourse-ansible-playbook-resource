require 'spec_helper'
require 'open3'
require 'json'

describe "integration:output" do

  let(:out_file) { '/opt/resource/out' }
  let(:mockelton_out) { '/resource/spec/fixtures/mockleton.out' }

  after(:each) do
    File.delete mockelton_out if File.exist? mockelton_out
  end

  it "should return a timestamp version" do
    stdin = {
        "source" => {
            "ssh_private_key" => "key"
        },
        "params" => {
            "path" => "spec/fixtures",
            "inventory" => "the_inventory"
        }
    }.to_json

    stdout, stderr, status = Open3.capture3("#{out_file} .", :stdin_data => stdin)

    expect(status.success?).to be true
    expect(JSON.parse(stdout)).to match(
      "version" => { "timestamp" => a_string_matching(/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\z/) }
    )
  end
end
