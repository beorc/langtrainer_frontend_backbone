class Langtrainer.LangtrainerApp.Models.Step extends Backbone.Model
  initialize: ->
    @resetState()

  resetState: ->
    @wordsHelped = 0
    @stepsHelped = 0
    @wrongAnsers = 0

  difficultyIndex: (answer) ->
    wordsNumber = answer.split(' ').length
    if wordsNumber == 0
      return 1

    return @stepsHelped + @wrongAnsers/2 + @wordsHelped/wordsNumber

  baseParams: ->
    result = '?token=' + Langtrainer.LangtrainerApp.currentUser.readAttribute('token')
    result += '&unit=' + Langtrainer.LangtrainerApp.currentUser.getCurrentCourse().getCurrentUnit().get('id')
    result += '&step=' + @id
    result += '&native_language=' + Langtrainer.LangtrainerApp.currentUser.getCurrentNativeLanguage().get('slug')
    result += '&language=' + Langtrainer.LangtrainerApp.currentUser.getCurrentForeignLanguage().get('slug')

  nextWordUrl: ->
    result = Langtrainer.LangtrainerApp.apiEndpoint + '/help_next_word'
    result += @baseParams()

  verifyAnswerUrl: (answer) ->
    result = Langtrainer.LangtrainerApp.apiEndpoint + '/verify_answer'
    result += @baseParams()
    result += '&answer=' + answer
    result += '&difficulty_index=' + @difficultyIndex(answer)

  nextStepUrl: ->
    result = Langtrainer.LangtrainerApp.apiEndpoint + '/next_step'
    result += @baseParams()

  showRightAnswerUrl: ->
    result = Langtrainer.LangtrainerApp.apiEndpoint + '/show_right_answer'
    result += @baseParams()

  question: (language) ->
    result = ''

    question = @get("#{language.get('slug')}_question")
    if question? && question.length > 0
      result = question

    if result.length == 0
      answer = @answers(language)[0]
      result = _.string.trim(answer)

    _.string.capitalize result.trim()

  answers: (language) ->
    @get("#{language.get('slug')}_answers").split('|')

  sanitizeText: (text) ->
    result = text
    result = result.replace(/(\n\r|\n|\r)/g, ' ')
    result = result.replace(/\s{2,}/g, ' ')
    result = result.trim()

  sanitizeForRegex: (text) ->
    result = text
    result = result.replace(/\?/g, '\\?')

  questionHelp: (language) ->
    @get("#{language.get('slug')}_help")

  matches: (answer, rightAnswer) ->
    answerRegexp = XRegExp("^#{@sanitizeText(@sanitizeForRegex(answer))}", 'i')
    answerRegexp.exec @sanitizeText(rightAnswer)

  nextWordMatches: (answer, rightAnswer) ->
    answerRegexp = XRegExp("^#{@sanitizeText(@sanitizeForRegex(answer))}([\\p{L}\\p{P}]*)\\s*([\\p{L}\\p{P}]*)")
    answerRegexp.exec @sanitizeText(rightAnswer)

  verifyAnswer: (answer, language, context) ->
    that = @
    rightAnswer = null

    if answer.length is 0
      Langtrainer.LangtrainerApp.trainingBus.trigger('step:emptyInput', @)
    else
      rightAnswer = _.find @answers(language), (rightAnswer) ->
        !!that.matches(answer, rightAnswer)

      if rightAnswer?
        Langtrainer.LangtrainerApp.trainingBus.trigger('step:rightInput', @)
      else
        Langtrainer.LangtrainerApp.trainingBus.trigger('step:wrongInput', @)

    rightAnswer

  triggerEvent: (context, eventName) ->
    @trigger(context + ':' + eventName)

  nextWord: (answer, language) ->
    $.ajax
      url: @nextWordUrl()
      dataType: 'json'

    that = @
    result = null

    _.find @answers(language), (rightAnswer) ->
      result = that.nextWordMatches(answer, rightAnswer)
      !!result

    if result? && result[2].length > 0
      @wordsHelped += 1

    result

  verifyAnswerOnServer: (answer, language) ->
    if answer.length is 0
      Langtrainer.LangtrainerApp.trainingBus.trigger('step:wrongAnswer', that)
      return

    that = @
    $.ajax
      url: @verifyAnswerUrl(@sanitizeText(answer))
      dataType: 'json'
      success: (response) ->
        if response
          that.set response
          Langtrainer.LangtrainerApp.trainingBus.trigger('step:changed', that)
          Langtrainer.LangtrainerApp.trainingBus.trigger('step:rightAnswer', that)
          that.resetState()
        else
          that.wrongAnsers += 1
          Langtrainer.LangtrainerApp.trainingBus.trigger('step:wrongAnswer', that)
      error: ->
        Langtrainer.LangtrainerApp.trainingBus.trigger 'step:verificationError', that

  nextStep: ->
    that = @
    $.ajax
      url: @nextStepUrl()
      dataType: 'json'
      success: (response) ->
        that.resetState()
        that.set response
        Langtrainer.LangtrainerApp.trainingBus.trigger('step:changed', that)
      error: ->
        Langtrainer.LangtrainerApp.trainingBus.trigger 'step:verificationError', that

  showRightAnswer: ->
    $.ajax
      url: @showRightAnswerUrl()
      dataType: 'json'

    @stepsHelped += 1
