class Robot {
  float x;
  float y;
  float direction;
  boolean debug = false;
  float vx = 0.0; // velocity in x direction
  float vy = 0.0; // velocity in y direction
  float va = 0.0; // turn velocity
  World world;
  // sensors 
  boolean stalled = false;
  String state = "forward";
  float time = 0;
  float[][] bounding_box = new float[4][2];
  color robot_color = color(255, 0, 0);
  Hit[] ir_sensors = new Hit[2];
  float max_ir = 50;
  Hit[] camera = new Hit[256];
  boolean cam = false;

  Robot() {
    this.x = -1;
    this.y = -1;
    this.direction = 0;
    this.state = "forward";
  }
  Robot(float x, float y, float direction) {
    this.x = x;
    this.y = y;
    this.direction = direction;
    this.state = "forward";
  }
  void forward(float vx) {
    this.vx = vx;
  }
  void backward(float vx) {
    this.vx = -vx;
  }
  float getIR(int pos) {
    // 0 is on right, front
    // 1 is on left, front
    if (this.ir_sensors[pos] != null) {
      return this.ir_sensors[pos].distance/(this.max_ir/250.0 * this.world.scale);
    } else {
      return 1.0;
    }
  }
  PImage takePicture() {
    PImage pic = new PImage(256, 128);
    float size = max(this.world.w, this.world.h);
    for (int i=0; i<this.camera.length; i++) {
      Hit hit = this.camera[i];
      float high;
      Integer hcolor = null;
      if (hit != null) {
        float s = max(min(1.0 - hit.distance/size, 1.0), 0.0);
        float r = red(hit.col);
        float g = green(hit.col);
        float b = blue(hit.col);
        hcolor = color(r * s, g * s, b * s);
        high = (1.0 - s) * 128;
        //pg.line(i, 0 + high/2, i, 128 - high/2);
      } else {
        high = 0;
      }
      for (int j = 0; j < 128; j++) {
        if (j < high/2) { //256 - high/2.0) { // sky
          pic.set(i, j, color(0, 0, 128));
        } else if (j < 128 - high/2) { //256 - high && hcolor != null) { // hit
        if (hcolor != null)
          pic.set(i, j, hcolor);
        } else { // ground
          pic.set(i, j, color(0, 128, 0));
        }
      }
    }
    return pic;
  }
  void turn(float va) {
    this.va = va;
  }
  void stop() {
    this.vx = 0.0;
    this.vy = 0.0;
    this.va = 0.0;
  }
  boolean ccw(float ax, float ay, 
  float bx, float by, 
  float cx, float cy) {
    // counter clockwise
    return (((cy - ay) * (bx - ax)) > ((by - ay) * (cx - ax)));
  }
  boolean intersect(float ax, float ay, 
  float bx, float by, 
  float cx, float cy, 
  float dx, float dy) {
    // Return true if line segments AB and CD intersect
    return (this.ccw(ax, ay, cx, cy, dx, dy) != this.ccw(bx, by, cx, cy, dx, dy) && 
      this.ccw(ax, ay, bx, by, cx, cy) != this.ccw(ax, ay, bx, by, dx, dy));
  }

  float[] coefs(float p1x, float p1y, float p2x, float p2y) {
    float A = (p1y - p2y);
    float B = (p2x - p1x);
    float C = (p1x * p2y - p2x * p1y);
    return new float[] {
      A, B, -C
    };
  }

