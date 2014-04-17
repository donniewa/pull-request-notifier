class GithubMon

  repositoryTemplate: null
  pullRequestTemplate: null
  repositoryJSON: null
  repositories: []
  hiddenPRs: []

  constructor: (url) ->
    @url = url.replace(/[\?#].*/, '')

    _.templateSettings =
      interpolate: /\{\{(.+?)\}\}/g

    @repositoryTemplate = $('#repository-row').html()
    @pullRequestTemplate = $('#pull-request-row').html()

    @port = chrome.extension.connect name: 'connection'
    @port.onMessage.addListener (msg) =>
      if msg.success
        @render()
      else
        debugger

    @renderVersion()
    @accessToken = localStorage.getItem('accessToken')
    @githubHost  = if localStorage.getItem('githubHost') then localStorage.getItem('githubHost') else 'https://github.com'

    if @accessToken
      @render()
      @triggerFetch()
    else
      @renderHelpView()
    @promptAddRepo()
    @

  renderVersion: ->
    manifest = chrome.runtime.getManifest()
    $('.version').text(manifest.version)

  render: ->
    @fetchRepositories()
    @fetchPullRequests()
    @populateRepoList()
    @bindEvents()

  fetchRepositories: =>
    @repositories = JSON.parse(localStorage.getItem('repositories')) or []

  fetchPullRequests: =>
    @hiddenPRs = JSON.parse(localStorage.getItem('hiddenPRs')) or []
    @repositoryJSON = JSON.parse(localStorage.getItem('repos'))

  populateRepoList: ->
    if @repositories.length > 0
      $('.empty').hide()
      html = _(@repositoryJSON).map (pullRequests, repo) =>
        pullRequests = _(pullRequests).filter (pr) =>
          not _(@hiddenPRs).contains pr.id
        if pullRequests.length > 0
          pullRequestsHTML = _(pullRequests).map (pr) =>
            _.template @pullRequestTemplate,
              id: pr.id
              title: pr.title
              html_url: pr.html_url
              user: pr.user.login
              user_avatar: pr.user.avatar_url
              user_url: pr.user.html_url
              git_host: @githubHost
              created_at: moment.utc(pr.created_at).fromNow()
        else
          pullRequestsHTML = ["<li><p>No PR's</p></li>"]

        _.template @repositoryTemplate,
          name: repo
          git_host: @githubHost
          pullRequests: pullRequestsHTML.join('')
      $('#repositories').html html.join('')
    else
      $('#repositories').html('')
      $('.empty').show()

  bindEvents: =>
    $('.hide').on 'click', @hidePR
    $('.remove').on 'click', @removeRepository

  promptAddRepo: ->
    regexExpression = "^" + @githubHost + "\\/([\\w-\\.]+\\/[\\w-\\.]+)"
    regex = new RegExp regexExpression
    if match = @url.match(regex)
      @currentRepo = match[1]
      @showPrompt(@currentRepo) unless _(@repositories).contains @currentRepo
    else
      @hidePrompt()

  showPrompt: (repository) ->
    $('.add-repo .title').text(repository)
    $('.add-repo').show()
    $('.add-repo .add').on 'click', @addCurrentRepo

  hidePrompt: ->
    $('.add-repo').hide()

  addCurrentRepo: =>
    @repositories.push @currentRepo
    localStorage.setItem('repositories', JSON.stringify(@repositories))
    @triggerFetch()
    @hidePrompt()

  hidePR: (event) =>
    id = $(event.target).closest('li').data('id')
    @hiddenPRs.push(id)
    localStorage.setItem('hiddenPRs', JSON.stringify(@hiddenPRs))
    @render()

  removeRepository: (event) =>
    repo = $(event.target).closest('li').data('id')
    @repositories = _(@repositories).without(repo)
    localStorage.setItem('repositories', JSON.stringify(@repositories))

    @repositoryJSON = JSON.parse(localStorage.getItem('repos'))
    delete @repositoryJSON[repo]
    localStorage.setItem('repos', JSON.stringify(@repositoryJSON))
    @promptAddRepo()
    @triggerFetch()

  renderHelpView: ->
    $('.welcome').show()
    $('.save-token').on 'click', =>
      if at = $('#access-token').val()
        localStorage.setItem('accessToken', at)
        localStorage.setItem('githubHost', gh) if gh = $('#github-host').val()
        localStorage.setItem('githubApiHost', gah) if gah = $('#github-apihost').val()
        $('.welcome').hide()
        @triggerFetch()

  triggerFetch: ->
    @port.postMessage refresh: true

$ ->
  chrome.tabs.getSelected null, (tab) ->
    mon = new GithubMon(tab.url)
