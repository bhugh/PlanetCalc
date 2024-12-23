//!
//! Copyright 2015-2021 by Garmin Ltd. or its subsidiaries.
//! Subject to Garmin SDK License Agreement and Wearables
//! Application Developer Agreement.
//!

import Toybox.Application;
import Toybox.Lang;
import Toybox.Position;
import Toybox.WatchUi;
import Toybox.Application.Storage;
import Toybox.System;
import Toybox.Math;

var page = 0;
var pages_total = 25;
//var geo_cache;
var sunrise_cache;
//var moon;

var vspo87a;
var vsop_cache;
var allOrbitParms = null;
    //var view_mode = [0, 1,2,3,4,5]; //manual move ecl, minuts ecl, day ecl, inner orr, mid orr, full orr
    var view_mode = 1;
    var num_view_modes = 9;

    //unit is HOUR
    //all are chosen to be WHOLE DAYS however, to make the sun stand still when moving forward on the eliptical screens
    //But also closest unit to WHOLE YEARS (ie 183 instead of 180 or 182.621187, 61 instead of 60 or 60.873729)
    //Adde synodic month & solar yr as exact time options
    var speeds = [-24*365*10, -24*365*7, -24*365*4, -24*365*2,-24*365.2422, -24*365, //0; year multiples (added 0)
                -24*183, -24*122, -24*91, -24*61, -24*31, -29.53059*24, -24*15, //6; 1/2, 1/4, 1/12, 1/24 of a year (added 1)
                -24*7,-24*5, -24*3, -24*2-15/60.0, -24*2, -24*2+15/60.0, -24-15/60.0, -24, -24+15/60.0, //11; Days up to a week, with 1&2 days +1/-1 hrsso you can adjust them easily
                -12,-6,-4,-2, -1, //22;Hours (added 1)
                -30/60.0,-15/60.0,-10/60.0, -5/60.0, -3/60.0, -2/60.0, -1/60.0,  //27; minutes (added 0)
                1/600000.0,  //34; Zero ( but still has very slight movement, also avoids /0 just in case)
                1/60.0, 2/60.0, 3/60.0, 5/60.0, 10/60.0, 15/60.0, 30/60.0,  //35; minutes (added 0)
                1,2,4,6,12,  //42; Hours (added 1)
                24-15/60.0, 24,24+15/60.0, 24*2-15/60.0, 24*2,24*2+15/60.0, 24*3,24*5, 24*7, //47; Days up to a week (added 0)
                24*15,29.53059*24, 24*31, 24*61, 24*91, 24*122, 24*183, 24*300, //56;300 days 1/2, 1/4, 1/12, 1/24 of a year (added 1)
                24*365,24*365.2422, 24 * 400, 24 * 500, 24*365*2, 24*365*4, 24*365 * 7, 24*365 * 10]; //64; year multiples (added 0)
var speeds_index; //the currently used speed that will be added to TIME @ each update of screen  //
//var screen0Move_index = 33;

var started = false; //whether to move forward on an update, ie STOPPED or STARTED moving
var save_started = null;
var reset_date_stop = false; //set TRUE when reset date is called, which STOPS time.
var hz = 5.0; //updates per second (Requested from OS)
var run_oneTime = true; //set to TRUE by anything that once the screeupdate to run ONCE when it is stopped

var message = [];
var message_until = 0;
var animation_count = 0;
var buttonPresses = 0;
var orreryDraws = 0;

var time_add_hrs = 0.0; //cumulation of all time to be added to time.NOW when a screen is displayed

var show_intvl = 0; //whether or not to show current SPEED on display
var animSinceModeChange = 0; //used to tell when to blank screen etc.
var solarSystemView_class; //saved instance of main class 

//enum {exitApp, resetDate, orrZoomOption, thetaOption, labelDisplayOption, refreshOption, screen0MoveOption, planetSizeOption, planetsOption, helpOption, helpBanners}

//enum {EXIT_APP, RESET_DATE, ORR_ZOOM, THETA, LABEL_DISPLAY, REFRESH, PLANET_SIZE, PLANETS, HELP, HELP_BANNERS}

