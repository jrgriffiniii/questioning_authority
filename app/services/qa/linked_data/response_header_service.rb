# Service to construct a request header that includes optional attributes for search and fetch requests.
module Qa
  module LinkedData
    class ResponseHeaderService
      class_attribute :ldpath_service
      self.ldpath_service = Qa::LinkedData::LdpathService

      attr_reader :request_header, :results, :config, :graph

      # @param request_header [Hash] request attributes constructed by Qa::LinkedData::RequestHeaderService
      # @param results [String, JSON] results generated by executing a request
      # @param config [String] authority configuration identifying where in the results or request_header data can be found
      # @param graph [RDF::Graph] graph holding results
      def initialize(request_header:, results:, config:, graph:)
        @request_header = request_header
        @results = results
        @config = config
        @graph = graph
      end

      # Construct response header to pass back with search results (linked data module).
      # @returns [Hash] response data
      # @see Qa::Authorities::LinkedData::SearchQuery
      def search_header
        header = {}
        header[:start_record] = start_record
        header[:requested_records] = requested_records
        header[:retrieved_records] = retrieved_records
        header[:total_records] = total_record_count
        header
      end

      # Construct response header to pass back with fetch results (linked data module).
      # @returns [Hash] response data
      # @see Qa::Authorities::LinkedData::FetchTerm
      def fetch_header
        header = {}
        header[:predicate_count] = pred_count
        header
      end

      private

        # determine the position of the first record in the returned results relative to all search results
        def start_record
          request_header.fetch(:replacements, {}).fetch(config.start_record_parameter, 1).to_i
        end

        # determine the number of requested records
        def requested_records
          num = request_header.fetch(:replacements, {}).fetch(config.requested_records_parameter, nil)
          num.present? ? num.to_i : I18n.t("qa.linked_data.search.default_requested_records")
        end

        # determine the number of records actually returned
        def retrieved_records
          results.count
        end

        # determine the full number of records matching the search query
        def total_record_count
          ldpath = config.total_count_ldpath
          service_uri = RDF::URI.new(config.service_uri)
          return I18n.t("qa.linked_data.search.total_not_reported") unless ldpath && service_uri
          prefixes = config.prefixes
          ldpath_program = ldpath_service.ldpath_program(ldpath: ldpath, prefixes: prefixes)
          values = ldpath_service.ldpath_evaluate(program: ldpath_program, graph: graph, subject_uri: service_uri)
          values.map!(&:to_i)
          values.first || I18n.t("qa.linked_data.search.total_not_reported")
        end

        # determine how many predicates are directly used with the requested term
        def pred_count
          results['predicates'].present? ? results['predicates'].size : 0
        end
    end
  end
end
