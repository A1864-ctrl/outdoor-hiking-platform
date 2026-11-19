-- =============================================================
--  户外徒步路线推荐与路书分享平台 · 数据库建表脚本
--  MySQL 8.0 / InnoDB / utf8mb4
--  12 张表，与毕业设计任务书"设计 12 张表并编写建表脚本"一一对应
-- =============================================================

CREATE DATABASE IF NOT EXISTS hiking_platform
  DEFAULT CHARACTER SET utf8mb4
  COLLATE utf8mb4_general_ci;

USE hiking_platform;

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- -------------------------------------------------------------
-- 1. user 用户表
-- -------------------------------------------------------------
DROP TABLE IF EXISTS `user`;
CREATE TABLE `user` (
  id            BIGINT       NOT NULL AUTO_INCREMENT,
  username      VARCHAR(50)  NOT NULL                COMMENT '登录名',
  password_hash VARCHAR(255) NOT NULL                COMMENT 'PBKDF2 加盐哈希，格式 algo$iter$salt$hash',
  nickname      VARCHAR(50)  NULL                    COMMENT '昵称',
  avatar        VARCHAR(255) NULL                    COMMENT '头像路径',
  city          VARCHAR(50)  NULL                    COMMENT '常驻城市（展示用，筛选走 user_preference）',
  bio           VARCHAR(255) NULL                    COMMENT '个人简介',
  role          TINYINT      NOT NULL DEFAULT 0      COMMENT '0 注册用户 1 管理员',
  status        TINYINT      NOT NULL DEFAULT 1      COMMENT '1 正常 0 禁用',
  created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_username (username)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户表';

-- -------------------------------------------------------------
-- 2. region 地区表（省市两级，字典）
-- -------------------------------------------------------------
DROP TABLE IF EXISTS region;
CREATE TABLE region (
  id       BIGINT      NOT NULL AUTO_INCREMENT,
  province VARCHAR(30) NOT NULL COMMENT '省级，如 广东省',
  city     VARCHAR(30) NOT NULL COMMENT '市级，如 深圳市',
  PRIMARY KEY (id),
  UNIQUE KEY uk_prov_city (province, city)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='地区表';

-- -------------------------------------------------------------
-- 3. category 分类字典表（三套字典共用一张表）
-- -------------------------------------------------------------
DROP TABLE IF EXISTS category;
CREATE TABLE category (
  id     BIGINT      NOT NULL AUTO_INCREMENT,
  type   VARCHAR(20) NOT NULL COMMENT '字典类型：attraction 景点类型 / route 路线类型 / difficulty 难度',
  name   VARCHAR(30) NOT NULL COMMENT '字典项名称',
  sort   INT         NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  UNIQUE KEY uk_type_name (type, name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='分类字典表';

-- -------------------------------------------------------------
-- 4. user_preference 用户偏好表（与 user 1:1）
-- -------------------------------------------------------------
DROP TABLE IF EXISTS user_preference;
CREATE TABLE user_preference (
  user_id           BIGINT       NOT NULL COMMENT '主键同时是外键，保证 1:1',
  prefer_difficulty TINYINT      NULL     COMMENT '偏好难度 1~5，NULL 表示不限',
  max_distance_km   DECIMAL(6,2) NULL     COMMENT '单日里程上限',
  prefer_season     TINYINT      NOT NULL DEFAULT 0 COMMENT '1春 2夏 3秋 4冬 0 不限',
  prefer_region_id  BIGINT       NULL     COMMENT '常驻城市，参与推荐距离衰减',
  updated_at        DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id),
  KEY idx_pref_region (prefer_region_id),
  CONSTRAINT fk_pref_user   FOREIGN KEY (user_id)          REFERENCES `user`(id) ON DELETE CASCADE,
  CONSTRAINT fk_pref_region FOREIGN KEY (prefer_region_id) REFERENCES region(id)  ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户偏好表';

-- -------------------------------------------------------------
-- 5. attraction 景点表
-- -------------------------------------------------------------
DROP TABLE IF EXISTS attraction;
CREATE TABLE attraction (
  id          BIGINT       NOT NULL AUTO_INCREMENT,
  name        VARCHAR(100) NOT NULL,
  region_id   BIGINT       NOT NULL,
  category_id BIGINT       NOT NULL,
  level       VARCHAR(20)  NULL     COMMENT '景区等级，如 5A / 4A / 无评级',
  ticket      VARCHAR(50)  NULL     COMMENT '门票，保留原始文本如 "免费" "60元"',
  season_start TINYINT     NULL     COMMENT '最佳季节起始月，3~10；可大于 end 表示跨年',
  season_end   TINYINT     NULL,
  address     VARCHAR(255) NULL,
  open_time   VARCHAR(100) NULL,
  intro       TEXT         NULL,
  tips        TEXT         NULL     COMMENT '游览提示',
  lng         DECIMAL(10,6) NOT NULL COMMENT '经度',
  lat         DECIMAL(10,6) NOT NULL COMMENT '纬度',
  heat        TINYINT      NOT NULL DEFAULT 0,
  status      TINYINT      NOT NULL DEFAULT 1,
  created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_region (region_id),
  KEY idx_cat (category_id),
  KEY idx_heat (heat),
  CONSTRAINT fk_att_region   FOREIGN KEY (region_id)   REFERENCES region(id),
  CONSTRAINT fk_att_category FOREIGN KEY (category_id) REFERENCES category(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='景点表';

-- -------------------------------------------------------------
-- 6. hiking_route 路线表（轨迹元数据内联，几何数据留文件）
-- -------------------------------------------------------------
DROP TABLE IF EXISTS hiking_route;
CREATE TABLE hiking_route (
  id             BIGINT       NOT NULL AUTO_INCREMENT,
  name           VARCHAR(100) NOT NULL,
  region_id      BIGINT       NOT NULL,
  category_id    BIGINT       NOT NULL,
  difficulty     TINYINT      NOT NULL DEFAULT 3 COMMENT '1入门 2较易 3中等 4较难 5难',
  distance_km    DECIMAL(6,2) NOT NULL,
  ascent_m       INT          NOT NULL DEFAULT 0,
  descent_m      INT          NOT NULL DEFAULT 0,
  ele_max        INT          NULL,
  ele_min        INT          NULL,
  naismith_hours DECIMAL(4,1) NULL,
  days           VARCHAR(10)  NULL COMMENT '建议天数，如 1天 / 1-2天',
  season_start   TINYINT      NULL COMMENT '起始月，可大于 end 表示跨年',
  season_end     TINYINT      NULL,
  transport      TEXT         NULL,
  supply         TEXT         NULL,
  safety         TEXT         NULL,
  track_file     VARCHAR(255) NULL COMMENT '轨迹 JSON 相对路径，如 data/tracks/xx.json',
  n_points       INT          NOT NULL DEFAULT 0,
  n_waypoints    INT          NOT NULL DEFAULT 0,
  heat           TINYINT      NOT NULL DEFAULT 0,
  rating_avg     DECIMAL(3,2) NOT NULL DEFAULT 0.00 COMMENT '贝叶斯平滑后的加权均分',
  rating_count   INT          NOT NULL DEFAULT 0,
  status         TINYINT      NOT NULL DEFAULT 1 COMMENT '1 上架 0 下架',
  created_at     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_region_diff (region_id, difficulty),
  KEY idx_km (distance_km),
  KEY idx_heat (heat),
  CONSTRAINT fk_route_region   FOREIGN KEY (region_id)   REFERENCES region(id),
  CONSTRAINT fk_route_category FOREIGN KEY (category_id) REFERENCES category(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='路线表';

-- -------------------------------------------------------------
-- 7. route_waypoint 途经点表
-- -------------------------------------------------------------
DROP TABLE IF EXISTS route_waypoint;
CREATE TABLE route_waypoint (
  id         BIGINT        NOT NULL AUTO_INCREMENT,
  route_id   BIGINT        NOT NULL,
  seq        INT           NOT NULL COMMENT '顺序号，从 1 开始',
  name       VARCHAR(100)  NULL     COMMENT '途经点名，如 山顶 / 补给点',
  lng        DECIMAL(10,6) NOT NULL,
  lat        DECIMAL(10,6) NOT NULL,
  ele        INT           NULL     COMMENT '海拔（米）',
  cum_km     DECIMAL(6,2)  NULL     COMMENT '从起点累计里程',
  PRIMARY KEY (id),
  UNIQUE KEY uk_route_seq (route_id, seq),
  CONSTRAINT fk_wp_route FOREIGN KEY (route_id) REFERENCES hiking_route(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='途经点表';

-- -------------------------------------------------------------
-- 8. roadbook 路书表
-- -------------------------------------------------------------
DROP TABLE IF EXISTS roadbook;
CREATE TABLE roadbook (
  id            BIGINT       NOT NULL AUTO_INCREMENT,
  user_id       BIGINT       NOT NULL,
  route_id      BIGINT       NULL COMMENT '关联路线，可为空（自拟线路）',
  title         VARCHAR(120) NOT NULL,
  travel_date   DATE         NULL,
  days          TINYINT      NOT NULL DEFAULT 1,
  transport     VARCHAR(255) NULL,
  cost          VARCHAR(255) NULL COMMENT '费用参考',
  gear          TEXT         NULL COMMENT '装备清单',
  notice        TEXT         NULL COMMENT '注意事项',
  content       LONGTEXT     NULL COMMENT '正文，纯文本或受限 HTML',
  cover         VARCHAR(255) NULL,
  gpx_file      VARCHAR(255) NULL,
  status        TINYINT      NOT NULL DEFAULT 0 COMMENT '0 待审 1 通过 2 驳回',
  reject_reason VARCHAR(255) NULL,
  views         INT          NOT NULL DEFAULT 0,
  created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_status_time (status, created_at),
  KEY idx_route (route_id),
  KEY idx_user (user_id),
  CONSTRAINT fk_rb_user  FOREIGN KEY (user_id)  REFERENCES `user`(id)       ON DELETE CASCADE,
  CONSTRAINT fk_rb_route FOREIGN KEY (route_id) REFERENCES hiking_route(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='路书表';

-- -------------------------------------------------------------
-- 9. roadbook_day 路书日程表
-- -------------------------------------------------------------
DROP TABLE IF EXISTS roadbook_day;
CREATE TABLE roadbook_day (
  id          BIGINT       NOT NULL AUTO_INCREMENT,
  roadbook_id BIGINT       NOT NULL,
  day_no      TINYINT      NOT NULL COMMENT '第几天，从 1 开始',
  title       VARCHAR(100) NULL,
  content     TEXT         NULL,
  km          DECIMAL(6,2) NULL COMMENT '当日里程',
  ascent_m    INT          NULL COMMENT '当日爬升',
  PRIMARY KEY (id),
  UNIQUE KEY uk_rb_day (roadbook_id, day_no),
  CONSTRAINT fk_day_roadbook FOREIGN KEY (roadbook_id) REFERENCES roadbook(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='路书日程表';

-- -------------------------------------------------------------
-- 10. comment 评论表（多态关联，不做外键）
-- -------------------------------------------------------------
DROP TABLE IF EXISTS comment;
CREATE TABLE comment (
  id          BIGINT   NOT NULL AUTO_INCREMENT,
  user_id     BIGINT   NOT NULL,
  target_type TINYINT  NOT NULL DEFAULT 3 COMMENT '1 景点 2 路线 3 路书',
  target_id   BIGINT   NOT NULL,
  parent_id   BIGINT   NULL     COMMENT '为空是一级评论，非空是回复',
  content     TEXT     NOT NULL,
  status      TINYINT  NOT NULL DEFAULT 1 COMMENT '1 正常 0 管理员隐藏',
  created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_target (target_type, target_id, created_at),
  KEY idx_user (user_id),
  KEY idx_parent (parent_id),
  CONSTRAINT fk_cm_user FOREIGN KEY (user_id) REFERENCES `user`(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='评论表（多态）';

-- -------------------------------------------------------------
-- 11. favorite 收藏表（多态关联，不做外键）
-- -------------------------------------------------------------
DROP TABLE IF EXISTS favorite;
CREATE TABLE favorite (
  id          BIGINT   NOT NULL AUTO_INCREMENT,
  user_id     BIGINT   NOT NULL,
  target_type TINYINT  NOT NULL COMMENT '1 景点 2 路线 3 路书',
  target_id   BIGINT   NOT NULL,
  created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_user_target (user_id, target_type, target_id),
  KEY idx_target (target_type, target_id),
  CONSTRAINT fk_fav_user FOREIGN KEY (user_id) REFERENCES `user`(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='收藏表（多态）';

-- -------------------------------------------------------------
-- 12. route_review 路线评价表
-- -------------------------------------------------------------
DROP TABLE IF EXISTS route_review;
CREATE TABLE route_review (
  id              BIGINT       NOT NULL AUTO_INCREMENT,
  user_id         BIGINT       NOT NULL,
  route_id        BIGINT       NOT NULL,
  score_scenery   TINYINT      NOT NULL COMMENT '风景 1~5',
  score_difficulty TINYINT     NOT NULL COMMENT '难度合理性 1~5',
  score_traffic   TINYINT      NOT NULL COMMENT '交通便利 1~5',
  score_overall   TINYINT      NOT NULL COMMENT '整体 1~5，参与推荐打分',
  content         TEXT         NULL,
  status          TINYINT      NOT NULL DEFAULT 1,
  created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_user_route (user_id, route_id),
  KEY idx_route (route_id),
  CONSTRAINT fk_rv_user  FOREIGN KEY (user_id)  REFERENCES `user`(id)       ON DELETE CASCADE,
  CONSTRAINT fk_rv_route FOREIGN KEY (route_id) REFERENCES hiking_route(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='路线评价表';

SET FOREIGN_KEY_CHECKS = 1;

-- =============================================================
--  字典初始化
-- =============================================================

INSERT INTO category (type, name, sort) VALUES
  ('difficulty', '入门', 1), ('difficulty', '较易', 2), ('difficulty', '中等', 3),
  ('difficulty', '较难', 4), ('difficulty', '难', 5),
  ('route', '山岳', 1), ('route', '海岸线', 2), ('route', '溪谷', 3),
  ('route', '古道', 4), ('route', '环湖', 5), ('route', '城市郊野', 6),
  ('attraction', '自然风光', 1), ('attraction', '人文古迹', 2), ('attraction', '主题乐园', 3),
  ('attraction', '温泉度假', 4), ('attraction', '乡村旅游', 5),
  ('attraction', '城市公园', 6), ('attraction', '博物馆', 7), ('attraction', '海岛', 8)
ON DUPLICATE KEY UPDATE sort = VALUES(sort);

INSERT INTO region (province, city) VALUES
  ('广东省', '广州市'), ('广东省', '深圳市'), ('广东省', '珠海市'), ('广东省', '佛山市'),
  ('广东省', '惠州市'), ('广东省', '东莞市'), ('广东省', '中山市'), ('广东省', '江门市'),
  ('广东省', '肇庆市'), ('广东省', '清远市'), ('广东省', '韶关市'), ('广东省', '梅州市'),
  ('广东省', '汕头市'), ('广东省', '河源市'), ('广东省', '阳江市'), ('广东省', '湛江市'),
  ('湖南省', '长沙市'), ('湖南省', '衡阳市'), ('湖南省', '郴州市'), ('湖南省', '张家界市'),
  ('江西省', '南昌市'), ('江西省', '赣州市'), ('江西省', '九江市'), ('江西省', '上饶市'),
  ('广西壮族自治区', '南宁市'), ('广西壮族自治区', '桂林市'), ('广西壮族自治区', '柳州市'),
  ('广西壮族自治区', '北海市')
ON DUPLICATE KEY UPDATE province = VALUES(province);
