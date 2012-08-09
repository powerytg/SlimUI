package frameworks.slim.activity
{
	import flash.display.BitmapData;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.utils.getTimer;
	
	import frameworks.slim.activity.events.ActivityContainerEvent;
	import frameworks.slim.activity.events.ActivityDeckEvent;
	
	import mx.collections.ArrayCollection;
	import mx.core.mx_internal;
	import mx.effects.Parallel;
	import mx.events.EffectEvent;
	import mx.events.FlexEvent;
	
	import spark.components.Group;
	import spark.components.HGroup;
	import spark.components.Scroller;
	import spark.effects.Animate;
	import spark.effects.Fade;
	import spark.effects.Move;
	import spark.effects.animation.MotionPath;
	import spark.effects.animation.SimpleMotionPath;
	import spark.primitives.BitmapImage;
	
	use namespace mx_internal;
	
	/**
	 * When the activity selection has changed
	 */
	[Event(name="activityChanged", type="frameworks.slim.activity.events.ActivityDeckEvent")]

	/**
	 * Scrolling begin
	 */
	[Event(name="transitionBegin", type="frameworks.slim.activity.events.ActivityDeckEvent")]

	/**
	 * Scrolling end
	 */
	[Event(name="transitionEnd", type="frameworks.slim.activity.events.ActivityDeckEvent")]

	/**
	 * Scrolling
	 */
	[Event(name="transitionUpdate", type="frameworks.slim.activity.events.ActivityDeckEvent")]
	
	/**
	 * Simplified ActivityDeck from Cavalier.
	 * 
	 * The SlideDeck behaves just like the ActivityDeck in SlimUI, except that it doesn't
	 * have the twin mode, nor can switch between landscape and portrait mode.
	 * 
	 * Also the SlideDeck shows part of the neighbor activity, though it's not updated until being swiped upon.
	 * 
	 * There is only one activity being "selected" per time, in contrast to ActivityDeck which could 
	 * have two current activities.
	 * 
	 * Note that this class has removed several capabilities from the original CrescentUI's ActivityDeck. Namely, 
	 * it cannot delete activities or enter full-screen mode. All activities must be created at the beginning.
	 */
	public class SlideDeck extends Group
	{
		/**
		 * The proxy group
		 */
		public var proxyGroup:HGroup;
		
		/**
		 * The content group
		 */
		public var contentGroup:Group;
		
		/**
		 * Gap between activities
		 */
		public var gap:Number = 10;
		
		/**
		 * @public
		 */
		[Bindable]
		public var currentActivity:Activity;
		
		/**
		 * @private
		 */
		[Bindable]
		public var activities:ArrayCollection = new ArrayCollection();
		
		/**
		 * @public
		 */
		public var isInTransitionMode:Boolean = false;
		
		/**
		 * @private
		 */
		private var mouseDetectionThreshold:Number = 15;
		
		/**
		 * @private
		 */
		private var spaceTransitionThreshold:Number = 60;
		
		/**
		 * @private
		 */
		private var transitionMouseOrigin:Point;
		
		/**
		 * @private
		 */
		private var moving:Boolean = false;
		
		/**
		 * @private
		 */
		private var longDragThreshold:Number = 100;
		
		/**
		 * @private
		 * 
		 * The timer to count the time of finger being pushed down
		 */
		private var mouseDownStartTime:Number;
		
		/**
		 * @private
		 */
		private var removeAllAnimation:Parallel;
		
		/**
		 * Constructor
		 */
		public function SlideDeck()
		{
			super();
			
			addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown, false, 0, true);
		}
		
		/**
		 * @private
		 */
		override protected function createChildren():void{
			super.createChildren();
			
			// Proxy group
			// Create proxy group
			var proxyScroller:Scroller = new Scroller();
			proxyScroller.percentWidth = 100;
			proxyScroller.percentHeight = 100;
			addElement(proxyScroller);
			
			proxyGroup = new HGroup();
			proxyGroup.gap = gap;
			proxyScroller.viewport = proxyGroup;
			
			// Turn off explict scrolling
			proxyScroller.setStyle("horizontalScrollPolicy", "off");
			proxyScroller.setStyle("verticalScrollPolicy", "off");
			
			// Content group
			contentGroup = new Group();
			contentGroup.percentWidth = 100;
			contentGroup.percentHeight = 100;
			addElement(contentGroup);
		}
		
		/**
		 * @public
		 */
		public function get selectedIndex():Number{
			if(!currentActivity)
				return -1;
			else
				return activities.getItemIndex(currentActivity);
		}
		
		/**
		 * @private
		 */
		private function onMouseDown(evt:MouseEvent):void{
			if(activities.length == 0)
				return;
			
			evt.stopPropagation();
			
			transitionMouseOrigin = new Point(evt.stageX, evt.stageY);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove, false, 0, true);
			stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp, false, 0, true);
		}
		
		/**
		 * @private
		 */
		private function onMouseMove(evt:MouseEvent):void{
			if(moving){
				evt.stopPropagation();
				var offset:Number = evt.stageX - transitionMouseOrigin.x;
				var currentProxy:BitmapImage = proxyGroup.getElementAt(selectedIndex) as BitmapImage;
				proxyGroup.horizontalScrollPosition = currentProxy.x - offset;
				
				var e:ActivityDeckEvent = new ActivityDeckEvent(ActivityDeckEvent.TRANSITION_UPDATE);
				e.horizontalScrollPercentage = proxyGroup.horizontalScrollPosition / proxyGroup.contentWidth;
				dispatchEvent(e);
			}
			else{
				var distX:Number = Math.abs(evt.stageX - transitionMouseOrigin.x);
				var distY:Number = Math.abs(evt.stageY - transitionMouseOrigin.y);
				if(distX > mouseDetectionThreshold && distX > distY)
					beginTransition();				
			}
		}
		
		/**
		 * @private
		 */
		private function onMouseUp(evt:MouseEvent):void{
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			
			var offset:Number = evt.stageX - transitionMouseOrigin.x;
			
			if(moving)
				endTransition(offset);
		}
		
		/**
		 * @private
		 */
		private function beginTransition():void{
			updateProxy(currentActivity);
			moving = true;
			enterTransitionMode();
			
			mouseDownStartTime = flash.utils.getTimer();
		}
		
		/**
		 * @private
		 * 
		 * The distance is the accumulated offset in vertical direction
		 */
		private function endTransition(distance:Number):void{
			moving = false;
			var targetIndex:Number;
			var target:Activity = null;
			
			// The finger offset
			var offset:Number = selectedIndex * currentActivity.width - proxyGroup.horizontalScrollPosition;
			
			var mouseDownTime:Number = flash.utils.getTimer() - mouseDownStartTime;
			if(mouseDownTime > longDragThreshold){
				// Long drag. In this case, the screen will move only move until the y offset is larger than spaceTransitionThreshold
				if(Math.abs(distance) < spaceTransitionThreshold)
					targetIndex = selectedIndex;
				else if(offset < 0)
					targetIndex = Math.min(activities.length - 1, selectedIndex + 1);
				else
					targetIndex = Math.max(0, selectedIndex - 1);				
			}
			else{
				// Quick swipe. In this case, the screen will move in the finger's direction
				if(offset < 0)
					targetIndex = Math.min(activities.length - 1, selectedIndex + 1);
				else
					targetIndex = Math.max(0, selectedIndex - 1);								
			}
			
			// Find the nearest screen
			target = activities.getItemAt(targetIndex) as Activity;
			lookAt(target);
		}
		
		/**
		 * @private
		 */
		public function enterTransitionMode():void{
			if(isInTransitionMode || activities.length == 0 || !currentActivity)
				return;
			
			isInTransitionMode = true;
			
			for each(var activity:Activity in activities){
				var proxy:BitmapImage = getProxyOf(activity);
				proxy.visible = true;
			}
			
			contentGroup.visible = false;
			dispatchEvent(new ActivityDeckEvent(ActivityDeckEvent.TRANSITION_BEGIN));
		}
		
		/**
		 * @private
		 */
		public function exitTransitionMode():void{
			if(!isInTransitionMode)
				return;
			
			isInTransitionMode = false;
			
			for each(var activity:Activity in activities){
				var proxy:BitmapImage = getProxyOf(activity);
				if(activity == currentActivity){
					activity.visible = true;
					proxy.visible = false;
				}
				else{
					activity.visible = false;
					proxy.visible = true;
				}
			}
			
			contentGroup.visible = true;
			dispatchEvent(new ActivityDeckEvent(ActivityDeckEvent.TRANSITION_END));
		}

		/**
		 * @protected
		 * 
		 * Get the activity that most likely to be in the middle of screen based
		 * on the horizontalScrollPosition value of the scroller
		 */
		public function getNearestActivity():Activity{
			var minDist:Number = -1;
			var nearestIndex:Number;
			
			// Find the nearest activity
			for (var i:uint = 0; i < proxyGroup.numElements; i++){
				var proxy:BitmapImage = proxyGroup.getElementAt(i) as BitmapImage;
				var dist:Number = Math.abs(proxy.x - proxyGroup.horizontalScrollPosition);
				
				if(minDist == -1 || dist < minDist){
					minDist = dist;
					nearestIndex = i;
				}
			}
			
			return contentGroup.getElementAt(nearestIndex) as Activity;
		}
		
		/**
		 * @public
		 * 
		 * Add an activity to the rear of the queue. This method does not auto-focus at
		 * the newly added activity, nor does it change the currentActivity property
		 */
		public function addActivity(activity:Activity):void{
			contentGroup.addElement(activity);
			activities.addItem(activity);
			adjustActivityWidth(activity);
			
			// Create an initial proxy
			activity.addEventListener(FlexEvent.CREATION_COMPLETE, onActivityInitialized, false, 0, true);
			
			// If this is the only activity, then set it to be the current activity
			if(contentGroup.numElements == 1){
				currentActivity = activity;
			}
		}
		
		/**
		 * @public
		 * 
		 * Select the target to be currentActivity, and focus on it
		 */
		public function lookAt(target:Activity):void{
			// Switch to transition mode
			enterTransitionMode();
			
			// Remember the old activity
			var previousActivity:Activity = currentActivity;
			
			var index:Number = contentGroup.getElementIndex(target);
			var targetProxy:BitmapImage = proxyGroup.getElementAt(index) as BitmapImage;
			var	targetX:Number = targetProxy.x - target.x;
			
			var evt:ActivityDeckEvent = new ActivityDeckEvent(ActivityDeckEvent.ACTIVITY_CHANGED);
			evt.selectedActivity = target;
			
			if(proxyGroup.horizontalScrollPosition != targetX){
				var mp:SimpleMotionPath = new SimpleMotionPath("horizontalScrollPosition");
				mp.valueTo = targetX;
				
				var animate:Animate = new Animate(proxyGroup);
				animate.suspendBackgroundProcessing = true;
				animate.motionPaths = Vector.<MotionPath>([mp]);
				animate.duration = 200;
				animate.play();
				animate.addEventListener(EffectEvent.EFFECT_END, function(event:EffectEvent):void{
					currentActivity = target;
					exitTransitionMode();
					dispatchEvent(evt);
					
					// If the activity has changed, deactive the old one and active the new one
					if(previousActivity && previousActivity != currentActivity){
						previousActivity.active = false;
						currentActivity.active = true;
					}
					
				}, false, 0, true);
			}
			else{
				currentActivity = target;
				exitTransitionMode();
				dispatchEvent(evt);
				
				// If the activity has changed, deactive the old one and active the new one
				if(previousActivity && previousActivity != currentActivity){
					previousActivity.active = false;
					currentActivity.active = true;
				}
				
			}
		}
		
		/**
		 * @public
		 */
		public function removeAll():void{
			if(activities.length == 0)
				return;
			
			enterTransitionMode();
			
			// Play "throw out" animation
			removeAllAnimation = new Parallel(proxyGroup);
			var move:Move = new Move();
			move.yTo = -height;
			removeAllAnimation.addChild(move);
			
			var fade:Fade = new Fade();
			fade.alphaTo = 0;
			removeAllAnimation.addChild(fade);
			removeAllAnimation.addEventListener(EffectEvent.EFFECT_END, onRemoveAllAnimationEnd);
			
			removeAllAnimation.play();
		}
		
		/**
		 * @private
		 */
		private function onRemoveAllAnimationEnd(evt:EffectEvent):void{
			removeAllAnimation.removeEventListener(EffectEvent.EFFECT_END, onRemoveAllAnimationEnd);
			removeAllAnimation = null;
			
			for each(var activity:Activity in activities){
				activity.destroy();
			}
			
			activities.removeAll();
			proxyGroup.removeAllElements();
			contentGroup.removeAllElements();
			
			proxyGroup.y = 0;
			proxyGroup.alpha = 1;
			
			exitTransitionMode();
		}
		
		/**
		 * @private
		 */
		private function onActivityInitialized(evt:FlexEvent):void{
			var activity:Activity = evt.target as Activity;
			activity.removeEventListener(FlexEvent.CREATION_COMPLETE, onActivityInitialized);
			updateProxy(activity);
		}
		
		/**
		 * @private
		 */
		private function adjustActivityWidth(target:Activity):void{
			target.width = 	getDefaultActivityWidth();	
			target.height = height;
			
			target.x = 0;
		}
		
		/**
		 * @private
		 */
		private function getDefaultActivityWidth():Number{
			return Math.ceil(width * 0.9);
		}
		
		/**
		 * @private
		 */
		private function getDefaultActivityHeight():Number{
			return height;
		}
		
		/**
		 * @private
		 *
		 * Create/update a proxy
		 */
		public function updateProxy(target:Activity):void{
			try{
				// Lookup if the proxy already exists
				var index:Number = activities.getItemIndex(target);
				var proxy:BitmapImage;
				
				if(target.width == 0 || target.height == 0){
					target.validateSize();
				}
				
				if(proxyGroup.numElements == contentGroup.numElements)
					proxy = proxyGroup.getElementAt(index) as BitmapImage;
				else{
					proxy = new BitmapImage();
					if(proxyGroup.numElements <= index)
						proxyGroup.addElement(proxy);
					else
						proxyGroup.addElementAt(proxy, index);
				}
				
				proxy.width = target.width;
				proxy.height = target.height;
				
				var bmp:BitmapData = new BitmapData(proxy.width, proxy.height, true, 0x000000);			
				bmp.draw(target);
				
				// Update proxy thumbnail
				proxy.source = bmp;
				
				var evt:ActivityContainerEvent = new ActivityContainerEvent(ActivityContainerEvent.PROXY_UPDATED);
				evt.proxy = proxy;
				target.dispatchEvent(evt);
			}
			catch(e:Error){
				// Ignore any exceptions
				trace(e.getStackTrace());
			}
			
			if(target == currentActivity)
				proxy.visible = false;
		}
		
		/**
		 * @public
		 */
		public function getProxyOf(activity:Activity):BitmapImage{
			return proxyGroup.getElementAt(activities.getItemIndex(activity)) as BitmapImage;
		}
		
		/**
		 * @public
		 */
		public function resize():void{
			if(!currentActivity)
				return;
			
			enterTransitionMode();
			
			for each(var activity:Activity in activities){
				adjustActivityWidth(activity);
				updateProxy(activity);
			}
			
			proxyGroup.invalidateSize();
			proxyGroup.invalidateDisplayList();
			proxyGroup.validateNow();
			
			for each(activity in activities){
				activity.dispatchEvent(new ActivityContainerEvent(ActivityContainerEvent.RESIZE_COMPLETE));
			}
			
			lookAt(currentActivity);
		}
		
	}
}