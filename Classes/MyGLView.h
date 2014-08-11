
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#include "libavformat/avformat.h"
#include "libswscale/swscale.h"
#include "libavcodec/avcodec.h"

#define OPENGL_RENDER_SCREE_NUM_4   4
#define OPENGL_RENDER_SCREE_NUM_8   8
#define OPENGL_RENDER_SCREE_NUM_16  16
#define OPENGL_RENDER_SCREE_NUM OPENGL_RENDER_SCREE_NUM_4
@interface MyVideoFrame :NSObject
@property (readwrite, nonatomic, strong) NSData *luma;
@property (readwrite, nonatomic, strong) NSData *chromaB;
@property (readwrite, nonatomic, strong) NSData *chromaR;
@property (readwrite, nonatomic) NSUInteger width;
@property (readwrite, nonatomic) NSUInteger height;
@end

#if OPENGL_RENDER_SCREE_NUM == OPENGL_RENDER_SCREE_NUM_4
typedef enum eRenderLoc {
    eLOC_TOP_LEFT  = 0,
    eLOC_TOP_RIGHT        = 1,
    eLOC_BOTTOM_LEFT       = 2,
    eLOC_BOTTOM_RIGHT       = 3,
} eRenderLocType;
#else
// when screen number is 8 or 16, we skip render
typedef enum eRenderLoc {
    eLOC_TOP_LEFT  = 0,
    eLOC_TOP_RIGHT        = 1,
    eLOC_BOTTOM_LEFT       = 2,
    eLOC_BOTTOM_RIGHT       = 3,
} eRenderLocType;
#endif

@interface MyGLView : UIView

- (id) initWithFrame:(CGRect)frame splitnumber:(int) vSplitNumber frameWidth:(float) w frameHeight:(float) h;

- (void) render: (MyVideoFrame *) frame;

-(void)RenderToHardware:(NSTimer *)timer;
-(void)StartRenderLoop;
- (void)clearFrameBuffer;
- (void) setFrame: (MyVideoFrame *) frame at: (eRenderLocType) vLocation;
- (void) setAVFrame: (AVFrame *) frame at: (eRenderLocType) vLocation;

+ (MyVideoFrame *) CopyFullAVFrameToVideoFrame: (AVFrame *) pFrameIn withWidth :(int) vWidth withHeight:(int) vHeight;

@end
