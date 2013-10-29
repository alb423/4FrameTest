
#import <Foundation/Foundation.h>

#include "libavformat/avformat.h"
#include "libswscale/swscale.h"
#include "libavcodec/avcodec.h"
//#import "VSaaSLiveviewPlayer.h"

@interface VSaaSVideoFrame :NSObject
@property (readwrite, nonatomic, strong) NSData *luma;
@property (readwrite, nonatomic, strong) NSData *chromaB;
@property (readwrite, nonatomic, strong) NSData *chromaR;
// 20131025 albert.liao modified start
@property (readwrite, nonatomic) NSUInteger width;
@property (readwrite, nonatomic) NSUInteger height;
// 20131025 albert.liao modified end
@end


@protocol VSaaSH264SPSPPSDataDelegate;

@interface VSaaSVideoDecoder : NSObject

-(id) init;
-(void) prepareNextRtspClient:(id<VSaaSH264SPSPPSDataDelegate>)d;

#if 1 //Yvonne. 9/13/2013 debug video play issue: 跳針
/* return value:
       0: success
       1: fail
 */
-(int) decodeOneFrame:(unsigned char *) frameBuf
          andFrameSize:(unsigned int) frameSize;
#else
-(void) decodeOneFrame:(unsigned char *) frameBuf
          andFrameSize:(unsigned int) frameSize;
#endif

- (VSaaSVideoFrame *) handleVideoFrame;

-(void) setH264SPSPPSDataDelegate:(id<VSaaSH264SPSPPSDataDelegate>) delegate;

- (AVCodecContext *) get_pCodecCtx;

-(void) takeSnapshot;

+ (VSaaSVideoFrame *) CopyAVFrameToVideoFrame: (AVFrame *) pFrameIn withWidth :(int) vWidth withHeight:(int) vHeight;

@end
