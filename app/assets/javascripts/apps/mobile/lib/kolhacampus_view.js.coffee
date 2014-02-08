getOffsetTop = (el) ->
  val = 0
  if el.offsetParent
    loop
      val += el.offsetTop
      break unless el = el.offsetParent
  val

class KolHacampus.ScrollableView extends Batman.View

  constructor: ->
    super
    @checks = 0
    @scrollCallback = @loadVisibleImages.bind(@)

  ready: ->
    re = new RegExp('scroll-container', 'g')
    @set 'hasScroll', re.test(@get('html'))
    @attchScrollEvent() if @get('hasScroll')

  viewDidAppear: ->
    @findImages() if @get('hasScroll')

  viewWillDisappear: ->
    @detachScrollEvent() if @get('hasScroll')

  attchScrollEvent: ->
    @scrollContainer = @get('node').querySelector('.scroll-container')
    @scrollContainer.addEventListener('scroll', @scrollCallback, false)

  detachScrollEvent: ->
    @scrollContainer.removeEventListener('scroll', @scrollCallback)

  findImages: ->
    @images = @get('node').querySelectorAll('img[data-src]')
    if @images is null or (@images.length < 10 and @checks < 10)
      clearTimeout(@timer) if @timer
      @timer = setTimeout(=>
        @checks += 1
        @findImages()
      ,100)
    else
      @loadVisibleImages()

  loadVisibleImages: ->
    scrollY = @scrollContainer.scrollTop
    pageHeight = window.innerHeight || document.documentElement.clientHeight
    range = {
      min: scrollY - 100,
      max: scrollY + pageHeight + 100
    }
    images = @get('node').querySelectorAll('img[data-src]')
    for img in images
      imagePosition = getOffsetTop(img)
      imageHeight = img.height || 0
      if ((imagePosition >= range.min - imageHeight) && (imagePosition <= range.max))
        src = img.getAttribute('data-src')
        img.setAttribute('src', src) unless src is null
        img.removeAttribute('data-src')
