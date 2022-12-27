// 矩形 和 圆角矩形的 sdf 推导: https://zhuanlan.zhihu.com/p/420700051

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

// 坐标 平移 变换
vec3 translate(vec3 coord, vec3 offset) {
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

// 坐标 缩放 变换
// 注：非均匀 缩放 会 扭曲 sdf
vec3 scale(vec3 coord, vec3 s) {
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

    return max(sdf - radius, -sdf - radius);
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

float sdfCircle(vec3 coord, float r) {
    return length(coord) - r;
}

float sdfCircle(vec3 coord, vec3 center, float r) {
    coord = translate(coord, center);

    return sdfCircle(coord, r);
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
float sdfEllipse1(vec2 coord, vec2 ab) {
    float k1 = length(coord / ab);
    float k2 = length(coord / (ab * ab));
    return (k1 - 1.0) * k1 / k2;
}

// https://iquilezles.org/articles/ellipsoids/
float sdfEllipse1(vec2 coord, vec2 center, vec2 ab) {
    coord = translate(coord, center);

    return sdfEllipse1(coord, ab);
}

// https://iquilezles.org/articles/ellipsoids/
float sdfEllipse1(vec2 coord, vec2 center, vec2 s, vec2 ab) {
    coord = translate(coord, center);
    coord = scale(coord, s);
    float d = sdfEllipse1(coord, ab);

    // 缩放比例 要 乘回去
    d *= min(s.x, s.y);

    return d;
}

// https://www.shadertoy.com/view/tttfzr
float sdfEllipse2(vec2 coord, vec2 ab) {
    // symmetry
    coord = abs(coord);

    // initial value
    vec2 q = ab * (coord - ab);
    vec2 cs = normalize((q.x < q.y) ? vec2(0.01, 1) : vec2(1, 0.01));

    // find root with Newton solver
    for(int i = 0; i < 5; i++) {
        vec2 u = ab * vec2(cs.x, cs.y);
        vec2 v = ab * vec2(-cs.y, cs.x);

        float a = dot(coord - u, v);
        float c = dot(coord - u, u) + dot(v, v);
        float b = sqrt(c * c - a * a);

        cs = vec2(cs.x * b - cs.y * a, cs.y * b + cs.x * a) / c;
    }

    // compute final point and distance
    float d = length(coord - ab * cs);

    // return signed distance
    return (dot(coord / ab, coord / ab) > 1.0) ? d : -d;
}

float sdfEllipse2(vec2 coord, vec2 center, vec2 ab) {
    coord = translate(coord, center);

    return sdfEllipse2(coord, ab);
}

float sdfEllipse2(vec2 coord, vec2 center, vec2 s, vec2 ab) {
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

// https://zhuanlan.zhihu.com/p/420700051
// https://iquilezles.org/articles/distfunctions2d/
float sdfRect(vec2 coord, vec2 extent) {
    vec2 d = abs(coord) - extent;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

// https://iquilezles.org/articles/distfunctions2d/
float sdfRect(vec2 coord, vec2 center, vec2 extent, float angle) {
    coord = translate(coord, center);
    coord = rotate(coord, angle);
    return sdfRect(coord, extent);
}

// https://zhuanlan.zhihu.com/p/420700051
// https://iquilezles.org/articles/distfunctions2d/
// 限制：r 每个分量 不能 超过 min(extent)
// 限制：只能画 圆 的 圆角矩形
float sdfFastRoundRect(vec2 coord, vec2 extent, vec4 r) {
    r.xy = (coord.x > 0.0) ? r.xy : r.zw;
    r.x = (coord.y > 0.0) ? r.x : r.y;

    vec2 q = abs(coord) - extent + r.x;

    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r.x;
}

// https://iquilezles.org/articles/distfunctions2d/
float sdfFastRoundRect(vec2 coord, vec2 center, vec2 extent, vec4 r, float angle) {
    coord = translate(coord, center);
    coord = rotate(coord, angle);

    return sdfFastRoundRect(coord, extent, r);
}

// 组合 画 圆角矩形
// top = (左, 上，上，右)
// bottom = (右，下，下，左)
float sdfRoundRect(vec2 coord, vec2 extent, vec4 top, vec4 bottom) {
    // TODO
    return 0.0;
}

float sdfRoundRect(vec2 coord, vec2 center, vec2 extent, vec4 top, vec4 bottom, float angle) {
    coord = translate(coord, center);
    coord = rotate(coord, angle);

    return sdfRoundRect(coord, extent, top, bottom);
}

// 边框大小 size = 上，右，下，左
float sdfBorder(vec2 coord, vec2 extent, vec4 top, vec4 bottom, vec4 size) {
    float e = sdfRoundRect(coord, extent, top, bottom);

    // TODO 中心点，extent，top，bottom 都要 做 调整
    float i = sdfRoundRect(coord, extent, top, bottom);

    return differenceSdf(e, i);
}

float sdfBorder(vec2 coord, vec2 center, vec2 extent, vec4 top, vec4 bottom, vec4 size, float angle) {
    coord = translate(coord, center);
    coord = rotate(coord, angle);

    return sdfBorder(coord, extent, top, bottom, size);
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

    col = mix(col, vec3(1.0), 1.0 - smoothstep(0.0, 0.01, abs(d)));

    return col;
}

// 按鼠标左键，能显示 该点的 sdf 圆
void showEllipseSdf(out vec3 color, vec2 coord, vec2 center, vec2 s, vec2 ab, int method) {
    if(iMouse.z > 0.001) {
        vec2 m = iMouse.xy;
        float d = 0.0;
        if(method == 1) {
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
    if(iMouse.z > 0.001) {
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
    if(cell.x < 2.0 * ps.x || cell.y < ps.y) {
        color = vec3(1.0);
    }

    if(abs(coord.x) < ps.x) {
        color = vec3(1.0, 0.0, 0.0);
    }
    if(abs(coord.y) < ps.y) {
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

float Raymarch(vec3 ro, vec3 rd) {
    float d = 0.0;
    for(int i = 0; i < 255; i++) {
        vec3 p = ro + rd * d;
        float d0 = sdfCircle(p, 1.0);
        if(d0 <= 0.001 || d >= 40.0) {
            break;
        }
        d += d0;
    }
    return d;
}

// https://iquilezles.org/articles/normalsSDF/
vec3 calcNormal(vec3 p)
{
    float eps = 0.0001;
    vec2 h = vec2(eps, 0.0);

    float dx = sdfCircle(p + h.xyy, 1.0) - sdfCircle(p - h.xyy, 1.0);

    float dy = sdfCircle(p + h.yxy, 1.0) - sdfCircle(p - h.yxy, 1.0);

    float dz = sdfCircle(p + h.yyx, 1.0) - sdfCircle(p - h.yyx, 1.0);

    return normalize(vec3(dx, dy, dz));
}

// https://zhuanlan.zhihu.com/p/494565379
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // [-0.5, 0.5]
    vec2 pt = uv(fragCoord);
    pt -= 0.5;

    vec3 col = vec3(0.0);

    // 从 ro 出发，射线 (pt, 1.0)
    vec3 ro = vec3(0.0, 0.0, -3);
    vec3 rd = normalize(vec3(pt, 1.0));

    float d = Raymarch(ro, rd);

    if(d < 40.0) {
        vec3 p = ro + rd * d;

        vec3 n = calcNormal(p);

        vec3 lightPos = vec3(0, 5, -5.0);
        lightPos.xz = rotate(lightPos.xz, iTime);

        vec3 lightdir = normalize(lightPos - p);

        float diffuse = dot(n, lightdir);
        diffuse = diffuse * 0.5 + 0.5;

        vec3 color = vec3(0.2, 0.7, 1.0);
        col += diffuse * color;
    }

    fragColor = vec4(col, 1.0);
}