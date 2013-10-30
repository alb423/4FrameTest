

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "MyGLView.h"

//////////////////////////////////////////////////////////

#pragma mark - shaders

#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)
#define SHADER_STRING(text) @ STRINGIZE2(text)

NSString *const VSaaS_vertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 attribute vec2 texcoord;
 uniform mat4 modelViewProjectionMatrix;
 varying vec2 v_texcoord;
 
 void main()
 {
     gl_Position = modelViewProjectionMatrix * position;
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

    }
    
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
	
	glLinkProgram(_program);
    
    GLint status;
    glGetProgramiv(_program, GL_LINK_STATUS, &status);
    if (status == GL_FALSE) {
		//NSLog(@"Failed to link program %d", _program);
        goto exit;
    }
    
    result = validateProgram(_program);
    
    _uniformMatrix = glGetUniformLocation(_program, "modelViewProjectionMatrix");
    [_renderer resolveUniforms:_program];
	
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
    const float w       = (width  * dd / (float)_backingWidth );

    NSLog(@"updateVertices fit=%d, (%f,%f) (%d,%d)", fit, width, height, _backingWidth, _backingHeight);
    NSLog(@"updateVertices w,h=(%f,%f) dw,dh=(%f,%f) dd=%f",w, h, dW, dH, dd);
    
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
    glViewport(0, 0, _backingWidth, _backingHeight);
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
    glClear(GL_COLOR_BUFFER_BIT);
}

- (void)setTexture: (MyVideoFrame *) frame at: (eRenderLocType) vLocation
{
    if (frame) {
        //[_renderer setFrame:frame];
        //[_renderer setFrame:frame width:fWidth height:fHeight at:0];
        
        [_renderer setFrame:frame width:frame.width height:frame.height at:0];
        
        //[_renderer setFrame:frame width:_backingWidth height:_backingHeight at:0];
    }
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
    
    yuvFrame.width = vWidth;
    yuvFrame.height = vHeight;
    
    
    return yuvFrame;
}

static NSData * copyHalfFrameData(UInt8 *src, int linesize, int width, int height)
{
    width = MIN(linesize, width);
    NSMutableData *md = [NSMutableData dataWithLength: width * height/2];
    Byte *dst = md.mutableBytes;

    for (NSUInteger i = 0; i < height/2; ) {
        if(i%1==1) continue;
        memcpy(dst, src, width);
        dst += width;
        src += linesize;
        i++;
    }
    return md;
}

+ (MyVideoFrame *) CopyHalfAVFrameToVideoFrame: (AVFrame *) pFrameIn withWidth :(int) vWidth withHeight:(int) vHeight
{
    if (!pFrameIn->data[0])
    {
        NSLog(@"CopyAVFrameToVideoFrame return nil");
        return nil;
    }
    
    MyVideoFrame *yuvFrame = [[MyVideoFrame alloc] init];
    
    //yuvFrame.luma.bytes = pFrameIn->data[0];
    yuvFrame.luma = copyHalfFrameData(pFrameIn->data[0],
                                  pFrameIn->linesize[0],
                                  vWidth,
                                  vHeight);
    
    yuvFrame.chromaB = copyHalfFrameData(pFrameIn->data[1],
                                     pFrameIn->linesize[1],
                                     vWidth / 2,
                                     vHeight / 2);
    
    yuvFrame.chromaR = copyHalfFrameData(pFrameIn->data[2],
                                     pFrameIn->linesize[2],
                                     vWidth / 2,
                                     vHeight / 2);
    
    yuvFrame.width = vWidth;
    yuvFrame.height = vHeight/2;
    
    
    return yuvFrame;
}

@end

