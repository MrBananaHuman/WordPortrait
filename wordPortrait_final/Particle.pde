ArrayList<Particle> particles = new ArrayList<Particle>();
int pixelSteps = 6; // Amount of pixels to skip
boolean drawAsPoints = false;
ArrayList<String> particleWords = new ArrayList<String>();
int wordIndex = 0;
color bgColor = color(255, 100);
String fontName = "Arial";

public class Particle {
  PVector pos = new PVector(0, 0);
  PVector vel = new PVector(0, 0);
  PVector acc = new PVector(0, 0);
  PVector target = new PVector(0, 0);

  float closeEnoughTarget = 50;
  float maxSpeed = 4.0;
  float maxForce = 0.1;
  float particleSize = 50;
  boolean isKilled = false;

  color startColor = color(0);
  color targetColor = color(0);
  float colorWeight = 0;
  float colorBlendRate = 0.025;
  float distance = 0;

  public void particleSetup() {
    particleWords.add("Who are you?");
    particleWords.add("Hello? :-)");
    particleWords.add("Nice to meet you");
    particleWords.add("Welcome :-)");
    particleWords.add("Meet your inside");
    
    nextWord(particleWords.get(wordIndex));
  }
  public PVector generateRandomPos(int x, int y, float mag) {
    PVector sourcePos = new PVector(x, y);
    PVector randomPos = new PVector(random(0, width), random(0, height));

    PVector direction = PVector.sub(randomPos, sourcePos);
    direction.normalize();
    direction.mult(mag);
    sourcePos.add(direction);

    return sourcePos;
  }

  public void nextWord(String word) {
    // Draw word in memory
    PGraphics pg = createGraphics(width, height);
    pg.beginDraw();
    pg.fill(0);
    pg.textSize(100);
    pg.textAlign(CENTER);
    PFont font = createFont(fontName, 100);
    pg.textFont(font);
    pg.text(word, width/2, height/2);
    pg.endDraw();
    pg.loadPixels();

    // Next color for all pixels to change to
    color newColor = color(random(0.0, 255.0), random(0.0, 255.0), random(0.0, 255.0));

    int particleCount = particles.size();
    int particleIndex = 0;

    // Collect coordinates as indexes into an array
    // This is so we can randomly pick them to get a more fluid motion
    ArrayList<Integer> coordsIndexes = new ArrayList<Integer>();
    for (int i = 0; i < (width*height)-1; i+= pixelSteps) {
      coordsIndexes.add(i);
    }

    for (int i = 0; i < coordsIndexes.size (); i++) {
      // Pick a random coordinate
      int randomIndex = (int)random(0, coordsIndexes.size());
      int coordIndex = coordsIndexes.get(randomIndex);
      coordsIndexes.remove(randomIndex);

      // Only continue if the pixel is not blank
      if (pg.pixels[coordIndex] != 0) {
        // Convert index to its coordinates
        int x = coordIndex % width;
        int y = coordIndex / width;

        Particle newParticle;

        if (particleIndex < particleCount) {
          // Use a particle that's already on the screen 
          newParticle = particles.get(particleIndex);
          newParticle.isKilled = false;
          particleIndex += 1;
        } else {
          // Create a new particle
          newParticle = new Particle();

          PVector randomPos = generateRandomPos(width/2, height/2, (width+height)/2);
          newParticle.pos.x = randomPos.x;
          newParticle.pos.y = randomPos.y;

          newParticle.maxSpeed = random(2.0, 5.0);
          newParticle.maxForce = newParticle.maxSpeed*0.025;
          newParticle.particleSize = random(3, 6);
          newParticle.colorBlendRate = random(0.0025, 0.03);

          particles.add(newParticle);
        }

        // Blend it from its current color
        newParticle.startColor = lerpColor(newParticle.startColor, newParticle.targetColor, newParticle.colorWeight);
        newParticle.targetColor = newColor;
        newParticle.colorWeight = 0;

        // Assign the particle's new target to seek
        newParticle.target.x = x;
        newParticle.target.y = y;
      }
    }

    // Kill off any left over particles
    if (particleIndex < particleCount) {
      for (int i = particleIndex; i < particleCount; i++) {
        Particle particle = particles.get(i);
        particle.kill();
      }
    }
    if(wordIndex > particleWords.size()-1){
      wordIndex = 0;
    } else{
      wordIndex++;
    }
  }
  void move() {
    // Check if particle is close enough to its target to slow down
    float proximityMult = 1.5;
    distance = dist(this.pos.x, this.pos.y, this.target.x, this.target.y);
    if (distance < this.closeEnoughTarget) {
      proximityMult = distance/this.closeEnoughTarget;
    }

    // Add force towards target
    PVector towardsTarget = new PVector(this.target.x, this.target.y);
    towardsTarget.sub(this.pos);
    towardsTarget.normalize();
    towardsTarget.mult(this.maxSpeed*proximityMult);

    PVector steer = new PVector(towardsTarget.x, towardsTarget.y);
    steer.sub(this.vel);
    steer.normalize();
    steer.mult(this.maxForce);
    this.acc.add(steer);

    // Move particle
    this.vel.add(this.acc);
    this.pos.add(this.vel);
    this.acc.mult(0);
  }

  void draw() {
    // Draw particle
    color currentColor = lerpColor(this.startColor, this.targetColor, this.colorWeight);
    if (drawAsPoints) {
      stroke(currentColor);
      point(this.pos.x, this.pos.y);
    } else {
      noStroke();
      fill(currentColor);
      ellipse(this.pos.x, this.pos.y, this.particleSize, this.particleSize);
    }

    // Blend towards its target color
    if (this.colorWeight < 1.0) {
      this.colorWeight = min(this.colorWeight+this.colorBlendRate, 1.0);
    }
  }

  void kill() {
    if (! this.isKilled) {
      // Set its target outside the scene
      PVector randomPos = generateRandomPos(width/2, height/2, (width+height)/2);
      this.target.x = randomPos.x;
      this.target.y = randomPos.y;

      // Begin blending its color to black
      this.startColor = lerpColor(this.startColor, this.targetColor, this.colorWeight);
      this.targetColor = color(0);
      this.colorWeight = 0;

      this.isKilled = true;
    }
  }
}
