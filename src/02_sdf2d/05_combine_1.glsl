// https://sparkar.facebook.com/ar-studio/learn/patch-editor/shader-patches/sdf-patches#example

// sdf 内部 负，外面 正
float sdfCircle(vec2 pt, float r) {
    return length(pt) - r;
}

// 半平面：x轴 正向 半平面，逆时针 为 里面
float sdfHP(vec2 pt) {
    return -pt.y;
}

// =========== 变换

vec2 translate(vec2 pt, vec2 center) {
    return pt - center;
}

// 注：不均匀缩放会引起 sdf 失真
vec2 scale(vec2 pt, vec2 s) {
    return pt / s;
}

vec2 rotate(vec2 pt, float rad) {
    float c = cos(rad);
    float s = sin(rad);
    return mat2(c, -s, s, c) * pt;
}

// =========== Combine

// 补集
float complementSdf(float sdf) {
    return -sdf;
}

// 并集
float unionSdf(float sdf1, float sdf2) {
    return min(sdf1, sdf2);
}

// 交集
float intersectionSdf(float sdf1, float sdf2) {
    return max(sdf1, sdf2);
}

// 差集 sdf1 - sdf2
float differenceSdf(float sdf1, float sdf2) {
    return max(sdf1, -sdf2);
}

// 环
float annularSdf(float sdf, float radius) {
    radius *= 0.5;
    
    return max(sdf - radius, - sdf - radius);
}

float smin(float a, float b, float k) {
     
     float h = clamp(0.5 + 0.5 * (a - b) / k, 0.0, 1.0);
     
     return mix(a, b, h) - k * h * (1.0 - h);
}


float smax(float a, float b, float k) {
     return -smin(-a, -b, k);
}

// 平滑-并集 smin
// https://zhuanlan.zhihu.com/p/246501223)
float sunionSdf(float sdf1, float sdf2, float k) {
    return smin(sdf1, sdf2, k);
}

// 平滑-交集
float sintersectionSdf(float sdf1, float sdf2, float k) {
    return smax(sdf1, sdf2, k);
}

// 平滑-差集 sdf1 - sdf2
float sdifferenceSdf(float sdf1, float sdf2, float k) {
    return smax(sdf1, -sdf2, k);
}

// 混合
float mixSdf(float sdf1, float sdf2, float t) {
    return mix(sdf1, sdf2, t);
}

// =========== Demo

float sdfHPTransform(vec2 pt, vec2 p0, float angle) {
    vec2 p = translate(pt, p0);
    p = rotate(p, angle);
    
    return sdfHP(p);
}

float sdfCircleTransform(vec2 pt, vec2 center, float r) {
    vec2 p = translate(pt, center);
    
    return sdfCircle(p, r);
}

// 圆环：差集
void ring(out vec4 fragColor, in vec2 fragCoord )
{
    vec2 pt = fragCoord;
    
    float width = 20.0;
    float radius = 100.0;
    
    vec2 center = vec2(200.0, 200.0);
    
    float circle1 = sdfCircleTransform(pt, center, radius);
    float circle2 = sdfCircleTransform(pt, center, radius - width);
    
    float d = differenceSdf(circle1, circle2);
    
    fragColor = vec4(d, 0.0, 0.0, 1.0);
}


// 半圆
void halfCircle(out vec4 fragColor, in vec2 fragCoord )
{
    vec2 pt = fragCoord;
    
    vec2 center = vec2(200.0, 200.0);
    float circle = sdfCircleTransform(pt, center, 50.0);
    
    float hp1 = sdfHPTransform(pt, center, 0.0);
    
    float d = intersectionSdf(circle, hp1);
    
    fragColor = vec4(0.0, d, 0.0, 1.0);
}

// 旋转-半圆
void halfCircleRotate(out vec4 fragColor, in vec2 fragCoord )
{
    vec2 pt = fragCoord;
    
    vec2 center = vec2(200.0, 200.0);
    
    float circle = sdfCircleTransform(pt, center, 50.0);
    
    float hp1 = sdfHPTransform(pt, center, 3.14159265 / 6.0);
    
    float d = intersectionSdf(circle, hp1);
    
    fragColor = vec4(d, 0.0, 0.0, 1.0);
}

