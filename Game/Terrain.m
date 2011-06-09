//
// Tiny Wings http://github.com/haqu/tiny-wings
//

#import "Terrain.h"

@interface Terrain()
- (void) generateStripes;
- (void) generateHills;
- (void) updateHillVisibleVertices;
- (void) offsetChanged;
@end

@implementation Terrain

@synthesize stripes = stripes_;

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
	
	glVertexPointer(2, GL_FLOAT, 0, hillVisibleVertices);
	glTexCoordPointer(2, GL_FLOAT, 0, hillVisibleTexCoords);
	glDrawArrays(GL_TRIANGLE_STRIP, 0, (GLsizei)nHillVisibleVertices);
	
	glEnableClientState(GL_COLOR_ARRAY);
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
	ccTexParams tp = {GL_NEAREST, GL_NEAREST, GL_REPEAT, GL_CLAMP_TO_EDGE};
	[stripes_.texture setTexParameters:&tp];
}

- (void) generateHills {
	
	// random key points
	srand(5);
	nHillKeyPoints = kMaxHillKeyPoints;
//	nHillKeyPoints = 5;
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
	
	nHillVertices = 0;
	CGPoint p0, p1, pt0, pt1;
	p0 = hillKeyPoints[0];
	for (int i=1; i<nHillKeyPoints; i++) {
		p1 = hillKeyPoints[i];
		
		// triangle strip between p0 and p1
		int hSegments = 30;
		int vSegments = 5;
		float dx = (p1.x - p0.x) / hSegments;
		float da = M_PI / hSegments;
		float ymid = (p0.y + p1.y) / 2;
		float ampl = (p0.y - p1.y) / 2;
		pt0 = p0;
		for (int j=1; j<hSegments+1; j++) {
			pt1.x = p0.x + j*dx;
			pt1.y = ymid + ampl * cosf(da*j);
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
	
	[self updateHillVisibleVertices];
}

- (void) updateHillVisibleVertices {
	
	nHillVisibleVertices = 0;
	
	CGPoint p;
	float padding = 20;
	for (int i=0; i<nHillVertices; i++) {
		p = hillVertices[i];
		if(p.x > offsetX-padding && p.x < offsetX+480+padding) {
			hillVisibleVertices[nHillVisibleVertices] = p;
			hillVisibleTexCoords[nHillVisibleVertices++] = hillTexCoords[i];
		}
	}
}

- (void) offsetChanged {
	self.position = CGPointMake(-offsetX, 0);
	[self updateHillVisibleVertices];
}

- (void) toggleScrolling {
	scrolling = !scrolling;
}

@end
