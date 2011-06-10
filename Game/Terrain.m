//
// Tiny Wings http://github.com/haqu/tiny-wings
//

#import "Terrain.h"

//#define DRAW_WIREFRAME

@interface Terrain()
- (void) generateStripes;
- (void) generateHills;
- (void) updateHillVertices;
- (void) offsetChanged;
@end

@implementation Terrain

@synthesize stripes = stripes_;
@synthesize offsetX;

- (id) init {
	if ((self = [super init])) {

		scrolling = NO;
		offsetX = 0;

		[self generateStripes];
		[self generateHills];

		[self scheduleUpdate];
	}
	return self;
}

- (void) dealloc {
	self.stripes = nil;
	[super dealloc];
}

- (void) draw {
	
	glBindTexture(GL_TEXTURE_2D, stripes_.texture.name);
	
	glDisableClientState(GL_COLOR_ARRAY);
	
	glColor4f(1, 1, 1, 1);
	glVertexPointer(2, GL_FLOAT, 0, hillVertices);
	glTexCoordPointer(2, GL_FLOAT, 0, hillTexCoords);
	glDrawArrays(GL_TRIANGLE_STRIP, 0, (GLsizei)nHillVertices);

	glDisable(GL_TEXTURE_2D);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);

	glLineWidth(3);
	glColor4ub(56, 125, 0, 255);
	glVertexPointer(2, GL_FLOAT, 0, borderVertices);
	glDrawArrays(GL_LINE_STRIP, 0, (GLsizei)nBorderVertices);
	
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	glEnable(GL_TEXTURE_2D);

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

- (void) update:(ccTime)dt {
	if(scrolling) {
		const float acc = 0.05f;
		const float maxVel = 3.0f;
		static float vel = 0;
		if(vel < maxVel) {
			vel += acc;
		} else {
			vel = maxVel;
		}
		offsetX += vel;
		float maxOffsetX = hillKeyPoints[nHillKeyPoints-1].x-480;
		if(offsetX > maxOffsetX) {
			offsetX = maxOffsetX;
			scrolling = NO;
		}
		[self offsetChanged];
	}
}

#define kMaxStripes 20

- (void) generateStripes {
	
    int textureSize = 512;
    int nStripes = 6;
	ccColor3B c1 = (ccColor3B){86,155,30};
	ccColor3B c2 = (ccColor3B){123,195,56};
	float gradientAlpha = 0.5f;
	
    CCRenderTexture *rt = [CCRenderTexture renderTextureWithWidth:textureSize height:textureSize];
    [rt beginWithClear:(float)c1.r/256.0f g:(float)c1.g/256.0f b:(float)c1.b/256.0f a:1];
    
	glDisable(GL_TEXTURE_2D);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	glDisableClientState(GL_COLOR_ARRAY);
	
	// layer 1: stripes
	
    CGPoint vertices[kMaxStripes*6];
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
	
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	glEnable(GL_TEXTURE_2D);	

	// layer 3: noise
	
	CCSprite *s = [CCSprite spriteWithFile:@"noise.png"];
	[s setBlendFunc:(ccBlendFunc){GL_DST_COLOR, GL_ZERO}];
	s.position = ccp(textureSize/2, textureSize/2);
    glColor4f(1,1,1,1);
	[s visit];
    
    [rt end];
	
	self.stripes = [CCSprite spriteWithTexture:rt.sprite.texture];
	ccTexParams tp = {GL_LINEAR, GL_LINEAR, GL_REPEAT, GL_CLAMP_TO_EDGE};
	[stripes_.texture setTexParameters:&tp];
}

- (void) generateHills {
	
	// random key points
	srand(5);
	nHillKeyPoints = kMaxHillKeyPoints;
	float x = 0, y = 120, dy, ny;
	float sign = -1;
	float paddingTop = 100;
	float paddingBottom = 20;
	for (int i=0; i<nHillKeyPoints; i++) {
		hillKeyPoints[i] = CGPointMake(x, y);
		x += rand()%40+160;
		while(true) {
			dy = rand()%80+40;
			ny = y + dy*sign;
			if(ny < 320-paddingTop && ny > paddingBottom) break;
		}
		y = ny;
		sign *= -1;
	}

	fromKeyPointI = 0;
	toKeyPointI = 0;
	
	[self updateHillVertices];
}

- (void) updateHillVertices {

	static int prevFromKeyPointI = -1;
	static int prevToKeyPointI = -1;
	
	// key points interval for drawing
	while (hillKeyPoints[fromKeyPointI+1].x < offsetX) {
		fromKeyPointI++;
	}
	while (hillKeyPoints[toKeyPointI].x < offsetX+480) {
		toKeyPointI++;
	}
	
	if (prevFromKeyPointI != fromKeyPointI || prevToKeyPointI != toKeyPointI) {

//		NSLog(@"from %d: %f, %f",fromKeyPointI,hillKeyPoints[fromKeyPointI].x,hillKeyPoints[fromKeyPointI].y);
//		NSLog(@"to   %d: %f, %f",toKeyPointI,hillKeyPoints[toKeyPointI].x,hillKeyPoints[toKeyPointI].y);
		
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
					hillTexCoords[nHillVertices++] = CGPointMake(pt0.x/256.0f, 1.0f-(float)(k)/vSegments);
					hillVertices[nHillVertices] = CGPointMake(pt1.x, pt1.y / vSegments * k);
					hillTexCoords[nHillVertices++] = CGPointMake(pt1.x/256.0f, 1.0f-(float)(k)/vSegments);
				}
				pt0 = pt1;
			}
			
			p0 = p1;
		}
		
//		NSLog(@"nHillVertices = %d",nHillVertices);
//		NSLog(@"nBorderVertices = %d",nBorderVertices);
		
		prevFromKeyPointI = fromKeyPointI;
		prevToKeyPointI = toKeyPointI;
	}
}

- (void) offsetChanged {
	self.position = CGPointMake(-offsetX, 0);
	[self updateHillVertices];
}

- (void) toggleScrolling {
	scrolling = !scrolling;
}

@end
