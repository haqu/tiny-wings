/*
 *  Tiny Wings Remake
 *  http://github.com/haqu/tiny-wings
 *
 *  Created by Sergey Tikhonov http://haqu.net
 *  Released under the MIT License
 *
 */

#import "Terrain.h"

//#define DRAW_WIREFRAME

@interface Terrain()
- (void) generateStripes;
- (void) generateHillKeyPoints;
- (void) resetHillVertices;
- (void) resetBox2DBody;
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
        body = NULL;

        CGSize size = [[CCDirector sharedDirector] winSize];
        screenW = size.width;
        screenH = size.height;
        
        textureSize = 256;
        
        [self generateStripes];
        [self generateHillKeyPoints];

        self.offsetX = 0;
    }
    return self;
}

- (void) dealloc {
    self.stripes = nil;
    [super dealloc];
}

- (void) draw {
    
    glBindTexture(GL_TEXTURE_2D, _stripes.texture.name);

    glDisableClientState(GL_COLOR_ARRAY);

    glColor4f(1, 1, 1, 1);
    glVertexPointer(2, GL_FLOAT, 0, hillVertices);
    glTexCoordPointer(2, GL_FLOAT, 0, hillTexCoords);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, (GLsizei)nHillVertices);

    glEnableClientState(GL_COLOR_ARRAY);

#ifdef DRAW_WIREFRAME
    glDisable(GL_TEXTURE_2D);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
    glDisableClientState(GL_COLOR_ARRAY);

    glColor4f(1, 1, 1, 1);
    glVertexPointer(2, GL_FLOAT, 0, hillVertices);
    glDrawArrays(GL_LINE_STRIP, 0, (GLsizei)nHillVertices);

    glEnableClientState(GL_COLOR_ARRAY);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    glEnable(GL_TEXTURE_2D);	
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
    const int maxStripes = 8;
    int nStripes = arc4random()%(maxStripes-minStripes)+minStripes;
    if (nStripes%2 != 0) {
        nStripes++;
    }
    NSLog(@"nStripes = %d", nStripes);
    
//    ccColor3B c1 = ccc3(86, 155, 30);
//    ccColor3B c2 = ccc3(123, 195, 56);
    ccColor3B c1 = [self generateDarkColor];
    ccColor3B c2 = [self generateLightColorFrom:c1];
    float gradientAlpha = 0.5f;

    CCRenderTexture *rt = [CCRenderTexture renderTextureWithWidth:textureSize height:textureSize];
    ccColor4F c1f = ccc4FFromccc3B(c1);
    [rt beginWithClear:c1f.r g:c1f.g b:c1f.b a:c1f.a];
    
    glDisable(GL_TEXTURE_2D);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
    glDisableClientState(GL_COLOR_ARRAY);

    // layer 1: stripes

    CGPoint vertices[maxStripes*6];
    int nVertices = 0;
    float x1 = -textureSize;
    float x2;
    float y1 = textureSize;
    float y2 = 0;
    float dx = textureSize*2 / nStripes;
    float stripeWidth = dx/2;
    for (int i=0; i<=nStripes; i++) {
        x2 = x1 + textureSize;
        vertices[nVertices++] = CGPointMake(x1, y1);
        vertices[nVertices++] = CGPointMake(x1+stripeWidth, y1);
        vertices[nVertices++] = CGPointMake(x2, y2);
        vertices[nVertices++] = vertices[nVertices-2];
        vertices[nVertices++] = vertices[nVertices-2];
        vertices[nVertices++] = CGPointMake(x2+stripeWidth, y2);
        x1 += dx;
    }

    glColor4ub(c2.r, c2.g, c2.b, 255);
    glVertexPointer(2, GL_FLOAT, 0, vertices);
    glDrawArrays(GL_TRIANGLES, 0, (GLsizei)nVertices);

    // layer 2: gradient

    glEnableClientState(GL_COLOR_ARRAY);

    ccColor4F colors[4];
    nVertices = 0;

    vertices[nVertices] = CGPointMake(0, 0);
    colors[nVertices++] = (ccColor4F){0, 0, 0, 0};
    vertices[nVertices] = CGPointMake(textureSize, 0);
    colors[nVertices++] = (ccColor4F){0, 0, 0, 0};

    vertices[nVertices] = CGPointMake(0, textureSize);
    colors[nVertices++] = (ccColor4F){0, 0, 0, gradientAlpha};
    vertices[nVertices] = CGPointMake(textureSize, textureSize);
    colors[nVertices++] = (ccColor4F){0, 0, 0, gradientAlpha};

    glVertexPointer(2, GL_FLOAT, 0, vertices);
    glColorPointer(4, GL_FLOAT, 0, colors);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, (GLsizei)nVertices);

    // layer 3: highlight

    float borderWidth = textureSize/8;
    ccColor4F borderColor = (ccColor4F){1, 1, 1, 0.3f};

    nVertices = 0;
    
    vertices[nVertices] = CGPointMake(0, 0);
    colors[nVertices++] = borderColor;
    vertices[nVertices] = CGPointMake(textureSize, 0);
    colors[nVertices++] = borderColor;

    vertices[nVertices] = CGPointMake(0, borderWidth);
    colors[nVertices++] = (ccColor4F){0, 0, 0, 0};
    vertices[nVertices] = CGPointMake(textureSize, borderWidth);
    colors[nVertices++] = (ccColor4F){0, 0, 0, 0};
    
    glVertexPointer(2, GL_FLOAT, 0, vertices);
    glColorPointer(4, GL_FLOAT, 0, colors);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, (GLsizei)nVertices);
    
    glDisableClientState(GL_COLOR_ARRAY);
    
    // layer 4: noise

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
    ccTexParams tp = {GL_LINEAR, GL_LINEAR, GL_REPEAT, GL_CLAMP_TO_EDGE};
    [_stripes.texture setTexParameters:&tp];
}

