# 缩放系数 对 sdf 的影响

## 1. 原始 圆

世界坐标系: [-10, 10] * [-10, 10]

+ $x^2 + y^2 = 10^2$
+ sdf: $d_1(x, y) = \sqrt{x^2 + y^2} - 10$

## 2. 缩放 2倍

世界坐标系: [-20, 20] * [-20, 20]

### 2.1. 方法1：修改圆的方程

+ $x^2 + y^2 = 20^2$
+ sdf: $d_2(x, y) = \sqrt{x^2 + y^2} - 20$

缺点：不通用，不能处理 旋转，也不能处理 复杂函数

### 2.2. 方法2：用原始方程，坐标缩放（类似于 相机 视图矩阵）

sdf: $d_3(x, y) = d_1(x/2, y/2) = \sqrt{(x/2)^2 + (y/2)^2} - 10$

例子: $d_3(10, 0) = d_1(5, 0) = -5$

但是 实际上的 sdf 是 $d_2(10, 0) = -10$, 是 d_3 算出来的 2倍

所以 需要修正下 缩放后的 sdf 公式

sdf: $d_4(x, y) = 2 * d_1(x/2, y/2) = 2 * (\sqrt{(x/2)^2 + (y/2)^2} - 10)$

### 2.3. 结论：设计稿中 的 sdf = d(x, y), 则 均匀缩放 s 倍 后

$d_s(x, y, s) = s * d(s/n, s/n)$

## 3. 分析

因为 均匀缩放 是 相似变换，保 角度（相似三角形 对应角相等），sdf 实际上是 圆 和 曲线 相切，相似变换后，圆还是圆，只是 距离 放大/缩小了 s倍

### 3.1. 非均匀缩放

+ 不保证 角度，包括垂直
+ 所以这时候，3D 顶点 法向量 需要重新 计算，不能直接乘 世界矩阵
+ 同理，sdf原来的圆和 曲线 相切 --> 椭圆 和 曲线相切，因此 非均匀缩放后，需要 重新找 sdf 的公式
    - 椭圆的 sdf 近似公式 见 [这里](https://github.com/moyy/e_documents/blob/main/cg/math/ellipse_sdf_approx.md)

## 4. （方案）目前 pi_ui_render 的 处理

+ 定义 布局空间，sdf 设定时候的 参数，比如 画个 100px的圆，那么 布局空间就是 [-50, 50], R = 100
+ 顶点着色器
  - 模型空间（由 gui内部实现决定），可以是 [-1, 1], 也可以是 [0, 100], 也可以是 [-50, 50]
  - 布局空间 (由 div 和 css 数据) ，必须是 [-50, 50]
  - 世界空间（css中 通过 transform 设置）
+ 布局空间 位置 就是 对应 原始 sdf 的 输入
  - 不管 transorm 旋转，缩放，平移，对称 怎么变

### 4.1 处理 scale

#### 4.1.1. 通过 布局空间 位置 的 fwidth

是 webrender的搞法，也是我目前的搞法

fwidth(e) = 每个像素 的 e值 的 变化率

放大 2倍 后，

+ 实际像素 [-100, 100]^2
+ 通过 varying pos 布局空间的 像素 [-50, 50]^2
+ 每像素的 fwidth(pos) = (0.5, 0.5)
+ s = sqrt(2) / |fwidth(pos)| = 2

为什么要长度，为了 兼容 非均匀缩放，好歹给个 近似 方案

#### 4.1.2. 直接用 sdf 的 fwidth 值

#### 4.1.3. 通过 世界矩阵的 逆，全部 变到 模型空间；

这时候，一定要保证 模型空间 = 布局空间；

### 4.1.4. 通过高层 传 uniform scale

+ 因为 矩阵乘法的行列式 = 行列式 相乘
+ 世界矩阵中：平移，旋转，缩放（含 翻转），剪切，只有 缩放变换才有 面积改变
+ 所以，可以 记住 transform 的 变换 所有 含 scale的变换的行列式（就是 scale 系数相乘），将 结果 传进来

 


