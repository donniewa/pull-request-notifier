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
    if @accessToken
      @render()
      @triggerFetch()
    else
      @renderHelpView()
    @

  renderVersion: ->
    manifest = chrome.runtime.getManifest()
    $('.version').text(manifest.version)

  render: ->
    @fetchRepositories()
    @fetchPullRequests()
    @populateRepoList()
    @bindEvents()
    @promptAddRepo()

  fetchRepositories: =>
    @repositories = JSON.parse(localStorage.getItem('repositories')) or []

  fetchPullRequests: =>
    @hiddenPRs = JSON.parse(localStorage.getItem('hiddenPRs')) or []
    @repositoryJSON = JSON.parse(localStorage.getItem('repos'))

  populateRepoList: ->
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
            created_at: pr.created_at
      else
        pullRequestsHTML = ["<li><p>No PR's</p></li>"]

      _.template @repositoryTemplate,
        name: repo
        pullRequests: pullRequestsHTML.join('')

    $('#repositories').html html.join('')

  bindEvents: =>
    $('.hide').on 'click', @hidePR
    $('.remove').on 'click', @removeRepository

  promptAddRepo: ->
    if match = @url.match(/^https:\/\/github\.com\/([\w-\.]+\/[\w-\.]+)/)
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

  hidePR: (event) =>
    id = $(event.target).closest('li').data('id')
    @hiddenPRs.push(id)
    localStorage.setItem('hiddenPRs', JSON.stringify(@hiddenPRs))
    @render()

  removeRepository: (event) ->
    repo = $(event.target).closest('li').data('id')
    @repositories = _(@repositories).without(repo)
    localStorage.setItem('repositories', JSON.stringify(@repositories))

    @repositoryJSON = JSON.parse(localStorage.getItem('repos'))
    delete @repositoryJSON[repo]
    localStorage.setItem('repos', JSON.stringify(@repositoryJSON))
    @render()

  renderHelpView: ->
    $('.welcome').show()
    $('.save-token').on 'click', =>
      if at = $('#access-token').val()
        localStorage.setItem('accessToken', at)
        $('.welcome').hide()
        @triggerFetch()

  triggerFetch: ->
    @port.postMessage refresh: true

$ ->
  chrome.tabs.getSelected null, (tab) ->
    mon = new GithubMon(tab.url)
