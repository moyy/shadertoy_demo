// 有向线段：有一个端点在 原点，x轴-正向
// 逆时针 为 里面
float sdfSegment(vec2 pt, float len) {
    
    float proj = clamp(pt.x, 0.0, len);
    
    float s = sign(-pt.y);
    
    pt -= proj * vec2(1.0, 0.0);
    
    return s * length(pt);
}