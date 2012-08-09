package frameworks.slim.skins
{   
	import flash.display.DisplayObject;
	
	import mx.core.ClassFactory;
	import mx.core.mx_internal;
	
	import spark.components.DataGroup;
	import spark.components.List;
	import spark.components.Scroller;
	import spark.layouts.HorizontalAlign;
	import spark.layouts.VerticalLayout;
	import spark.skins.mobile.supportClasses.MobileSkin;

	use namespace mx_internal;
	
	public class ListSkin extends MobileSkin
	{
		/**
		 *  Constructor.
		 */
		public function ListSkin()
		{
			super();
			
			minWidth = 112;
		}
		
		/** 
		 *  @copy spark.skins.spark.ApplicationSkin#hostComponent
		 */
		public var hostComponent:List;
		
		/**
		 * @public
		 */
		public var scroller:Scroller;
		
		/**
		 *  DataGroup skin part
		 */ 
		public var dataGroup:DataGroup;
		
		/**
		 *  @private 
		 */
		override protected function createChildren():void
		{
			if (!dataGroup)
			{
				// Create data group layout
				var layout:VerticalLayout = new VerticalLayout();
				layout.requestedMinRowCount = 5;
				layout.horizontalAlign = HorizontalAlign.JUSTIFY;
				layout.gap = 0;
				
				// Create data group
				dataGroup = new DataGroup();
				dataGroup.layout = layout;
				dataGroup.itemRenderer = new ClassFactory(spark.components.LabelItemRenderer);
			}
			if (!scroller)
			{
				// Create scroller
				scroller = new Scroller();
				scroller.minViewportInset = 0;
				scroller.hasFocusableChildren = false;
				scroller.ensureElementIsVisibleForSoftKeyboard = false;
				addChild(scroller);
			}
			
			// Associate scroller with data group
			if (!scroller.viewport)
			{
				scroller.viewport = dataGroup;
			}
		}
		
		/**
		 *  @private 
		 */
		override protected function measure():void
		{
			measuredWidth = scroller.getPreferredBoundsWidth();
			measuredHeight = scroller.getPreferredBoundsHeight();
		}
		
		/**
		 *  @private 
		 */
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{   
			graphics.clear();
			
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			// Scroller
			setElementSize(scroller, unscaledWidth, unscaledHeight);
			setElementPosition(scroller, 0, 0);
		}
	}
}