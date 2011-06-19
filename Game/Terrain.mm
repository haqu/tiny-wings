/*
 *  Tiny Wings Remake
 *  http://github.com/haqu/tiny-wings
 *
 *  Created by Sergey Tikhonov http://haqu.net
 *  Released under the MIT License
 *
 */

#import "Terrain.h"

@interface Terrain()
- (void) generateStripes;
- (void) generateHillKeyPoints;
- (void) generateBorderVertices;
- (void) createBox2DBody;
- (void) resetHillVertices;
@end

@implementation Terrain

@synthesize stripes = _stripes;
@synthesize offsetX = _offsetX;

+ (id) terrainWithWorld:(b2World*)w {
    return [[[self alloc] initWithWorld:w] autorelease];
}

- (id) initWithWorld:(b2World*)w {
    
    if ((self = [super init])) {
        
        world = w;

        CGSize size = [[CCDirector sharedDirector] winSize];
        screenW = size.width;
        screenH = size.height;
        
#ifndef DRAW_BOX2D_WORLD        
        textureSize = 512;
        [self generateStripes];
#endif
        
        [self generateHillKeyPoints];
        [self generateBorderVertices];
        [self createBox2DBody];

        self.offsetX = 0;
    }
    return self;
}

- (void) dealloc {

#ifndef DRAW_BOX2D_WORLD        
    self.stripes = nil;
#endif

    [super dealloc];
}

- (void) draw {

#ifdef DRAW_BOX2D_WORLD
    
    glDisable(GL_TEXTURE_2D);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
    glDisableClientState(GL_COLOR_ARRAY);
    
    world->DrawDebugData();
    
    glEnableClientState(GL_COLOR_ARRAY);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    glEnable(GL_TEXTURE_2D);	

#else
    
    glBindTexture(GL_TEXTURE_2D, _stripes.texture.name);

    glDisableClientState(GL_COLOR_ARRAY);

    glColor4f(1, 1, 1, 1);
    glVertexPointer(2, GL_FLOAT, 0, hillVertices);
    glTexCoordPointer(2, GL_FLOAT, 0, hillTexCoords);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, (GLsizei)nHillVertices);

    glEnableClientState(GL_COLOR_ARRAY);

#endif
}

- (ccColor3B) generateDarkColor {
    const int threshold = 250;
    int r, g, b;
    while (true) {
        r = arc4random()%256;
        g = arc4random()%256;
        b = arc4random()%256;
        if (r+g+b > threshold) break;
    }
    return ccc3(r, g, b);
}

- (ccColor3B) generateLightColorFrom:(ccColor3B)c {
    const int addon = 30;
    int r, g, b;
    r = c.r + addon;
    g = c.g + addon;
    b = c.b + addon;
    if (r > 255) r = 255;
    if (g > 255) g = 255;
    if (b > 255) b = 255;
    return ccc3(r, g, b);
}

