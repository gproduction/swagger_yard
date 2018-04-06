require 'spec_helper'

RSpec.describe SwaggerYard::Model do
  let(:content) do
    [ "@model MyModel",
      "@discriminator myType(required) [string]" ].join("\n")
  end

  let(:object)    { yard_class('MyModel', content) }

  subject(:model) { described_class.from_yard_object(object) }

  its(:id) { is_expected.to eq("MyModel") }

  context "with characters that are not components of a word" do
    let(:content) { "@model MyApp::Models::Foo" }

    its(:id) { is_expected.to eq("MyApp_Models_Foo") }
  end

  context "with numeric or _ characters" do
    let(:content) { "@model My__Model01" }

    its(:id) { is_expected.to eq("My__Model01") }
  end

  context "superclass with polymorphism" do
    its(:discriminator) { is_expected.to eq("myType") }
  end

  context "inherited class with polymorphism" do
    let(:content) do
      [
        "@model MyBiggerModel",
        "@inherits MyModel",
        "@property myOtherProperty [string]"
      ].join("\n")
    end

    its(:to_h) do
      is_expected.to eq(
        "allOf" => [
          {
            "$ref" => "#/definitions/MyModel"
          },
          {
            "type" => "object",
            "properties" => {
              "myOtherProperty" => {
                "type"=>"string",
                "description"=>""
              }
            }
          }
        ]
      )
    end

    context 'and an external schema' do
      let(:content) do
        ["@model MyModel",
         "@inherits schema#OtherModel"].join("\n")
      end
      let(:url)  { 'http://example.com/schemas/v1.0' }
      before do
        SwaggerYard.configure do |config|
          config.external_schema schema: url
        end
      end

      its(:to_h) do
        schema = {
          "allOf" => [{ "$ref" => "#{url}#/definitions/OtherModel" },
                      { "type" => "object", "properties" => {} }]
        }
        is_expected.to eq(schema)
      end
    end
  end
end
