/**
 * requestAnimationFrame and cancel polyfill
 */
(function() {
  var lastTime = 0,
      vendors = ['ms', 'moz', 'webkit', 'o'],
      x, l = vendors.length;
  for(x = 0, l = vendors.length; x < l && !window.requestAnimationFrame; x += 1) {
    window.requestAnimationFrame = window[vendors[x]+'RequestAnimationFrame'];
    window.cancelAnimationFrame = window[vendors[x]+'CancelAnimationFrame'] || window[vendors[x]+'CancelRequestAnimationFrame'];
  }

  if (!window.requestAnimationFrame) {
    window.requestAnimationFrame = function(callback, element) {
      var currTime = new Date().getTime(),
          timeToCall = Math.max(0, 16 - (currTime - lastTime)),
          id = window.setTimeout(function() { callback(currTime + timeToCall); },
              timeToCall);
      lastTime = currTime + timeToCall;
      return id;
    };
  }

  if (!window.cancelAnimationFrame){
    window.cancelAnimationFrame = function(id) {
      clearTimeout(id);
    };
  }
}());

(function(){

  var _this, PullToRefresh;

  /**
   * Touch gesture handler. Routes the relevant touch event to its handler.
   * @param ev touch gesture event
   */
  function onGesture(ev){
    switch(ev.type){
      case 'dragdown':
        _this.onDrag(ev);
        break;
      case 'release':
        _this.onRelease(ev);
        break;
      case 'tap':
        _this.resetTarget();
        break;
    }
  }
  /**
   * Create a new pull to refresh instance
   * @param target DOM element which is pulled down to refresh its content
   * @param container target element containing DOM element
   * @param handler release event handler
   * @param breakpoints optional breakpoints object with top, bottom and handler breakpoints
   * @constructor
   */
  PullToRefresh = window.PullToRefresh = function(target, container, handler, breakpoints) {
    _this = this;
    this.container = container;
    this.target = target;
    this.icon = this.target.find('.icon');
    this.handler = handler;
    this.handleOnRelase = false;
    this.touchEventsBound = false;
    this.breakpoints = $.extend({
      top: 120,
      bottom: 0,
      handler: 60
    }, breakpoints || {});
    this.targetY = 0;
    this.animation = false;
    this.Hammer = Hammer(document.body);
    this.bindTouchEvents();
    //this.container.on('scroll', this.onScroll.bind(this));
  };

  PullToRefresh.prototype = {
    /**
     * Handle scroll target events.
     * When target is scrolled to top, binds touch events to handle pull
     * @param ev scroll event
     */
    onScroll: function(ev){
      if(ev.target.scrollTop < 10 && !this.touchEventsBound){
        this.bindTouchEvents();
      } else if(this.touchEventsBound && ev.target.scrollTop > 70){
        this.unbindTouchEvents();
      }
    },
    /**
     * Drag event handler. Animates target element downwards when pulled
     * @param ev down gesture DOM event
     */
    onDrag: function(ev){
      var scrollY = this.container[0].scrollTop;
      if(ev.gesture.direction !== 'down' || scrollY > 5){
        return;
      }
      ev.gesture.preventDefault();
      if(ev.gesture.deltaY <= this.breakpoints.top){
        this.dragTarget(ev.gesture.deltaY * Math.min(1, Math.max(ev.gesture.velocityY, 1.6)));
      } else {
        cancelAnimationFrame(this.animation);
      }
    },
    /**
     * Release event handler. Called when target element has been released by user.
     * Triggers handler callback if target element has been pulled beyond the designated breakpoint
     * @param ev release gesture DOM event
     */
    onRelease: function(ev){
      if(ev.gesture.direction !== 'down'){
        return;
      }
      ev.gesture.preventDefault();
      var min = this.handleOnRelase && this.targetY >= this.breakpoints.handler ? this.breakpoints.handler : this.breakpoints.bottom;
      this.releaseTarget(min);
    },
    /**
     * Handle target element y position during drag event.
     * @param y vertical position of target element
     */
    dragTarget: function(y){
      this.targetY = Math.min(y, this.breakpoints.top);
      if(this.targetY <= this.breakpoints.top){
        this.animation = requestAnimationFrame(this.changeTargetPosition.bind(this, this.targetY));
        if(y > this.breakpoints.handler && !this.handleOnRelase){
          this.target.addClass('breakpoint');
          this.icon.removeClass('up').addClass('down');
          this.handleOnRelase = true;
        }
      }
    },
    /**
     * Handle target element y position when it has been released
     * @param min target y position to animated to upon release
     */
    releaseTarget: function(min){
      if(this.targetY >= min){
        this.animation = requestAnimationFrame(function(){
          this.targetY = Math.max(min, this.targetY - 5);
          this.changeTargetPosition(this.targetY);
          if(this.targetY > min){
            this.releaseTarget(min);
          } else {
            this.cancelAnimation();
            if(min === this.breakpoints.handler){
              this.triggerHandler();
            } else if (min === this.breakpoints.bottom){
              this.target.removeClass('breakpoint loading');
              this.icon.addClass('up');
              this.target.attr('style', null);
              this.target.css({top:'1px'});
            }
          }
        }.bind(this));
      }
    },
    /**
     * Resets target element to zero y position.
     */
    resetTarget: function(){
      this.releaseTarget(this.breakpoints.bottom);
      //this.unbindTouchEvents();
    },
    /**
     * Bind touch events to scroll target element
     */
    bindTouchEvents: function(){
      this.targetY = 0;
      this.Hammer.on("dragdown release tap", onGesture);
      this.touchEventsBound = true;
    },
    /**
     * Unbinds touch events from target once drag and release have been complete.
     * This makes sure that normal scroll is unhindered by touch event listeners.
     */
    unbindTouchEvents: function(){
      this.targetY = 0;
      this.Hammer.off("dragdown release tap", onGesture);
      this.touchEventsBound = false;
    },
    /**
     * Changes target y position to given height using CSS transitions
     * @param y target y position
     */
    changeTargetPosition: function(y){
      var css;
      if(Modernizr.csstransforms3d) {
        css = [
          'transform:translate3d(0,'+y+'px,0) scale3d(1,1,1)',
          '-o-transform:translate3d(0,'+y+'px,0) scale3d(1,1,1)',
          '-ms-transform:translate3d(0,'+y+'px,0) scale3d(1,1,1)',
          '-moz-transform:translate3d(0,'+y+'px,0) scale3d(1,1,1)',
          '-webkit-transform:translate3d(0,'+y+'px,0) scale3d(1,1,1)'
        ].join(';');
      }
      else if(Modernizr.csstransforms) {
        css = [
          'transform:translate(0,'+y+'px)',
          '-o-transform:translate(0,'+y+'px)',
          '-ms-transform:translate(0,'+y+'px)',
          '-moz-transform:translate(0,'+y+'px)',
          '-webkit-transform:translate(0,'+y+'px)'
        ].join(';');
      } else {
        css = 'top:'+y+'px';
      }
      if(y === 0){
        this.target.attr('style',null);
      } else {
        this.target.attr('style',css);
      }
    },
    /**
     * Triggers target release event handler once target has been release beyond the designated breakpoint.
     */
    triggerHandler: function(){
      this.target.addClass('loading').removeClass('breakpoint');
      this.icon.removeClass('down');
      this.handler.call(this);
    },
    /**
     * Cancels existing frame animation requests
     */
    cancelAnimation: function(){
      if(this.animation){
        cancelAnimationFrame(this.animation);
        this.animation = false;
      }
    },
    /**
     * Stops event listeners that trigger pull to refresh.
     * Can be used to cancel pull-to-refresh functionality.
     */
    cancel: function(){
      this.resetTarget();
      this.unbindTouchEvents();
      //this.container.off('scroll');
    }
  };
}());