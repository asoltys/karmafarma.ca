#= require bootstrap.min.js
#= require items.coffee
#= require qrcode.js
#= require check_email.js

g = this
$(->
  $.get('/js/rates.json', (data) ->
    g.rates = data

    $('#bitcoin').click(->
      rate = g.rates.CAD.cavirtex.rates.bid
      g.amount = parseFloat(450 / rate).toFixed(8)
      g.address = '15dRBzyg68NXRraGQVpa4MgbohyZEFH7sM'

      $('#request h2').html("Please send #{g.amount} BTC to:")
      $('#address').html(g.address)

      $('#qr').html('')
      new QRCode('qr', 
        text: "bitcoin:#{g.address}?amount=#{g.amount}"
        width: 250
        height: 250
      )

      $('#cancel, #pay_bitcoin').show()
      $('#choose').hide()
      setTimeout(listen, 10000) unless g.blockchain
    )
  )

  $('#cash').click(->
    $('#close, #pay_cash, #registered').show()
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

  $('#next').click(-> $('#register').submit())
  $('#register').submit(-> 
    email = $('#email').val()

    if validateEmail(email)
      $('#step2_link').click()
    else
      $('#email').parent().addClass('has-error')
      $('#email').focus()

    return false
  )

  $(document).on('click', '.plus, .minus', (e) -> 
    e.stopPropagation()

    span = $(this).siblings('.count')
    count = parseInt(span.html())
    total = parseInt($(this).closest('.items').find('h3 .count').html())
    max = parseInt($(this).closest('.items').find('.max').html())

    n = 1
    n = -1 if $(this).hasClass('minus')

    return if count is 0 and n is -1
    return if count is 2 and n is 1
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
    $('#name').focus()
  )

  $('#order').click(-> 
    $('#order_close, #order_done, #order_placed').hide()
    $('#order_cancel, #order_confirm').show()

    g.order = []
    total = 0
    $('#list').html('')

    $('.img:not(.grayscale)').closest('.item').each(->
      name = $(this).find('.name').html()
      count = $(this).find('.panel-body .count').html()
      total += parseInt(count)
      g.order.push(item: name, count: count)
      $('#list').append("<li><b>#{count}x</b> #{name}</li>")
    )

    $('#warning_count').html(total)
    $('#order_warning').toggle(total < 8)

    $('#confirmation').modal()
  )

  $('#confirmation').on('shown.bs.modal', ->
    $('#order_email').focus()
  )

  $('#confirm_form').submit(->
    $('#order_confirm').click()
    return false
  )

  $('#order_confirm').click(->
    email = $('#order_email').val()
    unless validateEmail(email)
      $('#order_email').parent().addClass('has-error')
      return

    $.get("/users/#{encodeURIComponent(email)}", (data) ->
      if data and data != "null"
        $.post('/orders', email: email, week: 'Nov4', order: JSON.stringify(g.order))
        $('#order_close, #order_done, #order_placed').show()
        $('#order_cancel, #order_confirm, #order_warning').hide()
      else
        $('#not_registered').show()
        $('#order_email').parent().addClass('has-error')
    )
  )

  $('#register_link').click(->
    $('#confirmation').modal('hide')
    $('#modal').modal()
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
    
    g.blockchain.onerror = (err) ->
      $('#connection').addClass('glyphicon-exclamation-sign').removeClass('glyphicon-signal')
      g.blockchain = null

    g.blockchain.onclose = ->
      $('#connection').addClass('glyphicon-exclamation-sign').removeClass('glyphicon-signal')
      g.blockchain = null

    g.blockchain.onmessage = (e) ->
      results = eval('(' + e.data + ')')
      amount = 0
      txid = results.x.hash

      $.each(results.x.out, (i, v) ->
        if (v.addr == g.address) 
          amount += v.value / 100000000
      )

      if amount >= g.amount
        $('#registered, #close').show()
        $('#request, #cancel').hide()
        register()

register = ->
  $.post('/users', $('#register').serialize())
  count = parseInt($('#users').html()) - 1
  $('#users').html(count.toString())
