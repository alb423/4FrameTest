

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "MyGLView.h"

//////////////////////////////////////////////////////////

#pragma mark - shaders

#define ENABLE_YUV_SACLE_BEFORE_RENDER 0
#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)
#define SHADER_STRING(text) @ STRINGIZE2(text)

#define SCALE_BY_OPENGLES 1
#define SCALE_BY_UISCROLLVIEW 2
#define GLVIEW_SCALE_METHOD SCALE_BY_OPENGLES

NSString *const VSaaS_vertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 attribute vec2 texcoord;
 attribute vec4 position_shift;
 uniform mat4 modelViewProjectionMatrix;
 varying vec2 v_texcoord;
 
 void main()
 {
     gl_Position = modelViewProjectionMatrix * position;
     
     // Change the gl_Position can change the texture location
     // gl_Position.x += 0.1;
//     gl_Position += position_shift;
//     gl_Position.x += position_shift.x;
//     gl_Position.y += position_shift.y;
     
     v_texcoord = texcoord.xy;
 }
 );

NSString *const VSaaS_yuvFragmentShaderString = SHADER_STRING
(
 varying highp vec2 v_texcoord;
 uniform sampler2D s_texture_y;
 uniform sampler2D s_texture_u;
 uniform sampler2D s_texture_v;
 
 void main()
 {
     highp float y = texture2D(s_texture_y, v_texcoord).r;
     highp float u = texture2D(s_texture_u, v_texcoord).r - 0.5;
     highp float v = texture2D(s_texture_v, v_texcoord).r - 0.5;
     
     highp float r = y +             1.402 * v;
     highp float g = y - 0.344 * u - 0.714 * v;
     highp float b = y + 1.772 * u;
     
     gl_FragColor = vec4(r,g,b,1.0);
 }
 );

static BOOL validateProgram(GLuint prog)
{
	GLint status;
	
    glValidateProgram(prog);
    
#ifdef DEBUG
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        //NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == GL_FALSE) {
		//NSLog(@"Failed to validate program %d", prog);
        return NO;
    }
	
	return YES;
}

static GLuint compileShader(GLenum type, NSString *shaderString)
{
	GLint status;
	const GLchar *sources = (GLchar *)shaderString.UTF8String;
	
    GLuint shader = glCreateShader(type);
    if (shader == 0 || shader == GL_INVALID_ENUM) {
        //NSLog(@"Failed to create shader %d", type);
        return 0;
    }
    
    glShaderSource(shader, 1, &sources, NULL);
    glCompileShader(shader);
	
#ifdef DEBUG
	GLint logLength;
    glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(shader, logLength, &logLength, log);
        //NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(shader, GL_COMPILE_STATUS, &status);
    if (status == GL_FALSE) {
        glDeleteShader(shader);
		//NSLog(@"Failed to compile shader:\n");
        return 0;
    }
    
	return shader;
}


static void mat4f_LoadOrtho(float left, float right, float bottom, float top, float near, float far, float* mout)
{
	float r_l = right - left;
	float t_b = top - bottom;
	float f_n = far - near;
	float tx = - (right + left) / (right - left);
	float ty = - (top + bottom) / (top - bottom);
	float tz = - (far + near) / (far - near);
    
	mout[0] = 2.0f / r_l;
	mout[1] = 0.0f;
	mout[2] = 0.0f;
	mout[3] = 0.0f;
	
	mout[4] = 0.0f;
	mout[5] = 2.0f / t_b;
	mout[6] = 0.0f;
	mout[7] = 0.0f;
	
	mout[8] = 0.0f;
	mout[9] = 0.0f;
	mout[10] = -2.0f / f_n;
	mout[11] = 0.0f;
	
	mout[12] = tx;
	mout[13] = ty;
	mout[14] = tz;
	mout[15] = 1.0f;
}

//////////////////////////////////////////////////////////

#pragma mark - frame renderers

@protocol MyGLRenderer
- (BOOL) isValid;
- (NSString *) fragmentShader;
- (void) resolveUniforms: (GLuint) program;
- (void) setFrame: (MyVideoFrame *) frame;
- (void) setFrame: (MyVideoFrame *) pFrame width:(int)w height:(int)h at:(int)vLocation;
- (BOOL) prepareRender;
@end

@interface MyGLRenderer_YUV : NSObject<MyGLRenderer> {
    GLint _uniformSamplers[3];
    GLuint _textures[3];
}
@end

@implementation MyGLRenderer_YUV

- (BOOL) isValid
{
    return (_textures[0] != 0);
}

- (NSString *) fragmentShader
{
    return VSaaS_yuvFragmentShaderString;
}

- (void) resolveUniforms: (GLuint) program
{
    _uniformSamplers[0] = glGetUniformLocation(program, "s_texture_y");
    _uniformSamplers[1] = glGetUniformLocation(program, "s_texture_u");
    _uniformSamplers[2] = glGetUniformLocation(program, "s_texture_v");
}


- (void) setFrame: (MyVideoFrame *) yuvFrame width:(int)w height:(int)h at:(int)vLocation
{
    //NSLog(@"---yuvFrame %d %d %d", yuvFrame.luma.length, yuvFrame.chromaB.length, yuvFrame.chromaR.length);
    
    const NSUInteger frameWidth = w;
    const NSUInteger frameHeight = h;
    
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    
    if (0 == _textures[0])
        glGenTextures(3, _textures);

    const UInt8 *pixels[3] = { yuvFrame.luma.bytes, yuvFrame.chromaB.bytes, yuvFrame.chromaR.bytes };
    const NSUInteger widths[3]  = { frameWidth, frameWidth / 2, frameWidth / 2 };
    const NSUInteger heights[3] = { frameHeight, frameHeight / 2, frameHeight / 2 };
    
    for (int i = 0; i < 3; ++i)
    {
        
        glBindTexture(GL_TEXTURE_2D, _textures[i]);
        
        glTexImage2D(GL_TEXTURE_2D,
                     0,
                     GL_LUMINANCE,
                     widths[i],
                     heights[i],
                     0,
                     GL_LUMINANCE,
                     GL_UNSIGNED_BYTE,
                     pixels[i]);
        
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    }
}



