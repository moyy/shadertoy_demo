// ======================= 实用方法 ======================= 

// 2D 叉乘，正数 逆时针
float cross2d(vec2 u, vec2 v) {
    return u.x * v.y - u.y * v.x;
}
// ======================= 坐标-变换 ======================= 

// 1像素 对应的 uv 坐标
float uv1() {
    return 1.0 / max(iResolution.x, iResolution.y);
}

// pixel --> uv
float uv(float pixel) {
    return pixel * uv1();
}

// pixel --> uv
vec2 uv(vec2 coord) {
    return coord * uv1();
}

// uv --> pixel
float pixel(float uv) {
    return uv / uv1();
}

// uv -> pixel
vec2 pixel(vec2 coord) {
    return coord / uv1();
}

// 坐标 平移 变换
vec2 translate(vec2 coord, vec2 offset) {
    return coord - offset;
}

// 坐标 缩放 变换
// 注：非均匀 缩放 会 扭曲 sdf
float scale(float d, float s) {
    return d / s;
}

// 坐标 缩放 变换
// 注：非均匀 缩放 会 扭曲 sdf
vec2 scale(vec2 coord, vec2 s) {
    return coord / s;
}

vec2 rotate(vec2 pt, float rad) {
    float c = cos(rad);
    float s = sin(rad);
    return mat2(c, -s, s, c) * pt;
}

// dir = vec2(cos, sin)
vec2 rotate(vec2 pt, vec2 dir) {
    return mat2(dir.x, -dir.y, dir.y, dir.x) * pt;
}

// ======================= 组合 ======================= 

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

// ======================= SDF ======================= 

// Half Plane
// x轴-半平面，右手定则，上半部分 里面；
float sdfHP(vec2 coord) {
    return -coord.y;
}

float sdfHP(vec2 coord, float angle) {
    coord = rotate(coord, angle);

    return sdfHP(coord);
}

float sdfHP(vec2 coord, vec2 center, float angle) {
    
    coord = translate(coord, center);
    coord = rotate(coord, angle);
    
    return sdfHP(coord);
}

// 指定单位向量 的 半平面
float sdfHP(vec2 coord, vec2 dir) {
    
    coord = rotate(coord, dir);
    
    return sdfHP(coord);
}

// 过两个点的半平面
float sdfHP(vec2 coord, vec2 start, vec2 end) {
    coord = translate(coord, start);
    vec2 dir = normalize(end - start);
    return sdfHP(coord, dir);
}

// 有向线段：有一个端点在 原点，x轴-正向
// 逆时针 为 里面
float sdfHPSegment(vec2 coord, float len) {
    
    float proj = clamp(coord.x, 0.0, len);
    
    float s = coord.y > 0.0 ? -1.0 : 1.0;
    
    coord -= proj * vec2(1.0, 0.0);
    
    return s * length(coord);
}

// 有向线段：有一个端点在 原点，x轴-正向
// 逆时针 为 里面
float sdfHPSegment(vec2 coord, vec2 start, vec2 end) {
    float len = length(end - start);
    vec2 dir = (end - start) / len;
    
    coord = translate(coord, start);
    coord = rotate(coord, dir);

    return sdfHPSegment(coord, len);
}

// 线段
float sdfSegment(vec2 coord, vec2 start, vec2 end) {
    return -abs(sdfHPSegment(coord, start, end));
}

float sdfCircle(vec2 coord, float r) {
    return length(coord) - r;
}

float sdfCircle(vec2 coord, vec2 center, float r) {
    
    coord = translate(coord, center);
    
    return sdfCircle(coord, r);
}

// r 半径
// 返回：圆 sdf，里面为负数，外面为正数
float sdfCircle(vec2 coord, vec2 center, vec2 s, float r) {
    
    coord = translate(coord, center);
    
    coord = scale(coord, s);

    float d = sdfCircle(coord, r);

    // 缩放比例 要 乘回去
    d *= min(s.x, s.y);
    
    // webrender 做法
    // float ds = sqrt(2.0) / length(fwidth(coord));
    // d *= ds;

    return d;
}

