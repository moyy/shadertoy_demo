// sdf 内部 负，外面 正
float sdfCircle(vec2 pt, float r) {
    return length(pt) - r;
}

float cross2d(vec2 u, vec2 v) {
    return u.x * v.y - u.y * v.x;
}

// 半平面：逆时针 为 里面
// (0， dir) 有向 直线
float sdfHalfPlane(vec2 pt, vec2 dir) {
    vec2 proj = dot(pt, dir) * dir;
    
    vec2 perp = pt - proj;
    
    float d = length(perp);
    float s = -cross2d(pt, dir);
    
    return sign(s) * d;
}

// 简单 半平面：x轴 正向 半平面，逆时针 为 里面
float sdfHalfPlaneSimple(vec2 pt) {
    return -pt.y;
}

// ================ 变换

// 平移
vec2 translate(vec2 pt, vec2 center) {
    return pt - center;
}

// 缩放
// 注：不均匀缩放会引起 sdf 失真
vec2 scale(vec2 pt, vec2 s) {
    return pt / s;
}

vec2 rotate(vec2 pt, float rad) {
    float c = cos(rad);
    float s = sin(rad);
    return mat2(c, -s, s, c) * pt;
}

// ================ Demo

void circle( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 pt = fragCoord;
    
    float radius = 200.0; 
    float d = sdfCircle(pt, radius);
    
    fragColor = vec4(d, 0.0, 0.0, 1.0);
    // fragColor = vec4(-d / radius, d / radius, 0.0, 1.0);
}

void withTranslate( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 pt = fragCoord;
    pt = translate(pt, vec2(205.0));
    
    float r = 200.0;
    float d = sdfCircle(pt, r);
    
    fragColor = vec4(-d / r, d / r, 0.0, 1.0);
}

void withScaleTranslate( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 pt = fragCoord;
 
    // 变换顺序 是 从下往上 看
    pt = translate(pt, vec2(205.0));
    pt = scale(pt, vec2(0.5));

    float r = 200.0;
    float d = sdfCircle(pt, r);
    
    fragColor = vec4(-d / r, d / r, 0.0, 1.0);
}

void hp(out vec4 fragColor, in vec2 fragCoord )
{
    vec2 pt = fragCoord;
    
    float rad = 3.14159265 / 4.0;
    vec2 dir = vec2(cos(rad), sin(rad));
    
    float d = sdfHalfPlane(pt, dir);
    
    fragColor = vec4(d, 0.0, 0.0, 1.0);
    fragColor = vec4(-d / max(iResolution.x, iResolution.y), d / max(iResolution.x, iResolution.y), 0.0, 1.0);
}

void hpWithTransform( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 pt = fragCoord;
    
    pt = translate(pt, vec2(0.0, 300.0));
    pt = rotate(pt, 3.14159265 / 4.0);
    
    float rad = 0.0;
    vec2 dir = vec2(cos(rad), sin(rad));
    
    float d = sdfHalfPlane(pt, dir);
    
    fragColor = vec4(d, 0.0, 0.0, 1.0);
    // fragColor = vec4(-d / max(iResolution.x, iResolution.y), d / max(iResolution.x, iResolution.y), 0.0, 1.0);
}

// 简单半平面
void hpSimple(out vec4 fragColor, in vec2 fragCoord )
{
    vec2 pt = fragCoord;
    
    float d = sdfHalfPlaneSimple(pt);
    
    fragColor = vec4(d, 0.0, 0.0, 1.0);
    fragColor = vec4(-d / max(iResolution.x, iResolution.y), d / max(iResolution.x, iResolution.y), 0.0, 1.0);
}

// 简单半平面 + 平移
void hpSimpleWithTransform(out vec4 fragColor, in vec2 fragCoord )
{
    vec2 pt = fragCoord;
    
    pt = translate(pt, vec2(0.0, 300.0));
    pt = rotate(pt, 3.14159265 / 4.0);
    
    float d = sdfHalfPlaneSimple(pt);
    
    fragColor = vec4(d, 0.0, 0.0, 1.0);
    fragColor = vec4(-d / 100.0, d / max(iResolution.x, iResolution.y), 0.0, 1.0);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    circle(fragColor, fragCoord);
    
    // withTranslate(fragColor, fragCoord);
    
    // withScaleTranslate(fragColor, fragCoord);

    // hp(fragColor, fragCoord);
    
    // hpSimpleWithTransform(fragColor, fragCoord);
    
    // hpSimple(fragColor, fragCoord);
    
    // hpSimpleWithTransform(fragColor, fragCoord);
}