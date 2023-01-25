// Model railroad
// Eventually for SCADvent?

width = 1.435;
thickness = 0.127;    // guess
s1 = true;

module stop() {}

$fa = 1;

railHeight = 0.12;
rail = {{
    polygon([
        [-.08,0],
        [-.05,railHeight],
        [.05,railHeight],
        [.08,0]
    ]);
}};

function straight(length) = {
    model: {{
        translate([0,length,0]) rotate([90,0,0]) {
            linear_extrude(height=length) {
                translate([-width/2,0]) rail;
                translate([width/2,0]) rail;
            }
        };
    }},
    translate: [0,length,0],
    rotate: 0,
    length: length,
    point: function (n)
        n > length ? undef : [0, n]
};

function curve(r, a) = 
    let (s = a > 0 ? 1 : -1)
    {
        model: {{
            translate([-s*r,0,0])
                rotate_extrude(angle=a) {
                    translate([s*r-width/2,0]) rail;
                    translate([s*r+width/2,0]) rail;
                }
        }},
        translate: [-s*r,0] + s*r*[cos(a),sin(a)],
        rotate: a,
        length: abs(a)*PI/180*r,
        point: function (n)
            let (radians = n/r)
            let (degrees = radians*180/PI)
            degrees > abs(a)
            ? undef
            : [ -s*r, 0 ] + s*r*[cos(s*degrees),sin(s*degrees)]
    };

function link(f) = {
    condition: true,
    link: f
};

function loop(f) = {
    loop: f
};

function switch(cond, f) = {
    condition: cond,
    link: f
};

track = [
    straight(30),
    switch(s1, function() track2),
    curve(30,90),
    straight(120),
    curve(30,90),
    link(function() track3),
];

track3 = [
    straight(30),
    curve(30,90),
    curve(30,90),
    curve(30,-90),
    curve(30,-90),
    curve(30,90),
    curve(30,90),
    loop(function () track)
];

track2 = [
    straight(60),
    curve(30,90),
    straight(120),
    curve(30,90),
    straight(60),
    loop(function () track3)
];

module drawTrack(track, i=0) {
    if (i < len(track)) {
        t = track[i];
        if (t.link) {
            drawTrack(t.link());
        }
        if (t.model) {
            t.model;
            translate(t.translate)
                rotate(t.rotate)
                drawTrack(track, i+1);
        } else {
            drawTrack(track, i+1);
        }
    }
}

function trans2(t, p) = p + t;
function rot2(a, p) = [ p.x*cos(a) - p.y*sin(a), p.x*sin(a) + p.y*cos(a) ];

function point(track, n, i=0) =
    i >= len(track)
    ? undef
    :
        let (t = track[i])
        t.condition
        ? point(t.link(), n)
        : t.loop
        ? point(t.loop(), n)
        : !t.model
        ? point(track, n, i+1)
        : n < t.length
        ? t.point(n)
        : trans2(t.translate, rot2(t.rotate, point(track, n-t.length, i+1)));

drawTrack(track);

module wheel(d) {
    wheel_t = 0.1;
    color("black") {
        rotate([0,-90,0])
        cylinder(h=wheel_t, d=d, center=true, $fn=20);
    }
}

truckHeight = 1;
axleD = 0.2;
truckBoxHeight = truckHeight * 0.75;
truckBoxWidth = width;
truckBoxLength = truckHeight * 0.9;
truck = {{
    for (y=[-truckHeight, truckHeight]) {
        translate([0,y,truckHeight/2]) {
            wheelPair(truckHeight);
        }
    }
    translate([-truckBoxWidth/2, -truckBoxLength/2, truckHeight-truckBoxHeight])
        color("black") cube([truckBoxWidth, truckBoxLength, truckBoxHeight]);
}};

module wheelPair(size) {
    for (a=[0,180])
        rotate(a)
            translate([width/2,0,0]) wheel(size);
    color("black") rotate([0,90,0])
        cylinder(h=width, d=axleD, center=true);
}

