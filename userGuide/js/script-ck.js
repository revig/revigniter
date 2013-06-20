/*!
 * revigniter.com script JavaScript v1.0
 * http://revigniter.com/
 *
 * Author: Ralf Bitter, rabit@revigniter.com
 *
 *//*
 * Object: Slidebox
 *
 *   Animate navigation panel.
 *
 * Parameters:
 *
 *   -
 *
 * Returns:
 *
 *   -
 *
*/var Slidebox={speed:1e3,timing:"ease",timeOutDur:1e3,vP:"",transitionEnd:"TransitionEnd",panelShownHeight:"520px",openBtn:$("#open-button"),closeBtn:$("#close-button"),init:function(){"use strict";if(document.ontouchstart==null){this.down="touchstart MozTouchDown";this.up="touchend MozTouchRelease";this.move="touchmove MozTouchMove"}else{this.down="mousedown";this.up="mouseup";this.move="mousemove"}if($.browser.webkit){this.vP="-webkit-";this.transitionEnd="webkitTransitionEnd"}else if($.browser.msie){this.vP="-ms-";this.transitionEnd="msTransitionEnd"}else if($.browser.mozilla){this.vP="-moz-";this.transitionEnd="transitionend"}else if($.browser.opera){this.vP="-o-";this.transitionEnd="oTransitionEnd"}Slidebox.openBtn.css("display","block");Slidebox.openBtn.on("click",function(e){Slidebox.slideThePanel({thisEvt:e,panelHeight:Slidebox.panelShownHeight})});Slidebox.closeBtn.on("click",function(e){Slidebox.slideThePanel({thisEvt:e,panelHeight:"0px"})})},cancelEvent:function(e){"use strict";e.preventDefault()},doTransition:function(e){"use strict";e.evt&&e.evt.preventDefault();var t=typeof e.ms=="undefined"?this.speed:e.ms,n=typeof e.transitionTiming=="undefined"?"linear":e.transitionTiming;if(Modernizr.csstransitions){if(e.objectDisplay){e.obj.css("display",e.objectDisplay);var r=e.obj.css("display")}e.obj.css(e.pvP+"transition","all "+t.toString()+"ms "+n);e.obj.css(e.cssProps);$.isFunction(e.callback)&&e.obj.on(Slidebox.transitionEnd,function(){e.obj.off(Slidebox.transitionEnd);e.callback(e.evt,e.obj,e.pvP)})}else this.JQanimation(e)},JQanimation:function(e){"use strict";var t=typeof e.ms=="undefined"?this.speed:e.ms;e.objectDisplay&&e.obj.css("display",e.objectDisplay);$.isFunction(e.callback)?e.obj.animate(e.cssProps,e.ms,"swing",e.callback):e.obj.animate(e.cssProps,e.ms,"swing")},slideThePanel:function(e){"use strict";var t=Slidebox.openBtn.css("display");window.setTimeout(function(){Slidebox.doTransition({evt:"",pvP:Slidebox.vP,obj:$("#panelContent"),cssProps:{height:e.panelHeight},callback:Slidebox.slideEnd,ms:800,transitionTiming:Slidebox.timing})},0)},slideEnd:function(){"use strict";$(".slide-button").toggle()}};