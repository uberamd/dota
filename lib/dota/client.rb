require 'dota/configuration'
require 'dota/connection'

require 'dota/match'
require 'dota/league'
require 'dota/live_league'
require 'dota/history'
require 'dota/profile'
require 'dota/player_ban'
require 'dota/friend'

module Dota
  class Client
    attr_reader :config

    VERSIONS = { 1 => 'V001',
                 2 => 'V002' }.freeze

    def initialize(options = {})
      @config = Configuration.new(options)
    end

    def configure
      yield config
    end

    def connection
      @connection ||= Connection.new
    end

    # Match details
    #
    # @param [Integer] match id
    # @return [Dota::Match] match object
    def match(id)
      response = run_request('GetMatchDetails', match_id: id)['result']
      Match.new(response) if response
    end

    # The list of matches played
    #
    # @return [Dota::History] match object
    def history(options = {})
      response = run_request('GetMatchHistory', options)['result']
      History.new(response) if response
    end

    # All leagues list
    #
    # @return [Dota::League] league object
    def leagues(options = {})
      response = run_request('GetLeagueListing', options)['result']

      if response && (leagues = response['leagues'])
        leagues.map { |league| League.new(league) }
      end
    end

    # All live leagues list
    #
    # @return [Dota::League] league object
    def live_leagues(options = {})
      response = run_request('GetLiveLeagueGames', options)['result']

      if response && (leagues = response['games'])
        leagues.map { |league| LiveLeague.new(league) }
      end
    end

    # @param [Integer] A list of 64 bit IDs to retrieve profiles for
    #
    # @return [Dota::Profile] match object
    def profiles(*ids)
      raise "Require steam id" unless ids

      response = run_request('GetPlayerSummaries', { steamids: ids.join(",") }, 'ISteamUser', VERSIONS[2])['response']
      if response && (profiles = response['players'])
        profiles.map { |profile| Profile.new(profile) }
      end
    end

    def player_bans(*ids)
      raise "Require steam id" unless ids

      response = run_request('GetPlayerBans', { steamids: ids.join(",") }, 'ISteamUser')
      if response && (player_bans = response['players'])
        player_bans.map { |ban| PlayerBan.new(ban) }
      end
    end

    def friends id
      response = run_request('GetFriendList', { steamid: id }, 'ISteamUser')
      if response && (friends = response["friendslist"]["friends"])
        friends.map { |friend| Friend.new(friend) }
      end
    end

    # @private
    def run_request(method, options = { }, interface = 'IDOTA2Match_570', api_version = VERSIONS[1])
      url = "https://api.steampowered.com/#{interface}/#{method}/#{api_version}/"
      connection.request(:get, url, options.merge(key: config.api_key))
    end
  end
end