// https://iquilezles.org/articles/ellipsoids/
float sdfEllipse1(vec2 coord, vec2 ab)
{
    float k1 = length(coord / ab);
    float k2 = length(coord / (ab * ab));
    return (k1 - 1.0) * k1 / k2;
}

// https://iquilezles.org/articles/ellipsoids/
float sdfEllipse1(vec2 coord, vec2 center, vec2 ab)
{
    coord = translate(coord, center);

    return sdfEllipse1(coord, ab);
}

// https://iquilezles.org/articles/ellipsoids/
float sdfEllipse1(vec2 coord, vec2 center, vec2 s, vec2 ab)
{
    coord = translate(coord, center);
    coord = scale(coord, s);
    float d = sdfEllipse1(coord, ab);
    
    // 缩放比例 要 乘回去
    d *= min(s.x, s.y);

    return d;
}

// https://www.shadertoy.com/view/tttfzr
float sdfEllipse2(vec2 coord, vec2 ab)
{
    // symmetry
    coord = abs(coord);
    
    // initial value
    vec2 q = ab * (coord - ab);
    vec2 cs = normalize((q.x < q.y) ? vec2(0.01, 1) : vec2(1, 0.01) );

    // find root with Newton solver
    for(int i = 0; i < 5; i++) {
        vec2 u = ab * vec2(cs.x,cs.y);
        vec2 v = ab * vec2(-cs.y,cs.x);
        
        float a = dot(coord - u, v);
        float c = dot(coord - u, u) + dot(v, v);
        float b = sqrt(c * c - a * a);
        
        cs = vec2( cs.x * b - cs.y * a, cs.y * b + cs.x * a ) / c;
    }
    
    // compute final point and distance
    float d = length(coord - ab * cs);
    
    // return signed distance
    return (dot(coord / ab, coord / ab) > 1.0) ? d : -d;
}

float sdfEllipse2(vec2 coord, vec2 center, vec2 ab)
{
    coord = translate(coord, center);

    return sdfEllipse2(coord, ab);
}

float sdfEllipse2(vec2 coord, vec2 center, vec2 s, vec2 ab)
{
    coord = translate(coord, center);
    coord = scale(coord, s);
 
    float d = sdfEllipse2(coord, ab);
    
    // 缩放比例 要 乘回去
    d *= min(s.x, s.y);

    return d;
}

// 用 有向线段 模拟 半圆
float sdfHalfCircleApprox(vec2 coord, vec2 center, float angle, float r) {
    float c = sdfCircle(coord, center, r);
    
    vec2 dir = vec2(cos(angle), sin(angle));
    float hp = sdfHPSegment(coord, center - r * dir, center + r * dir);
    
    return intersectionSdf(hp, c);
}

// 用 有向线段 模拟 弓形
float sdfBowApprox(vec2 coord, vec2 center, float angle, float r) {
    float c = sdfCircle(coord, center, r);
    
    vec2 dir = vec2(cos(angle), sin(angle));
    
    vec2 start = center + r * dir;
    vec2 end = center + r * vec2(dir.x, -dir.y);
    float hp = sdfHPSegment(coord, start, end);
    
    return intersectionSdf(hp, c);
}

// 用 有向线段 模拟 扇形
float sdfPieApprox(vec2 coord, vec2 center, float r, float angle1, float angle2) {
    
    float c = sdfCircle(coord, center, r);
    
    float hp1 = sdfHPSegment(coord, center, center + r * vec2(cos(angle1), sin(angle1)));

    float hp2 = sdfHPSegment(coord, center, center + r * vec2(cos(angle2), sin(angle2)));
    
    float d = c;

    d = intersectionSdf(d, hp1);
    d = intersectionSdf(d, complementSdf(hp2));
    return d;
}

// 用 有向线段 模拟 三角形
// 逆时针的 3个点
float sdfTriApprox(vec2 coord, vec2 p1, vec2 p2, vec2 p3) {
    float hp1 = sdfHPSegment(coord, p1, p2);
    float hp2 = sdfHPSegment(coord, p2, p3);
    float hp3 = sdfHPSegment(coord, p3, p1);    
    
    float d = hp1;
    d = intersectionSdf(d, hp2);
    d = intersectionSdf(d, hp3);
    return d;
}

