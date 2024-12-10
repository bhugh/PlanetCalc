/***************************************************************************************
* SIMPLIFIED Small & Fast Moon Position & Phase Calculator
*
***************************************************************************************/

//The average duration in modern times is 29.53059 days with up to seven hours variation about the mean in any given year.[7] (which gives a mean synodic month as 29.53059 days or 29 d 12 h 44 min 3 s)[a] A more precise figure of the average duration may be derived for a specific date using the lunar theory of Chapront-Touzé and Chapront (1988):
//29.5305888531 + 0.00000021621T − 3.64×10−10T2 where T = (JD − 2451545.0)/36525 and JD is the Julian day number (and JD = 2451545 corresponds to 1 January AD 2000 at Noon.)
//Source: https://en.wikipedia.org/wiki/Lunar_month#Synodic_month
//
//This is an approximation and any phase/full moon may be off by as much as +/- 7 hours. The moon moves about 0.5 degrees per hour against the background stars, so the difference may be about +/- 3.5 degrees visually or +/- 12 minutes.  This is large enough to be seen visually on i.e. even a small
//24-hour clock dial but considering we are only showing a approx. sky positions & rough moon quarter this probably good enough for many applications.

class simpleMoon {

    //  can use Time.Gregorian.info() output for now_info &
    // now = System.getClockTime(); output for now.timeZoneOffset and now.dst
    //Note timeZoneOffset_sec is SECONDS not hours
    public function synodicMonthLength_days(now_info, timeZoneOffset_sec, dst ) {
        if (timeZoneOffset_sec == null) {timeZoneOffset_sec = 0;}
        if (dst == null) {dst = 0;}


        var JD = julianDate (now_info.year, now_info.month, now_info.day, now_info.hour, now_info.min, timeZoneOffset_sec/3600, dst);

        var T = (JD - 2451545.0d)/36525d;

        return 29.5305888531d + 0.00000021621d* T - 3.64E-10d * T*T;
    }

    //Using above month length, you can calculate new moon etc starting with any
    //known new moon date/time
    //We will use: 2025 Jan 29  12:36 UTC
    // JD = 2460705 ; 2460705.025000
    //This will return the current % of lunar phase as a number ranging 0 to 1
    // 0 & 1 are new moon, 0.5 full moon, etc.
    //returns a triplet: [lunar phase(0-1), current lunar day, synodic month length in days]

    public function lunarPhase (now_info, timeZoneOffset_sec, dst) {

        var sml_days  = synodicMonthLength_days(now_info, timeZoneOffset_sec, dst );
        var base_JD = julianDate (2025, 1, 29 , 12, 36, 0, 0);
        var current_JD = julianDate (now_info.year, now_info.month, now_info.day,now_info.hour, now_info.min, timeZoneOffset_sec/3600, dst);

        var difference = current_JD - base_JD;

        var lunar_day = mod (difference, sml_days);

        var lunar_phase = lunar_day/sml_days;

        return [lunar_phase, lunar_day, sml_days];

    }

    public function eclipticPos (now_info, timeZoneOffset_sec, dst) {

        //var sml_days  = synodicMonthLength_days(now_info, timeZoneOffset_sec, dst );
        //var base_JD = julianDate (2025, 1, 29 , 12, 36, 0, 0);
        var current_JD = julianDate (now_info.year, now_info.month, now_info.day,now_info.hour, now_info.min, timeZoneOffset_sec/3600, dst);
        return getGeocentricMoonPos(current_JD);
    }

    // Low Precision Moon Position
    //Accurate to .5 deg over period 1900-2100
    // Source
    // https://celestialprogramming.com/lowprecisionmoonposition.html
    //Input: Julian Date
    //Output: Ecliptical Long, Lat 
    // (rem-ed out portion converts this to geocentric RA & Decl)

