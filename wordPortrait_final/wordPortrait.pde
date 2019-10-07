import processing.video.*;
import java.util.Collections;

import gab.opencv.*;
import java.awt.Rectangle;

import org.opencv.core.Mat;
import org.opencv.core.Core;
import org.opencv.core.Mat;
import org.opencv.core.Size;
import org.opencv.core.Point;
import org.opencv.core.Scalar;
import org.opencv.core.CvType;
import org.opencv.imgproc.Imgproc;

OpenCV opencv;
Capture cam;
PImage smaller;
Rectangle[] faces;

int scale = 5;
int cur_x = 1;
int cur_y = 1;
int cur_width = 1;
int cur_height = 1;
int startTime = 0;
int stopTime = 0;

boolean startFlag = false;
boolean faceDetectFlag = false;
boolean captureFlag = false;
boolean saveFlag = false;
boolean drawFlag = false;
boolean resetFlag = false;

float face_center_x = 0.0f;
float face_center_y = 0.0f;
float face_size = 0.0f;

float[] bright;

String[] words;

ArrayList<CharObj> charObjs = new ArrayList<CharObj>();
ArrayList<Integer> brightPixels = new ArrayList<Integer>();
ArrayList<String> randomWords = new ArrayList<String>();
ArrayList<Integer> randomWordSize = new ArrayList<Integer>();

int randomNum;
int frameNum = 1;
int maxFrameNum = 400;
int setFrameNum = 0;

Particle particle = new Particle();

void captureEvent(Capture cam) {
  cam.read();
  smaller.copy(cam, 0, 0, cam.width, cam.height, 0, 0, smaller.width, smaller.height);
  smaller.updatePixels();
}

String fileName() {
  int M = month();
  int d = day();
  int s = second();
  int m = minute();
  int h = hour();
  String fileName = M + "" + d +"" + h + "" + m + "" + s + ".jpg";
  return fileName;
}

Scalar colorToScalar(color c) {
  return new Scalar(blue(c), green(c), red(c));
}

int setFrame(int frameNum) {
  int frame = floor(sqrt(frameNum));
  return frame;
}

void setup() {
  fullScreen(P3D, 2);
  cam = new Capture(this, 640, 480, "/dev/video1");
  cam.start();

  opencv = new OpenCV(this, cam.width/scale, cam.height/scale);
  opencv.loadCascade(OpenCV.CASCADE_FRONTALFACE); 

  smaller = createImage(opencv.width, opencv.height, RGB);  

  words = loadStrings("sentiWord_modi.txt");

  background(0);

  particle.particleSetup();
}