- (void) setFrame: (MyVideoFrame *) yuvFrame
{
    //NSLog(@"---yuvFrame %d %d %d", yuvFrame.luma.length, yuvFrame.chromaB.length, yuvFrame.chromaR.length);

    const NSUInteger frameWidth = yuvFrame.width;
    const NSUInteger frameHeight = yuvFrame.height;
    
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    
    if (0 == _textures[0])
        glGenTextures(3, _textures);
    
    const UInt8 *pixels[3] = { yuvFrame.luma.bytes, yuvFrame.chromaB.bytes, yuvFrame.chromaR.bytes };
    const NSUInteger widths[3]  = { frameWidth, frameWidth / 2, frameWidth / 2 };
    const NSUInteger heights[3] = { frameHeight, frameHeight / 2, frameHeight / 2 };
    
    for (int i = 0; i < 3; ++i) {
        
        glBindTexture(GL_TEXTURE_2D, _textures[i]);
        
        glTexImage2D(GL_TEXTURE_2D,
                     0,
                     GL_LUMINANCE,
                     widths[i],
                     heights[i],
                     0,
                     GL_LUMINANCE,
                     GL_UNSIGNED_BYTE,
                     pixels[i]);
        
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    }
}

- (BOOL) prepareRender
{
    if (_textures[0] == 0)
        return NO;
    
    for (int i = 0; i < 3; ++i) {
        glActiveTexture(GL_TEXTURE0 + i);
        glBindTexture(GL_TEXTURE_2D, _textures[i]);
        glUniform1i(_uniformSamplers[i], i);
    }
    
    return YES;
}


- (void) dealloc
{
    //NSLog(@">>>>>>>>>>>>>   %@ dealloc", self);
    
    if (_textures[0])
        glDeleteTextures(3, _textures);
}

@end

//////////////////////////////////////////////////////////

#pragma mark - MyVideoFrame
@implementation MyVideoFrame
@synthesize width, height;
@end

//////////////////////////////////////////////////////////

#pragma mark - gl view

enum {
	ATTRIBUTE_VERTEX,
   	ATTRIBUTE_TEXCOORD,
    ATTRIBUTE_POS_SHIFT,
};

@implementation MyGLView {
    EAGLContext     *_context;
    GLuint          _framebuffer;
    GLuint          _renderbuffer;
    GLint           _backingWidth;
    GLint           _backingHeight;
    GLuint          _program;
    GLint           _uniformMatrix;
    GLfloat         _vertices[32];

    id<MyGLRenderer> _renderer;
    
    UIImageView *disconnectImageView;
    
    
    int iWidth;
    int iHeight;
    int ScreenNumber;
    
    GLuint pTmpTextures[3];
    UInt8  pTmpPixels[3][1280*720]; // For max resolution 720p
    GLint  pTmpUniformSamplers[3];
    
#if ENABLE_YUV_SACLE_BEFORE_RENDER == 1
    // Scale YUV to smaller size before render
    AVPicture picture;
    struct SwsContext *img_convert_ctx;
    GLint           outputWidth;
    GLint           outputHeight;
#endif
    
    // For Scale and Roate for single screen
    GLfloat ScaleFactor;
    GLfloat FinalFixedScaleFator;
    GLfloat SwipeFactor_X;
    GLfloat SwipeFactor_Y;
    
    GLfloat LeftBoundaryAfterScale;
    GLfloat RightBoundaryAfterScale;
    GLfloat UpBoundaryAfterScale;
    GLfloat DownBoundaryAfterScale;
    
    GLfloat SwipeOffset;
}

+ (Class) layerClass
{
	return [CAEAGLLayer class];
}



