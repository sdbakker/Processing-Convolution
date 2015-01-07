/**
 * Blur. 
 * 
 * A low-pass filter blurs an image. This program analyzes every
 * pixel in an image and blends it with the neighboring pixels
 * to blur the image. 
 */

// The next line is needed if running in JavaScript Mode with Processing.js
/* @pjs preload="moon.jpg"; */ 


class ConvolutionFilter {
  public final static int IDENTITY = 0;
  public final static int EDGE1 = 1;
  public final static int EDGE2 = 2;
  public final static int EDGE3 = 3;
  public final static int SHARPEN = 4;
  public final static int BOXBLUR = 5;
  public final static int GAUSSIANBLUR = 6;
  public final static int UNSHARP = 7;

  private float[][] kernel;
  private float normalization_factor;
  
  /** 3x3 identity constructor */
  private void create_identity_matrix() {
    kernel = new float[][] {{ 0, 0, 0}, {0, 1, 0}, {0, 0, 0}};
    normalization_factor = 1;
  }
  
  public ConvolutionFilter() {
    this.create_identity_matrix();
  }
  
  public ConvolutionFilter(int type) {
    switch (type) {
      case IDENTITY:
        this.create_identity_matrix();
        break;
      case EDGE1:
        kernel = new float[][] {{ 1, 0, -1}, 
                                { 0, 0,  0}, 
                                {-1, 0, 1}};
        normalization_factor = 1;
        break;
      case EDGE2:
        kernel = new float[][] {{0, 1, 0},
                                {1, 4, 1}, 
                                {0, 1, 0}};
        normalization_factor = 1;
        break;
      case EDGE3:
        kernel = new float[][] {{-1, -1, -1}, 
                                {-1,  8, -1}, 
                                {-1, -1, -1}};
        normalization_factor = 1;
        break;
      case SHARPEN:
        kernel = new float[][] {{-1, -1, -1}, 
                                {-1,  5, -1}, 
                                {-1, -1, -1}};
        normalization_factor = 1;
        break;
      case BOXBLUR:
        kernel = new float[][] {{1, 1, 1}, 
                                {1, 1, 1}, 
                                {1, 1, 1}};
        normalization_factor = 1.0 / 9.0;
        break;
      case GAUSSIANBLUR:
        kernel = new float[][] {{1, 2, 1}, 
                                {2, 4, 2}, 
                                {1, 2, 1}};
        normalization_factor = 1.0 / 16.0;
        break;
      case UNSHARP:
        kernel = new float[][] {{1,  4,    6,  4, 1}, 
                                {4, 16,   24, 16, 4}, 
                                {6, 24, -476, 24, 6}, 
                                {4, 16,   24, 16, 4}, 
                                {1,  4,    6,  4, 1}};
        normalization_factor = -1.0 / 256.0;
        break;
      default:
        this.create_identity_matrix();
    }
  }
  
  public float getCell(int r, int c) {
    return kernel[r][c];
  }
  
  public float getCell(int r, int c, boolean normalize) {
    return normalization_factor * this.getCell(r, c); 
  }
    
  public int getKernelSize() {
    return kernel.length;
  }
};


final int ITERATIONS = 10;

PImage original_img;
PImage blur_img;

ConvolutionFilter filter = new ConvolutionFilter(ConvolutionFilter.GAUSSIANBLUR);
boolean normalize = true;

int start_millis;
int num_iterations = 0;
float frame_duration = 0.0;
float total_duration = 0.0;

int box_x = 0;
int box_y = 0;
int box_w = 40;
int box_h = 45;

void setup() {
  size(1280, 720);
  
  original_img = loadImage("alarm-clock-render.jpg"); // Load the original image
  original_img.loadPixels();
  blur_img = createImage(original_img.width, original_img.height, RGB);

  start_millis = millis();
} 

void draw() {
  if (num_iterations > ITERATIONS) {
    if (millis() - start_millis >= 5000) {
      blur_img = createImage(original_img.width, original_img.height, RGB);
      background(0);
      num_iterations = 0;
    }
  } else if (millis() - start_millis >= 10) {    
    if (box_y < blur_img.height ) {
      if (box_x < blur_img.width) {
        blur_img.loadPixels();
        convolute_over_area(filter, normalize, box_x, box_y, box_w, box_h, 10 - (1 * num_iterations), original_img, blur_img);
        blur_img.updatePixels(box_x, box_y, box_w, box_h);
        image(blur_img, 0, 0);

        box_y += box_h;
        frame_duration += (millis() - start_millis - 10) / 1000.0;
                
      } else {
        println("Iteration " + num_iterations + " done in " + frame_duration + " seconds");
        total_duration += frame_duration;
        frame_duration = 0;
        num_iterations++;
        box_x = 0;
        box_y = 0;
      }
    } else {
      box_y = 0;
      box_x += box_w;
    }
  
    if (num_iterations > ITERATIONS) {    
      println("DONE in " + total_duration + " seconds");
      image(original_img, 0, 0); 
      total_duration = 0.0f;
    } else {
      start_millis = millis();
    }
  }
}

color convolution(ConvolutionFilter filter, boolean normalize, int x, int y, PImage img)
{
  final int kernelsize = filter.getKernelSize();
  final int offset = kernelsize / 2;
 
  float rtotal = 0.0f;
  float gtotal = 0.0f;
  float btotal = 0.0f;

  if (x < offset || x >= img.width - offset)
    return color(0);
  if (y < offset || y >= img.height - offset)
    return color(0);
  
  //println("x: " + x + ", y: " + y + ", offset: " + offset + ", height: " + img.height + ", width: " + img.width);

  for (int i = 0; i < kernelsize; i++){
    for (int j = 0; j < kernelsize; j++){
        // Calculate the adjacent pixel for this kernel point
        int pos = (y + i-offset) * img.width + (x + j-offset);
        
        float kernel_cell = filter.getCell(i, j, normalize);
        rtotal += red(img.pixels[pos])   * kernel_cell;
        gtotal += green(img.pixels[pos]) * kernel_cell;
        btotal += blue(img.pixels[pos])  * kernel_cell;
    }
  }
  
  constrain(rtotal, 0, 255);
  constrain(gtotal, 0, 255);
  constrain(btotal, 0, 255);
  
  return color(rtotal, gtotal, btotal);
}

void convolute_over_area(ConvolutionFilter filter, boolean normalize, int rx, int ry, int rw, int rh, int iterations, PImage src, PImage dest)
{
  for (int i = 0; i < iterations; i++) {
    for (int x = rx; x < rx + rw; x++) {
      for (int y = ry; y < ry+rh; y++ ) {
        color c;
        if (i == 0) {
          /* first run take source image */
          c = convolution(filter, normalize, x, y, src);
        } else {
          /* next iterations take dest image as source */
          c = convolution(filter, normalize, x, y, dest);
        }
        dest.pixels[y * dest.width + x] = c;    
      }
    }
  }
}

void convolute_over_area(ConvolutionFilter filter,  boolean normalize, int rx, int ry, int rw, int rh, int iterations, PImage src)
{  
  convolute_over_area(filter, normalize, rx, ry, rw, rh, iterations, src, src);
}

void convolute_over_image(ConvolutionFilter filter,  boolean normalize, int iterations, PImage src, PImage dest)
{
  convolute_over_area(filter, normalize, 0, 0, src.width, src.height, iterations, src, dest);
}

void convolute_over_image(ConvolutionFilter filter, boolean normalize, int iterations, PImage src)
{
  convolute_over_image(filter, normalize, iterations, src, src);
}


