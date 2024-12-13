import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Math;
import Toybox.System;


//! Handle input on initial view
class SolarSystemBaseDelegate extends WatchUi.BehaviorDelegate {
    private var _mainview;
    //! Constructor
    public function initialize(view) {
        BehaviorDelegate.initialize();
        //System.println("delegate initl..");
        _mainview = view;
    }
    var last_animation_count = 0;
    var animation_retry_tally = 0;


    //! Handle the select button
    //! @return true if handled, false otherwise
    public function onSelect() as Boolean {

        $.buttonPresses++;

        if (_mainview.animation_count == last_animation_count) {
            animation_retry_tally ++;
            if (animation_retry_tally%3 == 0) {
                _mainview.startAnimationTimer($.hz);
            }

        } else {
            animation_retry_tally =0;            
        }
        last_animation_count=_mainview.animation_count;

        
        //if stopped, it starts playing (whatever mode we're in)
        //if started already, it moves to next mode
        if (!started && $.view_index != 0) {
            started = true;
    
            //WatchUi.requestUpdate();
        } else {
            //System.println("delegate onselect... moving ot new mode" + $.view_index);
            var old_index = $.view_index;
            $.view_index = ($.view_index + 1) % $.view_modes.size();  
            started = true;
            $.show_intvl = 0;
            $.changeModes(old_index);  
        }

        
        return true;
    }

        //! Handle the select button
    //! @return true if handled, false otherwise

    //if stopped, moved back one mode
    //if started, stop.
    public function onBack() as Boolean {
        $.buttonPresses++;
        $.show_intvl = 0;
        if (!started || $.view_index == 0) {
            var old_index = $.view_index;
            $.view_index = ($.view_index - 1);        
            if ($.view_index < 0) {
                return false;
            }
            started = true;
            $.show_intvl = 0;
            $.changeModes(old_index);  
            //WatchUi.requestUpdate();
        } else {
            started = false;
        }    
        
        //var view = _mainview;
        //var delegate = new $.SolarSystemBaseDelegate(view);
        
        //popView(WatchUi.SLIDE_RIGHT);//(view, delegate, WatchUi.SLIDE_IMMEDIATE);

        //WatchUi.requestUpdate();
        return true;
    }

        //! Handle going to the next view
    //! @return true if handled, false otherwise
    public function onNextPage() as Boolean {
        //_view.nextSensor();
        //$.show_intvl = false;
        //_mainview.$.time_add_hrs -= _mainview.time_add_inc;

        //System.println("onNextPage..." );
        $.buttonPresses++;

        if ($.view_modes[$.view_index] == 0) {
            $.time_add_hrs -= speeds[speeds_index];
            WatchUi.requestUpdate();
        } else {
            speeds_index --;
            if (speeds_index<0)  {speeds_index=0; }
            $.show_intvl = 0;
            

            //WatchUi.requestUpdate();
        


        }
        
        /*
        if (_mainview.$.time_add_hrs%24==0 && _mainview.$.time_add_hrs!=0) {
            _mainview.$.time_add_hrs -=24;
        } else {
            _mainview.$.time_add_hrs -=1;
        }
        */


        return true;
    }

    //! Handle going to the previous view
    //! @return true if handled, false otherwise
    public function onPreviousPage() as Boolean {
        //_view.previousSensor();
        //System.println("onPrevPage..." );

        $.buttonPresses++;
        
        if ($.view_modes[$.view_index] == 0) {
            $.time_add_hrs += speeds[speeds_index];
            WatchUi.requestUpdate();
        } else {
                speeds_index ++;
                if (speeds_index>= speeds.size()) {speeds_index = speeds.size()-1;}
                $.show_intvl = 0;
                

            //WatchUi.requestUpdate();
        }

        //$.show_intvl = false;
        //$.time_add_hrs += _mainview.time_add_inc;
        //WatchUi.requestUpdate();
        /*
        if ($.time_add_hrs%24==0 && $.time_add_hrs!=0) {
            $.time_add_hrs +=24;
        } else {
            $.time_add_hrs +=1;
        } */

        return true;
    }

    function onTap(clickEvent) {
        System.println("Click1: " + clickEvent.getCoordinates()); // e.g. [36, 40]
        System.println("Click2: " + clickEvent.getType());        // CLICK_TYPE_TAP = 0
        return true;
    }

    
    function onKey(keyEvent) {
        var keyvent =  keyEvent.getKey();
        System.println("GOT KEEY!!!!!!!!!: " + keyvent);         // e.g. KEY_MENU = 7

        if (keyvent == 7) {

            $.buttonPresses++;
            var view = new $.SolarSystemSettingsView();
            var delegate = new $.SolarSystemSettingsDelegate();
        
            pushView(view, delegate, WatchUi.SLIDE_LEFT);


            return true;
        }
        return false;
        
        
    }
    
}

function changeModes(previousMode){
        //System.println("chmodes..." );
        
        $.animSinceModeChange = 0;
        $.show_intvl = 0; //used by showDate to decide when/how long to show (5 min) type labels
        //$.time_add_hrs = .5; //reset to present time //NOW Do this, or not, individually per MODE below
        $.Options_Dict["orrZoomOption"] = orrZoomOption_default;

        switch($.view_modes[$.view_index]){
            case (0):
                //time_add_inc = 0.25;
                //$.time_add_hrs = .5; //reset to present time
                if (previousMode != null && previousMode==5 ) {  //mode 5 often moves years into the future...
                    $.time_add_hrs = 0; //reset to present time
                }
                speeds_index = screen0Move_index; //15 mins or whatever the person has set
                solarSystemView_class.sendMessage("Manual Mode", "Use Up/Down", "", 5);
                break;
            case (1):
                //time_add_inc=1;
                //DON'T reset to present time here bec. we're usually coming from mode 0 or mode 2& can just continue seamlessly
                //$.time_add_hrs = .5; //reset to present time
                speeds_index = 32; //5 mins
                solarSystemView_class.sendMessage("Auto by Min Mode", "Use Up/Down", "", 5);
                break;
            case(2):
                //time_add_inc = 24*3; //1 day
                //DON'T reset to present time here bec. we're usually coming from mode 0 or mode 2& can just continue seamlessly
                if (previousMode != null && previousMode==3 ) {  //mode 3 often moves years into the future...
                    $.time_add_hrs = 0; //reset to present time
                }
                speeds_index = 41; //1 day or 24 hrs
                solarSystemView_class.sendMessage("Auto by Day Mode", "Use Up/Down", "", 5);
                break;                
            case(3):
                //time_add_inc = 24*3; //1 day
                $.time_add_hrs = 0; //reset to present time
                speeds_index = 41; //1 day
                solarSystemView_class.sendMessage("Inner", "Solar System", "(Use Up/Down)", 5);
                break;
            case(4):
                //time_add_inc = 24*15; //14 days
                $.time_add_hrs = 0; //reset to present time
                speeds_index = 46; //15 days
                solarSystemView_class.sendMessage("Outer", "Solar System", "(Use Up/Down)", 5);
                break;
            
            case(5):
                //time_add_inc = 24*15; //90 days
                $.time_add_hrs = 0; //reset to present time
                speeds_index = 48; //61 days
                solarSystemView_class.sendMessage("Far Outer", "Solar System","(Use Up/Down)", 5);
                break;
            default:
              speeds_index = 29; //2 mins


        }
        

}