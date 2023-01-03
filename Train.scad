// Model railroad
// Eventually for SCADvent?

width = 1.435;
thickness = 0.127;    // guess
s1 = true;

module stop() {}

$fa = 1;

rail = {{
    polygon([
        [-.08,0],
        [-.05,.12],
        [.05,.12],
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

function length(track, i=0) =
    i >= len(track) || track[i].loop
    ? 0
    : track[i].model
    ? track[i].length + length(track, i+1)
    : length(track, i+1);
    
drawTrack(track);

module wheel(d) {
    color("black")
        translate([0,0,d/2])
        rotate([0,90,0])
        cylinder(h=width, d=d, center=true, $fn=20);
}

truckHeight = 1;
truck = {{
    for (y=[-truckHeight/2, truckHeight/2]) {
        translate([0,y,0]) wheel(truckHeight);
    }
}};

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
            for (y=[0.1,0.2]) translate([0, length*(1-y),0]) wheel(1);
            for (y=[0.35,0.52,0.69]) translate([0, length*(1-y),0]) wheel(2);
        }}
    };

function boxcar(color) =
    let(width = 3.05, length=10, height=3.05)
    {
        length: length,
        model: {{
            color(color) translate([-width/2,0,truckHeight])
                cube([width,length,height]);
            translate([0,length*0.2,0]) truck;
            translate([0, length*0.8,0]) truck;
        }}
    };

function tanker(color) =
    let(width = 3.05, length=10, height=3.05)
    {
        length: length,
        model: {{
            color(color) translate([0,0,height/2+truckHeight])
                rotate([-90,0,0]) cylinder(d=width,h=length, $fn=20);
            translate([0,length*0.2,0]) truck;
            translate([0, length*0.8,0]) truck;
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

front = $t*length(track)*3;

module drawTrain(track, train, front, car=0) {
    if (car < len(train)) {
        c = train[car];
        if (front > c.length) {
            back = front - c.length;
            pfront = point(track, front);
            pback = point(track, back);
            delta = pfront-pback;
            translate(pback)
                rotate(atan2(delta.y, delta.x)-90)
                c.model;
            drawTrain(track, train, front - c.length - sep, car+1);
        }
    }
}

drawTrain(track, train, front);