// frameWidth and frameHeight is used to caculate the scale factor
- (id) initWithFrame:(CGRect)frame splitnumber:(int) vSplitNumber frameWidth:(float) w frameHeight:(float) h
{
    self = [super initWithFrame:frame];
    if (self) {

        ScreenNumber = vSplitNumber;
        iWidth = w;
        iHeight = h;
        
        
        _renderer = [[MyGLRenderer_YUV alloc] init];
        NSLog(@"MyGLRenderer_YUV alloc ok");
        
        CAEAGLLayer *eaglLayer = (CAEAGLLayer*) self.layer;
        eaglLayer.opaque = YES;
        eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithBool:FALSE], kEAGLDrawablePropertyRetainedBacking,
                                        kEAGLColorFormatRGBA8,           kEAGLDrawablePropertyColorFormat,
                                        nil];
        
        _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        
        if (!_context ||
            ![EAGLContext setCurrentContext:_context])
        {
            //NSLog(@"failed to setup EAGLContext");
            self = nil;
            return nil;
        }
        
        // If we set scale, the fps will down
        //[self.layer setContentsScale:2.0];
        
        glGenFramebuffers(1, &_framebuffer);
        glGenRenderbuffers(1, &_renderbuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);
        [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.layer];
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_backingWidth);
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_backingHeight);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderbuffer);
        
        
        // Disable unused fucntion to speed up
        glDisable(GL_DITHER);
        glDisable(GL_BLEND);
        glDisable(GL_STENCIL_TEST);
        //glDisable(GL_TEXTURE_2D);
        glDisable(GL_DEPTH_TEST);
        
        NSLog(@"init framebuffer %d:%d", _backingWidth, _backingHeight);
        
        GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
        if (status != GL_FRAMEBUFFER_COMPLETE) {
            
            //NSLog(@"failed to make complete framebuffer object %x", status);
            self = nil;
            return nil;
        }
        
        GLenum glError = glGetError();
        if (GL_NO_ERROR != glError) {
            
            //NSLog(@"failed to setup GL %x", glError);
            self = nil;
            return nil;
        }
        
        if (![self loadShaders]) {
            
            self = nil;
            return nil;
        }
        
        if(ScreenNumber==1)
        {
            _vertices[0] = -1.0f;  // x0
            _vertices[1] = -1.0f;  // y0
            _vertices[2] =  1.0f;  // ..
            _vertices[3] = -1.0f;
            _vertices[4] = -1.0f;
            _vertices[5] =  1.0f;
            _vertices[6] =  1.0f;  // x3
            _vertices[7] =  1.0f;  // y3
        }
        else if(ScreenNumber==2)
        {
            _vertices[0] = -1.0f;  // x0
            _vertices[1] =  0.0f;  // y0
            _vertices[2] =  1.0f;  // ..
            _vertices[3] =  0.0f;
            _vertices[4] = -1.0f;
            _vertices[5] =  1.0f;
            _vertices[6] =  1.0f;  // x3
            _vertices[7] =  1.0f;  // y3
            
            _vertices[8] =  -1.0f;  // x0
            _vertices[9] =  -1.0f;  // y0
            _vertices[10] =  1.0f;  // ..
            _vertices[11] = -1.0f;
            _vertices[12] = -1.0f;
            _vertices[13] =  0.0f;
            _vertices[14] =  1.0f;  // x3
            _vertices[15] =  0.0f;  // y3
        }
        else
        {
            _vertices[0] = -1.0f;  // x0
            _vertices[1] =  0.0f;  // y0
            _vertices[2] =  0.0f;  // ..
            _vertices[3] =  0.0f;
            _vertices[4] = -1.0f;
            _vertices[5] =  1.0f;
            _vertices[6] =  0.0f;  // x3
            _vertices[7] =  1.0f;  // y3
            
            _vertices[8] =  0.0f;  // x0
            _vertices[9] =  0.0f;  // y0
            _vertices[10] =  1.0f;  // ..
            _vertices[11] =  0.0f;
            _vertices[12] =  0.0f;
            _vertices[13] =  1.0f;
            _vertices[14] =  1.0f;  // x3
            _vertices[15] =  1.0f;  // y3
            
            _vertices[16] = -1.0f;  // x0
            _vertices[17] = -1.0f;  // y0
            _vertices[18] =  0.0f;  // ..
            _vertices[19] = -1.0f;
            _vertices[20] = -1.0f;
            _vertices[21] =  0.0f;
            _vertices[22] =  0.0f;  // x3
            _vertices[23] =  0.0f;  // y3
            
            _vertices[24] =  0.0f;  // x0
            _vertices[25] = -1.0f;  // y0
            _vertices[26] =  1.0f;  // ..
            _vertices[27] = -1.0f;
            _vertices[28] =  0.0f;
            _vertices[29] =  0.0f;
            _vertices[30] =  1.0f;  // x3
            _vertices[31] =  0.0f;  // y3
        }
        
        //[self StartRenderLoop];
        
        
#if ENABLE_YUV_SACLE_BEFORE_RENDER == 1
        // For YUV Scale
        // Release old picture and scaler
        avpicture_free(&picture);
        sws_freeContext(img_convert_ctx);
        
        // Allocate RGB picture
        outputWidth = iWidth/4;
        outputHeight = iHeight/4;
        avpicture_alloc(&picture, PIX_FMT_YUV420P, outputWidth, outputHeight);
        
        // Setup scaler
        img_convert_ctx = sws_getContext(iWidth,
                                         iHeight,
                                         PIX_FMT_YUV420P,
                                         outputWidth,
                                         outputHeight,
                                         PIX_FMT_YUV420P,
                                         SWS_FAST_BILINEAR, NULL, NULL, NULL);
#endif
    }
    
    
    // support gesture recognization
    ScaleFactor = 1.0;
    FinalFixedScaleFator = 1.0;
    SwipeFactor_X = 0.0;
    SwipeFactor_Y = 0.0;
    SwipeOffset = 2.0;
    
#if GLVIEW_SCALE_METHOD == SCALE_BY_OPENGLES
    if(ScreenNumber==1)
    {
        [self setUserInteractionEnabled:YES];
        
        UITapGestureRecognizer *tapper = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapHandler:)];
        tapper.numberOfTapsRequired = 2;
        [self addGestureRecognizer:tapper];
        
        UIPinchGestureRecognizer *pincher = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchHandler:)];
        [self addGestureRecognizer:pincher];
        
        UIPanGestureRecognizer *PanSwiper = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panHandler:)];
        [PanSwiper setMinimumNumberOfTouches:1];
        [self addGestureRecognizer:PanSwiper];
        
#if 0
        UISwipeGestureRecognizer *LeftSwiper = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeHandler:)];
        LeftSwiper.direction = UISwipeGestureRecognizerDirectionLeft;
        [self addGestureRecognizer:LeftSwiper];
        
        UISwipeGestureRecognizer *RightSwiper = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeHandler:)];
        RightSwiper.direction = UISwipeGestureRecognizerDirectionRight;
        [self addGestureRecognizer:RightSwiper];
        
        UISwipeGestureRecognizer *UpSwiper = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeHandler:)];
        UpSwiper.direction = UISwipeGestureRecognizerDirectionUp;
        [self addGestureRecognizer:UpSwiper];
        
        UISwipeGestureRecognizer *DownSwiper = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeHandler:)];
        DownSwiper.direction = UISwipeGestureRecognizerDirectionDown;
        [self addGestureRecognizer:DownSwiper];
        
        UILongPressGestureRecognizer *longpresser = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressHandler:)];
        [self addGestureRecognizer:longpresser];
        
        UIRotationGestureRecognizer *rotater = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(rotateHandler:)];
        [self addGestureRecognizer:rotater];