enum {exitApp_enum, resetDate_enum, orrZoomOption_enum, thetaOption_enum, labelDisplayOption_enum, refreshOption_enum, planetSizeOption_enum, planetsOption_enum, helpOption_enum, helpBanners_enum, lastLoc_enum} //screen0MoveOption_enum, 


class SolarSystemBaseApp extends Application.AppBase {

    //enum {ECLIPTIC_STATIC, ECLIPTIC_MOVE, SMALL_ORRERY, MED_ORRERY, LARGE_ORRERY}
    //var view_mode = [ECLIPTIC_STATIC, ECLIPTIC_MOVE, SMALL_ORRERY, MED_ORRERY, LARGE_ORRERY];


    private var _positionView as SolarSystemBaseView;
    private var _positionDelegate as SolarSystemBaseDelegate;

    //! Constructor
    public function initialize() {
        AppBase.initialize();
        System.println("init starting...");
        _positionView = new $.SolarSystemBaseView();
        solarSystemView_class = _positionView;
        _positionDelegate = new $.SolarSystemBaseDelegate(_positionView);
        //geo_cache = new Geocentric_cache();
        readStorageValues();
        $.now = System.getClockTime();
        $.time_now = Time.now();
        $.now_info = Time.Gregorian.info($.time_now, Time.FORMAT_SHORT);

        sunrise_cache = new sunRiseSet_cache2();        
        System.println("inited...");
        view_mode=0;
        $.changeModes(null); //inits speeds_index properly        


        //System.println("ARR" + toArray("HI|THERE FRED|M<SYUEIJFJ |FIEJKDF:LKJF|SKDJFF|SDLKJSDFLKJ|THIESNEK|FJIEKJF","|",0));
        
        

    }

    //! Handle app startup
    //! @param state Startup arguments
    public function onStart(state as Dictionary?) as Void {  
        System.println("onStart...");
        $.started = false;
        $.run_oneTime = true;
        $.timeWasAdded = true;
        $.buttonPresses = 0;
        $.animation_count = 0;
        $.countWhenMode0Started = 0;
        $.now = System.getClockTime(); //before ANY routines or functions run, so all can have access if necessary        
        $.time_now = Time.now();
        $.now_info = Time.Gregorian.info($.time_now, Time.FORMAT_SHORT);
        System.println ("onStart at " 
            +  $.now.hour.format("%02d") + ":" +
            $.now.min.format("%02d") + ":" +
            $.now.sec.format("%02d") + " " + now_info.year + "-" + now_info.month + "-" + now_info.day);
        _positionView.startAnimationTimer($.hz);
        

        //readStorageValues();
        Position.enableLocationEvents(Position.LOCATION_ONE_SHOT, method(:onPosition));
    }

    //! Handle app shutdown
    //! @param state Shutdown arguments
    public function onStop(state as Dictionary?) as Void {
        System.println ("onStop at " 
            +  $.now.hour.format("%02d") + ":" +
            $.now.min.format("%02d") + ":" +
            $.now.sec.format("%02d"));
        _positionView.stopAnimationTimer();
        started = false;
        Position.enableLocationEvents(Position.LOCATION_DISABLE, method(:onPosition));
        _positionView = null;
        _positionDelegate = null;
        settings_view = null;
        settings_delegate = null;

    }

    //! Update the current position
    //! @param info Position information
    public function onPosition(info as Info) as Void {
        System.println("onPosition... count: " + $.count);
        _positionView.setPosition();

        //We only need this ONCE, not continuously, so . . . 
        Position.enableLocationEvents(Position.LOCATION_DISABLE, method(:onPosition));

    }

    //! Return the initial view for the app
    //! @return Array [View]
    public function getInitialView() as [Views] or [Views, InputDelegates] {
        System.println ("getInitialView at " 
            +  now.hour.format("%02d") + ":" +
            now.min.format("%02d") + ":" +
            now.sec.format("%02d"));
        return [_positionView, _positionDelegate];
        _positionDelegate = null;
        _positionView = null;

    }
    /*
    // settingsview works only for watch faces & data fields (?)
    public function getSettingsView() as [Views] or [Views, InputDelegates] or Null {
        System.println("6A");
        return [new $.SolarSystemSettingsMenu(), new $.SolarSystemInputDelegate()];
    }
    */

