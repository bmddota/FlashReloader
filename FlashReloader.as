package {
	import flash.display.MovieClip;

	//import some stuff from the valve lib
	import ValveLib.Globals;
	import ValveLib.ResizeManager;
	import flash.display.Loader;
	import flash.events.IOErrorEvent;
	import flash.events.Event;
	import flash.events.ProgressEvent;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
	import flash.system.ApplicationDomain;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	import flash.utils.getDefinitionByName;
	import flash.events.MouseEvent;
	import scaleform.clik.controls.Button;
	
	public class FlashReloader extends MovieClip{
		
		//these three variables are required by the engine
		public var gameAPI:Object;
		public var globals:Object;
		public var elementName:String;
		
		public var asdf:int = 148;
		
		public var oldFun:Function = null;
		public var loaders:Object = {};
		
		public var unloadButton = null;
		public var loaderKV:Object = null;
		public var unloaded:Boolean = false;
		
		public var oldSubscribe:Function = null;
		public var subFunctions:Array = new Array();
		
		//constructor, you usually will use onLoaded() instead
		public function FlashReloader() : void {
			trace("[FlashReloader] FlashReloader UI Constructed!");
			trace(asdf);		
		}
		
		public function onUnloaded():void {
			trace("[FlashReloader] FlashReloader UI UNLOADING!");
			trace(asdf);
			
			unloadSwfs();
			
			unloadButton.removeEventListener(MouseEvent.CLICK, unloadClicked);
			this.removeChild(unloadButton);
			unloadButton = null;
			
			Globals.instance.resizeManager.RemoveListener(this);
			
			loaderKV = null;
			this.gameAPI.SubscribeToGameEvent = oldSubscribe;
			oldSubscribe = null;
			unloaded = true;
			for (var i=subFunctions.length; i>0; i--){
				subFunctions.pop();
			}
        }
		
		public function unloadSwfs():void {
			if (loaders == null)
		   		return;
		   
		   for (var loaderFile:String in loaders){
			   trace("[FlashReloader] Unloading " + loaderFile);
			   var loader:Loader = loaders[loaderFile];
			   
			   var mc:MovieClip = loader.content as MovieClip;
			   
			   if (mc.hasOwnProperty("onUnloaded")){
			   	   mc.onUnloaded();
			   }
			   
			   //loader.contentLoaderInfo.removeEventListener(ProgressEvent.PROGRESS, this.loadProgress);
			   loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, this.loadComplete);
			   loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, this.loadIOError);
			   
			   loader.parent.removeChild(loader);
			   
			   
			    mc["gameAPI"] = null
				mc["globals"] = null
				mc["elementName"] = "Loader_" + loader.name;
			   
			   loader.unloadAndStop();
			   delete loaders[loaderFile];
		   }
		   
		   loaders = null;
		}
		
		public function OnUnload():Boolean {
			trace("[FlashReloader] FlashReloader UNLOAD Call");
			
			//gameAPI.OnUnload = oldFun;
			
			return true;
		}
		
		public function unloadClicked(){
			if (loaders != null){
				unloadSwfs();
				
				trace("----");
				trace("DONE UNLOAD");
				
				var timer4:Timer = new Timer(2500, 1);
				var fun4:Function = function(e:TimerEvent){
					timer4.removeEventListener(TimerEvent.TIMER, fun4);
					timer4.stop();
					timer4 = null;
					fun4 = null;
					
					
					trace("RESTARTING");
					gameAPI.SendServerCommand("unload_and_restart");
				};
				timer4.addEventListener(TimerEvent.TIMER, fun4);
				timer4.start();
			}
		}
		
		//this function is called when the UI is loaded
		public function onLoaded() : void {
			this.visible = true;
			
			trace("[FlashReloader] FlashReloader OnLoaded");
			//this.gameAPI.SubscribeToGameEvent("console_command", this.onConsoleCommand);
			
			//oldFun = gameAPI.OnUnload;
			//gameAPI.OnUnload = OnUnload;
			
			loaderKV = globals.GameInterface.LoadKVFile('resource/flash3/reloader.txt');
			Globals.instance.TraceObject(loaderKV, "");
			
			for (var index:String in loaderKV){
				var inner:Object = loaderKV[index];
				var depth:Number = inner.Depth;
				var file:String = inner.File;
				var loader:Loader = new Loader();
				loader.name = file;
				loader.tabIndex = depth;
				file += ".swf";
				//loader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, this.loadProgress);
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, this.loadComplete);
				loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, this.loadIOError);
				
				trace("Loading: " + file);
				
				var context:LoaderContext = new LoaderContext(false, ApplicationDomain.currentDomain);
				
				loader.load(new URLRequest(file), context);
			}
			
			
			var redClass:Class = getDefinitionByName("chrome_button_primary_short") as Class;
			unloadButton = new redClass();
			unloadButton.visible = true;
			unloadButton.label = "Unload+Restart";
			unloadButton.addEventListener(MouseEvent.CLICK, unloadClicked);
			this.addChild(unloadButton);
			
			Globals.instance.resizeManager.AddListener(this);
			
			oldSubscribe = this.gameAPI.SubscribeToGameEvent;
			this.gameAPI.SubscribeToGameEvent = function(evt:String, fun:Function){
				
				trace("Subscribe overload for " + evt);
				var index = subFunctions.length;
				subFunctions.push(fun);
				var newFun:Function = makeFunction(index);
				
				oldSubscribe(evt, newFun);
			};
		}
		
		public function makeFunction(index):Function {
			return function(obj){
				trace("Overload called for " + index);
				if (unloaded)
					return;
				subFunctions[index](obj);
			};
		}
		
		public function loadProgress(e:ProgressEvent){
			trace("[FlashReloader] LOAD PROGRESS" + e.bytesTotal);
		}
		
		public function loadComplete(e:Event){
			var loader:Loader = e.currentTarget.loader as Loader;
			trace("[FlashReloader] Load Complete for " + loader.name);
			
			var mc:MovieClip = loader.content as MovieClip;
			mc["gameAPI"] = this.gameAPI;
			mc["globals"] = this.globals;
			mc["elementName"] = "Loader_" + loader.name;
			
			var children:int = globals.Level0.numChildren;
			var index:int = 0;
			var newIndex:int = -1;
			//globals.TraceObject(globals.Level0, "");
			//trace(children);
			 while(index < children)
            {
               if(globals.Level0.getChildAt(index) is Loader)
               {
                  var inner:Loader = globals.Level0.getChildAt(index) as Loader;
				  ///trace(inner.name + " -- " + inner.tabIndex + " -- " + loader.tabIndex);
                  if(inner.tabIndex > loader.tabIndex)
                  {
					 newIndex = index;
                     break;
                  }
               }
               index++;
            }
			
			//trace(newIndex);
			globals.Level0.addChild(loader);
			if (newIndex != -1){
				globals.Level0.setChildIndex(loader, newIndex);
			}
			//this.addChild(loader);
			
			if (mc.hasOwnProperty("onResize")){
				mc.onResize(Globals.instance.resizeManager);
			}
			
			if (mc.hasOwnProperty("onLoaded")){
				mc.onLoaded();
			}
			
			loaders[loader.name] = loader;
		}
		
		public function loadIOError(e:IOErrorEvent){
			var loader:Loader = e.currentTarget.loader as Loader;
			trace("[FlashReloader] IO ERROR for " + loader.name);
			trace(e.text);
		}
		
		public function onResize(re:ResizeManager) : * {
			unloadButton.x = re.ScreenWidth - unloadButton.width;
			unloadButton.y = re.ScreenHeight - unloadButton.height;
			
			for (var loaderFile:String in loaders){
			   trace("[FlashReloader] Resizing " + loaderFile);
			   var loader:Loader = loaders[loaderFile];
			   
			   var mc:MovieClip = loader.content as MovieClip;
			   
			   if (mc.hasOwnProperty("onResize")){
				mc.onResize(re);
			   }
			}
		}
	}
}