// 弓形
void bow(out vec4 fragColor, in vec2 fragCoord )
{
    vec2 pt = fragCoord;
    
    vec2 center = vec2(200.0, 200.0);
    
    float circle = sdfCircleTransform(pt, center, 100.0);
    
    center += vec2(50.0);
    float hp1 = sdfHPTransform(pt, center, 0.0);
    
    float d = intersectionSdf(circle, hp1);
    
    fragColor = vec4(d, 0.0, 0.0, 1.0);
}

// 扇形：近似
// 注：不是 理论正确的 sdf。。。。
void pie(out vec4 fragColor, in vec2 fragCoord )
{
    vec2 pt = fragCoord;
    
    vec2 center = vec2(200.0, 200.0);
    
    float circle = sdfCircleTransform(pt, center, 100.0);
    
    float hp1 = sdfHPTransform(pt, center, 3.1459265 / 6.0);

    float hp2 = sdfHPTransform(pt, center, 3.1459265 / 2.0);
    hp2 = complementSdf(hp2);
    
    float d = intersectionSdf(circle, hp1);
    d = intersectionSdf(d, hp2);
    
    fragColor = vec4(d, 0.0, 0.0, 1.0);
}

// 三角形：近似
// 多边形 同理
// 注：不是 理论正确的 sdf。。。。
void triagnle(out vec4 fragColor, in vec2 fragCoord )
{
    vec2 pt = fragCoord;
    
    vec2 p0 = vec2(300.0, 200.0);
    float hp1 = sdfHPTransform(pt, p0, 3.1459265 / 6.0);
    hp1 = complementSdf(hp1);
    
    vec2 p1 = vec2(500.0, 200.0);
    float hp2 = sdfHPTransform(pt, p1, 2.0 * 3.1459265 / 3.0);

    float hp3 = sdfHPTransform(pt, p0, 0.0);
    
    float d = intersectionSdf(hp1, hp2);
    d = intersectionSdf(d, hp3);
    
    fragColor = vec4(d, 0.0, 0.0, 1.0);
}

// 矩形：近似
// 注：不是 理论正确的 sdf。。。。
float sdfRectApprox(vec2 pt, vec2 center, float angle, vec2 wh)
{
    pt = translate(pt, center);
    pt = rotate(pt, angle);
    
    pt = abs(pt);
    
    float hp1 = sdfHPTransform(pt, vec2(wh.x, 0.0), 3.1459265 / 2.0);
    
    float hp2 = sdfHPTransform(pt, vec2(0.0, wh.y), 3.1459265);
    
    return intersectionSdf(hp1, hp2);
}

// 矩形：近似
void rect(out vec4 fragColor, in vec2 fragCoord )
{
    vec2 pt = fragCoord;

    float d = sdfRectApprox(pt, vec2(300.0, 200.0), 3.14159265 / 6.0, vec2(100.0, 150.0));
    
    fragColor = vec4(d, 0.0, 0.0, 1.0);
}

void mixCircleRect(out vec4 fragColor, in vec2 fragCoord )
{
    vec2 pt = fragCoord;

    vec2 center = vec2(300.0, 200.0);
    
    float dCircle = sdfCircle(pt - center, 300.0);

    float dRect = sdfRectApprox(pt, center, 3.14159265 / 6.0, vec2(200.0, 50.0));    
    
    float d = mixSdf(dCircle, dRect, fract(0.5 * iTime));
    
    fragColor = vec4(d, 0.0, 0.0, 1.0);
}


void testAnnular(out vec4 fragColor, in vec2 fragCoord ) 
{
    vec2 pt = fragCoord;

    float d = sdfRectApprox(pt, vec2(300.0, 200.0), 0.0 * 3.14159265 / 6.0, vec2(100.0, 150.0));
    
    d = annularSdf(d, 20.0); 
    
    fragColor = vec4(d, 0.0, 0.0, 1.0);
    
    fragColor = vec4(d / 20.0, 0.0, 0.0, 1.0);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord )
{
    ring(fragColor, fragCoord);
    
    // halfCircle(fragColor, fragCoord);
    
    // halfCircleRotate(fragColor, fragCoord);
    
    // bow(fragColor, fragCoord);
    
    // pie(fragColor, fragCoord);
    
    // triagnle(fragColor, fragCoord);
    
    // rect(fragColor, fragCoord);
    
    // mixCircleRect(fragColor, fragCoord);
    
    testAnnular(fragColor, fragCoord);
}