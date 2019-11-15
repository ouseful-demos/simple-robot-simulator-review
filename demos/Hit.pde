class Hit {
    float distance;
    float x;
    float y;
    float start_x;
    float start_y;
    color col;
    Hit(float x, float y, float distance, color col, 
        float start_x, float start_y) {
      this.x = x;
      this.y = y;
      this.distance = distance;
      this.col = col;
      this.start_x = start_x;
      this.start_y = start_y;
    }
}