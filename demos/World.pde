class World {
    float scale = 250;
    float at_x = 0;
    float at_y = 0;
    float w;
    float h;
    ArrayList<Robot> robots = new ArrayList<Robot>();
    ArrayList<ArrayList<PVector>> walls = new ArrayList<ArrayList<PVector>>();
    ArrayList<Integer> colors = new ArrayList<Integer>();
    World(int w, int h) {
        this.w = w; 
        this.h = h;
        this.addWall(color(128, 0, 128), 
                     new PVector(0.0, 0.0),
                     new PVector(this.w, 0.0),
                     new PVector(this.w, 10.0),
                     new PVector(0, 10.0));
        this.addWall(color(128, 0, 128), 
                     new PVector(0, 0),
                     new PVector(0, this.h),
                     new PVector(10, this.h),
                     new PVector(10, 0));
        this.addWall(color(128, 0, 128), 
                     new PVector(0.0, this.h - 10.0),
                     new PVector(0.0, this.h),
                     new PVector(this.w, this.h),
                     new PVector(this.w, this.h - 10.0)
                     );
        this.addWall(color(128, 0, 128), 
                     new PVector(this.w - 10.0, 0.0),
                     new PVector(this.w, 0.0),
                     new PVector(this.w, this.h),
                     new PVector(this.w - 10.0, this.h));
    }
    void addBox(float x1, float y1, float x2, float y2, Integer col) {
      // add to world, scaled
      x1 = x1/this.w * this.w;
      y1 = y1/this.h * this.h;
      x2 = x2/this.w * this.w;
      y2 = y2/this.h * this.h;
      this.addWall(col, 
                     new PVector(x1, y1),
                     new PVector(x2, y1),
                     new PVector(x2, y2),
                     new PVector(x1, y2));
    }
    void addWall(float x1, float y1, float x2, float y2) {
      // add to world, scaled
      this.addBox(x1, y1, x2, y2, color(128, 0, 128));
    }
    
    void setScale(float s) {
      // scale the world... > 1 make it bigger
      this.scale = s * 250;
    }
      
    void addWall(color c, PVector v1, PVector v2, PVector v3, PVector v4) {
        this.colors.add(c);
        ArrayList<PVector> wall = new ArrayList();
        wall.add(v1);
        wall.add(v2);
        wall.add(v3);
        wall.add(v4);
        this.walls.add(wall);
    }
    void addRobot(Robot robot) {
      // scale the robot's position to this world:
      robot.x = robot.x/this.w * this.w;
      robot.y = robot.y/this.h * this.h;
      this.robots.add(robot);
      robot.world = this;
    }
    void update() {
        noStroke();
        fill(0, 128, 0);
        rect(this.at_x, this.at_y, this.w, this.h); 
        int count = 0;
        for (ArrayList<PVector> wall: this.walls) {
            color c = (color)this.colors.get(count);
            fill(c);
            beginShape();
            for (PVector v: wall) {
                vertex(v.x, v.y);
            }
            endShape();
            count++;
        }
        for (Robot robot: this.robots) {
            robot.update();
            robot.draw();
        }
    }
}