    function getGeocentricMoonPos(jd){
	var T = (jd-2451545)/36525;
	var L = 218.32 + 481267.881*T + 6.29*sind(135.0 + 477198.87*T) - 1.27*sind(259.3 - 413335.36*T) + 0.66*sind(235.7 + 890534.22*T) + 0.21*sind(269.9 + 954397.74*T) - 0.19*sind(357.5 + 35999.05*T) - 0.11*sind(186.5 + 966404.03*T);
	var B = 5.13*sind( 93.3 + 483202.02*T) + 0.28*sind(228.2 + 960400.89*T) - 0.28*sind(318.3 + 6003.15*T) - 0.17*sind(217.6 - 407332.21*T);
	//var P = 0.9508 + 0.0518*cosd(135.0 + 477198.87*T) + 0.0095*cosd(259.3 - 413335.36*T) + 0.0078*cosd(235.7 + 890534.22*T) + 0.0028*cosd(269.9 + 954397.74*T);
    return [normalize(L),normalize(B)];

    /*
    //convert to geocentric ra & decl
	var SD=0.2724*P;
	var r=1/sind(P);

	var l = cosd(B) * cosd(L);
	var m = 0.9175*cosd(B)*sind(L) - 0.3978*sind(B);
	var n = 0.3978*cosd(B)*sind(L) + 0.9175*sind(B);

	var ra=Math.atan2(m,l);
	if(ra<0){ra+=2*Math.PI;}
	var dec=Math.asin(n);
	return [ra,dec];
    */
    }

    public function eclipticSunPos (now_info, timeZoneOffset_sec, dst) {

        //var sml_days  = synodicMonthLength_days(now_info, timeZoneOffset_sec, dst );
        //var base_JD = julianDate (2025, 1, 29 , 12, 36, 0, 0);
        var current_JD = julianDate (now_info.year, now_info.month, now_info.day,now_info.hour, now_info.min, timeZoneOffset_sec/3600, dst);
        return getSun(current_JD);
    }

    function getSun(jd)
    {
    //Truncated VSOP87, accurate to 39 arcsecs for 1000 years centered on J2000 (~60 arcsecs for 3000 years)
    //Return values ra,dec are in radians, r retains input units
    //Greg Miller (gmiller@gregmiller.net) 2024.  http://www.celestialprogramming.com/
    //Released as public domain
    var t=(jd - 2451545.0) / 365250.0;
    var y = 0.00010466965 * Math.cos(0.09641690558 + 18849.22754997420*t);
    y += 0.00835292314 * Math.cos(0.13952878991 + 12566.15169998280*t) -0.02442699036;
    y += 0.99989211030 * Math.cos(0.18265890456 + 6283.07584999140*t);
    y += (0.00093046324 + 0.00051506609 * Math.cos(4.43180499286 + 12566.15169998280*t))*t;

    var x = 0.00561144206 + 0.00010466628 * Math.cos(1.66722645223 + 18849.22754997420*t);
    x += 0.00835257300 * Math.cos(1.71034539450 + 12566.15169998280*t);
    x += 0.99982928844 * Math.cos(1.75348568475 + 6283.07584999140*t);
    x += (0.00123403056 + 0.00051500156 * Math.cos(6.00266267204 + 12566.15169998280*t))*t;

    var z=0.00227822442 * Math.cos(3.41372504278 + 6283.07584999140*t)*t;

    //Rotate from VSOP coordinates to J2000
    var tx = -(x + y * 0.000000440360 + z * -0.000000190919);
    var ty = -(x * -0.000000479966 + y * 0.917482137087 + z * -0.397776982902);
    var tz = -(y * 0.397776982902 + z * 0.917482137087);

    //Convert from Cartesian to polar coordinates 
    var r = Math.sqrt(tx * tx + ty * ty + tz * tz);
    var l = Math.atan2(ty, tx);
    var t2 = Math.acos(tz / r);

    //Make sure RA is positive, and Dec is in range +/-90
    if (l < 0) { l += 2 * Math.PI; }
    t2 = .5 * Math.PI - t2;

    //Uncomment to return results in hours and degrees rather than radians
    //return {ra: l*180/Math.PI/15, dec: t2*180/Math.PI, r: r};
    //return {ra: l, dec: t2, r: r};
    return {:lat=> Math.toDegrees(l), :lon => Math.toDegrees(t2), :r => r};
}

}

