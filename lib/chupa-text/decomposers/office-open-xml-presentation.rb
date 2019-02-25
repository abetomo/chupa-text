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

require "chupa-text/decomposers/office-open-xml"

module ChupaText
  module Decomposers
    class OfficeOpenXMLPresentation < OfficeOpenXML
      registry.register("office-open-xml-presentation", self)

      def initialize(options={})
        super
        @extensions = [
          "pptx",
          "pptm",
          "ppsx",
          "ppsm",
          "potx",
          "potm",
          "sldx",
          "sldm",
        ]
        @mime_types = [
          "application/vnd.openxmlformats-officedocument.presentationml.presentation",
          "application/vnd.ms-powerpoint.presentation.macroEnabled.12",
          "application/vnd.openxmlformats-officedocument.presentationml.slideshow",
          "application/vnd.ms-powerpoint.slideshow.macroEnabled.12",
          "application/vnd.openxmlformats-officedocument.presentationml.template",
          "application/vnd.ms-powerpoint.template.macroEnabled.12",
          "application/vnd.openxmlformats-officedocument.presentationml.slide",
          "application/vnd.ms-powerpoint.slide.macroEnabled.12",
        ]
        @namespace_uri =
          "http://schemas.openxmlformats.org/drawingml/2006/main"
      end

      private
      def process_entry(entry, context)
        case entry.zip_path
        when /\Appt\/slides\/slide(\d+)\.xml/
          nth_slide = Integer($1, 10)
          slide_text = ""
          extract_text(entry, slide_text)
          context[:slides] ||= []
          context[:slides] << [nth_slide, slide_text]
        end
      end

      def accumulate_text(context)
        context[:slides].sort_by(&:first).collect(&:last).join("\n")
      end
    end
  end
end