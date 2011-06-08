//
// Tiny Wings http://github.com/haqu/tiny-wings
//

#import "Terrain.h"

@interface Terrain()
- (void) generateHills;
- (void) updateHillVisibleVertices;
- (void) offsetChanged;
@end

@implementation Terrain

@synthesize stripes = stripes_;

- (id) init {
	if ((self = [super init])) {

		self.stripes = [CCSprite spriteWithFile:@"stripes.png"];
		ccTexParams tp = {GL_NEAREST, GL_NEAREST, GL_REPEAT, GL_CLAMP_TO_EDGE};
		[stripes_.texture setTexParameters:&tp];
		
		scrolling = NO;
		offsetX = 0;
		
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

- (void) generateHills {
	
	// random key points
	srand(1);
	nHillKeyPoints = kMaxHillKeyPoints;
//	nHillKeyPoints = 5;
	float x = 0, y = 160, dy, ny;
	float sign = -1;
	float paddingTop = 100;
	float paddingBottom = 20;
	for (int i=0; i<nHillKeyPoints; i++) {
		hillKeyPoints[i] = CGPointMake(x, y);
		x += random()%40+160;
		while(true) {
			dy = random()%80+40;
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
