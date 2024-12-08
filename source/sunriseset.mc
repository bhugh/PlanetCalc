/*************************************************************
*
* Adapted directly from:
* SolarSystem by Ioannis Nasios 
* https://github.com/IoannisNasios/solarsystem
*
* LICENSE & COPYRIGHT of original code:
* The MIT License, Copyright (c) 2020, Ioannis Nasios
*
* Monkey C/Garmin IQ version of the code, with many modifications,
* Copyright (c) 2024, Brent Hugh. Released under the MIT license.
*
***************************************************************/

import Toybox.Math;
//from .functions import normalize

    enum {
        ASTRO_DAWN,
        NAUTIC_DAWN,
        DAWN,
        BLUE_HOUR_AM,
        SUNRISE,
        SUNRISE_END,
        GOLDEN_HOUR_AM,
        NOON,
        GOLDEN_HOUR_PM,
        SUNSET_START,
        SUNSET,
        BLUE_HOUR_PM,
        DUSK,
        NAUTIC_DUSK,
        ASTRO_DUSK,
        NUM_RESULTS,
        SIDEREAL_TIME
    }

class SunRiseSet{

    public var sunEvents = [
        ASTRO_DAWN,
        NAUTIC_DAWN,
        DAWN,
        BLUE_HOUR_AM,
        SUNRISE,
        SUNRISE_END,
        GOLDEN_HOUR_AM,
        NOON,
        GOLDEN_HOUR_PM,
        SUNSET_START,
        SUNSET,
        BLUE_HOUR_PM,
        DUSK,
        NAUTIC_DUSK,
        ASTRO_DUSK,
        SIDEREAL_TIME
    ];

    public var sunEventData = {
        ASTRO_DAWN => [-18,  "Astronomical Dawn"],
        NAUTIC_DAWN => [-12, "Nautical Dawn"],
        DAWN => [-6 , "Civil Dawn"],
        BLUE_HOUR_AM => [-4, "Morning Blue Hour"],
        SUNRISE => [-.833, "Sunrise"],
        SUNRISE_END => [-.3, "End of Sunrise"],
        GOLDEN_HOUR_AM => [6, "Morning Golden Hour"],
        NOON => [null, "Noon"], //noon is the highest point or whatever, but not a certain # of degrees
        GOLDEN_HOUR_PM => [6, "Evening Golden Hour"],
        SUNSET_START => [-0.3, "Start of Sunset"],
        SUNSET => [-.833,  "Sunset"],
        BLUE_HOUR_PM => [-4,  "Evening Blue HOur"],
        DUSK => [-6,  "Civil Dusk"],
        NAUTIC_DUSK => [-12,  "Nautical Dusk"],
        ASTRO_DUSK  => [-18,  "Astronomical Dusk"], 
        SIDEREAL_TIME => [null, "Sidereal Time"],
    };
        
        //degrees above / below the horizon for these events
    public const TIMES = [
        -18,    // ASTRO_DAWN
        -12,    // NAUTIC_DAWN
        -6,     // DAWN
        -4,     // BLUE_HOUR
        -0.833, // SUNRISE
        -0.3,   // SUNRISE_END
        6,      // GOLDEN_HOUR_AM
        null,         // NOON
        6 ,
        -0.3,
        -0.833,
        -4,
        -6,
        -12,
        -18,
        ];

    /* **************************************************************************
    Outputs Dictionary with all sun events for the day + Sidereal_Time EVENT_NAME => [time, name_str].  See enum with EVENT_NAMEs above.
    If any events do not happen (ie sunrise & set during polar summer) their time will be a null.
    
    Args:
        year (int): Year (4 digits) ex. 2020.
        month (int): Month (1-12).
        day (int): Day (1-31).
        UT: Time Zone (deviation from UT, -12:+14), ex. for Greece (GMT + 2) 
            enter UT = 2.
        dst (int): daylight saving time (0 or 1). Wheather dst is applied at 
                   given time and place.
        longitude (float): longitude of place of Sunrise - Sunset in decimal format.
        latitude (float): latitude of place of Sunrise - Sunset in decimal format.
    ***************************************************************************/
    