#endif
    }
#endif
    
    return self;
}

- (void)dealloc
{
    //NSLog(@">>>>>>>>>>>> %@ dealloc", self);
    
    _renderer = nil;
    
    if (_framebuffer) {
        glDeleteFramebuffers(1, &_framebuffer);
        _framebuffer = 0;
    }
    
    if (_renderbuffer) {
        glDeleteRenderbuffers(1, &_renderbuffer);
        _renderbuffer = 0;
    }
    
    if (_program) {
        glDeleteProgram(_program);
        _program = 0;
    }
	
	if ([EAGLContext currentContext] == _context) {
		[EAGLContext setCurrentContext:nil];
	}
    
#if ENABLE_YUV_SACLE_BEFORE_RENDER == 1
	// Free scaler
	sws_freeContext(img_convert_ctx);
    
	// Free YUV picture
	avpicture_free(&picture);
#endif
	_context = nil;
}


- (void)layoutSubviews
{
    glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.layer];
	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_backingHeight);
	
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
	if (status != GL_FRAMEBUFFER_COMPLETE) {
		
        NSLog(@"failed to make complete framebuffer object %x", status);
        
	} else {
        
        NSLog(@"OK setup GL framebuffer %d:%d", _backingWidth, _backingHeight);
    }
    
    [self updateVertices];
    [self render: nil];
}

- (void)setContentMode:(UIViewContentMode)contentMode
{
    [super setContentMode:contentMode];
    [self updateVertices];
    if (_renderer.isValid)
        [self render:nil];
}

- (BOOL)loadShaders
{
    BOOL result = NO;
    GLuint vertShader = 0, fragShader = 0;
    
    
	_program = glCreateProgram();
	
    vertShader = compileShader(GL_VERTEX_SHADER, VSaaS_vertexShaderString);
	if (!vertShader)
        goto exit;
    
	fragShader = compileShader(GL_FRAGMENT_SHADER, _renderer.fragmentShader);
    if (!fragShader)
        goto exit;
    
	glAttachShader(_program, vertShader);
	glAttachShader(_program, fragShader);
	glBindAttribLocation(_program, ATTRIBUTE_VERTEX, "position");
    glBindAttribLocation(_program, ATTRIBUTE_TEXCOORD, "texcoord");
    glBindAttribLocation(_program, ATTRIBUTE_POS_SHIFT, "position_shift");
    
	
	glLinkProgram(_program);
    
    GLint status;
    glGetProgramiv(_program, GL_LINK_STATUS, &status);
    if (status == GL_FALSE) {
		//NSLog(@"Failed to link program %d", _program);
        goto exit;
    }
    
    result = validateProgram(_program);
    
    // 20131106 test
    glUseProgram(_program);
    pTmpUniformSamplers[0] = glGetUniformLocation(_program, "s_texture_y");
    pTmpUniformSamplers[1] = glGetUniformLocation(_program, "s_texture_u");
    pTmpUniformSamplers[2] = glGetUniformLocation(_program, "s_texture_v");
    
    _uniformMatrix = glGetUniformLocation(_program, "modelViewProjectionMatrix");
    //GLKMatrix4Multiply(_uniformMatrix, GLKMatrix4MakeScale(0.5, 0.5, 1));
    //[_renderer resolveUniforms:_program];
	
exit:
    
    if (vertShader)
        glDeleteShader(vertShader);
    if (fragShader)
        glDeleteShader(fragShader);
    
    if (result) {
        
        //NSLog(@"OK setup GL programm");
        
    } else {
        
        glDeleteProgram(_program);
        _program = 0;
    }
    
    return result;
}

- (void)updateVertices
{
    const BOOL fit      = (self.contentMode == UIViewContentModeScaleAspectFit);
    //BOOL fit      = (self.contentMode == UIViewContentModeScaleAspectFit);
    const float width   = iWidth;
    const float height  = iHeight;

    
    const float dH      = (float)_backingHeight / height;
    const float dW      = (float)_backingWidth	  / width;
    
    // Test
    //fit = 1;
    const float dd      = fit ? MIN(dH, dW) : MAX(dH, dW);
    
    const float h       = (height * dd / (float)_backingHeight);
    float w       = (width  * dd / (float)_backingWidth );
    
    
    NSLog(@"updateVertices fit=%d, (%f,%f) (%d,%d)", fit, width, height, _backingWidth, _backingHeight);
    NSLog(@"updateVertices w,h=(%f,%f) dw,dh=(%f,%f) dd=%f",w, h, dW, dH, dd);
    

//    // rotate to landscap
//    int vTest = 1; // SwipeFactor_X
//    _vertices[0] = - w*vTest - SwipeFactor_X; // Shift to Left
//    _vertices[1] = - h*vTest;   // Shift to Up
//    _vertices[2] =   w*vTest ;   // Shift to Right
//    _vertices[3] = - h*vTest ;   // Shift to Down
//    _vertices[4] = - w*vTest - SwipeFactor_X; // Shift to Left
//    _vertices[5] =   h*vTest;   // Shift to Up
//    _vertices[6] =   w*vTest;   // Shift to Right
//    _vertices[7] =   h*vTest;   // Shift to Down
    
#if 0
    _vertices[0] =   1;
    _vertices[1] =  -1;
    _vertices[2] =   1;
    _vertices[3] =   1;
    _vertices[4] =  -1;
    _vertices[5] =  -1;
    _vertices[6] =  -1;
    _vertices[7] =   1;
#endif
    
#if 0
    if(ScreenNumber==1)
    {
        _vertices[0] = - w;
        _vertices[1] = - h;
        _vertices[2] =   w;
        _vertices[3] = - h;
        _vertices[4] = - w;
        _vertices[5] =   h;
        _vertices[6] =   w;
        _vertices[7] =   h;
    }
    else if(ScreenNumber==2)
    {
        _vertices[0] = - w;
        _vertices[1] =   0;
        _vertices[2] =   w;
        _vertices[3] =   0;
        _vertices[4] = - w;
        _vertices[5] =   h;
        _vertices[6] =   w;
        _vertices[7] =   h;
        
        _vertices[8] = - w;
        _vertices[9] = - h;
        _vertices[10] =   w;
        _vertices[11] = - h;
        _vertices[12] = - w;
        _vertices[13] =   0;
        _vertices[14] =   w;
        _vertices[15] =   0;
    }
    else
    {
        _vertices[0] = -w;  // x0
        _vertices[1] =  0.0f;  // y0
        _vertices[2] =  0.0f;  // ..
        _vertices[3] =  0.0f;
        _vertices[4] = -w;
        _vertices[5] =  h;
        _vertices[6] =  0.0f;  // x3
        _vertices[7] =  h;  // y3
        
        _vertices[8] =  0.0f;  // x0
        _vertices[9] =  0.0f;  // y0
        _vertices[10] =  w;  // ..
        _vertices[11] =  0.0f;
        _vertices[12] =  0.0f;
        _vertices[13] =  h;
        _vertices[14] =  w;  // x3
        _vertices[15] =  h;  // y3
        
        _vertices[16] = -w;  // x0
        _vertices[17] = -h;  // y0
        _vertices[18] =  0.0f;  // ..
        _vertices[19] = -h;
        _vertices[20] = -w;
        _vertices[21] =  0.0f;
        _vertices[22] =  0.0f;  // x3
        _vertices[23] =  0.0f;  // y3
        
        _vertices[24] =  0.0f;  // x0
        _vertices[25] = -h;  // y0
        _vertices[26] =  w;  // ..
        _vertices[27] = -h;
        _vertices[28] =  0.0f;
        _vertices[29] =  0.0f;
        _vertices[30] =  w;  // x3
        _vertices[31] =  0.0f;  // y3
    }
#endif
}






