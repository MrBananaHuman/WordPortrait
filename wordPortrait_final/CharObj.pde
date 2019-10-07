class CharObj {
  PImage image;
  String word;
  int wordX, wordY, wordZ, wordSize;
  int charIdx;
  int pixelLoc;
  color charColor;
  ArrayList<Integer> charZ = new ArrayList<Integer>();
  PFont font;

  CharObj(String oriWord, int oriWordX, int oriWordY, int oriWordSize, color c) {
    //image = oriImage;
    word = oriWord;
    wordX = oriWordX;
    wordY = oriWordY;
    wordSize = oriWordSize;
    wordZ = 100;
    charIdx = 0;
    for (int i = 0; i < word.length(); i++) {
      charZ.add(100);
    }
    charColor = c;
    font = createFont("NanumGothic", oriWordSize);
    textFont(font);
  }

  void displayChar() {
    for (int i = 0; i < charZ.size(); i++) {
      if (charZ.get(i) <= 0) {
        text(word.charAt(i), wordX + (wordSize/2 * i), wordY, charZ.get(i));
      }
      if (i == charIdx) {
        if (charZ.get(i) > 0) {
          int currentCharZ = charZ.get(i) - 100;
          charZ.set(i, currentCharZ);
          fill(charColor);
          textSize(wordSize);
          //textFont(font);
          text(word.charAt(i), wordX + (wordSize/2 * charIdx), wordY, charZ.get(i));
          //ellipse(wordX, wordY, wordSize/2, wordSize/2);
        } else {
          charIdx++;
        }
      }
    }
  }
}
