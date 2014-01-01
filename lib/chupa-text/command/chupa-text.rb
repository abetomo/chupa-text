# Copyright (C) 2013  Kouhei Sutou <kou@clear-code.com>
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

module ChupaText
  module Command
    class ChupaText
      class << self
        def run(*arguments)
          chupa_text = new
          chupa_text.run(*arguments)
        end
      end

      def initialize
      end

      def run(*arguments)
        paths = arguments
        feeder = create_feeder
        paths.each do |path|
          data = Data.new
          data.path = path
          feeder.feed(data) do |extracted|
            puts(extracted.body)
          end
        end
        true
      end

      private
      def create_feeder
        Decomposer.load
        feeder = Feeder.new
        Decomposer.registory.decomposers.each do |decomposer|
          feeder.add_decomposer(decomposer)
        end
        feeder
      end
    end
  end
end