//By Greg Miller gmiller@gregmiller.net http://www.celestialprogramming.com
//Released as public domain



class ELP82 {

    public function eclipticMoonELP82 (now_info, timeZoneOffset_sec, dst) {

        //var sml_days  = synodicMonthLength_days(now_info, timeZoneOffset_sec, dst );
        //var base_JD = julianDate (2025, 1, 29 , 12, 36, 0, 0);
        var JD = julianDate (now_info.year, now_info.month, now_info.day,now_info.hour, now_info.min, timeZoneOffset_sec/3600, dst);

        var DT =68.6954/60/60/24;
        //lon=-lon; //ALERT!!!!  Meeus considers West longitudes to be positive, which is the opposite of how everything else uses it. !!!!!!!!!!!!!!

        var JDE=JD+DT;
        var T=self.JDEtoT(JDE);
        var ret = elp82(T);
        System.println("ELP82: " + JD + " ret:" + ret);
        return ret;

    }

    var toRad=Math.PI/180.0;
    var toDeg=180.0/Math.PI;

    //Chapront ELP2000/82 truncated implementation from Meeus
    //Input is T in Julian centuries since J2000 in Dynamical Time (T=(JDE-2451545)/36525)
    //Output is geocentric ecliptic longitude, latitude in degrees and distance in km
    //lon=-lon; //ALERT!!!!  Meeus considers West longitudes to be positive, which is the opposite of how everything else uses it. !!!!!!!!!!!!!!
    public function elp82(T){  
        var Lp = normalize(218.3164477d + 481267.88123421d*T - 0.0015786d*T*T + 1.0/538841.0*T*T*T - 1.0/65194000.0d*T*T*T*T)*toRad;
        var D = normalize(297.8501921d + 445267.1114034*T - 0.0018819d*T*T + 1.0/545868.0*T*T*T - 1.0/113065000.0d*T*T*T*T)*toRad;
        var M = normalize(357.5291092d + 35999.0502909*T - 0.0001536d*T*T + 1.0/24490000.0*T*T*T)*toRad;
        var Mp = normalize(134.9633964d + 477198.8675055d*T + 0.0087414d*T*T + 1.0/69699.0*T*T*T - 1.0/14712000.0d*T*T*T*T)*toRad;
        var F = normalize(93.2720950d + 483202.0175233d*T - 0.0036539d*T*T - 1.0/3526000.0*T*T*T + 1.0/863310000.0d*T*T*T*T)*toRad;
        var E = 1 - .002516*T - 0.0000074d*T*T;
        var A1=normalize(119.75d + 131.849d*T)*toRad;
        var A2=normalize(53.09d + 479264.290d*T)*toRad;
        var A3=normalize(313.45d + 481266.484d*T)*toRad;

        var LongitudeRadius = [ 
            //D   M  Mp   F    Long     Radius
            [ 0,  0,  1,  0,  6288774, -20905355 ], 
            [ 2,  0, -1,  0,  1274027,  -3699111 ], 
            [ 2,  0,  0,  0,   658314,  -2955968 ], 
            [ 0,  0,  2,  0,   213618,   -569925 ], 
            [ 0,  1,  0,  0,  -185116,     48888 ], 
            [ 0,  0,  0,  2,  -114332,     -3149 ], 
            [ 2,  0, -2,  0,    58793,    246158 ], 
            [ 2, -1, -1,  0,    57066,   -152138 ], 
            [ 2,  0,  1,  0,    53322,   -170733 ], 
            [ 2, -1,  0,  0,    45758,   -204586 ], 
            [ 0,  1, -1,  0,   -40923,   -129620 ], 
            [ 1,  0,  0,  0,   -34720,    108743 ], 
            [ 0,  1,  1,  0,   -30383,    104755 ], 
            [ 2,  0,  0, -2,    15327,     10321 ], 
            [ 0,  0,  1,  2,   -12528,         0 ], 
            [ 0,  0,  1, -2,    10980,     79661 ], 
            [ 4,  0, -1,  0,    10675,    -34782 ], 
            [ 0,  0,  3,  0,    10034,    -23210 ], 
            [ 4,  0, -2,  0,     8548,    -21636 ], 
            [ 2,  1, -1,  0,    -7888,     24208 ], 
            [ 2,  1,  0,  0,    -6766,     30824 ], 
            [ 1,  0, -1,  0,    -5163,     -8379 ], 
            [ 1,  1,  0,  0,     4987,    -16675 ], 
            [ 2, -1,  1,  0,     4036,    -12831 ], 
            [ 2,  0,  2,  0,     3994,    -10445 ], 
            [ 4,  0,  0,  0,     3861,    -11650 ], 
            [ 2,  0, -3,  0,     3665,     14403 ], 
            [ 0,  1, -2,  0,    -2689,     -7003 ], 
            [ 2,  0, -1,  2,    -2602,         0 ], 
            [ 2, -1, -2,  0,     2390,     10056 ], 
            [ 1,  0,  1,  0,    -2348,      6322 ], 
            [ 2, -2,  0,  0,     2236,     -9884 ], 
            [ 0,  1,  2,  0,    -2120,      5751 ], 
            [ 0,  2,  0,  0,    -2069,         0 ], 
            [ 2, -2, -1,  0,     2048,     -4950 ], 
            [ 2,  0,  1, -2,    -1773,      4130 ], 
            [ 2,  0,  0,  2,    -1595,         0 ], 
            [ 4, -1, -1,  0,     1215,     -3958 ], 
            [ 0,  0,  2,  2,    -1110,         0 ], 
            [ 3,  0, -1,  0,     -892,      3258 ], 
            [ 2,  1,  1,  0,     -810,      2616 ], 
            [ 4, -1, -2,  0,      759,     -1897 ], 
            [ 0,  2, -1,  0,     -713,     -2117 ], 
            [ 2,  2, -1,  0,     -700,      2354 ], 
            [ 2,  1, -2,  0,      691,         0 ], 
            [ 2, -1,  0, -2,      596,         0 ], 
            [ 4,  0,  1,  0,      549,     -1423 ], 
            [ 0,  0,  4,  0,      537,     -1117 ], 
            [ 4, -1,  0,  0,      520,     -1571 ], 
            [ 1,  0, -2,  0,     -487,     -1739 ], 
            [ 2,  1,  0, -2,     -399,         0 ], 
            [ 0,  0,  2, -2,     -381,     -4421 ], 
            [ 1,  1,  1,  0,      351,         0 ], 
            [ 3,  0, -2,  0,     -340,         0 ], 
            [ 4,  0, -3,  0,      330,         0 ], 
            [ 2, -1,  2,  0,      327,         0 ], 
            [ 0,  2,  1,  0,     -323,      1165 ], 
            [ 1,  1, -1,  0,      299,         0 ], 
            [ 2,  0,  3,  0,      294,         0 ], 
            [ 2,  0, -1, -2,        0,      8752 ] 
        ]; 
        
        var Latitude = [ 
            [ 0,  0,  0,  1, 5128122 ], 
            [ 0,  0,  1,  1,  280602 ], 
            [ 0,  0,  1, -1,  277693 ], 
            [ 2,  0,  0, -1,  173237 ], 
            [ 2,  0, -1,  1,   55413 ], 
            [ 2,  0, -1, -1,   46271 ], 
            [ 2,  0,  0,  1,   32573 ], 
            [ 0,  0,  2,  1,   17198 ], 
            [ 2,  0,  1, -1,    9266 ], 
            [ 0,  0,  2, -1,    8822 ], 
            [ 2, -1,  0, -1,    8216 ], 
            [ 2,  0, -2, -1,    4324 ], 
            [ 2,  0,  1,  1,    4200 ], 
            [ 2,  1,  0, -1,   -3359 ], 
            [ 2, -1, -1,  1,    2463 ], 
            [ 2, -1,  0,  1,    2211 ], 
            [ 2, -1, -1, -1,    2065 ], 
            [ 0,  1, -1, -1,   -1870 ], 
            [ 4,  0, -1, -1,    1828 ], 
            [ 0,  1,  0,  1,   -1794 ], 
            [ 0,  0,  0,  3,   -1749 ], 
            [ 0,  1, -1,  1,   -1565 ], 
            [ 1,  0,  0,  1,   -1491 ], 
            [ 0,  1,  1,  1,   -1475 ], 
            [ 0,  1,  1, -1,   -1410 ], 
            [ 0,  1,  0, -1,   -1344 ], 
            [ 1,  0,  0, -1,   -1335 ], 
            [ 0,  0,  3,  1,    1107 ], 
            [ 4,  0,  0, -1,    1021 ], 
            [ 4,  0, -1,  1,     833 ], 
            [ 0,  0,  1, -3,     777 ], 
            [ 4,  0, -2,  1,     671 ], 
            [ 2,  0,  0, -3,     607 ], 
            [ 2,  0,  2, -1,     596 ], 
            [ 2, -1,  1, -1,     491 ], 
            [ 2,  0, -2,  1,    -451 ], 
            [ 0,  0,  3, -1,     439 ], 
            [ 2,  0,  2,  1,     422 ], 
            [ 2,  0, -3, -1,     421 ], 
            [ 2,  1, -1,  1,    -366 ], 
            [ 2,  1,  0,  1,    -351 ], 
            [ 4,  0,  0,  1,     331 ], 
            [ 2, -1,  1,  1,     315 ], 
            [ 2, -2,  0, -1,     302 ], 
            [ 0,  0,  1,  3,    -283 ], 
            [ 2,  1,  1, -1,    -229 ], 
            [ 1,  1,  0, -1,     223 ], 
            [ 1,  1,  0,  1,     223 ], 
            [ 0,  1, -2, -1,    -220 ], 
            [ 2,  1, -1, -1,    -220 ], 
            [ 1,  0,  1,  1,    -185 ], 
            [ 2, -1, -2, -1,     181 ], 
            [ 0,  1,  2,  1,    -177 ], 
            [ 4,  0, -2, -1,     176 ], 
            [ 4, -1, -1, -1,     166 ], 
            [ 1,  0,  1, -1,    -164 ], 
            [ 4,  0,  1, -1,     132 ], 
            [ 1,  0, -1, -1,    -119 ], 
            [ 4, -1,  0, -1,     115 ], 
            [ 2, -2,  0,  1,     107 ] 
        ]; 

        var Lon=0;
        var Radius=0;
        for(var i=0;i<LongitudeRadius.size();i++){
            var t=LongitudeRadius[i];
            var a=D*t[0] + M*t[1] + Mp*t[2] + F*t[3];

            var e=1;
            if(t[1]==1 || t[1]==-1){e=E;}
            if(t[1]==2 || t[1]==-2){e=E*E;}

            Lon+=e*t[4]*Math.sin(a);
            Radius+=e*t[5]*Math.cos(a);
        }

        var Lat=0;
        for(var i=0;i<Latitude.size();i++){
            var t=Latitude[i];
            var a=D*t[0] + M*t[1] + Mp*t[2] + F*t[3];

            var e=1;
            if(t[1]==1 || t[1]==-1){e=E;}
            if(t[1]==2 || t[1]==-2){e=E*E;}

            Lat+=e*t[4]*Math.sin(a);
        }

        var aLon=3958*Math.sin(A1) + 1962*Math.sin(Lp-F) + 318*Math.sin(A2);
        var aLat=-2235*Math.sin(Lp) + 382*Math.sin(A3) + 175*Math.sin(A1-F) + 175*Math.sin(A1+F) + 127*Math.sin(Lp-Mp) - 115*Math.sin(Lp+Mp);

        Lon=Lp*toDeg + (Lon+aLon)/1000000;
        Radius=385000.56 + Radius/1000;
        Lat=(Lat+aLat)/1000000;

        return [Lon,Lat,Radius];
    }

    //use normalize instead/doesn't work in monkey c

    /*
    private function constrain(d){
        var t=d;
        t=t%360;
        if(t<0){t+=360;}
        return t;
    }
    */

    private function JDEtoT(jde){
        return (jde-2451545)/36525.0;
    }
}