void draw() {
  if (faceDetectFlag == false && captureFlag == false) {
    fill(bgColor);
    noStroke();
    background(0);
    for (int x = particles.size ()-1; x > -1; x--) {
      // Simulate and draw pixels
      Particle particle = particles.get(x);
      particle.move();
      particle.draw();

      // Remove any dead pixels out of bounds
      if (particle.isKilled) {
        if (particle.pos.x < 0 || particle.pos.x > 700 || particle.pos.y < 0 || particle.pos.y > 300) {
          particles.remove(particle);
        }
      }
    }
    //background(0);
    frameNum = 1;
    maxFrameNum = 400;
    setFrameNum = 0;

    opencv.loadImage(smaller);
    faces = opencv.detect();
    if (faces.length > 0) {
      if (startFlag == false) {
        startTime = millis();
        startFlag = true;
      } else {
        stopTime = millis();
        if (stopTime - startTime > 3000) {
          for (int i = 0; i < faces.length; i++) {
            if (abs(cur_x - faces[i].x * scale) > 80) {
              cur_x = faces[i].x * scale;
            }
            if (abs(cur_y - faces[i].y * scale) > 80) {
              cur_y = faces[i].y * scale;
            }
            if (abs(cur_width - faces[i].width * scale) > 80) {
              cur_width = faces[i].width * scale;
            }
            if (abs(cur_height - faces[i].height * scale) > 80) {
              cur_height = faces[i].height * scale;
            }
          }
          faceDetectFlag = true;
          face_center_x = cur_width;
          face_center_y = cur_height;
          face_size = cur_width;
        }
      }
    } else {
      int finishParticleNum = 0;
      for (int x = particles.size ()-1; x > -1; x--) {
        Particle particle = particles.get(x);
        if (particle.distance < 10) {
          finishParticleNum++;
        }
      }
      if(finishParticleNum == particles.size()){
        particle.particleSetup();
      }
    }
  }

  if (faceDetectFlag == true && captureFlag == false) {
    background(0);
    PImage myImage = cam.get(cur_x-80, cur_y-80, cur_width+160, cur_height+160); 
    PImage flipped = createImage(myImage.width, myImage.height, RGB);
    for (int i = 0; i < flipped.pixels.length; i++) {
      int srcX = i % flipped.width;
      int dstX = flipped.width-srcX-1;
      int y    = i / flipped.width;
      flipped.pixels[y*flipped.width+dstX] = myImage.pixels[i];
    }
    captureFlag = true;
    flipped.updatePixels();
    /***/
    for (int x = 0; x < flipped.width; x++) {    
      for (int y = 0; y < flipped.height; y++) {      
        // Calculate the 1D location from a 2D grid
        int loc = x + y * flipped.width;  

        // Get the red, green, blue values from a pixel      
        float r = red  (flipped.pixels[loc]);      
        float g = green(flipped.pixels[loc]);      
        float b = blue (flipped.pixels[loc]);      

        // Calculate an amount to change brightness based on proximity to the mouse      
        float d = dist(x, y, face_center_x, face_center_y);      
        float adjustbrightness = map(d, 0, face_size, 1, 0);      
        r *= adjustbrightness;      
        g *= adjustbrightness;      
        b *= adjustbrightness;      

        // Constrain RGB to make sure they are within 0-255 color range      
        r = constrain(r, 0, 255);      
        g = constrain(g, 0, 255);      
        b = constrain(b, 0, 255);      

        // Make a new color and set pixel in the window      
        color c = color(r, g, b);      
        flipped.pixels[loc] = c;
      }
    }
    String fileName = fileName();
    flipped.save(fileName);
    saveFlag = true;

    if (saveFlag == true && drawFlag == false) {

      PImage portraitImage;
      portraitImage = loadImage(fileName);
      charObjs = new ArrayList<CharObj>();
      brightPixels = new ArrayList<Integer>();
      randomWords = new ArrayList<String>();
      randomWordSize = new ArrayList<Integer>();
      frameNum = 1;
      setFrameNum = 0;

      if (width > height) {
        portraitImage.resize(height, height);
      } else {
        portraitImage.resize(width, width);
      }
      for (int y = 0; y < portraitImage.height; y++) {
        for (int x = 0; x < portraitImage.width; x++) {
          int loc = x + y * portraitImage.width;

          float r = red  (portraitImage.pixels[loc]);      
          float g = green(portraitImage.pixels[loc]);      
          float b = blue (portraitImage.pixels[loc]); 

          float pixelBright = max(r, g, b);
          if (pixelBright > 20) {
            brightPixels.add(loc);
            String word = words[floor(random(words.length))];
            randomWords.add(word);
            int randomNum = ceil(random(10, 30));
            randomWordSize.add(randomNum);
            x += word.length() * randomNum/2;
          }
        }
      }
      //println(brightPixels.size());
      Collections.shuffle(brightPixels);
      for (int i = 0; i < brightPixels.size(); i++) {
        int loc = brightPixels.get(i);
        int oriX = loc % portraitImage.width;
        int oriY = ceil(loc / portraitImage.width);
        int x = oriX + (width / 2) - (portraitImage.width / 2);
        int y = oriY + (height / 2) - (portraitImage.height / 2);
        float r = red  (portraitImage.pixels[loc]);      
        float g = green(portraitImage.pixels[loc]);      
        float b = blue (portraitImage.pixels[loc]);
        color c = color(r, g, b);
        CharObj charObj = new CharObj(randomWords.get(i), x, y, randomWordSize.get(i), c);
        charObjs.add(charObj);
      }
      frameRate(1);
    }

    drawFlag = true;
  }

  if (drawFlag == true) {
    if (frameNum % 7 == 0 && setFrameNum < maxFrameNum) {
      setFrameNum += 5;
      frameRate(setFrameNum);
    }
    frameNum++;
    randomNum = floor(random(charObjs.size()));
    CharObj charObj = charObjs.get(randomNum);
    while (charObj.charIdx != charObj.word.length()) {
      charObj.displayChar();
    }
    if (frameNum == 8500) {
      delay(5000);
      startFlag = false;
      faceDetectFlag = false;
      captureFlag = false;
      saveFlag = false;
      drawFlag = false;
      particle.particleSetup();
    }
  }
}
