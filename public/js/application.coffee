#= require bootstrap.min.js
#= require items.coffee
#= require qrcode.js

g = this
$(->
  setTimeout(listen, 10000)

  $.get('/js/rates.json', (data) ->
    g.rates = data
  )

  $('#bitcoin').click(->
    rate = g.rates.CAD.cavirtex.rates.bid
    g.amount = parseFloat(0.04 / rate).toFixed(8)
    g.address = '15dRBzyg68NXRraGQVpa4MgbohyZEFH7sM'

    $('#request p').html("Please send #{g.amount} BTC to:")
    $('#address').html(g.address)

    $('#qr').html('')
    new QRCode('qr', 
      text: "bitcoin:#{g.address}?amount=#{g.amount}"
      width: 250
      height: 250
    )

    $('#cancel, #pay_bitcoin').show()
    $('#choose').hide()
  )

  $('#cash').click(->
    $('#close, #pay_cash').show()
    $('#choose').hide()
    register()
  ) 

  $('#modal').on('hidden.bs.modal', -> $('#cancel').click())
  $('#cancel').click(->
    $('#choose').show()
    $('#cancel, #close, #pay_cash, #pay_bitcoin').hide()
  )

  $('a[data-toggle="tab"]').on('shown.bs.tab', (e) ->
    $('#next').toggle(e.target.attributes.href.value == '#step1')
  )

  $('#next').click(-> $('#step2_link').click())

  $(document).on('click', '.plus, .minus', (e) -> 
    e.stopPropagation()

    span = $(this).siblings('.count')
    count = parseInt(span.html())
    total = parseInt($(this).closest('.items').find('h3 .count').html())
    max = parseInt($(this).closest('.items').find('.max').html())

    n = 1
    n = -1 if $(this).hasClass('minus')

    return if count is 0 and n is -1
    return if total is max and n is 1
    count += n

    img = $(this).closest('.item').find('.img')
    img.toggleClass('grayscale', count is 0)
    span.html(count.toString())

    updateTotals()
  )

  $(document).on('mouseenter', '.item', (e) -> 
    e.stopPropagation()
    $(this).find('.img').removeClass('grayscale')
  )

  $(document).on('mouseleave', '.item', (e) -> 
    e.stopPropagation()
    count = parseInt($(this).find('.panel-body .count').html())
    if count is 0
      $(this).find('.img').addClass('grayscale')
  )

  updateTotals = ->
    $('.items').each(->
      count = 0
      $(this).find('div.item span.count').each(-> 
        count += parseInt($(this).html())
      )
      $(this).find('h3 span.count').html(count.toString())
    )

  $(document).on('click', '.item', -> $(this).find('.plus').click())

  $('#register-button').click(->
    $('#modal').modal()
  )

  $('#modal').on('shown.bs.modal', ->
    $('#email').focus()
  )

  $('#order').click(->
    order = "BEEF"
    $.post('/orders', email: 'asoltys@gmail.com', week: 1, order: order)
  )

  for item in g.items
    div = $('.item').first().clone()
    div.removeAttr('id')
    div.find('.img').css('background-image', "url(#{item.image})")
    div.find('.name').html(item.name)
    div.find('.description').html(item.description)
    div.find('.ingredients').html(item.ingredients.toString())
    div.show()

    switch item.type
      when 'Entree'
        $('#entrees').append(div)
      when 'Soup'
        $('#soups').append(div)
      when 'Salad'
        $('#salads').append(div)

  $('#item').remove()

)

listen = ->
  unless g.blockchain and g.blockchain.readyState is 1
    g.blockchain = new WebSocket("wss://ws.blockchain.info/inv")

    g.blockchain.onopen = -> 
      $('#connection').fadeIn().removeClass('glyphicon-exclamation-sign').addClass('glyphicon-signal')
      g.blockchain.send('{"op":"addr_sub", "addr":"' + g.address + '"}')
    
    g.blockchain.onerror =  ->
      $('#connection').addClass('glyphicon-exclamation-sign').removeClass('glyphicon-signal')
      g.blockchain = null
      fail(SOCKET_FAIL)

    g.blockchain.onclose = ->
      $('#connection').addClass('glyphicon-exclamation-sign').removeClass('glyphicon-signal')
      g.blockchain = null
      fail(SOCKET_FAIL)

    g.blockchain.onmessage = (e) ->
      results = eval('(' + e.data + ')')
      amount = 0
      txid = results.x.hash

      $.each(results.x.out, (i, v) ->
        if (v.addr == g.address) 
          amount += v.value / 100000000
      )

      if amount >= g.amount
        $('#received').show()
        $('#request').hide()
        register()

register = ->
  $.post('/users', $('#register').serialize())
  count = parseInt($('#users').html()) - 1
  $('#users').html(count.toString())
