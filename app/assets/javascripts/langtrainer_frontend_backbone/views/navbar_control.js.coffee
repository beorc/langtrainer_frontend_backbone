class Langtrainer.LangtrainerApp.Views.NavbarControl extends Backbone.View
  template: JST['langtrainer_frontend_backbone/templates/navbar_control']
  className: 'navbar-user-controls'

  events:
    'click .sign-in-btn': 'onSignInBtnClick'
    'click .sign-up-btn': 'onSignUpBtnClick'
    'click .sign-out-btn': 'onSignOutBtnClick'

  initialize: ->
    Langtrainer.LangtrainerApp.globalBus.on 'user:signedUp user:signedIn user:signedOut', @render, @

  render: ->
    @$el.html(@template())
    @

  onSignInBtnClick: ->
    Langtrainer.LangtrainerApp.navigateToSignIn()
    false

  onSignUpBtnClick: ->
    Langtrainer.LangtrainerApp.navigateToSignUp()
    false

  onSignOutBtnClick: ->
    Langtrainer.LangtrainerApp.currentUser.signOut()
    false
