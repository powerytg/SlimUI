package frameworks.slim.activity
{
	import flash.display.BitmapData;
	import flash.display.StageOrientation;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.StageOrientationEvent;
	import flash.geom.Point;
	import flash.utils.getTimer;
	
	import frameworks.slim.activity.events.ActivityContainerEvent;
	import frameworks.slim.activity.events.ActivityDeckEvent;
	
	import mx.collections.ArrayCollection;
	import mx.core.mx_internal;
	import mx.effects.Parallel;
	import mx.effects.Sequence;
	import mx.events.EffectEvent;
	import mx.events.FlexEvent;
	
	import spark.components.Group;
	import spark.components.HGroup;
	import spark.components.Scroller;
	import spark.effects.Animate;
	import spark.effects.Fade;
	import spark.effects.animation.MotionPath;
	import spark.effects.animation.SimpleMotionPath;
	import spark.primitives.BitmapImage;
	
	use namespace mx_internal;
	
	/**
	 * This class is taken, modified and simplified from CrescentUI's ActivityClass.
	 * 
	 * It's specially targeting mobile devices, and support screen orientation.
	 * 
	 * While in portrait mode, only one activity is shown on screen, while on landscape mode
	 * two could be displayed along with eath other.
	 * 
	 * We no longer support transition methods. Only "optimized" method is built-in.
	 */
	public class ActivityDeck extends Group
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
		public function get gap():Number{
			return isTwinView ? LANDSCAPE_GAP : PORTRAIT_GAP;
		}
		
		/**
		 * Default gap
		 */
		public static var PORTRAIT_GAP:Number = 0;
		
		/**
		 * Default fullscreen gap
		 */
		public static var LANDSCAPE_GAP:Number = 0;
		
		/**
		 * @public
		 */
		[Bindable]
		public var currentActivities:ArrayCollection = new ArrayCollection();
		
		/**
		 * @public
		 */
		public var isTwinView:Boolean = false;
		
		/**
		 * @private
		 */
		private var isInTransitionMode:Boolean = false;
		
		/**
		 * @private
		 */
		[Bindable]
		public var activities:ArrayCollection = new ArrayCollection();
		
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
		private var flyInAnimation:Animate;
		
		/**
		 * @private
		 */
		private var flyInAndMoveAnimation:Parallel;

		/**
		 * @private
		 */
		private var replaceAnimation:Sequence;

		/**
		 * @private
		 * 
		 * removeActivity() animation
		 */
		private var flyOutAnimation:Animate;
		
		/**
		 * @private
		 */
		private var landscapeAnimation:Animate;

		/**
		 * @private
		 */
		private var portraitAnimation:Animate;

		/**
		 * @private
		 */
		private var targetingActivity:Activity;
		
		/**
		 * Constructor
		 */
		public function ActivityDeck()
		{
			super();
			
			addEventListener(Event.ADDED_TO_STAGE, onCreationComplete, false, 0, true);
		}
		
		/**
		 * @private
		 */
		private function onCreationComplete(evt:Event):void{
			addEventListener(Event.ADDED_TO_STAGE, onCreationComplete, false, 0, true);			
			addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
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
		 * @private
		 */
		private function onMouseDown(evt:MouseEvent):void{
			transitionMouseOrigin = new Point(evt.stageX, evt.stageY);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove, false, 0, true);
			stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp, false, 0, true);
			
			targetingActivity = currentActivities.getItemAt(0) as Activity;
		}
		
		/**
		 * @private
		 */
		private function onMouseMove(evt:MouseEvent):void{
			if(moving){
				evt.stopPropagation();
				var offset:Number = evt.stageX - transitionMouseOrigin.x;
				var currentProxy:BitmapImage = getProxyOf(targetingActivity);
				proxyGroup.horizontalScrollPosition = currentProxy.x - offset;
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
			enterTransitionMode();
			moving = true;
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
			var selectedIndex:Number = activities.getItemIndex(targetingActivity);
			var offset:Number = selectedIndex * (targetingActivity.width + gap) - proxyGroup.horizontalScrollPosition;
			
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
				
			target = activities.getItemAt(targetIndex) as Activity;						
			lookAt(target);
		}
		
		/**
		 * @private
		 */
		protected function enterTransitionMode():void{
			if(isInTransitionMode || activities.length == 0 || currentActivities.length == 0)
				return;
			
			isInTransitionMode = true;
			
			// Update the current visible activities. If in twin view mode, then
			// we need to update two activites, otherwise only update the current activity
			for each(var activity:Activity in currentActivities){
				updateProxy(activity);
			}
			
			contentGroup.visible = false;
			proxyGroup.visible = true;
		}
		
		/**
		 * @private
		 */
		protected function exitTransitionMode():void{
			if(!isInTransitionMode || activities.length == 0)
				return;
			
			isInTransitionMode = false;
			
			// If under twin view mode, then both the current activity and its next neighbor should be 
			// visible. Otherwise only the current activity is visible
			for each(var activity:Activity in activities){
				if(currentActivities.contains(activity)){
					activity.visible = true;
					activity.x = (activity.width + gap) * currentActivities.getItemIndex(activity);
				}
				else
					activity.visible = false;
			}
			
			contentGroup.visible = true;
			proxyGroup.visible = false;
		}
		
		/**
		 * @public
		 *
		 * Add an activity to the rear of the deck.   
		 */
		public function push(activity:Activity):void{
			setToCurrentActivity(activity);
			
			// Adjust size
			adjustActivitySize(activity);

			// Add to deck, and create a proxy
			activity.visible = false;
			contentGroup.addElement(activity);
			activities.addItem(activity);
			
			var proxy:BitmapImage = updateProxy(activity);
			proxyGroup.addElement(proxy);
			proxyGroup.invalidateSize();
			proxyGroup.validateNow();

			// Distance between the new activity to the current activity
			var dist:Number = (activities.length - 1) - activities.getItemIndex(currentActivities.getItemAt(currentActivities.length - 1) as Activity);
			
			// Decide whether to play animation
			var playAnimation:Boolean = isTwinView ? (dist <= 1) : (dist  == 0); 
			
			if(playAnimation){
				proxyGroup.autoLayout = false;
				
				enterTransitionMode();
				targetingActivity = activity;
				
				proxy.y = height;
				
				var mp:SimpleMotionPath = new SimpleMotionPath("y");
				mp.valueTo = 0;
				flyInAnimation = new Animate(proxy);
				flyInAnimation.motionPaths = Vector.<MotionPath>([mp]);
				flyInAnimation.addEventListener(EffectEvent.EFFECT_END, onFlyInAnimationEnd);
				flyInAnimation.play();
			}
			else{
				if(isTwinView)
					activity.visible = (dist <= 1);
				else
					activity.visible = (dist == 0);
				
				checkActivities();
			}
		}
		
		/**
		 * @private
		 */
		private function onFlyInAnimationEnd(evt:EffectEvent):void{
			flyInAnimation.removeEventListener(EffectEvent.EFFECT_END, onFlyInAnimationEnd);
			
			proxyGroup.autoLayout = true;

			exitTransitionMode();
			
			targetingActivity.visible = true;
			
			checkActivities();
		}
		
		/**
		 * @public
		 */
		public function pushAndLookAt(activity:Activity):void{
			// Adjust size
			adjustActivitySize(activity);
			
			// Add to deck, and create a proxy
			activity.visible = false;
			contentGroup.addElement(activity);
			activities.addItem(activity);
			
			var proxy:BitmapImage = updateProxy(activity);
			proxyGroup.addElement(proxy);
			proxyGroup.invalidateSize();
			proxyGroup.validateNow();

			// Distance between the new activity to the current activity
			var dist:Number = (activities.length - 1) - activities.getItemIndex(currentActivities.getItemAt(currentActivities.length - 1) as Activity);
			
			// Decide whether to play animation
			var needToMoveDeck:Boolean = isTwinView ? (activities.length > 2) : (dist != 0);
			
			if(!needToMoveDeck){
				// Directly "fly-in" the new activity
				proxyGroup.autoLayout = false;
				setToCurrentActivity(activity);
				
				enterTransitionMode();
				targetingActivity = activity;
				
				proxy.y = height;
				
				var ymp:SimpleMotionPath = new SimpleMotionPath("y");
				ymp.valueTo = 0;
				var amp:SimpleMotionPath = new SimpleMotionPath("alpha");
				amp.valueFrom = 0;
				amp.valueTo = 1;

				flyInAnimation = new Animate(proxy);
				flyInAnimation.motionPaths = Vector.<MotionPath>([ymp, amp]);
				flyInAnimation.addEventListener(EffectEvent.EFFECT_END, onFlyInAnimationEnd);
				flyInAnimation.play();
			}
			else{
				proxyGroup.autoLayout = false;
				proxy.y = height;
				enterTransitionMode();

				// First move the deck, and then push in the new activity
				var targetX:Number;
				if(isTwinView){
					targetX = activities.length == 1 ? 0 : proxy.x - gap - proxy.width;
				}
				else{
					targetX = proxy.x;
				}
				
				flyInAndMoveAnimation = new Parallel();
				flyInAndMoveAnimation.duration = 300;
				var deckAnimation:Animate = new Animate(proxyGroup);
				var deckMp:SimpleMotionPath = new SimpleMotionPath("horizontalScrollPosition");
				deckMp.valueTo = targetX;
				deckAnimation.motionPaths = Vector.<MotionPath>([deckMp]);
				
				flyInAndMoveAnimation.addChild(deckAnimation);
				
				var proxyMp:SimpleMotionPath = new SimpleMotionPath("y");
				proxyMp.valueTo = 0;
				var proxyAnimation:Animate = new Animate(proxy);
				proxyAnimation.motionPaths = Vector.<MotionPath>([proxyMp]);
				
				flyInAndMoveAnimation.addChild(proxyAnimation);
				flyInAndMoveAnimation.addEventListener(EffectEvent.EFFECT_END, onPushAndLookAtAnimationEnd);
				flyInAndMoveAnimation.play();
			}
		}
		
		/**
		 * @private
		 */
		private function onPushAndLookAtAnimationEnd(evt:EffectEvent):void{
			flyInAndMoveAnimation.removeEventListener(EffectEvent.EFFECT_END, onPushAndLookAtAnimationEnd);
			
			proxyGroup.autoLayout = true;
			
			exitTransitionMode();

			lookAt(activities.getItemAt(activities.length - 1) as Activity);
		}
		
		/**
		 * @private
		 */
		private var activitiesToRemove:Array = [];

		/**
		 * @private
		 */
		private var proxiesToRemove:Array = [];

		/**
		 * @public
		 * 
		 */
		public function replaceAt(activity:Activity, index:Number):void{
			// First of all, we need to remove the original object at index as well as all its sequencial activities.
			// If there's no object at the index (meaning, the length of the deck is smaller than index), then we do
			// a "push-and-look-at" action.
			if((activities.length - 1) < index){
				pushAndLookAt(activity);
				return;
			}
			
			if(activities.getItemAt(index) == activity){
				lookAt(activity);
				return;
			}
			
			// Now we need to mark all those that must be deleted, and then throw them out
			targetingActivity = activity;
			activitiesToRemove = [];
			proxiesToRemove = [];
			for(var i:uint = index; i < activities.length; i++){
				var oldActivity:Activity = activities.getItemAt(i) as Activity;
				if(oldActivity == activity)
					continue;
				
				activitiesToRemove.push(oldActivity);
				proxiesToRemove.push(getProxyOf(oldActivity));
			}
			
			// Enter transition mode
			enterTransitionMode();
			
			var needToCreateProxy:Boolean = false;
			if(!activities.contains(activity)){
				needToCreateProxy = true;
				// Add the new activity in, initialize it, and create its proxy image
				// Adjust size
				adjustActivitySize(activity);
				
				// Add to deck, and create a proxy
				contentGroup.addElement(activity);
				activities.addItem(activity);
			}
			
			// Turn off auto layout, and add the proxy to align with the first element to be deleted
			proxyGroup.autoLayout = false;
			var proxy:BitmapImage = updateProxy(activity);
			proxy.y = height;
			proxy.x = proxiesToRemove[0].x;
			
			if(needToCreateProxy)
				proxyGroup.addElement(proxy);				
			
			// Now move the deck to the proper position. If not under twin view mode,
			// then we align the deck to the first element of the to-be-deleted activity
			var	targetX:Number;
			if(!isTwinView)
				targetX = proxiesToRemove[0].x;
			else{
				targetX = activities.getItemAt(activities.getItemIndex(activitiesToRemove[0]) - 1).x;
			}
			
			replaceAnimation = new Sequence();
			replaceAnimation.duration = 500;
			
			if(targetX != proxyGroup.horizontalScrollPosition){
				var deckAnimation:Animate = new Animate(proxyGroup);
				var deckMp:SimpleMotionPath = new SimpleMotionPath("horizontalScrollPosition");
				deckMp.valueTo = targetX;
				deckAnimation.motionPaths = Vector.<MotionPath>([deckMp]);
				
				replaceAnimation.addChild(deckAnimation);				
			}
			
			// Old fellas fly-out animation
			var flyParallel:Parallel = new Parallel();
			var oldFlyOutAnimation:Animate = new Animate();
			oldFlyOutAnimation.targets = proxiesToRemove;
			var flyOutMp:SimpleMotionPath = new SimpleMotionPath("y");
			flyOutMp.valueTo = -height;
			var flyOutAlphaMp:SimpleMotionPath = new SimpleMotionPath("alpha");
			flyOutAlphaMp.valueTo = 0;
			oldFlyOutAnimation.motionPaths = Vector.<MotionPath>([flyOutMp, flyOutAlphaMp]);
			
			flyParallel.addChild(oldFlyOutAnimation);
			
			// Proxy fly-in animation
			proxy.alpha = 0;
			var proxyMp:SimpleMotionPath = new SimpleMotionPath("y");
			proxyMp.valueTo = 0;
			var proxyAlphaMp:SimpleMotionPath = new SimpleMotionPath("alpha");
			proxyAlphaMp.valueTo = 1;
			var proxyAnimation:Animate = new Animate(proxy);
			proxyAnimation.motionPaths = Vector.<MotionPath>([proxyMp, proxyAlphaMp]);
			
			flyParallel.addChild(proxyAnimation);
			
			replaceAnimation.addChild(flyParallel);
			
			replaceAnimation.addEventListener(EffectEvent.EFFECT_END, onReplaceAnimationEnd);
			replaceAnimation.play();
		}
		
		/**
		 * @private
		 */
		private function onReplaceAnimationEnd(evt:EffectEvent):void{
			replaceAnimation.removeEventListener(EffectEvent.EFFECT_END, onReplaceAnimationEnd);
			
			for each(var oldActivity:Activity in activitiesToRemove){
				activities.removeItemAt(activities.getItemIndex(oldActivity));
				contentGroup.removeElement(oldActivity);
			}
			
			for each(var oldProxy:BitmapImage in proxiesToRemove){
				proxyGroup.removeElement(oldProxy);
			}
			
			proxyGroup.autoLayout = true;
			
			exitTransitionMode();
			
			lookAt(targetingActivity);
		}
		
		/**
		 * @public
		 * 
		 * Select the target to be currentActivity, and focus on it.
		 * The currentActivity will always be aligned to left
		 */
		public function lookAt(target:Activity):void{
			// Switch to transition mode
			enterTransitionMode();
			
			// Remember the old activity
			var previousActivities:Array = [];
			if(currentActivities.length != 0){
				for each(var currentActivity:Activity in currentActivities){
					previousActivities.push(currentActivity);
				}
			}
			
			var index:Number = contentGroup.getElementIndex(target);
			if(isTwinView){
				if(index == activities.length - 1)
					index = Math.max(activities.length - 2, 0);
			}
			
			var targetProxy:BitmapImage = proxyGroup.getElementAt(index) as BitmapImage;
			
			if(proxyGroup.horizontalScrollPosition != targetProxy.x){
				var mp:SimpleMotionPath = new SimpleMotionPath("horizontalScrollPosition");
				mp.valueTo = targetProxy.x;
				
				var animate:Animate = new Animate(proxyGroup);
				animate.suspendBackgroundProcessing = true;
				animate.motionPaths = Vector.<MotionPath>([mp]);
				animate.duration = 200;
				animate.play();
				animate.addEventListener(EffectEvent.EFFECT_END, function(event:EffectEvent):void{
					setToCurrentActivity(target);
					exitTransitionMode();
					checkActivities();
					
				}, false, 0, true);
			}
			else{
				setToCurrentActivity(target);
				exitTransitionMode();
				checkActivities();
			}
		}
		
		/**
		 * @private
		 */
		private function adjustActivitySize(target:Activity):void{
			if(isTwinView)
				target.width = 	width / 2 - gap / 2;
			else
				target.width = 	width;
				
			target.height = height;
			target.dispatchEvent(new ActivityContainerEvent(ActivityContainerEvent.RESIZE_COMPLETE));
		}
		
		/**
		 * @private
		 *
		 * Create/update a proxy
		 */
		public function updateProxy(target:Activity):BitmapImage{
			var proxy:BitmapImage = null;
			
			try{
				if(target.width == 0 || target.height == 0){
					target.invalidateSize();
					target.validateNow();
				}

				proxy = getProxyOf(target);
				if(!proxy){
					proxy = new BitmapImage();
					target.invalidateDisplayList();
					target.validateNow();
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
			
			return proxy;
		}
		
		/**
		 * @public
		 * 
		 * Return the proxy image of the target. If target is not in activity deck, then return null
		 */
		public function getProxyOf(activity:Activity):BitmapImage{
			if(!activities.contains(activity))
				return null;
			
			var index:Number = activities.getItemIndex(activity);
			if(index >= proxyGroup.numElements)
				return null;
			
			return proxyGroup.getElementAt(index) as BitmapImage;
		}

		/**
		 * @public
		 */
		public function getNextActivity(target:Activity):Activity{
			if(!activities.contains(target))
				return null;
			
			var targetIndex:Number = activities.getItemIndex(target);
			
			if(targetIndex + 1 >= activities.length)
				return null;
			
			return activities.getItemAt(targetIndex + 1) as Activity;
		}
		
		/**
		 * @private
		 */
		public function enterTwinView():void{
			// While outsize of transition mode, change the proxyGroup's gap
			isTwinView = true;
			proxyGroup.gap = gap;
			
			// In landscape mode, 2 views could be visible along with each other (like in HBox),
			// First we enter transition mode, and resize the two wannabe views in background.
			isInTransitionMode = true;
			contentGroup.visible = false;
			proxyGroup.visible = true;

			var nextActivity:Activity;
			var currentActivity:Activity = currentActivities.getItemAt(0) as Activity;
			
			if(currentActivity){
				adjustActivitySize(currentActivity);
				nextActivity = getNextActivity(currentActivity);
				if(nextActivity)
					adjustActivitySize(nextActivity);
			}
			
			// Now all real activities are hidden, leaving their proxies visible on screen.
			// Play an animation by "sliding" the origianlly stacked "nextActivity" to right
			var proxies:Array = [];
			for(var i:uint = 0; i < proxyGroup.numElements; i++){
				var proxy:BitmapImage = proxyGroup.getElementAt(i) as BitmapImage;
				proxies.push(proxy);
			}
			
			var wmp:SimpleMotionPath = new SimpleMotionPath("width");
			wmp.valueTo = width / 2 - gap / 2;
			
			var hmp:SimpleMotionPath = new SimpleMotionPath("height");
			hmp.valueTo = height;
			
			landscapeAnimation = new Animate();
			landscapeAnimation.targets = proxies;
			landscapeAnimation.motionPaths = Vector.<MotionPath>([wmp, hmp]);
			landscapeAnimation.addEventListener(EffectEvent.EFFECT_END, onLandscapeAnimationEnd);
			landscapeAnimation.play();
		}

		/**
		 * @private
		 */
		private function onLandscapeAnimationEnd(evt:EffectEvent):void{
			landscapeAnimation.removeEventListener(EffectEvent.EFFECT_END, onLandscapeAnimationEnd);
			
			// Adjust the rest of activites' size
			for each(var activity:Activity in activities){
				if(!activity.visible)
					adjustActivitySize(activity);
				
				updateProxy(activity);
			}
			
			proxyGroup.invalidateSize();
			
			// Align to the current activity
			if(currentActivities.length != 0)
				lookAt(currentActivities.getItemAt(0) as Activity);
		}
		
		/**
		 * @private
		 */
		public function exitTwinView():void{
			if(!isTwinView)
				return;
				
			// While outsize of transition mode, change the proxyGroup's gap
			isTwinView = false;
			proxyGroup.gap = gap;
			
			// In portrait mode, only the current view is visible
			// First we enter transition mode, and resize the two wannabe views in background.
			isInTransitionMode = true;			
			contentGroup.visible = false;
			proxyGroup.visible = true;
			
			// Find out which view to adjust
			for each(var activity:Activity in currentActivities){
				adjustActivitySize(activity);
			}

			// Now all real activities are hidden, leaving their proxies visible on screen.
			// Play an animation by "sliding" the origianlly stacked "nextActivity" to right
			var proxies:Array = [];
			for(var i:uint = 0; i < proxyGroup.numElements; i++){
				var proxy:BitmapImage = proxyGroup.getElementAt(i) as BitmapImage;
				proxies.push(proxy);
			}
			
			var wmp:SimpleMotionPath = new SimpleMotionPath("width");
			wmp.valueTo = width;
			
			var hmp:SimpleMotionPath = new SimpleMotionPath("height");
			hmp.valueTo = height;

			portraitAnimation = new Animate();
			portraitAnimation.targets = proxies;
			portraitAnimation.motionPaths = Vector.<MotionPath>([wmp, hmp]);
			portraitAnimation.addEventListener(EffectEvent.EFFECT_END, onPortraitAnimationEnd);
			portraitAnimation.play();

		}

		/**
		 * @private
		 */
		private function onPortraitAnimationEnd(evt:EffectEvent):void{
			portraitAnimation.removeEventListener(EffectEvent.EFFECT_END, onPortraitAnimationEnd);
			
			// Exit transition mode
			exitTransitionMode();
			
			// Adjust the rest of activites' size
			for each(var activity:Activity in activities){
				if(!activity.visible)
					adjustActivitySize(activity);
				
				updateProxy(activity);
			}
			
			proxyGroup.invalidateSize();
			checkActivities();
		}

		/**
		 * @public
		 */
		public function checkActivities():void{
			for each(var activity:Activity in activities){
				activity.active = activity.visible;
			}
		}
		
		/**
		 * @public
		 */
		public function setToCurrentActivity(target:Activity):void{
			currentActivities.removeAll();
			
			if(isTwinView){
				var targetIndex:Number = activities.getItemIndex(target);
				if(targetIndex == activities.length - 1){
					if(activities.length > 1)
						currentActivities.addItem(activities.getItemAt(targetIndex - 1) as Activity);
					currentActivities.addItem(target);
				}
				else{
					currentActivities.addItem(target);
					currentActivities.addItem(activities.getItemAt(targetIndex + 1) as Activity);
				}
			}
			else
				currentActivities.addItem(target);
		}

		/**
		 * @public
		 */
		public function resize():void{
			if(!isInTransitionMode)
				enterTransitionMode();
			
			for each(var activity:Activity in activities){
				adjustActivitySize(activity);
				updateProxy(activity);
			}
			
			proxyGroup.invalidateSize();
			proxyGroup.invalidateDisplayList();
			proxyGroup.validateNow();
			
			for each(activity in activities){
				activity.dispatchEvent(new ActivityContainerEvent(ActivityContainerEvent.RESIZE_COMPLETE));
			}
			
			if(currentActivities.length != 0)
				lookAt(currentActivities.getItemAt(0) as Activity);
		}
		
	}
}