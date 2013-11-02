/*!
 * revigniter.com script JavaScript v1.0.1
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
*/var Slidebox={speed:1e3,timing:"ease",timeOutDur:1e3,transitionEnd:"TransitionEnd",panelShownHeight:"510px",openBtn:$("#open-button"),closeBtn:$("#close-button"),init:function(){"use strict";if(document.ontouchstart==null){this.down="touchstart MozTouchDown";this.up="touchend MozTouchRelease";this.move="touchmove MozTouchMove"}else{this.down="mousedown";this.up="mouseup";this.move="mousemove"}window.innerHeight>610&&(Slidebox.panelShownHeight="520");var e={WebkitTransition:"webkitTransitionEnd",MozTransition:"transitionend",transition:"transitionend"};this.transitionEnd=e[Modernizr.prefixed("transition")];Slidebox.openBtn.on("click",function(e){Slidebox.slideThePanel({thisEvt:e,panelHeight:Slidebox.panelShownHeight})});Slidebox.closeBtn.on("click",function(e){Slidebox.slideThePanel({thisEvt:e,panelHeight:"0px"})})},cancelEvent:function(e){"use strict";e.preventDefault()},doTransition:function(e){"use strict";e.evt&&e.evt.preventDefault();var t=e.ms===undefined?this.speed:e.ms,n=e.transitionTiming===undefined?"linear":e.transitionTiming,r="";if(Modernizr.csstransitions){if(e.objectDisplay){e.obj.css("display",e.objectDisplay);r=e.obj.css("display")}e.obj.css(Modernizr.prefixed("transition"),"all "+t.toString()+"ms "+n);e.obj.css(e.cssProps);$.isFunction(e.callback)&&e.obj.on(Slidebox.transitionEnd,function(){e.obj.off(Slidebox.transitionEnd);e.callback(e.evt,e.obj)})}else this.JQanimation(e)},JQanimation:function(e){"use strict";var t=e.ms===undefined?this.speed:e.ms;e.objectDisplay&&e.obj.css("display",e.objectDisplay);$.isFunction(e.callback)?e.obj.animate(e.cssProps,e.ms,"swing",e.callback):e.obj.animate(e.cssProps,e.ms,"swing")},slideThePanel:function(e){"use strict";var t=Slidebox.openBtn.css("display");window.setTimeout(function(){Slidebox.doTransition({evt:"",obj:$("#panelContent"),cssProps:{height:e.panelHeight},callback:Slidebox.slideEnd,ms:800,transitionTiming:Slidebox.timing})},0)},slideEnd:function(){"use strict";$(".slide-button").toggle()}};