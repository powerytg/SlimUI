package frameworks.slim.skins
{
	import frameworks.slim.components.supportClasses.HSliderHighlight;
	
	import spark.components.Button;
	import spark.skins.mobile.HSliderSkin;
	
	public class HSliderSkin extends spark.skins.mobile.HSliderSkin
	{
		/**
		 * @private
		 */
		public var highlight:HSliderHighlight;
		
		/**
		 * Constructor
		 */
		public function HSliderSkin()
		{
			super();
			thumbSkinClass = HSliderThumbSkin;
			trackSkinClass = HSliderTrackSkin;
		}

		/**
		 * @private
		 */
		override protected function createChildren():void{
			track = new Button();
			track.setStyle("skinClass", trackSkinClass);
			addChild(track);

			// Create a highlight
			highlight = new HSliderHighlight();
			addChild(highlight);

			thumb = new Button();
			thumb.setStyle("skinClass", thumbSkinClass);
			addChild(thumb);		
		}
		
		/**
		 *  @private
		 */ 
		override protected function layoutContents(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.layoutContents(unscaledWidth, unscaledHeight);
			
			// Layout highlight
			setElementPosition(highlight, 41, track.y + 1);
		}
	}
}