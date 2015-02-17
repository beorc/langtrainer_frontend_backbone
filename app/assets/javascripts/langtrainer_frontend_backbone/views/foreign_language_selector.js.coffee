class Langtrainer.LangtrainerApp.Views.LanguageSelector extends Backbone.View
  _.extend(@prototype, Langtrainer.LangtrainerApp.Views.Extensions.Localized)

  template: JST['langtrainer_frontend_backbone/templates/language_selector']
  class: 'language-selector'

  events:
    'change select': 'onChange'

  initialize: (options) ->
    @options = options
    @listenTo @collection, 'reset', @render
    @initLocalization(onLocaleChanged: @render)

  render: ->
    that = @
    if @collection.length > 0
      @$el.hide().html(@template(
        languages: @collection.models
        model: @model
        label: LangtrainerI18n.t('label.' + @options.label)
      ))
      @$input = @.$('select')
      @$input.selectpicker(noneSelectedText: '')

      @$el.show()
    @

  onChange: (ev) ->
    slug = $(ev.target).val()

    if slug != @model.get('slug')
      @model.set('slug', slug)