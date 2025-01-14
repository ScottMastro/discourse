# frozen_string_literal: true

RSpec.describe SearchLog, type: :model do
  after { SearchLog.clear_debounce_cache! }

  describe ".log" do
    context "with invalid arguments" do
      it "no search type returns error" do
        status, _ =
          SearchLog.log(
            term: "bounty hunter",
            search_type: :missing,
            ip_address: "127.0.0.1",
            user_agent: "Mozilla",
          )
        expect(status).to eq(:error)
      end

      it "no IP returns error" do
        status, _ =
          SearchLog.log(
            term: "bounty hunter",
            search_type: :header,
            ip_address: nil,
            user_agent: "Mozilla",
          )
        expect(status).to eq(:error)
      end

      it "does not error when no user_agent" do
        status, _ =
          SearchLog.log(term: "bounty hunter", search_type: :header, ip_address: "127.0.0.1")
        expect(status).to eq(:created)
      end
    end

    context "when anonymous" do
      it "logs and updates the search" do
        freeze_time
        action, log_id =
          SearchLog.log(
            term: "jabba",
            search_type: :header,
            ip_address: "192.168.0.33",
            user_agent: "Mozilla",
          )
        expect(action).to eq(:created)
        log = SearchLog.find(log_id)
        expect(log.term).to eq("jabba")
        expect(log.search_type).to eq(SearchLog.search_types[:header])
        expect(log.ip_address).to eq("192.168.0.33")
        expect(log.user_agent).to eq("Mozilla")

        action, updated_log_id =
          SearchLog.log(term: "jabba the hut", search_type: :header, ip_address: "192.168.0.33")
        expect(action).to eq(:updated)
        expect(updated_log_id).to eq(log_id)
      end

      it "creates a new search with a different prefix" do
        freeze_time
        action, _ = SearchLog.log(term: "darth", search_type: :header, ip_address: "127.0.0.1")
        expect(action).to eq(:created)

        action, _ = SearchLog.log(term: "anakin", search_type: :header, ip_address: "127.0.0.1")
        expect(action).to eq(:created)
      end

      it "creates a new search with a different ip" do
        freeze_time
        action, _ = SearchLog.log(term: "darth", search_type: :header, ip_address: "127.0.0.1")
        expect(action).to eq(:created)

        action, _ = SearchLog.log(term: "darth", search_type: :header, ip_address: "127.0.0.2")
        expect(action).to eq(:created)
      end
    end

    context "when logged in" do
      fab!(:user)

      it "logs and updates the search" do
        freeze_time
        action, log_id =
          SearchLog.log(
            term: "hello",
            search_type: :full_page,
            ip_address: "192.168.0.1",
            user_agent: "Mozilla",
            user_id: user.id,
          )
        expect(action).to eq(:created)
        log = SearchLog.find(log_id)
        expect(log.term).to eq("hello")
        expect(log.search_type).to eq(SearchLog.search_types[:full_page])
        expect(log.ip_address).to eq(nil)
        expect(log.user_agent).to eq("Mozilla")
        expect(log.user_id).to eq(user.id)

        action, updated_log_id =
          SearchLog.log(
            term: "hello dolly",
            search_type: :header,
            ip_address: "192.168.0.33",
            user_id: user.id,
          )
        expect(action).to eq(:updated)
        expect(updated_log_id).to eq(log_id)
      end

      it "logs again if time has passed" do
        freeze_time(10.minutes.ago)

        action, _ =
          SearchLog.log(
            term: "hello",
            search_type: :full_page,
            ip_address: "192.168.0.1",
            user_id: user.id,
          )
        expect(action).to eq(:created)

        freeze_time(10.minutes.from_now)
        Discourse.redis.del(SearchLog.redis_key(ip_address: "192.168.0.1", user_id: user.id))

        action, _ =
          SearchLog.log(
            term: "hello",
            search_type: :full_page,
            ip_address: "192.168.0.1",
            user_id: user.id,
          )

        expect(action).to eq(:created)
      end

      it "logs again with a different user" do
        freeze_time

        action, _ =
          SearchLog.log(
            term: "hello",
            search_type: :full_page,
            ip_address: "192.168.0.1",
            user_id: user.id,
          )
        expect(action).to eq(:created)

        action, _ =
          SearchLog.log(
            term: "hello dolly",
            search_type: :full_page,
            ip_address: "192.168.0.1",
            user_id: Fabricate(:user).id,
          )
        expect(action).to eq(:created)
      end
    end
  end

  describe ".term_details" do
    it "should only use the date for the period" do
      time = Time.utc(2019, 5, 23, 18, 15, 30)
      freeze_time(time)

      search_log = Fabricate(:search_log, created_at: time - 1.hour)
      search_log2 = Fabricate(:search_log, created_at: time + 1.hour)

      details = SearchLog.term_details(search_log.term, :daily)

      expect(details[:data].first[:y]).to eq(2)
    end

    it "correctly returns term details" do
      Fabricate(:search_log, term: "ruby")
      Fabricate(:search_log, term: "ruBy", user: Fabricate(:user))
      Fabricate(:search_log, term: "ruby core", ip_address: "127.0.0.3")

      Fabricate(
        :search_log,
        term: "ruBy",
        search_type: SearchLog.search_types[:full_page],
        ip_address: "127.0.0.2",
      )

      term_details = SearchLog.term_details("ruby")
      expect(term_details[:data][0][:y]).to eq(3)

      term_header_details = SearchLog.term_details("ruby", :all, :header)
      expect(term_header_details[:data][0][:y]).to eq(2)

      SearchLog
        .where("lower(term) = ?", "ruby")
        .where(ip_address: "127.0.0.2")
        .update_all(search_result_id: 24)

      term_click_through_details = SearchLog.term_details("ruby", :all, :click_through_only)
      expect(term_click_through_details[:period]).to eq("all")
      expect(term_click_through_details[:data][0][:y]).to eq(1)
    end
  end

  describe "trending" do
    fab!(:user)
    before do
      SearchLog.log(term: "ruby", search_type: :header, ip_address: "127.0.0.1")
      SearchLog.log(term: "php", search_type: :header, ip_address: "127.0.0.1")
      SearchLog.log(term: "java", search_type: :header, ip_address: "127.0.0.1")
      SearchLog.log(term: "ruby", search_type: :header, ip_address: "127.0.0.1", user_id: user.id)
      SearchLog.log(term: "swift", search_type: :header, ip_address: "127.0.0.1")
      SearchLog.log(term: "ruby", search_type: :header, ip_address: "127.0.0.2")
    end

    it "considers time period" do
      expect(SearchLog.trending.to_a.count).to eq(4)

      SearchLog.where(term: "swift").update_all(created_at: 1.year.ago)
      expect(SearchLog.trending(:monthly).to_a.count).to eq(3)
    end

    it "correctly returns trending data" do
      top_trending = SearchLog.trending.first
      expect(top_trending.term).to eq("ruby")
      expect(top_trending.searches).to eq(3)
      expect(top_trending.click_through).to eq(0)

      SearchLog.where(term: "ruby", ip_address: "127.0.0.1").update_all(search_result_id: 12)
      SearchLog.where(term: "ruby", user_id: user.id).update_all(search_result_id: 12)
      SearchLog.where(term: "ruby", ip_address: "127.0.0.2").update_all(search_result_id: 24)
      top_trending = SearchLog.trending.first
      expect(top_trending.click_through).to eq(3)
    end
  end

  describe "clean_up" do
    it "will remove old logs" do
      SearchLog.log(term: "jawa", search_type: :header, ip_address: "127.0.0.1")
      SearchLog.log(term: "jedi", search_type: :header, ip_address: "127.0.0.1")
      SearchLog.log(term: "rey", search_type: :header, ip_address: "127.0.0.1")
      SearchLog.log(term: "finn", search_type: :header, ip_address: "127.0.0.1")

      SiteSetting.search_query_log_max_size = 5
      SearchLog.clean_up
      expect(SearchLog.count).to eq(4)

      SiteSetting.search_query_log_max_size = 2
      SearchLog.clean_up
      expect(SearchLog.count).to eq(2)
      expect(SearchLog.where(term: "rey").first).to be_present
      expect(SearchLog.where(term: "finn").first).to be_present
    end
  end
end