  float[] intersect_coefs(float L1_0, float L1_1, float L1_2, 
  float L2_0, float L2_1, float L2_2) {
    float D  = L1_0 * L2_1 - L1_1 * L2_0;
    float Dx = L1_2 * L2_1 - L1_1 * L2_2;
    float Dy = L1_0 * L2_2 - L1_2 * L2_0;
    if (D != 0) {
      float x1 = Dx / D;
      float y1 = Dy / D;
      return new float[] {
        x1, y1
      };
    } else {
      return null;
    }
  }
  float[] intersect_hit(float p1x, float p1y, float p2x, float p2y, 
  float p3x, float p3y, float p4x, float p4y ) {
    // http://stackoverflow.com/questions/20677795/find-the-point-of-intersecting-lines
    float[] L1 = coefs(p1x, p1y, p2x, p2y);
    float[] L2 = coefs(p3x, p3y, p4x, p4y);
    float[] xy = intersect_coefs(L1[0], L1[1], L1[2], 
    L2[0], L2[1], L2[2]);
    // now check to see on both segments:
    if (xy != null) {
      float lowx = min(p1x, p2x) - .1;
      float highx = max(p1x, p2x) + .1;
      float lowy = min(p1y, p2y) - .1;
      float highy = max(p1y, p2y) + .1;
      if (lowx <= xy[0] && xy[0] <= highx && 
        lowy <= xy[1] && xy[1] <= highy) {
        lowx = min(p3x, p4x) - .1;
        highx = max(p3x, p4x) + .1;
        lowy = min(p3y, p4y) - .1;
        highy = max(p3y, p4y) + .1;
        if (lowx <= xy[0] && xy[0] <= highx && 
          lowy <= xy[1] && xy[1] <= highy) {
          return xy;
        }
      }
    }
    return null;
  }
  float distance(float x1, float y1, float x2, float y2) {
    return sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2));
  } 
  Hit castRay(float x1, float y1, float a, float maxRange) {
    ArrayList<Hit> hits = new ArrayList<Hit>();
    float x2 = sin(a) * maxRange + x1;
    float y2 = cos(a) * maxRange + y1;
    int count = 0;
    for (ArrayList<PVector> wall : this.world.walls) {
      // if intersection, can't move
      PVector v1 = wall.get(0);
      PVector v2 = wall.get(1);
      PVector v3 = wall.get(2);
      PVector v4 = wall.get(3);
      float[] pos = this.intersect_hit(x1, y1, x2, y2, 
      v1.x, v1.y, v2.x, v2.y);
      if (pos != null) {
        color col = this.world.colors.get(count);
        float dist = this.distance(pos[0], pos[1], x1, y1);
        hits.add(new Hit(pos[0], pos[1], dist, col, x1, y1));
      }
      pos = this.intersect_hit(x1, y1, x2, y2, 
      v2.x, v2.y, v3.x, v3.y);
      if (pos != null) {
        color col = this.world.colors.get(count);
        float dist = this.distance(pos[0], pos[1], x1, y1);
        hits.add(new Hit(pos[0], pos[1], dist, col, x1, y1));
      }
      pos = this.intersect_hit(x1, y1, x2, y2, 
      v3.x, v3.y, v4.x, v4.y);
      if (pos != null) {
        color col = this.world.colors.get(count);
        float dist = this.distance(pos[0], pos[1], x1, y1);
        hits.add(new Hit(pos[0], pos[1], dist, col, x1, y1));
      }
      pos = this.intersect_hit(x1, y1, x2, y2, 
      v4.x, v4.y, v1.x, v1.y);
      if (pos != null) {
        color col = this.world.colors.get(count);
        float dist = this.distance(pos[0], pos[1], x1, y1);
        hits.add(new Hit(pos[0], pos[1], dist, col, x1, y1));
      }
      count++;
    }
    if (hits.size() == 0) {
      return null;
    } else {
      return min_hit(hits);
    }
  }
  Hit min_hit(ArrayList<Hit> hits) {
    Hit minimum = hits.get(0);
    for (Hit hit : hits) {
      if (hit.distance < minimum.distance) {
        minimum = hit;
      }
    }
    return minimum;
  }
  void brain() {
    // will be overridden
  }
  void update() {
    this.brain();
    float scale = this.world.scale;
    //this.direction += PI/180;
    float tvx = this.vx * sin(-this.direction + PI/2) + this.vy * cos(-this.direction + PI/2);
    float tvy = this.vx * cos(-this.direction + PI/2) - this.vy * sin(-this.direction + PI/2);
    // proposed positions:
    float px = this.x + tvx/250.0 * scale; 
    float py = this.y + tvy/250.0 * scale; 
    float pdirection = this.direction - this.va; 
    // check to see if collision
    // bounding box:
    float[] p1 = rotateAround(px, py, 30/250.0 * scale, pdirection + PI/4 + 0 * PI/2);
    float[] p2 = rotateAround(px, py, 30/250.0 * scale, pdirection + PI/4 + 1 * PI/2);
    float[] p3 = rotateAround(px, py, 30/250.0 * scale, pdirection + PI/4 + 2 * PI/2);
    float[] p4 = rotateAround(px, py, 30/250.0 * scale, pdirection + PI/4 + 3 * PI/2);
    this.bounding_box[0] = p1;
    this.bounding_box[1] = p2;
    this.bounding_box[2] = p3;
    this.bounding_box[3] = p4;
    this.stalled = false;
    for (ArrayList<PVector> wall : this.world.walls) {
      // if intersection, can't move
      PVector v1 = wall.get(0);
      PVector v2 = wall.get(1);
      PVector v3 = wall.get(2);
      PVector v4 = wall.get(3);
      if ( // p1 to p2
      this.intersect(p1[0], p1[1], p2[0], p2[1], 
      v1.x, v1.y, v2.x, v2.y) ||
        this.intersect(p1[0], p1[1], p2[0], p2[1], 
      v2.x, v2.y, v3.x, v3.y) ||
        this.intersect(p1[0], p1[1], p2[0], p2[1], 
      v3.x, v3.y, v4.x, v4.y) ||
        this.intersect(p1[0], p1[1], p2[0], p2[1], 
      v4.x, v4.y, v1.x, v1.y) ||
        // p2 to p3
      this.intersect(p2[0], p2[1], p3[0], p3[1], 
      v1.x, v1.y, v2.x, v2.y) ||
        this.intersect(p2[0], p2[1], p3[0], p3[1], 
      v2.x, v2.y, v3.x, v3.y) ||
        this.intersect(p2[0], p2[1], p3[0], p3[1], 
      v3.x, v3.y, v4.x, v4.y) ||
        this.intersect(p2[0], p2[1], p3[0], p3[1], 
      v4.x, v4.y, v1.x, v1.y) ||
        // p3 to p4
      this.intersect(p3[0], p3[1], p4[0], p4[1], 
      v1.x, v1.y, v2.x, v2.y) ||
        this.intersect(p3[0], p3[1], p4[0], p4[1], 
      v2.x, v2.y, v3.x, v3.y) ||
        this.intersect(p3[0], p3[1], p4[0], p4[1], 
      v3.x, v3.y, v4.x, v4.y) ||
        this.intersect(p3[0], p3[1], p4[0], p4[1], 
      v4.x, v4.y, v1.x, v1.y) ||
        // p4 to p1
      this.intersect(p4[0], p4[1], p1[0], p1[1], 
      v1.x, v1.y, v2.x, v2.y) ||
        this.intersect(p4[0], p4[1], p1[0], p1[1], 
      v2.x, v2.y, v3.x, v3.y) ||
        this.intersect(p4[0], p4[1], p1[0], p1[1], 
      v3.x, v3.y, v4.x, v4.y) ||
        this.intersect(p4[0], p4[1], p1[0], p1[1], 
      v4.x, v4.y, v1.x, v1.y)) {
        this.stalled = true;
        break;
        //this.x = this.x - tvx/250.0 * scale; 
        //this.y = this.y - tvy/250.0 * scale;
      }
    }
    if (! this.stalled) {
      // if no intersection, make move
      this.x = px; 
      this.y = py; 
      this.direction = pdirection; 
      if (tvx != 0 && random(1.0) < .01) {
        //this.direction += random(.1) - .05; // a bit of noise
      }
    } else {
      //this.direction += random(.2) - .1;
    }
    // update sensors, camera
    // on right:
    float[] p = rotateAround(this.x, this.y, 25/250.0 * scale, this.direction + PI/8);
    Hit hit = this.castRay(p[0], p[1], -this.direction + PI/2.0, this.max_ir/250.0 * scale);
    if (hit != null) {
      if (this.debug) {
        fill(0, 255, 0);
        ellipse(p[0], p[1], 5, 5);
        ellipse(hit.x, hit.y, 5, 5);
      }
      this.ir_sensors[0] = hit;
    } else {
      this.ir_sensors[0] = null;
    }
    p = rotateAround(this.x, this.y, 25/250.0 * scale, this.direction - PI/8);
    hit = this.castRay(p[0], p[1], -this.direction + PI/2, this.max_ir/250.0 * scale);
    if (hit != null) {
      if (this.debug) {
        fill(0, 0, 255);
        ellipse(p[0], p[1], 5, 5);
        ellipse(hit.x, hit.y, 5, 5);
      }
      this.ir_sensors[1] = hit;
    } else {
      this.ir_sensors[1] = null;
    }
    // camera:
    for (int i=0; i<256; i++) {
      float angle = i/256.0 * 60 - 30;  
      this.camera[i] = this.castRay(this.x, this.y, -this.direction + PI/2.0 - angle*PI/180.0, 1000);
    } 
  }
  float[] rotateAround(float x1, float y1, float length, float angle) {
    return new float[] {
      x1 + length * cos(-angle), 
      y1 - length * sin(-angle)
    };
  }
  void draw() {
    float scale = this.world.scale;
    float [] sx = new float[] {
      0.05, 0.05, 0.07, 0.07, 0.09, 0.09, 0.07, 
      0.07, 0.05, 0.05, -0.05, -0.05, -0.07, 
      -0.08, -0.09, -0.09, -0.08, -0.07, -0.05, 
      -0.05
    };
    float [] sy = new float[] {
      0.06, 0.08, 0.07, 0.06, 0.06, -0.06, -0.06, 
      -0.07, -0.08, -0.06, -0.06, -0.08, -0.07, 
      -0.06, -0.05, 0.05, 0.06, 0.07, 0.08, 0.06
    };
    if (this.debug) {
      stroke(255);
      // bounding box:
      float[] p1 = rotateAround(this.x, this.y, 30/250.0 * scale, this.direction + PI/4.0 + 0 * PI/2.0);
      float[] p2 = rotateAround(this.x, this.y, 30/250.0 * scale, this.direction + PI/4.0 + 1 * PI/2.0);
      float[] p3 = rotateAround(this.x, this.y, 30/250.0 * scale, this.direction + PI/4.0 + 2 * PI/2.0);
      float[] p4 = rotateAround(this.x, this.y, 30/250.0 * scale, this.direction + PI/4.0 + 3 * PI/2.0);
      line(p1[0], p1[1], p2[0], p2[1]);
      line(p2[0], p2[1], p3[0], p3[1]);
      line(p3[0], p3[1], p4[0], p4[1]);
      line(p4[0], p4[1], p1[0], p1[1]);
    }
    pushMatrix();
    translate(this.x, this.y);
    rotate(this.direction);
    // body:
    if (this.stalled) {
      fill(128, 128, 128);
      stroke(255);
    } else {
      fill(this.robot_color);
      noStroke();
    }
    beginShape();
    for (int i =0; i < sx.length; i++) {
      vertex(sx[i] * scale, sy[i] * scale);
    }
    endShape();
    noStroke();
    // Draw wheels:
    fill(0);
    rect(-10/250.0 * scale, -23/250.0 * scale, 19/250.0 * scale, 5/250.0 * scale);
    rect(-10/250.0 * scale, 18/250.0 * scale, 19/250.0 * scale, 5/250.0 * scale);
    // hole:
    fill(0, 64, 0);
    ellipse(0, 0, 7/250.0 * scale, 7/250.0 * scale);
    // fluke
    fill(0, 64, 0);
    rect(15/250.0 * scale, -10/250.0 * scale, 4/250.0 * scale, 19/250.0 * scale);
    popMatrix();
    // draw sensors
    // right front IR
    // position of start of sensor:
    float[] p1 = rotateAround(this.x, this.y, 25/250.0 * scale, this.direction + PI/8);
    // angle of sensor:
    float[] p2 = rotateAround(p1[0], p1[1], this.getIR(0) * this.max_ir/250.0 * scale, this.direction);
    float dist = this.distance(p1[0], p1[1], p2[0], p2[1]);
    if (this.getIR(0) < 1.0) {
      stroke(255);
    }
    fill(128, 0, 128, 64);
    arc(p1[0], p1[1], dist * 2, dist * 2, 
    this.direction - .5, this.direction + .5);
    // left front IR
    p1 = rotateAround(this.x, this.y, 25/250.0 * scale, this.direction - PI/8);
    p2 = rotateAround(p1[0], p1[1], this.getIR(1) * this.max_ir/250.0 * scale, this.direction);
    dist = this.distance(p1[0], p1[1], p2[0], p2[1]);
    if (this.getIR(1) < 1.0) {
      stroke(255);
    }
    fill(128, 0, 128, 64);
    arc(p1[0], p1[1], dist * 2, dist * 2, 
    this.direction - .5, this.direction + .5);
  }
}
