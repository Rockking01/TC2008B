Crop[][] crops;
ArrayList<Tractor> tractors;
ArrayList<Truck> trucks;
int rows = 20;      
int cols = 20;      
int cropSize = 10; 
int waitTime = 2000; 
int fuelCount = 0;   
int energyCount = 0; 
int fuelIncreaseRate = 10;   
int energyIncreaseRate = 30; 

void setup() {
  size(800, 600);
  crops = new Crop[rows][cols];
  for (int i = 0; i < rows; i++) {
    for (int j = 0; j < cols; j++) {
      int x = j * (width / cols) + cropSize / 2;
      int y = i * (height / rows) + cropSize / 2;
      crops[i][j] = new Crop(x, y);
    }
  }
  
  tractors = new ArrayList<Tractor>();
  trucks = new ArrayList<Truck>();
  
  tractors.add(new Tractor(2, width, height));
  tractors.add(new Tractor(2, width, height));
  
  for (Tractor tractor : tractors) {
    trucks.add(new Truck(tractor.x, tractor.y));
  }
}

void draw() {
  background(0, 128, 0);

  for (Crop[] cropRow : crops) {
    for (Crop crop : cropRow) {
      crop.display();
    }
  }

  if (millis() % fuelIncreaseRate == 0) {
    fuelCount++;
  }
  
  if (millis() % energyIncreaseRate == 0) {
    energyCount++;
  }

  fill(255);
  textSize(16);
  text("Combustible gastado: " + fuelCount + " | Energía gastada: " + energyCount, 170, 10);

  for (int i = 0; i < tractors.size(); i++) {
    Tractor tractor = tractors.get(i);
    Truck truck = trucks.get(i);

    boolean waiting = tractor.isWaiting();

    if (!waiting) {
      if (tractor.getCropsCollected() % 20 != 0 || tractor.getCropsCollected() == 0) {
        tractor.move(crops);
      }
    }
    tractor.display();

    for (Crop[] cropRow : crops) {
      for (Crop crop : cropRow) {
        if (tractor.isCloseToCrop(crop)) {
          if (!crop.collected) {
            crop.collected = true;
            tractor.incrementCropsCollected();
            if (tractor.getCropsCollected() % 20 == 0) {
              tractor.startWaiting();
            }
          }
        }
      }
    }
    if (waiting) {
      int elapsedTime = millis() - tractor.getStartTime();
      if (elapsedTime >= waitTime) {
        tractor.stopWaiting();
        tractor.resetCropsCollected();
      }
    }
    truck.follow(tractor.x, tractor.y, tractor.getCropsCollected(), tractor.isWaiting());
    truck.display();
    if (truck.shouldRemove()) {
      truck.stopFollowing(); 
      truck.resetCropsInside(); 
      float truckX = truck.x;
      float truckY = truck.y;
      trucks.remove(i);
      trucks.add(i, new Truck(truckX, truckY));
    }
  }
}

class Crop {
  int x, y;
  boolean collected = false;

  Crop(int x, int y) {
    this.x = x;
    this.y = y;
  }

  void display() {
    if (!collected) {
      fill(139, 69, 19);
      ellipse(x, y, cropSize, cropSize);
    }
  }
}

class Tractor {
  float x, y;
  int speed;
  int fieldWidth, fieldHeight;
  private int cropsCollected = 0; 
  private boolean waiting = false;
  private int startTime = 0;

  Tractor(int speed, int fieldWidth, int fieldHeight) {
    this.speed = speed;
    this.fieldWidth = fieldWidth;
    this.fieldHeight = fieldHeight;
    int randomEdge = int(random(4)); 
    if (randomEdge == 0) { 
      this.x = random(fieldWidth);
      this.y = 0;
    } else if (randomEdge == 1) {
      this.x = fieldWidth;
      this.y = random(fieldHeight);
    } else if (randomEdge == 2) { 
      this.x = random(fieldWidth);
      this.y = fieldHeight;
    } else if (randomEdge == 3) { 
      this.x = 0;
      this.y = random(fieldHeight);
    }
  }

  void move(Crop[][] crops) {
    Crop closestCrop = findClosestCrop(crops);
    if (closestCrop != null) {
      float dx = closestCrop.x - x;
      float dy = closestCrop.y - y;
      float angle = atan2(dy, dx);
      x += cos(angle) * speed;
      y += sin(angle) * speed;
    }
  }

  Crop findClosestCrop(Crop[][] crops) {
    Crop closestCrop = null;
    float closestDistance = Float.MAX_VALUE;
    
    for (Crop[] cropRow : crops) {
      for (Crop crop : cropRow) {
        if (!crop.collected) {
          float distance = dist(x, y, crop.x, crop.y);
          if (distance < closestDistance) {
            closestCrop = crop;
            closestDistance = distance;
          }
        }
      }
    }
    
    return closestCrop;
  }

  boolean isCloseToCrop(Crop crop) {
    if (!crop.collected) {
      float distance = dist(x, y, crop.x, crop.y);
      return distance <= cropSize / 2;
    }
    return false;
  }

  void display() {
    fill(255, 0, 0);
    ellipse(x, y, 20, 20);
    fill(255);
    textSize(12);
    textAlign(CENTER, CENTER);
    text("Tractor", x, y + 15);
    text(cropsCollected, x, y);
  }

  int getCropsCollected() {
    return cropsCollected;
  }
  
  void incrementCropsCollected() {
    cropsCollected++;
  }
  
  void resetCropsCollected() {
    cropsCollected = 0;
  }
  
  boolean isWaiting() {
    return waiting;
  }
  
  void startWaiting() {
    waiting = true;
    startTime = millis();
  }
  
  void stopWaiting() {
    waiting = false;
  }
  
  int getStartTime() {
    return startTime;
  }
}

class Truck {
  float x, y;
  float speed = 1.9;
  int truckSize = 20;
  int cropsInside = 0; 
  boolean tractorStopped = false;
  boolean shouldRemove = false; 
  private boolean followingTractor = true;
  private boolean tractorMoved = true;
  Truck(float initialX, float initialY) {
    x = initialX;
    y = initialY;
  }
  
  void stopFollowing() {
    followingTractor = false;
  }
  
   void follow(float targetX, float targetY, int tractorCropsCollected, boolean isTractorWaiting) {
    if (!followingTractor) {
      return;
    }
    float dx = targetX - x;
    float dy = targetY - y;
    float distance = sqrt(dx * dx + dy * dy);

    if (isTractorWaiting) {
      if (!tractorStopped) {
        tractorStopped = true;
        cropsInside += tractorCropsCollected;
        tractorCropsCollected = 0;

        if (cropsInside >= 100) {
          cropsInside = 0;
          shouldRemove = true;
        }
      }
      
      float stoppingDistance = 40;
      if (distance > stoppingDistance) {
        x += dx * speed / distance;
        y += dy * speed / distance;
      } else {
        x = targetX - dx * stoppingDistance / distance;
        y = targetY - dy * stoppingDistance / distance;
      }
    } else {
      tractorStopped = false;
      if (distance > 1) {
        x += dx * speed / distance;
        y += dy * speed / distance;
      }
    }
  }
  void resetCropsInside() {
    cropsInside = 0;
    shouldRemove = false; 
    tractorMoved = false;
  }

  void display() {
    fill(0, 0, 255);
    ellipse(x, y, truckSize, truckSize);
    fill(255);
    textSize(12);
    textAlign(CENTER, CENTER);
    text("Camión", x, y + 15); 
    text(cropsInside, x, y);
  }

  boolean shouldRemove() {
    return shouldRemove;
  }
}
