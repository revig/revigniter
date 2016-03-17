/*!
 * revigniter.com script JavaScript v1.0.1
 * http://revigniter.com/
 *
 * Author: Ralf Bitter, rabit@revigniter.com
 *
 */



/*
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
*/
var Slidebox =
	{
		// INITIAL VALUES
		//
		speed: 1000,
		timing: "ease",
		timeOutDur: 1000,

		transitionEnd: "TransitionEnd",
		
		// SLIDE BOX HEIGHT FOR SMALL TABLETS IN LANDSCAPE MODE
		panelShownHeight: "510px",

		// BUTTON REFERENCES
		openBtn: $("#open-button"),
		closeBtn: $("#close-button"),

		
		
		init: function () {
			"use strict";
			// USE TOUCH EVENTS IF THEY'RE SUPPORTED, OTHERWISE MOUSE EVENTS
			// PREVENTDEFAULT() FOR LINKS DOES NOT WORK WITH MOUSEUP / MOUSEDOWN
			// YOU NEED TO USE CLICK IN COMBINATION WITH preventDefault()
			// THEN UP DOWN OR MOVE
			// if (document.hasOwnProperty('createTouch')) {
			if (document.ontouchstart == null) {
				this.down = "touchstart MozTouchDown";
				this.up = "touchend MozTouchRelease";
				this.move = "touchmove MozTouchMove";
			} else {
				this.down = "mousedown";
				this.up = "mouseup";
				this.move = "mousemove";
			}
			
			// SLIDE BOX HEIGHT FOR LARGE TABLETS AND DESKTOP
			if (window.innerHeight > 610) {
				Slidebox.panelShownHeight = "550";
			}

			// TRANSITION END NAME
			var transEndEventNames = {
			    'WebkitTransition' : 'webkitTransitionEnd',// Saf 6, Android Browser
			    'MozTransition'    : 'transitionend',      // only for FF < 15
			    'transition'       : 'transitionend'       // IE10, Opera, Chrome, FF 15+, Saf 7+
			};
			this.transitionEnd = transEndEventNames[ Modernizr.prefixed('transition') ];
			
			// THIS ATTRIBUTE IS NOW SET USING MEDIA QUERIES
			// Slidebox.openBtn.css('display', 'block');

			// ADD EVENT LISTENERS
			Slidebox.openBtn.on ( 'click', function(evt) {Slidebox.slideThePanel({thisEvt:evt, panelHeight:Slidebox.panelShownHeight});});
			Slidebox.closeBtn.on ( 'click', function(evt) {Slidebox.slideThePanel({thisEvt:evt, panelHeight:'0px'});});
		},
		
		// USE THIS FOR CLICK EVENTS
		// THEN USE this.down, this.up, this.move
		cancelEvent: function(event) {
			"use strict";
			event.preventDefault();
		},

		
		// GENERIC ANIMATION (TRANSITION)
		doTransition: function(paramsObj) {
			"use strict";
			if (paramsObj.evt) {
				paramsObj.evt.preventDefault();
			}

			// SPEED AND TIMING
			var ms = (paramsObj.ms === undefined) ? this.speed : paramsObj.ms,
				transitionTiming = (paramsObj.transitionTiming === undefined) ? "linear" : paramsObj.transitionTiming, unusedVar = "";
			
			// CHECK CSS CAPABILITIES
			if (Modernizr.csstransitions) {
				// DISPLAY TYPE
				if (paramsObj.objectDisplay) {
					paramsObj.obj.css("display", paramsObj.objectDisplay);
					// DIRTY HACK
					// DO NOT REMOVE, DOES NOT WORK WITHOUT
					unusedVar = paramsObj.obj.css("display");
				}

				// CSS TRANSITION
				paramsObj.obj.css(Modernizr.prefixed('transition'), "all "+ms.toString() +"ms "+transitionTiming);

				paramsObj.obj.css(paramsObj.cssProps);
				
				// CALLBACK
				if ($.isFunction(paramsObj.callback)) {
					paramsObj.obj.on (Slidebox.transitionEnd,function(){
						paramsObj.obj.off (Slidebox.transitionEnd);
						paramsObj.callback(paramsObj.evt, paramsObj.obj);
					});
				}

			} else {
				// ANIMATE USING JQUERY
				this.JQanimation(paramsObj);
			}
		},
		
		
		
		// FALLBACK JQUERY ANIMATION
		JQanimation: function(paramsObj) {
			"use strict";
			// SPEED
			var ms = (paramsObj.ms === undefined) ? this.speed : paramsObj.ms;
			
			// DISPLAY TYPE
			if (paramsObj.objectDisplay) {
				paramsObj.obj.css("display", paramsObj.objectDisplay);
			}

			// CALLBACK
			if ($.isFunction(paramsObj.callback)) {
				paramsObj.obj.animate(paramsObj.cssProps, paramsObj.ms, 'swing', paramsObj.callback);
			} else {
				paramsObj.obj.animate(paramsObj.cssProps, paramsObj.ms, 'swing');
			}

		},


		slideThePanel: function(paramsObj) {
			"use strict";
			// DIRTY HACK
			// DO NOT REMOVE, DOES NOT WORK WITHOUT IN FIREFOX
			var unusedVar = Slidebox.openBtn.css("display");
			window.setTimeout(function() {
				Slidebox.doTransition({evt:"",
				obj:$("#panelContent"), 
				cssProps:{'height': paramsObj.panelHeight}, 
				callback:Slidebox.slideEnd, 
				ms:800, 
				transitionTiming:Slidebox.timing
			});
			}, 0);
		},
		
		
		
		slideEnd: function() {
			"use strict";
			$(".slide-button").toggle();
		}
		
		
	};