- (void) generateHillKeyPoints {

    nHillKeyPoints = 0;
    
    float x, y, dx, dy, ny;
    
    x = -screenW/4;
	y = screenH*3/4;
    hillKeyPoints[nHillKeyPoints++] = CGPointMake(x, y);

    // right under the starting point
    x = 0;
	y = screenH/2;
    hillKeyPoints[nHillKeyPoints++] = CGPointMake(x, y);
    
    srand(1);
	int minDX = 160, rangeDX = 80;
	int minDY = 60,  rangeDY = 60;
    float sign = -1; // +1 - going up, -1 - going  down
    float paddingTop = 20;
    float paddingBottom = 20;
    while (nHillKeyPoints < kMaxHillKeyPoints) {
        dx = rand()%rangeDX+minDX;
        x += dx;
        while(true) {
            dy = rand()%rangeDY+minDY;
            ny = y + dy*sign;
            if(ny < screenH-paddingTop && ny > paddingBottom) break;
        }
        y = ny;
        sign *= -1;
        hillKeyPoints[nHillKeyPoints++] = CGPointMake(x, y);
    }
    
    fromKeyPointI = 0;
    toKeyPointI = 0;

    [self resetHillVertices];
}

- (void) resetHillVertices {

    static int prevFromKeyPointI = -1;
    static int prevToKeyPointI = -1;

    // key points interval for drawing
    while (hillKeyPoints[fromKeyPointI+1].x < _offsetX-screenW/8/self.scale) {
        fromKeyPointI++;
    }
    while (hillKeyPoints[toKeyPointI].x < _offsetX+screenW*7/8/self.scale) {
        toKeyPointI++;
    }
    
    if (prevFromKeyPointI != fromKeyPointI || prevToKeyPointI != toKeyPointI) {
        
//        NSLog(@"building hillVertices array for the visible area");
//        NSLog(@"fromKeyPointI = %d (x = %f)",fromKeyPointI,hillKeyPoints[fromKeyPointI].x);
//        NSLog(@"toKeyPointI = %d (x = %f)",toKeyPointI,hillKeyPoints[toKeyPointI].x);
        
        // vertices for visible area
        nHillVertices = 0;
        nBorderVertices = 0;
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
            borderVertices[nBorderVertices++] = pt0;
            for (int j=1; j<hSegments+1; j++) {
                pt1.x = p0.x + j*dx;
                pt1.y = ymid + ampl * cosf(da*j);
                borderVertices[nBorderVertices++] = pt1;
                for (int k=0; k<vSegments+1; k++) {
                    hillVertices[nHillVertices] = CGPointMake(pt0.x, pt0.y / vSegments * k);
                    hillTexCoords[nHillVertices++] = CGPointMake(pt0.x/(float)textureSize, 1.0f-(float)(k)/vSegments);
                    hillVertices[nHillVertices] = CGPointMake(pt1.x, pt1.y / vSegments * k);
                    hillTexCoords[nHillVertices++] = CGPointMake(pt1.x/(float)textureSize, 1.0f-(float)(k)/vSegments);
                }
                pt0 = pt1;
            }
            
            p0 = p1;
        }
        
//        NSLog(@"nHillVertices = %d", nHillVertices);
//        NSLog(@"nBorderVertices = %d", nBorderVertices);
        
        prevFromKeyPointI = fromKeyPointI;
        prevToKeyPointI = toKeyPointI;
        
        [self resetBox2DBody];
    }
}

- (void) resetBox2DBody {

    if(body) {
        world->DestroyBody(body);
    }

    b2BodyDef bd;
    bd.position.Set(0, 0);

    body = world->CreateBody(&bd);

    b2PolygonShape shape;

    b2Vec2 p1, p2;
    for (int i=0; i<nBorderVertices-1; i++) {
        p1 = b2Vec2(borderVertices[i].x/PTM_RATIO,borderVertices[i].y/PTM_RATIO);
        p2 = b2Vec2(borderVertices[i+1].x/PTM_RATIO,borderVertices[i+1].y/PTM_RATIO);
        shape.SetAsEdge(p1, p2);
        body->CreateFixture(&shape, 0);
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
        self.position = CGPointMake(screenW/8-_offsetX*self.scale, 0);
        [self resetHillVertices];
    }
}

@end
