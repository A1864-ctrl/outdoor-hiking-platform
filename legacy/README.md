# legacy —— 旧项目代码存档

这个目录里的代码**不参与新项目运行**，只作为算法参考与数据血缘记录保留。

| 文件 | 来源 | 为什么要保留 |
|---|---|---|
| `app_utils.py` | 旧 streamlit 仓 | `haversine_m`、`track_stats`、`steepest_section`、`naismith_hours`、`tobler_speed` 这几个纯函数经过实测，可直接改写进 `app/services/geo.py` |
| `gpx_store.py` | 旧 streamlit 仓 | GPX 解析、轨迹写入、噪声平滑的处理方式，可作为 `app/services/gpx.py` 的参考实现 |
| `tools/build_tracks.py` | 旧 streamlit 仓 | 轨迹生成流水线（OSM 路网规划 + SRTM 高程），解释了 `data/tracks/*.json` 是怎么来的 |
| `tools/osm_lookup.py` | 旧 streamlit 仓 | OSM 地名与路网查询 |
| `tools/fetch_osm_index.py` | 旧 streamlit 仓 | 路网索引抓取 |
| `tools/audit_tracks.py` | 旧 streamlit 仓 | 轨迹体检脚本，输出见 `docs/轨迹体检报告.md` |
| `tools/import_gpx_dir.py` | 旧 streamlit 仓 | 批量导入 GPX 目录 |
| `tools/routes_manifest.py` | 旧 streamlit 仓 | 路线清单生成 |

## 复用边界（写论文时要讲清楚）

**可以复用**：几何计算、GPX 解析、地形统计这类**无状态纯函数**。它们与本课题无关，是通用工具。

**必须重写**：

- `views/` 下四个 Streamlit 页面 —— 框架换了，一行都用不上。
- `read_csv_smart()` 多编码探测 —— 迁移是一次性动作，写进 `scripts/import_seed.py` 即可，不该留在运行时。
- `norm_city()` 这类字符串截取补丁 —— 用 `region` 字典表从数据模型层面解决，不再需要补丁。
- `gen_track()` 反推的假轨迹 —— **已删除，不得使用**。旧项目里它对没有真实轨迹的路线合成了一条演示曲线，
  放进毕业设计属于数据造假。

## 旧仓库地址（仅作追溯，已归档/待删除）

- `A1864-ctrl/south-china-hiking-map-streamlit`
- `A1864-ctrl/south-china-hiking-map-python`
- `A1864-ctrl/south-china-hiking-map`（Vue 3 版，违反"只用 Python"约束，不参与本课题）