// 用 有向线段 模拟 矩形
float sdfRectApprox(vec2 coord, vec2 center, vec2 extent, float angle) {

    coord = translate(coord, center);
    coord = rotate(coord, angle);

    vec2 lt = vec2(-extent.x, extent.y);
    vec2 lb = vec2(-extent.x, -extent.y);
    vec2 rb = vec2(extent.x, -extent.y);
    vec2 rt = vec2(extent.x, extent.y);
    
    float hp1 = sdfHPSegment(coord, lt, lb);

    float hp2 = sdfHPSegment(coord, lb, rb);

    float hp3 = sdfHPSegment(coord, rb, rt);

    float hp4 = sdfHPSegment(coord, rt, lt);

    float d = hp1;
    d = intersectionSdf(d, hp2);
    d = intersectionSdf(d, hp3);
    d = intersectionSdf(d, hp4);
    return d;
}

// ======================= 可视化 方法 ======================= 

// 等值线
vec3 isovalue(float d) {
    // 画成 uv
    d = uv(d);

    // 外 红 内 绿
    vec3 col = (d > 0.0) ? vec3(1.0, 0.0, 0.0) : vec3(0.0, 1.0, 0.0);

    col *= 1.0 - exp(-6.0 * abs(d));
	
    col *= 0.8 + 0.2 * cos(150.0 * d);
	
    col = mix(col, vec3(1.0), 1.0 - smoothstep(0.0, 0.01, abs(d)) );

    return col;
}

// 按鼠标左键，能显示 该点的 sdf 圆
void showEllipseSdf(out vec3 color, vec2 coord, vec2 center, vec2 s, vec2 ab, int method) {
    if ( iMouse.z > 0.001 ) {
        vec2 m = iMouse.xy;
        float d = 0.0;
        if (method == 1) {
            d = sdfEllipse1(m, center, s, ab);
        } else {
            d = sdfEllipse2(m, center, s, ab);
        }

        float len = length(coord - m);
        
        len = uv(len);
        d = uv(d);

        color = mix(color, vec3(1.0, 1.0, 0.0), 1.0 - smoothstep(0.0, 0.005, abs(len - abs(d)) - 0.0025));
        
        color = mix(color, vec3(1.0, 1.0, 0.0), 1.0 - smoothstep(0.0, 0.005, len - 0.015));
    }
}

// 按鼠标左键，能显示 该点的 sdf 圆
void showHPSdf(out vec3 color, vec2 coord, vec2 start, vec2 end) {
    if ( iMouse.z > 0.001 ) {
        vec2 m = iMouse.xy;
        float d = sdfHP(m, start, end);

        float len = length(coord - m);
        
        len = uv(len);
        d = uv(d);

        color = mix(color, vec3(1.0, 1.0, 0.0), 1.0 - smoothstep(0.0, 0.005, abs(len - abs(d)) - 0.0025));
        
        color = mix(color, vec3(1.0, 1.0, 0.0), 1.0 - smoothstep(0.0, 0.005, len - 0.015));
    }
}

// 画 坐标轴 网格
vec3 showGrid(vec2 coord, float row, float column) {
    coord = uv(coord);
    coord = vec2(row, column) * coord;
    
    vec2 cell;
    
    // 每像素 的 宽度
    vec2 ps = fwidth(coord);

    cell = fract(coord);
    cell = 1.0 - 2.0 * abs(cell - 0.5);
    
    vec3 color = vec3(0.0);
    if (cell.x < 2.0 * ps.x || cell.y < ps.y) {
        color = vec3(1.0);
    }

    if (abs(coord.x) < ps.x) {
        color = vec3(1.0, 0.0, 0.0);
    }
    if (abs(coord.y) < ps.y) {
        color = vec3(0.0, 1.0, 0.0);
    }

    return color;
}

// ======================= 抗锯齿 ======================= 

// 抗锯齿 方法 1
float aa_1(float d) {
    // 0.5 像素 的 smoothstep
    
    // smoothstep 说明：smoothstep(a, b, x) x<a 返回0，x>b 返回1，否则在[0,1] 平滑插值
    
    return smoothstep(0.5, -0.5, d);
}