function steamLoco(color) =
    let(boilerWidth = 3.05, boilerLength=10, cabWidth=4, cabLength=3, cabHeight=3.05, length=boilerLength+cabLength)
    {
        length: length,
        model: {{
            color(color) {
                translate([0,cabLength,boilerWidth/2+1])
                    rotate([-90,0,0])
                    cylinder(d=boilerWidth,h=boilerLength, $fn=20);
                translate([-cabWidth/2,0,1])
                    cube([cabWidth, cabLength, cabHeight]);
            }
            wheels = [
                { pos: 0.1, size: 1 },
                { pos: 0.2, size: 1 },
                { pos: 0.35, size: 2 },
                { pos: 0.52, size: 2 },
                { pos: 0.69, size: 2 }
            ];
            for (w = wheels) {
                translate([0, length*(1-w.pos),w.size/2]) {
                    wheelPair(w.size);
                }
            }
        }}
    };

function boxcar(color) =
    let (width = 3.05, length=10, height=3.05)
    let (doorW = 2, doorT = 0.1, doorY = 5)
    let (ribW = 0.1, ribT = 0.1, nRib = 10)
    let (nEndRib = 5)
    {
        length: length,
        model: {{
            color(color) translate([0,0,truckHeight]) {
                translate([-width/2,0,0])
                    cube([width,length,height]);
                for (s = [-1,1]) {
                    translate([s*width/2, 0, height/2]) {
                        translate([0, doorY, 0])
                            cube([doorT*2, doorW, height], center=true);
                        for (i = [0:nRib]) {
                            translate([0, ribW/2 + i*(length-ribW)/nRib, 0])
                                cube([ribT*2, ribW, height], center=true);
                        }
                    }
                }
                for (y = [0, length]) {
                    translate([0, y, 0]) {
                        for (i = [0:nEndRib]) {
                            translate([0, 0, ribW/2 + i*(height-ribW)/nEndRib])
                                cube([width, 2*ribT, ribW], center=true);
                        }
                    }
                }
            }
            for (y = [0.2, 0.8]) {
                translate([0, length*y, 0]) truck;
            }
        }}
    };

function tanker(color) =
    let(width = 3.05, length=10, height=3.05)
    {
        length: length,
        model: {{
            color(color) {
                translate([0,0,truckHeight]) {
                    translate([0,0,height/2]) {
                        $fn = 20;
                        // The rotate around Z aligns the faces of the cylinder with
                        // the faces of the sphere.
                        rotate([-90,0,0]) rotate(360/$fn/2) cylinder(d=width,h=length);
                        for (y = [0, length]) {
                            translate([0,y,0]) scale([1,0.3,1]) sphere(d=height);
                        }
                    }
                    translate([0, length/2, height*0.75])
                        cylinder(h=height/3, d=width*0.5, $fn=20);
                }
            }
            for (y = [0.2, 0.8]) {
                translate([0, length*y, 0]) truck;
            }
        }}
    };

function caboose(color) = let(width = 3.05, length=10, height=3.05) {
    length: length,
    model: {{
        topLength = 2;
        topHeight = 1;
        color(color) translate([0,0,truckHeight]) {
            translate([-width/2,0,0]) cube([width,length,height]);
            translate([-width/2,length/2-topLength/2,0])
                cube([width, topLength, height+topHeight]);
        }
        translate([0,length*0.2,0]) truck;
        translate([0, length*0.8,0]) truck;
    }}
};

train = [
    steamLoco("darkgray"),
    boxcar("lightgreen"),
    tanker("silver"),
    boxcar("blue"),
    caboose("red")
];
sep = 1;

front = $t*10000;

module drawTrain(track, train, front, car=0) {
    if (car < len(train)) {
        c = train[car];
        if (front > c.length) {
            back = front - c.length;
            pfront = point(track, front);
            pback = point(track, back);
            delta = pfront-pback;
            // It would be better if this calculated the positions
            // of the forward and aft trucks, and ensured that
            // *they* were on the track.
            translate(pback)
                rotate(atan2(delta.y, delta.x)-90)
                translate([0,0,railHeight])
                c.model;
            drawTrain(track, train, front - c.length - sep, car+1);
        }
    }
}

drawTrain(track, train, front);