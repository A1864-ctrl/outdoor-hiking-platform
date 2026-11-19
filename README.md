# 基于 Python 的户外徒步路线推荐与路书分享平台

> 毕业设计项目 · 信息工程学院 · 计算机网络技术
> 学生：唐锦明　学号：202451024670　班级：计网 G32401

一个面向华南地区（湘粤赣桂）的户外徒步服务平台：把"找路线—看路书—发路书—存收藏"这条完整链路做通，
核心是**按用户偏好推荐路线**，而不是简单地给一个热度榜。

**在线方案文档**：https://a1864-ctrl.github.io/outdoor-hiking-platform/

---

## 一、项目定位

本仓库是**新的毕设项目仓库**，从零搭建平台型系统。它吸收了两个旧仓库的数据资产与几何算法，
但架构、技术栈、数据模型全部重做。

| 维度 | 旧项目（旧仓库） | 本项目 |
|---|---|---|
| 形态 | 只读看板（Streamlit 单机应用） | 平台（多角色 Web 系统） |
| 技术栈 | Streamlit + pandas + CSV | FastAPI + Jinja2 + MySQL |
| 用户体系 | 无 | 注册 / 登录 / 角色 / 偏好 |
| 内容生产 | 无（数据写死在 CSV） | 路书投稿 + 审核 + 评论 + 评价 |
| 推荐 | `sort_values('heat')` 单字段排序 | 硬过滤 + 五因子加权 + 贝叶斯平滑 |
| 数据库 | 无 | MySQL，12 张表 |
| 后台 | 无 | 内容审核、用户管理、数据看板 |

## 二、技术栈

- **后端**：Python 3.11 + FastAPI + Uvicorn
- **模板**：Jinja2（服务端渲染，不引入前端框架）
- **数据库**：MySQL 8.0 + PyMySQL（手写 SQL，不使用 ORM）
- **地图**：Leaflet 1.9（CDN 引入，浏览器端唯一第三方库）
- **密码**：标准库 `hashlib.pbkdf2_hmac`，SHA-256，20 万次迭代 + 独立盐值
- **会话**：签名 Cookie（`itsdangerous`）

> 约束说明：题目要求"只能使用 Python 和 MySQL"。后端全部为 Python，数据全部落 MySQL；
> HTML/CSS/JavaScript 是浏览器渲染的必备载体（任何 Web 系统都无法回避），
> 且本项目不使用 Vue/React 等前端框架、不使用第二套服务端语言。

## 三、目录结构

```
outdoor-hiking-platform/
├── app/                        # 应用源码（待开发）
│   ├── main.py                 # FastAPI 入口
│   ├── config.py               # 配置与数据库连接
│   ├── models/                 # 数据访问层（纯 SQL 封装）
│   ├── services/               # 业务逻辑层
│   │   ├── geo.py              # 距离、爬升、Naismith 耗时
│   │   ├── gpx.py              # GPX 解析与导出
│   │   ├── recommend.py        # 推荐算法（课题核心）
│   │   ├── roadbook.py         # 路书业务
│   │   └── stats.py            # 后台统计
│   ├── api/                    # REST 接口
│   ├── web/                    # 页面路由
│   ├── templates/              # Jinja2 模板
│   └── static/                 # CSS / JS / 图片
├── sql/
│   └── schema.sql              # 12 张表建表脚本 + 字典初始化
├── scripts/
│   └── import_seed.py          # CSV 清洗入库脚本（待开发）
├── data/
│   ├── attractions.csv         # 155 条景点（迁自旧仓库）
│   ├── hiking_routes.csv       # 34 条路线（迁自旧仓库）
│   ├── custom_routes.csv       # 用户自建路线样例
│   └── tracks/                 # 34 个轨迹 JSON，合计 15,330 个坐标点
├── docs/
│   ├── 整合优化方案.docx        # 完整方案（35 页，含逐项匹配度分析）
│   └── 轨迹体检报告.md          # 旧项目数据质量记录
├── legacy/                     # 旧项目代码存档：仅作算法参考，不参与运行
│   ├── app_utils.py            # 可复用的几何/地形计算
│   ├── gpx_store.py            # GPX 解析与存储
│   └── tools/                  # 数据流水线脚本（OSM 路网 + SRTM 高程）
├── site/
│   └── index.html              # 方案文档网页版（GitHub Pages 首页）
└── requirements.txt
```

## 四、数据库设计

12 张表，对应任务书"设计 12 张表并编写建表脚本"：

| # | 表 | 作用 |
|---|---|---|
| 1 | `user` | 账号、密码哈希、角色、状态 |
| 2 | `user_preference` | 难度、里程上限、偏好季节、常驻城市（1:1） |
| 3 | `region` | 省市字典，解决城市名口径不一 |
| 4 | `category` | 景点类型 / 路线类型 / 难度三套字典 |
| 5 | `attraction` | 景点：等级、门票、季节、经纬度 |
| 6 | `hiking_route` | 路线：里程、爬升、难度、轨迹元数据 |
| 7 | `route_waypoint` | 途经点（含累计里程与海拔） |
| 8 | `roadbook` | 路书主体与审核状态 |
| 9 | `roadbook_day` | 多日路书的每日行程 |
| 10 | `comment` | 评论，支持一级回复（多态） |
| 11 | `favorite` | 收藏景点/路线/路书（多态） |
| 12 | `route_review` | 四项评分 + 文字评价 |

**两个关键设计取舍**（论文需展开）：轨迹点不入库（元数据入库、几何留 JSON 文件）；
多态关联不做外键（用服务层清理钩子保证一致性）。

## 五、快速开始

```bash
# 1. 建库建表
mysql -u root -p < sql/schema.sql

# 2. 安装依赖
pip install -r requirements.txt

# 3. 配置环境变量
cp .env.example .env      # 修改数据库账号密码

# 4. 启动
uvicorn app.main:app --reload --port 8000
```

## 六、开发进度

任务书八项任务与当前完成度：

- [ ] (1) 景点浏览与检索
- [ ] (2) 路线库（筛选 + 详情 + 轨迹地图）
- [ ] (3) 个性化路线推荐 ★课题核心
- [ ] (4) 路书发布与管理
- [ ] (5) 收藏与评价
- [ ] (6) 个人中心
- [ ] (7) 后台管理（用户/内容/统计）
- [ ] (8) 账户安全（注册登录、密码加密、权限控制）

## 七、数据来源与许可

- 景点与路线基础数据来自旧仓库 `south-china-hiking-map-streamlit`，原为本项目作者整理。
- 轨迹由 OSM 路网规划 + SRTM 高程数据生成（详见 `docs/轨迹体检报告.md`）。
- 地图底图 © OpenStreetMap contributors，遵循 ODbL 许可。

## 八、文档

- 完整方案：`docs/整合优化方案.docx`（含原项目逐项匹配度分析、冲突裁决、数据库设计与推荐算法论证）
- 网页版：https://a1864-ctrl.github.io/outdoor-hiking-platform/