    var UT, dst, longitude, latitude, d, oblecl;

    function initialize(year, month, day, UT1, dst1, 
                 latitude1, longitude1) {
        UT =  UT1;
        dst = dst1;
        longitude = longitude1;
        latitude = latitude1;
        var pr=0d;
        if (dst==1) {pr=1/24d;}
        var JDN= ((367l*(year) - Math.floor(7*(year + Math.floor((month+9 )/12))/4)) + Math.floor(275*(month)/9) + (day + 1721013.5d - UT/24d ) );
        var JD= (JDN + (12)/24d + 0/1440d - pr); //(hour)/24 + (min)/1440; in this case  noon (hr12, min0)
        var j2000= 2451543.5d;
        d = JD - j2000;
        //self.d = d;
        oblecl=23.4393d - 3.563E-7d * d;
        oblecl= Math.toRadians(oblecl);
        //self.oblecl = oblecl ;
    }
        

    function riseSet() {
        /*Get the time of sun rise and set within given date.
        
        Returns:
            tuple: Sunrise - Sunset time of given date
            
        */
        
        //Sun's trajectory elements
        var w=282.9404d + 4.70935E-5d * d      ;
        var e=(0.016709d - (1.151E-9  * d))   ;
        var M=356.047d + 0.9856002585d * d   ;
        M=normalize(M);
        var L=w+M   ;
        L=normalize(L);

        var M2=M;
        M=Math.toRadians(M);
        var E=M2 + (180d/Math.PI)*e*Math.sin(M)*(1+e*Math.cos(M));
        E=Math.toRadians(E);
        var x=Math.cos(E)-e;
        var y=Math.sin(E)*Math.sqrt(1-e*e);
        
        var r=Math.sqrt(x*x + y*y) ;
        var v=Math.atan2(y,x)  ;
        v=Math.toDegrees(v);
        var lon=(v+w)   ;
        lon=normalize((lon));
        lon=Math.toRadians(lon) ;
        var x2=r * Math.cos(lon) ;
        var y2=r * Math.sin(lon);
        var z2=0;
        
        var xequat = x2   ;
        var yequat = (y2*Math.cos(oblecl) - z2 * Math.sin(oblecl));
        var zequat = (y2*Math.sin(oblecl) + z2 * Math.cos(oblecl));

    
        var RA=Math.atan2(yequat, xequat);
        RA=Math.toDegrees(RA);
        RA=normalize(RA);
        var Decl=Math.atan2(zequat, Math.sqrt(xequat*xequat +yequat*yequat));
        //Decl=Math.toDegrees(Decl); //can't transform to degrees yet...
        //RA2=RA/15;
        
        var gmsto=L/15.0d + 12.0d;
        
        var sidtime=(-dst + gmsto - UT + longitude/15);

        
        var HA=(sidtime*15 - RA); //gonia oras; = time angle
        HA=Math.toRadians(HA);
        //Decl=Math.toRadians(Decl);
        
        var x3=Math.cos(HA)*Math.cos(Decl);
        var y3=Math.sin(HA)*Math.cos(Decl);
        var z3=Math.sin(Decl);

        //System.println("RA " + RA + " DECL " + Decl + " HA " + HA + "gmsto " + gmsto + " sidtime " + sidtime + " x3 " + x3 + "y3 " + y3 + " z3 " + z3);
        
        latitude=Math.toRadians(latitude);
        var xhor=(x3*Math.sin(latitude) - z3*Math.cos(latitude));
        var yhor=y3;
        var zhor=(x3*Math.cos(latitude) + z3*Math.sin(latitude));
        var azim=Math.atan2(yhor, xhor) ;
        azim=Math.toDegrees(azim);
        //  azimuth=azim + 180 ;
        var altitude=Math.asin(zhor);
        altitude=Math.toDegrees(altitude);
        
        var ret = {};
        var kys = sunEventData.keys();

        for (var i = 0; i<sunEventData.size();i++) {
            var ky = kys[i];

            var T_sun=normalize((RA - sidtime*15))/15 ;
            if (ky == NOON) {
                ret.put (ky, [T_sun,sunEventData[ky][1]]);
                continue;
            } else if (ky == SIDEREAL_TIME) {
                ret.put (ky, [sidtime ,sunEventData[ky][1]]);
                continue;
            }

            //var h=Math.toRadians(-.833); //but this is clearly in radians not degrees...
            var h=Math.toRadians(sunEventData[ky][0]); //but this is clearly in radians not degrees...
            var adi=(Math.sin(h) -Math.sin(latitude)*Math.sin(Decl))/(Math.cos(latitude)*Math.cos(Decl));

            //System.println("h " + h + " latitude " + latitude +  " Decl rad. " + Decl + "adi " + adi);
            //In polar regions etc we might not have sunrise, sunset etc
            var Lha = (adi>1 || adi < -1) ? null : Math.acos(adi);

            //var Lha=Math.acos(adi);
            if (Lha != null) { Lha= (Math.toDegrees(Lha))/15;}
            //Decl=Math.toDegrees(Decl); 
            //System.println("LHa " + Lha + " Tsun " + T_sun + " adi " + adi + " Decl deg. " + Decl);

            if (i < NOON) {
                var anatoli=null;
                if (Lha != null) {anatoli=T_sun - Lha;}
                ret.put (ky, [anatoli ,sunEventData[ky][1]]);
            } else {
                var disi=null;
                if (Lha != null) {disi=T_sun + Lha;}                
                ret.put (ky, [disi ,sunEventData[ky][1]]);
            }
            //var ret = [anatoli, disi];
            
        }
        //System.println("sunrise/sets " + ret);

        return ret;
    }