- (void) generateStripes {

	// random even number of stripes (2,4,6,etc)
    const int minStripes = 2;
    const int maxStripes = 20;
    int nStripes = arc4random()%(maxStripes-minStripes)+minStripes;
    if (nStripes%2 != 0) {
        nStripes++;
    }
    NSLog(@"nStripes = %d", nStripes);
    
    ccColor3B c1 = [self generateDarkColor];
    ccColor3B c2 = [self generateLightColorFrom:c1];

    CCRenderTexture *rt = [CCRenderTexture renderTextureWithWidth:textureSize height:textureSize];
    ccColor4F c1f = ccc4FFromccc3B(c1);
    [rt beginWithClear:c1f.r g:c1f.g b:c1f.b a:c1f.a];
    
    // layer 1: stripes

    CGPoint vertices[maxStripes*6];
    int nVertices = 0;
    float x1 = -textureSize;
    float x2;
    float y1 = textureSize;
    float y2 = 0;
    float dx = textureSize*2 / nStripes;
    float stripeWidth = dx/2;
    for (int i=0; i<nStripes; i++) {
        x2 = x1 + textureSize;
        vertices[nVertices++] = ccp(x1, y1);
        vertices[nVertices++] = ccp(x1+stripeWidth, y1);
        vertices[nVertices++] = ccp(x2, y2);
        vertices[nVertices++] = vertices[nVertices-2];
        vertices[nVertices++] = vertices[nVertices-2];
        vertices[nVertices++] = ccp(x2+stripeWidth, y2);
        x1 += dx;
    }

    glDisable(GL_TEXTURE_2D);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
    glDisableClientState(GL_COLOR_ARRAY);
    
    glColor4ub(c2.r, c2.g, c2.b, 255);
    glVertexPointer(2, GL_FLOAT, 0, vertices);
    glDrawArrays(GL_TRIANGLES, 0, (GLsizei)nVertices);

    // layer: gradient

    float gradientAlpha = 0.7f;
    
    glEnableClientState(GL_COLOR_ARRAY);

    ccColor4F colors[4];
    nVertices = 0;

    vertices[nVertices] = ccp(0, 0);
    colors[nVertices++] = (ccColor4F){0, 0, 0, 0};
    vertices[nVertices] = ccp(textureSize, 0);
    colors[nVertices++] = (ccColor4F){0, 0, 0, 0};

    vertices[nVertices] = ccp(0, textureSize);
    colors[nVertices++] = (ccColor4F){0, 0, 0, gradientAlpha};
    vertices[nVertices] = ccp(textureSize, textureSize);
    colors[nVertices++] = (ccColor4F){0, 0, 0, gradientAlpha};

    glVertexPointer(2, GL_FLOAT, 0, vertices);
    glColorPointer(4, GL_FLOAT, 0, colors);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, (GLsizei)nVertices);

    // layer: highlight

    float highlightWidth = textureSize/8;
    ccColor4F highlightColor = (ccColor4F){1, 1, 1, 0.3f};

    nVertices = 0;
    
    vertices[nVertices] = ccp(0, 0);
    colors[nVertices++] = highlightColor;
    vertices[nVertices] = ccp(textureSize, 0);
    colors[nVertices++] = highlightColor;

    vertices[nVertices] = ccp(0, highlightWidth);
    colors[nVertices++] = (ccColor4F){0, 0, 0, 0};
    vertices[nVertices] = ccp(textureSize, highlightWidth);
    colors[nVertices++] = (ccColor4F){0, 0, 0, 0};
    
    glVertexPointer(2, GL_FLOAT, 0, vertices);
    glColorPointer(4, GL_FLOAT, 0, colors);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, (GLsizei)nVertices);
    
    glDisableClientState(GL_COLOR_ARRAY);

    // layer: top border
    
    float borderWidth = 2.0f;
    ccColor4F borderColor = (ccColor4F){0, 0, 0, 0.5f};
    
    nVertices = 0;
    
    vertices[nVertices] = ccp(0, borderWidth/2);
    colors[nVertices++] = borderColor;
    vertices[nVertices] = ccp(textureSize, borderWidth/2);
    colors[nVertices++] = borderColor;

    glLineWidth(borderWidth);
    glColor4f(borderColor.r, borderColor.g, borderColor.b, borderColor.a);
    glVertexPointer(2, GL_FLOAT, 0, vertices);
    glDrawArrays(GL_LINE_STRIP, 0, (GLsizei)nVertices);
    
    // layer: noise

    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    glEnable(GL_TEXTURE_2D);	
    
    CCSprite *s = [CCSprite spriteWithFile:@"noise.png"];
    [s setBlendFunc:(ccBlendFunc){GL_DST_COLOR, GL_ZERO}];
    s.position = ccp(textureSize/2, textureSize/2);
    s.scale = (float)textureSize/512.0f;
    glColor4f(1, 1, 1, 1);
    [s visit];

    [rt end];

    self.stripes = [CCSprite spriteWithTexture:rt.sprite.texture];
    ccTexParams tp = {GL_NEAREST, GL_NEAREST, GL_REPEAT, GL_CLAMP_TO_EDGE};
    [_stripes.texture setTexParameters:&tp];
}

- (void) generateHillKeyPoints {

    nHillKeyPoints = 0;
    
    float x, y, dx, dy, ny;
    
    x = -screenW/4;
	y = screenH*3/4;
    hillKeyPoints[nHillKeyPoints++] = ccp(x, y);

    // starting point
    x = 0;
	y = screenH/2;
    hillKeyPoints[nHillKeyPoints++] = ccp(x, y);
    
    srand(1);
	int minDX = 160, rangeDX = 80;
	int minDY = 60,  rangeDY = 60;
    float sign = -1; // +1 - going up, -1 - going  down
    float paddingTop = 20;
    float paddingBottom = 20;
    while (nHillKeyPoints < kMaxHillKeyPoints-1) {
        dx = rand()%rangeDX+minDX;
        x += dx;
        dy = rand()%rangeDY+minDY;
        ny = y + dy*sign;
        if(ny > screenH-paddingTop) ny = screenH-paddingTop;
        if(ny < paddingBottom) ny = paddingTop;
        y = ny;
        sign *= -1;
        hillKeyPoints[nHillKeyPoints++] = ccp(x, y);
    }

    // cliff
    x += minDX+rangeDX;
	y = 0;
    hillKeyPoints[nHillKeyPoints++] = ccp(x, y);
    
    fromKeyPointI = 0;
    toKeyPointI = 0;
}

