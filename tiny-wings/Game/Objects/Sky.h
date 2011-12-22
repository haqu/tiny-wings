//
//  Tiny Wings Remake
//  http://github.com/haqu/tiny-wings
//
//  Created by Sergey Tikhonov http://haqu.net
//  Released under the MIT License
//

#import "cocos2d.h"

@interface Sky : CCNode {
	CCSprite *_sprite;
	float _offsetX;
	float _scale;
	int textureSize;
	int screenW;
	int screenH;
}
@property (nonatomic, retain) CCSprite *sprite;
@property (nonatomic) float offsetX;
@property (nonatomic) float scale;

+ (id) skyWithTextureSize:(int)ts;
- (id) initWithTextureSize:(int)ts;

@end