- (void)render: (MyVideoFrame *) frame
{
    static const GLfloat texCoords[] = {
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 0.0f,

        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 0.0f,
        
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 0.0f,
        
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 0.0f,

    };
	
    [EAGLContext setCurrentContext:_context];
    
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
    glViewport(-1, -1, _backingWidth, _backingHeight);
    //glViewport(0, 0, _backingHeight, _backingWidth);
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
	glUseProgram(_program);
    
    if (frame) {

        [_renderer setFrame:frame width:iWidth height:iHeight at:0];
        //[_renderer setFrame:frame width:_backingWidth height:_backingHeight at:0];

    }
    
    if ([_renderer prepareRender]) {
        
        GLfloat modelviewProj[16];
        mat4f_LoadOrtho(-1.0f, 1.0f, -1.0f, 1.0f, -1.0f, 1.0f, modelviewProj);
        glUniformMatrix4fv(_uniformMatrix, 1, GL_FALSE, modelviewProj);
        
        glVertexAttribPointer(ATTRIBUTE_VERTEX, 2, GL_FLOAT, 0, 0, _vertices);
        glEnableVertexAttribArray(ATTRIBUTE_VERTEX);
        glVertexAttribPointer(ATTRIBUTE_TEXCOORD, 2, GL_FLOAT, 0, 0, texCoords);
        glEnableVertexAttribArray(ATTRIBUTE_TEXCOORD);
        
#if 0
        if (!validateProgram(_program))
        {
            //NSLog(@"Failed to validate program");
            return;
        }
#endif
        
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    }
    
    glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);
    [_context presentRenderbuffer:GL_RENDERBUFFER];
}


- (void)clearFrameBuffer
{
    //[EAGLContext setCurrentContext:_context];
    
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
    //glViewport(0, 0, _backingWidth, _backingHeight);
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT); // GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT
}


// When multi-thread, we should avoid different thread access CurrentContext at the same time
// Use operation queue...
// drawToBuffer at location
- (void)setFrame: (MyVideoFrame *) frame at: (eRenderLocType) vLocation
{
    static const GLfloat texCoords[] = {
#if 1
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 0.0f,
#else
        0.0f, 0.5f,
        0.5f, 0.5f,
        0.0f, 0.0f,
        0.5f, 0.0f,
#endif
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 0.0f,
        
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 0.0f,
        
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 0.0f,
    };
	
    [EAGLContext setCurrentContext:_context];
    
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
    glViewport(0, 0, _backingWidth, _backingHeight);
    
//    NSLog(@" w,h = (%d,%d) (%d,%.d)",_backingWidth, _backingHeight, iWidth, iHeight);
//    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
//    glClear(GL_COLOR_BUFFER_BIT);
	glUseProgram(_program);
    
    if (frame) {
        //[_renderer setFrame:frame];
        [_renderer setFrame:frame width:iWidth height:iHeight at:0];
        //[_renderer setFrame:frame width:_backingWidth height:_backingHeight at:0];
    }
    
    if ([_renderer prepareRender]) {
        
        GLfloat modelviewProj[16];
        mat4f_LoadOrtho(-1.0f, 1.0f, -1.0f, 1.0f, -1.0f, 1.0f, modelviewProj);
        glUniformMatrix4fv(_uniformMatrix, 1, GL_FALSE, modelviewProj);
        
        glVertexAttribPointer(ATTRIBUTE_VERTEX, 2, GL_FLOAT, 0, 0, _vertices);
        glEnableVertexAttribArray(ATTRIBUTE_VERTEX);
        glVertexAttribPointer(ATTRIBUTE_TEXCOORD, 2, GL_FLOAT, 0, 0, texCoords);
        glEnableVertexAttribArray(ATTRIBUTE_TEXCOORD);
        
        if(eLOC_TOP_LEFT == vLocation)
            glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        else if(eLOC_TOP_RIGHT == vLocation)
            glDrawArrays(GL_TRIANGLE_STRIP, 4, 4);
        else if(eLOC_BOTTOM_LEFT == vLocation)
            glDrawArrays(GL_TRIANGLE_STRIP, 8, 4);
        else
            glDrawArrays(GL_TRIANGLE_STRIP, 12, 4);
        
    }
    
    // NSLog(@"setFrame at:%d",vLocation);

}