- (void) generateBorderVertices {

    nBorderVertices = 0;
    CGPoint p0, p1, pt0, pt1;
    p0 = hillKeyPoints[0];
    for (int i=1; i<nHillKeyPoints; i++) {
        p1 = hillKeyPoints[i];
        
        int hSegments = floorf((p1.x-p0.x)/kHillSegmentWidth);
        float dx = (p1.x - p0.x) / hSegments;
        float da = M_PI / hSegments;
        float ymid = (p0.y + p1.y) / 2;
        float ampl = (p0.y - p1.y) / 2;
        pt0 = p0;
        borderVertices[nBorderVertices++] = pt0;
        for (int j=1; j<hSegments+1; j++) {
            pt1.x = p0.x + j*dx;
            pt1.y = ymid + ampl * cosf(da*j);
            borderVertices[nBorderVertices++] = pt1;
            pt0 = pt1;
        }
        
        p0 = p1;
    }
//    NSLog(@"nBorderVertices = %d", nBorderVertices);
}

- (void) createBox2DBody {
    
    b2BodyDef bd;
    bd.position.Set(0, 0);
    
    body = world->CreateBody(&bd);
    
    b2Vec2 b2vertices[kMaxBorderVertices];
    int nVertices = 0;
    for (int i=0; i<nBorderVertices; i++) {
        b2vertices[nVertices++].Set(borderVertices[i].x/PTM_RATIO,borderVertices[i].y/PTM_RATIO);
    }
    b2vertices[nVertices++].Set(borderVertices[nBorderVertices-1].x/PTM_RATIO,0);
    b2vertices[nVertices++].Set(-screenW/4,0);
    
    b2LoopShape shape;
    shape.Create(b2vertices, nVertices);
    body->CreateFixture(&shape, 0);
}

- (void) resetHillVertices {

#ifdef DRAW_BOX2D_WORLD
    return;
#endif
    
    static int prevFromKeyPointI = -1;
    static int prevToKeyPointI = -1;
    
    // key points interval for drawing
    
    float leftSideX = _offsetX-screenW/8/self.scale;
    float rightSideX = _offsetX+screenW*7/8/self.scale;
    
    while (hillKeyPoints[fromKeyPointI+1].x < leftSideX) {
        fromKeyPointI++;
    }
    while (hillKeyPoints[toKeyPointI].x < rightSideX) {
        toKeyPointI++;
    }
    
    if (prevFromKeyPointI != fromKeyPointI || prevToKeyPointI != toKeyPointI) {
        
//        NSLog(@"building hillVertices array for the visible area");

//        NSLog(@"leftSideX = %f", leftSideX);
//        NSLog(@"rightSideX = %f", rightSideX);
        
//        NSLog(@"fromKeyPointI = %d (x = %f)",fromKeyPointI,hillKeyPoints[fromKeyPointI].x);
//        NSLog(@"toKeyPointI = %d (x = %f)",toKeyPointI,hillKeyPoints[toKeyPointI].x);
        
        // vertices for visible area
        nHillVertices = 0;
        CGPoint p0, p1, pt0, pt1;
        p0 = hillKeyPoints[fromKeyPointI];
        for (int i=fromKeyPointI+1; i<toKeyPointI+1; i++) {
            p1 = hillKeyPoints[i];
            
            // triangle strip between p0 and p1
            int hSegments = floorf((p1.x-p0.x)/kHillSegmentWidth);
            int vSegments = 1;
            float dx = (p1.x - p0.x) / hSegments;
            float da = M_PI / hSegments;
            float ymid = (p0.y + p1.y) / 2;
            float ampl = (p0.y - p1.y) / 2;
            pt0 = p0;
            for (int j=1; j<hSegments+1; j++) {
                pt1.x = p0.x + j*dx;
                pt1.y = ymid + ampl * cosf(da*j);
                for (int k=0; k<vSegments+1; k++) {
                    hillVertices[nHillVertices] = ccp(pt0.x, pt0.y-(float)textureSize/vSegments*k);
                    hillTexCoords[nHillVertices++] = ccp(pt0.x/(float)textureSize, (float)(k)/vSegments);
                    hillVertices[nHillVertices] = ccp(pt1.x, pt1.y-(float)textureSize/vSegments*k);
                    hillTexCoords[nHillVertices++] = ccp(pt1.x/(float)textureSize, (float)(k)/vSegments);
                }
                pt0 = pt1;
            }
            
            p0 = p1;
        }
        
//        NSLog(@"nHillVertices = %d", nHillVertices);
        
        prevFromKeyPointI = fromKeyPointI;
        prevToKeyPointI = toKeyPointI;
    }
}

- (void) setOffsetX:(float)newOffsetX {

    float minOffsetX = 0;
    float maxOffsetX = hillKeyPoints[nHillKeyPoints-1].x-screenW;
    if (newOffsetX < minOffsetX) {
        newOffsetX = minOffsetX;
    }
    if (newOffsetX > maxOffsetX) {
        newOffsetX = maxOffsetX;
    }
    static BOOL firstTime = YES;
    if (_offsetX != newOffsetX || firstTime) {
        firstTime = NO;
        _offsetX = newOffsetX;
        self.position = ccp(screenW/8-_offsetX*self.scale, 0);
        [self resetHillVertices];
    }
}

@end