    public function readAStorageValue(name, defoolt, size  ) {
        if (!(Application has :Storage)) {
            $.Options_Dict[name] = defoolt;
            return;
        }
        var temp = Storage.getValue(name);  
        //System.println((32.0).toNumber() + " " + temp);  
        if (!(temp instanceof Number)) {$.Options_Dict[name] = defoolt;}
        else { $.Options_Dict[name] = temp  != null ? temp : defoolt; }
        if ($.Options_Dict[name]>size-1) {$.Options_Dict[name] = defoolt;}
        if ($.Options_Dict[name]<0) {$.Options_Dict[name] = defoolt;}
        Storage.setValue(name,$.Options_Dict[name]);
    }

    //read stored settings & set default values if nothing stored
    public function readStorageValues() as Void {

        System.println("STORAGE VALUES ARE READ - PROGRAM INIT!!!!");

        loadPlanetsOpt();
      
        readAStorageValue("orrZoomOption", orrZoomOption_default, orrZoomOption_size );

        //readAStorageValue(orrZoomOption, thetaOption_default, thetaOption_size );

        $.Options_Dict[thetaOption_enum] = 0; //just always default to TIME INTERVAL here.

        readAStorageValue(labelDisplayOption_enum,labelDisplayOption_default, labelDisplayOption_size );

        readAStorageValue(refreshOption_enum,refreshOption_default, refreshOption_size );

        //readAStorageValue("Screen0 Move Option",screen0MoveOption_default, screen0MoveOption_size );

        readAStorageValue(planetSizeOption_enum, planetSizeOption_default, planetSizeOption_size );

        //readAStorageValue("Ecliptic Size Option", eclipticSizeOption_default, eclipticSizeOption_size );
/*
        readAStorageValue("Orbit Circles Option", orbitCirclesOption_default, orbitCirclesOption_size );

        readAStorageValue("resetDots", resetDots_default, resetDots_size );
        */

        readAStorageValue(planetsOption_enum, planetsOption_default, planetsOption_size );        

        var temp = Storage.getValue(helpBanners_enum);
        $.Options_Dict[helpBanners_enum] = temp != null ? temp : true;
        Storage.setValue(helpBanners_enum,$.Options_Dict[helpBanners_enum]); 

       



        //Now IMPLEMENT the above values

        
        /*
        //#####SCREEN0 MOVE
        $.screen0Move_index = screen0MoveOption_values[$.Options_Dict["Screen0 Move Option"]];
        */

        //###### REFRESH RATE
        $.hz = refreshOption_values[$.Options_Dict[refreshOption_enum]];                
        _positionView.startAnimationTimer($.hz);           
        
        //##### PLANET SIZE
        planetSizeFactor = planetSizeOption_values[$.Options_Dict[planetSizeOption_enum]];

        /*
        //##### ECLIPTIC SIZE
        eclipticSizeFactor = eclipticSizeOption_values[$.Options_Dict["Ecliptic Size Option"]];
        */

        //##### Display all or only planets
        planetsOption_value = $.Options_Dict[planetsOption_enum]; //the number not the array (unusual) 

        /* //Sample binary option
        temp = Storage.getValue("Show Battery");
        $.Options_Dict["Show Battery"] = temp  != null ? temp : true;
        Storage.setValue("Show Battery",$.Options_Dict["Show Battery"]);        
        */

     
        
    }


}

/*  SAMPLEs..
class SolarSystemInputDelegate extends WatchUi.InputDelegate {
    function onKey(keyEvent) {
        System.println("GOT KEEY!!!!!!!!!: " + keyEvent.getKey());         // e.g. KEY_MENU = 7
        return true;
    }

    function onTap(clickEvent) {
        System.println(clickEvent.getType());      // e.g. CLICK_TYPE_TAP = 0
        return true;
    }

    function onSwipe(swipeEvent) {
        System.println(swipeEvent.getDirection()); // e.g. SWIPE_DOWN = 2
        return true;
    }
}

*/