// 抗锯齿 方法 2
float aa_2(float d) {

    // 用 fwidth 确定 1像素 对应 的 sdf-变化 值
    float dd = fwidth(d);
    
    // fwidth 的 smoothstep
    return smoothstep(dd, -dd, d);
}

// 抗锯齿 方法 3
// 0.5 像素 + clamp
float aa_3(float d) {
    // 像素 d 在 [-0.5, 0.5] 之间才会截取 到 [0.0, 1.0]
    return clamp(0.5 - d, 0.0, 1.0);
}

// 抗锯齿 方法 4
// 1 像素 + clamp
float aa_4(float d) {
    // 像素 d 在 [-1, 1] 之间才会截取 到 [0.0, 1.0]
    return clamp(0.5 - 0.5 * d, 0.0, 1.0);
}

// =========== Demo

// 编辑器 https://sparkar.facebook.com/ar-studio/learn/patch-editor/shader-patches/introduction-sdf-patches/
void mainImage(out vec4 fragColor, in vec2 fragCoord )
{
    vec2 coord = fragCoord;

    vec3 color = vec3(0.0, 0.0, 0.0);
    vec3 fg = vec3(0.0, 1.0, 0.0);

    float now, angle;
    
    now = 1.0;
    now = sin(0.1 * iTime);

    angle = 3.14159265 / 6.0;
    angle = 3.14159265 / 1.0 * now;

    float d1 = sdfHalfCircleApprox(coord, vec2(100.0, 100.0), angle, 50.0);
    color = mix(color, fg, aa_4(d1));

    float d2 = sdfBowApprox(coord, vec2(250.0, 100.0), angle, 50.0);
    color = mix(color, fg, aa_4(d2));

    float d3 = sdfPieApprox(coord, vec2(400.0, 100.0), 50.0, 0.0, angle);
    color = mix(color, fg, aa_4(d3));

    float d4 = sdfTriApprox(coord, vec2(100.0, 200.0), vec2(200.0, 200.0), vec2(150.0, 250.0));
    color = mix(color, fg, aa_4(d4));

    float d5 = sdfRectApprox(coord, vec2(300.0, 250.0), vec2(30.0, 60.0), angle);
    color = mix(color, fg, aa_4(d5));

    float d6 = sdfPieApprox(coord, vec2(400.0, 250.0), 50.0, 0.0, angle);
    d6 = annularSdf(d6, 6.0);
    color = mix(color, fg, aa_4(d6));

    float d7 = sdfTriApprox(coord, vec2(100.0, 250.0), vec2(200.0, 270.0), vec2(150.0, 300.0));
    d7 = annularSdf(d7, 6.0);
    color = mix(color, fg, aa_4(d7));

    float d8 = sdfRectApprox(coord, vec2(300.0, 350.0), vec2(30.0, 60.0), angle);
    d8 = annularSdf(d8, 6.0);
    color = mix(color, fg, aa_4(d8));

    float d9 = sdfBowApprox(coord, vec2(200.0, 50.0), angle, 30.0);
    d9 = annularSdf(d9, 6.0);
    color = mix(color, fg, aa_4(d9));

    // blend
    float d10 = sdfEllipse2(coord, vec2(100.0, 400.0), vec2(75, 30));
    float d11 = sdfRectApprox(coord, vec2(100.0, 400.0), vec2(30.0, 60.0), angle);
    float d12 = mixSdf(d10, d11, abs(now));
    color = mix(color, fg, aa_4(d12));

    // smooth union
    float d13 = sdfCircle(coord, vec2(200.0, 530.0), 70.0);
    float d14 = sdfCircle(coord, vec2(340.0, 530.0), 70.0);
    float d15;
    d15 = unionSdf(d13, d14); 
    d15 = sunionSdf(d13, d14, 0.4);
    color = mix(color, fg, aa_4(d15));

    vec2 start16 = vec2(560.0, 120.0);
    vec2 end16 = start16 + 100.0 * vec2(sin(0.05 * iTime), cos(0.05 * iTime));
    float d16 = sdfSegment(coord, start16, end16);
    color = mix(color, fg, aa_4(abs(d16)));

    // 等高线
    color = isovalue(d5);

    fragColor = vec4(color, 1.0);
}