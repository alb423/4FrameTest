
#import <Foundation/Foundation.h>
#include "libavformat/avformat.h"
#include "libswscale/swscale.h"
#include "libavcodec/avcodec.h"

@interface MyVideoFrame :NSObject
@property (readwrite, nonatomic, strong) NSData *luma;
@property (readwrite, nonatomic, strong) NSData *chromaB;
@property (readwrite, nonatomic, strong) NSData *chromaR;
@property (readwrite, nonatomic) NSUInteger width;
@property (readwrite, nonatomic) NSUInteger height;
@end


typedef enum eRenderLoc {
    eLOC_TOP_LEFT  = 0,
    eLOC_TOP_RIGHT        = 1,
    eLOC_BOTTOM_LEFT       = 2,
    eLOC_BOTTOM_RIGHT       = 3,
} eRenderLocType;


@interface MyGLView : UIView

- (id) initWithFrame:(CGRect)frame frameWidth:(float) w frameHeight:(float) h;

- (void) render: (MyVideoFrame *) frame;

-(void)RenderToHardware:(NSTimer *)timer;
-(void)StartRenderLoop;
- (void)clearFrameBuffer;
-(void) setFrame: (MyVideoFrame *) frame at: (eRenderLocType) vLocation;

+ (MyVideoFrame *) CopyAVFrameToVideoFrame: (AVFrame *) pFrameIn withWidth :(int) vWidth withHeight:(int) vHeight;


@end