// TODO: caculate the offset of swipe
// TODO: to avoid the texture render over the frame range
// Reference http://stackoverflow.com/questions/8342164/ios-uiswipegesturerecognizer-calculate-offset
- (void)setAVFrame: (AVFrame *) frame at: (eRenderLocType) vLocation
{
    static GLfloat texCoords[] = {
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 0.0f,

        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 0.0f,
        
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 0.0f,
        
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 0.0f,
    };
	
    if (!frame)
        return;
    
    [EAGLContext setCurrentContext:_context];
    
    //glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
    glViewport(0, 0, _backingWidth, _backingHeight);
    
    // Try to minimize below time....
    //NSTimeInterval vTmpTime= [NSDate timeIntervalSinceReferenceDate];
    {
        const NSUInteger frameWidth = frame->width;
        const NSUInteger frameHeight = frame->height;
        
#if ENABLE_YUV_SACLE_BEFORE_RENDER == 1
        NSUInteger widths[3]  = { outputWidth, outputWidth / 2, outputWidth / 2 };
        NSUInteger heights[3] = { outputHeight, outputHeight / 2, outputHeight / 2 };
#else
        NSUInteger widths[3]  = { frameWidth, frameWidth / 2, frameWidth / 2 };
        NSUInteger heights[3] = { frameHeight, frameHeight / 2, frameHeight / 2 };
#endif
        
        int vTmp = 0;
        
        // If the source data is not 4 byte alignment, we should set GL_UNPACK_ALIGNMENT
        glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
        //glPixelStorei(GL_UNPACK_ALIGNMENT, 4);
        //glPixelStorei(GL_UNPACK_ALIGNMENT, 2); //better
        
        // reference http://www.zwqxin.com/archives/opengl/opengl-api-memorandum-2.html
        
        if (0 == pTmpTextures[0])
            glGenTextures(12, pTmpTextures);
        
        
#if ENABLE_YUV_SACLE_BEFORE_RENDER == 1
        // scale YUV before assign to a texture
        sws_scale (img_convert_ctx, frame->data, frame->linesize,
                   0, iHeight,
                   picture.data, picture.linesize);
        {
            int i=0,j=0;
            UInt8 *pTmp = NULL, *pSrc = NULL;
            
            i = 0;
            widths[i] = MIN(picture.linesize[i], widths[i]);
            pSrc = picture.data[i];
            pTmp = pTmpPixels[i];
            for (j = 0; j < heights[i]; ++j) {
                memcpy(pTmp, pSrc, widths[i]);
                pTmp += widths[i];
                pSrc += picture.linesize[i];
            }
            
            i = 1;
            widths[i] = MIN(picture.linesize[i], widths[i]);
            pSrc = picture.data[i];
            pTmp = pTmpPixels[i];
            for (j = 0; j < heights[i]; ++j) {
                memcpy(pTmp, pSrc, widths[i]);
                pTmp += widths[i];
                pSrc += picture.linesize[i];
            }
            
            i = 2;
            widths[i] = MIN(picture.linesize[i], widths[i]);
            pSrc = picture.data[i];
            pTmp = pTmpPixels[i];
            for (j = 0; j < heights[i]; ++j) {
                memcpy(pTmp, pSrc, widths[i]);
                pTmp += widths[i];
                pSrc += picture.linesize[i];
            }
            //NSLog(@" linesize=(%d,%d,%d)",frame->linesize[0],frame->linesize[1],frame->linesize[2]);
        }
#else
        // Unroll the loop to speed up
        // In iPAD2, below need 4~5 ms
        {
            int width = frameWidth, height = frameHeight;
            int i=0,j=0;
            UInt8 *pTmp = NULL, *pSrc = NULL;
            
            i = 0;
            width = MIN(frame->linesize[i], width);
            pSrc = frame->data[i];
            pTmp = pTmpPixels[i];
            for (j = 0; j < height; ++j) {
                memcpy(pTmp, pSrc, width);
                pTmp += width;
                pSrc += frame->linesize[i];
            }
            
            i = 1; height=frameHeight/2; width=frameWidth/2;
            width = MIN(frame->linesize[i], width);
            pSrc = frame->data[i];
            pTmp = pTmpPixels[i];
            for (j = 0; j < height; ++j) {
                memcpy(pTmp, pSrc, width);
                pTmp += width;
                pSrc += frame->linesize[i];
            }
            
            i = 2; height=frameHeight/2; width=frameWidth/2;
            width = MIN(frame->linesize[i], width);
            pSrc = frame->data[i];
            pTmp = pTmpPixels[i];
            for (j = 0; j < height; ++j) {
                memcpy(pTmp, pSrc, width);
                pTmp += width;
                pSrc += frame->linesize[i];
            }
            //NSLog(@" linesize=(%d,%d,%d)",frame->linesize[0],frame->linesize[1],frame->linesize[2]);
        }
#endif
        
        // In iPAD2, below need 4~5 ms
        {
            int i = 0;
            
            glBindTexture(GL_TEXTURE_2D, pTmpTextures[i+vTmp]);
            
            glTexImage2D(GL_TEXTURE_2D,
                         0,
                         GL_LUMINANCE,
                         widths[i],
                         heights[i],
                         0,
                         GL_LUMINANCE,
                         GL_UNSIGNED_BYTE,
                         pTmpPixels[i]);
            
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            
            i = 1;
            glBindTexture(GL_TEXTURE_2D, pTmpTextures[i+vTmp]);
            
            glTexImage2D(GL_TEXTURE_2D,
                         0,
                         GL_LUMINANCE,
                         widths[i],
                         heights[i],
                         0,
                         GL_LUMINANCE,
                         GL_UNSIGNED_BYTE,
                         pTmpPixels[i]);
            
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            
            i = 2;
            glBindTexture(GL_TEXTURE_2D, pTmpTextures[i+vTmp]);
            
            glTexImage2D(GL_TEXTURE_2D,
                         0,
                         GL_LUMINANCE,
                         widths[i],
                         heights[i],
                         0,
                         GL_LUMINANCE,
                         GL_UNSIGNED_BYTE,
                         pTmpPixels[i]);
            
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        }
    }

//    vTmpTime = [NSDate timeIntervalSinceReferenceDate]-vTmpTime;
//    NSLog(@"vTmpTime = %f",vTmpTime);
 
    // 20131106 test
    //glUseProgram(_program);
//    pTmpUniformSamplers[0] = glGetUniformLocation(_program, "s_texture_y");
//    pTmpUniformSamplers[1] = glGetUniformLocation(_program, "s_texture_u");
//    pTmpUniformSamplers[2] = glGetUniformLocation(_program, "s_texture_v");
    
    for (int i = 0; i < 3; ++i) {
        glActiveTexture(GL_TEXTURE0 + i);
        glBindTexture(GL_TEXTURE_2D, pTmpTextures[i]);
        glUniform1i(pTmpUniformSamplers[i], i);
    }
    
    {
        GLfloat modelviewProj[16];
        
        // update the matrix, this can be used to scale
        if(ScreenNumber==1)
        {
#if GLVIEW_SCALE_METHOD == SCALE_BY_OPENGLES
            
            //對於放大縮小以及移動，要試著統一只改變 modelviewProj
            GLKMatrix4 modelviewProjectionMatrix =
            {
                1.0f, 0.0f, 0.0f, 0.0f,
                0.0f, 1.0f, 0.0f, 0.0f,
                0.0f, 0.0f, 1.0f, 0.0f,
                0.0f, 0.0f, 0.0f, 1.0f,
            };
            
            // 此時矩陣運算要直接使用 GLKMatrix4Scale(), GLKMatrix4Translate()
            modelviewProjectionMatrix = GLKMatrix4Scale(modelviewProjectionMatrix, ScaleFactor, ScaleFactor,1.0f);

            if(SwipeFactor_X!=0)
            NSLog(@"Scale:%f,%f 0.01x:%f", ScaleFactor, 1/ScaleFactor, SwipeFactor_X*0.01);
            modelviewProjectionMatrix = GLKMatrix4Translate(
                                                        modelviewProjectionMatrix,
                                                        SwipeFactor_X,
                                                        SwipeFactor_Y,
                                                        0.0f);
            
            glUniformMatrix4fv(_uniformMatrix, 1, GL_FALSE, (CGFloat *)(&modelviewProjectionMatrix));
#endif
        }
        else
        {
            mat4f_LoadOrtho(-1.0f, 1.0f, -1.0f, 1.0f, -1.0f, 1.0f, modelviewProj);
            glUniformMatrix4fv(_uniformMatrix, 1, GL_FALSE, modelviewProj);
        }
        
        glVertexAttribPointer(ATTRIBUTE_VERTEX, 2, GL_FLOAT, 0, 0, _vertices);
        glEnableVertexAttribArray(ATTRIBUTE_VERTEX);
        
        glVertexAttribPointer(ATTRIBUTE_TEXCOORD, 2, GL_FLOAT, 0, 0, texCoords);
        glEnableVertexAttribArray(ATTRIBUTE_TEXCOORD);
        
        if(eLOC_TOP_LEFT == vLocation)
            glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        else if(eLOC_TOP_RIGHT == vLocation)
            glDrawArrays(GL_TRIANGLE_STRIP, 4, 4);
        else if(eLOC_BOTTOM_LEFT == vLocation)
            glDrawArrays(GL_TRIANGLE_STRIP, 8, 4);
        else
            glDrawArrays(GL_TRIANGLE_STRIP, 12, 4);
    }
    
    // NSLog(@"setFrame at:%d",vLocation);
}



