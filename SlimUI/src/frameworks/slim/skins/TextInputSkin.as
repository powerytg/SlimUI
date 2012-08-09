package frameworks.slim.skins
{
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.SoftKeyboardEvent;
	
	import mx.core.mx_internal;
	
	import spark.components.supportClasses.StyleableTextField;
	import spark.skins.mobile.TextInputSkin;
	
	use namespace mx_internal;
	
	public class TextInputSkin extends spark.skins.mobile.TextInputSkin
	{
		/**
		 * @private
		 */
		[Embed(source='images/TextInput.png', scaleGridLeft="10", scaleGridRight="30", scaleGridTop="10", scaleGridBottom="30")]
		private var upBorderClass:Class;

		/**
		 * Constructor
		 */
		public function TextInputSkin()
		{
			super();
			borderClass = upBorderClass;			
		}
		
		/**
		 * @private
		 */
		override protected function createChildren():void
		{
			if (!border)
			{
				border = new borderClass();
				addChild(border);				
			}
			
			if (!textDisplay)
			{
				textDisplay = StyleableTextField(createInFontContext(StyleableTextField));
				textDisplay.styleName = this;
				textDisplay.editable = true;
				textDisplay.useTightTextBounds = false;
				addChild(textDisplay);
			}
		}
		
		/**
		 *  @private
		 */
		override protected function layoutContents(unscaledWidth:Number, 
												   unscaledHeight:Number):void
		{
			super.layoutContents(unscaledWidth, unscaledHeight);
			
			// position & size border
			if (border)
			{
				setElementSize(border, unscaledWidth + 16, unscaledHeight + 16);
				setElementPosition(border, -8, -8);
			}
		}
		
		/**
		 *  @private
		 */
		override protected function drawBackground(unscaledWidth:Number, unscaledHeight:Number):void
		{
			// Don't draw anything here
		}

	}
}