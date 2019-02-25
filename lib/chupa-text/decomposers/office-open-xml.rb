# Copyright (C) 2019  Kouhei Sutou <kou@clear-code.com>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

require "cgi/util"
require "rexml/parsers/sax2parser"
require "rexml/sax2listener"

require "archive/zip"

module ChupaText
  module Decomposers
    class OfficeOpenXML < Decomposer
      def target?(data)
        @extensions.include?(data.extension) or
          @mime_types.include?(data.mime_type)
      end

      def target_score(data)
        if target?(data)
          -1
        else
          nil
        end
      end

      def decompose(data)
        texts = []
        attributes = {}
        data.open do |input|
          Archive::Zip.open(input) do |zip|
            zip.each do |entry|
              next unless entry.file?
              case entry.zip_path
              when @path
                extract_text(entry, texts)
              when "docProps/app.xml"
                listener = AttributesListener.new(attributes)
                parse(entry.file_data, listener)
              when "docProps/core.xml"
                listener = AttributesListener.new(attributes)
                parse(entry.file_data, listener)
              end
            end
          end
        end
        text = accumulate_texts(texts)
        text_data = TextData.new(text, source_data: data)
        attributes.each do |name, value|
          text_data[name] = value
        end
        yield(text_data)
      end

      private
      def parse(io, listener)
        source = REXML::Source.new(io.read)
        parser = REXML::Parsers::SAX2Parser.new(source)
        parser.listen(listener)
        parser.parse
      end

      def extract_text(entry, texts)
        listener = TextListener.new(texts, @namespace_uri)
        parse(entry.file_data, listener)
      end

      def accumulate_texts(texts)
        texts.join("")
      end

      class TextListener
        include REXML::SAX2Listener

        def initialize(output, target_uri)
          @output = output
          @target_uri = target_uri
          @in_target = false
        end

        def start_element(uri, local_name, qname, attributes)
          return unless uri == @target_uri
          case local_name
          when "t"
            @in_target = true
          end
        end

        def end_element(uri, local_name, qname)
          return unless uri == @target_uri
          case local_name
          when "t"
            @in_target = false
          when "p", "br"
            @output << "\n"
          end
        end

        def characters(text)
          add_text(text)
        end

        def cdata(content)
          add_text(content)
        end

        private
        def add_text(text)
          return unless @in_target
          @output << CGI.unescapeHTML(text)
        end
      end

      class AttributesListener
        include REXML::SAX2Listener

        CORE_PROPERTIES_URI =
          "http://schemas.openxmlformats.org/package/2006/metadata/core-properties"
        EXTENDED_PROPERTIES_URI =
          "http://schemas.openxmlformats.org/officeDocument/2006/extended-properties"
        DUBLIN_CORE_URI = "http://purl.org/dc/elements/1.1/"
        DUBLIN_CORE_TERMS_URI = "http://purl.org/dc/terms/"

        def initialize(attributes)
          @attributes = attributes
          @name = nil
          @type = nil
        end

        def start_element(uri, local_name, qname, attributes)
          case uri
          when CORE_PROPERTIES_URI
            case local_name
            when "keywords"
              @name = local_name
            end
          when EXTENDED_PROPERTIES_URI
            case local_name
            when "Application"
              @name = local_name.downcase
            end
          when DUBLIN_CORE_URI
            case local_name
            when "description", "title", "subject"
              @name = local_name
            end
          when DUBLIN_CORE_TERMS_URI
            case local_name
            when "created", "modified"
              @name = "#{local_name}_time"
              @type = :w3cdtf
            end
          end
        end

        def end_element(uri, local_name, qname)
          @name = nil
          @type = nil
        end

        def characters(text)
          set_attribute(text)
        end

        def cdata(content)
          set_attribute(content)
        end

        def set_attribute(value)
          return if @name.nil?

          value = CGI.unescapeHTML(value)
          case @type
          when :w3cdtf
            value = Time.xmlschema(value)
          end
          @attributes[@name] = value
        end
      end
    end
  end
end