-(void)RenderToHardware:(NSTimer *)timer {
    //NSLog(@"RenderToHardware!!");
    
    glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);
    [_context presentRenderbuffer:GL_RENDERBUFFER];
    
    //ENABLE_DISPATCH_QUEUE_FOR_GLVIEW
    //glFlush();

}

-(void)StartRenderLoop
{
    [NSTimer scheduledTimerWithTimeInterval:1/30
                                     target:self
                                   selector:@selector(RenderToHardware:)
                                   userInfo:nil
                                    repeats:YES];
}

static NSData * copyFrameData(UInt8 *src, int linesize, int width, int height)
{
    width = MIN(linesize, width);
    NSMutableData *md = [NSMutableData dataWithLength: width * height];
    Byte *dst = md.mutableBytes;
    
    for (NSUInteger i = 0; i < height; ++i) {
        memcpy(dst, src, width);
        dst += width;
        src += linesize;
    }

    return md;
}

+ (MyVideoFrame *) CopyFullAVFrameToVideoFrame: (AVFrame *) pFrameIn withWidth :(int) vWidth withHeight:(int) vHeight
{
    if (!pFrameIn->data[0])
    {
        NSLog(@"CopyAVFrameToVideoFrame return nil");
        return nil;
    }
    
    MyVideoFrame *yuvFrame = [[MyVideoFrame alloc] init];
    
//    NSTimeInterval vTmpTime= [NSDate timeIntervalSinceReferenceDate];
    //yuvFrame.luma.bytes = pFrameIn->data[0];
    yuvFrame.luma = copyFrameData(pFrameIn->data[0],
                                  pFrameIn->linesize[0],
                                  vWidth,
                                  vHeight);
    
    yuvFrame.chromaB = copyFrameData(pFrameIn->data[1],
                                     pFrameIn->linesize[1],
                                     vWidth / 2,
                                     vHeight / 2);
    
    yuvFrame.chromaR = copyFrameData(pFrameIn->data[2],
                                     pFrameIn->linesize[2],
                                     vWidth / 2,
                                     vHeight / 2);
    
//    vTmpTime = [NSDate timeIntervalSinceReferenceDate]-vTmpTime;
//    NSLog(@"vTmpTime=%f",vTmpTime); // For ipad2, above copy time cost 5ms
    
    yuvFrame.width = vWidth;
    yuvFrame.height = vHeight;
    
    
    return yuvFrame;
}