    public function siderealTime(year, month, day, hour, min, UT1, dst1, 
                 latitude1, longitude1){

 
        var UT =  UT1;
        var dst = dst1;
        var longitude = longitude1;
        var latitude = latitude1;
        var pr=0d;
        if (dst==1) {pr=1/24d;}
        var JDN= ((367l*(year) - Math.floor(7*(year + Math.floor((month+9 )/12))/4)) + Math.floor(275*(month)/9) + (day + 1721013.5d - UT/24d ) );
        var JD= (JDN + (hour)/24d + min/1440d - pr); //(hour)/24 + (min)/1440; in this case  noon (hr12, min0)
        var j2000= 2451543.5d;
        var d = JD - j2000;
        //self.d = d;
        var oblecl=23.4393d - 3.563E-7d * d;
        oblecl= Math.toRadians(oblecl);
        //self.oblecl = oblecl ;
        
        //Sun's trajectory elements
        var w=282.9404d + 4.70935E-5d * d      ;
        var e=(0.016709d - (1.151E-9  * d))   ;
        var M=356.047d + 0.9856002585d * d   ;
        M=normalize(M);
        var L=w+M   ;
        L=normalize(L);

        var M2=M;
        M=Math.toRadians(M);
        var E=M2 + (180d/Math.PI)*e*Math.sin(M)*(1+e*Math.cos(M));
        E=Math.toRadians(E);
        var x=Math.cos(E)-e;
        var y=Math.sin(E)*Math.sqrt(1-e*e);
        
        var r=Math.sqrt(x*x + y*y) ;
        var v=Math.atan2(y,x)  ;
        v=Math.toDegrees(v);
        var lon=(v+w)   ;
        lon=normalize((lon));
        lon=Math.toRadians(lon) ;
        var x2=r * Math.cos(lon) ;
        var y2=r * Math.sin(lon);
        var z2=0;
        
        var xequat = x2   ;
        var yequat = (y2*Math.cos(oblecl) - z2 * Math.sin(oblecl));
        var zequat = (y2*Math.sin(oblecl) + z2 * Math.cos(oblecl));

    
        var RA=Math.atan2(yequat, xequat);
        RA=Math.toDegrees(RA);
        RA=normalize(RA);
        var Decl=Math.atan2(zequat, Math.sqrt(xequat*xequat +yequat*yequat));
        //Decl=Math.toDegrees(Decl); //can't transform to degrees yet...
        //RA2=RA/15;
        
        var gmsto=L/15.0d + 12.0d;
        
        var sidtime=(-dst + gmsto - UT + longitude/15);

        return sidtime;


    }
}