#pragma mark - Gesture Handler

- (void) tapHandler:(id)sender
{
    FinalFixedScaleFator = 1.0f;
    ScaleFactor = 1.0f;
    
    SwipeFactor_X = 0.0f;
    SwipeFactor_Y = 0.0f;
    
    LeftBoundaryAfterScale = 0.0f;
    RightBoundaryAfterScale = 0.0f;
    UpBoundaryAfterScale = 0.0f;
    DownBoundaryAfterScale = 0.0f;
    
    NSLog(@"Double TAP!");
}

- (void) pinchHandler:(UIPinchGestureRecognizer *)sender
{
    // if sender.scale > 1.0, zoom in
    // if sender.scale < 1.0, zoom out

    float FinalScaleFator = 1.0f;
    FinalScaleFator = FinalFixedScaleFator * sender.scale;
    
    if((FinalScaleFator>1) && (FinalScaleFator<6))
    {
        ScaleFactor = FinalScaleFator;
        
        if([(UIPinchGestureRecognizer*)sender state] == UIGestureRecognizerStateEnded)
        {
            LeftBoundaryAfterScale = (1.0/ScaleFactor);
            RightBoundaryAfterScale = 1-(1.0/ScaleFactor);
            UpBoundaryAfterScale = LeftBoundaryAfterScale;
            DownBoundaryAfterScale = RightBoundaryAfterScale;
            
            FinalFixedScaleFator = ScaleFactor;
            NSLog(@"FixScale=%0.2f, x,y=(%0.2f,%0.2f), boundary(x,y)=(%0.2f,%0.2f)",FinalFixedScaleFator, SwipeFactor_X, SwipeFactor_Y,
                  LeftBoundaryAfterScale,UpBoundaryAfterScale);
            
            // The boundary may change when scale, we should correct the value
            if(SwipeFactor_X > RightBoundaryAfterScale)
                SwipeFactor_X = RightBoundaryAfterScale;
            else if(SwipeFactor_X < -1*LeftBoundaryAfterScale)
                SwipeFactor_X = -1*LeftBoundaryAfterScale;
            
            if(SwipeFactor_Y > UpBoundaryAfterScale)
                SwipeFactor_Y = UpBoundaryAfterScale;
            else if(SwipeFactor_Y < -1*DownBoundaryAfterScale)
                SwipeFactor_Y = -1*DownBoundaryAfterScale;
        }
    }
    
    //NSLog(@"PICH %0.2f! %0.2f, Left=%0.2f, Right=%0.2f", sender.scale, ScaleFactor,LeftBoundaryAfterScale,RightBoundaryAfterScale);
}


-(void) panHandler:(UIPanGestureRecognizer *)sender
{
    static CGFloat startX, startY;
    
    if([(UIPanGestureRecognizer*)sender state] == UIGestureRecognizerStateChanged) {
        
        CGPoint tp = [(UIPanGestureRecognizer*)sender locationInView:self.superview];
        CGFloat deltaX = tp.x - startX;
        CGFloat deltaY = - tp.y + startY;
        startX = tp.x; startY = tp.y;
        
        
        if( fabsf(deltaX) > fabsf(deltaY) )
        {
            if(deltaX>0)
            {
                if(SwipeFactor_X < RightBoundaryAfterScale)
                    SwipeFactor_X += 0.01;
            }
            else
            {
                if(SwipeFactor_X > -1*LeftBoundaryAfterScale)
                    SwipeFactor_X -= 0.01;
            }
        }
        else
        {
            if(deltaY>0)
            {
                if(SwipeFactor_Y < UpBoundaryAfterScale)
                    SwipeFactor_Y += 0.01;
            }
            else
            {
                if(SwipeFactor_Y > -1*DownBoundaryAfterScale)
                    SwipeFactor_Y -= 0.01;
            }
        }
        
        //NSLog(@"start(x,y)=%f,%f, del(x,y)=%f,%f",startX,startY,deltaX,deltaY);
    }
    
    if([(UIPanGestureRecognizer*)sender state] == UIGestureRecognizerStateBegan) {
        CGPoint tp = [(UIPanGestureRecognizer*)sender locationInView:self.superview];
        startX = tp.x;
        startY = tp.y;
    }
}

- (void) rotateHandler:(id)sender
{
    NSLog(@"ROTATE!");
}

- (void) longPressHandler:(UILongPressGestureRecognizer *)sender
{
    NSLog(@"LONG PRESS!");
}

- (void) swipeHandler:(UISwipeGestureRecognizer *)sender
{
    if(sender.direction == UISwipeGestureRecognizerDirectionRight)
    {
        NSLog(@"SWIPE Right");
    }
    if(sender.direction == UISwipeGestureRecognizerDirectionLeft)
    {
        NSLog(@"SWIPE Left");
    }
    if(sender.direction == UISwipeGestureRecognizerDirectionUp)
    {
        NSLog(@"SWIPE Up");
    }
    if(sender.direction == UISwipeGestureRecognizerDirectionDown)
    {
        NSLog(@"SWIPE Down");
    }
}


@end

